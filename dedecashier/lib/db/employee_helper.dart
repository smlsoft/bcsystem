import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/objectbox/employees_struct.dart';
import 'package:dedecashier/objectbox.g.dart';

class EmployeeHelper {
  final box = global.objectBoxStore.box<EmployeeObjectBoxStruct>();

  int insert(EmployeeObjectBoxStruct value) {
    return box.put(value);
  }

  void insertMany(List<EmployeeObjectBoxStruct> values) {
    box.putMany(values);
  }

  bool deleteByGuidFixed(String guid) {
    bool result = false;
    final find = box.query(EmployeeObjectBoxStruct_.guidfixed.equals(guid)).build().findFirst();
    if (find != null) {
      result = box.remove(find.id);
    }
    return result;
  }

  void deleteByGuidFixedMany(List<String> guidFixedList) {
    Condition<EmployeeObjectBoxStruct>? ids;
    for (var guidFixed in guidFixedList) {
      if (ids == null) {
        ids = EmployeeObjectBoxStruct_.guidfixed.equals(guidFixed);
      } else {
        ids = ids.or(EmployeeObjectBoxStruct_.guidfixed.equals(guidFixed));
      }
    }
    if (ids != null) {
      final find = box.query(ids).build().find();
      box.removeMany(find.map((data) => data.id).toList());
    }
  }

  List<EmployeeObjectBoxStruct> getAll() {
    return (box.query()).build().find();
  }

  List<EmployeeObjectBoxStruct> select({String word = ""}) {
    if (word.trim().isEmpty) {
      return (box.query()).build().find();
    }
    // ค้นหาตามชื่อพนักงานหรือรหัสพนักงาน (contains - case insensitive)
    return (box.query(EmployeeObjectBoxStruct_.name.contains(word, caseSensitive: false).or(EmployeeObjectBoxStruct_.code.contains(word, caseSensitive: false)))).build().find();
  }

  EmployeeObjectBoxStruct? selectByCode({required String code}) {
    return (box.query(
      EmployeeObjectBoxStruct_.code.equals(code),
    )).build().findFirst();
  }

  int count() {
    return (box.query()).build().count();
  }

  void deleteAll() {
    box.removeAll();
  }
}
