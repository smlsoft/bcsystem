import 'package:dedekiosk/model/category_model.dart';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/model/trans_model.dart';

/// Data class สำหรับเก็บข้อมูล Background Task
/// ช่วยลดการ copy ตัวแปรมากเกินไปใน payAndSave
class BackgroundTaskData {
  // Order Info
  final String localBillId;
  final int billLedgerId;
  final String payloadChecksum;
  final String orderDocNumber;
  final int queueNumber;
  final String orderTagNumber;
  final int orderType;
  final DateTime docDateTime;
  final String discountWord;

  // Bill Values
  final BillData billData;

  // Global Values
  final GlobalData globalData;

  // Shop Profile Info
  final ShopData shopData;

  // Device Config
  final DeviceData deviceData;

  // Order Details
  final List<OrderTempDetailModel> orderTempDetailList;

  // Pay Condition
  final List<PayConditionModel> payCondition;

  BackgroundTaskData({
    required this.localBillId,
    required this.billLedgerId,
    required this.payloadChecksum,
    required this.orderDocNumber,
    required this.queueNumber,
    required this.orderTagNumber,
    required this.orderType,
    required this.docDateTime,
    required this.discountWord,
    required this.billData,
    required this.globalData,
    required this.shopData,
    required this.deviceData,
    required this.orderTempDetailList,
    required this.payCondition,
  });

  /// สร้าง BackgroundTaskData จาก global state และ bill
  factory BackgroundTaskData.fromCurrentState({
    String localBillId = '',
    int billLedgerId = 0,
    String payloadChecksum = '',
    required String orderDocNumber,
    required int queueNumber,
    required String orderTagNumber,
    required int orderType,
    required DateTime docDateTime,
    required String discountWord,
    required BillCalcAmount bill,
    required List<OrderTempDetailModel> orderTempDetailList,
    required String memberCode,
    required List<TransNameInfoModel> custNames,
    required String phoneNumber,
    required String tableNumber,
    required String orderId,
    required int isTakeAway,
    required int globalOrderType,
    required String saleChannelCode,
    required double saleChannelgp,
    required int saleChannelgptype,
    required String tableNumberSelectedOrdertagnumber,
    required List<PayConditionModel> payConditionList,
    required String shopName1,
    required String branchCode,
    required List<LanguageNameModel>? branchNames,
    required String orderStationCode,
    required double vatRate,
    required int vatType,
    required bool isVatRegister,
    required String deviceShopId,
    required String deviceBranchId,
    required String deviceOrderStationCode,
    required int deviceSystemCondition, // ข้อมูลแต้มสะสม
    double usePoint = 0,
    double getPoint = 0,
    double pointDiscountAmount = 0,
    double pointAmount = 0,
    double currentPointBalance = 0,
    String memberPointsCode = '',
    String memberGuidFixed = '',
    // BC Member
    String memberPinCode = '',
    bool isBCMember = false,
    String shopName = '',
    String bcMemberName = '',
    String bcMemberPicture = '',
  }) {
    return BackgroundTaskData(
      localBillId: localBillId,
      billLedgerId: billLedgerId,
      payloadChecksum: payloadChecksum,
      orderDocNumber: orderDocNumber,
      queueNumber: queueNumber,
      orderTagNumber: orderTagNumber,
      orderType: orderType,
      docDateTime: docDateTime,
      discountWord: discountWord,
      billData: BillData.fromBillCalcAmount(bill),
      globalData: GlobalData(
        memberCode: memberCode,
        custNames: List<TransNameInfoModel>.from(custNames),
        phoneNumber: phoneNumber,
        tableNumber: tableNumber,
        orderId: orderId,
        isTakeAway: isTakeAway,
        globalOrderType: globalOrderType,
        saleChannelCode: saleChannelCode,
        saleChannelgp: saleChannelgp,
        saleChannelgptype: saleChannelgptype,
        tableNumberSelectedOrdertagnumber: tableNumberSelectedOrdertagnumber,
        usePoint: usePoint,
        getPoint: getPoint,
        pointDiscountAmount: pointDiscountAmount,
        pointAmount: pointAmount,
        currentPointBalance: currentPointBalance,
        memberPointsCode: memberPointsCode,
        memberGuidFixed: memberGuidFixed,
        memberPinCode: memberPinCode,
        isBCMember: isBCMember,
        shopName: shopName,
        bcMemberName: bcMemberName,
        bcMemberPicture: bcMemberPicture,
      ),
      shopData: ShopData(
        shopName1: shopName1,
        branchCode: branchCode,
        branchNames: branchNames,
        orderStationCode: orderStationCode,
        vatRate: vatRate,
        vatType: vatType,
        isVatRegister: isVatRegister,
      ),
      deviceData: DeviceData(
        shopId: deviceShopId,
        branchId: deviceBranchId,
        orderStationCode: deviceOrderStationCode,
        systemCondition: deviceSystemCondition,
      ),
      orderTempDetailList: orderTempDetailList,
      payCondition: payConditionList
          .map((e) => PayConditionModel(
                payType: e.payType,
                payTypeName: e.payTypeName,
                amount: e.amount,
                payAmount: e.payAmount,
                changeAmount: e.changeAmount,
                roundAmount: e.roundAmount,
                approvalCode: e.approvalCode,
                cardNumber: e.cardNumber,
              ))
          .toList(),
    );
  }
}

