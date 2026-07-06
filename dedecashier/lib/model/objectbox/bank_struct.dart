import 'package:objectbox/objectbox.dart';

@Entity()
class BankObjectBoxStruct {
  int id = 0;
  @Unique()
  String guidfixed;
  String code;
  String logo;
  List<String> names;

  BankObjectBoxStruct({
    this.guidfixed = "",
    this.code = "",
    this.logo = "",
    this.names = const [],
  });
}
