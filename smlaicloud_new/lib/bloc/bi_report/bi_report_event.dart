part of 'bi_report_bloc.dart';

sealed class BiReportEvent extends Equatable {
  const BiReportEvent();

  @override
  List<Object> get props => [];
}

// Complete report generation (Submit → Poll → Get Details)
class GenerateBiReportRequested extends BiReportEvent {
  final BiReportType reportType;
  final dynamic conditions; // Can be ReportConditions, ProductReportConditions, etc.
  final String token;
  final Duration? pollInterval;
  final Duration? timeout;
  final int? page;
  final int? size;

  const GenerateBiReportRequested({
    required this.reportType,
    required this.conditions,
    required this.token,
    this.pollInterval,
    this.timeout,
    this.page,
    this.size,
  });

  @override
  List<Object> get props => [reportType, conditions, token];
}

class GetBiReportDetailRequested extends BiReportEvent {
  final BiReportType reportType;
  final String jobId;
  final String token;
  final int? page;
  final int? size;

  const GetBiReportDetailRequested({
    required this.reportType,
    required this.jobId,
    required this.token,
    this.page,
    this.size,
  });

  @override
  List<Object> get props => [reportType, jobId, token];
}

// Get report summary
class GetBiReportSummaryRequested extends BiReportEvent {
  final BiReportType reportType;
  final String jobId;
  final String token;

  const GetBiReportSummaryRequested({
    required this.reportType,
    required this.jobId,
    required this.token,
  });

  @override
  List<Object> get props => [reportType, jobId, token];
}

// Reset state
class ResetBiReportState extends BiReportEvent {
  const ResetBiReportState();
}
