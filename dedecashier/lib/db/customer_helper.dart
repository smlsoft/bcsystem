import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/objectbox/customer_struct.dart';
import 'package:dedecashier/objectbox.g.dart';

class CustomerHelper {
  final box = global.objectBoxStore.box<CustomerObjectBoxStruct>();

  int insert(CustomerObjectBoxStruct value) {
    return box.put(value);
  }

  void insertMany(List<CustomerObjectBoxStruct> values) {
    box.putMany(values);
  }

  bool deleteByGuidFixed(String guid) {
    bool result = false;
    final find = box.query(CustomerObjectBoxStruct_.guidfixed.equals(guid)).build().findFirst();
    if (find != null) {
      result = box.remove(find.id);
    }
    return result;
  }

  void deleteByGuidFixedMany(List<String> guidFixedList) {
    Condition<CustomerObjectBoxStruct>? ids;
    for (var guidFixed in guidFixedList) {
      if (ids == null) {
        ids = CustomerObjectBoxStruct_.guidfixed.equals(guidFixed);
      } else {
        ids = ids.or(CustomerObjectBoxStruct_.guidfixed.equals(guidFixed));
      }
    }
    if (ids != null) {
      final find = box.query(ids).build().find();
      box.removeMany(find.map((data) => data.id).toList());
    }
  }

  List<CustomerObjectBoxStruct> getAll() {
    return (box.query()).build().find();
  }

  // ค้นหาลูกค้าตามเบอร์โทรหรือชื่อ
  List<CustomerObjectBoxStruct> findByTelName(String searchText) {
    if (searchText.trim().isEmpty) {
      return (box.query()).build().find();
    }

    return (box.query(CustomerObjectBoxStruct_.tel.contains(searchText).or(CustomerObjectBoxStruct_.name.contains(searchText)).or(CustomerObjectBoxStruct_.code.contains(searchText)))).build().find();
  }

  // ค้นหาลูกค้าตาม code
  CustomerObjectBoxStruct? selectByCode({required String code}) {
    return (box.query(
      CustomerObjectBoxStruct_.code.equals(code),
    )).build().findFirst();
  }

  // ค้นหาลูกค้าตามเบอร์โทร
  CustomerObjectBoxStruct? selectByTel({required String tel}) {
    return (box.query(
      CustomerObjectBoxStruct_.tel.equals(tel),
    )).build().findFirst();
  }

  // ค้นหาลูกค้าตาม pointscode
  CustomerObjectBoxStruct? selectByPointsCode({required String pointscode}) {
    return (box.query(
      CustomerObjectBoxStruct_.pointscode.equals(pointscode),
    )).build().findFirst();
  }

  int count() {
    return (box.query()).build().count();
  }

  void deleteAll() {
    box.removeAll();
  }

  // อัปเดตยอดแต้ม
  bool updatePointBalance(String customerCode, double newBalance) {
    final customer = selectByCode(code: customerCode);
    if (customer != null) {
      customer.pointbalance = newBalance;
      customer.last_updated = DateTime.now();
      box.put(customer);
      return true;
    }
    return false;
  }

  bool updateGetPointBalance(String customerCode, double newBalance) {
    final customer = selectByPointsCode(pointscode: customerCode);
    if (customer != null) {
      customer.pointbalance += newBalance;
      customer.last_updated = DateTime.now();
      box.put(customer);
      return true;
    }
    return false;
  }
}
