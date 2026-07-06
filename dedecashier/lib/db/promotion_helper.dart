import 'package:dedecashier/global.dart' as global;

import 'package:dedecashier/model/objectbox/promotion_struct.dart';
import 'package:dedecashier/objectbox.g.dart';

class PromotionHelper {
  final box = global.objectBoxStore.box<PromotionObjectBoxStruct>();

  void insertMany(List<PromotionObjectBoxStruct> values) {
    box.putMany(values);
  }

  List<PromotionObjectBoxStruct> selectAll() {
    return box.getAll();
  }

  PromotionObjectBoxStruct? selectByCode({String code = ""}) {
    return (box.query(PromotionObjectBoxStruct_.promotion_code.equals(code))).build().findFirst();
  }

  void deleteByGuidFixedMany(List<String> guidFixedList) {
    Condition<PromotionObjectBoxStruct>? ids;
    for (var guidFixed in guidFixedList) {
      if (ids == null) {
        ids = PromotionObjectBoxStruct_.guidfixed.equals(guidFixed);
      } else {
        ids = ids.or(PromotionObjectBoxStruct_.guidfixed.equals(guidFixed));
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
