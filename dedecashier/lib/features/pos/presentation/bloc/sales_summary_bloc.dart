import 'package:bloc/bloc.dart';
import 'package:dedecashier/model/objectbox/bill_struct.dart';
import 'package:dedecashier/model/objectbox/shift_struct.dart';
import 'package:dedecashier/objectbox.g.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/features/pos/presentation/models/shift_report_model.dart';

part 'sales_summary_event.dart';
part 'sales_summary_state.dart';
part 'sales_summary_bloc.freezed.dart';

class SalesSummaryBloc extends Bloc<SalesSummaryEvent, SalesSummaryState> {
  SalesSummaryBloc() : super(SalesSummaryState.initial()) {
    on<LoadSalesSummary>(_onLoadSalesSummary);
    on<FilterSalesByDate>(_onFilterByDate);
    on<FilterSalesByShift>(_onFilterByShift);
    on<ClearSalesFilters>(_onClearFilters);
    on<LoadShiftReports>(_onLoadShiftReports);
    on<LoadMoneyTransferReports>(_onLoadMoneyTransferReports);
    on<LoadPaymentReports>(_onLoadPaymentReports);
  }
  Future<void> _onLoadSalesSummary(LoadSalesSummary event, Emitter<SalesSummaryState> emit) async {
    // ⭐ ใช้ copyWith เพื่อคงข้อมูล tab อื่นไว้
    emit(state.copyWith(isLoadingSalesReport: true, errorMessage: null));
    try {
      // Get all bills (sales transactions)
      final billBox = global.objectBoxStore.box<BillObjectBoxStruct>();
      final shiftBox = global.objectBoxStore.box<ShiftObjectBoxStruct>(); // Get all shifts and sort by docdate ascending
      final allShifts = shiftBox.getAll();
      allShifts.sort((a, b) => a.docdate.compareTo(b.docdate));

      // Process shifts to pair open and close shifts
      final shifts = <ShiftObjectBoxStruct>[];
      final shiftCloseMap = <String, ShiftObjectBoxStruct>{};

      // First pass: create map of close shifts keyed by docno+posid
      for (final shift in allShifts) {
        if (shift.doctype == 2) {
          final key = '${shift.docno}_${shift.posid}';
          shiftCloseMap[key] = shift;
        }
      }

      // Second pass: add open shifts and store close shift info
      for (final shift in allShifts) {
        if (shift.doctype == 1) {
          // Add all open shifts to dropdown (both with and without close)
          shifts.add(shift);
        }
      } // Build base query condition - Sales mode only and not cancelled
      var condition = BillObjectBoxStruct_.doc_mode.equals(1).and(BillObjectBoxStruct_.is_cancel.equals(false));

      // Apply date filtering if provided
      if (event.startDate != null && event.endDate != null) {
        final startDate = DateTime(event.startDate!.year, event.startDate!.month, event.startDate!.day);
        final endDate = DateTime(event.endDate!.year, event.endDate!.month, event.endDate!.day, 23, 59, 59);
        condition = condition.and(BillObjectBoxStruct_.date_time.between(startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch));
      } // Apply shift filtering if provided
      if (event.shiftId != null && event.shiftId!.isNotEmpty) {
        // Find the selected open shift (doctype = 1)
        final selectedShift = shifts.firstWhere(
          (shift) => shift.guidfixed == event.shiftId,
          orElse: () => ShiftObjectBoxStruct(
            guidfixed: '',
            doctype: 1,
            docdate: DateTime.now(),
            remark: '',
            usercode: '',
            username: '',
            amount: 0,
            creditcard: 0,
            promptpay: 0,
            transfer: 0,
            cheque: 0,
            coupon: 0,
            isSync: false,
            posid: '',
            docno: '',
          ),
        );

        if (selectedShift.guidfixed.isNotEmpty) {
          // Find corresponding close shift (doctype = 2) with same docno and posid
          final closeShift = allShifts.where((shift) => shift.doctype == 2 && shift.docno == selectedShift.docno && shift.posid == selectedShift.posid).firstOrNull;
          if (closeShift != null) {
            // Case 2: เปิดกะ มีปิดกะ - filter between เปิดกะ and ปิดกะ
            final shiftStartTime = selectedShift.docdate;
            final shiftEndTime = closeShift.docdate;

            // Apply shift time filtering (this will override date filtering if both are present)
            condition = BillObjectBoxStruct_.doc_mode
                .equals(1)
                .and(BillObjectBoxStruct_.is_cancel.equals(false))
                .and(BillObjectBoxStruct_.date_time.between(shiftStartTime.millisecondsSinceEpoch, shiftEndTime.millisecondsSinceEpoch));
          } else {
            // Case 1: เปิดกะ ไม่มีปิดกะ - filter docdate >= เวลาเปิดกะ
            final shiftStartTime = selectedShift.docdate;
            condition = BillObjectBoxStruct_.doc_mode
                .equals(1)
                .and(BillObjectBoxStruct_.is_cancel.equals(false))
                .and(BillObjectBoxStruct_.date_time.greaterOrEqual(shiftStartTime.millisecondsSinceEpoch));
          }
        }
      }

      // Create query with final condition
      final query = billBox.query(condition); // Execute query and get results
      final salesData = query.build().find();

      // Sort sales data by most recent date first (newest to oldest)
      salesData.sort((a, b) => b.date_time.compareTo(a.date_time));

      // Calculate totals
      double totalAmount = 0;
      int totalTransactions = salesData.length;

      for (final sale in salesData) {
        totalAmount += sale.total_amount;
      }
      // ⭐ ใช้ copyWith เพื่อคงข้อมูล tab อื่นไว้
      emit(
        state.copyWith(
          salesData: salesData,
          shifts: shifts,
          shiftCloseMap: shiftCloseMap,
          startDate: event.startDate,
          endDate: event.endDate,
          selectedShiftId: event.shiftId,
          totalAmount: totalAmount,
          totalTransactions: totalTransactions,
          isLoadingSalesReport: false,
          isSalesReportLoaded: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoadingSalesReport: false, errorMessage: 'Failed to load sales data: ${e.toString()}'));
    }
  }

