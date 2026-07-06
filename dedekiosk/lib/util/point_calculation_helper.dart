import 'package:dedekiosk/model/global_model.dart';

/// ผลลัพธ์การคำนวณแต้มสะสม
class PointCalculationResult {
  final double usePoint; // แต้มที่ใช้
  final double getPoint; // แต้มที่จะได้รับ
  final double pointDiscountAmount; // ส่วนลดจากแต้ม (ถ้า pointusagetype = 1)
  final double pointAmount; // ยอดชำระจากแต้ม (ถ้า pointusagetype = 2)
  final double currentPointBalance; // แต้มคงเหลือหลังใช้แต้ม
  final int pointUsageType; // 1 = ส่วนลด, 2 = ชำระเงิน

  PointCalculationResult({
    this.usePoint = 0,
    this.getPoint = 0,
    this.pointDiscountAmount = 0,
    this.pointAmount = 0,
    this.currentPointBalance = 0,
    this.pointUsageType = 1,
  });

  /// สร้างผลลัพธ์ว่าง
  factory PointCalculationResult.empty() => PointCalculationResult();

  @override
  String toString() {
    return 'PointCalculationResult(usePoint: $usePoint, getPoint: $getPoint, pointDiscountAmount: $pointDiscountAmount, pointAmount: $pointAmount, currentPointBalance: $currentPointBalance, pointUsageType: $pointUsageType)';
  }
}

