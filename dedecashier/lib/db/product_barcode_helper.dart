import 'dart:async';
import 'dart:convert';
import 'package:dedecashier/core/logger/logger.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/objectbox.g.dart';
import 'package:dedecashier/model/objectbox/product_barcode_struct.dart';

class ProductBarcodeHelper {
  void deleteByGuidFixedMany(List<String> guidfixed) {
    Condition<ProductBarcodeObjectBoxStruct>? ids;
    for (var guid in guidfixed) {
      if (ids == null) {
        ids = ProductBarcodeObjectBoxStruct_.guid_fixed.equals(guid);
      } else {
        ids = ids.or(ProductBarcodeObjectBoxStruct_.guid_fixed.equals(guid));
      }
    }
    if (ids != null) {
      final find = global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().query(ids).build().find();
      global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().removeMany(find.map((data) => data.id).toList());
    }
  }

  List<ProductBarcodeObjectBoxStruct> getAll() {
    return global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().query().build().find();
  }

  int count() {
    return global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().count();
  }

  void insertMany(List<ProductBarcodeObjectBoxStruct> values) {
    global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().putMany(values);
  }

  Future insert(ProductBarcodeObjectBoxStruct value) async {
    return global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().put(value);
  }

  List<ProductBarcodeObjectBoxStruct> packData(List<ProductBarcodeObjectBoxStruct> source) {
    List<ProductBarcodeObjectBoxStruct> results = [];
    for (var data in source) {
      ProductBarcodeObjectBoxStruct newData = ProductBarcodeObjectBoxStruct(
        barcode: data.barcode,
        names: data.names,
        name_all: data.name_all,
        prices: data.prices,
        unit_code: data.unit_code,
        unit_names: data.unit_names,
        unit_stand: data.unit_stand,
        unit_divide: data.unit_divide,
        new_line: 0,
        vat_type: data.vat_type,
        color_select: "",
        image_or_color: true,
        color_select_hex: "",
        guid_fixed: data.guid_fixed,
        item_code: data.item_code,
        item_guid: data.item_guid,
        descriptions: data.descriptions,
        options_json: "",
        issumpoint: data.issumpoint,
        images_url: data.images_url,
        isalacarte: data.isalacarte,
        ordertypes: data.ordertypes,
        is_except_vat: data.is_except_vat,
        issplitunitprint: data.issplitunitprint,
        food_type: data.food_type,
        is_resterant_use_stock: data.is_resterant_use_stock,
        ref_barcode_json: data.ref_barcode_json,
        patterncode: data.patterncode,
        product_count: 0,
      );
      /*List<ProductOptionStruct> _jsonOption =  ProductOptionStruct.fromJson(await jsonDecode(  _data.options));
      _data.options.forEach((_optionStr) {
        ProductOptionStruct _option =
            ProductOptionStruct.fromJson(await jsonDecode(_optionStr));
        ProductOptionStruct _newOption = new ProductOptionStruct();
        _newOption.guid_fixed = _option.guid_fixed;
        _newOption.choice_type = _option.choice_type;
        _newOption.code = _option.code;
        _newOption.max_select = _option.max_select;
        _newOption.name1 = _option.name1;
        _newOption.name2 = _option.name2;
        _newOption.name3 = _option.name3;
        _newOption.name4 = _option.name4;
        _newOption.name5 = _option.name5;
        _newOption.isRequired = _option.isRequired;
        _option.choices.forEach((_choice) {
          ProductChoiceStruct _newChoice = new ProductChoiceStruct();
          _newChoice.barcode = _choice.barcode;
          _newChoice.is_default = _choice.is_default;
          _newChoice.item_unit_code = _choice.item_unit_code;
          _newChoice.name1 = _choice.name1;
          _newChoice.name2 = _choice.name2;
          _newChoice.name3 = _choice.name3;
          _newChoice.name4 = _choice.name4;
          _newChoice.name5 = _choice.name5;
          _newChoice.price = _choice.price;
          _newChoice.qty = _choice.qty;
          _newChoice.qty_max = _choice.qty_max;
          _newChoice.selected = _choice.selected;
          //_newChoice.suggest_code = _choice.suggest_code;
          _newOption.choices.add(_newChoice);
        });
        _new.options = _newOption.toJson().toString();
      });*/
      results.add(newData);
    }
    return results;
  }

