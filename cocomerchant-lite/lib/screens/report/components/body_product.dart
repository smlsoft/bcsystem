import 'dart:async';
import 'package:cocomerchant_lite/bloc/report/product_status_bloc.dart';
import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/model/product_status_model.dart';
import 'package:cocomerchant_lite/screens/menu/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cocomerchant_lite/global.dart' as global;

class BodyProduct extends StatefulWidget {
  const BodyProduct({super.key});

  @override
  BodyProductState createState() => BodyProductState();
}

class BodyProductState extends State<BodyProduct> {
  List<ProductStatusModel> dataReport = [];
  DateRange dateRangeSelected = DateRange.today;
  DateRangeModel dateRangeForBarChart = global.getDateRange(dateRange: DateRange.lastSevenDays);
  DateRangeModel dateRangeInput = global.getDateRange(dateRange: DateRange.today);
  Timer? _timer;
  String _selectedPeriod = global.language('Today');
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  int _topN = 10;
  final List<int> _topOptions = [10, 20, 50, 100];
  final TextEditingController _customTopController = TextEditingController();

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
    dataReport = [];
    _updateDateRange(_selectedPeriod);
    loadData(_startDate, _endDate);

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      loadData(_startDate, _endDate);
    });
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void loadData(DateTime startDate, DateTime endDate) {
    startDate = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    context.read<ProductStatusBloc>().add(ProductStatusLoadStart(
          mode: 0,
          startDateTime: startDate,
          endDateTime: endDate,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            leading: Semantics(
              label: global.language('Back to menu') ?? 'Back to menu',
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
            pinned: true,
            title: Semantics(
              label: global.language('Top Products') ?? 'Top Products',
              header: true,
              child: Text(
                global.language('Top Products') ?? 'Top Products',
                style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              minHeight: 160.0,
              maxHeight: 160.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(0),
                    bottomRight: Radius.circular(0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 3),
                    child: Column(
                      children: [
                        _buildPeriodSelector(),
                        _buildDateRangeDisplay(),
                        _buildTopSelector(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildReportSummary(),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSelector() {
    return Semantics(
      label: global.language('Select Top Products'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  ..._topOptions.map((option) => ChoiceChip(
                        label: Text(global.language('Top') + option.toString()),
                        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        backgroundColor: Colors.grey[500],
                        selectedColor: kPrimaryColor,
                        elevation: 3,
                        checkmarkColor: Colors.white,
                        selected: _topN == option,
                        side: const BorderSide(color: Colors.transparent),
                        onSelected: (selected) {
                          if (selected) setState(() => _topN = option);
                        },
                      )),
                  ChoiceChip(
                    label: Text(global.language('Custom')),
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    selected: !_topOptions.contains(_topN) && _topN > 0,
                    backgroundColor: Colors.grey[500],
                    selectedColor: kPrimaryColor,
                    elevation: 3,
                    checkmarkColor: Colors.white,
                    side: const BorderSide(color: Colors.transparent),
                    onSelected: (selected) {
                      if (selected) _showCustomTopDialog();
                    },
                  ),
                  ChoiceChip(
                    label: Text(global.language('All')),
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    selected: _topN == -1,
                    backgroundColor: Colors.grey[500],
                    selectedColor: kPrimaryColor,
                    elevation: 3,
                    checkmarkColor: Colors.white,
                    side: const BorderSide(color: Colors.transparent),
                    onSelected: (selected) {
                      if (selected) setState(() => _topN = -1);
                    },
                  ),
                ],
              ),
            ),
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
                  child: Text(period),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedPeriod = newValue;
                    _updateDateRange(newValue);
                    loadData(_startDate, _endDate);
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
      label: global.language('Show Date Range'),
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

  Widget _buildReportSummary() {
    return Semantics(
      label: global.language('Product Report'),
      child: BlocBuilder<ProductStatusBloc, ProductStatusState>(
        builder: (context, state) {
          if (state is ProductStatusLoadSuccess) {
            dataReport = state.data;
          }
          return _buildProductList();
        },
      ),
    );
  }

  Widget _buildProductList() {
    final sortedProducts = dataReport..sort((a, b) => b.totalamount.compareTo(a.totalamount));

    int show = _topN == -1 ? sortedProducts.length : _topN;
    final displayedProducts = sortedProducts.take(show).toList();

    return Semantics(
      label: global.language('Product List'),
      child: ListView.separated(
        itemCount: displayedProducts.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 5),
        separatorBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Divider(height: 1, color: Colors.grey[300]),
        ),
        itemBuilder: (context, index) {
          final product = displayedProducts[index];
          return Semantics(
            label: 'Product ${index + 1}: ${product.productname}, Quantity: ${product.totalquantity}, Price: ${product.totalamount} THB',
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
                                Text(
                                  '${global.language('Quantity')}: ${NumberFormat('#,##0.00').format(product.totalquantity)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  '${NumberFormat('#,##0.00').format(product.totalamount)} ${global.language('THB')}',
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
      ),
    );
  }

  void _showCustomTopDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(global.language('Custom Top') ?? 'Custom Top'),
          content: TextField(
            controller: _customTopController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: global.language("Enter number") ?? "Enter number"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(global.language('Cancel') ?? 'Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(global.language('OK') ?? 'OK'),
              onPressed: () {
                setState(() {
                  _topN = int.tryParse(_customTopController.text) ?? 10;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _updateDateRange(String period) {
    final now = DateTime.now();

    // Helper function to handle null cases
    bool matches(String translated, String defaultEnglish) {
      return period == translated || period == defaultEnglish;
    }

    switch (period) {
      case var _ when matches(global.language('Today') ?? 'Today', 'Today'):
        _startDate = now;
        _endDate = now;
        break;
      case var _ when matches(global.language('Yesterday'), 'Yesterday'):
        _startDate = now.subtract(const Duration(days: 1));
        _endDate = now.subtract(const Duration(days: 1));
        break;
      case var _ when matches(global.language('Last 7 Days'), 'Last 7 Days'):
        _startDate = now.subtract(const Duration(days: 6));
        _endDate = now;
        break;
      case var _ when matches(global.language('This Week'), 'This Week'):
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = now;
        break;
      case var _ when matches(global.language('Last Week'), 'Last Week'):
        _startDate = now.subtract(Duration(days: now.weekday + 6));
        _endDate = now.subtract(Duration(days: now.weekday));
        break;
      case var _ when matches(global.language('This Month'), 'This Month'):
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case var _ when matches(global.language('Last Month'), 'Last Month'):
        _startDate = DateTime(now.year, now.month - 1, 1);
        _endDate = DateTime(now.year, now.month, 0);
        break;
      case var _ when matches(global.language('This Year'), 'This Year'):
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
        break;
      case var _ when matches(global.language('Last Year'), 'Last Year'):
        _startDate = DateTime(now.year - 1, 1, 1);
        _endDate = DateTime(now.year - 1, 12, 31);
        break;
      case var _ when matches(global.language('Custom'), 'Custom'):
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
        loadData(_startDate, _endDate); // Load data when custom date range is selected
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
