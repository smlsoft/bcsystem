import 'package:objectbox/objectbox.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_temp_struct.g.dart';

@JsonSerializable(explicitToJson: true)
class OrderTempStruct {
  double orderQty;
  List<OrderTempObjectBoxStruct> orderTemp;

  OrderTempStruct({required this.orderQty, required this.orderTemp});

  factory OrderTempStruct.fromJson(Map<String, dynamic> json) =>
      _$OrderTempStructFromJson(json);

  Map<String, dynamic> toJson() => _$OrderTempStructToJson(this);
}

@JsonSerializable(explicitToJson: true)
@Entity()
class OrderTempObjectBoxStruct {
  int id;

  /// รหัส Order (โทรศัพท์,GUID โต๊ะ)
  @Index()
  String orderId;

  /// รหัส อ้างอิง
  @Index()
  String orderGuid;

  String guidPos;

  /// รหัส Order หลัก (โทรศัพท์,GUID โต๊ะ)
  @Index()
  String orderIdMain;

  /// UUID หน้าจอกรณีเลือกพร้อมกันหลายคน
  String machineId;

  /// เลขที่เอกสาร (สร้างเมื่อคิดเงินแล้ว)
  @Index()
  String docNo;

  @Property(type: PropertyType.date)
  DateTime orderDateTime;

  @Index(type: IndexType.hash)
  String barcode;

  /// จำนวนสั่ง (เมื่อจากกดส่งแล้ว)
  double orderQty;

  String orderHistory;

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

  /// ปิด (เก็บสะสม)
  bool isPaySuccess;

  /// ข้อเลือกพิเศษ
  String optionSelected;
  String remark;
  String remarkForCancel;

  @Index()
  String names;

  @Index(type: IndexType.hash)
  String unitCode;

  @Index()
  String unitName;

  String imageUri;
  bool takeAway;
  bool issumpoint;

  /// KDS System
  @Property(type: PropertyType.date)
  DateTime kdsSuccessTime;

  /// ครัวปรุงเสร็จ
  bool kdsSuccess;
  String kdsId;

  // เสริฟท์
  @Property(type: PropertyType.date)
  DateTime servedTime;
  bool servedSuccess;
  double servedQty;
  String servedHistory;

  // Delivery
  String deliveryNumber;
  String deliveryCode;
  String deliveryName;

