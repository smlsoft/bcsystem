part of 'bi_report_bloc.dart';

sealed class BiReportState extends Equatable {
  const BiReportState();

  @override
  List<Object> get props => [];
}

final class BiReportInitial extends BiReportState {}

// Complete Report Generation States
final class BiReportGenerating extends BiReportState {
  final BiReportType reportType;

  const BiReportGenerating({
    required this.reportType,
  });

  @override
  List<Object> get props => [reportType];
}

final class BiReportGenerateProgress extends BiReportState {
  final BiReportType reportType;
  final String jobId;
  final int progress;
  final String statusMessage;

  const BiReportGenerateProgress({
    required this.reportType,
    required this.jobId,
    required this.progress,
    required this.statusMessage,
  });

  @override
  List<Object> get props => [reportType, jobId, progress, statusMessage];
}

final class BiReportGenerateSuccess extends BiReportState {
  final BiReportType reportType;
  final String jobId;
  final List<dynamic> data;
  final BiReportMeta meta;

  const BiReportGenerateSuccess({
    required this.reportType,
    required this.jobId,
    required this.data,
    required this.meta,
  });

  @override
  List<Object> get props => [reportType, jobId, data, meta];
}

final class BiReportGenerateFailure extends BiReportState {
  final String message;
  final int? errorCode;

  const BiReportGenerateFailure({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object> get props => [message, errorCode ?? 0];
}

final class BiReportDetailLoading extends BiReportState {
  final BiReportType reportType;
  final String jobId;

  const BiReportDetailLoading({
    required this.reportType,
    required this.jobId,
  });

  @override
  List<Object> get props => [reportType, jobId];
}

final class BiReportDetailSuccess extends BiReportState {
  final BiReportType reportType;
  final String jobId;
  final List<dynamic> data;
  final BiReportMeta meta; // เปลี่ยนกลับเป็น required

  const BiReportDetailSuccess({
    required this.reportType,
    required this.jobId,
    required this.data,
    required this.meta, // เปลี่ยนกลับเป็น required
  });

  @override
  List<Object> get props => [reportType, jobId, data, meta];
}

final class BiReportDetailFailure extends BiReportState {
  final String jobId;
  final String message;
  final int? errorCode;

  const BiReportDetailFailure({
    required this.jobId,
    required this.message,
    this.errorCode,
  });

  @override
  List<Object> get props => [jobId, message, errorCode ?? 0];
}

// Get Report Summary States
final class BiReportSummaryLoading extends BiReportState {
  final BiReportType reportType;
  final String jobId;

  const BiReportSummaryLoading({
    required this.reportType,
    required this.jobId,
  });

  @override
  List<Object> get props => [reportType, jobId];
}

final class BiReportSummarySuccess extends BiReportState {
  final BiReportType reportType;
  final String jobId;
  final SaleReportSummary? summaryData;
  final SaleDailyReportSummary? dailySummaryData;
  final StockMovmentSummaryModel? stockMovementSummaryData;
  final PaymentDailySummaryModel? paymentDailySummaryData;
  final SaleReturnSummaryModel? saleReturnSummaryData;
  final StockBalanceSummaryModel? stockBalanceSummaryData;

  const BiReportSummarySuccess({
    required this.reportType,
    required this.jobId,
    this.summaryData,
    this.dailySummaryData,
    this.stockMovementSummaryData,
    this.paymentDailySummaryData,
    this.saleReturnSummaryData,
    this.stockBalanceSummaryData,
  });

  @override
  List<Object> get props =>
      [reportType, jobId, summaryData!, dailySummaryData!, stockMovementSummaryData!, paymentDailySummaryData!, saleReturnSummaryData!, stockBalanceSummaryData!];
}

final class BiReportSummaryFailure extends BiReportState {
  final String jobId;
  final String message;
  final int? errorCode;

  const BiReportSummaryFailure({
    required this.jobId,
    required this.message,
    this.errorCode,
  });

  @override
  List<Object> get props => [jobId, message, errorCode ?? 0];
}
