import 'package:json_annotation/json_annotation.dart';
import 'package:cocomerchant_lite/model/global_model.dart';

part 'customer_address_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CustomerAddressModel {
  late String guid;

  /// ที่อยู่
  late List<String> address;

  /// รหัสประเทศ
  late String countrycode;

  /// รหัสจังหวัด
  late String provincecode;

  /// รหัสอำเภอ
  late String districtcode;

  /// รหัสตำบล
  late String subdistrictcode;

  /// รหัสไปรษณีย์
  late String zipcode;

  /// ผู้ติดต่อ
  late List<LanguageDataModel> contactnames;

  /// เบอร์โทร
  late String phoneprimary;

  /// เบอร์โทรสำรอง
  late String phonesecondary;

  /// ตำแหน่งดาวเทียม
  late double latitude;
  late double longitude;

  CustomerAddressModel({
    required this.guid,
    required this.address,
    required this.countrycode,
    required this.provincecode,
    required this.districtcode,
    required this.subdistrictcode,
    required this.zipcode,
    required this.latitude,
    required this.longitude,
    required this.contactnames,
    required this.phoneprimary,
    required this.phonesecondary,
  });

  factory CustomerAddressModel.fromJson(Map<String, dynamic> json) => _$CustomerAddressModelFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerAddressModelToJson(this);
}
