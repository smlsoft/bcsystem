import 'dart:convert';
import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/api/clickhouse/clickhouse_api.dart';
import 'package:dedecashier/core/logger/logger.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/db/product_barcode_helper.dart';
import 'package:dedecashier/api/sync/model/sync_inventory_model.dart';
import 'package:dedecashier/api/sync/model/item_remove_model.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/product_barcode_struct.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/objectbox.g.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

void syncProductBarcode(
  List<ItemRemoveModel> removeList,
  List<SyncProductBarcodeModel> newDataList,
) {
  List<String> manyForDelete = [];
  List<ProductBarcodeObjectBoxStruct> manyForInsert = [];

  // Remove duplicate barcodes from newDataList, keep only unique barcodes
  Map<String, SyncProductBarcodeModel> uniqueBarcodes = {};
  for (var data in newDataList) {
    if (data.barcode.isNotEmpty) {
      uniqueBarcodes[data.barcode] = data;
    }
  }
  newDataList = uniqueBarcodes.values.toList();

  // Delete
  for (var removeData in removeList) {
    //print("Remove Product Barcode : " + removeData.guidfixed);
    try {
      global.syncTimeIntervalSecond = 1;
      manyForDelete.add(removeData.guidfixed);
      global.syncRefreshProductBarcode = true;
    } catch (e) {
      AppLogger.error(e);
    }
  }

  // Insert
  for (var newData in newDataList) {
    if (newData.barcode == "1101100900050") {
      // shopid : 2kK9FxaycIF8TeFYLpp2ggRCS3n
      AppLogger.debug(global.shopId);
    }
    global.syncTimeIntervalSecond = 1;
    manyForDelete.add(newData.guidfixed);
    double standValue = 1;
    double divideValue = 1;
    if (newData.refbarcodes != null && newData.refbarcodes!.isNotEmpty) {
      standValue = newData.refbarcodes![0].standvalue;
      divideValue = newData.refbarcodes![0].dividevalue;
    }
    ProductBarcodeObjectBoxStruct newBarcode = ProductBarcodeObjectBoxStruct(
      guid_fixed: newData.guidfixed,
      issumpoint: newData.issumpoint,
      names: jsonEncode(newData.names),
      name_all: (newData.names)
          .map((e) => e.name)
          .toList()
          .join(" ")
          .toString(),
      product_count: 0,
      barcode: newData.barcode,
      item_guid: "",
      descriptions: "",
      item_code: newData.itemcode,
      unit_names: jsonEncode(newData.itemunitnames),
      prices: (newData.prices == null) ? "" : jsonEncode(newData.prices!),
      new_line: 0,
      unit_code: newData.itemunitcode,
      unit_stand: standValue,
      unit_divide: divideValue,
      options_json: jsonEncode(newData.options),
      images_url: newData.imageuri,
      image_or_color: newData.useimageorcolor,
      color_select: newData.colorselect,
      vat_type: 1,
      isalacarte: newData.isalacarte!,
      is_except_vat: (newData.vatcal == 1) ? true : false,
      ordertypes: (newData.ordertypes == null)
          ? ""
          : jsonEncode(newData.ordertypes!),
      color_select_hex: newData.colorselecthex,
      issplitunitprint: newData.issplitunitprint,
      food_type: newData.foodtype,
      is_resterant_use_stock: newData.isstockforrestaurant,
      ref_barcode_json: jsonEncode(newData.refbarcodes),
      patterncode: newData.patterncode,
    );
    newBarcode.image_or_color = true;

    manyForInsert.add(newBarcode);
    global.syncRefreshProductBarcode = true;
    // Update ข้อมูลใน Memory
    for (
      int index = 0;
      index < global.productCategoryCodeSelected.length;
      index++
    ) {
      if (global.productCategoryCodeSelected[index].guid_fixed ==
          newData.guidfixed) {
        global.productCategoryCodeSelected[index].names = jsonEncode(
          newData.names,
        );
        global.productCategoryCodeSelected[index].image_url = newData.imageuri;

        /*global.productGroupCodeSelected[_index].xorder =
            newData.xsorts![0].xorder;
        global.productGroupCodeSelected[_index].parent_group_guid =
            newData.parentguid;*/
        break;
      }
    }
    global.syncRefreshProductBarcode = true;
  }
  if (manyForDelete.isNotEmpty) {
    ProductBarcodeHelper().deleteByGuidFixedMany(manyForDelete);
  }
  if (manyForInsert.isNotEmpty) {
    ProductBarcodeHelper().insertMany(manyForInsert);
  }
  // Update Count Group
  /*final box = global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>();
  List<ProductBarcodeObjectBoxStruct> selectGroup = box.getAll();
  for (var group in selectGroup) {
    final count = box
        .query(ProductBarcodeObjectBoxStruct_.parent_group_guid
            .equals(group.item_code))
        .build()
        .count();
    if (count > 0) {
      group.group_count = count;
      box.put(group);
    }
  }*/
  // update sum order qty 7 days เอาไว้เรียงลำดับสั่งอาหาร (จาก clickhouse)
  clickHouseSelect(
    "SELECT barcode, sum(qty) as sum_order_qty FROM  dedebi.docdetail WHERE shopid = '${global.shopId}' AND docdatetime >= today()-30 GROUP BY barcode",
  ).then((onValue) {
    ResponseDataModel response = ResponseDataModel.fromJson(onValue);
    if (response.data.isNotEmpty) {
      for (var data in response.data) {
        var products = global.objectBoxStore
            .box<ProductBarcodeObjectBoxStruct>()
            .query(
              ProductBarcodeObjectBoxStruct_.barcode.equals(data["barcode"]),
            )
            .build()
            .find();
        if (products.isNotEmpty) {
          for (var product in products) {
            product.sum_order_qty =
                double.tryParse(data["sum_order_qty"].toString()) ?? 0.0;
            global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>().put(
              product,
              mode: PutMode.update,
            );
          }
        }
      }
    }
  });
}

