import 'package:dedecashier/model/objectbox/bill_struct.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/objectbox.g.dart';

class BillHelper {
  final box = global.objectBoxStore.box<BillObjectBoxStruct>();

  /*static final BillHelper _instance = BillHelper.internal();

  factory BillHelper() => _instance;

  BillHelper.internal();*/

  /*  Future<void> create() async {
    if (await global.findTable(global.billTableName) == false) {
      await global.clientDb!.execute("CREATE TABLE " +
          global.billTableName +
          " (doc_number TEXT PRIMARY KEY,date_time datetime,time TEXT,customer_code TEXT,customer_name TEXT, customer_telephone TEXT,person_code TEXT,person_name TEXT,total_amount NUMERIC)");
    }
  }*/

  BillObjectBoxStruct? selectByDocNumber({required String docNumber, required int posScreenMode}) {
    return box.query(BillObjectBoxStruct_.doc_number.equals(docNumber).and(BillObjectBoxStruct_.doc_mode.equals(posScreenMode))).build().findFirst();
  }

  List<BillObjectBoxStruct> selectSyncIsFalse() {
    return box.query(BillObjectBoxStruct_.is_sync.equals(false)).build().find();
  }

  int insert(BillObjectBoxStruct value) {
    return box.put(value, mode: PutMode.insert);
  }

  List<BillObjectBoxStruct> select({required int posScreenMode, String where = "", int limit = 0, int offset = 0}) {
    return (box.query(BillObjectBoxStruct_.doc_mode.equals(posScreenMode))).build().find();
  }

  List<BillObjectBoxStruct> selectOrderByDateTimeDesc({required int posScreenMode}) {
    return (box.query(BillObjectBoxStruct_.doc_mode.equals(posScreenMode)).order(BillObjectBoxStruct_.date_time, flags: Order.descending).build()..limit = 100).find();
  }

  bool deleteByDocNumber(String docNumber) {
    bool result = false;
    final find = box.query(BillObjectBoxStruct_.doc_number.equals(docNumber)).build().findFirst();
    if (find != null) {
      result = box.remove(find.id);
    }
    return result;
  }
  //updatesDocNumber

  void updatesDocNumber({required String newDocNumber, required String guidpos}) {
    final find = box.query(BillObjectBoxStruct_.guidpos.equals(guidpos)).build().findFirst();
    if (find != null) {
      find.doc_number = newDocNumber;
      box.put(find);
    }
  }

  void updatesIsCancel({required String docNumber, required bool value, required String description}) {
    final find = box.query(BillObjectBoxStruct_.doc_number.equals(docNumber)).build().findFirst();
    if (find != null) {
      find.is_cancel = value;
      find.cancel_date_time = DateTime.now().toString();
      find.cancel_description = description;
      find.is_sync = false;
      box.put(find);
    }
  }

  void updatesSyncSuccess({required String docNumber}) {
    final find = box.query(BillObjectBoxStruct_.doc_number.equals(docNumber)).build().findFirst();
    if (find != null) {
      find.is_sync = true;
      box.put(find);
    }
  }

  void updateRePrintBill(String docNumber) {
    final find = box.query(BillObjectBoxStruct_.doc_number.equals(docNumber)).build().findFirst();
    if (find != null) {
      find.print_copy_bill_date_time.add(DateTime.now().toString());
      // Removed: find.is_sync = false;
      // Reason: การพิมพ์บิลซ้ำไม่ได้เปลี่ยนแปลงข้อมูล ไม่ต้อง sync ใหม่
      box.put(find);
    }
  }

  void updatesFullVat({required String docNumber, required String taxId, required String branchNumber, required String customerCode, required String customerName, required String customerAddress, required String customerTelephone}) {
    final find = box.query(BillObjectBoxStruct_.doc_number.equals(docNumber)).build().findFirst();
    if (find != null) {
      find.bill_tax_type = 2;
      find.full_vat_tax_id = taxId;
      find.full_vat_branch_number = branchNumber;
      find.customer_code = customerCode;
      find.full_vat_name = customerName;
      find.full_vat_address = customerAddress;
      find.customer_telephone = customerTelephone;

      // ถ้าบิล sync ไปแล้ว ให้ reset flag เพื่อ trigger update ใน sync cycle ถัดไป
      // checkAndSaveTransaction จะตรวจพบว่ามีบิลอยู่แล้วและเรียก updateTransaction API
      if (find.is_sync) {
        find.is_sync = false;
      }
      // ถ้ายังไม่ sync (is_sync = false อยู่แล้ว) ไม่ต้องทำอะไร

      box.put(find);
    }
  }
}
