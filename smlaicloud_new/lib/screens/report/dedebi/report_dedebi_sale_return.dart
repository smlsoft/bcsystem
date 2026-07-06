// ignore_for_file: deprecated_member_use, unused_import

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smlaicloud/bloc/bi_report/bi_report_bloc.dart';
import 'package:smlaicloud/global.dart' as global;
import 'package:smlaicloud/model/bi_report/sale_return_model.dart';
import 'package:smlaicloud/model/global_model.dart';
import 'package:smlaicloud/model/bi_report/bi_report_models.dart';
import 'package:smlaicloud/model/bi_report/branch_selection_model.dart';
import 'package:smlaicloud/screen_search/dedebi/multi_branch_search_screen.dart';
import 'package:smlaicloud/screens/report/dedebi/components/filter_panel.dart';
import 'package:smlaicloud/screens/report/dedebi/components/report_condition_dialog.dart';
import 'package:smlaicloud/screens/report/dedebi/components/sale_table_view.dart';
import 'package:smlaicloud/screens/report/dedebi/components/total_summary_panel.dart';
import 'package:smlaicloud/screens/report/dedebi/components/transaction_detail_dialog.dart';
import 'package:smlaicloud/screens/report/dedebi/utils/report_utils.dart';
import 'package:smlaicloud/utils/date_picker.dart';

class ReportDedebiSaleReturnScreen extends StatefulWidget {
  const ReportDedebiSaleReturnScreen({super.key});

  @override
  State<ReportDedebiSaleReturnScreen> createState() => _ReportDedebiSaleReturnScreenState();
}

class _ReportDedebiSaleReturnScreenState extends State<ReportDedebiSaleReturnScreen> {
  // Report condition variables
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _showDetails = true;

  BranchSelectionModel _selectedBranches = const BranchSelectionModel(selectedBranches: [], isCancel: false); // Branch selection

  // Pagination variables
  int _pageSize = 20;

  BiReportMeta? _currentMeta;
  List<SaleReturnModel> _currentData = [];
  String _currentJobId = ''; // Add this to track current job ID

  // Total summary data
  SaleReturnSummaryModel? _currentTotalSummary;
  bool _totalSummaryLoading = false;

  @override
  void initState() {
    print('🚀 ReportDedebiSaleReturnScreen initState called');
    super.initState();

    // Initialize default dates (current month)
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1); // First day of current month
    _toDate = DateTime(now.year, now.month + 1, 0); // Last day of current month

    // Reset report state when entering screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('📱 PostFrameCallback executed');
      // Reset BiReport state first
      context.read<BiReportBloc>().add(const ResetBiReportState());

