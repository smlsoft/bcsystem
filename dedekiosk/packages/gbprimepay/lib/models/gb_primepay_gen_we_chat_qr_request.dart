import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gb_primepay_gen_we_chat_qr_request.g.dart';

@JsonSerializable()
class GBPrimePayGenWeChatQRCodeRequest {
  final String publicKey;
  final Decimal amount;
  final String referenceNo;
  final String backgroundUrl;
  final String detail;
  final String checksum;

  GBPrimePayGenWeChatQRCodeRequest(
      {required this.publicKey,
      required this.amount,
      required this.referenceNo,
      required this.backgroundUrl,
      required this.detail,
      required this.checksum});

  Map<String, dynamic> toJson() =>
      _$GBPrimePayGenWeChatQRCodeRequestToJson(this);
  factory GBPrimePayGenWeChatQRCodeRequest.fromJson(
          Map<String, dynamic> json) =>
      _$GBPrimePayGenWeChatQRCodeRequestFromJson(json);
}
