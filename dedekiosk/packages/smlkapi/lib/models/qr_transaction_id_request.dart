import 'package:json_annotation/json_annotation.dart';

part 'qr_transaction_id_request.g.dart';

@JsonSerializable()
class QRTransactionIDRequest {
  final String txnUid;

  QRTransactionIDRequest({
    required this.txnUid,
  });

  factory QRTransactionIDRequest.fromJson(Map<String, dynamic> json) =>
      _$QRTransactionIDRequestFromJson(json);

  Map<String, dynamic> toJson() => _$QRTransactionIDRequestToJson(this);
}
