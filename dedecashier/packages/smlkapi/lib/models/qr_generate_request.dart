import 'package:json_annotation/json_annotation.dart';

part 'qr_generate_request.g.dart';

@JsonSerializable()
class QRGenerateRequest {
  final double amount;
  final String ref1;
  final String ref2;
  final String ref3;
  final String ref4;

  QRGenerateRequest({
    required this.amount,
    required this.ref1,
    required this.ref2,
    required this.ref3,
    required this.ref4,
  });

  factory QRGenerateRequest.fromJson(Map<String, dynamic> json) =>
      _$QRGenerateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$QRGenerateRequestToJson(this);
}
