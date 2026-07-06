import 'dart:async';

import 'package:cocomerchant_lite/bloc/report/sale_daily_bloc.dart';
import 'package:cocomerchant_lite/bloc/report/sale_daily_list_bloc.dart';
import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/model/sale_daily_list_model.dart';
import 'package:cocomerchant_lite/model/sale_daily_model.dart';
import 'package:cocomerchant_lite/screens/menu/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cocomerchant_lite/global.dart' as global;

class BodyReceiveMoney extends StatefulWidget {
  const BodyReceiveMoney({super.key});

  @override
  BodyReceiveMoneyState createState() => BodyReceiveMoneyState();
}

class BodyReceiveMoneyState extends State<BodyReceiveMoney> {
  int barChartMode = 0;
  int rangeValue = 7;
  DateRange dateRangeSelected = DateRange.today;
  DateRangeModel dateRangeForBarChart = global.getDateRange(dateRange: DateRange.lastSevenDays);
  DateRangeModel dateRangeInput = global.getDateRange(dateRange: DateRange.today);
  Timer? _timer;
  String _selectedPeriod = global.language('Today');
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  List<SaleDailyListModel> saleDailyList = [];
  bool isLoadingMore = false;
  int currentPage = 0;
  bool hasMoreData = true;
  Timer? _searchTimer;
  String _searchQuery = '';
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
  final int pageSize = 10;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<String> get _periods => [
        global.language('Today'),
        global.language('Yesterday'),
        global.language('Last 7 Days'),
        global.language('This Week'),
        global.language('Last Week'),
        global.language('This Month'),
        global.language('Last Month'),
        global.language('This Year'),
        global.language('Last Year'),
        global.language('Custom'),
      ];

  void setSystemLanguageList() async {
    await global.setSystemLanguage(context);
  }

