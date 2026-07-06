// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';
import 'package:objectbox/objectbox.dart';

part 'pos_ticket_struct.g.dart';

@JsonSerializable()
@Entity()
class PosTicketObjectBoxStruct {
  int id = 0;
  @Unique()
  late String guidfixed;
  late String ticket_name;
  late int print_mode; // 0 = Raw (Text Mode), 1 = Image
  late int printer_width;
  late bool logo;
  late bool shop_name;
  late bool shop_address;
  late bool shop_tax_id;
  late bool shop_tel;
  late bool cashier_detail;
  late bool customer_detail;
  late bool customer_address;
  late bool customer_tax_id;
  late bool sale_detail;
  late bool doc_no_qr_code;

  PosTicketObjectBoxStruct(
      {this.logo = true,
      this.print_mode = 0,
      this.printer_width = 0,
      this.guidfixed = "",
      this.ticket_name = "",
      this.shop_name = true,
      this.shop_address = true,
      this.shop_tax_id = true,
      this.shop_tel = true,
      this.cashier_detail = true,
      this.customer_detail = true,
      this.customer_address = true,
      this.customer_tax_id = true,
      this.sale_detail = true,
      this.doc_no_qr_code = true});

  factory PosTicketObjectBoxStruct.fromJson(Map<String, dynamic> json) =>
      _$PosTicketObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() => _$PosTicketObjectBoxStructToJson(this);
}
