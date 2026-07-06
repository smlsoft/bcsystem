import 'dart:async';
import 'dart:convert';
import 'package:dedecashier/api/client.dart';
import 'package:dedecashier/api/sync/model/promotion_model.dart';
import 'package:dedecashier/api/sync/model/promotion_sync_model.dart';
import 'package:dedecashier/core/logger/logger.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/db/promotion_helper.dart';
import 'package:dedecashier/model/objectbox/promotion_struct.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

Future<ApiResponse> serverPromotionGetData({int limit = 0}) async {
  Dio client = Client().init();

  try {
    String query = "/product/promotion?limit=$limit";
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

Future getPromotionData() async {
  await serverPromotionGetData(limit: 1000).then((value) {
    if (value.success) {
      AppLogger.debug(value.data);
      List<PromotionObjectBoxStruct> manyForInsert = [];
      var dataList = value.data;
      List<PromotionSyncModel> newDataList = (dataList as List)
          .map((data) => PromotionSyncModel.fromJson(data))
          .toList();
      if (newDataList.isNotEmpty) {
        for (var data in newDataList) {
          List<PromotionProductIncludeModel> promotionbarcodeinclude = [];

          for (var element in data.promotionbarcodeinclude) {
            List<PromotionProductModel> promotionProduct = [];
            List<PromotionProductModel> includeProduct = [];
            for (var product in element.promotionproduct) {
              promotionProduct.add(
                PromotionProductModel(
                  item_code: product.barcode,
                  name: jsonEncode(
                    product.name.map((e) => e.toJson()).toList(),
                  ),
                  unit_code: product.unitcode,
                  unit_name: jsonEncode(
                    product.unitname.map((e) => e.toJson()).toList(),
                  ),
                  qty: product.qty,
                  price: product.price,
                  discount_text: product.discounttext,
                ),
              );
            }
            for (var includeproduct in element.includeproduct) {
              includeProduct.add(
                PromotionProductModel(
                  item_code: includeproduct.barcode,
                  name: jsonEncode(
                    includeproduct.name.map((e) => e.toJson()).toList(),
                  ),
                  unit_code: includeproduct.unitcode,
                  unit_name: jsonEncode(
                    includeproduct.unitname.map((e) => e.toJson()).toList(),
                  ),
                  qty: includeproduct.qty,
                  price: includeproduct.price,
                  discount_text: includeproduct.discounttext,
                ),
              );
            }
            promotionbarcodeinclude.add(
              PromotionProductIncludeModel(
                promotion_product: promotionProduct,
                include_product: includeProduct,
              ),
            );
          }

          manyForInsert.add(
            PromotionObjectBoxStruct(
              guidfixed: data.guidfixed,
              type: data.promotiontype,
              index: data.index,
              promotion_code: data.code,
              date_begin: DateTime.parse(data.datebegin),
              date_end: DateTime.parse(data.dateend),
              promotion_name: jsonEncode(
                data.name.map((e) => e.toJson()).toList(),
              ),
              customer_only: data.customeronly,
              discount_text: data.discounttext,
              promotion_item_code_include_list: promotionbarcodeinclude,
              limit_qty: data.limitqty,
              promotion_qty: data.promotionqty,
              limit_amount: data.limitamount,
            ),
          );
        }
      }
      PromotionHelper().deleteAll();
      PromotionHelper().insertMany(manyForInsert);
    } else {
      AppLogger.error(
        "************************************************* Error",
      );
    }
  });
}