  Future<void> _onFilterByDate(FilterSalesByDate event, Emitter<SalesSummaryState> emit) async {
    // ⭐ ใช้ state โดยตรง (ไม่ต้อง cast แล้ว)
    add(LoadSalesSummary(startDate: event.startDate, endDate: event.endDate, shiftId: state.selectedShiftId));
  }

  Future<void> _onFilterByShift(FilterSalesByShift event, Emitter<SalesSummaryState> emit) async {
    // ⭐ ใช้ state โดยตรง (ไม่ต้อง cast แล้ว)
    add(LoadSalesSummary(startDate: state.startDate, endDate: state.endDate, shiftId: event.shiftId));
  }

  Future<void> _onClearFilters(ClearSalesFilters event, Emitter<SalesSummaryState> emit) async {
    add(const LoadSalesSummary());
  }

  Future<void> _onLoadShiftReports(LoadShiftReports event, Emitter<SalesSummaryState> emit) async {
    // ⭐ ใช้ copyWith เพื่อคงข้อมูล tab อื่นไว้
    emit(state.copyWith(isLoadingShiftReports: true, errorMessage: null));
    try {
      final billBox = global.objectBoxStore.box<BillObjectBoxStruct>();
      final shiftBox = global.objectBoxStore.box<ShiftObjectBoxStruct>();

      // Get all shifts and sort by docdate ascending
      final allShifts = shiftBox.getAll();
      allShifts.sort((a, b) => a.docdate.compareTo(b.docdate));

      // Apply date filtering if provided
      final filteredShifts = <ShiftObjectBoxStruct>[];
      if (event.startDate != null && event.endDate != null) {
        final startDate = DateTime(event.startDate!.year, event.startDate!.month, event.startDate!.day);
        final endDate = DateTime(event.endDate!.year, event.endDate!.month, event.endDate!.day, 23, 59, 59);

        for (final shift in allShifts) {
          if (shift.docdate.isAfter(startDate.subtract(const Duration(seconds: 1))) && shift.docdate.isBefore(endDate.add(const Duration(seconds: 1)))) {
            filteredShifts.add(shift);
          }
        }
      } else {
        filteredShifts.addAll(allShifts);
      }

      // Find closed shifts only (with both open and close)
      final shiftReports = <ShiftReportModel>[];
      final processedDocnos = <String>{};

      for (final shift in filteredShifts) {
        if (shift.doctype == 1 && !processedDocnos.contains(shift.docno)) {
          // Find corresponding close shift in filtered results
          final closeShift = filteredShifts.where((s) => s.doctype == 2 && s.docno == shift.docno && s.posid == shift.posid).firstOrNull;

          if (closeShift != null) {
            processedDocnos.add(shift.docno);

            // Calculate sales data for this shift
            final shiftStartTime = shift.docdate;
            final shiftEndTime = closeShift.docdate;

            // Get bills for this shift period
            final billCondition = BillObjectBoxStruct_.doc_mode
                .equals(1)
                .and(BillObjectBoxStruct_.is_cancel.equals(false))
                .and(BillObjectBoxStruct_.date_time.between(shiftStartTime.millisecondsSinceEpoch, shiftEndTime.millisecondsSinceEpoch));

            final billQuery = billBox.query(billCondition);
            final bills = billQuery.build().find(); // Calculate payment totals from bills
            double totalCash = 0;
            double totalQr = 0;
            double totalCreditCard = 0;
            double totalTransfer = 0;
            double totalCheque = 0;
            double totalCoupon = 0;
            double totalCredit = 0;
            double totalPoint = 0;
            double totalChange = 0;
            for (final bill in bills) {
              totalCash += (bill.pay_cash_amount - bill.pay_cash_change);
              totalQr += bill.sum_qr_code;
              totalCreditCard += bill.sum_credit_card;
              totalTransfer += bill.sum_money_transfer;
              totalCheque += bill.sum_cheque;
              totalCoupon += bill.sum_coupon;
              totalCredit += bill.sum_credit;
              totalPoint += bill.paypointamount;
              totalChange += bill.pay_cash_change;
            } // Calculate added/withdrawn money (doctype 3 and 4)
            final moneyShifts = filteredShifts
                .where((s) => (s.doctype == 3 || s.doctype == 4) && s.docdate.isAfter(shiftStartTime) && s.docdate.isBefore(shiftEndTime) && s.posid == shift.posid)
                .toList();

            double addedMoney = 0;
            double withdrawnMoney = 0;

            for (final moneyShift in moneyShifts) {
              if (moneyShift.doctype == 3) {
                addedMoney += moneyShift.amount;
              } else if (moneyShift.doctype == 4) {
                withdrawnMoney += moneyShift.amount;
              }
            }

            // Calculate drawer amount = opening amount + added money - withdrawn money + cash sales - change given
            final drawerAmount = shift.amount + addedMoney - withdrawnMoney + totalCash - totalChange;
            final shiftReport = ShiftReportModel(
              openShift: shift,
              closeShift: closeShift,
              totalCash: totalCash,
              totalQr: totalQr,
              totalCreditCard: totalCreditCard,
              totalTransfer: totalTransfer,
              totalCheque: totalCheque,
              totalCoupon: totalCoupon,
              totalCredit: totalCredit,
              totalPoint: totalPoint,
              addedMoney: addedMoney,
              withdrawnMoney: withdrawnMoney,
              totalChange: totalChange,
              drawerAmount: drawerAmount,
              totalTransactions: bills.length,
            );

            shiftReports.add(shiftReport);
          }
        }
      } // Sort shift reports by close date descending (newest first)
      shiftReports.sort((a, b) => b.closeShift.docdate.compareTo(a.closeShift.docdate));

      // ⭐ ใช้ copyWith เพื่อคงข้อมูล tab อื่นไว้
      emit(state.copyWith(shiftReports: shiftReports, isLoadingShiftReports: false, isShiftReportsLoaded: true));
    } catch (e) {
      emit(state.copyWith(isLoadingShiftReports: false, errorMessage: 'Failed to load shift reports: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMoneyTransferReports(LoadMoneyTransferReports event, Emitter<SalesSummaryState> emit) async {
    // ⭐ ใช้ copyWith เพื่อคงข้อมูล tab อื่นไว้
    emit(state.copyWith(isLoadingMoneyTransfer: true, errorMessage: null));
    try {
      final shiftBox = global.objectBoxStore.box<ShiftObjectBoxStruct>();

      var condition = ShiftObjectBoxStruct_.doctype.equals(4);

      if (event.startDate != null && event.endDate != null) {
        final startDate = DateTime(event.startDate!.year, event.startDate!.month, event.startDate!.day);
        final endDate = DateTime(event.endDate!.year, event.endDate!.month, event.endDate!.day, 23, 59, 59);
        condition = condition.and(ShiftObjectBoxStruct_.docdate.between(startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch));
      }

      final query = shiftBox.query(condition);
      final moneyTransferShifts = query.build().find();

      moneyTransferShifts.sort((a, b) => b.docdate.compareTo(a.docdate));

      // ⭐ ใช้ copyWith เพื่อคงข้อมูล tab อื่นไว้
      emit(state.copyWith(moneyTransferReports: moneyTransferShifts, isLoadingMoneyTransfer: false, isMoneyTransferLoaded: true));
    } catch (e) {
      emit(state.copyWith(isLoadingMoneyTransfer: false, errorMessage: 'Failed to load money transfer reports: ${e.toString()}'));
    }
  }

  Future<void> _onLoadPaymentReports(LoadPaymentReports event, Emitter<SalesSummaryState> emit) async {
    // ⭐ ใช้ copyWith เพื่อคงข้อมูล tab อื่นไว้
    emit(state.copyWith(isLoadingPaymentReports: true, errorMessage: null));
    try {
      final billBox = global.objectBoxStore.box<BillObjectBoxStruct>();

      Condition<BillObjectBoxStruct> condition = BillObjectBoxStruct_.doc_mode.equals(1).and(BillObjectBoxStruct_.is_cancel.equals(false));

      if (event.startDate != null && event.endDate != null) {
        final startOfDay = DateTime(event.startDate!.year, event.startDate!.month, event.startDate!.day);
        final endOfDay = DateTime(event.endDate!.year, event.endDate!.month, event.endDate!.day, 23, 59, 59, 999);

        condition = condition.and(BillObjectBoxStruct_.date_time.between(startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch));
      }

      final query = billBox.query(condition);
      final salesTransactions = query.build().find();
      salesTransactions.sort((a, b) => b.date_time.compareTo(a.date_time));

      // ⭐ ใช้ copyWith เพื่อคงข้อมูล tab อื่นไว้
      emit(state.copyWith(salesTransactions: salesTransactions, isLoadingPaymentReports: false, isPaymentReportsLoaded: true));
    } catch (e) {
      emit(state.copyWith(isLoadingPaymentReports: false, errorMessage: 'Failed to load payment reports: $e'));
    }
  }
}
