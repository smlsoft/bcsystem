import 'dart:convert';
import 'package:dedecashier/api/client.dart';
import 'package:dedecashier/core/environment.dart';
import 'package:dedecashier/core/logger/logger.dart';
import 'package:dedecashier/core/request.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart' as global_model;
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/json/member_model.dart';
import 'package:dio/dio.dart';
import 'package:dedecashier/db/employee_helper.dart';
import 'package:dedecashier/db/product_barcode_helper.dart';
import 'package:dedecashier/model/objectbox/employees_struct.dart';
import 'package:dedecashier/model/find/find_employee_model.dart';
import 'package:dedecashier/model/find/find_item_model.dart';
import 'dart:async';
import 'package:dedecashier/model/objectbox/product_barcode_struct.dart';
import 'package:flutter/foundation.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

// GET {{host}}/master-sync/list?lastupdate=2010-01-02T15:04&module=productunit&limit=1&offset=0&action=new
class ApiRepository {
  Future<bool> radisPost({
    required String branchCode,
    required String data,
  }) async {
    bool result = false;
    Dio client = Client().init();
    try {
      String query = "/pos/temp?branch-code=$branchCode";
      final response = await client.post(query, data: data);
      try {
        final rawData = json.decode(response.toString());
        result = rawData["success"];
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
    return result;
  }

  Future<ApiResponse> getTransactionList({
    int limit = 1000,
    int offset = 0,
    String search = "",
    String custcode = "",
    String ispos = "1",
  }) async {
    Dio client = Client().init();
    try {
      final response = await client.get(
        '/transaction/sale-invoice/list?offset=$offset&limit=$limit&q=$search&custcode=$custcode&ispos=$ispos&sort=docdatetime:-1',
      );
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

  Future<ApiResponse> authenUser(
    String userName,
    String shopid,
    int isDev,
  ) async {
    if (isDev == 1) {
      Environment().initConfig("DEV");
      serviceLocator<Request>().updateEndpoint();
    } else if (isDev == 2) {
      Environment().initConfig("STAGING");
      serviceLocator<Request>().updateEndpoint();
    } else {
      Environment().initConfig("PROD");
      serviceLocator<Request>().updateEndpoint();
    }

    Dio client = Client().init();

    try {
      final response = await client.post(
        '/poslogin',
        data: {"username": userName, "shopid": shopid},
      );
      try {
        final result = json.decode(response.toString());
        final rawData = {"success": result["success"], "data": result};

        if (rawData['error'] != null) {
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex, s) {
      if (kDebugMode) {
        AppLogger.debug(ex);
        AppLogger.debug(s);
      }

      String errorMessage = ex.response.toString();

      throw Exception(errorMessage);
    }
  }

  Future<String> radisGet({required String branchCode}) async {
    Dio client = Client().init();
    try {
      String query = "/pos/temp?branch-code=$branchCode";
      final response = await client.get(query);
      try {
        final rawData = json.decode(response.toString());
        if (rawData['error'] != null) {
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }
        if (rawData['success'] == true) {
          return rawData['data'].toString();
        } else {
          return "";
        }
      } catch (ex) {
        throw Exception(ex);
      }
    } catch (ex) {
      String errorMessage = ex.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> serverGetLastDocNumber({
    required String docNumber,
  }) async {
    Dio client = Client().init();
    try {
      String query =
          "/transaction/sale-invoice/last-pos-docno?posid=${global.posConfig.code}&maxdocno=$docNumber";
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
    } catch (ex) {
      String errorMessage = ex.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<List<global_model.SyncMasterStatusModel>> serverMasterStatus() async {
    Dio client = Client().init();

    try {
      String query = "/master-sync/status";
      final response = await client.get(query);
      try {
        final Map<dynamic, dynamic> rawData = json.decode(response.toString());
        return rawData.entries
            .map(
              (e) => global_model.SyncMasterStatusModel()
                ..tableName = e.key
                ..lastUpdate = e.value,
            )
            .toList();
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> serverKitchenGetData({
    int limit = 0,
    int offset = 0,
    String lastupdate = '',
  }) async {
    Dio client = Client().init();
    String shopfilter = "";
    if (global.mainShopId.isNotEmpty) {
      shopfilter = "${global.shopId},${global.mainShopId}";
    }
    try {
      String query =
          "/master-sync/list?lastupdate=$lastupdate&module=restaurant-kitchen&offset=$offset&limit=$limit&action=all&shopsid=$shopfilter";
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
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> serverTableGetData({
    int limit = 0,
    int offset = 0,
    String lastupdate = '',
  }) async {
    Dio client = Client().init();

    try {
      String query =
          "/master-sync/list?lastupdate=$lastupdate&module=restaurant-table&offset=$offset&limit=$limit&action=all";
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
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> serverOrderTypeGetData({
    int limit = 0,
    int offset = 0,
    String lastupdate = '',
  }) async {
    Dio client = Client().init();

    try {
      String query =
          "/master-sync/list?lastupdate=$lastupdate&module=ordertype&offset=$offset&limit=$limit&action=all";
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
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> serverWalletGetData({
    int limit = 0,
    int offset = 0,
    String lastupdate = '',
  }) async {
    Dio client = Client().init();

    try {
      String query =
          "/master-sync/list?lastupdate=$lastupdate&module=qrpayment&offset=$offset&limit=$limit&action=all";
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
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> serverPrinter({
    int limit = 0,
    int offset = 0,
    String lastupdate = '',
  }) async {
    Dio client = Client().init();

    try {
      String query =
          "/master-sync/list?lastupdate=$lastupdate&module=printer&offset=$offset&limit=$limit&action=all";
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
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> serverProductCategory({
    int limit = 0,
    int offset = 0,
    String lastupdate = '',
  }) async {
    Dio client = Client().init();

    try {
      String query =
          "/master-sync/list?lastupdate=$lastupdate&module=productcategory&offset=$offset&limit=$limit&action=all";
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
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> serverProductBarcode({
    int limit = 0,
    int offset = 0,
    String lastupdate = '',
  }) async {
    Dio client = Client().init();
    String shopfilter = "";
    if (global.mainShopId.isNotEmpty && global.posProductCenterType != 0) {
      shopfilter = "${global.shopId},${global.mainShopId}";
    }
    try {
      String query =
          "/master-sync/list?lastupdate=$lastupdate&module=productbarcode&offset=$offset&limit=$limit&action=all&shopsid=$shopfilter";
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
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getMasterBank() async {
    Dio client = Client().init();

    try {
      final response = await client.get('/paymentmaster');
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          serviceLocator<Log>().debug(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(ex);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getMasterUpdate({
    int page = 1,
    int limit = 50,
    String time = "",
  }) async {
    Dio client = Client().init();

    try {
      final response = await client.get(
        '/master-sync?lastUpdate=$time&page=$page&limit=$limit',
      );
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getInventoryFetchUpdate({
    int page = 0,
    int perPage = 1,
    String time = "",
  }) async {
    Dio client = Client().init();

    try {
      final response = await client.get(
        '/inventory/fetchupdate?lastUpdate=$time&page=$page&limit=$perPage',
      );
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getCategoryFetchUpdate({
    int page = 0,
    int limit = 1,
    String time = "",
  }) async {
    Dio client = Client().init();

    try {
      final response = await client.get(
        '/category/fetchupdate?lastUpdate=$time&page=$page&limit=$limit',
      );
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getMemberFetchUpdate({
    int page = 0,
    int perPage = 1,
    String time = "",
  }) async {
    Dio client = Client().init();

    try {
      final response = await client.get(
        '/member/fetchupdate?lastUpdate=$time&page=$page&limit=$perPage',
      );
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getPrinterFetchUpdate({
    int page = 0,
    int perPage = 1,
    String time = "",
  }) async {
    Dio client = Client().init();

    try {
      final response = await client.get(
        '/restaurant/printer/fetchupdate?lastUpdate=$time&page=$page&limit=$perPage',
      );
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getTableFetchUpdate({
    int page = 0,
    int perPage = 1,
    String time = "",
  }) async {
    Dio client = Client().init();

    try {
      final response = await client.get(
        '/restaurant/table/fetchupdate?lastUpdate=$time&page=$page&limit=$perPage',
      );
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getZoneFetchUpdate({
    int page = 0,
    int perPage = 1,
    String time = "",
  }) async {
    Dio client = Client().init();

    try {
      final response = await client.get(
        '/restaurant/zone/fetchupdate?lastUpdate=$time&page=$page&limit=$perPage',
      );
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getCategoryList({
    int page = 0,
    int perPage = 20,
    String search = "",
  }) async {
    Dio client = Client().init();

    try {
      final response = await client.get(
        '/category?page=$page&limit=$perPage&q=$search',
      );
      try {
        final rawData = json.decode(response.toString());

        serviceLocator<Log>().trace(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getInventoryList({
    int page = 0,
    int perPage = 1,
    String search = "",
  }) async {
    Dio client = Client().init();

    try {
      final response = await client.get(
        '/inventory?page=$page&limit=$perPage&q=$search',
      );
      try {
        final rawData = json.decode(response.toString());

        serviceLocator<Log>().trace(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getInventoryId(String id) async {
    Dio client = Client().init();

    try {
      final response = await client.get('/inventory/$id');
      try {
        final rawData = json.decode(response.toString());

        serviceLocator<Log>().trace(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getEmployeeList() async {
    Dio client = Client().init();

    try {
      final response = await client.get('/shop/employee/list');
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<List<MemberModel>> findMemberByTelName(
    String word,
    int offset,
    int limit,
  ) async {
    Dio client = Client().init();
    if (word.trim().isNotEmpty) {
      String shopfilter = "";
      if (global.mainShopId.isNotEmpty && global.debtorCenterType != 0) {
        shopfilter = "${global.shopId},${global.mainShopId}";
      }
      try {
        final response = await client.get(
          '/debtaccount/debtor/list?q=$word&offset=$offset&limit=$limit&lang=th&shopsid=$shopfilter',
        );
        try {
          final rawData = json.decode(response.toString());

          AppLogger.debug(rawData);

          if (rawData['error'] != null) {
            String errorMessage = '${rawData['code']}: ${rawData['message']}';
            AppLogger.error(errorMessage);
            throw Exception('${rawData['code']}: ${rawData['message']}');
          }
          return (rawData['data'] as List)
              .map((e) => MemberModel.fromJson(e))
              .toList();
        } catch (ex) {
          AppLogger.error(ex);
          throw Exception(ex);
        }
      } on DioException catch (ex) {
        String errorMessage = ex.response.toString();
        AppLogger.error(errorMessage);
        throw Exception(errorMessage);
      }
    }
    return [];
  }

  Future<MemberModel> findMemberByCode(String word) async {
    Dio client = Client().init();
    if (word.trim().isNotEmpty) {
      String shopfilter = "";
      if (global.mainShopId.isNotEmpty && global.debtorCenterType != 0) {
        shopfilter = "${global.shopId},${global.mainShopId}";
      }
      try {
        final response = await client.get(
          '/debtaccount/debtor/code/${word.trim()}',
        );
        try {
          final rawData = json.decode(response.toString());

          AppLogger.debug(rawData);

          if (rawData['error'] != null) {
            String errorMessage = '${rawData['code']}: ${rawData['message']}';
            AppLogger.error(errorMessage);
            throw Exception('${rawData['code']}: ${rawData['message']}');
          }
          return MemberModel.fromJson(rawData['data']);
        } catch (ex) {
          AppLogger.error(ex);
          throw Exception(ex);
        }
      } on DioException catch (ex) {
        String errorMessage = ex.response.toString();
        AppLogger.error(errorMessage);
        throw Exception(errorMessage);
      }
    }
    return MemberModel(code: "", names: []);
  }

  Future<List<MemberModel>> findALlMember(
    String word,
    int offset,
    int limit,
  ) async {
    Dio client = Client().init();
    String shopfilter = "";

    try {
      final response = await client.get('/debtaccount/debtor');
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }
        return (rawData['data'] as List)
            .map((e) => MemberModel.fromJson(e))
            .toList();
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getProfileShop() async {
    Dio client = Client().init();

    try {
      final response = await client.get('/profileshop');
      try {
        final rawData = await json.decode(response.toString());

        AppLogger.debug("getProfileShop : $rawData");

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getProfileSetting() async {
    Dio client = Client().init();

    try {
      final response = await client.get('/restaurant/settings');
      try {
        final rawData = await json.decode(response.toString());

        AppLogger.debug("getProfileSetting : $rawData");

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getPosSetting(String posId) async {
    Dio client = Client().init();

    try {
      final response = await client.get(
        '/pos/setting/code/${posId.toUpperCase()}',
      );
      try {
        final rawData = json.decode(response.toString());

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getCenterSetting(String mainShopId) async {
    Dio client = Client().init();

    try {
      final response = await client.get('/shop/${mainShopId}');
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug("getCenterSetting : ${response.toString()}");

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getMedia(String guid) async {
    Dio client = Client().init();

    try {
      final response = await client.get('/pos/media/${guid}');
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug("getMedia : ${response.toString()}");

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getProfileSBranch() async {
    Dio client = Client().init();

    try {
      final response = await client.get('/organization/branch');
      try {
        final rawData = json.decode(response.toString());

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getProfileBranchByGuid(PosConfigModel posconfig) async {
    Dio client = Client().init();
    AppLogger.debug(posconfig);
    try {
      final response = await client.get(
        '/organization/branch/${posconfig.branch.guidfixed}',
      );
      try {
        final rawData = json.decode(response.toString());

        AppLogger.debug(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<bool> userChangePassword(String code, String newPassword) async {
    bool result = false;
    Dio client = Client().init();
    try {
      final response = await client.post(
        '/employee/password',
        data: {"code": code, "password": newPassword},
      );
      try {
        final rawData = json.decode(response.toString());
        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          AppLogger.error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }
        result = true;
      } catch (ex) {
        AppLogger.error(ex);
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      AppLogger.error(errorMessage);
      throw Exception(errorMessage);
    }
    return result;
  }
}

class RestApiFindItemByCodeNameBarcode {
  Future<List<FindItemModel>> findItemByCodeNameBarcode(
    String word,
    int offset,
    int limit,
  ) async {
    //String _fieldName = "barcode,code,name_1";
    List<FindItemModel> result = [];
    if (word.trim().isNotEmpty) {
      ProductBarcodeHelper productBarcodeHelper = ProductBarcodeHelper();
      List<ProductBarcodeObjectBoxStruct> select = productBarcodeHelper
          .selectByCodeNameBarCode(
            word: word.toString(),
            limit: limit,
            offset: offset,
            order: "",
          );
      for (int index = 0; index < select.length; index++) {
        ProductBarcodeObjectBoxStruct source = select[index];
        result.add(
          FindItemModel(
            barcode: source.barcode,
            item_code: source.item_code,
            item_names: source.names,
            unit_code: source.unit_code,
            unit_names: source.unit_names,
            unit_type: 0,
            qty: 1.0,
            prices: source.prices,
            images_guid_list: [],
            unit_stand: source.unit_stand,
            unit_divide: source.unit_divide,
          ),
        );
      }
    }
    return result;
  }
}

class RestApiFindEmployeeByWord {
  Future<List<FindEmployeeModel>> findEmployeeByWord(String word) async {
    List<FindEmployeeModel> result = [];
    EmployeeHelper employeeHelper = EmployeeHelper();
    List<EmployeeObjectBoxStruct> select = employeeHelper.select(word: word);
    for (int index = 0; index < select.length; index++) {
      EmployeeObjectBoxStruct source = select[index];
      result.add(
        FindEmployeeModel(
          name: source.name,
          code: source.code,
          roles: "" /* _source.roles.toString()*/,
          profile_picture: source.profile_picture,
          username: source.name,
        ),
      );
    }
    return result;
  }
}
