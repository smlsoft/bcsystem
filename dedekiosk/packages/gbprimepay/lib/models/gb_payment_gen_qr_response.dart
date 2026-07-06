import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';

part 'gb_payment_gen_qr_response.g.dart';

@JsonSerializable()
class GBPaymentGenQRResponse {
  final String resultCode;
  final String resultMessage;
  String? referenceNo;
  String? qrcode;
  String? gbpReferenceNo;

  @JsonKey(includeFromJson: false, includeToJson: false)
  Uint8List? qrImageData;

  GBPaymentGenQRResponse(
      {required this.resultCode, required this.resultMessage});

  Map<String, dynamic> toJson() => _$GBPaymentGenQRResponseToJson(this);
  factory GBPaymentGenQRResponse.fromJson(Map<String, dynamic> json) =>
      _$GBPaymentGenQRResponseFromJson(json);

  bool isSuccess() {
    return resultCode == "00";
  }
}
