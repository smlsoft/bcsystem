import 'package:dedecashier/model/objectbox/table_struct.dart';
import 'package:json_annotation/json_annotation.dart';

part 'system_info_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SystemInfoModel {
  List<TableObjectBoxStruct> tableObjectBox;
  List<TableProcessObjectBoxStruct> tableProcessObjectBox;

  SystemInfoModel({
    required this.tableObjectBox,
    required this.tableProcessObjectBox,
  });

  factory SystemInfoModel.fromJson(Map<String, dynamic> json) => _$SystemInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$SystemInfoModelToJson(this);
}
