import 'dart:async';
import 'package:cocomerchant_lite/bloc/report/product_status_bloc.dart';
import 'package:cocomerchant_lite/bloc/report/sale_daily_bloc.dart';
import 'package:cocomerchant_lite/bloc/report/sale_summery_bloc.dart';
import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/model/product_status_model.dart';
import 'package:cocomerchant_lite/model/sale_daily_model.dart';
import 'package:cocomerchant_lite/model/sale_summery_model.dart';
import 'package:cocomerchant_lite/screens/menu/menu_screen.dart';
import 'package:cocomerchant_lite/screens/report/report_receivemoney_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cocomerchant_lite/global.dart' as global;

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  DashboardState createState() => DashboardState();
}

class DashboardState extends State<Dashboard> {
  String totalAmountHL = "฿0.00";
  String docCountHL = "0";
  int barChartMode = 0;
  int rangeValue = 7;
  DateRange dateRangeSelected = DateRange.today;
  List<ProductStatusModel> dataReport = [];
  DateRangeModel dateRangeForBarChart = global.getDateRange(dateRange: DateRange.lastSevenDays);
  DateRangeModel dateRangeInput = global.getDateRange(dateRange: DateRange.today);
  Timer? _timer;
  String _selectedPeriod = global.language('Today') ?? 'Today';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  int _topN = 10;
  SaleDailyModel _saleModelModel = SaleDailyModel(
      shopid: '',
      branchid: '',
      doccount: 0,
      totalamount: 0,
      totalpayamount: 0,
      totalpaycashamount: 0,
      totalpaycashchange: 0,
      totalroundamount: 0,
      paymentlist: [],
      totalpaymentlist: 0);

  final List<String> _periods = [
    global.language('Today') ?? 'Today',
    global.language('Yesterday') ?? 'Yesterday',
    global.language('Last 7 Days') ?? 'Last 7 Days',
    global.language('This Week') ?? 'This Week',
    global.language('Last Week') ?? 'Last Week',
    global.language('This Month') ?? 'This Month',
    global.language('Last Month') ?? 'Last Month',
    global.language('This Year') ?? 'This Year',
    global.language('Last Year') ?? 'Last Year',
    global.language('Custom') ?? 'Custom',
  ];

  void setSystemLanguageList() async {
    await global.setSystemLanguage(context);
  }

