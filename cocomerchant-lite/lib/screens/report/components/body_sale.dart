import 'dart:async';
import 'package:cocomerchant_lite/bloc/report/sale_summery_bloc.dart';
import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/model/sale_summery_model.dart';
import 'package:cocomerchant_lite/screens/menu/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cocomerchant_lite/global.dart' as global;

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  BodyState createState() => BodyState();
}

class BodyState extends State<Body> {
  int barChartMode = 0;
  int rangeValue = 7;
  DateRange dateRangeSelected = DateRange.today;
  DateRangeModel dateRangeForBarChart = global.getDateRange(dateRange: DateRange.lastSevenDays);
  DateRangeModel dateRangeInput = global.getDateRange(dateRange: DateRange.today);
  Timer? _timer;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  void setSystemLanguageList() async {
    await global.setSystemLanguage(context);
    // เรียก setState เพื่อให้ UI อัปเดตเมื่อมีการเปลี่ยนภาษา
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    setSystemLanguageList();

    loadDataSaleSummery(dateRangeForBarChart.startDate, dateRangeForBarChart.endDate);

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      loadDataSaleSummery(dateRangeForBarChart.startDate, dateRangeForBarChart.endDate);
    });
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void loadDataSaleSummery(DateTime startDate, DateTime endDate) {
    startDate = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    context.read<SaleSummeryBloc>().add(SaleSummeryLoadStart(
          mode: 0,
          startDateTime: startDate,
          endDateTime: endDate,
          shopIdList: global.appConfig.read("shopid"),
        ));
  }

  void _updateChartMode(int mode) {
    setState(() {
      barChartMode = mode;
      rangeValue = mode == 0 ? 7 : 12;
      _updateDateRangeAndLoadData(mode == 0 ? global.language('Last 7 Days') : global.language('This Month'));
    });
  }

  void _updateDateRangeAndLoadData(String period) {
    final now = DateTime.now();
    switch (period) {
      case var _ when period == global.language('Today'):
        _startDate = now;
        _endDate = now;
        break;
      case var _ when period == global.language('Yesterday'):
        _startDate = now.subtract(const Duration(days: 1));
        _endDate = now.subtract(const Duration(days: 1));
        break;
      case var _ when period == global.language('Last 7 Days'):
        _startDate = now.subtract(const Duration(days: 6));
        _endDate = now;
        break;
      case var _ when period == global.language('This Week'):
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = now;
        break;
      case var _ when period == global.language('Last Week'):
        _startDate = now.subtract(Duration(days: now.weekday + 6));
        _endDate = now.subtract(Duration(days: now.weekday));
        break;
      case var _ when period == global.language('This Month'):
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case var _ when period == global.language('Last Month'):
        _startDate = DateTime(now.year, now.month - 1, 1);
        _endDate = DateTime(now.year, now.month, 0);
        break;
      case var _ when period == global.language('This Year'):
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
        break;
      case var _ when period == global.language('Last Year'):
        _startDate = DateTime(now.year - 1, 1, 1);
        _endDate = DateTime(now.year - 1, 12, 31);
        break;
      case var _ when period == global.language('Custom'):
        // Handle custom date range if needed
        break;
      default:
        _startDate = now;
        _endDate = now;
    }

    // Update dateRangeForBarChart
    dateRangeForBarChart.startDate = _startDate;
    dateRangeForBarChart.endDate = _endDate;

    loadDataSaleSummery(_startDate, _endDate);
  }

  Widget _buildControlButtons() {
    return Semantics(
      label: global.language('Control buttons for selecting daily or monthly chart'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _updateChartMode(0),
                  child: Semantics(
                    button: true,
                    label: global.language('Daily mode selected'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: barChartMode == 0 ? kPrimaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        global.language('Daily'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: barChartMode == 0 ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _updateChartMode(1),
                  child: Semantics(
                    button: true,
                    label: global.language('Monthly mode selected'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: barChartMode == 1 ? kPrimaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        global.language('Monthly'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: barChartMode == 1 ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBarChart() {
    return Semantics(
      label: global.language('Bar chart showing sales data'),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 9),
        elevation: 4,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                barChartMode == 0
                    ? '${global.language('sales in the last')} $rangeValue ${global.language('days')}'
                    : '${global.language('sales in the last')} $rangeValue ${global.language('months')}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: BlocConsumer<SaleSummeryBloc, SaleSummeryState>(
                  listener: (context, state) {
                    if (state is SaleSummeryLoadSuccess) {
                      setState(() {
                        _buildBarChart(state.data);
                      });
                    }
                  },
                  builder: (context, state) {
                    if (state is SaleSummeryLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is SaleSummeryLoadSuccess) {
                      return SfCartesianChart(
                        plotAreaBorderWidth: 0,
                        primaryXAxis: const CategoryAxis(
                          majorGridLines: MajorGridLines(width: 0),
                          labelRotation: 45,
                          labelStyle: TextStyle(fontSize: 10),
                        ),
                        primaryYAxis: NumericAxis(
                          numberFormat: NumberFormat('###,###,##0'),
                          majorGridLines: MajorGridLines(width: 0.5, color: Colors.grey[300]),
                          labelStyle: const TextStyle(fontSize: 10),
                        ),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <CartesianSeries>[
                          ColumnSeries<BarChartDataModel, String>(
                            dataSource: dataForChart,
                            xValueMapper: (BarChartDataModel sales, _) => barChartMode == 0
                                ? '${global.getDayName(sales.docDate)}\n${NumberFormat("00").format(sales.docDate.day)}/${NumberFormat("00").format(sales.docDate.month)}'
                                : global.getMonthName(sales.docDate),
                            yValueMapper: (BarChartDataModel sales, _) => sales.value,
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: true,
                              labelAlignment: ChartDataLabelAlignment.top,
                              textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            pointColorMapper: (BarChartDataModel sales, _) =>
                                sales.value == dataForChart.map((e) => e.value).reduce((max, value) => max > value ? max : value) ? kPrimaryColor : Colors.orange[200],
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          )
                        ],
                      );
                    }
                    return Center(child: Text(global.language('No data available')));
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (dataForChart.isNotEmpty)
                Semantics(
                  label: 'Date range from ${DateFormat('dd/MM/yyyy').format(dataForChart.first.docDate)} to ${DateFormat('dd/MM/yyyy').format(dataForChart.last.docDate)}',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${global.language('From')}: ${DateFormat('dd/MM/yyyy').format(dataForChart.first.docDate)}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        "${global.language('To')}: ${DateFormat('dd/MM/yyyy').format(dataForChart.last.docDate)}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangeRangeButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircularButton(Icons.arrow_back_ios, () {
                  setState(() {
                    dateRangeForBarChart.startDate = dateRangeForBarChart.startDate.subtract(const Duration(days: 1));
                    dateRangeForBarChart.endDate = dateRangeForBarChart.endDate.subtract(const Duration(days: 1));
                    loadDataSaleSummery(dateRangeForBarChart.startDate, dateRangeForBarChart.endDate);
                  });
                }, kPrimaryColor!),
                _buildCircularButton(Icons.remove, () {
                  if (rangeValue > 1) {
                    setState(() {
                      rangeValue--;
                      loadDataSaleSummery(dateRangeForBarChart.startDate, dateRangeForBarChart.endDate);
                    });
                  }
                }, Colors.grey[400]!),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$rangeValue ${barChartMode == 0 ? global.language('Days') : global.language('Months')}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildCircularButton(Icons.add, () {
                  setState(() {
                    rangeValue++;
                    loadDataSaleSummery(dateRangeForBarChart.startDate, dateRangeForBarChart.endDate);
                  });
                }, Colors.grey[400]!),
                _buildCircularButton(Icons.arrow_forward_ios, () {
                  setState(() {
                    dateRangeForBarChart.startDate = dateRangeForBarChart.startDate.add(const Duration(days: 1));
                    dateRangeForBarChart.endDate = dateRangeForBarChart.endDate.add(const Duration(days: 1));
                    loadDataSaleSummery(dateRangeForBarChart.startDate, dateRangeForBarChart.endDate);
                  });
                }, kPrimaryColor!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularButton(IconData icon, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(12),
        backgroundColor: color,
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  void _buildBarChart(List<SaleSummeryModel> data) {
    dataForChart.clear();
    if (barChartMode == 0) {
      // ย้อนหลัง 7 วัน (rangeValue)
      List<DateTime> dateOfWeek = [];
      DateTime dateTrailing = dateRangeForBarChart.endDate.subtract(Duration(days: rangeValue - 1));
      for (int day = 0; day < rangeValue; day++) {
        dateOfWeek.insert(0, dateTrailing);
        dateTrailing = dateTrailing.add(const Duration(days: 1));
      }
      for (var date in dateOfWeek) {
        double totalAmount = 0;
        DateTime dateCompare = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
        for (var item in data) {
          DateTime docDate = DateTime.parse(item.docdate);
          if (docDate.year == dateCompare.year && docDate.month == dateCompare.month && docDate.day == dateCompare.day) {
            totalAmount += item.totalamount;
          }
        }
        dataForChart.insert(0, BarChartDataModel(docDate: date, value: totalAmount));
      }
    }
    if (barChartMode == 1) {
      // ย้อนหลัง 12 เดือน
      List<DateTime> dateOfMonth = [];
      DateTime dayTrailing = global.getLastDayOfMonth(dateRangeForBarChart.endDate);
      int currentMonth = dayTrailing.month;
      int currentYear = dayTrailing.year;
      for (int month = 0; month < rangeValue; month++) {
        dateOfMonth.insert(0, dayTrailing);
        currentMonth--;
        if (currentMonth == 0) {
          currentMonth = 12;
          currentYear--;
        }
        dayTrailing = DateTime(currentYear, currentMonth);
      }
      for (var date in dateOfMonth) {
        double totalAmount = 0;
        DateTime dateCompare = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
        for (var item in data) {
          DateTime docDate = DateTime.parse(item.docdate);
          if (docDate.year == dateCompare.year && docDate.month == dateCompare.month) {
            totalAmount += item.totalamount;
          }
        }
        dataForChart.add(BarChartDataModel(docDate: date, value: totalAmount));
      }
    }
  }

  List<BarChartDataModel> dataForChart = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: Semantics(
          label: global.language('Go back to menu screen'),
          button: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            color: Colors.white,
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, MenuScreen.routeName, (route) => false);
            },
          ),
        ),
        backgroundColor: kPrimaryColor,
        title: Text(
          global.language('Sales'),
          style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          _buildControlButtons(),
          buildBarChart(),
          _buildChangeRangeButtons(),
          Semantics(
            label: global.language('List of sales data'),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              child: Card(
                color: Colors.white,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                  child: Column(
                    children: dataForChart
                        .map((data) => Container(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    barChartMode == 0
                                        ? global.formatFullDate(data.docDate)
                                        : '${global.getMonthName(data.docDate)} ${(data.docDate.year + 543).toString().substring(2)}',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Expanded(
                                  child: data.value != 0
                                      ? Text(
                                          NumberFormat('###,###,###').format(data.value),
                                          textAlign: TextAlign.right,
                                          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                        )
                                      : Container(),
                                ),
                              ],
                            )))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class BarChartDataModel {
  DateTime docDate;
  double value;

  BarChartDataModel({required this.docDate, required this.value});
}
