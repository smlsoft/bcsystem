import 'package:json_annotation/json_annotation.dart';

part 'qr_transaction_common_response.g.dart';

@JsonSerializable()
class QRTransactionCommonResponse {
  final String partnerTxnUid;
  final String partnerId;
  final String statusCode;
  final String errorCode;
  final String errorDesc;

  QRTransactionCommonResponse({
    required this.partnerTxnUid,
    required this.partnerId,
    required this.statusCode,
    required this.errorCode,
    required this.errorDesc,
  });

  factory QRTransactionCommonResponse.fromJson(Map<String, dynamic> json) =>
      _$QRTransactionCommonResponseFromJson(json);

  Map<String, dynamic> toJson() => _$QRTransactionCommonResponseToJson(this);
}
