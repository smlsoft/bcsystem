import 'package:json_annotation/json_annotation.dart';

part 'import_product_model.g.dart';

@JsonSerializable()
class UploadSuccessModel {
  bool success;
  String id;

  UploadSuccessModel({
    required this.success,
    required this.id,
  });

  factory UploadSuccessModel.fromJson(Map<String, dynamic> json) => _$UploadSuccessModelFromJson(json);
  Map<String, dynamic> toJson() => _$UploadSuccessModelToJson(this);
}

@JsonSerializable()
class ImportProductModel {
  String? guidfixed;
  String? shopid;
  String? taskid;
  int? rownumber;
  String? barcode;
  String? name;
  String? unitcode;
  double? price;
  double? pricemember;
  double? pricedelivery;
  bool? isduplicate;
  bool? isexist;
  bool? isunitnotexist;

  ImportProductModel({
    String? guidfixed,
    String? shopid,
    String? taskid,
    int? rownumber,
    String? barcode,
    String? name,
    String? unitcode,
    double? price,
    double? pricemember,
    double? pricedelivery,
    bool? isduplicate,
    bool? isexist,
    bool? isunitnotexist,
  })  : guidfixed = guidfixed ?? '',
        shopid = shopid ?? '',
        taskid = taskid ?? '',
        rownumber = rownumber ?? 0,
        barcode = barcode ?? '',
        name = name ?? '',
        unitcode = unitcode ?? '',
        price = price ?? 0,
        pricemember = pricemember ?? 0,
        pricedelivery = pricedelivery ?? 0,
        isduplicate = isduplicate ?? false,
        isexist = isexist ?? false,
        isunitnotexist = isunitnotexist ?? false;

  factory ImportProductModel.fromJson(Map<String, dynamic> json) => _$ImportProductModelFromJson(json);
  Map<String, dynamic> toJson() => _$ImportProductModelToJson(this);
}
