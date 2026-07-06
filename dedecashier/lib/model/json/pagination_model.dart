import 'package:json_annotation/json_annotation.dart';

part 'pagination_model.g.dart';

@JsonSerializable()
class PaginationModel {
  int total = 0;
  int page = 0;
  int perPage = 0;
  int prev = 0;
  int next = 0;
  int totalPage = 0;

  PaginationModel(
      {required this.total,
      required this.page,
      required this.perPage,
      required this.prev,
      required this.next,
      required this.totalPage});

  factory PaginationModel.fromJson(Map<String, dynamic> json) =>
      _$PaginationModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationModelToJson(this);
}
