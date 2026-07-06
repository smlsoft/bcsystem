import 'package:json_annotation/json_annotation.dart';

part 'api_common_error.g.dart';

@JsonSerializable()
class CommonErrorResponse {
  @JsonKey(name: 'success')
  final bool Success;

  @JsonKey(name: 'message')
  final String Message;

  CommonErrorResponse({
    required this.Success,
    required this.Message,
  });

  factory CommonErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$CommonErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CommonErrorResponseToJson(this);
}
