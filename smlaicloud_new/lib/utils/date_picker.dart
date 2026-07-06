import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Date Picker Widget ที่รองรับทั้งปี พ.ศ. และ ค.ศ.
class CustomDatePicker extends StatefulWidget {
  final ValueChanged<DateTime?>? onDateSelected;
  final String? labelText;
  final bool useBuddhistCalendar;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CustomDatePicker({
    super.key,
    this.onDateSelected,
    this.labelText,
    this.useBuddhistCalendar = true,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    required InputDecoration decoration,
  });

  @override
  _CustomDatePickerState createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  final TextEditingController _controller = TextEditingController();
  DateTime? _selectedDate;
  final GlobalKey _calendarIconKey = GlobalKey();
  bool isDateValid = true;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _updateDisplayDate();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _completeDate(_controller.text);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateDisplayDate() {
    if (_selectedDate != null) {
      int year = widget.useBuddhistCalendar ? _selectedDate!.year + 543 : _selectedDate!.year;
      String twoDigitYear = (year % 100).toString().padLeft(2, '0');
      _controller.text = '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/$twoDigitYear';
    }
  }

  DateTime? _parseDate(String text) {
    List<String> parts = text.split('/');
    if (parts.length < 1 || parts.length > 3) return null;

    DateTime now = DateTime.now();
    int currentYear = widget.useBuddhistCalendar ? now.year + 543 : now.year;
    String twoDigitYear = (currentYear % 100).toString().padLeft(2, '0');

    String dayStr = parts[0].padLeft(2, '0');
    String monthStr = parts.length > 1 ? parts[1].padLeft(2, '0') : now.month.toString().padLeft(2, '0');
    String yearStr = parts.length > 2 ? parts[2].padLeft(2, '0') : twoDigitYear;

    int day = int.tryParse(dayStr) ?? 0;
    int month = int.tryParse(monthStr) ?? 0;
    int yy = int.tryParse(yearStr) ?? 0;

    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    int century = (currentYear ~/ 100) * 100;
    int fullYear = century + yy;
    if (fullYear > currentYear + 50) fullYear -= 100;

    int christianYear = widget.useBuddhistCalendar ? fullYear - 543 : fullYear;

    try {
      DateTime date = DateTime(christianYear, month, day);
      if (date.month == month && date.day == day) return date;
      return null;
    } catch (e) {
      return null;
    }
  }

  void _completeDate(String text) {
    if (text.isEmpty) return;

    DateTime? parsedDate = _parseDate(text);
    setState(() {
      if (parsedDate != null) {
        _selectedDate = parsedDate;
        isDateValid = true;
        _updateDisplayDate(); // แปลงเป็น "01/04/68"
        // onDateSelected callback
        if (widget.onDateSelected != null) {
          widget.onDateSelected!(_selectedDate);
        }
      } else {
        isDateValid = false;
      }
    });
  }

  void _handleInput(String text) {
    // จำกัดความยาวสูงสุดที่ 8 (dd/mm/yy)
    if (text.length > 8) {
      _controller.value = _controller.value.copyWith(
        text: text.substring(0, 8),
        selection: TextSelection.collapsed(offset: 8),
      );
      return;
    }

    // อัปเดตตำแหน่งเคอร์เซอร์เท่านั้น ไม่จัดรูปแบบ
    _controller.value = _controller.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    // ไม่ตรวจสอบหรือจัดรูปแบบขณะพิมพ์ รอเสียโฟกัส
    setState(() {
      isDateValid = true;
    });
  }

  Future<void> _showCustomDatePicker() async {
    DateTime initialDate = _selectedDate ?? DateTime.now();
    DateTime firstDate = widget.firstDate ?? DateTime(1900);
    DateTime lastDate = widget.lastDate ?? DateTime(2100);

    final RenderBox? iconBox = _calendarIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (iconBox == null) return;

    final iconPosition = iconBox.localToGlobal(Offset.zero);
    final iconSize = iconBox.size;

    final double left = iconPosition.dx - 280 + iconSize.width;
    final double top = iconPosition.dy + iconSize.height + 5;
    final screenWidth = MediaQuery.of(context).size.width;
    final adjustedLeft = left + 320 > screenWidth ? screenWidth - 340 : left;

    DateTime? pickedDate = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              left: adjustedLeft,
              top: top,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 320,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: CustomDatePickerDialog(
                    initialDate: initialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    useBuddhistCalendar: widget.useBuddhistCalendar,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        isDateValid = true;
        _updateDisplayDate();
      });
      if (widget.onDateSelected != null) widget.onDateSelected!(_selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.datetime,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
        LengthLimitingTextInputFormatter(8),
      ],
      onChanged: _handleInput,
      onSubmitted: (_) => _completeDate(_controller.text),
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: OutlineInputBorder(),
        suffixIcon: IconButton(
          key: _calendarIconKey,
          icon: Icon(Icons.calendar_today),
          onPressed: _showCustomDatePicker,
        ),
        filled: true,
        fillColor: isDateValid ? Colors.grey[100] : Colors.red[100],
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      ),
    );
  }
}

