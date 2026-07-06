import 'package:objectbox/objectbox.dart';
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
@Entity()
class OrderTempObjectBoxStruct {
  int id;

  /// รหัส Order (โทรศัพท์,GUID โต๊ะ)
  String orderId;

  /// รหัส อ้างอิง
  String orderGuid;

  /// รหัส Order หลัก (โทรศัพท์,GUID โต๊ะ)
  String orderIdMain;

  /// UUID หน้าจอกรณีเลือกพร้อมกันหลายคน
  String machineId;

  @Property(type: PropertyType.date)
  DateTime orderDateTime;
  String barcode;

  /// จำนวนสั่ง (เมื่อจากกดส่งแล้ว)
  double orderQty;

  /// จำนวนจริง หลังจากหักยกเลิก
  double qty;

  /// จำนวนยกเลิก (เมื่อกดส่งแล้วมีการยกเลิก)
  double cancelQty;

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

  /// ปิด (เก็บสะสม)
  bool isPaySuccess;

  /// ข้อเลือกพิเศษ
  String optionSelected;
  String remark;
  String names;
  String unitCode;
  String unitName;
  String imageUri;
  bool takeAway;

  /// KDS System
  @Property(type: PropertyType.date)
  DateTime kdsSuccessTime;

  /// ครัวปรุงเสร็จ
  bool kdsSuccess;
  String kdsId;

  // Delivery
  String deliveryNumber;
  String deliveryCode;
  String deliveryName;

  /// วันที่เวลาแก้ไขล่าสุด เพื่อให้ระบบอื่นนำไปใช้เป็นตัวเช็คว่ามีการแก้ไขหรือยัง
  @Property(type: PropertyType.date)
  DateTime lastUpdateDateTime;

  OrderTempObjectBoxStruct({
    required this.id,
    required this.orderId,
    required this.orderIdMain,
    required this.orderGuid,
    required this.machineId,
    required this.orderDateTime,
    required this.barcode,
    required this.qty,
    required this.price,
    required this.amount,
    required this.isOrder,
    required this.isPaySuccess,
    required this.optionSelected,
    required this.remark,
    required this.names,
    required this.takeAway,
    required this.unitCode,
    required this.unitName,
    required this.imageUri,
    required this.kdsSuccessTime,
    required this.kdsSuccess,
    required this.isOrderSuccess,
    required this.isOrderSendKdsSuccess,
    required this.kdsId,
    required this.cancelQty,
    required this.orderQty,
    required this.deliveryNumber,
    required this.deliveryCode,
    required this.isOrderReadySendKds,
    required this.deliveryName,
    required this.lastUpdateDateTime,
  });

  factory OrderTempObjectBoxStruct.fromJson(Map<String, dynamic> json) =>
      _$OrderTempObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() => _$OrderTempObjectBoxStructToJson(this);
}

