import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/objectbox/table_struct.dart';
import 'package:dedecashier/objectbox.g.dart';

class TableProcessHelper {
  final box = global.objectBoxStore.box<TableProcessObjectBoxStruct>();

  int insert(TableProcessObjectBoxStruct value) {
    return box.put(value);
  }

  void insertMany(List<TableProcessObjectBoxStruct> values) {
    box.putMany(values);
  }

  void updateByTableNumber(TableProcessObjectBoxStruct value) {
    final find = getByTableNumber(value.number);
    if (find != null) {
      value.id = find.id;
      box.put(value);
    }
  }

  TableProcessObjectBoxStruct? getByTableNumber(String number) {
    return box.query(TableProcessObjectBoxStruct_.number.equals(number)).build().findFirst();
  }

  bool deleteByTableNumber(String number) {
    bool result = false;
    final find = box.query(TableProcessObjectBoxStruct_.number.equals(number)).build().findFirst();
    if (find != null) {
      result = box.remove(find.id);
    }
    return result;
  }

  void deleteByGuidFixedMany(List<String> guidFixedList) {
    Condition<TableProcessObjectBoxStruct>? ids;
    for (var guidFixed in guidFixedList) {
      if (ids == null) {
        ids = TableProcessObjectBoxStruct_.guidfixed.equals(guidFixed);
      } else {
        ids = ids.or(TableProcessObjectBoxStruct_.guidfixed.equals(guidFixed));
      }
    }
    if (ids != null) {
      final find = box.query(ids).build().find();
      box.removeMany(find.map((data) => data.id).toList());
    }
  }

  List<TableProcessObjectBoxStruct> getAll() {
    return (box.query()).build().find();
  }

  List<TableProcessObjectBoxStruct> select({String word = ""}) {
    if (word.trim().isEmpty) {
      return (box.query()).build().find();
    }
    return (box.query()).build().find();
  }

  int count() {
    return (box.query()).build().count();
  }

  void deleteAll() {
    box.removeAll();
  }
}
