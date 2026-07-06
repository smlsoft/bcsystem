import 'dart:async';
import 'dart:convert';
import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/api/sync/model/sync_table_model.dart';
import 'package:dedecashier/core/logger/logger.dart';
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/api/sync/model/item_remove_model.dart';
import 'package:dedecashier/db/table_helper.dart';
import 'package:dedecashier/db/table_process_helper.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/table_struct.dart';
import 'package:intl/intl.dart';

Future syncTable(List<ItemRemoveModel> removeList, List<SyncTableModel> newDataList) async {
  List<String> removeMany = [];
  List<TableObjectBoxStruct> manyForInsert = [];

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

    if (global.posConfig.tablegroupnumber == newData.groupnumber) {
      TableObjectBoxStruct newTable = TableObjectBoxStruct(
        guidfixed: newData.guidfixed,
        number: newData.number,
        numberMain: "",
        names: jsonEncode(newData.names),
        zone: newData.zone,
      );
      manyForInsert.add(newTable);
    }
  }
  if (removeMany.isNotEmpty) {
    TableHelper().deleteByGuidFixedMany(removeMany);
  }
  if (manyForInsert.isNotEmpty) {
    TableHelper().insertMany(manyForInsert);
  }
}

Future<void> syncTableCompare(List<SyncMasterStatusModel> masterStatus) async {
  ApiRepository apiRepository = ApiRepository();
  // TableHelper().deleteAll();
  // Sync Table
  String lastUpdateTime = global.appStorage.read(global.syncTableTimeName) ?? global.syncDateBegin;
  // print("TableHelper().count() = ${TableHelper().count()}");
  if (TableHelper().count() == 0) {
    lastUpdateTime = global.syncDateBegin;
  }
  lastUpdateTime = DateFormat(global.dateFormatSync).format(DateTime.parse(lastUpdateTime));
  var getLastUpdateTime = global.syncFindLastUpdate(masterStatus, "restaurant-table");
  if (lastUpdateTime != getLastUpdateTime) {
    var loop = true;
    var offset = 0;
    var limit = 10000;
    while (loop) {
      await apiRepository.serverTableGetData(offset: offset, limit: limit, lastupdate: lastUpdateTime).then((value) {
        if (value.success) {
          var dataList = value.data["restaurant-table"];
          List<ItemRemoveModel> removeList = (dataList["remove"] as List).map((removeCate) => ItemRemoveModel.fromJson(removeCate)).toList();
          List<SyncTableModel> newDataList = (dataList["new"] as List).map((newCate) => SyncTableModel.fromJson(newCate)).toList();
          if (newDataList.isEmpty && removeList.isEmpty) {
            loop = false;
          } else {
            syncTable(removeList, newDataList);
          }
        } else {
          AppLogger.error("************************************************* Error");
          loop = false;
        }
      });
      offset += limit;
    }
    global.appStorage.write(global.syncTableTimeName, getLastUpdateTime);
    // เพิ่มโต็ะไว้ที่ Table Process ด้วย
    var tableList = TableHelper().getAll();
    // TableProcessHelper().deleteAll();
    for (var table in tableList) {
      // find old table
      var oldTable = TableProcessHelper().getByTableNumber(table.number);
      if (oldTable == null) {
        TableProcessHelper().insert(
          TableProcessObjectBoxStruct(
            guidfixed: table.guidfixed,
            number: table.number,
            table_child_count: 0,
            number_main: table.numberMain,
            names: table.names,
            zone: table.zone,
            table_status: 0,
            order_count: 0,
            order_cancel_count: 0,
            order_served_count: 0,
            amount: 0,
            order_success: true,
            qr_code: "",
            man_count: 0,
            woman_count: 0,
            child_count: 0,
            table_al_la_crate_mode: true,
            buffet_code: "",
            table_open_datetime: DateTime.now(),
            customer_code_or_telephone: "",
            customer_name: "",
            customer_address: "",
            delivery_code: "",
            delivery_number: "",
            delivery_ticket_number: "",
            remark: "",
            open_by_staff_code: "",
            make_food_immediately: true,
            is_delivery: false,
            delivery_cook_success: false,
            delivery_cook_success_datetime: DateTime.now(),
            delivery_send_success: false,
            delivery_send_success_datetime: DateTime.now(),
            delivery_status: 0,
            detail_discount_formula: "",
            customer_nationality_code: "",
          ),
        );
      }
    }
  }
}
