import 'dart:async';
import 'dart:convert';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/objectbox.g.dart';
import 'package:dedecashier/model/objectbox/product_barcode_status_struct.dart';

class ProductBarcodeStatusHelper {
  final box = global.objectBoxStore.box<ProductBarcodeStatusObjectBoxStruct>();

  void insertMany(List<ProductBarcodeStatusObjectBoxStruct> values) {
    box.putMany(values);
  }

  Future insert(ProductBarcodeStatusObjectBoxStruct value) async {
    return box.put(value);
  }

  List<ProductBarcodeStatusObjectBoxStruct> getAll() {
    return box.query().order(ProductBarcodeStatusObjectBoxStruct_.barcode).build().find();
  }

  Future<List<ProductBarcodeStatusObjectBoxStruct>> selectByBarcodeList(
    List<String> barcodeList,
  ) async {
    Condition<ProductBarcodeStatusObjectBoxStruct>? ids;
    for (var barcode in barcodeList) {
      if (ids == null) {
        ids = ProductBarcodeStatusObjectBoxStruct_.barcode.equals(barcode);
      } else {
        ids = ids.or(ProductBarcodeStatusObjectBoxStruct_.barcode.equals(barcode));
      }
    }
    if (ids != null) {
      return box.query(ids).build().find();
    } else {
      return [];
    }
  }

  Future<ProductBarcodeStatusObjectBoxStruct?> selectByBarcodeFirst(String barcode) async {
    if (global.appMode == global.AppModeEnum.posRemote) {
      HttpParameterModel jsonParameter = HttpParameterModel(barcode: barcode);
      HttpGetDataModel json = HttpGetDataModel(code: "selectByBarcodeFirst", json: jsonEncode(jsonParameter.toJson()));
      String result = await global.getFromServer(json: jsonEncode(json.toJson()));
      return ProductBarcodeStatusObjectBoxStruct.fromJson(await jsonDecode(result));
    } else {
      return box.query(ProductBarcodeStatusObjectBoxStruct_.barcode.equals(barcode)).build().findFirst();
    }
  }

  void deleteAll() {
    box.removeAll();
  }

  bool deleteByBarcode(String barcode) {
    bool result = false;
    final find = box.query(ProductBarcodeStatusObjectBoxStruct_.barcode.equals(barcode)).build().findFirst();
    if (find != null) {
      result = box.remove(find.id);
    }
    return result;
  }
}
