import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/objectbox/kitchen_struct.dart';
import 'package:dedecashier/objectbox.g.dart';

class KitchenHelper {
  final box = global.objectBoxStore.box<KitchenObjectBoxStruct>();

  int insert(KitchenObjectBoxStruct value) {
    return box.put(value);
  }

  void insertMany(List<KitchenObjectBoxStruct> values) {
    box.putMany(values);
  }

  bool deleteByGuidFixed(String guid) {
    bool result = false;
    final find = box.query(KitchenObjectBoxStruct_.guidfixed.equals(guid)).build().findFirst();
    if (find != null) {
      result = box.remove(find.id);
    }
    return result;
  }

  void deleteByGuidFixedMany(List<String> guidFixedList) {
    Condition<KitchenObjectBoxStruct>? ids;
    for (var guidFixed in guidFixedList) {
      if (ids == null) {
        ids = KitchenObjectBoxStruct_.guidfixed.equals(guidFixed);
      } else {
        ids = ids.or(KitchenObjectBoxStruct_.guidfixed.equals(guidFixed));
      }
    }
    if (ids != null) {
      final find = box.query(ids).build().find();
      box.removeMany(find.map((data) => data.id).toList());
    }
  }

  List<KitchenObjectBoxStruct> getAll() {
    return (box.query()).build().find();
  }

  List<KitchenObjectBoxStruct> select({String word = ""}) {
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