  @override
  void initState() {
    super.initState();
    setSystemLanguageList();
    saleDailyList = [];
    _updateDateRange(_selectedPeriod);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !isLoadingMore) {
        loadMoreData();
      }
    });

    _searchController.addListener(_onSearchChanged);

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      loadDataReceiveMoney(_startDate, _endDate);
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      loadData(_startDate, _endDate, reset: true);
    });

    setState(() {});
  }

  void loadDataReceiveMoney(DateTime startDate, DateTime endDate) {
    startDate = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    context.read<SaleDailyBloc>().add(SaleDailyLoadStart(
          startDateTime: startDate,
          endDateTime: endDate,
        ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchTimer?.isActive ?? false) {
      _searchTimer?.cancel();
    }
    _searchTimer = Timer(const Duration(seconds: 2), () {
      _searchQuery = _searchController.text;
      loadData(_startDate, _endDate, reset: true);
    });
  }

  void loadData(DateTime startDate, DateTime endDate, {bool reset = false}) {
    if (reset) {
      currentPage = 0;
      saleDailyList.clear();
    }

    startDate = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    context.read<SaleDailyListBloc>().add(SaleDailyListLoadStart(
          startDateTime: startDate,
          endDateTime: endDate,
          page: currentPage,
          pageSize: pageSize,
          searchQuery: _searchQuery,
        ));
  }

  void loadMoreData() {
    setState(() {
      isLoadingMore = true;
      hasMoreData = true;
      currentPage++;

      Future.delayed(const Duration(seconds: 5), () {
        setState(() {
          isLoadingMore = false;
          hasMoreData = false;
        });
      });
    });
    loadData(_startDate, _endDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: global.language('Back to menu'),
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
        title: Semantics(
          label: global.language('Receive Money'),
          header: true,
          child: Text(
            global.language('Receive Money'),
            style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        actions: [
          Semantics(
            label: global.language('Refresh data'),
            button: true,
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                loadData(_startDate, _endDate, reset: true);
                loadDataReceiveMoney(_startDate, _endDate);
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Fixed content
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildPeriodSelector(),
                _buildDateRangeDisplay(),
                _buildSalesSummary(),
                _buildSearchField(),
              ],
            ),
          ),
          // Scrollable content
          Expanded(
            child: _buildOrderItemList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemList() {
    return Semantics(
      label: global.language('Receive Money List'),
      child: BlocBuilder<SaleDailyListBloc, SaleDailyListState>(
        builder: (context, state) {
          if (state is SaleDailyListLoadSuccess) {
            if (state.data.isEmpty) {
              hasMoreData = false;
            } else {
              saleDailyList.addAll(state.data);
            }
            isLoadingMore = false;
          }
          if (saleDailyList.isNotEmpty) {
            return ListView.separated(
              controller: _scrollController,
              itemCount: saleDailyList.length + (isLoadingMore ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == saleDailyList.length) {
                  return _buildLoadingIndicator();
                }
                return _buildOrderItem(saleDailyList[index]);
              },
            );
          } else {
            return _buildEmptyState();
          }
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(child: hasMoreData ? const CircularProgressIndicator() : Container()),
    );
  }

  Widget _buildOrderItem(SaleDailyListModel order) {
    return Semantics(
      label:
          '${global.language('Receipt Number')} ${order.docno}, ${global.language('Date')} ${DateFormat('dd/MM/yyyy HH:mm').format(order.docdatetime)}, ${global.language('Total Amount')} ${NumberFormat('#,##0.00').format(order.totalamount)} ${global.language('THB')}',
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        child: ExpansionTileTheme(
          data: ExpansionTileThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
              side: BorderSide.none,
            ),
          ),
          child: ExpansionTile(
            title: Text(
              order.docno,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              DateFormat('dd/MM/yyyy HH:mm').format(order.docdatetime),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  NumberFormat('#,##0.00').format(order.totalamount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
            children: [_buildOrderDetails(order)],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetails(SaleDailyListModel order) {
    return Semantics(
      label: global.language('Receipt Details'),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(global.language('Total Payment'), order.sumpayamount),
            _buildInfoRow(global.language('Cash Payment'), order.paycashamount),
            _buildInfoRow(global.language('Cash Change'), order.paycashchange),
            _buildInfoRow(global.language('Rounding Adjustment'), order.roundamount),
            const SizedBox(height: 8),
            Text('${global.language('Other Payment Methods')}:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...order.paymentlist.map((payment) => _buildInfoRow(payment.description, payment.totalamount)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Semantics(
      label: global.language('No data found for receiving money'),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text(global.language('No data found'), style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Semantics(
      label: global.language('Search Document'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: global.language('Search Document'),
            contentPadding: const EdgeInsets.symmetric(vertical: 11.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            prefixIcon: const Icon(Icons.search),
          ),
        ),
      ),
    );
  }

  Widget _buildSalesSummary() {
    return BlocBuilder<SaleDailyBloc, SaleDailyState>(
      builder: (context, state) {
        if (state is SaleDailyLoadSuccess) {
          _saleModelModel = state.data.first;
        }
        return Semantics(
          label: global.language('Sales Summary'),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
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
                    Text(
                      '฿${NumberFormat('###,###,##0.00').format(_saleModelModel.totalamount)}',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.green[400]),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      margin: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(global.language("Cash Payment"), style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                          Text(NumberFormat('###,###,##0.00').format(_saleModelModel.totalpaycashamount), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    _buildReceiveMoneyList(_saleModelModel.paymentlist),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(global.language("Rounding Adjustment"), style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(description.isNotEmpty ? description : "-", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
          Text(NumberFormat('###,###,##0.00').format(amount), style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildReceiveMoneyList(List<SaleDailyPaymentModel> paymentList) {
    return Column(
      children: paymentList.map((payment) => _buildReceiveMoney(payment.description, payment.totalamount)).toList(),
    );
  }

  Widget _buildInfoRow(String label, double value) {
    return Semantics(
      label: '$label: ${NumberFormat('#,##0.00').format(value)} ${global.language('THB')}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(global.language(label)),
            Text(NumberFormat('#,##0.00').format(value), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Semantics(
      label: global.language('Select Period'),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedPeriod,
              isExpanded: true,
              items: _periods.map((String period) {
                return DropdownMenuItem<String>(
                  value: period,
                  child: Text(global.language(period)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedPeriod = newValue;
                    _updateDateRange(newValue);
                    loadData(_startDate, _endDate, reset: true);
                    loadDataReceiveMoney(_startDate, _endDate);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeDisplay() {
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    return Semantics(
      label: "${global.language('Selected Date Range:')} ${global.language('From')} ${formatter.format(_startDate)}${global.language('to')} ${formatter.format(_endDate)}",
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${global.language('From')}: ${formatter.format(_startDate)}',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
            Text(
              '${global.language('To')}: ${formatter.format(_endDate)}',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _updateDateRange(String period) {
    final now = DateTime.now();

    // Helper function to handle null cases
    bool matches(String original, String? translated) {
      return period == original || period == (translated ?? original);
    }

    switch (period) {
      case var _ when matches('Today', global.language('Today')):
        _startDate = now;
        _endDate = now;
        break;
      case var _ when matches('Yesterday', global.language('Yesterday')):
        _startDate = now.subtract(const Duration(days: 1));
        _endDate = now.subtract(const Duration(days: 1));
        break;
      case var _ when matches('Last 7 Days', global.language('Last 7 Days')):
        _startDate = now.subtract(const Duration(days: 6));
        _endDate = now;
        break;
      case var _ when matches('This Week', global.language('This Week')):
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = now;
        break;
      case var _ when matches('Last Week', global.language('Last Week')):
        _startDate = now.subtract(Duration(days: now.weekday + 6));
        _endDate = now.subtract(Duration(days: now.weekday));
        break;
      case var _ when matches('This Month', global.language('This Month')):
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case var _ when matches('Last Month', global.language('Last Month')):
        _startDate = DateTime(now.year, now.month - 1, 1);
        _endDate = DateTime(now.year, now.month, 0);
        break;
      case var _ when matches('This Year', global.language('This Year')):
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
        break;
      case var _ when matches('Last Year', global.language('Last Year')):
        _startDate = DateTime(now.year - 1, 1, 1);
        _endDate = DateTime(now.year - 1, 12, 31);
        break;
      case var _ when matches('Custom', global.language('Custom')):
        _showDateRangePicker();
        break;
      default:
        _startDate = now;
        _endDate = now;
    }
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        loadData(_startDate, _endDate, reset: true); // Load data when custom date range is selected
        loadDataReceiveMoney(_startDate, _endDate);
      });
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight || minHeight != oldDelegate.minHeight || child != oldDelegate.child;
  }
}