  Future<List<ProductBarcodeObjectBoxStruct>> selectByBarcodeList(List<String> barcodeList) async {
    if (global.appMode == global.AppModeEnum.posRemote) {
      HttpParameterModel jsonParameter = HttpParameterModel(barcode: barcodeList.join(","));
      HttpGetDataModel json = HttpGetDataModel(code: "selectByBarcodeList", json: jsonEncode(jsonParameter.toJson()));
      String result = await global.getFromServer(json: jsonEncode(json.toJson()));
      return (await jsonDecode(result) as List).map((e) => ProductBarcodeObjectBoxStruct.fromJson(e)).toList();
    } else {
      Condition<ProductBarcodeObjectBoxStruct>? ids;
      for (var barcode in barcodeList) {
        if (ids == null) {
          ids = ProductBarcodeObjectBoxStruct_.barcode.equals(barcode);
        } else {
          ids = ids.or(ProductBarcodeObjectBoxStruct_.barcode.equals(barcode));
        }
      }
      if (ids != null) {
        return global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().query(ids).build().find();
      } else {
        return [];
      }
    }
  }

  Future<ProductBarcodeObjectBoxStruct?> selectByBarcodeFirst(String barcode) async {
    if (global.appMode == global.AppModeEnum.posRemote) {
      HttpParameterModel jsonParameter = HttpParameterModel(barcode: barcode);
      HttpGetDataModel json = HttpGetDataModel(code: "selectByBarcodeFirst", json: jsonEncode(jsonParameter.toJson()));
      String result = await global.getFromServer(json: jsonEncode(json.toJson()));
      var data = ProductBarcodeObjectBoxStruct.fromJson(await jsonDecode(result));
      return data;
    } else {
      var find = global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().query(ProductBarcodeObjectBoxStruct_.barcode.equals(barcode)).build().findFirst();
      find?.issplitunitprint = true;
      return find;
    }
  }

  /// ค้นหาสินค้าด้วย item_code โดยเลือก base unit (unit_stand=1, unit_divide=1) ก่อน
  /// ถ้าไม่มี base unit ให้คืนรายการแรกที่พบ
  ProductBarcodeObjectBoxStruct? selectByItemCodeFirst(String itemCode) {
    final results = global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().query(ProductBarcodeObjectBoxStruct_.barcode.equals(itemCode)).build().find();
    if (results.isEmpty) return null;
    // เลือก base unit (unit_stand=1, unit_divide=1) ก่อน
    return results.firstWhere((p) => p.unit_stand == 1 && p.unit_divide == 1, orElse: () => results.first);
  }

  List<ProductBarcodeObjectBoxStruct> xselect({String where = "", String order = "", int limit = 0, int offset = 0}) {
    return global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().query().build().find();
  }

  List<ProductBarcodeObjectBoxStruct> selectByCodeNameBarCode({required String word, required String order, required int limit, required int offset}) {
    Condition<ProductBarcodeObjectBoxStruct>? condition;

    List<String> wordBreak = global.wordSplit(word);
    serviceLocator<Log>().debug(wordBreak);
    for (int wordIndex = 0; wordIndex < wordBreak.length; wordIndex++) {
      var currentCondition = ProductBarcodeObjectBoxStruct_.item_code.contains(wordBreak[wordIndex]).or(ProductBarcodeObjectBoxStruct_.barcode.contains(wordBreak[wordIndex])).or(ProductBarcodeObjectBoxStruct_.name_all.contains(wordBreak[wordIndex]));

      if (wordIndex == 0) {
        condition = currentCondition;
      } else {
        condition = condition?.and(currentCondition);
      }
    }
    var query = global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().query(condition).build();
    if (limit > 0) {
      query.offset = offset;
      query.limit = limit;
    }
    return query.find();
  }

  void deleteAll() {
    global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().removeAll();
  }

  bool deleteByBarcode(String barcode) {
    bool result = false;
    final find = global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().query(ProductBarcodeObjectBoxStruct_.barcode.equals(barcode)).build().findFirst();
    if (find != null) {
      result = global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().remove(find.id);
    }
    return result;
  }

  void deleteByBarcodeMany(List<String> barcodeList) {
    Condition<ProductBarcodeObjectBoxStruct>? ids;
    for (var barcode in barcodeList) {
      if (ids == null) {
        ids = ProductBarcodeObjectBoxStruct_.barcode.equals(barcode);
      } else {
        ids = ids.or(ProductBarcodeObjectBoxStruct_.barcode.equals(barcode));
      }
    }
    if (ids != null) {
      final find = global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().query(ids).build().find();
      global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().removeMany(find.map((data) => data.id).toList());
    }
  }

  Future<int> deleteByCode(String code) async {
    return 0;
  }

  bool deleteByGuidFixed(String guidfixed) {
    bool result = false;
    final find = global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().query(ProductBarcodeObjectBoxStruct_.barcode.equals(guidfixed)).build().findFirst();
    if (find != null) {
      result = global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().remove(find.id);
    }
    return result;
  }
}