  @override
  void initState() {
    super.initState();
    setSystemLanguageList();

    loadDataSaleSummery(dateRangeForBarChart.startDate, dateRangeForBarChart.endDate);

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      loadDataSaleSummery(dateRangeForBarChart.startDate, dateRangeForBarChart.endDate);
      loadDataStatic();
    });
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void loadDataStatic() {
    DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 0, 0);
    DateTime endDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59);

    context.read<ProductStatusBloc>().add(ProductStatusLoadStart(
          mode: 0,
          startDateTime: startDate,
          endDateTime: endDate,
        ));
    context.read<SaleDailyBloc>().add(SaleDailyLoadStart(
          startDateTime: startDate,
          endDateTime: endDate,
        ));
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

  bool _matchesPeriod(String periodKey, String selectedPeriod) {
    String? translated = global.language(periodKey);
    return selectedPeriod == periodKey || (translated != null && selectedPeriod == translated);
  }

  Widget _buildControlButtons() {
    return Semantics(
      label: global.language("Control buttons for data display") ?? "Control buttons for data display",
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
                    label: global.language("Daily") ?? "Daily",
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: barChartMode == 0 ? kPrimaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        global.language('Daily') ?? 'Daily',
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
                    label: global.language("Monthly") ?? "Monthly",
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: barChartMode == 1 ? kPrimaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        global.language('Monthly') ?? 'Monthly',
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

  Widget _buildHighlightCard() {
    return BlocBuilder<SaleDailyBloc, SaleDailyState>(
      builder: (context, state) {
        if (state is SaleDailyLoadSuccess && state.data.isNotEmpty) {
          totalAmountHL = "฿${NumberFormat('###,###,##0.00').format(state.data.first.totalamount)}";
          docCountHL = NumberFormat('###,###,##0').format(state.data.first.doccount);
        }
        return Semantics(
          label: global.language("Today's sales summary") ?? "Today's sales summary",
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 7),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      button: true,
                      label: global.language("View receive money report") ?? "View receive money report",
                      onTapHint: global.language("Tap to view receive money report") ?? "Tap to view receive money report",
                      child: InkWell(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, ReportReceivemoneyScreen.routeName);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  global.language("Today's Sales") ?? "Today's Sales",
                                  style: TextStyle(fontSize: 17, color: Colors.grey[700], fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  totalAmountHL,
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 0),
                    Divider(color: Colors.grey[300]),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          "$docCountHL ${global.language('Orders') ?? 'Orders'}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSalesSummary() {
    return BlocBuilder<SaleDailyBloc, SaleDailyState>(
      builder: (context, state) {
        if (state is SaleDailyLoadSuccess) {
          _saleModelModel = state.data.first;
        }
        return Semantics(
          label: global.language("Sales and receive money summary") ?? "Sales and receive money summary",
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
            child: Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(global.language("Cash Payment") ?? "Cash Payment", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                          Text(NumberFormat('###,###,##0.00').format(_saleModelModel.totalpaycashamount), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    _buildReceiveMoneyList(_saleModelModel.paymentlist),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(global.language("Rounding Amount") ?? "Rounding Amount", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                        Text(NumberFormat('###,###,##0.00').format(_saleModelModel.totalroundamount), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiveMoney(String description, double amount) {
    return Semantics(
      label: global.language("Payment details:") ??
          "Payment details:" + " $description " + global.language("Amount:") ??
          "Amount:" + " ${NumberFormat('###,###,##0.00').format(amount)}",
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(description.isNotEmpty ? description : "-", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
            Text(NumberFormat('###,###,##0.00').format(amount), style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiveMoneyList(List<SaleDailyPaymentModel> paymentList) {
    return Column(
      children: paymentList.map((payment) => _buildReceiveMoney(payment.description, payment.totalamount)).toList(),
    );
  }

  Widget buildBarChart() {
    return Semantics(
      label: global.language("Sales trend chart") ?? "Sales trend chart",
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildControlButtons(),
              Center(
                child: Text(
                  (barChartMode == 0)
                      ? global.language('Sales trend for the past') ?? 'Sales trend for the past' + " $rangeValue " + global.language('days') ?? 'days'
                      : global.language('Sales trend for the past') ?? 'Sales trend for the past' + " $rangeValue " + global.language('months') ?? 'months',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                ),
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
                    return const Center(child: Text('ไม่มีข้อมูล'));
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (dataForChart.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(global.language('From') ?? 'From' + ': ${DateFormat('dd/MM/yyyy').format(dataForChart.first.docDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text(global.language('To') ?? 'To' + ': ${DateFormat('dd/MM/yyyy').format(dataForChart.last.docDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.only(left: 2, right: 2, top: 10),
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
                                  (barChartMode == 0)
                                      ? global.formatFullDate(data.docDate)
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportSummary() {
    return BlocBuilder<ProductStatusBloc, ProductStatusState>(
      builder: (context, state) {
        if (state is ProductStatusLoadSuccess) {
          dataReport = state.data;
        }
        return Semantics(
          label: global.language("Top 10 Best Selling Products Summary") ?? "Top 10 Best Selling Products Summary",
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
            child: Card(
              elevation: 2,
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(
                    height: 8,
                  ),
                  Center(
                    child: Text(
                      global.language('Top 10 Best Selling Products') ?? 'Top 10 Best Selling Products',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Divider(height: 1, color: Colors.grey[300]),
                  ),
                  _buildProductList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductList() {
    final sortedProducts = dataReport..sort((a, b) => b.totalamount.compareTo(a.totalamount));

    int show = _topN == -1 ? sortedProducts.length : _topN;
    final displayedProducts = sortedProducts.take(show).toList();

    return ListView.separated(
      itemCount: displayedProducts.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 5, bottom: 7),
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Divider(height: 1, color: Colors.grey[300]),
      ),
      itemBuilder: (context, index) {
        final product = displayedProducts[index];
        return Semantics(
          label: global.language("Rank") ??
              "Rank" + " ${index + 1}, " + global.language("Product Name:") ??
              "Product Name:" + " ${product.productname}, " + global.language("Quantity:") ??
              "Quantity:" + " ${NumberFormat('#,##0.00').format(product.totalquantity)}, " + global.language("Sales:") ??
              "Sales:" + " ${NumberFormat('#,##0.00').format(product.totalamount)} " + global.language("Baht") ??
              "Baht",
          child: Container(
            color: Colors.white,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700], fontSize: 22),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 0, top: 6, bottom: 6, right: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            product.productname,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(global.language('Quantity:') ?? 'Quantity:' + ' ${NumberFormat('#,##0.00').format(product.totalquantity)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(
                                '${NumberFormat('#,##0.00').format(product.totalamount)} .-',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircularButton(IconData icon, VoidCallback onPressed, Color color) {
    return Semantics(
      button: true,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(12),
          backgroundColor: color,
        ),
        child: Icon(icon, color: Colors.white),
      ),
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
          button: true,
          label: global.language("Go back"),
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
          global.language('Overview'),
          style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          child: Column(children: [
            _buildHighlightCard(),
            _buildSalesSummary(),
            _buildReportSummary(),
            const SizedBox(
              height: 4,
            ),
            buildBarChart(),
          ]),
        ),
      ),
    );
  }
}

class BarChartDataModel {
  DateTime docDate;
  double value;

  BarChartDataModel({required this.docDate, required this.value});
}
