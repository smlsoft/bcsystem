// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gb_primepay_gen_we_chat_qr_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GBPrimePayGenWeChatQRCodeRequest _$GBPrimePayGenWeChatQRCodeRequestFromJson(
        Map<String, dynamic> json) =>
    GBPrimePayGenWeChatQRCodeRequest(
      publicKey: json['publicKey'] as String,
      amount: Decimal.fromJson(json['amount'] as String),
      referenceNo: json['referenceNo'] as String,
      backgroundUrl: json['backgroundUrl'] as String,
      detail: json['detail'] as String,
      checksum: json['checksum'] as String,
    );

Map<String, dynamic> _$GBPrimePayGenWeChatQRCodeRequestToJson(
        GBPrimePayGenWeChatQRCodeRequest instance) =>
    <String, dynamic>{
      'publicKey': instance.publicKey,
      'amount': instance.amount,
      'referenceNo': instance.referenceNo,
      'backgroundUrl': instance.backgroundUrl,
      'detail': instance.detail,
      'checksum': instance.checksum,
    };
