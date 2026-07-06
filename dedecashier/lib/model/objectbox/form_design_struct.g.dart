// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_design_struct.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FormDesignObjectBoxStruct _$FormDesignObjectBoxStructFromJson(
  Map<String, dynamic> json,
) => FormDesignObjectBoxStruct(
  guid_fixed: json['guid_fixed'] as String,
  code: json['code'] as String,
  form_code: json['form_code'] as String,
  sum_by_type: json['sum_by_type'] as bool,
  sum_by_barcode: json['sum_by_barcode'] as bool,
  print_logo: json['print_logo'] as bool,
  print_prompt_pay: json['print_prompt_pay'] as bool,
  names_json: json['names_json'] as String,
  detail_json: json['detail_json'] as String,
  detail_extra_json: json['detail_extra_json'] as String,
  detail_total_json: json['detail_total_json'] as String,
  detail_footer_json: json['detail_footer_json'] as String,
)..id = (json['id'] as num).toInt();

Map<String, dynamic> _$FormDesignObjectBoxStructToJson(
  FormDesignObjectBoxStruct instance,
) => <String, dynamic>{
  'id': instance.id,
  'guid_fixed': instance.guid_fixed,
  'code': instance.code,
  'form_code': instance.form_code,
  'sum_by_type': instance.sum_by_type,
  'sum_by_barcode': instance.sum_by_barcode,
  'print_logo': instance.print_logo,
  'print_prompt_pay': instance.print_prompt_pay,
  'names_json': instance.names_json,
  'detail_json': instance.detail_json,
  'detail_extra_json': instance.detail_extra_json,
  'detail_total_json': instance.detail_total_json,
  'detail_footer_json': instance.detail_footer_json,
};

FormDesignRowModel _$FormDesignRowModelFromJson(Map<String, dynamic> json) =>
    FormDesignRowModel(
      condition:
          (json['condition'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      columns:
          (json['columns'] as List<dynamic>?)
              ?.map(
                (e) =>
                    FormDesignColumnModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$FormDesignRowModelToJson(FormDesignRowModel instance) =>
    <String, dynamic>{
      'condition': instance.condition,
      'columns': instance.columns.map((e) => e.toJson()).toList(),
    };

FormDesignColumnModel _$FormDesignColumnModelFromJson(
  Map<String, dynamic> json,
) => FormDesignColumnModel(
  command_text: json['command_text'] as String? ?? "",
  width: (json['width'] as num?)?.toDouble() ?? 1,
  text: json['text'] as String? ?? "",
  header_names:
      (json['header_names'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  font_size: (json['font_size'] as num?)?.toDouble() ?? 24,
  font_family: json['font_family'] as String? ?? "Arial",
  font_weight_bold: json['font_weight_bold'] as bool? ?? false,
  font_style_italic: json['font_style_italic'] as bool? ?? false,
  decoration_underline: json['decoration_underline'] as bool? ?? false,
  text_align:
      $enumDecodeNullable(_$PrintColumnAlignEnumMap, json['text_align']) ??
      PrintColumnAlign.left,
  background_color: json['background_color'] as String? ?? "",
  font_color: json['font_color'] as String? ?? "",
  condition_join_is_vat_register:
      (json['condition_join_is_vat_register'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$FormDesignColumnModelToJson(
  FormDesignColumnModel instance,
) => <String, dynamic>{
  'header_names': instance.header_names.map((e) => e.toJson()).toList(),
  'text': instance.text,
  'command_text': instance.command_text,
  'width': instance.width,
  'font_size': instance.font_size,
  'font_family': instance.font_family,
  'font_weight_bold': instance.font_weight_bold,
  'font_style_italic': instance.font_style_italic,
  'decoration_underline': instance.decoration_underline,
  'text_align': _$PrintColumnAlignEnumMap[instance.text_align]!,
  'background_color': instance.background_color,
  'font_color': instance.font_color,
  'condition_join_is_vat_register': instance.condition_join_is_vat_register,
};

const _$PrintColumnAlignEnumMap = {
  PrintColumnAlign.left: 'left',
  PrintColumnAlign.right: 'right',
  PrintColumnAlign.center: 'center',
};
