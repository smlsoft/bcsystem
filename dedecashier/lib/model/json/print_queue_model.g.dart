// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'print_queue_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrintQueueModel _$PrintQueueModelFromJson(Map<String, dynamic> json) =>
    PrintQueueModel(
      code: (json['code'] as num).toInt(),
      doc_number: json['doc_number'] as String,
      line_number: (json['line_number'] as num?)?.toInt() ?? 0,
      printer_code: json['printer_code'] as String,
    )..guid = json['guid'] as String;

Map<String, dynamic> _$PrintQueueModelToJson(PrintQueueModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'code': instance.code,
      'doc_number': instance.doc_number,
      'line_number': instance.line_number,
      'printer_code': instance.printer_code,
    };
