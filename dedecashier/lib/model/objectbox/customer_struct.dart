import 'package:dedecashier/model/json/member_model.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class CustomerObjectBoxStruct {
  int id = 0;

  /// GUID ของลูกค้า
  String guidfixed;

  /// รหัสลูกค้า
  @Unique()
  @Index(type: IndexType.hash)
  String code;

  /// ชื่อลูกค้า
  @Index()
  String name;

  /// เบอร์โทรศัพท์
  @Index(type: IndexType.hash)
  String tel;

  /// อีเมล
  String email;

  /// ที่อยู่
  String address;

  /// ยอดแต้มคงเหลือ
  double pointbalance;

  /// รหัสแต้ม
  String pointscode;

  /// ระดับราคา
  String pricelevel;

  /// กลุ่มลูกค้า
  List<Group> groups;

  /// วันที่อัปเดตล่าสุด
  @Property(type: PropertyType.date)
  DateTime last_updated;
  CustomerObjectBoxStruct({
    required this.guidfixed,
    required this.code,
    required this.name,
    required this.tel,
    required this.email,
    required this.address,
    required this.pointbalance,
    String? pointscode,
    String? pricelevel,
    List<Group>? groups,
    DateTime? last_updated,
  }) : pointscode = pointscode ?? '',
       pricelevel = pricelevel ?? '',
       groups = groups ?? [],
       last_updated = last_updated ?? DateTime.now();
}
