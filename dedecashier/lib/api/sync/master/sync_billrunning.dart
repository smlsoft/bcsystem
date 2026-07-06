import 'dart:async';
import 'dart:convert';
import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/api/client.dart';
import 'package:dedecashier/api/sync/model/promotion_model.dart';
import 'package:dedecashier/api/sync/model/promotion_sync_model.dart';
import 'package:dedecashier/core/logger/logger.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/db/promotion_helper.dart';
import 'package:dedecashier/model/objectbox/bill_struct.dart';
import 'package:dedecashier/model/objectbox/promotion_struct.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/objectbox.g.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

Future syncBillrunning() async {
  DateTime dateTimeNow = DateTime.now();

  String dateNow = intl.DateFormat('yyyyMMdd').format(dateTimeNow);
  String result = "";
  String countDigit = "";
  String lastDigit = "";
  for (var item in global.posConfig.docformatinv.split("")) {
    if (item == "#") {
      countDigit += "0";
      lastDigit += "9";
    }
  }
  String docFormat =
      global.posConfig.doccode +
      global.posConfig.docformatinv.replaceAll("#", "");
  docFormat = docFormat.replaceAll("YYYY", dateNow.substring(0, 4));
  docFormat = docFormat.replaceAll("YY", dateNow.substring(2, 4));
  docFormat = docFormat.replaceAll("MM", dateNow.substring(4, 6));
  docFormat = docFormat.replaceAll("DD", dateNow.substring(6, 8));
  int number = 0;

  List<BillObjectBoxStruct> allDocs = global.objectBoxStore
      .box<BillObjectBoxStruct>()
      .query(BillObjectBoxStruct_.doc_number.lessOrEqual(docFormat + lastDigit))
      .order(BillObjectBoxStruct_.doc_number, flags: Order.descending)
      .build()
      .find();

  var filteredDocs = allDocs
      .where((doc) => !doc.doc_number.contains('-x'))
      .toList();
  filteredDocs.sort((a, b) => b.doc_number.compareTo(a.doc_number));

  var getLast = filteredDocs.isNotEmpty ? filteredDocs.first : null;

  if (getLast != null) {
    try {
      if (getLast.doc_number.substring(0, docFormat.length) == docFormat) {
        number = int.parse(
          getLast.doc_number.substring(
            getLast.doc_number.length - countDigit.length,
          ),
        );
      }
    } catch (e) {
      number = 0;
    }
  } else {
    // ค้นหาข้อมูลบน Cloud
    var lastDocNumberJson = await ApiRepository().serverGetLastDocNumber(
      docNumber: docFormat + lastDigit,
    );
    String lastDocNumber = "";
    try {
      lastDocNumber = lastDocNumberJson.data;
      try {
        AppLogger.debug(
          "lastDocNumber:${lastDocNumber.substring(0, docFormat.length)}",
        );
        if (lastDocNumber.substring(0, docFormat.length) == docFormat) {
          number = int.parse(
            lastDocNumber.substring(lastDocNumber.length - countDigit.length),
          );
        } else {
          number = 0;
          lastDocNumber = "";
        }
      } catch (e) {
        number = 0;
      }
    } catch (e) {
      number = 0;
      //AppLogger.error(e);
    }
    if (lastDocNumber.isNotEmpty) {
      number = int.parse(
        lastDocNumber.substring(lastDocNumber.length - countDigit.length),
      );
    }
  }
  result = "$docFormat${(intl.NumberFormat(countDigit)).format(number)}";
  SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  await sharedPreferences.setString('last_doc_no', result);
  global.last_doc_no = result;
  AppLogger.debug(global.last_doc_no);
}
