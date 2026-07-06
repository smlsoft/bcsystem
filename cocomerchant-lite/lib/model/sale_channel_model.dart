import 'package:json_annotation/json_annotation.dart';

part 'sale_channel_model.g.dart';

@JsonSerializable()
class SaleChannelModel {
  String? guidfixed;
  String? code;
  int? gp;
  int? gptype;
  String? imageuri;
  String? name;

  SaleChannelModel({
    String? guidfixed,
    String? code,
    int? gp,
    int? gptype,
    String? imageuri,
    String? name,
  })  : guidfixed = guidfixed ?? '',
        code = code ?? '',
        gp = gp ?? 0,
        gptype = gptype ?? 0,
        imageuri = imageuri ?? '',
        name = name ?? '';

  factory SaleChannelModel.fromJson(Map<String, dynamic> json) => _$SaleChannelModelFromJson(json);

  Map<String, dynamic> toJson() => _$SaleChannelModelToJson(this);
}
