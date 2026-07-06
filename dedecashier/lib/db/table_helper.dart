import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/objectbox/table_struct.dart';
import 'package:dedecashier/objectbox.g.dart';

class TableHelper {
  final box = global.objectBoxStore.box<TableObjectBoxStruct>();

  int insert(TableObjectBoxStruct value) {
    return box.put(value);
  }

  void insertMany(List<TableObjectBoxStruct> values) {
    box.putMany(values);
  }

  bool deleteByGuidFixed(String guid) {
    bool result = false;
    final find = box.query(TableObjectBoxStruct_.guidfixed.equals(guid)).build().findFirst();
    if (find != null) {
      result = box.remove(find.id);
    }
    return result;
  }

  void deleteByGuidFixedMany(List<String> guidFixedList) {
    Condition<TableObjectBoxStruct>? ids;
    for (var guidFixed in guidFixedList) {
      if (ids == null) {
        ids = TableObjectBoxStruct_.guidfixed.equals(guidFixed);
      } else {
        ids = ids.or(TableObjectBoxStruct_.guidfixed.equals(guidFixed));
      }
    }
    if (ids != null) {
      final find = box.query(ids).build().find();
      box.removeMany(find.map((data) => data.id).toList());
    }
  }

  List<TableObjectBoxStruct> getAll() {
    return (box.query()).build().find();
  }

  List<TableObjectBoxStruct> select({String word = ""}) {
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
