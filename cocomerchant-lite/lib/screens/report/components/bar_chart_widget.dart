import 'package:cocomerchant_lite/bloc/report/sale_summery_bloc.dart';
import 'package:cocomerchant_lite/model/sale_summery_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cocomerchant_lite/global.dart' as global;

typedef BarChartRangeChangedCallback = void Function(int mode, DateTime startDateTime, DateTime endDateTime);
typedef BarChartModeChangedCallback = void Function(int mode, DateTime startDateTime, DateTime endDateTime);
typedef BarChartRangeValuedCallback = void Function(int newValue);

class BarChartWidget extends StatefulWidget {
  // mode : 0 = รายวัน, 1 = รายเดือน
  final int mode;
  final String shopId;
  final String shopName;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int rangeValue;
  final BarChartRangeChangedCallback onRangChanged;
  final BarChartModeChangedCallback onModeChanged;
  final BarChartRangeValuedCallback onRangeValued;

  const BarChartWidget(
      {super.key,
      required this.mode,
      required this.shopId,
      required this.shopName,
      required this.startDateTime,
      required this.endDateTime,
      required this.rangeValue,
      required this.onRangChanged,
      required this.onRangeValued,
      required this.onModeChanged});

  @override
  _BarChartWidgetState createState() => _BarChartWidgetState();
}

class _BarChartWidgetState extends State<BarChartWidget> {
  List<BarChartDataModel> dataForChart = [];

  @override
  void initState() {
    super.initState();
    print("BarChartWidget : Start Date Time : ${widget.startDateTime} End Date Time : ${widget.endDateTime}");
  }

  void buildBarChart(List<SaleSummeryModel> data) {
    dataForChart.clear();
    if (widget.mode == 0) {
      // ย้อนหลัง 7 วัน (rangeValue)
      List<DateTime> dateOfWeek = [];
      DateTime dateTrailing = widget.endDateTime.subtract(Duration(days: widget.rangeValue - 1));
      for (int day = 0; day < widget.rangeValue; day++) {
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
    if (widget.mode == 1) {
      // ย้อนหลัง 12 เดือน
      List<DateTime> dateOfMonth = [];
      DateTime dayTrailing = global.getLastDayOfMonth(widget.endDateTime);
      int currentMonth = dayTrailing.month;
      int currentYear = dayTrailing.year;
      for (int month = 0; month < widget.rangeValue; month++) {
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SaleSummeryBloc, SaleSummeryState>(
      listener: (context, state) {
        if (state is SaleSummeryLoadSuccess) {
          setState(() {
            buildBarChart(state.data);
          });
        }
      },
      builder: (context, state) {
        return Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 10, bottom: 32),
            width: double.infinity,
            child: Column(children: [
              SfCartesianChart(
                  backgroundColor: Colors.white,
                  plotAreaBackgroundColor: Colors.grey[50],
                  palette: [Colors.orange.shade400],
                  primaryXAxis: const CategoryAxis(),
                  primaryYAxis: NumericAxis(
                    numberFormat: NumberFormat('###,###,##0'),
                  ),
                  legend: const Legend(isVisible: false),
                  title: ChartTitle(
                      text: '${(widget.mode == 0) ? 'ยอดขายย้อนหลัง ${widget.rangeValue} วัน' : 'ยอดขายย้อนหลัง ${widget.rangeValue} เดือน'} ${widget.shopName}',
                      textStyle: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                  series: <CartesianSeries>[
                    ColumnSeries<BarChartDataModel, String>(
                      dataSource: dataForChart,
                      xValueMapper: (BarChartDataModel sales, _) => (widget.mode == 0)
                          ? '${global.getDayName(sales.docDate)}\n${NumberFormat("00").format(sales.docDate.day)}/${NumberFormat("00").format(sales.docDate.month)}/${NumberFormat("00").format(sales.docDate.year + 543).substring(2)}'
                          : '${NumberFormat("00").format(sales.docDate.month)}/${(sales.docDate.year + 543).toString().substring(2)}',
                      yValueMapper: (BarChartDataModel sales, _) => sales.value,
                      dataLabelSettings: const DataLabelSettings(isVisible: true),
                      animationDuration: 250,
                    )
                  ]),
              Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 3),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[500]),
                            onPressed: () {
                              widget.onRangChanged(0, widget.startDateTime, widget.endDateTime);
                            },
                            child: const Icon(Icons.arrow_back_ios_outlined)),
                        const SizedBox(width: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            if (widget.mode == 0)
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[500]),
                                  onPressed: () {
                                    var endDateTime = global.getLastDayOfMonth(DateTime.now());
                                    var startDateTime = endDateTime;
                                    int currentMonth = endDateTime.month;
                                    int currentYear = endDateTime.year;
                                    for (int i = 0; i < 12; i++) {
                                      currentMonth--;
                                      if (currentMonth == 0) {
                                        currentMonth = 12;
                                        currentYear--;
                                      }
                                    }
                                    startDateTime = DateTime(currentYear, currentMonth);
                                    widget.onModeChanged(1, startDateTime, endDateTime);
                                  },
                                  child: const Text('เปลี่ยนเป็นรายเดือน', style: TextStyle(fontSize: 12))),
                            if (widget.mode == 1)
                              ElevatedButton(
                                  onPressed: () {
                                    widget.onModeChanged(0, widget.startDateTime, widget.endDateTime);
                                  },
                                  child: const Text('เปลี่ยนเป็นรายวัน', style: TextStyle(fontSize: 12))),
                            const SizedBox(width: 4),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[400]),
                                onPressed: () {
                                  if (widget.rangeValue > 1) {
                                    widget.onRangeValued(widget.rangeValue - 1);
                                  }
                                },
                                child: const Icon(Icons.remove, color: Colors.white)),
                            Container(padding: const EdgeInsets.only(left: 10, right: 10), child: Text(widget.rangeValue.toString(), style: const TextStyle(fontSize: 20))),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[400]),
                                onPressed: () {
                                  widget.onRangeValued(widget.rangeValue + 1);
                                },
                                child: const Icon(Icons.add, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[500]),
                            onPressed: () {
                              widget.onRangChanged(1, widget.startDateTime, widget.endDateTime);
                            },
                            child: const Icon(Icons.arrow_forward_ios_outlined)),
                      ],
                    ),
                  )),
              Container(
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
                                  (widget.mode == 0)
                                      ? '${global.formatFullDate(data.docDate)}'
                                      : '${global.getMonthName(data.docDate)} ${(data.docDate.year + 543).toString().substring(2)}',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                child: (data.value != 0)
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
            ]));
      },
    );
  }
}

class BarChartDataModel {
  DateTime docDate;
  double value;

  BarChartDataModel({required this.docDate, required this.value});
}
