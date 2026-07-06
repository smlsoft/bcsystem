part of 'sales_summary_bloc.dart';

/// ⭐ UNIFIED STATE: เก็บข้อมูลทุก Tab ไว้ด้วยกัน
/// เมื่อเปลี่ยน Tab ข้อมูล Tab อื่นจะไม่หาย
@freezed
sealed class SalesSummaryState with _$SalesSummaryState {
  const factory SalesSummaryState({
    // === Shared Filters ===
    DateTime? startDate,
    DateTime? endDate,
    String? selectedShiftId,
    String? errorMessage,

    // === Tab 1: Sales Report ===
    @Default([]) List<BillObjectBoxStruct> salesData,
    @Default([]) List<ShiftObjectBoxStruct> shifts,
    @Default({}) Map<String, ShiftObjectBoxStruct> shiftCloseMap,
    @Default(0) double totalAmount,
    @Default(0) int totalTransactions,
    @Default(false) bool isLoadingSalesReport,
    @Default(false) bool isSalesReportLoaded,

    // === Tab 2: Shift Reports ===
    @Default([]) List<ShiftReportModel> shiftReports,
    @Default(false) bool isLoadingShiftReports,
    @Default(false) bool isShiftReportsLoaded,

    // === Tab 3: Money Transfer ===
    @Default([]) List<ShiftObjectBoxStruct> moneyTransferReports,
    @Default(false) bool isLoadingMoneyTransfer,
    @Default(false) bool isMoneyTransferLoaded,

    // === Tab 4: Payment Reports ===
    @Default([]) List<BillObjectBoxStruct> salesTransactions,
    @Default(false) bool isLoadingPaymentReports,
    @Default(false) bool isPaymentReportsLoaded,
  }) = _SalesSummaryState;

  /// Initial state
  factory SalesSummaryState.initial() => const SalesSummaryState();
}