/// ข้อมูล Bill ที่ต้องใช้ใน Background Task
class BillData {
  final double totalAmount;
  final double totalVatAmount;
  final double totalDiscount;
  final double diffAmount;
  final double saveAmount;
  final double amountBeforeCalcVat;
  final double amountAfterCalcVat;
  final double totalItemExceptVatAmount;
  final double totalAmountAfterDiscount;
  final double totalDiscountExceptVatAmount;
  final double totalDiscountVatAmount;
  final double detailTotalAmountBeforeDiscount;
  final double amountExceptVat;
  final double roundAmount;
  final double sumCreditCard;
  final double sumQrCode;

  BillData({
    required this.totalAmount,
    required this.totalVatAmount,
    required this.totalDiscount,
    required this.diffAmount,
    required this.saveAmount,
    required this.amountBeforeCalcVat,
    required this.amountAfterCalcVat,
    required this.totalItemExceptVatAmount,
    required this.totalAmountAfterDiscount,
    required this.totalDiscountExceptVatAmount,
    required this.totalDiscountVatAmount,
    required this.detailTotalAmountBeforeDiscount,
    required this.amountExceptVat,
    required this.roundAmount,
    required this.sumCreditCard,
    required this.sumQrCode,
  });

  factory BillData.fromBillCalcAmount(BillCalcAmount bill) {
    return BillData(
      totalAmount: bill.totalAmount,
      totalVatAmount: bill.totalVatAmount,
      totalDiscount: bill.totalDiscount,
      diffAmount: bill.diffAmount,
      saveAmount: bill.saveAmount,
      amountBeforeCalcVat: bill.amountBeforeCalcVat,
      amountAfterCalcVat: bill.amountAfterCalcVat,
      totalItemExceptVatAmount: bill.totalItemExceptVatAmount,
      totalAmountAfterDiscount: bill.totalAmountAfterDiscount,
      totalDiscountExceptVatAmount: bill.totalDiscountExceptVatAmount,
      totalDiscountVatAmount: bill.totalDiscountVatAmount,
      detailTotalAmountBeforeDiscount: bill.detailTotalAmountBeforeDiscount,
      amountExceptVat: bill.amountExceptVat,
      roundAmount: bill.roundAmount,
      sumCreditCard: bill.sumCreditCard,
      sumQrCode: bill.sumQrCode,
    );
  }
}

/// ข้อมูล Global State ที่ต้องใช้ใน Background Task
class GlobalData {
  final String memberCode;
  final List<TransNameInfoModel> custNames;
  final String phoneNumber;
  final String tableNumber;
  final String orderId;
  final int isTakeAway;
  final int globalOrderType;
  final String saleChannelCode;
  final double saleChannelgp;
  final int saleChannelgptype;
  final String tableNumberSelectedOrdertagnumber;
  // ข้อมูลแต้มสะสม
  final double usePoint; // แต้มที่ใช้
  final double getPoint; // แต้มที่จะได้รับ
  final double pointDiscountAmount; // ส่วนลดจากแต้ม (pointusagetype = 1)
  final double pointAmount; // ยอดชำระจากแต้ม (pointusagetype = 2)
  final double currentPointBalance; // แต้มคงเหลือหลังใช้แต้ม
  final String memberPointsCode; // รหัสแต้มสะสม
  final String memberGuidFixed; // GUID สมาชิก

  // BC Member
  final String memberPinCode; // PIN code หรือ line_uid สำหรับ BC Member
  final bool isBCMember; // flag ว่าเป็น BC Member หรือไม่
  final String shopName; // ชื่อร้านค้า (สำหรับส่ง BC Member API)
  final String bcMemberName; // ชื่อสมาชิก LINE
  final String bcMemberPicture; // รูปโปรไฟล์สมาชิก LINE

  GlobalData({
    required this.memberCode,
    required this.custNames,
    required this.phoneNumber,
    required this.tableNumber,
    required this.orderId,
    required this.isTakeAway,
    required this.globalOrderType,
    required this.saleChannelCode,
    required this.saleChannelgp,
    required this.saleChannelgptype,
    required this.tableNumberSelectedOrdertagnumber,
    this.usePoint = 0,
    this.getPoint = 0,
    this.pointDiscountAmount = 0,
    this.pointAmount = 0,
    this.currentPointBalance = 0,
    this.memberPointsCode = '',
    this.memberGuidFixed = '',
    this.memberPinCode = '',
    this.isBCMember = false,
    this.shopName = '',
    this.bcMemberName = '',
    this.bcMemberPicture = '',
  });
}

/// ข้อมูล Shop Profile ที่ต้องใช้ใน Background Task
class ShopData {
  final String shopName1;
  final String branchCode;
  final List<LanguageNameModel>? branchNames;
  final String orderStationCode;
  final double vatRate;
  final int vatType;
  final bool isVatRegister;

  ShopData({
    required this.shopName1,
    required this.branchCode,
    required this.branchNames,
    required this.orderStationCode,
    required this.vatRate,
    required this.vatType,
    required this.isVatRegister,
  });
}

/// ข้อมูล Device Config ที่ต้องใช้ใน Background Task
class DeviceData {
  final String shopId;
  final String branchId;
  final String orderStationCode;
  final int systemCondition;

  DeviceData({
    required this.shopId,
    required this.branchId,
    required this.orderStationCode,
    required this.systemCondition,
  });
}
