import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/objectbox/buffet_mode_struct.dart';
import 'package:dedecashier/objectbox.g.dart';

class BuffetModeHelper {
  final box = global.objectBoxStore.box<BuffetModeObjectBoxStruct>();

  int insert(BuffetModeObjectBoxStruct value) {
    return box.put(value);
  }

  void insertMany(List<BuffetModeObjectBoxStruct> values) {
    box.putMany(values);
  }

  BuffetModeObjectBoxStruct? getByCode(String code) {
    return box.query(BuffetModeObjectBoxStruct_.code.equals(code)).build().findFirst();
  }

  bool deleteByCode(String code) {
    bool result = false;
    final find = box.query(BuffetModeObjectBoxStruct_.code.equals(code)).build().findFirst();
    if (find != null) {
      result = box.remove(find.id);
    }
    return result;
  }

  List<BuffetModeObjectBoxStruct> getAll() {
    return (box.query()).build().find();
  }

  List<BuffetModeObjectBoxStruct> select({String word = ""}) {
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

  void deleteByGuidFixedMany(List<String> guidfixed) {
    Condition<BuffetModeObjectBoxStruct>? ids;
    for (var guid in guidfixed) {
      if (ids == null) {
        ids = BuffetModeObjectBoxStruct_.guid_fixed.equals(guid);
      } else {
        ids = ids.or(BuffetModeObjectBoxStruct_.guid_fixed.equals(guid));
      }
    }
    if (ids != null) {
      final find = box.query(ids).build().find();
      box.removeMany(find.map((data) => data.id).toList());
    }
  }
}
