import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smlaicloud/model/bi_report/bi_report_models.dart';
import 'package:smlaicloud/model/bi_report/bi_sale_report_data.dart';
import 'package:smlaicloud/model/bi_report/payment_daily_model.dart';
import 'package:smlaicloud/model/bi_report/sale_daily_report_models.dart';
import 'package:smlaicloud/model/bi_report/sale_daily_report_summary.dart';
import 'package:smlaicloud/model/bi_report/sale_report_summary.dart';
import 'package:smlaicloud/model/bi_report/sale_return_model.dart';
import 'package:smlaicloud/model/bi_report/stock_balance_model.dart';
import 'package:smlaicloud/model/bi_report/stock_movment_model.dart';
import 'package:smlaicloud/model/bi_report/stock_movment_summary_model.dart';
import 'package:smlaicloud/repositories/bi_report_repository.dart';

part 'bi_report_event.dart';
part 'bi_report_state.dart';

class BiReportBloc extends Bloc<BiReportEvent, BiReportState> {
  final BiReportRepository _repository;

  // Report type to data model mapping for type safety
  static const _reportDataTypeHandlers = {
    BiReportType.sale: SaleReportData,
    BiReportType.saleDaily: SaleDailyReportData,
    BiReportType.stockMovement: StockMovementModel,
    BiReportType.paymentDaily: PaymentDailyModel,
    BiReportType.saleReturn: SaleReturnModel,
    BiReportType.stockBalance: StockBalanceModel,
  };

  BiReportBloc({
    required BiReportRepository biReportRepository,
  })  : _repository = biReportRepository,
        super(BiReportInitial()) {
    on<GenerateBiReportRequested>(_onGenerateBiReportRequested);
    on<GetBiReportDetailRequested>(_onGetBiReportDetailRequested);
    on<GetBiReportSummaryRequested>(_onGetBiReportSummaryRequested);
    on<ResetBiReportState>(_onResetBiReportState);
  }

  // Complete report generation process (Submit → Poll → Get Details)
  Future<void> _onGenerateBiReportRequested(
    GenerateBiReportRequested event,
    Emitter<BiReportState> emit,
  ) async {
    try {
      emit(BiReportGenerating(reportType: event.reportType));

      // Validate conditions type
      if (event.conditions is! ReportConditionsModel) {
        emit(BiReportGenerateFailure(
          message: 'รูปแบบเงื่อนไขรายงานไม่ถูกต้อง',
        ));
        return;
      }

      // Check if report type is supported
      if (!_reportDataTypeHandlers.containsKey(event.reportType)) {
        emit(BiReportGenerateFailure(
          message: 'รายงานประเภท ${event.reportType.displayName} ยังไม่รองรับ',
        ));
        return;
      }

      // Use generic report generation
      await _generateGenericReport(
        event.reportType,
        event.conditions as ReportConditionsModel,
        event.token,
        emit,
        timeout: event.timeout,
        pollInterval: event.pollInterval,
        page: event.page,
        size: event.size,
      );
    } on BiReportException catch (e) {
      emit(BiReportGenerateFailure(
        message: e.message,
        errorCode: e.code,
      ));
    } catch (e) {
      emit(BiReportGenerateFailure(
        message: 'เกิดข้อผิดพลาดไม่คาดคิด: ${e.toString()}',
      ));
    }
  }

  // Generic report generation method
  Future<void> _generateGenericReport(
    BiReportType reportType,
    ReportConditionsModel conditions,
    String token,
    Emitter<BiReportState> emit, {
    Duration? timeout,
    Duration? pollInterval,
    int? page,
    int? size,
  }) async {
    // Step 1: Submit report job
    final jobResponse = await _repository.submitReport(
      reportType: reportType,
      conditions: conditions.toJson(),
      token: token,
    );

    final jobId = jobResponse.jobId;
    emit(BiReportGenerateProgress(
      reportType: reportType,
      jobId: jobId,
      progress: 0,
      statusMessage: 'เริ่มสร้าง${reportType.displayName}...',
    ));

    // Step 2: Poll for completion with progress updates
    final startTime = DateTime.now();
    final timeoutDuration = timeout ?? const Duration(minutes: 10);
    final pollIntervalDuration = pollInterval ?? const Duration(seconds: 2);

    while (DateTime.now().difference(startTime) < timeoutDuration) {
      await Future.delayed(pollIntervalDuration);

      final statusResponse = await _repository.getReportStatus(
        reportType: reportType,
        jobId: jobId,
        token: token,
      );

      // Emit progress update
      emit(BiReportGenerateProgress(
        reportType: reportType,
        jobId: jobId,
        progress: statusResponse.data.progress,
        statusMessage: _getStatusMessage(statusResponse.data.state, statusResponse.data.progress),
      ));

      if (statusResponse.data.state == 'completed') {
        // Step 3: Get report details using generic method
        await _getReportDetailByType(
          reportType: reportType,
          jobId: jobId,
          token: token,
          emit: emit,
          page: page ?? 1,
          size: size ?? 20,
        );
        return;
      } else if (statusResponse.data.state == 'failed') {
        emit(BiReportGenerateFailure(
          message: _formatErrorMessage(statusResponse.data.failedReason),
        ));
        return;
      }
    }

    // Timeout reached
    emit(BiReportGenerateFailure(
      message: 'การสร้าง${reportType.displayName}ใช้เวลานานเกินไป',
    ));
  }