/// Helper class สำหรับคำนวณแต้มสะสม
class PointCalculationHelper {
  /// แปลงวันที่จาก String เป็น DateTime
  static DateTime? _parseDate(String dateString) {
    if (dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// ตรวจสอบว่าวันที่ปัจจุบันอยู่ในช่วงเวลาที่กำหนดหรือไม่
  static bool _isDateInStringRange(String startDateString, String endDateString) {
    final startDate = _parseDate(startDateString);
    final endDate = _parseDate(endDateString);

    if (startDate == null || endDate == null) return false;

    final now = DateTime.now();
    return now.isAfter(startDate.subtract(const Duration(days: 1))) && now.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// ตรวจสอบวันในสัปดาห์
  static bool _isDayOfWeekValid(DateTime date, Map<int, bool> dayRules) {
    return dayRules[date.weekday] ?? false;
  }

  /// สร้าง Map สำหรับวันในสัปดาห์
  static Map<int, bool> _createDayRulesMap({
    required bool monday,
    required bool tuesday,
    required bool wednesday,
    required bool thursday,
    required bool friday,
    required bool saturday,
    required bool sunday,
  }) {
    return {
      DateTime.monday: monday,
      DateTime.tuesday: tuesday,
      DateTime.wednesday: wednesday,
      DateTime.thursday: thursday,
      DateTime.friday: friday,
      DateTime.saturday: saturday,
      DateTime.sunday: sunday,
    };
  }

  /// คำนวณแต้มที่ได้รับจากการซื้อ
  static double calculateEarnedPoints({
    required double totalAmount,
    PointConfigModel? pointConfig,
  }) {
    if (pointConfig == null || totalAmount <= 0) {
      return 0.0;
    }

    double calculateGetPoint = 0.0;
    final currentLocalTime = DateTime.now();

    // ใช้ general rules เป็นค่าเริ่มต้น
    if (pointConfig.generalrules.isNotEmpty) {
      final generalRule = pointConfig.generalrules.first;

      // ตรวจสอบว่าอยู่ในช่วงเวลาของ general rule หรือไม่
      if (_isDateInStringRange(generalRule.startdate, generalRule.enddate)) {
        if (generalRule.payperpoint > 0) {
          calculateGetPoint = totalAmount / generalRule.payperpoint;
        }
      }
    }

    // ตรวจสอบ special rules ตามวันที่
    for (final specialRule in pointConfig.specialrules) {
      if (_isDateInStringRange(specialRule.startdate, specialRule.enddate)) {
        // ตรวจสอบวันในสัปดาห์
        final dayRules = _createDayRulesMap(
          monday: specialRule.monday,
          tuesday: specialRule.tuesday,
          wednesday: specialRule.wednesday,
          thursday: specialRule.thursday,
          friday: specialRule.friday,
          saturday: specialRule.saturday,
          sunday: specialRule.sunday,
        );

        if (_isDayOfWeekValid(currentLocalTime, dayRules)) {
          // คำนวณแต้มใหม่ด้วย multiplier
          if (calculateGetPoint == 0.0 && pointConfig.generalrules.isNotEmpty) {
            final generalRule = pointConfig.generalrules.first;
            if (generalRule.payperpoint > 0) {
              calculateGetPoint = totalAmount / generalRule.payperpoint;
            }
          }

          calculateGetPoint *= specialRule.multiplier;

          // ตรวจสอบแต้มสูงสุดต่อบิล
          if (specialRule.maxpointperbill > 0 && calculateGetPoint > specialRule.maxpointperbill) {
            calculateGetPoint = specialRule.maxpointperbill;
          }
          break; // ใช้ special rule แรกที่ตรงเงื่อนไข
        }
      }
    }

    return calculateGetPoint.floor().toDouble(); // ปัดลงเป็นจำนวนเต็ม
  }

  /// คำนวณมูลค่าส่วนลด/การชำระจากแต้มที่ใช้
  /// pointusagetype: 1 = ใช้เป็นส่วนลด, 2 = ใช้เป็นการชำระเงิน
  static double calculatePointDiscountAmount({
    required double pointsUsed,
    PointConfigModel? pointConfig,
  }) {
    if (pointConfig == null || pointsUsed <= 0) {
      return 0.0;
    }

    if (pointConfig.generalrules.isNotEmpty) {
      final generalRule = pointConfig.generalrules.first;

      if (_isDateInStringRange(generalRule.startdate, generalRule.enddate)) {
        if (generalRule.pointvalue > 0) {
          // แต้ม / pointvalue = มูลค่าเงิน
          return pointsUsed / generalRule.pointvalue;
        }
      }
    }

    return 0.0;
  }

  /// รับข้อมูล general rule ที่ active
  static PointGeneralRuleModel? getActiveGeneralRule(PointConfigModel? pointConfig) {
    if (pointConfig == null || pointConfig.generalrules.isEmpty) return null;

    final generalRule = pointConfig.generalrules.first;

    if (_isDateInStringRange(generalRule.startdate, generalRule.enddate)) {
      return generalRule;
    }

    return null;
  }

  /// ตรวจสอบว่ามี special rule ที่ active อยู่หรือไม่
  static PointSpecialRuleModel? getActiveSpecialRule(PointConfigModel? pointConfig) {
    if (pointConfig == null) return null;

    final currentLocalTime = DateTime.now();

    for (final specialRule in pointConfig.specialrules) {
      if (_isDateInStringRange(specialRule.startdate, specialRule.enddate)) {
        final dayRules = _createDayRulesMap(
          monday: specialRule.monday,
          tuesday: specialRule.tuesday,
          wednesday: specialRule.wednesday,
          thursday: specialRule.thursday,
          friday: specialRule.friday,
          saturday: specialRule.saturday,
          sunday: specialRule.sunday,
        );

        if (_isDayOfWeekValid(currentLocalTime, dayRules)) {
          return specialRule;
        }
      }
    }

    return null;
  }

  /// คำนวณแต้มสูงสุดที่สามารถใช้ได้
  /// ไม่เกินแต้มคงเหลือ และไม่เกินยอดชำระ (แปลงเป็นแต้ม)
  static double calculateMaxUsablePoints({
    required double pointBalance,
    required double totalAmount,
    PointConfigModel? pointConfig,
  }) {
    if (pointConfig == null || pointBalance <= 0 || totalAmount <= 0) {
      return 0.0;
    }

    final generalRule = getActiveGeneralRule(pointConfig);
    if (generalRule == null || generalRule.pointvalue <= 0) {
      return 0.0;
    }

    // แปลงยอดชำระเป็นแต้ม: ยอดเงิน * pointvalue = แต้มสูงสุดที่ใช้ได้
    double maxPointsFromAmount = totalAmount * generalRule.pointvalue;

    // ใช้ค่าที่น้อยกว่าระหว่างแต้มคงเหลือ และแต้มสูงสุดจากยอดชำระ
    return pointBalance < maxPointsFromAmount ? pointBalance : maxPointsFromAmount;
  }

  /// รับข้อความอธิบายการคำนวณแต้ม
  static String getPointCalculationDescription(PointConfigModel? pointConfig) {
    if (pointConfig == null) return 'ไม่มีการตั้งค่าระบบแต้ม';

    final specialRule = getActiveSpecialRule(pointConfig);
    final generalRule = getActiveGeneralRule(pointConfig);

    if (specialRule != null && generalRule != null) {
      return 'โปรโมชั่นพิเศษ: ได้แต้ม ${specialRule.multiplier}x';
    }

    if (generalRule != null) {
      return 'ซื้อ ${generalRule.payperpoint} บาท ได้ ${generalRule.pointvalue.toInt()} แต้ม';
    }

    return 'ไม่มีกฎการให้แต้มที่ใช้งานได้';
  }

  /// รับข้อความอธิบายการใช้แต้ม
  static String getPointUsageDescription(PointConfigModel? pointConfig) {
    if (pointConfig == null) return '';

    final generalRule = getActiveGeneralRule(pointConfig);
    if (generalRule == null || generalRule.pointvalue <= 0) return '';

    return '${generalRule.pointvalue.toInt()} แต้ม = 1 บาท';
  }

  /// คำนวณผลลัพธ์แต้มทั้งหมด (แต้มที่ใช้, แต้มที่ได้, ส่วนลด/ยอดชำระ, แต้มคงเหลือ)
  ///
  /// Parameters:
  /// - [pointsToUse]: จำนวนแต้มที่ต้องการใช้
  /// - [totalAmount]: ยอดชำระก่อนหักแต้ม
  /// - [pointBalance]: แต้มคงเหลือปัจจุบัน
  /// - [pointConfig]: การตั้งค่าแต้มจาก shopProfile
  ///
  /// Returns: [PointCalculationResult] ที่มีข้อมูลครบถ้วน
  static PointCalculationResult calculatePointTransaction({
    required double pointsToUse,
    required double totalAmount,
    required double pointBalance,
    PointConfigModel? pointConfig,
  }) {
    if (pointConfig == null) {
      return PointCalculationResult.empty();
    }

    final int pointUsageType = pointConfig.pointusagetype;
    final generalRule = getActiveGeneralRule(pointConfig);

    // ถ้าไม่มี general rule ที่ active ให้คืนค่าว่าง
    if (generalRule == null || generalRule.pointvalue <= 0) {
      return PointCalculationResult.empty();
    }

    // คำนวณแต้มสูงสุดที่ใช้ได้
    double maxUsablePoints = calculateMaxUsablePoints(
      pointBalance: pointBalance,
      totalAmount: totalAmount,
      pointConfig: pointConfig,
    );

    // ตรวจสอบว่าแต้มที่ต้องการใช้ไม่เกินแต้มสูงสุดที่ใช้ได้
    double actualPointsToUse = pointsToUse > maxUsablePoints ? maxUsablePoints : pointsToUse;
    actualPointsToUse = actualPointsToUse > pointBalance ? pointBalance : actualPointsToUse;

    // คำนวณมูลค่าเงินจากแต้ม: แต้ม / pointvalue = มูลค่าเงิน
    double pointMoneyValue = actualPointsToUse / generalRule.pointvalue;

    // กำหนดค่าตาม pointUsageType
    double pointDiscountAmt = 0;
    double pointAmt = 0;

    if (pointUsageType == 1) {
      // pointusagetype = 1: ใช้เป็นส่วนลด
      pointDiscountAmt = pointMoneyValue;
    } else if (pointUsageType == 2) {
      // pointusagetype = 2: ใช้เป็นการชำระเงิน
      pointAmt = pointMoneyValue;
    }

    // คำนวณแต้มที่จะได้รับ (คำนวณจากยอดหลังหักส่วนลดแต้ม)
    double amountForEarningPoints = totalAmount - pointDiscountAmt - pointAmt;
    if (amountForEarningPoints < 0) amountForEarningPoints = 0;

    double earnedPoints = calculateEarnedPoints(
      totalAmount: amountForEarningPoints,
      pointConfig: pointConfig,
    );

    // คำนวณแต้มคงเหลือหลังใช้: (แต้มเดิม - แต้มที่ใช้) + แต้มที่ได้รับ
    double newPointBalance = (pointBalance - actualPointsToUse) + earnedPoints;
    if (newPointBalance < 0) newPointBalance = 0;

    return PointCalculationResult(
      usePoint: actualPointsToUse,
      getPoint: earnedPoints,
      pointDiscountAmount: pointDiscountAmt,
      pointAmount: pointAmt,
      currentPointBalance: newPointBalance,
      pointUsageType: pointUsageType,
    );
  }

  /// รับ pointusagetype จาก pointConfig
  /// 1 = ใช้เป็นส่วนลด, 2 = ใช้เป็นการชำระเงิน
  static int getPointUsageType(PointConfigModel? pointConfig) {
    return pointConfig?.pointusagetype ?? 1;
  }
}
