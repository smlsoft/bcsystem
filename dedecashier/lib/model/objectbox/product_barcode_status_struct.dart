// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';
import 'package:objectbox/objectbox.dart';

part 'product_barcode_status_struct.g.dart';

@JsonSerializable()
@Entity()
class ProductBarcodeStatusObjectBoxStruct {
  int id = 0;

  /// Barcode สินค้า
  @Unique()
  @Index(type: IndexType.hash)
  String barcode;

  /// 0=ปรกติมีสินค้า,1=สินค้าหมด,2=สินค้าหมดอัตโนมัติเมื่อยอดคงเหลือเป็นศูนย์
  int orderStatus;

  // สินค้าหมดอัตโนมัติเมื่อยอดคงเหลือเป็นศูนย์ (True,False)
  bool orderAutoStock;

  // เลิกขาย (ไม่แสดง) True,False
  bool orderDisable;

  /// ยอดคงเหลือเริ่มต้น (เมื่อกด เริ่มต้น)
  double qtyStart;

  /// ยอดคงเหลือ
  double qtyBalance;

  /// เตือนเมื่อต่ำกว่า (เพื่อผลิต)
  double qtyMin;

  ProductBarcodeStatusObjectBoxStruct({
    required this.barcode,
    required this.orderStatus,
    required this.orderDisable,
    required this.orderAutoStock,
    required this.qtyStart,
    required this.qtyBalance,
    required this.qtyMin,
  });

  factory ProductBarcodeStatusObjectBoxStruct.fromJson(
    Map<String, dynamic> json,
  ) => _$ProductBarcodeStatusObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() =>
      _$ProductBarcodeStatusObjectBoxStructToJson(this);
}
