import 'package:dedecashier/flavors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/features/pos/presentation/bloc/sales_summary_bloc.dart';
import 'package:dedecashier/features/pos/presentation/models/shift_report_model.dart';
import 'package:dedecashier/model/objectbox/bill_struct.dart';
import 'package:dedecashier/model/objectbox/shift_struct.dart';
import 'package:dedecashier/db/bill_detail_helper.dart';
import 'package:dedecashier/util/printer.dart';
import 'dart:convert';
import 'package:dedecashier/global.dart' as global;
import 'package:intl/intl.dart';

class SaleSummaryPage extends StatefulWidget {
  const SaleSummaryPage({super.key});

  @override
  State<SaleSummaryPage> createState() => _SaleSummaryPageState();
}

class _SaleSummaryPageState extends State<SaleSummaryPage> with TickerProviderStateMixin {
  // ⭐ Theme Colors: MARINEPOS = น้ำเงินเข้ม, อื่นๆ = อิฐบ้านเชียง (Terracotta)
  static final Color _themeColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);
  static final MaterialColor _themeSwatch = (F.appFlavor == Flavor.MARINEPOS)
      ? const MaterialColor(0xFF005598, <int, Color>{
          50: Color(0xFFE6EFF5),
          100: Color(0xFFB3D1E6),
          200: Color(0xFF80B3D7),
          300: Color(0xFF4D95C8),
          400: Color(0xFF2677B9),
          500: Color(0xFF005598),
          600: Color(0xFF004A85),
          700: Color(0xFF003D6E),
          800: Color(0xFF003057),
          900: Color(0xFF002340),
        })
      : const MaterialColor(0xFFB5651D, <int, Color>{
          50: Color(0xFFFBF5F0),
          100: Color(0xFFF5E6D8),
          200: Color(0xFFEAC9AC),
          300: Color(0xFFDEAB7F),
          400: Color(0xFFD18D52),
          500: Color(0xFFB5651D),
          600: Color(0xFF9A5518),
          700: Color(0xFF7F4513),
          800: Color(0xFF64350E),
          900: Color(0xFF4A2509),
        });

  // === Tab 1: Sales Report Date ===
  DateTime? startDate;
  DateTime? endDate;
  String? selectedShiftId;

  // === Tab 2: Shift Reports Date ===
  DateTime? shiftStartDate;
  DateTime? shiftEndDate;

  // === Tab 3: Money Transfer Date ===
  DateTime? moneyTransferStartDate;
  DateTime? moneyTransferEndDate;

  // === Tab 4: Payment Reports Date ===
  DateTime? paymentStartDate;
  DateTime? paymentEndDate;

  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      global.playSound(sound: global.SoundEnum.buttonTing);
      // if (_tabController.index == 1) {
      //   // Shift Reports tab
      //   _loadShiftReports(context);
      // } else if (_tabController.index == 2) {
      //   // Money Transfer Reports tab
      //   _loadMoneyTransferReports(context);
      // } else if (_tabController.index == 3) {
      //   // Payment Reports tab
      //   _loadPaymentReports(context);
      // }
    });
    // Set default date range to today for all tabs
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Tab 1: Sales Report
    startDate = todayStart;
    endDate = todayEnd;

    // Tab 2: Shift Reports
    shiftStartDate = todayStart;
    shiftEndDate = todayEnd;

    // Tab 3: Money Transfer
    moneyTransferStartDate = todayStart;
    moneyTransferEndDate = todayEnd;

    // Tab 4: Payment Reports
    paymentStartDate = todayStart;
    paymentEndDate = todayEnd;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SalesSummaryBloc()..add(LoadSalesSummary(startDate: startDate, endDate: endDate, shiftId: selectedShiftId)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(global.language("sale_summary")),
          backgroundColor: _themeColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: const Icon(Icons.receipt_long), text: global.language("sales_report")),
              Tab(icon: const Icon(Icons.schedule), text: global.language("shift_reports")),
              Tab(icon: const Icon(Icons.money_off), text: global.language("money_transfer_list")),
              Tab(icon: const Icon(Icons.payments), text: global.language("payment_reports")),
            ],
          ),
        ),
        body: BlocBuilder<SalesSummaryBloc, SalesSummaryState>(
          builder: (context, state) {
            return TabBarView(
              controller: _tabController,
              children: [_buildSalesReportTab(context, state), _buildShiftReportsTab(context, state), _buildMoneyTransferTab(context, state), _buildPaymentReportsTab(context, state)],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, SalesSummaryState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;
    final isMobile = screenWidth <= 600;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_themeSwatch[50]!, _themeSwatch[100]!], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border(bottom: BorderSide(color: _themeSwatch[200]!, width: 1)),
      ),
      child: isMobile ? _buildMobileFilterLayout(context, state) : _buildDesktopFilterLayout(context, state, isTablet),
    );
  }

  Widget _buildMobileFilterLayout(BuildContext context, SalesSummaryState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildModernDatePickerField(label: global.language("start_date"), date: startDate, onTap: () => _selectStartDate(context)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildModernDatePickerField(label: global.language("end_date"), date: endDate, onTap: () => _selectEndDate(context)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(flex: 3, child: _buildModernShiftDropdown(context, state)),
            const SizedBox(width: 8),
            _buildModernActionButton(onPressed: () => _applyFilters(context), icon: Icons.search, backgroundColor: _themeSwatch, tooltip: global.language("search")),
            const SizedBox(width: 8),
            _buildModernActionButton(onPressed: () => _clearFilters(context), icon: Icons.clear, backgroundColor: Colors.grey, tooltip: global.language("clear")),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopFilterLayout(BuildContext context, SalesSummaryState state, bool isTablet) {
    return Row(
      children: [
        Expanded(
          flex: isTablet ? 2 : 3,
          child: _buildModernDatePickerField(label: global.language("start_date"), date: startDate, onTap: () => _selectStartDate(context)),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: isTablet ? 2 : 3,
          child: _buildModernDatePickerField(label: global.language("end_date"), date: endDate, onTap: () => _selectEndDate(context)),
        ),
        const SizedBox(width: 12),
        Expanded(flex: isTablet ? 3 : 4, child: _buildModernShiftDropdown(context, state)),
        const SizedBox(width: 12),
        _buildModernActionButton(onPressed: () => _applyFilters(context), icon: Icons.search, backgroundColor: _themeSwatch, tooltip: global.language("search")),
        const SizedBox(width: 8),
        _buildModernActionButton(onPressed: () => _clearFilters(context), icon: Icons.clear, backgroundColor: Colors.grey, tooltip: global.language("clear")),
      ],
    );
  }

  Widget _buildContent(BuildContext context, SalesSummaryState state) {
    // ⭐ Tab 1: Sales Report - ใช้ flags แทน type checking
    if (state.isLoadingSalesReport) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.errorMessage!.isNotEmpty && !state.isSalesReportLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => _applyFilters(context), child: Text(global.language("retry"))),
          ],
        ),
      );
    }

    if (state.isSalesReportLoaded) {
      return Column(
        children: [
          _buildSummaryCards(state),
          Expanded(child: _buildSalesDataList(state)),
        ],
      );
    }

    return const Center(child: Text('No data available'));
  }

  // ⭐ แก้ไข: ใช้ SalesSummaryState แทน SalesSummaryLoaded
  Widget _buildSummaryCards(SalesSummaryState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 12),
      child: isMobile
          ? Column(
              children: [
                _buildModernSummaryCard(
                  title: global.language("total_sales"),
                  value: '${global.moneyFormatAndDot.format(state.totalAmount)} ',
                  color: Colors.green,
                  icon: Icons.attach_money,
                  isFullWidth: true,
                ),
                const SizedBox(height: 8),
                _buildModernSummaryCard(title: global.language("total_transactions"), value: state.totalTransactions.toString(), color: _themeSwatch, icon: Icons.receipt_long, isFullWidth: true),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _buildModernSummaryCard(
                    title: global.language("total_sales"),
                    value: '${global.moneyFormatAndDot.format(state.totalAmount)} ',
                    color: Colors.green,
                    icon: Icons.attach_money,
                    isFullWidth: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModernSummaryCard(
                    title: global.language("total_transactions"),
                    value: state.totalTransactions.toString(),
                    color: _themeSwatch,
                    icon: Icons.receipt_long,
                    isFullWidth: false,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildModernSummaryCard({required String title, required String value, required Color color, required IconData icon, required bool isFullWidth}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: isFullWidth || isMobile
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontSize: isMobile ? 12 : 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold, color: color),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }

  // ⭐ แก้ไข: ใช้ SalesSummaryState แทน SalesSummaryLoaded
  Widget _buildSalesDataList(SalesSummaryState state) {
    if (state.salesData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No sales data found'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.salesData.length,
      itemBuilder: (context, index) {
        final sale = state.salesData[index];
        return _buildSalesItem(sale);
      },
    );
  }

  Widget _buildSalesItem(BillObjectBoxStruct sale) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 4),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: InkWell(
          onTap: () => _showBillDetails(sale),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sale.is_cancel ? Colors.red.shade200 : Colors.green.shade200, width: 1.5),
            ),
            child: isMobile ? _buildMobileSalesItemLayout(sale) : _buildDesktopSalesItemLayout(sale),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSalesItemLayout(BillObjectBoxStruct sale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: sale.is_cancel ? Colors.red.shade100 : Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
              child: Icon(sale.is_cancel ? Icons.cancel : Icons.check_circle, color: sale.is_cancel ? Colors.red : Colors.green, size: 20),
            ),
            const SizedBox(width: 8),
            // Sync status indicator
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: sale.is_sync ? _themeSwatch[100]! : Colors.orange.shade100, borderRadius: BorderRadius.circular(6)),
              child: Icon(sale.is_sync ? Icons.cloud_done : Icons.cloud_off, color: sale.is_sync ? _themeSwatch : Colors.orange, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.doc_number,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: sale.is_cancel ? TextDecoration.lineThrough : null, color: sale.is_cancel ? Colors.red : Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text('${global.language("customer")}: ${sale.customer_name.isNotEmpty ? sale.customer_name : global.language("walk_in")}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${global.moneyFormatAndDot.format(sale.total_amount)} ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: sale.is_cancel ? Colors.red : Colors.green, decoration: sale.is_cancel ? TextDecoration.lineThrough : null),
                ),
                Text('${global.language("qty")}: ${sale.total_qty.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text('${global.language("date")}: ${dateTimeFormat.format(sale.date_time)}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text('${global.language("sale")}: ${sale.cashier_name}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ),
            // Sync status text
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            //   decoration: BoxDecoration(
            //     color: sale.is_sync ? _themeSwatch[50]! : Colors.orange.shade50,
            //     borderRadius: BorderRadius.circular(4),
            //     border: Border.all(
            //       color: sale.is_sync ? _themeSwatch[200]! : Colors.orange.shade200,
            //       width: 1,
            //     ),
            //   ),
            //   child: Text(
            //     sale.is_sync ? global.language("synced") : global.language("not_synced"),
            //     style: TextStyle(
            //       fontSize: 10,
            //       color: sale.is_sync ? _themeSwatch[700]! : Colors.orange.shade700,
            //       fontWeight: FontWeight.w500,
            //     ),
            //   ),
            // ),
            if (sale.detail_total_discount > 0) ...[
              const SizedBox(width: 8),
              Text(
                '${global.language("discount")} ${sale.detail_discount_formula} : ${sale.detail_total_discount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 11, color: Colors.orange[600], fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopSalesItemLayout(BillObjectBoxStruct sale) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: sale.is_cancel ? Colors.red.shade100 : Colors.green.shade100, borderRadius: BorderRadius.circular(10)),
          child: Icon(sale.is_cancel ? Icons.cancel : Icons.check_circle, color: sale.is_cancel ? Colors.red : Colors.green, size: 24),
        ),
        const SizedBox(width: 12),
        // Sync status indicator
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: sale.is_sync ? _themeSwatch[100]! : Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
          child: Icon(sale.is_sync ? Icons.cloud_done : Icons.cloud_off, color: sale.is_sync ? _themeSwatch : Colors.orange, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sale.doc_number,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: sale.is_cancel ? TextDecoration.lineThrough : null, color: sale.is_cancel ? Colors.red : Colors.black87),
              ),
              const SizedBox(height: 4),
              Text('${global.language("customer")}: ${sale.customer_name.isNotEmpty ? sale.customer_name : global.language("walk_in")}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${global.language("date")}: ${dateTimeFormat.format(sale.date_time)}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text('${global.language("sale")}: ${sale.cashier_name}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${global.moneyFormatAndDot.format(sale.total_amount)} ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: sale.is_cancel ? Colors.red : Colors.green, decoration: sale.is_cancel ? TextDecoration.lineThrough : null),
              ),
              const SizedBox(height: 4),
              Text('${global.language("qty")}: ${sale.total_qty.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 4),
              // Sync status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sale.is_sync ? _themeSwatch[50]! : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: sale.is_sync ? _themeSwatch[200]! : Colors.orange.shade200, width: 1),
                ),
                child: Text(
                  sale.is_sync ? global.language("synced") : global.language("not_synced"),
                  style: TextStyle(fontSize: 11, color: sale.is_sync ? _themeSwatch[700]! : Colors.orange.shade700, fontWeight: FontWeight.w500),
                ),
              ),
              if (sale.detail_total_discount > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '${global.language("discount")} ${sale.detail_discount_formula} : ${sale.detail_total_discount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, color: Colors.orange[600], fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showBillDetails(BillObjectBoxStruct sale) {
    global.playSound(sound: global.SoundEnum.buttonTing);
    final billDetailHelper = BillDetailHelper();
    final billDetails = billDetailHelper.selectByDocNumber(docNumber: sale.doc_number);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(maxWidth: isMobile ? screenWidth * 0.95 : 600, maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modern Header
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  decoration: BoxDecoration(
                    color: _themeColor,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.white, size: isMobile ? 24 : 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              global.language("bill_detail"),
                              style: TextStyle(color: Colors.white, fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              sale.doc_number,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: isMobile ? 14 : 16),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          global.playSound(sound: global.SoundEnum.buttonTing);
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close, color: Colors.white),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    child: billDetails.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(global.language("no_data_found"), style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: billDetails.length,
                            itemBuilder: (context, index) {
                              return _buildModernBillDetailItem(billDetails[index], isMobile);
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernBillDetailItem(dynamic detail, bool isMobile) {
    // Parse extra_json for additional options
    List<BillDetailExtraObjectBoxStruct> extraOptions = [];
    if (detail.extra_json.isNotEmpty) {
      try {
        final jsonData = json.decode(detail.extra_json);
        if (jsonData is List) {
          extraOptions = jsonData.map((item) => BillDetailExtraObjectBoxStruct.fromJson(item)).toList();
        }
      } catch (e) {
        // Handle JSON parsing error silently
      }
    }

    // Calculate total amount including extra options
    double extraOptionsTotal = extraOptions.fold(0.0, (sum, option) => sum + option.total_amount);
    double grandTotal = detail.total_amount + extraOptionsTotal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Name
            Text(
              global.getNameFromJsonLanguage(detail.item_name, global.userScreenLanguage),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 18, color: Colors.black87),
            ),
            const SizedBox(height: 8),

            // Item details grid
            if (isMobile) _buildMobileItemDetails(detail) else _buildDesktopItemDetails(detail),

            // Grand total for items with extra options
            if (extraOptions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${global.language("total_including_options")}:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: isMobile ? 14 : 15),
                    ),
                    Text(
                      global.moneyFormatAndDot.format(grandTotal),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 18, color: Colors.green.shade700),
                    ),
                  ],
                ),
              ),
            ],

            // Item code if available
            if (detail.item_code.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  '${global.language("item_code")}: ${detail.item_code}',
                  style: TextStyle(fontSize: isMobile ? 11 : 12, color: Colors.grey[600], fontFamily: 'monospace'),
                ),
              ),
            ],

            // Additional options
            if (extraOptions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _themeSwatch[50]!,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _themeSwatch[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.add_circle_outline, size: 16, color: _themeSwatch[600]!),
                        const SizedBox(width: 6),
                        Text(
                          '${global.language("additional_options")}:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 14, color: _themeSwatch[700]!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...extraOptions.map(
                      (option) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '• ${global.getNameFromJsonLanguage(option.item_name, global.userScreenLanguage)}',
                                style: TextStyle(fontSize: isMobile ? 12 : 13, color: Colors.grey[700]),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              global.moneyFormatAndDot.format(option.total_amount),
                              style: TextStyle(fontSize: isMobile ? 12 : 13, fontWeight: FontWeight.w600, color: _themeSwatch[600]!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMobileItemDetails(dynamic detail) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${global.language("qty")}: ${global.moneyFormat.format(detail.qty)}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
            Text('${global.language("unit")}: ${global.getNameFromJsonLanguage(detail.unit_name, global.userScreenLanguage)}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${global.language("price")}: ${global.moneyFormat.format(detail.price)}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
              child: Text(
                '${global.language("total")}: ${global.moneyFormatAndDot.format(detail.total_amount)}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange.shade700),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopItemDetails(dynamic detail) {
    return Row(
      children: [
        Expanded(
          child: Text('${global.language("qty")}: ${global.moneyFormat.format(detail.qty)}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ),
        Expanded(
          child: Text('${global.language("unit")}: ${global.getNameFromJsonLanguage(detail.unit_name, global.userScreenLanguage)}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ),
        Expanded(
          child: Text('${global.language("price")}: ${global.moneyFormat.format(detail.price)}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(6)),
          child: Text(
            '${global.language("total")}: ${global.moneyFormatAndDot.format(detail.total_amount)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange.shade700),
          ),
        ),
      ],
    );
  }

  // ========== Tab 1: Sales Report Date Pickers ==========
  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(context: context, initialDate: startDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null) {
      setState(() {
        startDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(context: context, initialDate: endDate ?? DateTime.now(), firstDate: startDate ?? DateTime(2020), lastDate: DateTime.now());
    if (picked != null) {
      setState(() {
        endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  void _applyFilters(BuildContext context) {
    global.playSound(sound: global.SoundEnum.buttonTing);
    context.read<SalesSummaryBloc>().add(LoadSalesSummary(startDate: startDate, endDate: endDate, shiftId: selectedShiftId));
  }

  void _clearFilters(BuildContext context) {
    global.playSound(sound: global.SoundEnum.buttonTing);
    setState(() {
      final now = DateTime.now();
      startDate = DateTime(now.year, now.month, now.day);
      endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      selectedShiftId = null;
    });
    context.read<SalesSummaryBloc>().add(const ClearSalesFilters());
  }

  // ========== Tab 2: Shift Reports Date Pickers ==========
  Future<void> _selectShiftStartDate(BuildContext context) async {
    final picked = await showDatePicker(context: context, initialDate: shiftStartDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null) {
      setState(() {
        shiftStartDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _selectShiftEndDate(BuildContext context) async {
    final picked = await showDatePicker(context: context, initialDate: shiftEndDate ?? DateTime.now(), firstDate: shiftStartDate ?? DateTime(2020), lastDate: DateTime.now());
    if (picked != null) {
      setState(() {
        shiftEndDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  // ========== Tab 3: Money Transfer Date Pickers ==========
  Future<void> _selectMoneyTransferStartDate(BuildContext context) async {
    final picked = await showDatePicker(context: context, initialDate: moneyTransferStartDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null) {
      setState(() {
        moneyTransferStartDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _selectMoneyTransferEndDate(BuildContext context) async {
    final picked = await showDatePicker(context: context, initialDate: moneyTransferEndDate ?? DateTime.now(), firstDate: moneyTransferStartDate ?? DateTime(2020), lastDate: DateTime.now());
    if (picked != null) {
      setState(() {
        moneyTransferEndDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  // ========== Tab 4: Payment Reports Date Pickers ==========
  Future<void> _selectPaymentStartDate(BuildContext context) async {
    final picked = await showDatePicker(context: context, initialDate: paymentStartDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
    if (picked != null) {
      setState(() {
        paymentStartDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _selectPaymentEndDate(BuildContext context) async {
    final picked = await showDatePicker(context: context, initialDate: paymentEndDate ?? DateTime.now(), firstDate: paymentStartDate ?? DateTime(2020), lastDate: DateTime.now());
    if (picked != null) {
      setState(() {
        paymentEndDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  Widget _buildSalesReportTab(BuildContext context, SalesSummaryState state) {
    return Column(
      children: [
        _buildFilterSection(context, state),
        Expanded(child: _buildContent(context, state)),
      ],
    );
  }

  Widget _buildShiftReportsTab(BuildContext context, SalesSummaryState state) {
    return Column(
      children: [
        _buildShiftReportFilters(context),
        Expanded(child: _buildShiftReportContent(context, state)),
      ],
    );
  }

  Widget _buildShiftReportFilters(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_themeSwatch[50]!, _themeSwatch[100]!], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border(bottom: BorderSide(color: _themeSwatch[200]!, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModernDatePickerField(label: global.language("start_date"), date: shiftStartDate, onTap: () => _selectShiftStartDate(context)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildModernDatePickerField(label: global.language("end_date"), date: shiftEndDate, onTap: () => _selectShiftEndDate(context)),
          ),
          const SizedBox(width: 12),
          Material(
            color: _themeSwatch,
            borderRadius: BorderRadius.circular(8),
            elevation: 2,
            child: InkWell(
              onTap: () => _loadShiftReports(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, size: 18, color: Colors.white),
                    if (!isMobile) ...[
                      const SizedBox(width: 6),
                      Text(
                        global.language("load_reports"),
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftReportContent(BuildContext context, SalesSummaryState state) {
    // ⭐ Tab 2: Shift Reports - ใช้ flags แทน type checking
    if (state.isLoadingShiftReports) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.errorMessage!.isNotEmpty && !state.isShiftReportsLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => _loadShiftReports(context), child: Text(global.language("retry"))),
          ],
        ),
      );
    }

    if (state.isShiftReportsLoaded) {
      return _buildShiftReportsList(state.shiftReports);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(global.language("no_shift_reports")),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => _loadShiftReports(context), child: Text(global.language("load_reports"))),
        ],
      ),
    );
  }

  Widget _buildShiftReportsList(List<ShiftReportModel> shiftReports) {
    if (shiftReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(global.language("no_shift_reports_found")),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: shiftReports.length,
      itemBuilder: (context, index) {
        final report = shiftReports[index];
        return _buildShiftReportCard(report);
      },
    );
  }

  Widget _buildShiftReportCard(ShiftReportModel report) {
    final totalSales = report.totalCash + report.totalQr + report.totalCreditCard + report.totalTransfer + report.totalCheque + report.totalCoupon + report.totalCredit + report.totalPoint;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: const Icon(Icons.schedule, color: Colors.green, size: 20),
        title: Text(
          '${report.openShift.username} ${dateTimeFormat.format(report.openShift.docdate)} - ${dateTimeFormat.format(report.closeShift.docdate)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${global.language("total_sales")}: ${global.moneyFormatAndDot.format(totalSales)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                Text(
                  '${global.language("total_transactions")}: ${report.totalTransactions}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
        children: [
          // Payment Methods
          _buildSectionTitle(global.language("payment_methods")),
          const SizedBox(height: 8),
          _buildPaymentMethodsGrid(report),
          const SizedBox(height: 16),
          // Drawer Calculation
          _buildSectionTitle(global.language("drawer_calculation")),
          const SizedBox(height: 8),
          _buildDrawerCalculation(report),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black87),
      ),
    );
  }

  Widget _buildPaymentMethodsGrid(ShiftReportModel report) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildPaymentMethodRow(global.language("cash"), report.totalCash, Colors.green),
          _buildPaymentMethodRow(global.language("qr_code"), report.totalQr, Colors.purple),
          _buildPaymentMethodRow(global.language("credit_card"), report.totalCreditCard, Colors.orange),
          _buildPaymentMethodRow(global.language("money_transfer"), report.totalTransfer, _themeSwatch),
          _buildPaymentMethodRow(global.language("cheque"), report.totalCheque, Colors.brown),
          _buildPaymentMethodRow(global.language("coupon"), report.totalCoupon, Colors.pink),
          if (report.totalCredit > 0) _buildPaymentMethodRow(global.language("credit"), report.totalCredit, Colors.red),
          _buildPaymentMethodRow(global.language("point_payment"), report.totalPoint, Colors.amber),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
            ],
          ),
          Text(
            '${global.moneyFormatAndDot.format(amount)} ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerCalculation(ShiftReportModel report) {
    // Calculate difference between expected and actual amount
    final difference = (report.drawerAmount + report.totalChange) - report.closeShift.amount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                global.language("drawer_calculation"),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _themeSwatch),
              ),
              Material(
                color: Colors.green,
                borderRadius: BorderRadius.circular(6),
                elevation: 1,
                child: InkWell(
                  onTap: () => _printShiftReport(report),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.print, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          global.language("print"),
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Opening Amount
          // _buildDrawerCalculationRow(
          //   label: global.language("opening_amount"),
          //   amount: report.openShift.amount,
          //   isPositive: true,
          //   showOperator: false,
          // ),

          // Added Money (if any)
          if (report.addedMoney > 0) _buildDrawerCalculationRow(label: global.language("added_money"), amount: report.addedMoney, isPositive: true, showOperator: true),

          // Withdrawn Money (if any)
          if (report.withdrawnMoney > 0) _buildDrawerCalculationRow(label: global.language("withdrawn_money"), amount: report.withdrawnMoney, isPositive: false, showOperator: true),

          // Cash Sales
          _buildDrawerCalculationRow(label: global.language("cash_sales"), amount: report.totalCash + report.totalChange, isPositive: true, showOperator: true),

          // Change Given (if any)
          if (report.totalChange > 0) _buildDrawerCalculationRow(label: global.language("change_given"), amount: report.totalChange, isPositive: false, showOperator: true),

          // Divider
          const Divider(height: 16, thickness: 1),

          // Expected Drawer Amount
          _buildDrawerCalculationRow(label: global.language("expected_drawer"), amount: report.drawerAmount + report.totalChange, isPositive: true, showOperator: false, isTotal: true),

          // Actual Closing Amount
          // _buildDrawerCalculationRow(
          //   label: global.language("closing_shift_amount"),
          //   amount: report.closeShift.amount,
          //   isPositive: true,
          //   showOperator: false,
          //   isSubtitle: true,
          // ),

          // // Difference
          // _buildDrawerCalculationRow(
          //   label: global.language("difference"),
          //   amount: difference.abs(),
          //   isPositive: difference >= 0,
          //   showOperator: false,
          //   isDifference: true,
          //   differenceValue: difference,
          // ),
        ],
      ),
    );
  }

  Widget _buildDrawerCalculationRow({
    required String label,
    required double amount,
    required bool isPositive,
    required bool showOperator,
    bool isTotal = false,
    bool isSubtitle = false,
    bool isDifference = false,
    double? differenceValue,
  }) {
    final operator = showOperator ? (isPositive ? "+ " : "- ") : "";
    final amountText = "$operator${global.moneyFormat.format(amount)} ${global.language("money_symbol")}";

    Color textColor = Colors.black87;
    FontWeight fontWeight = FontWeight.normal;

    if (isTotal) {
      textColor = _themeSwatch[700]!;
      fontWeight = FontWeight.bold;
    } else if (isSubtitle) {
      textColor = Colors.grey.shade600;
      fontWeight = FontWeight.w500;
    } else if (isDifference) {
      if (differenceValue != null) {
        textColor = differenceValue >= 0 ? Colors.green.shade700 : Colors.red.shade700;
        fontWeight = FontWeight.bold;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: fontWeight, color: textColor),
            ),
          ),
          Text(
            amountText,
            style: TextStyle(fontSize: 12, fontWeight: fontWeight, color: textColor),
          ),
        ],
      ),
    );
  }

  void _loadShiftReports(BuildContext context) {
    global.playSound(sound: global.SoundEnum.buttonTing);
    context.read<SalesSummaryBloc>().add(LoadShiftReports(startDate: shiftStartDate, endDate: shiftEndDate));
  }

  void _loadMoneyTransferReports(BuildContext context) {
    global.playSound(sound: global.SoundEnum.buttonTing);
    context.read<SalesSummaryBloc>().add(LoadMoneyTransferReports(startDate: moneyTransferStartDate, endDate: moneyTransferEndDate));
  }

  Widget _buildModernDatePickerField({required String label, required DateTime? date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _themeSwatch[200]!, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: _themeSwatch[600]!, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    date != null ? dateFormat.format(date) : global.language("select_date"),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.calendar_today, color: _themeSwatch[600]!, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernShiftDropdown(BuildContext context, SalesSummaryState state) {
    // ⭐ ใช้ state โดยตรง (ไม่ต้อง cast แล้ว)
    List<ShiftObjectBoxStruct> shifts = state.shifts;
    Map<String, ShiftObjectBoxStruct> shiftCloseMap = state.shiftCloseMap;

    final validShiftIds = shifts.map((shift) => shift.guidfixed).toSet();
    if (selectedShiftId != null && !validShiftIds.contains(selectedShiftId)) {
      selectedShiftId = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _themeSwatch[200]!, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedShiftId,
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
          hint: Text(global.language("select_shift"), style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          icon: Icon(Icons.keyboard_arrow_down, color: _themeSwatch[600]!),
          items: [
            DropdownMenuItem<String>(value: null, child: Text(global.language("all_shifts"), style: const TextStyle(fontSize: 13))),
            ...shifts.map((shift) {
              final key = '${shift.docno}_${shift.posid}';
              final closeShift = shiftCloseMap[key];
              String displayText;
              if (closeShift != null) {
                displayText = '${shift.username} - ${DateFormat('dd/MM HH:mm').format(shift.docdate)}';
              } else {
                displayText = '${shift.username} - ${DateFormat('dd/MM HH:mm').format(shift.docdate)} (${global.language("shift_open")})';
              }

              return DropdownMenuItem<String>(
                value: shift.guidfixed,
                child: Text(displayText, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              selectedShiftId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildModernActionButton({required VoidCallback onPressed, required IconData icon, required Color backgroundColor, required String tooltip}) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        elevation: 2,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildMoneyTransferTab(BuildContext context, SalesSummaryState state) {
    return Column(
      children: [
        _buildMoneyTransferFilters(context),
        Expanded(child: _buildMoneyTransferContent(context, state)),
      ],
    );
  }

  Widget _buildMoneyTransferFilters(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange.shade50, Colors.orange.shade100], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border(bottom: BorderSide(color: Colors.orange.shade200, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModernDatePickerField(label: global.language("start_date"), date: moneyTransferStartDate, onTap: () => _selectMoneyTransferStartDate(context)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildModernDatePickerField(label: global.language("end_date"), date: moneyTransferEndDate, onTap: () => _selectMoneyTransferEndDate(context)),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(8),
            elevation: 2,
            child: InkWell(
              onTap: () => _loadMoneyTransferReports(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, size: 18, color: Colors.white),
                    if (!isMobile) ...[
                      const SizedBox(width: 6),
                      Text(
                        global.language("load_reports"),
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyTransferContent(BuildContext context, SalesSummaryState state) {
    // ⭐ Tab 3: Money Transfer - ใช้ flags แทน type checking
    if (state.isLoadingMoneyTransfer) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.errorMessage!.isNotEmpty && !state.isMoneyTransferLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => _loadMoneyTransferReports(context), child: Text(global.language("retry"))),
          ],
        ),
      );
    }

    if (state.isMoneyTransferLoaded) {
      return _buildMoneyTransferList(state.moneyTransferReports);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.money_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(global.language("no_money_transfer_records")),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => _loadMoneyTransferReports(context), child: Text(global.language("load_reports"))),
        ],
      ),
    );
  }

  Widget _buildMoneyTransferList(List<ShiftObjectBoxStruct> moneyTransferReports) {
    if (moneyTransferReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(global.language("no_money_transfer_found_in_period")),
          ],
        ),
      );
    }

    // Calculate total amount
    double totalAmount = moneyTransferReports.fold(0.0, (sum, report) => sum + report.amount);

    return Column(
      children: [
        // Summary card
        Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          global.language("money_transfer_summary"),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                        const SizedBox(height: 8),
                        Text('${global.language("total_records")}: ${moneyTransferReports.length}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        Text(
                          '${global.language("total_amount")}: ${NumberFormat('#,##0.00').format(totalAmount)} ${global.language("money_symbol")}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                    elevation: 2,
                    child: InkWell(
                      onTap: () => _printMoneyTransferReport(moneyTransferReports),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.print, size: 18, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              global.language("print"),
                              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // List of money transfer records
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: moneyTransferReports.length,
            itemBuilder: (context, index) {
              final report = moneyTransferReports[index];
              return _buildMoneyTransferCard(report);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoneyTransferCard(ShiftObjectBoxStruct report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.money_off, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(global.language("money_transfer_list"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${global.language("user")}: ${report.username}', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  Text('${global.language("date")}: ${dateTimeFormat.format(report.docdate)}', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  if (report.remark.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${global.language("remark")}: ${report.remark}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat('#,##0.00').format(report.amount),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                Text(global.language("money_symbol"), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _printMoneyTransferReport(List<ShiftObjectBoxStruct> moneyTransferReports) {
    global.playSound(sound: global.SoundEnum.buttonTing);
    if (moneyTransferReports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(global.language("no_money_transfer_to_print")), backgroundColor: Colors.orange));
      return;
    }

    try {
      // ใช้ฟังก์ชันพิมพ์รายการใหม่แทน
      printMoneyTransferReportList(moneyTransferReports: moneyTransferReports, startDate: moneyTransferStartDate ?? DateTime.now(), endDate: moneyTransferEndDate ?? DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(global.language("printing_money_transfer_report")), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${global.language("print_error")}: $e'), backgroundColor: Colors.red));
    }
  }

  void _loadPaymentReports(BuildContext context) {
    global.playSound(sound: global.SoundEnum.buttonTing);
    context.read<SalesSummaryBloc>().add(SalesSummaryEvent.loadPaymentReports(startDate: paymentStartDate, endDate: paymentEndDate));
  }

  Widget _buildPaymentReportsTab(BuildContext context, SalesSummaryState state) {
    return Column(
      children: [
        _buildPaymentReportFilters(context),
        Expanded(child: _buildPaymentReportContent(context, state)),
      ],
    );
  }

  Widget _buildPaymentReportFilters(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade50, Colors.green.shade100], begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border(bottom: BorderSide(color: Colors.green.shade200, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModernDatePickerField(label: global.language("start_date"), date: paymentStartDate, onTap: () => _selectPaymentStartDate(context)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildModernDatePickerField(label: global.language("end_date"), date: paymentEndDate, onTap: () => _selectPaymentEndDate(context)),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
            elevation: 2,
            child: InkWell(
              onTap: () => _loadPaymentReports(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, size: 18, color: Colors.white),
                    if (!isMobile) ...[
                      const SizedBox(width: 6),
                      Text(
                        global.language("load_reports"),
                        style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentReportContent(BuildContext context, SalesSummaryState state) {
    // ⭐ Tab 4: Payment Reports - ใช้ flags แทน type checking
    if (state.isLoadingPaymentReports) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.errorMessage!.isNotEmpty && !state.isPaymentReportsLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => _loadPaymentReports(context), child: Text(global.language("retry"))),
          ],
        ),
      );
    }

    if (state.isPaymentReportsLoaded) {
      return _buildSalesTransactionsList(state.salesTransactions);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.payments, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(global.language("no_payment_reports")),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => _loadPaymentReports(context), child: Text(global.language("load_reports"))),
        ],
      ),
    );
  }

  Widget _buildPaymentReportsList(List<ShiftReportModel> paymentReports) {
    if (paymentReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(global.language("no_payment_reports_found_in_period")),
          ],
        ),
      );
    } // Calculate totals from all payment reports
    double totalCash = 0;
    double totalQr = 0;
    double totalCreditCard = 0;
    double totalTransfer = 0;
    double totalCheque = 0;
    double totalCoupon = 0;
    double totalCredit = 0;
    double totalPoint = 0;
    int totalTransactions = 0;

    for (final report in paymentReports) {
      totalCash += report.totalCash;
      totalQr += report.totalQr;
      totalCreditCard += report.totalCreditCard;
      totalTransfer += report.totalTransfer;
      totalCheque += report.totalCheque;
      totalCoupon += report.totalCoupon;
      totalCredit += report.totalCredit;
      totalPoint += report.totalPoint;
      totalTransactions += report.totalTransactions;
    }

    double grandTotal = totalCash + totalQr + totalCreditCard + totalTransfer + totalCheque + totalCoupon + totalCredit + totalPoint;

    return Column(
      children: [
        // Summary card
        Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          global.language("payment_summary"),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 8),
                        Text('${global.language("total_amount")}: ${NumberFormat('#,##0.00').format(grandTotal)} ฿', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('${global.language("total_transactions")}: $totalTransactions', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        Text('${global.language("total_records")}: ${paymentReports.length} ${global.language("shifts")}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                    elevation: 2,
                    child: InkWell(
                      onTap: () => _printPaymentSummaryReport(
                        totalCash: totalCash,
                        totalQr: totalQr,
                        totalCreditCard: totalCreditCard,
                        totalTransfer: totalTransfer,
                        totalCheque: totalCheque,
                        totalCoupon: totalCoupon,
                        totalCredit: totalCredit,
                        grandTotal: grandTotal,
                        totalTransactions: totalTransactions,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.print, size: 18, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              global.language("print"),
                              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Payment method summary grid
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _buildPaymentMethodsTotalsGrid(
            totalCash: totalCash,
            totalQr: totalQr,
            totalCreditCard: totalCreditCard,
            totalTransfer: totalTransfer,
            totalCheque: totalCheque,
            totalCoupon: totalCoupon,
            totalCredit: totalCredit,
          ),
        ),
        // List of shift reports
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: paymentReports.length,
            itemBuilder: (context, index) {
              final report = paymentReports[index];
              return _buildPaymentReportShiftCard(report);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsTotalsGrid({
    required double totalCash,
    required double totalQr,
    required double totalCreditCard,
    required double totalTransfer,
    required double totalCheque,
    required double totalCoupon,
    required double totalCredit,
    double totalPoint = 0,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildPaymentMethodRow(global.language("cash"), totalCash, Colors.green),
          _buildPaymentMethodRow(global.language("qr_code"), totalQr, Colors.purple),
          _buildPaymentMethodRow(global.language("credit_card"), totalCreditCard, Colors.orange),
          _buildPaymentMethodRow(global.language("money_transfer"), totalTransfer, _themeSwatch),
          _buildPaymentMethodRow(global.language("cheque"), totalCheque, Colors.brown),
          _buildPaymentMethodRow(global.language("coupon"), totalCoupon, Colors.pink),
          if (totalCredit > 0) _buildPaymentMethodRow(global.language("credit"), totalCredit, Colors.red),
          if (totalPoint > 0) _buildPaymentMethodRow("Point Payment", totalPoint, Colors.amber),
        ],
      ),
    );
  }

  Widget _buildPaymentReportShiftCard(ShiftReportModel report) {
    final totalSales = report.totalCash + report.totalQr + report.totalCreditCard + report.totalTransfer + report.totalCheque + report.totalCoupon + report.totalCredit + report.totalPoint;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: const Icon(Icons.schedule, color: Colors.green, size: 20),
        title: Text(
          '${report.openShift.username} ${dateTimeFormat.format(report.openShift.docdate)} - ${dateTimeFormat.format(report.closeShift.docdate)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${global.language("total_sales")}: ${global.moneyFormatAndDot.format(totalSales)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                Text(
                  '${global.language("total_transactions")}: ${report.totalTransactions}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
        children: [
          // Payment Methods
          _buildSectionTitle(global.language("payment_methods")),
          const SizedBox(height: 8),
          _buildPaymentMethodsGrid(report),
          const SizedBox(height: 16),
          // Drawer Calculation
          _buildSectionTitle(global.language("drawer_calculation")),
          const SizedBox(height: 8),
          _buildDrawerCalculation(report),
        ],
      ),
    );
  }

  Widget _buildSalesTransactionsList(List<BillObjectBoxStruct> salesTransactions) {
    if (salesTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(global.language("no_transactions_found_in_period")),
          ],
        ),
      );
    } // Calculate payment method totals from all transactions
    double totalCash = 0;
    double totalQr = 0;
    double totalCreditCard = 0;
    double totalTransfer = 0;
    double totalCheque = 0;
    double totalCoupon = 0;
    double totalCredit = 0;
    double totalPoint = 0;
    double totalAmount = 0;
    int totalTransactions = salesTransactions.length;
    for (final transaction in salesTransactions) {
      totalCash += (transaction.pay_cash_amount - transaction.pay_cash_change);
      totalQr += transaction.sum_qr_code;
      totalCreditCard += transaction.sum_credit_card;
      totalTransfer += transaction.sum_money_transfer;
      totalCheque += transaction.sum_cheque;
      totalCoupon += transaction.sum_coupon;
      totalCredit += transaction.sum_credit;
      totalPoint += transaction.paypointamount;
      totalAmount += transaction.total_amount;
    }

    // Calculate payment methods grand total
    double paymentMethodsGrandTotal = totalCash + totalQr + totalCreditCard + totalTransfer + totalCheque + totalCoupon + totalCredit + totalPoint;

    return Column(
      children: [
        // Summary card
        Container(
          margin: const EdgeInsets.all(16),
          child: Card(
            elevation: 4,
            color: _themeSwatch[50]!,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          global.language("payment_transactions_summary"),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _themeSwatch),
                        ),
                        const SizedBox(height: 12),
                        Text('${global.language("total_amount")}: ${NumberFormat('#,##0.00').format(totalAmount)} ฿', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          'Payment Methods Total: ${NumberFormat('#,##0.00').format(paymentMethodsGrandTotal)} ฿',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.green),
                        ),
                        const SizedBox(height: 4),
                        Text('${global.language("total_transactions")}: $totalTransactions', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Material(
                    color: _themeSwatch,
                    borderRadius: BorderRadius.circular(8),
                    elevation: 2,
                    child: InkWell(
                      onTap: () => _printTransactionsSummaryReport(
                        totalCash: totalCash,
                        totalQr: totalQr,
                        totalCreditCard: totalCreditCard,
                        totalTransfer: totalTransfer,
                        totalCheque: totalCheque,
                        totalCoupon: totalCoupon,
                        totalCredit: totalCredit,
                        totalPoint: totalPoint,
                        grandTotal: paymentMethodsGrandTotal,
                        totalTransactions: totalTransactions,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.print, size: 18, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              global.language("print"),
                              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Payment method summary grid
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _buildPaymentMethodsTotalsGrid(
            totalCash: totalCash,
            totalQr: totalQr,
            totalCreditCard: totalCreditCard,
            totalTransfer: totalTransfer,
            totalCheque: totalCheque,
            totalCoupon: totalCoupon,
            totalCredit: totalCredit,
            totalPoint: totalPoint,
          ),
        ),
      ],
    );
  }

  void _printShiftReport(ShiftReportModel report) {
    global.playSound(sound: global.SoundEnum.buttonTing);
    try {
      printShiftReportDetailed(shiftReport: report, startDate: report.openShift.docdate, endDate: report.closeShift.docdate);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(global.language("printing_shift_report")), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${global.language("print_error")}: $e'), backgroundColor: Colors.red));
    }
  }

  void _printPaymentSummaryReport({
    required double totalCash,
    required double totalQr,
    required double totalCreditCard,
    required double totalTransfer,
    required double totalCheque,
    required double totalCoupon,
    required double totalCredit,
    double totalPoint = 0,
    required double grandTotal,
    required int totalTransactions,
  }) {
    global.playSound(sound: global.SoundEnum.buttonTing);
    try {
      // Get payment reports from current bloc state
      final currentState = context.read<SalesSummaryBloc>().state;

      // ⭐ แก้ไข: ใช้ isPaymentReportsLoaded flag แทน type checking
      if (currentState.isPaymentReportsLoaded && currentState.salesTransactions.isNotEmpty) {
        // Fallback to simple payment summary
        printSimplePaymentSummary(
          totalCash: totalCash,
          totalQr: totalQr,
          totalCreditCard: totalCreditCard,
          totalTransfer: totalTransfer,
          totalCheque: totalCheque,
          totalCoupon: totalCoupon,
          totalCredit: totalCredit,
          totalPoint: totalPoint,
          grandTotal: grandTotal,
          totalTransactions: totalTransactions,
          startDate: paymentStartDate ?? DateTime.now(),
          endDate: paymentEndDate ?? DateTime.now(),
        );

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(global.language("printing_payment_report")), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${global.language("print_error")}: $e'), backgroundColor: Colors.red));
    }
  }

  void _printTransactionsSummaryReport({
    required double totalCash,
    required double totalQr,
    required double totalCreditCard,
    required double totalTransfer,
    required double totalCheque,
    required double totalCoupon,
    required double totalCredit,
    double totalPoint = 0,
    required double grandTotal,
    required int totalTransactions,
  }) {
    global.playSound(sound: global.SoundEnum.buttonTing);
    try {
      printSimplePaymentSummary(
        totalCash: totalCash,
        totalQr: totalQr,
        totalCreditCard: totalCreditCard,
        totalTransfer: totalTransfer,
        totalCheque: totalCheque,
        totalCoupon: totalCoupon,
        totalCredit: totalCredit,
        totalPoint: totalPoint,
        grandTotal: grandTotal,
        totalTransactions: totalTransactions,
        startDate: paymentStartDate ?? DateTime.now(),
        endDate: paymentEndDate ?? DateTime.now(),
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(global.language("printing_payment_report")), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${global.language("print_error")}: $e'), backgroundColor: Colors.red));
    }
  }
}
