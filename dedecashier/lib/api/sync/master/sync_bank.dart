import 'dart:async';
import 'dart:convert';
import 'package:dedecashier/api/client.dart';
import 'package:dedecashier/core/logger/logger.dart';
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/db/bank_helper.dart';
import 'package:dedecashier/api/sync/model/sync_bank_model.dart';
import 'package:dedecashier/model/objectbox/bank_struct.dart';
import 'package:dedecashier/api/sync/model/item_remove_model.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

Future<ApiResponse> serverBankGetData({
  int limit = 0,
  int offset = 0,
  String lastupdate = '',
}) async {
  Dio client = Client().init();

  try {
    String query =
        "/master-sync/list?lastupdate=$lastupdate&module=bankmaster&offset=$offset&limit=$limit&action=all";
    final response = await client.get(query);
    try {
      final rawData = json.decode(response.toString());
      if (rawData['error'] != null) {
        throw Exception('${rawData['code']}: ${rawData['message']}');
      }
      return ApiResponse.fromMap(rawData);
    } catch (ex) {
      throw Exception(ex);
    }
  } on DioException catch (ex) {
    String errorMessage = ex.response.toString();
    throw Exception(errorMessage);
  }
}

Future syncBank(
  List<ItemRemoveModel> removeList,
  List<SyncBankModel> newDataList,
) async {
  List<String> removeMany = [];
  List<BankObjectBoxStruct> manyForInsert = [];

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
    List<String> packNameValues = [];
    global.syncTimeIntervalSecond = 1;
    removeMany.add(newData.guidfixed);

    for (int index = 0; index < newData.names.length; index++) {
      packNameValues.add(newData.names[index].name);
    }

    BankObjectBoxStruct newBank = BankObjectBoxStruct(
      guidfixed: newData.guidfixed,
      code: newData.code,
      names: packNameValues,
      logo: newData.logo,
    );
    manyForInsert.add(newBank);
  }
  if (removeMany.isNotEmpty) {
    BankHelper().deleteByGuidFixedMany(removeMany);
  }
  if (manyForInsert.isNotEmpty) {
    BankHelper().insertMany(manyForInsert);
  }
}

Future<void> syncBankCompare(List<SyncMasterStatusModel> masterStatus) async {
  // Sync พนักงาน
  String lastUpdateTime =
      global.appStorage.read(global.syncBankTimeName) ?? global.syncDateBegin;
  if (BankHelper().count() == 0) {
    lastUpdateTime = global.syncDateBegin;
  }
  lastUpdateTime = DateFormat(
    global.dateFormatSync,
  ).format(DateTime.parse(lastUpdateTime));
  var getLastUpdateTime = global.syncFindLastUpdate(masterStatus, "bankmaster");
  if (lastUpdateTime != getLastUpdateTime) {
    var loop = true;
    var offset = 0;
    var limit = 10000;
    while (loop) {
      await serverBankGetData(
        offset: offset,
        limit: limit,
        lastupdate: lastUpdateTime,
      ).then((value) {
        if (value.success) {
          var dataList = value.data["bankmaster"];
          List<ItemRemoveModel> removeList = (dataList["remove"] as List)
              .map((removeCate) => ItemRemoveModel.fromJson(removeCate))
              .toList();
          List<SyncBankModel> newDataList = (dataList["new"] as List)
              .map((newCate) => SyncBankModel.fromJson(newCate))
              .toList();
          if (newDataList.isEmpty && removeList.isEmpty) {
            loop = false;
          } else {
            syncBank(removeList, newDataList);
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
    global.appStorage.write(global.syncBankTimeName, getLastUpdateTime);
  }
}
