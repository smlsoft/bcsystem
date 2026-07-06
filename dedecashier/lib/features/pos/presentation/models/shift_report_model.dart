import 'package:dedecashier/model/objectbox/shift_struct.dart';

class ShiftReportModel {
  final ShiftObjectBoxStruct openShift;
  final ShiftObjectBoxStruct closeShift;
  final double totalCash; // ยอดเงินสด
  final double totalQr; // ชำระโดย QR
  final double totalCreditCard; // บัตรเครดิต
  final double totalTransfer; // โอนเงิน
  final double totalCheque; // เช็ค
  final double totalCoupon; // คูปอง
  final double totalCredit; // เงินเชื่อ
  final double totalPoint; // จ่ายด้วย Point
  final double addedMoney; // เงินทอนที่เพิ่ม (doctype=3)
  final double withdrawnMoney; // เงินที่ถอน (doctype=4)
  final double totalChange; // เงินทอนทั้งหมด
  final double drawerAmount; // จำนวนเงินในลิ้นชัก
  final int totalTransactions; // จำนวนรายการ
  const ShiftReportModel({
    required this.openShift,
    required this.closeShift,
    required this.totalCash,
    required this.totalQr,
    required this.totalCreditCard,
    required this.totalTransfer,
    required this.totalCheque,
    required this.totalCoupon,
    required this.totalCredit,
    required this.totalPoint,
    required this.addedMoney,
    required this.withdrawnMoney,
    required this.totalChange,
    required this.drawerAmount,
    required this.totalTransactions,
  });
  ShiftReportModel copyWith({
    ShiftObjectBoxStruct? openShift,
    ShiftObjectBoxStruct? closeShift,
    double? totalCash,
    double? totalQr,
    double? totalCreditCard,
    double? totalTransfer,
    double? totalCheque,
    double? totalCoupon,
    double? totalCredit,
    double? totalPoint,
    double? addedMoney,
    double? withdrawnMoney,
    double? totalChange,
    double? drawerAmount,
    int? totalTransactions,
  }) {
    return ShiftReportModel(
      openShift: openShift ?? this.openShift,
      closeShift: closeShift ?? this.closeShift,
      totalCash: totalCash ?? this.totalCash,
      totalQr: totalQr ?? this.totalQr,
      totalCreditCard: totalCreditCard ?? this.totalCreditCard,
      totalTransfer: totalTransfer ?? this.totalTransfer,
      totalCheque: totalCheque ?? this.totalCheque,
      totalCoupon: totalCoupon ?? this.totalCoupon,
      totalCredit: totalCredit ?? this.totalCredit,
      totalPoint: totalPoint ?? this.totalPoint,
      addedMoney: addedMoney ?? this.addedMoney,
      withdrawnMoney: withdrawnMoney ?? this.withdrawnMoney,
      totalChange: totalChange ?? this.totalChange,
      drawerAmount: drawerAmount ?? this.drawerAmount,
      totalTransactions: totalTransactions ?? this.totalTransactions,
    );
  }
}
