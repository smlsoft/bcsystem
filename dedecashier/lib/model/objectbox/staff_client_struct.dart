// ignore_for_file: non_constant_identifier_names

import 'package:objectbox/objectbox.dart';

@Entity()
class StaffClientObjectBoxStruct {
  int id = 0;
  @Unique()
  String client_guid;
  String client_name;
  String client_ip;

  StaffClientObjectBoxStruct({
    this.client_guid = "",
    this.client_name = "",
    this.client_ip = "",
  });
}
