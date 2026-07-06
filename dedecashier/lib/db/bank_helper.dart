import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/objectbox/bank_struct.dart';
import 'package:dedecashier/objectbox.g.dart';

class BankHelper {
  final box = global.objectBoxStore.box<BankObjectBoxStruct>();

  void insertMany(List<BankObjectBoxStruct> values) {
    box.putMany(values);
  }

  List<BankObjectBoxStruct> selectAll() {
    return box.getAll();
  }

  BankObjectBoxStruct? selectByCode({String code = ""}) {
    return (box.query(BankObjectBoxStruct_.code.equals(code))).build().findFirst();
  }

  void deleteByGuidFixedMany(List<String> guidFixedList) {
    Condition<BankObjectBoxStruct>? ids;
    for (var guidFixed in guidFixedList) {
      if (ids == null) {
        ids = BankObjectBoxStruct_.guidfixed.equals(guidFixed);
      } else {
        ids = ids.or(BankObjectBoxStruct_.guidfixed.equals(guidFixed));
      }
    }
    if (ids != null) {
      final find = box.query(ids).build().find();
      box.removeMany(find.map((data) => data.id).toList());
    }
  }

  Future<void> deleteAll() async {
    box.removeAll();
  }

  int count() {
    return (box.query()).build().count();
  }
}
