import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:objectbox/objectbox.dart';

part 'shift_struct.g.dart';

@JsonSerializable(explicitToJson: true)
@Entity()
class ShiftObjectBoxStruct {
  int id = 0;

  @Unique()
  @Index(type: IndexType.hash)
  String guidfixed;

  /// 1=เปิดกะ,2=ปิดกะ,3=รับเงินทอนเพิ่ม,4=นำเงินออก
  int doctype;

  @Property(type: PropertyType.date)
  DateTime docdate;

  @Index(type: IndexType.hash)
  String usercode;

  @Index()
  String username;

  String remark;

  /// เงินสด
  double amount;

  /// บัตรเครดิต
  double creditcard;

  /// promptpay
  double promptpay;

  /// โอนเงิน
  double transfer;

  /// เช็ค
  double cheque;

  /// coupon
  double coupon;

  bool isSync;

  String posid;

  String docno;

  ShiftObjectBoxStruct({
    required this.guidfixed,
    required this.doctype,
    required this.docdate,
    required this.remark,
    required this.usercode,
    required this.username,
    required this.amount,
    required this.creditcard,
    required this.promptpay,
    required this.transfer,
    required this.cheque,
    required this.coupon,
    required this.isSync,
    required this.posid,
    required this.docno,
  });

  factory ShiftObjectBoxStruct.fromJson(Map<String, dynamic> json) =>
      _$ShiftObjectBoxStructFromJson(json);

  Map<String, dynamic> toJson() => _$ShiftObjectBoxStructToJson(this);
}
