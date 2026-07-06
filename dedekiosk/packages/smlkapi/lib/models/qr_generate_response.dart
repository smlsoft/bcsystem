import 'package:json_annotation/json_annotation.dart';

part 'qr_generate_response.g.dart';

@JsonSerializable()
class QRGenerateResponse {
  final String txnUid;
  final String partnerId;
  final String statusCode;
  final String errorCode;
  final String errorDesc;
  final String accountName;
  final String qrCode;
  final String qrType;

  QRGenerateResponse({
    required this.txnUid,
    required this.partnerId,
    required this.statusCode,
    required this.errorCode,
    required this.errorDesc,
    required this.accountName,
    required this.qrCode,
    required this.qrType,
  });

  factory QRGenerateResponse.fromJson(Map<String, dynamic> json) =>
      _$QRGenerateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$QRGenerateResponseToJson(this);

  bool IsSuccess() {
    return statusCode == "00";
  }
}
