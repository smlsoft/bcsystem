import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/objectbox/shift_struct.dart';
import 'package:dedecashier/objectbox.g.dart';

class ShiftHelper {
  final box = global.objectBoxStore.box<ShiftObjectBoxStruct>();

  int insert(ShiftObjectBoxStruct value) {
    return box.put(value);
  }

  void insertMany(List<ShiftObjectBoxStruct> values) {
    box.putMany(values);
  }

  bool deleteByGuidFixed(String guid) {
    bool result = false;
    final find = box.query(ShiftObjectBoxStruct_.guidfixed.equals(guid)).build().findFirst();
    if (find != null) {
      result = box.remove(find.id);
    }
    return result;
  }

  List<ShiftObjectBoxStruct> selectSyncIsFalse() {
    return box.query(ShiftObjectBoxStruct_.isSync.equals(false)).build().find();
  }

  void updatesSyncSuccess({required String docNumber}) {
    final find = box.query(ShiftObjectBoxStruct_.guidfixed.equals(docNumber)).build().findFirst();
    if (find != null) {
      find.isSync = true;
      box.put(find);
    }
  }

  void deleteByGuidFixedMany(List<String> guidFixedList) {
    Condition<ShiftObjectBoxStruct>? ids;
    for (var guidFixed in guidFixedList) {
      if (ids == null) {
        ids = ShiftObjectBoxStruct_.guidfixed.equals(guidFixed);
      } else {
        ids = ids.or(ShiftObjectBoxStruct_.guidfixed.equals(guidFixed));
      }
    }
    if (ids != null) {
      final find = box.query(ids).build().find();
      box.removeMany(find.map((data) => data.id).toList());
    }
  }

  List<ShiftObjectBoxStruct> getAll() {
    return (box.query()).build().find();
  }

  ShiftObjectBoxStruct getByGuid(String guid) {
    return box.query(ShiftObjectBoxStruct_.guidfixed.equals(guid)).build().findFirst()!;
  }

  List<ShiftObjectBoxStruct> select({String word = ""}) {
    if (word.trim().isEmpty) {
      return (box.query()).build().find();
    }
    return (box.query()).build().find();
  }

  int count() {
    return (box.query()).build().count();
  }

  /// Find the last open shift (doctype=1) for the current POS that doesn't have a corresponding close shift
  ShiftObjectBoxStruct? getLastOpenShift(String posId) {
    // Get all shifts for this POS, sorted by docdate descending
    final allShifts = box.query(ShiftObjectBoxStruct_.posid.equals(posId)).order(ShiftObjectBoxStruct_.docdate, flags: Order.descending).build().find();

    // Find the most recent open shift that doesn't have a close shift
    for (final shift in allShifts) {
      if (shift.doctype == 1) {
        // Check if there's a corresponding close shift with the same docno
        final closeShift = box.query(ShiftObjectBoxStruct_.doctype.equals(2).and(ShiftObjectBoxStruct_.docno.equals(shift.docno)).and(ShiftObjectBoxStruct_.posid.equals(posId))).build().findFirst();

        // If no close shift found, this is the last open shift
        if (closeShift == null) {
          return shift;
        }
      }
    }

    return null; // No open shift found
  }

  void deleteAll() {
    box.removeAll();
  }
}