  /// วันที่เวลาแก้ไขล่าสุด เพื่อให้ระบบอื่นนำไปใช้เป็นตัวเช็คว่ามีการแก้ไขหรือยัง
  @Property(type: PropertyType.date)
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
    String? orderId,
    String? guidPos,
    String? orderIdMain,
    String? orderGuid,
    String? docNo,
    String? machineId,
    DateTime? orderDateTime,
    String? barcode,
    double? price,
    double? amount,
    bool? isOrder,
    bool? isPaySuccess,
    String? optionSelected,
    String? remark,
    String? remarkForCancel,
    String? names,
    bool? takeAway,
    String? unitCode,
    String? unitName,
    String? imageUri,
    DateTime? kdsSuccessTime,
    bool? kdsSuccess,
    String? kdsId,
    DateTime? servedTime,
    bool? servedSuccess,
    double? servedQty,
    String? servedHistory,
    String? orderHistory,
    double? cancelQty,
    String? cancelHistory,
    double? qtyLastCancel,
    double? orderQty,
    String? deliveryNumber,
    String? deliveryCode,
    bool? isOrderReadySendKds,
    String? deliveryName,
    DateTime? lastUpdateDateTime,
    int? orderType,
    bool? issumpoint,
    String? orderEmployeeCode,
    String? orderEmployeeDetail,
    bool? isOrderSendDedeTempSuccess,
    bool? isOrderSendKdsSuccess,
    bool? isOrderSuccess,
  }) : orderId = orderId ?? '',
       issumpoint = issumpoint ?? false,
       guidPos = guidPos ?? '',
       orderIdMain = orderIdMain ?? '',
       orderGuid = orderGuid ?? '',
       docNo = docNo ?? '',
       machineId = machineId ?? '',
       orderDateTime = orderDateTime ?? DateTime.now(),
       barcode = barcode ?? '',
       price = price ?? 0.0,
       amount = amount ?? 0.0,
       isOrder = isOrder ?? false,
       isPaySuccess = isPaySuccess ?? false,
       optionSelected = optionSelected ?? '',
       remark = remark ?? '',
       remarkForCancel = remarkForCancel ?? '',
       names = names ?? '',
       takeAway = takeAway ?? false,
       unitCode = unitCode ?? '',
       unitName = unitName ?? '',
       imageUri = imageUri ?? '',
       kdsSuccessTime = kdsSuccessTime ?? DateTime.now(),
       kdsSuccess = kdsSuccess ?? false,
       kdsId = kdsId ?? '',
       servedTime = servedTime ?? DateTime.now(),
       servedSuccess = servedSuccess ?? false,
       servedQty = servedQty ?? 0.0,
       servedHistory = servedHistory ?? '',
       orderHistory = orderHistory ?? '',
       cancelQty = cancelQty ?? 0.0,
       cancelHistory = cancelHistory ?? '',
       qtyLastCancel = qtyLastCancel ?? 0.0,
       orderQty = orderQty ?? 0.0,
       deliveryNumber = deliveryNumber ?? '',
       deliveryCode = deliveryCode ?? '',
       isOrderReadySendKds = isOrderReadySendKds ?? false,
       deliveryName = deliveryName ?? '',
       lastUpdateDateTime = lastUpdateDateTime ?? DateTime.now(),
       orderType = orderType ?? 0,
       orderEmployeeCode = orderEmployeeCode ?? '',
       orderEmployeeDetail = orderEmployeeDetail ?? '',
       isOrderSendDedeTempSuccess = isOrderSendDedeTempSuccess ?? false,
       isOrderSendKdsSuccess = isOrderSendKdsSuccess ?? false,
       isOrderSuccess = isOrderSuccess ?? false;

  factory OrderTempObjectBoxStruct.fromJson(Map<String, dynamic> json) =>
      _$OrderTempObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() => _$OrderTempObjectBoxStructToJson(this);
}

@JsonSerializable(explicitToJson: true)
@Entity()
class OrderTempSyncObjectBoxStruct {
  int id;

  /// รหัส Order (โทรศัพท์,GUID โต๊ะ)
  String orderId;

  /// เลขที่เอกสาร (สร้างเมื่อคิดเงินแล้ว)
  String docNo;

  String guidPos;

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

  /// Order History
  String orderHistory;

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

  /// ปิด (เก็บสะสม)
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
  @Property(type: PropertyType.date)
  DateTime kdsSuccessTime;

  /// ครัวปรุงเสร็จ
  bool kdsSuccess;
  String kdsId;

  // เสริฟท์
  @Property(type: PropertyType.date)
  DateTime servedTime;
  bool servedSuccess;
  double servedQty;
  String servedHistory;

  // Delivery
  String deliveryNumber;
  String deliveryCode;
  String deliveryName;

  /// วันที่เวลาแก้ไขล่าสุด เพื่อให้ระบบอื่นนำไปใช้เป็นตัวเช็คว่ามีการแก้ไขหรือยัง
  @Property(type: PropertyType.date)
  DateTime lastUpdateDateTime;

  /// 0=พนักงานสั่ง,1=ลูกค้าสั่งเองด้วย Order Online
  int orderType;

  /// รหัสพนักงานสั่ง Order
  String orderEmployeeCode;
  String orderEmployeeDetail;

  // ส่งขึ้น dedetemp.ordertemplog สำเร็จ
  bool isOrderSendDedeTempSuccess;

