import 'package:flutter/material.dart';
import '../global.dart' as global;

/// DatePickerWidget - ส่วนประกอบสำหรับเลือกวันที่ที่ใช้ได้ทั่วไปในระบบ
/// รองรับการแสดงปี พ.ศ. และมี UI ที่สอดคล้องกับ _buildOptionalField และ _buildRequiredField
class DatePickerWidget extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final Function(DateTime?)? onDateSelected;
  final bool isEnabled;
  final bool isRequired;
  final bool hasError;

  const DatePickerWidget({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.isEnabled = true,
    this.isRequired = false,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with required indicator (เหมือนกับ _buildRequiredField)
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: hasError ? Colors.red[700] : Colors.grey[700],
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Container เหมือนกับ _buildRequiredField/_buildOptionalField
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError ? Colors.red[400]! : Colors.grey[300]!,
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: (isEnabled && onDateSelected != null)
                ? () async {
                    // ใช้ showDatePicker ธรรมดาแทน CustomDatePicker เพื่อให้ได้ UI ที่เหมือนกัน
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: global.theme.buttonColor,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null && onDateSelected != null) {
                      onDateSelected!(picked);
                    }
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: isEnabled ? (selectedDate != null ? global.theme.buttonColor : Colors.grey[600]) : Colors.grey[400],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedDate != null
                          ? "${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year + 543}" // แสดงปี พ.ศ.
                          : "เลือกวันที่",
                      style: TextStyle(
                        fontSize: 14,
                        color: selectedDate != null ? Colors.black87 : Colors.grey[400],
                      ),
                    ),
                  ),
                  if (selectedDate != null && isEnabled && onDateSelected != null)
                    InkWell(
                      onTap: () => onDateSelected!(null),
                      child: Icon(
                        Icons.clear,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Bottom spacing เหมือนกับ _buildRequiredField/_buildOptionalField
        const SizedBox(height: 12),
      ],
    );
  }
}
