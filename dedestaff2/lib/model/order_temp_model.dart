import 'package:dedeorder/model/global_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_temp_model.g.dart';

@JsonSerializable(explicitToJson: true)
class OrderTempStruct {
  double orderQty;
  List<OrderTempObjectBoxStruct> orderTemp;

  OrderTempStruct({
    required this.orderQty,
    required this.orderTemp,
  });

  factory OrderTempStruct.fromJson(Map<String, dynamic> json) =>
      _$OrderTempStructFromJson(json);

  Map<String, dynamic> toJson() => _$OrderTempStructToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OrderTempObjectBoxStruct {
  int id;

  /// รหัส Order (โทรศัพท์,GUID โต๊ะ)
  String orderId;

  /// รหัส Order หลัก (โทรศัพท์,GUID โต๊ะ)
  String orderIdMain;

  /// รหัส อ้างอิง
  String orderGuid;

  /// เลขที่เอกสาร (สร้างเมื่อคิดเงินแล้ว)
  String docNo;

  /// UUID หน้าจอกรณีเลือกพร้อมกันหลายคน
  String machineId;
  DateTime orderDateTime;
  String barcode;

  /// จำนวนสั่ง (เมื่อจากกดส่งแล้ว)
  double orderQty;

  /// จำนวนยกเลิก (เมื่อกดส่งแล้วมีการยกเลิก)
  double cancelQty;
  String cancelHistory;

  /// จำนวนยกเลิกล่าสุด
  double qtyLastCancel;

  double price;
  double amount;

  /// สถานะล่าสุด True=กำลังรับ Order,False=จบการรับ Order
  bool isOrder;

  /// สั่งเรียบร้อย (รอคิดเงิน)
  bool isOrderSuccess;

  /// ส่งเข้าครัวเรียบร้อย
  bool isOrderSendKdsSuccess;

  /// รายการนี้รอส่งเข้าครัว
  bool isOrderReadySendKds;

  /// ปิดแล้ว (เก็บไว้)
  bool isPaySuccess;

  /// ข้อเลือกพิเศษ
  String optionSelected;
  String remark;
  String remarkForCancel;
  String names;
  String unitCode;
  String unitName;
  String imageUri;
  bool takeAway;

  /// KDS System
  DateTime kdsSuccessTime;

  /// ครัวปรุงเสร็จ
  bool kdsSuccess;
  String kdsId;

  String orderHistory;

  // เสริฟท์
  DateTime servedTime;
  bool servedSuccess;
  double servedQty;
  String servedHistory;

  // Delivery
  String deliveryNumber;
  String deliveryCode;
  String deliveryName;

  /// วันที่เวลาแก้ไขล่าสุด เพื่อให้ระบบอื่นนำไปใช้เป็นตัวเช็คว่ามีการแก้ไขหรือยัง
  DateTime lastUpdateDateTime;

  /// 0=พนักงานสั่ง,1=ลูกค้าสั่งเองด้วย Order Online
  int orderType;

  /// รหัสพนักงานสั่ง Order
  String orderEmployeeCode;
  String orderEmployeeDetail;

  // ส่งขึ้น dedetemp.ordertemplog สำเร็จ
  bool isOrderSendDedeTempSuccess;

  OrderTempObjectBoxStruct({
    required this.id,
    required this.orderId,
    required this.docNo,
    required this.orderIdMain,
    required this.orderGuid,
    required this.machineId,
    required this.orderDateTime,
    required this.barcode,
    required this.qtyLastCancel,
    required this.price,
    required this.amount,
    required this.isOrder,
    required this.isPaySuccess,
    required this.optionSelected,
    required this.remark,
    required this.remarkForCancel,
    required this.names,
    required this.takeAway,
    required this.unitCode,
    required this.unitName,
    required this.imageUri,
    required this.orderHistory,
    required this.kdsSuccessTime,
    required this.kdsSuccess,
    required this.isOrderSuccess,
    required this.isOrderSendKdsSuccess,
    required this.kdsId,
    required this.cancelQty,
    required this.cancelHistory,
    required this.orderQty,
    required this.deliveryNumber,
    required this.deliveryCode,
    required this.isOrderReadySendKds,
    required this.deliveryName,
    required this.lastUpdateDateTime,
    required this.servedTime,
    required this.servedSuccess,
    required this.servedQty,
    required this.servedHistory,
    required this.orderType,
    required this.orderEmployeeCode,
    required this.orderEmployeeDetail,
    required this.isOrderSendDedeTempSuccess,
  });

  factory OrderTempObjectBoxStruct.fromJson(Map<String, dynamic> json) =>
      _$OrderTempObjectBoxStructFromJson(json);

  Map<String, dynamic> toJson() => _$OrderTempObjectBoxStructToJson(this);
}
