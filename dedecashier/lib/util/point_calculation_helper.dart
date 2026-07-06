import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/util/date_time_helper.dart';

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

  /// ตรวจสอบว่าวันที่ปัจจุบันอยู่ในช่วงเวลาที่กำหนดหรือไม่ (รับ String)
  static bool _isDateInStringRange(String startDateString, String endDateString) {
    final startDate = _parseDate(startDateString);
    final endDate = _parseDate(endDateString);

    if (startDate == null || endDate == null) return false;

    return DateTimeHelper.isDateInRange(startDate, endDate);
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
        calculateGetPoint = totalAmount / generalRule.payperpoint;
      }
    }

    // ตรวจสอบ special rules ตามวันที่
    for (final specialRule in pointConfig.specialrules) {
      if (_isDateInStringRange(specialRule.startdate, specialRule.enddate)) {
        // ตรวจสอบวันในสัปดาห์
        final dayRules = DateTimeHelper.createDayRulesMap(
          monday: specialRule.monday,
          tuesday: specialRule.tuesday,
          wednesday: specialRule.wednesday,
          thursday: specialRule.thursday,
          friday: specialRule.friday,
          saturday: specialRule.saturday,
          sunday: specialRule.sunday,
        );

        if (DateTimeHelper.isDayOfWeekValid(currentLocalTime, dayRules)) {
          // คำนวณแต้มใหม่ด้วย multiplier
          if (calculateGetPoint == 0.0 && pointConfig.generalrules.isNotEmpty) {
            final generalRule = pointConfig.generalrules.first;
            calculateGetPoint = totalAmount / generalRule.payperpoint;
          }

          calculateGetPoint *= specialRule.multiplier;

          // ตรวจสอบแต้มสูงสุดต่อบิล
          if (specialRule.maxpointperbill > 0 && calculateGetPoint > specialRule.maxpointperbill) {
            calculateGetPoint = specialRule.maxpointperbill.toDouble();
          }
          break; // ใช้ special rule แรกที่ตรงเงื่อนไข
        }
      }
    }

    return calculateGetPoint.floor().toDouble(); // ปัดลงเป็นจำนวนเต็ม
  }

  /// ตรวจสอบว่ามี special rule ที่ active อยู่หรือไม่
  static PointSpecialRuleModel? getActiveSpecialRule(PointConfigModel? pointConfig) {
    if (pointConfig == null) return null;

    final currentLocalTime = DateTime.now();

    for (final specialRule in pointConfig.specialrules) {
      if (_isDateInStringRange(specialRule.startdate, specialRule.enddate)) {
        final dayRules = DateTimeHelper.createDayRulesMap(
          monday: specialRule.monday,
          tuesday: specialRule.tuesday,
          wednesday: specialRule.wednesday,
          thursday: specialRule.thursday,
          friday: specialRule.friday,
          saturday: specialRule.saturday,
          sunday: specialRule.sunday,
        );

        if (DateTimeHelper.isDayOfWeekValid(currentLocalTime, dayRules)) {
          return specialRule;
        }
      }
    }

    return null;
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

  /// คำนวณมูลค่าเงินจากแต้มที่ใช้
  static double calculatePointValue({
    required double points,
    PointConfigModel? pointConfig,
  }) {
    if (pointConfig == null || points <= 0) {
      return 0.0;
    }

    final generalRule = getActiveGeneralRule(pointConfig);
    if (generalRule == null) return 0.0;

    // คำนวณมูลค่าเงินจากแต้ม
    return points * generalRule.payperpoint / generalRule.pointvalue;
  }

  /// รับข้อความอธิบายการคำนวณแต้ม
  static String getPointCalculationDescription(PointConfigModel? pointConfig) {
    if (pointConfig == null) return 'ไม่มีการตั้งค่าระบบแต้ม';

    final specialRule = getActiveSpecialRule(pointConfig);
    final generalRule = getActiveGeneralRule(pointConfig);

    if (specialRule != null) {
      final dayText = DateTimeHelper.getActiveDaysText(DateTimeHelper.createDayRulesMap(
        monday: specialRule.monday,
        tuesday: specialRule.tuesday,
        wednesday: specialRule.wednesday,
        thursday: specialRule.thursday,
        friday: specialRule.friday,
        saturday: specialRule.saturday,
        sunday: specialRule.sunday,
      ));

      final startDate = _parseDate(specialRule.startdate);
      final endDate = _parseDate(specialRule.enddate);

      return 'โปรโมชั่นพิเศษ: ได้แต้ม ${specialRule.multiplier}x '
          '(${startDate != null ? DateTimeHelper.formatLocalDate(startDate) : 'N/A'} - ${endDate != null ? DateTimeHelper.formatLocalDate(endDate) : 'N/A'}) '
          'วัน: $dayText';
    }

    if (generalRule != null) {
      final startDate = _parseDate(generalRule.startdate);
      final endDate = _parseDate(generalRule.enddate);

      return 'ทั่วไป: ซื้อ ${generalRule.payperpoint} บาท ได้ ${generalRule.pointvalue} แต้ม '
          '(${startDate != null ? DateTimeHelper.formatLocalDate(startDate) : 'N/A'} - ${endDate != null ? DateTimeHelper.formatLocalDate(endDate) : 'N/A'})';
    }

    return 'ไม่มีกฎการให้แต้มที่ใช้งานได้';
  }

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
        return pointsUsed / generalRule.pointvalue;
      }
    }

    return 0.0;
  }
}
