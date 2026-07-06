// ignore_for_file: non_constant_identifier_names

import 'package:objectbox/objectbox.dart';

@Entity()
class PrinterObjectBoxStruct {
  int id = 0;

  /// รหัส
  @Unique()
  String code;

  /// Guid สำหรับอ้างอิง
  String guid_fixed;

  /// ชื่อ
  String name1;

  /// ประเภท
  int type;

  /// ไอพี
  String print_ip_address;

  // port
  int printer_port;

  PrinterObjectBoxStruct({
    this.guid_fixed = "",
    this.code = "",
    this.name1 = "",
    this.type = 0,
    this.printer_port = 9100,
    this.print_ip_address = "",
  });
}
