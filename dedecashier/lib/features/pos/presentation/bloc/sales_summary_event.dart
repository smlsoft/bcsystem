part of 'sales_summary_bloc.dart';

@freezed
class SalesSummaryEvent with _$SalesSummaryEvent {
  const factory SalesSummaryEvent.loadSalesSummary({
    DateTime? startDate,
    DateTime? endDate,
    String? shiftId,
  }) = LoadSalesSummary;

  const factory SalesSummaryEvent.filterByDate({
    required DateTime startDate,
    required DateTime endDate,
  }) = FilterSalesByDate;

  const factory SalesSummaryEvent.filterByShift({
    required String shiftId,
  }) = FilterSalesByShift;

  const factory SalesSummaryEvent.clearFilters() = ClearSalesFilters;
  const factory SalesSummaryEvent.loadShiftReports({
    DateTime? startDate,
    DateTime? endDate,
  }) = LoadShiftReports;
  const factory SalesSummaryEvent.loadMoneyTransferReports({
    DateTime? startDate,
    DateTime? endDate,
  }) = LoadMoneyTransferReports;

  const factory SalesSummaryEvent.loadPaymentReports({
    DateTime? startDate,
    DateTime? endDate,
  }) = LoadPaymentReports;
}
