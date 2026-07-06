import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/objectbox/bill_struct.dart';
import 'package:dedecashier/objectbox.g.dart';

class BillDetailHelper {
  final box = global.objectBoxStore.box<BillDetailObjectBoxStruct>();

  void insertMany(List<BillDetailObjectBoxStruct> values) {
    box.putMany(values);
  }

  List<BillDetailObjectBoxStruct> selectAll() {
    return box.getAll();
  }

  List<BillDetailObjectBoxStruct> selectByDocNumber({required String docNumber}) {
    return box.query(BillDetailObjectBoxStruct_.doc_number.equals(docNumber)).order(BillDetailObjectBoxStruct_.line_number).build().find();
  }

  List<BillDetailObjectBoxStruct> selectByDocNumberAndGuidPos({
    required String docNumber,
    required String guidPos,
  }) {
    return box.query(BillDetailObjectBoxStruct_.doc_number.equals(docNumber).and(BillDetailObjectBoxStruct_.guidpos.equals(guidPos))).order(BillDetailObjectBoxStruct_.line_number).build().find();
  }

  List<BillDetailObjectBoxStruct> selectByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // Note: BillDetailObjectBoxStruct doesn't have a direct date field
    // We need to join with BillObjectBoxStruct to filter by date
    // This method returns all details and should be filtered by the caller
    return box.getAll();
  }

  int insert(BillDetailObjectBoxStruct value) {
    return box.put(value, mode: PutMode.insert);
  }

  bool deleteByDocNumber(String docNumber) {
    final query = box.query(BillDetailObjectBoxStruct_.doc_number.equals(docNumber));
    final count = query.build().remove();
    return count > 0;
  }

  void deleteByGuidFixedMany(List<String> guidFixedList) {
    // Implementation depends on the specific guid field structure
    // This is a placeholder for potential future use
  }
}
