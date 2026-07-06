// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_common_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommonErrorResponse _$CommonErrorResponseFromJson(Map<String, dynamic> json) =>
    CommonErrorResponse(
      Success: json['success'] as bool,
      Message: json['message'] as String,
    );

Map<String, dynamic> _$CommonErrorResponseToJson(
        CommonErrorResponse instance) =>
    <String, dynamic>{
      'success': instance.Success,
      'message': instance.Message,
    };