  // กรณีไม่ได้สร้างเอกสาร (ปิดโต๊ะโดยไม่มีรายการ)
  bool orderEmtry = false;

  OrderTempSyncObjectBoxStruct({
    required this.id,
    String? orderId,
    String? docNo,
    String? guidPos,
    String? orderGuid,
    String? orderIdMain,
    String? machineId,
    DateTime? orderDateTime,
    String? barcode,
    double? price,
    double? amount,
    bool? isOrder,
    bool? isPaySuccess,
    String? optionSelected,
    String? remark,
    String? remarkForCancel,
    String? names,
    bool? takeAway,
    String? unitCode,
    String? unitName,
    String? imageUri,
    DateTime? kdsSuccessTime,
    bool? kdsSuccess,
    String? kdsId,
    DateTime? servedTime,
    bool? servedSuccess,
    double? servedQty,
    String? servedHistory,
    String? orderHistory,
    double? cancelQty,
    String? cancelHistory,
    double? qtyLastCancel,
    double? orderQty,
    String? deliveryNumber,
    String? deliveryCode,
    bool? isOrderReadySendKds,
    String? deliveryName,
    DateTime? lastUpdateDateTime,
    int? orderType,
    String? orderEmployeeCode,
    String? orderEmployeeDetail,
    bool? isOrderSendDedeTempSuccess,
    bool? isOrderSendKdsSuccess,
    bool? isOrderSuccess,
    bool? orderEmtry,
  }) : orderId = orderId ?? '',
       docNo = docNo ?? '',
       guidPos = guidPos ?? '',
       orderGuid = orderGuid ?? '',
       orderIdMain = orderIdMain ?? '',
       machineId = machineId ?? '',
       orderDateTime = orderDateTime ?? DateTime.now(),
       barcode = barcode ?? '',
       price = price ?? 0.0,
       amount = amount ?? 0.0,
       isOrder = isOrder ?? false,
       isPaySuccess = isPaySuccess ?? false,
       optionSelected = optionSelected ?? '',
       remark = remark ?? '',
       remarkForCancel = remarkForCancel ?? '',
       names = names ?? '',
       takeAway = takeAway ?? false,
       unitCode = unitCode ?? '',
       unitName = unitName ?? '',
       imageUri = imageUri ?? '',
       kdsSuccessTime = kdsSuccessTime ?? DateTime.now(),
       kdsSuccess = kdsSuccess ?? false,
       kdsId = kdsId ?? '',
       servedTime = servedTime ?? DateTime.now(),
       servedSuccess = servedSuccess ?? false,
       servedQty = servedQty ?? 0.0,
       servedHistory = servedHistory ?? '',
       orderHistory = orderHistory ?? '',
       cancelQty = cancelQty ?? 0.0,
       cancelHistory = cancelHistory ?? '',
       qtyLastCancel = qtyLastCancel ?? 0.0,
       orderQty = orderQty ?? 0.0,
       deliveryNumber = deliveryNumber ?? '',
       deliveryCode = deliveryCode ?? '',
       isOrderReadySendKds = isOrderReadySendKds ?? false,
       deliveryName = deliveryName ?? '',
       lastUpdateDateTime = lastUpdateDateTime ?? DateTime.now(),
       orderType = orderType ?? 0,
       orderEmployeeCode = orderEmployeeCode ?? '',
       orderEmployeeDetail = orderEmployeeDetail ?? '',
       isOrderSendDedeTempSuccess = isOrderSendDedeTempSuccess ?? false,
       isOrderSendKdsSuccess = isOrderSendKdsSuccess ?? false,
       isOrderSuccess = isOrderSuccess ?? false,
       orderEmtry = orderEmtry ?? false;

  factory OrderTempSyncObjectBoxStruct.fromJson(Map<String, dynamic> json) =>
      _$OrderTempSyncObjectBoxStructFromJson(json);

  Map<String, dynamic> toJson() => _$OrderTempSyncObjectBoxStructToJson(this);
}
