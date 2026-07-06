import 'dart:async';
import 'dart:convert';
import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/api/sync/model/sync_kitchen_model.dart';
import 'package:dedecashier/core/logger/logger.dart';
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/api/sync/model/item_remove_model.dart';
import 'package:dedecashier/db/kitchen_helper.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/kitchen_struct.dart';
import 'package:intl/intl.dart';

Future syncKitchen(
  List<ItemRemoveModel> removeList,
  List<SyncKitchenModel> newDataList,
) async {
  List<String> removeMany = [];
  List<KitchenObjectBoxStruct> manyForInsert = [];

  // Delete
  for (var removeData in removeList) {
    try {
      global.syncTimeIntervalSecond = 1;
      removeMany.add(removeData.guidfixed);
    } catch (e) {
      AppLogger.error(e);
    }
  }
  // Insert
  for (var newData in newDataList) {
    global.syncTimeIntervalSecond = 1;
    removeMany.add(newData.guidfixed);

    if (global.posConfig.kitchengroupnumber == newData.groupnumber) {
      KitchenObjectBoxStruct newKitchen = KitchenObjectBoxStruct(
        guidfixed: newData.guidfixed,
        code: newData.code,
        names: jsonEncode(newData.names),
        zones: newData.zones,
        products: newData.products,
      );
      manyForInsert.add(newKitchen);
    }
  }
  if (removeMany.isNotEmpty) {
    KitchenHelper().deleteByGuidFixedMany(removeMany);
  }
  if (manyForInsert.isNotEmpty) {
    KitchenHelper().insertMany(manyForInsert);
  }
}

Future<void> syncKitchenCompare(
  List<SyncMasterStatusModel> masterStatus,
) async {
  ApiRepository apiRepository = ApiRepository();

  // Sync Kitchen
  String lastUpdateTime =
      global.appStorage.read(global.syncKitchenTimeName) ??
      global.syncDateBegin;
  if (KitchenHelper().count() == 0) {
    lastUpdateTime = global.syncDateBegin;
  }
  lastUpdateTime = DateFormat(
    global.dateFormatSync,
  ).format(DateTime.parse(lastUpdateTime));
  var getLastUpdateTime = global.syncFindLastUpdate(
    masterStatus,
    "restaurant-kitchen",
  );
  if (lastUpdateTime != getLastUpdateTime) {
    var loop = true;
    var offset = 0;
    var limit = 10000;
    while (loop) {
      await apiRepository
          .serverKitchenGetData(
            offset: offset,
            limit: limit,
            lastupdate: lastUpdateTime,
          )
          .then((value) {
            if (value.success) {
              var dataList = value.data["restaurant-kitchen"];
              List<ItemRemoveModel> removeList = (dataList["remove"] as List)
                  .map((removeCate) => ItemRemoveModel.fromJson(removeCate))
                  .toList();
              List<SyncKitchenModel> newDataList = (dataList["new"] as List)
                  .map((newCate) => SyncKitchenModel.fromJson(newCate))
                  .toList();
              if (newDataList.isEmpty && removeList.isEmpty) {
                loop = false;
              } else {
                syncKitchen(removeList, newDataList);
              }
            } else {
              AppLogger.error(
                "************************************************* Error",
              );
              loop = false;
            }
          });
      offset += limit;
    }
    global.appStorage.write(global.syncKitchenTimeName, getLastUpdateTime);
  }
}