  // Generic method to get report details based on type
  Future<void> _getReportDetailByType({
    required BiReportType reportType,
    required String jobId,
    required String token,
    required Emitter<BiReportState> emit,
    required int page,
    required int size,
  }) async {
    switch (reportType) {
      case BiReportType.sale:
        final result = await _repository.getReportDetail<SaleReportData>(
          reportType: reportType,
          jobId: jobId,
          token: token,
          fromJsonT: (json) => SaleReportData.fromJson(json as Map<String, dynamic>),
          page: page,
          size: size,
        );

        emit(BiReportGenerateSuccess(
          reportType: reportType,
          jobId: jobId,
          data: result.data,
          meta: result.meta,
        ));
        break;

      case BiReportType.saleDaily:
        final result = await _repository.getReportDetail<SaleDailyReportData>(
          reportType: reportType,
          jobId: jobId,
          token: token,
          fromJsonT: (json) => SaleDailyReportData.fromJson(json as Map<String, dynamic>),
          page: page,
          size: size,
        );

        emit(BiReportGenerateSuccess(
          reportType: reportType,
          jobId: jobId,
          data: result.data,
          meta: result.meta,
        ));
        break;

      case BiReportType.stockMovement:
        final result = await _repository.getReportDetail<StockMovementModel>(
          reportType: reportType,
          jobId: jobId,
          token: token,
          fromJsonT: (json) => StockMovementModel.fromJson(json as Map<String, dynamic>),
          page: page,
          size: size,
        );

        emit(BiReportGenerateSuccess(
          reportType: reportType,
          jobId: jobId,
          data: result.data,
          meta: result.meta,
        ));
        break;

      case BiReportType.paymentDaily:
        final result = await _repository.getReportDetail<PaymentDailyModel>(
          reportType: reportType,
          jobId: jobId,
          token: token,
          fromJsonT: (json) => PaymentDailyModel.fromJson(json as Map<String, dynamic>),
          page: page,
          size: size,
        );

        emit(BiReportGenerateSuccess(
          reportType: reportType,
          jobId: jobId,
          data: result.data,
          meta: result.meta,
        ));
        break;

      case BiReportType.saleReturn:
        final result = await _repository.getReportDetail<SaleReturnModel>(
          reportType: reportType,
          jobId: jobId,
          token: token,
          fromJsonT: (json) => SaleReturnModel.fromJson(json as Map<String, dynamic>),
          page: page,
          size: size,
        );

        emit(BiReportGenerateSuccess(
          reportType: reportType,
          jobId: jobId,
          data: result.data,
          meta: result.meta,
        ));
        break;

      // stockbalance
      case BiReportType.stockBalance:
        final result = await _repository.getReportDetail<StockBalanceModel>(
          reportType: reportType,
          jobId: jobId,
          token: token,
          fromJsonT: (json) => StockBalanceModel.fromJson(json as Map<String, dynamic>),
          page: page,
          size: size,
        );

        emit(BiReportGenerateSuccess(
          reportType: reportType,
          jobId: jobId,
          data: result.data,
          meta: result.meta,
        ));
        break;
    }
  }

  String _getStatusMessage(String state, int progress) {
    switch (state) {
      case 'queued':
        return 'อยู่ในคิวรอ...';
      case 'processing':
        return 'กำลังประมวลผล... ($progress%)';
      case 'completed':
        return 'เสร็จสิ้น';
      case 'failed':
        return 'ล้มเหลว';
      default:
        return 'สถานะ: $state ($progress%)';
    }
  }

  String _formatErrorMessage(String? failedReason) {
    if (failedReason == null) return 'การสร้างรายงานล้มเหลวโดยไม่ทราบสาเหตุ';

    // แปลง error messages ที่พบบ่อยเป็นภาษาไทย
    if (failedReason.contains('invalid input syntax for type bigint')) {
      return 'รูปแบบข้อมูลไม่ถูกต้อง กรุณาตรวจสอบเงื่อนไขการค้นหา';
    } else if (failedReason.contains('timeout')) {
      return 'การประมวลผลใช้เวลานานเกินไป กรุณาลองใหม่';
    } else if (failedReason.contains('permission denied')) {
      return 'ไม่มีสิทธิ์เข้าถึงข้อมูล';
    } else if (failedReason.contains('connection')) {
      return 'เกิดปัญหาการเชื่อมต่อ กรุณาลองใหม่';
    }

    return 'การสร้างรายงานล้มเหลว: $failedReason';
  }

