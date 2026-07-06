import 'package:json_annotation/json_annotation.dart';
part 'server_trans_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ServerTransModel {
  String docno;
  String docdatetime;
  String slipurl;

  ServerTransModel({
    required this.docno,
    required this.docdatetime,
    required this.slipurl,
  });

  factory ServerTransModel.fromJson(Map<String, dynamic> json) =>
      _$ServerTransModelFromJson(json);

  Map<String, dynamic> toJson() => _$ServerTransModelToJson(this);
}
