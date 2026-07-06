import 'package:intl/intl.dart';

class DateTimeHelper {
  /// แปลงวันที่ UTC เป็น local time และแสดงในรูปแบบที่เหมาะสม
  static String formatLocalDateTime(DateTime utcDateTime) {
    final localDateTime = utcDateTime.toLocal();
    return DateFormat('dd/MM/yyyy HH:mm').format(localDateTime);
  }

  /// แปลงวันที่ UTC เป็น local date เท่านั้น
  static String formatLocalDate(DateTime utcDateTime) {
    final localDateTime = utcDateTime.toLocal();
    return DateFormat('dd/MM/yyyy').format(localDateTime);
  }

  /// ตรวจสอบว่าวันที่ปัจจุบันอยู่ในช่วงเวลาที่กำหนดหรือไม่
  static bool isDateInRange(DateTime startUtc, DateTime endUtc) {
    final now = DateTime.now();
    final startLocal = startUtc.toLocal();
    final endLocal = endUtc.toLocal();

    return now.isAfter(startLocal) && now.isBefore(endLocal);
  }

  /// ตรวจสอบว่าวันในสัปดาห์ตรงกับเงื่อนไขหรือไม่
  static bool isDayOfWeekValid(DateTime dateTime, Map<String, bool> dayRules) {
    final weekday = dateTime.weekday;

    switch (weekday) {
      case DateTime.monday:
        return dayRules['monday'] ?? false;
      case DateTime.tuesday:
        return dayRules['tuesday'] ?? false;
      case DateTime.wednesday:
        return dayRules['wednesday'] ?? false;
      case DateTime.thursday:
        return dayRules['thursday'] ?? false;
      case DateTime.friday:
        return dayRules['friday'] ?? false;
      case DateTime.saturday:
        return dayRules['saturday'] ?? false;
      case DateTime.sunday:
        return dayRules['sunday'] ?? false;
      default:
        return false;
    }
  }

  /// รับชื่อวันในสัปดาห์
  static String getDayName(int weekday) {
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday];
  }

  /// รับชื่อวันในสัปดาห์ภาษาไทย
  static String getDayNameTh(int weekday) {
    const days = ['', 'จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์', 'อาทิตย์'];
    return days[weekday];
  }

  /// แปลงวันในสัปดาห์เป็น Map สำหรับใช้กับ special rules
  static Map<String, bool> createDayRulesMap({
    bool monday = false,
    bool tuesday = false,
    bool wednesday = false,
    bool thursday = false,
    bool friday = false,
    bool saturday = false,
    bool sunday = false,
  }) {
    return {
      'monday': monday,
      'tuesday': tuesday,
      'wednesday': wednesday,
      'thursday': thursday,
      'friday': friday,
      'saturday': saturday,
      'sunday': sunday,
    };
  }

  /// รับรายการวันที่เปิดใช้งานจาก dayRules
  static String getActiveDaysText(Map<String, bool> dayRules) {
    final activeDays = <String>[];

    if (dayRules['monday'] == true) activeDays.add('จ.');
    if (dayRules['tuesday'] == true) activeDays.add('อ.');
    if (dayRules['wednesday'] == true) activeDays.add('พ.');
    if (dayRules['thursday'] == true) activeDays.add('พฤ.');
    if (dayRules['friday'] == true) activeDays.add('ศ.');
    if (dayRules['saturday'] == true) activeDays.add('ส.');
    if (dayRules['sunday'] == true) activeDays.add('อา.');

    return activeDays.isEmpty ? 'ไม่มี' : activeDays.join(', ');
  }
}