// Dialog แสดงปฏิทิน
class CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool useBuddhistCalendar;

  const CustomDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.useBuddhistCalendar = true,
  });

  @override
  _CustomDatePickerDialogState createState() => _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<CustomDatePickerDialog> {
  late DateTime _currentDate;
  late DateTime _displayedMonth;
  int _displayedYear = 0;
  bool _isYearMode = false;
  bool _isMonthMode = false;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate;
    _displayedMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    _displayedYear = widget.useBuddhistCalendar ? _currentDate.year + 543 : _currentDate.year;
  }

  Widget _buildHeader() {
    int yearToDisplay = widget.useBuddhistCalendar ? _displayedMonth.year + 543 : _displayedMonth.year;
    String monthName = widget.useBuddhistCalendar ? _getThaiMonthNameFull(_displayedMonth.month) : _getEnglishMonthNameFull(_displayedMonth.month);
    String yearLabel = widget.useBuddhistCalendar ? 'พ.ศ.' : 'A.D.';

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          if (!_isYearMode && !_isMonthMode)
            IconButton(
              icon: Icon(Icons.chevron_left, color: Colors.blue[800]),
              padding: EdgeInsets.zero,
              iconSize: 24,
              onPressed: () {
                setState(() {
                  _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
                });
              },
            ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _isMonthMode = true;
                      _isYearMode = false;
                    });
                  },
                  child: Text(
                    monthName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                  ),
                ),
                Text(
                  ' $yearLabel ',
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isYearMode = true;
                      _isMonthMode = false;
                    });
                  },
                  child: Text(
                    '$yearToDisplay',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),
          if (!_isYearMode && !_isMonthMode)
            IconButton(
              icon: Icon(Icons.chevron_right, color: Colors.blue[800]),
              padding: EdgeInsets.zero,
              iconSize: 24,
              onPressed: () {
                setState(() {
                  _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWeekdayNames() {
    final List<String> weekDays = widget.useBuddhistCalendar ? ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'] : ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return Container(
      color: Colors.grey[200],
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: weekDays
            .map((day) => Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final DateTime firstDayOfMonth = _displayedMonth;
    final DateTime lastDayOfMonth = DateTime(firstDayOfMonth.year, firstDayOfMonth.month + 1, 0);
    final int firstWeekday = firstDayOfMonth.weekday % 7;
    final int daysInMonth = lastDayOfMonth.day;
    final int totalCells = 42;

    List<Widget> dayWidgets = [];

    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(Container());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final DateTime currentDate = DateTime(_displayedMonth.year, _displayedMonth.month, day);
      bool isSelected = currentDate.year == _currentDate.year && currentDate.month == _currentDate.month && currentDate.day == _currentDate.day;
      bool isToday = currentDate.year == DateTime.now().year && currentDate.month == DateTime.now().month && currentDate.day == DateTime.now().day;

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _currentDate = currentDate;
            });
            Navigator.of(context).pop(_currentDate);
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[600] : (isToday ? Colors.blue[100] : Colors.white),
              border: Border.all(color: Colors.grey[300]!, width: 0.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                color: isSelected ? Colors.white : (isToday ? Colors.blue[800] : Colors.black87),
                fontWeight: isToday || isSelected ? FontWeight.bold : null,
              ),
            ),
          ),
        ),
      );
    }

    while (dayWidgets.length < totalCells) {
      dayWidgets.add(Container());
    }

    return Container(
      color: Colors.white,
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: dayWidgets,
      ),
    );
  }

  Widget _buildMonthGrid() {
    List<Widget> monthWidgets = [];
    for (int month = 1; month <= 12; month++) {
      String monthName = widget.useBuddhistCalendar ? _getThaiMonthNameShort(month) : _getEnglishMonthNameShort(month);
      bool isSelected = month == _displayedMonth.month;
      monthWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _displayedMonth = DateTime(_displayedMonth.year, month, 1);
              _isMonthMode = false;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[600] : Colors.white,
              border: Border.all(color: Colors.grey[300]!, width: 0.5),
            ),
            alignment: Alignment.center,
            child: Text(
              monthName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: monthWidgets,
      ),
    );
  }

  Widget _buildYearGrid() {
    int middleYear = _displayedYear;
    int startYear = middleYear - 5;
    List<Widget> yearWidgets = [];

    for (int year = startYear; year < startYear + 12; year++) {
      bool isSelected = year == _displayedYear;
      yearWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _displayedYear = year;
              int christianYear = widget.useBuddhistCalendar ? year - 543 : year;
              _displayedMonth = DateTime(christianYear, _displayedMonth.month, 1);
              _isYearMode = false;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue[600] : Colors.white,
              border: Border.all(color: Colors.grey[300]!, width: 0.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '$year',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: yearWidgets,
      ),
    );
  }

  Widget _buildNavigationButtons() {
    if (_isYearMode) {
      return Container(
        color: Colors.blue[50],
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left, color: Colors.blue[800]),
              padding: EdgeInsets.zero,
              iconSize: 24,
              onPressed: () {
                setState(() {
                  _displayedYear -= 12;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: Colors.blue[800]),
              padding: EdgeInsets.zero,
              iconSize: 24,
              onPressed: () {
                setState(() {
                  _displayedYear += 12;
                });
              },
            ),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildCloseButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Colors.grey[100],
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: Size(double.infinity, 40),
        ),
        child: Text('ปิด', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  String _getThaiMonthNameFull(int month) {
    List<String> monthNames = ['มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'];
    return monthNames[month - 1];
  }

  String _getThaiMonthNameShort(int month) {
    List<String> monthNames = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    return monthNames[month - 1];
  }

  String _getEnglishMonthNameFull(int month) {
    List<String> monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return monthNames[month - 1];
  }

  String _getEnglishMonthNameShort(int month) {
    List<String> monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return monthNames[month - 1];
  }

  Widget _buildContent() {
    if (_isYearMode) {
      return _buildYearGrid();
    } else if (_isMonthMode) {
      return _buildMonthGrid();
    } else {
      return Column(
        children: [
          _buildWeekdayNames(),
          _buildCalendarGrid(),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildNavigationButtons(),
          _buildContent(),
          _buildCloseButton(),
        ],
      ),
    );
  }
}
