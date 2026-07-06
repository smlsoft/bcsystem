import 'dart:async';
import 'dart:convert';
import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/core/logger/logger.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/db/product_category_helper.dart';
import 'package:dedecashier/api/sync/model/sync_inventory_model.dart';
import 'package:dedecashier/api/sync/model/item_remove_model.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/product_category_struct.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/objectbox.g.dart';
import 'package:intl/intl.dart';

Future syncProductCategory(data) async {
  List<String> removeMany = [];
  List<ProductCategoryObjectBoxStruct> manyForInsert = [];

  // Delete
  List<ItemRemoveModel> removes = (data["remove"] as List).map((removeCate) => ItemRemoveModel.fromJson(removeCate)).toList();
  for (var removeData in removes) {
    try {
      global.syncTimeIntervalSecond = 1;
      removeMany.add(removeData.guidfixed);
      global.syncRefreshProductCategory = true;
    } catch (e) {
      serviceLocator<Log>().debug(e);
    }
  }
  // Insert
  List<SyncCategoryModel> newDataList = (data["new"] as List).map((newCate) => SyncCategoryModel.fromJson(newCate)).toList();
  for (var newData in newDataList) {
    global.syncTimeIntervalSecond = 1;
    removeMany.add(newData.guidfixed);

    if (global.posConfig.categorygroupnumber == newData.groupnumber) {
      ProductCategoryObjectBoxStruct newProduct = ProductCategoryObjectBoxStruct(
        guid_fixed: newData.guidfixed,
        parent_guid_fixed: newData.parentguid,
        names: jsonEncode(newData.names),
        image_url: newData.imageuri,
        use_image_or_color: newData.useimageorcolor,
        colorselect: newData.colorselect,
        colorselecthex: newData.colorselecthex,
        codelist: jsonEncode(newData.codelist),
        xorder: newData.xsorts![0].xorder,
        category_count: newData.childcount,
      );
      manyForInsert.add(newProduct);
    }
  }
  if (removeMany.isNotEmpty) {
    global.syncRefreshProductCategory = true;
    ProductCategoryHelper().deleteByGuidFixedMany(removeMany);
  }
  if (manyForInsert.isNotEmpty) {
    global.syncRefreshProductCategory = true;
    ProductCategoryHelper().insertMany(manyForInsert);
  }
  if (global.syncRefreshProductCategory) {
    // Update Count Group
    final box = global.objectBoxStore.box<ProductCategoryObjectBoxStruct>();
    List<ProductCategoryObjectBoxStruct> selectCategory = box.getAll();
    for (var category in selectCategory) {
      final count = box.query(ProductCategoryObjectBoxStruct_.parent_guid_fixed.equals(category.guid_fixed)).build().count();
      if (count > 0) {
        category.category_count = count;
        box.put(category);
      }
    }
  }
}

Future<void> syncProductCategoryCompare(List<SyncMasterStatusModel> masterStatus) async {
  ApiRepository apiRepository = ApiRepository();

  String lastUpdateTime = global.appStorage.read(global.syncCategoryTimeName) ?? global.syncDateBegin;
  // หมวดสินค้า
  final productCategoryCount = ProductCategoryHelper().count();
  if (productCategoryCount == 0) {
    lastUpdateTime = global.syncDateBegin;
  }
  lastUpdateTime = DateFormat(global.dateFormatSync).format(DateTime.parse(lastUpdateTime));
  var getLastUpdateTime = global.syncFindLastUpdate(masterStatus, "productcategory");
  if (lastUpdateTime != getLastUpdateTime) {
    await apiRepository.serverProductCategory(offset: 0, limit: 1000, lastupdate: lastUpdateTime).then((value) {
      if (value.success) {
        syncProductCategory(value.data["productcategory"]).then((_) {
          global.appStorage.write(global.syncCategoryTimeName, getLastUpdateTime);
        });
      }
    });
  }
}