      // Then show condition dialog
      _showConditionDialog();
    });
  }

  @override
  void dispose() {
    // Reset BiReport state when leaving screen
    context.read<BiReportBloc>().add(const ResetBiReportState());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        // Reset state when user navigates back
        context.read<BiReportBloc>().add(const ResetBiReportState());
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            'รายงานลดหนี้/รับคืน',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: Colors.indigo.shade600,
          foregroundColor: Colors.white,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Reset state before navigation
              context.read<BiReportBloc>().add(const ResetBiReportState());
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_alt_outlined),
              onPressed: _showConditionDialog,
              tooltip: 'ตั้งค่าเงื่อนไขการค้นหา',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Reset and refresh data
                context.read<BiReportBloc>().add(const ResetBiReportState());
                _refreshReportData();
              },
              tooltip: 'รีเฟรชข้อมูล',
            ),
          ],
        ),
        body: BlocConsumer<BiReportBloc, BiReportState>(
          // ลดความซับซ้อนของ buildWhen
          buildWhen: (previous, current) {
            // เฉพาะ states ที่ไม่ใช่ summary และ total summary ให้ rebuild UI หลัก
            return current is! BiReportSummaryLoading && current is! BiReportSummarySuccess && current is! BiReportSummaryFailure;
          },
          listener: (context, state) {
            _handleStateChanges(state);
          },

          builder: (context, state) {
            return _buildContent(state);
          },
        ),
      ),
    );
  }

  void _handleStateChanges(BiReportState state) {
    switch (state) {
      case BiReportGenerateFailure():
        _showErrorSnackBar(state.message);
        break;
      case BiReportDetailFailure():
        _showErrorSnackBar(state.message);
        break;
      case BiReportGenerateSuccess():
        _updateCurrentData(state);
        _requestTotalSummary(state.jobId);

        break;
      case BiReportDetailSuccess():
        _updateCurrentData(state);
        break;
      case BiReportSummaryLoading():
        setState(() {
          _totalSummaryLoading = true;
        });
        break;
      case BiReportSummarySuccess():
        setState(() {
          _currentTotalSummary = state.saleReturnSummaryData;
          _totalSummaryLoading = false;
        });
        break;
      case BiReportSummaryFailure():
        setState(() {
          _totalSummaryLoading = false;
        });
        _showErrorSnackBar(state.message);
        break;

      default:
        // No action needed for other states
        break;
    }
  }

  Widget _buildContent(BiReportState state) {
    return switch (state) {
      BiReportInitial() => _buildInitialState(),
      BiReportGenerating() => _buildLoadingState('กำลังเริ่มสร้างรายงาน...', 0),
      BiReportGenerateProgress() => _buildLoadingState(state.statusMessage, state.progress),
      BiReportGenerateSuccess() => _buildSuccessContent(state.data.whereType<SaleReturnModel>().toList(), state.jobId, state.meta),
      BiReportDetailLoading() => _buildContentWithLoading(state.jobId),
      BiReportDetailSuccess() => _buildSuccessContent(state.data.whereType<SaleReturnModel>().toList(), state.jobId, state.meta),
      BiReportGenerateFailure() => _buildErrorState(state.message),
      BiReportDetailFailure() => _buildErrorState(state.message),

      // Default fallback
      _ => _currentData.isNotEmpty ? _buildSuccessContent(_currentData, _currentJobId, _currentMeta!) : _buildInitialState(),
    };
  }

  void _updateCurrentData(dynamic state) {
    if (state is BiReportGenerateSuccess || state is BiReportDetailSuccess) {
      setState(() {
        _currentData = state.data.whereType<SaleReturnModel>().toList();
        _currentMeta = state.meta;
        _currentJobId = state.jobId;
      });
    }
  }

  void _requestTotalSummary(String jobId) {
    context.read<BiReportBloc>().add(
          GetBiReportSummaryRequested(
            reportType: BiReportType.saleReturn,
            jobId: jobId,
            token: global.appConfig.getString("token")!,
          ),
        );
  }

  Widget _buildContentWithLoading(String jobId) {
    if (_currentData.isNotEmpty && _currentMeta != null) {
      return _buildMainLayoutWithLoading(_currentData, jobId, _currentMeta!);
    }
    return _buildLoadingState('กำลังโหลดข้อมูล...', 0);
  }

  Widget _buildSuccessContent(List<SaleReturnModel> data, String jobId, BiReportMeta meta) {
    return _buildMainLayout(data, jobId, meta);
  }

  Widget _buildMainLayout(List<SaleReturnModel> data, String jobId, BiReportMeta meta) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main content
        Expanded(
          child: _buildMainContent(data, jobId, meta),
        ),

        // Sidebar
        _buildSidebar(data),
      ],
    );
  }

  Widget _buildMainLayoutWithLoading(List<SaleReturnModel> data, String jobId, BiReportMeta meta) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSidebar(data),
        Expanded(
          child: Stack(
            children: [
              Opacity(
                opacity: 0.5,
                child: _buildMainContent(data, jobId, meta),
              ),
              _buildLoadingOverlay(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar(List<SaleReturnModel> data) {
    return Container(
      width: 260,
      padding: const EdgeInsets.only(top: 16, bottom: 16, left: 0, right: 16),
      child: SingleChildScrollView(
        // เพิ่ม scroll ลงได้
        child: Column(
          children: [
            FilterPanel(
              reportType: BiReportType.saleReturn,
              fromDate: _fromDate,
              toDate: _toDate,
              showDetails: _showDetails,
              selectedBranches: _selectedBranches,
              onShowConditionDialog: _showConditionDialog,
              onRefresh: _refreshReportData,
            ),
            const SizedBox(height: 16),
            TotalSummaryPanel(
              saleReturnSummary: _currentTotalSummary,
              isLoading: _totalSummaryLoading,
              reportType: BiReportType.saleReturn,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(List<SaleReturnModel> data, String jobId, BiReportMeta meta) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(child: _buildDataGrid(data)),
          const SizedBox(height: 16),
          _buildPaginationControls(jobId, meta),
        ],
      ),
    );
  }

  Widget _buildDataGrid(List<SaleReturnModel> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SaleTableView(
        dataSaleReturn: data,
        formatCurrency: ReportUtils.formatCurrency,
        getCreditorName: ReportUtils.getCreditorName,
        onRowSaleReturnTap: _showTransactionDialog,
        reportType: BiReportType.saleReturn,
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade600),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'กำลังโหลดหน้าใหม่...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'ลองใหม่',
          textColor: Colors.white,
          onPressed: _refreshReportData,
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.indigo.shade600,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'รายงานยอดขาย Dedebi',
            style: TextStyle(
              fontSize: 24,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              'กำหนดเงื่อนไขการค้นหาเพื่อดูข้อมูล',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showConditionDialog,
            icon: const Icon(Icons.filter_alt),
            label: const Text('ตั้งค่าเงื่อนไขการค้นหา'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(String message, int progress) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: null, // ❌ เปลี่ยนให้เป็น null เพื่อให้หมุนตลอด
                    strokeWidth: 6,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade600),
                  ),
                ),
                if (progress > 0)
                  Text(
                    '$progress%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'กรุณารอสักครู่...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(String jobId, BiReportMeta meta) {
    final totalPages = meta.totalPage;
    final currentPage = meta.page;
    final totalItems = meta.total;
    final startItem = (currentPage - 1) * meta.size + 1;
    final endItem = (currentPage * meta.size > totalItems) ? totalItems : currentPage * meta.size;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page info
          Expanded(
            child: Text(
              'แสดง $startItem-$endItem จากทั้งหมด $totalItems รายการ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          // Page size selector
          Row(
            children: [
              Text(
                'แสดง',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _pageSize,
                items: [10, 20, 50, 100].map((size) {
                  return DropdownMenuItem<int>(
                    value: size,
                    child: Text('$size'),
                  );
                }).toList(),
                onChanged: (newSize) {
                  if (newSize != null) {
                    setState(() {
                      _pageSize = newSize;
                    });
                    _loadPage(jobId, 1, newSize);
                  }
                },
                underline: Container(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'รายการ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // Pagination buttons
          Row(
            children: [
              // First page
              IconButton(
                onPressed: currentPage > 1 ? () => _loadPage(jobId, 1, _pageSize) : null,
                icon: const Icon(Icons.first_page),
                tooltip: 'หน้าแรก',
              ),

              // Previous page
              IconButton(
                onPressed: currentPage > 1 ? () => _loadPage(jobId, currentPage - 1, _pageSize) : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'หน้าก่อนหน้า',
              ),

              // Page numbers
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$currentPage / $totalPages',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Next page
              IconButton(
                onPressed: currentPage < totalPages ? () => _loadPage(jobId, currentPage + 1, _pageSize) : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'หน้าถัดไป',
              ),

              // Last page
              IconButton(
                onPressed: currentPage < totalPages ? () => _loadPage(jobId, totalPages, _pageSize) : null,
                icon: const Icon(Icons.last_page),
                tooltip: 'หน้าสุดท้าย',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _loadPage(String jobId, int page, int size) {
    setState(() {
      _pageSize = size;
    });

    context.read<BiReportBloc>().add(
          GetBiReportDetailRequested(
            reportType: BiReportType.saleReturn,
            jobId: jobId,
            token: global.appConfig.getString("token")!,
            page: page,
            size: size,
          ),
        );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'เกิดข้อผิดพลาด',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Reset state and try again with current conditions
                  context.read<BiReportBloc>().add(const ResetBiReportState());
                  _refreshReportData();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _showConditionDialog,
                icon: const Icon(Icons.settings),
                label: const Text('เปลี่ยนเงื่อนไข'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.indigo.shade600,
                  side: BorderSide(color: Colors.indigo.shade600),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              context.read<BiReportBloc>().add(const ResetBiReportState());
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('ล้างข้อมูล'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showConditionDialog() async {
    print('🔵 _showConditionDialog called');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ReportConditionDialog(
          reportType: BiReportType.saleReturn,
          initialFromDate: _fromDate,
          initialToDate: _toDate,
          initialShowDetails: _showDetails,
          initialSelectedBranches: _selectedBranches,
          onConditionsSet: (conditions) {
            print('🔍 Conditions set from dialog');
            setState(() {
              _fromDate = conditions.fromDate;
              _toDate = conditions.toDate;
              _showDetails = conditions.showDetails!;
              _selectedBranches = conditions.selectedBranches!;
            });
            print('💾 State updated in main screen');
            print('🚪 Calling _refreshReportData');
            _refreshReportData();
          },
        );
      },
    );
  }

  void _refreshReportData() {
    print('🟢 _refreshReportData called');

    // Validate date inputs
    if (_fromDate == null || _toDate == null) {
      print('❌ Date validation failed: fromDate=$_fromDate, toDate=$_toDate');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกช่วงวันที่'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    print('✅ Date validation passed: ${DateFormat('yyyy-MM-dd').format(_fromDate!)} to ${DateFormat('yyyy-MM-dd').format(_toDate!)}');

    // Validate date range
    if (_fromDate!.isAfter(_toDate!)) {
      print('❌ Date range validation failed: fromDate > toDate');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('วันที่เริ่มต้นต้องไม่เกินวันที่สิ้นสุด'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Check if date range is too large (more than 1 year)
    final daysDifference = _toDate!.difference(_fromDate!).inDays;
    if (daysDifference > 365) {
      print('⚠️ Date range too large: $daysDifference days');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ช่วงวันที่ต้องไม่เกิน 1 ปี'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate token
    final token = global.appConfig.getString("token");
    if (token == null || token.isEmpty) {
      print('❌ Token validation failed: token is null or empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบ Token การเชื่อมต่อ กรุณาเข้าสู่ระบบใหม่'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Reset current state before new request
    print('🔄 Resetting BiReport state');
    context.read<BiReportBloc>().add(const ResetBiReportState());

    // Reset total summary state
    setState(() {
      _currentTotalSummary = null;
      _totalSummaryLoading = false;
    });

    // Create conditions for Sale Report
    final conditions = ReportConditionsModel(
      fromdate: DateFormat('yyyy-MM-dd').format(_fromDate!),
      todate: DateFormat('yyyy-MM-dd').format(_toDate!),
      branchcode: _selectedBranches.getBranchCodeString(),
      showdetail: _showDetails,
    );

    print('📋 Report conditions created: ${conditions.toJson()}');

    // Show loading indicator and trigger report generation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text('กำลังเตรียมข้อมูลรายงาน...'),
          ],
        ),
        backgroundColor: Colors.indigo.shade600,
        duration: const Duration(seconds: 2),
      ),
    );

    // Trigger report generation via BiReportBloc
    final startTime = DateTime.now();
    print('🚀 Dispatching GenerateBiReportRequested event with:');
    print('   - reportType: ${BiReportType.saleReturn}');
    print('   - conditions: ${conditions.toJson()}');
    print('   - token: ${token.substring(0, 10)}...');
    print('   - page: 1, size: $_pageSize');
    print('   - startTime: $startTime');

    try {
      context.read<BiReportBloc>().add(
            GenerateBiReportRequested(
              reportType: BiReportType.saleReturn,
              conditions: conditions,
              token: token,
              pollInterval: const Duration(seconds: 2),
              timeout: const Duration(minutes: 10),
              page: 1, // Start with first page
              size: _pageSize, // Use current page size
            ),
          );

      print('✅ Event dispatched successfully at ${DateTime.now()}');
      print('⏱️ Dispatch took: ${DateTime.now().difference(startTime).inMilliseconds}ms');
    } catch (e, stackTrace) {
      print('❌ Error dispatching event: $e');
      print('📚 Stack trace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการส่งคำขอ: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showTransactionDialog(SaleReturnModel sale) {
    if (sale.transactions.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return TransactionDetailDialog(
            saleReturn: sale,
            formatCurrency: ReportUtils.formatCurrency,
            getCreditorName: ReportUtils.getCreditorName,
          );
        },
      );
    }
  }
}
