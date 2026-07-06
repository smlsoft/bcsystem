import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/objectbox/printer_struct.dart';
import 'package:dedecashier/objectbox.g.dart';

class PrinterHelper {
  final box = global.objectBoxStore.box<PrinterObjectBoxStruct>();

  List<PrinterObjectBoxStruct> selectAll() {
    return box.getAll();
  }

  int insert(PrinterObjectBoxStruct value) {
    return box.put(value);
  }

  void insertMany(List<PrinterObjectBoxStruct> values) {
    box.putMany(values);
  }

  bool deleteByGuidFixed(String guidfixed) {
    bool result = false;
    final find = box.query(PrinterObjectBoxStruct_.guid_fixed.equals(guidfixed)).build().findFirst();
    if (find != null) {
      result = box.remove(find.id);
    }
    return result;
  }

  void deleteByGuidFixedMany(List<String> guidfixed) {
    Condition<PrinterObjectBoxStruct>? ids;
    for (var guid in guidfixed) {
      if (ids == null) {
        ids = PrinterObjectBoxStruct_.guid_fixed.equals(guid);
      } else {
        ids = ids.or(PrinterObjectBoxStruct_.guid_fixed.equals(guid));
      }
    }
    if (ids != null) {
      final find = box.query(ids).build().find();
      box.removeMany(find.map((data) => data.id).toList());
    }
  }

  bool deleteByCode(String code) {
    bool result = false;
    final find = box.query(PrinterObjectBoxStruct_.code.equals(code)).build().findFirst();
    if (find != null) {
      result = box.remove(find.id);
    }
    return result;
  }

  void deleteAll() {
    box.removeAll();
  }

  int count() {
    return box.count();
  }
}