Future<void> syncProductBarcodeCompare(
  List<SyncMasterStatusModel> masterStatus,
) async {
  // Sync Barcode
  ApiRepository apiRepository = ApiRepository();
  String lastUpdateTime =
      global.appStorage.read(global.syncProductBarcodeTimeName) ??
      global.syncDateBegin;
  if (ProductBarcodeHelper().count() == 0) {
    lastUpdateTime = global.syncDateBegin;
  }
  lastUpdateTime = DateFormat(
    global.dateFormatSync,
  ).format(DateTime.parse(lastUpdateTime));
  var getLastUpdateTime = global.syncFindLastUpdate(
    masterStatus,
    "productbarcode",
  );
  if (lastUpdateTime != getLastUpdateTime) {
    var loop = true;
    var offset = 0;
    var limit = 10000;
    while (loop) {
      await apiRepository
          .serverProductBarcode(
            offset: offset,
            limit: limit,
            lastupdate: lastUpdateTime,
          )
          .then((value) {
            if (value.success) {
              var dataList = value.data["productbarcode"];
              List<ItemRemoveModel> removeList = (dataList["remove"] as List)
                  .map((removeCate) => ItemRemoveModel.fromJson(removeCate))
                  .toList();
              try {
                List<SyncProductBarcodeModel> newDataList =
                    (dataList["new"] as List)
                        .map(
                          (newCate) =>
                              SyncProductBarcodeModel.fromJson(newCate),
                        )
                        .toList();

                if (newDataList.isEmpty && removeList.isEmpty) {
                  loop = false;
                } else {
                  syncProductBarcode(removeList, newDataList);
                }
              } catch (e, s) {
                if (kDebugMode) {
                  AppLogger.error(e);
                  AppLogger.debug(s);
                }
              }
            } else {
              serviceLocator<Log>().debug(
                "************************************************* Error",
              );
              loop = false;
            }
          });
      offset += limit;
    }
    global.appStorage.write(
      global.syncProductBarcodeTimeName,
      getLastUpdateTime,
    );
    global.rebuildProductBarcodeStatus = true;
  }
}
