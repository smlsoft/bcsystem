// ignore_for_file: non_constant_identifier_names

import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/services/print_process.dart';
import 'package:objectbox/objectbox.dart';
import 'package:json_annotation/json_annotation.dart';

part 'form_design_struct.g.dart';

@JsonSerializable(explicitToJson: true)
@Entity()
class FormDesignObjectBoxStruct {
  int id = 0;

  @Unique()
  String guid_fixed;

  @Unique()
  String code;

  /// รหัสแบบฟอร์ม
  String form_code;

  /// True=รวมรายการตามประเภท, False=ไม่รวมตามประเภท  (อาหาร,เครื่องดื่ม,อื่นๆ)
  bool sum_by_type;

  /// True=รวมรายการตามบาร์โค้ด, False=ไม่รวมตามบาร์โค้ด
  bool sum_by_barcode;

  /// พิมพ์ LOGO
  bool print_logo;

  /// พิมพ์ Prompt Pay
  bool print_prompt_pay;

  String names_json;
  String detail_json;
  String detail_extra_json;
  String detail_total_json;
  String detail_footer_json;

  FormDesignObjectBoxStruct({
    required this.guid_fixed,
    required this.code,
    required this.form_code,
    required this.sum_by_type,
    required this.sum_by_barcode,
    required this.print_logo,
    required this.print_prompt_pay,
    required this.names_json,
    required this.detail_json,
    required this.detail_extra_json,
    required this.detail_total_json,
    required this.detail_footer_json,
  });

  factory FormDesignObjectBoxStruct.fromJson(Map<String, dynamic> json) => _$FormDesignObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() => _$FormDesignObjectBoxStructToJson(this);
}

@JsonSerializable(explicitToJson: true)
class FormDesignRowModel {
  List<int> condition;
  List<FormDesignColumnModel> columns;

  FormDesignRowModel({
    this.condition = const [],
    this.columns = const [],
  });

  factory FormDesignRowModel.fromJson(Map<String, dynamic> json) => _$FormDesignRowModelFromJson(json);
  Map<String, dynamic> toJson() => _$FormDesignRowModelToJson(this);

  /*
  Condition (ในบิลมี)
  1=สินค้ามีภาษี และสินค้ายกเว้นภาษี
  5=ส่วนลดท้ายบิล
  6=ยอดไม่เท่ากับยอดรวมสุทธิ
  7=ระบบร้านอาหาร
  */
}

@JsonSerializable(explicitToJson: true)
class FormDesignColumnModel {
  List<LanguageDataModel> header_names;
  String text;
  String command_text;
  double width;
  double font_size;
  String font_family;
  bool font_weight_bold;
  bool font_style_italic;
  bool decoration_underline;

  /// 0=Left,1=Center,2=Right
  PrintColumnAlign text_align;
  String background_color;
  String font_color;
  // การจดทะเบียนภาษี (0=แสดงทั้งหมดทุกเงื่อนไข,1=แสดงเฉพาะจดทะเบียนภาษี)
  int condition_join_is_vat_register;

  FormDesignColumnModel({
    this.command_text = "",
    this.width = 1,
    this.text = "",
    this.header_names = const [],
    this.font_size = 24,
    this.font_family = "Arial",
    this.font_weight_bold = false,
    this.font_style_italic = false,
    this.decoration_underline = false,
    this.text_align = PrintColumnAlign.left,
    this.background_color = "",
    this.font_color = "",
    this.condition_join_is_vat_register = 0,
  });

  factory FormDesignColumnModel.fromJson(Map<String, dynamic> json) => _$FormDesignColumnModelFromJson(json);

  Map<String, dynamic> toJson() => _$FormDesignColumnModelToJson(this);
}