  // Step 3: Get report details
  Future<void> _onGetBiReportDetailRequested(
    GetBiReportDetailRequested event,
    Emitter<BiReportState> emit,
  ) async {
    try {
      emit(BiReportDetailLoading(
        reportType: event.reportType,
        jobId: event.jobId,
      ));

      // Use generic method to get report details
      await _getReportDetailByType(
        reportType: event.reportType,
        jobId: event.jobId,
        token: event.token,
        emit: emit,
        page: event.page ?? 1,
        size: event.size ?? 20,
      );
    } on BiReportException catch (e) {
      emit(BiReportDetailFailure(
        jobId: event.jobId,
        message: e.message,
        errorCode: e.code,
      ));
    } catch (e) {
      emit(BiReportDetailFailure(
        jobId: event.jobId,
        message: 'Unexpected error: ${e.toString()}',
      ));
    }
  }

  // Get report summary - แก้ไขให้เป็น generic
  Future<void> _onGetBiReportSummaryRequested(
    GetBiReportSummaryRequested event,
    Emitter<BiReportState> emit,
  ) async {
    try {
      emit(BiReportSummaryLoading(
        reportType: event.reportType,
        jobId: event.jobId,
      ));

      final summaryData = await _repository.getReportSummary(
        reportType: event.reportType,
        jobId: event.jobId,
        token: event.token,
      );

      // แยกการจัดการตาม reportType ด้วย generic method
      await _handleReportSummaryByType(
        emit: emit,
        event: event,
        summaryData: summaryData,
      );
    } catch (e) {
      print('Error fetching report summary: $e');
      print('Summary data type: ${e.runtimeType}');

      String errorMessage = 'เกิดข้อผิดพลาดในการดึงข้อมูลสรุปรายงาน';
      int? errorCode;

      if (e is BiReportException) {
        errorMessage = e.message;
        errorCode = e.code;
      } else if (e.toString().contains('type') || e.toString().contains('format')) {
        errorMessage = 'รูปแบบข้อมูลสรุปรายงานไม่ถูกต้อง';
      }

      emit(BiReportSummaryFailure(
        jobId: event.jobId,
        message: errorMessage,
        errorCode: errorCode,
      ));
    }
  }

  // Generic method to handle report summary by type
  Future<void> _handleReportSummaryByType({
    required Emitter<BiReportState> emit,
    required GetBiReportSummaryRequested event,
    required dynamic summaryData,
  }) async {
    try {
      if (summaryData is! Map<String, dynamic>) {
        throw Exception('Invalid summary data format: expected Map<String, dynamic>, got ${summaryData.runtimeType}');
      }

      switch (event.reportType) {
        case BiReportType.sale:
          final dataSum = SaleReportSummary.fromJson(summaryData["data"]);
          emit(BiReportSummarySuccess(
            reportType: event.reportType,
            jobId: event.jobId,
            summaryData: dataSum,
          ));
          break;

        case BiReportType.saleDaily:
          final dataSum = SaleDailyReportSummary.fromJson(summaryData["data"]);
          emit(BiReportSummarySuccess(
            reportType: event.reportType,
            jobId: event.jobId,
            dailySummaryData: dataSum,
          ));
          break;

        case BiReportType.stockMovement:
          final dataSum = StockMovmentSummaryModel.fromJson(summaryData["data"]);
          emit(BiReportSummarySuccess(
            reportType: event.reportType,
            jobId: event.jobId,
            stockMovementSummaryData: dataSum,
          ));
          break;

        case BiReportType.paymentDaily:
          final dataSum = PaymentDailySummaryModel.fromJson(summaryData["data"]);
          emit(BiReportSummarySuccess(
            reportType: event.reportType,
            jobId: event.jobId,
            paymentDailySummaryData: dataSum,
          ));
          break;

        case BiReportType.saleReturn:
          final dataSum = SaleReturnSummaryModel.fromJson(summaryData["data"]);
          emit(BiReportSummarySuccess(
            reportType: event.reportType,
            jobId: event.jobId,
            saleReturnSummaryData: dataSum,
          ));
          break;

        case BiReportType.stockBalance:
          final dataSum = StockBalanceSummaryModel.fromJson(summaryData["data"]);
          emit(BiReportSummarySuccess(
            reportType: event.reportType,
            jobId: event.jobId,
            stockBalanceSummaryData: dataSum,
          ));
          break;
      }
    } catch (e) {
      throw BiReportException(
        message: 'เกิดข้อผิดพลาดในการประมวลผลข้อมูลสรุป${event.reportType.displayName}: ${e.toString()}',
        code: 1000 + event.reportType.index,
      );
    }
  }

  // Reset state
  Future<void> _onResetBiReportState(
    ResetBiReportState event,
    Emitter<BiReportState> emit,
  ) async {
    emit(BiReportInitial());
  }

  @override
  Future<void> close() {
    _repository.dispose();
    return super.close();
  }
}

// Exception class for BI Report errors
class BiReportException implements Exception {
  final String message;
  final int code;

  const BiReportException({
    required this.message,
    required this.code,
  });

  @override
  String toString() => 'BiReportException($code): $message';
}
