import 'dart:convert';

import 'package:smlaicloud/model/transaction_model.dart';

import 'client.dart';
import 'package:dio/dio.dart';

class TransRepository {
  Future<ApiResponse> getTrans(String code, String search) async {
    Dio client = Client().init();
    try {
      final response = await client.get('/sml-transaction');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getPurchaseList({
    int limit = 0,
    int offset = 0,
    String search = "",
    String custcode = "",
  }) async {
    Dio client = Client().init();

    try {
      String query = "/transaction/purchase/list?offset=$offset&limit=$limit&q=$search&custcode=$custcode";
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

  Future<ApiResponse> getPurchaseByCode({
    int limit = 0,
    int offset = 0,
    String custcode = "",
  }) async {
    Dio client = Client().init();

    try {
      String query = "/transaction/purchase?offset=$offset&limit=$limit&custcode=$custcode";
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

  Future<ApiResponse> getPurchaseReturnList({
    int limit = 0,
    int offset = 0,
    String search = "",
    String custcode = "",
  }) async {
    Dio client = Client().init();

    try {
      String query = "/transaction/purchase-return/list?offset=$offset&limit=$limit&q=$search&custcode=$custcode";
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

  Future<ApiResponse> getSaleList({
    int limit = 0,
    int offset = 0,
    String search = "",
    String custcode = "",
    String ispos = "",
  }) async {
    Dio client = Client().init();

    try {
      String qureyispos = "";
      if (ispos == "null") {
        qureyispos = "";
      } else {
        qureyispos = "&ispos=$ispos";
      }
      String query = "/transaction/sale-invoice/list?offset=$offset&limit=$limit&q=$search&custcode=$custcode$qureyispos&sort=docdatetime:-1";
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

  Future<ApiResponse> getSaleByCode({
    int limit = 0,
    int offset = 0,
    String custcode = "",
  }) async {
    Dio client = Client().init();

    try {
      String query = "/transaction/sale-invoice?offset=$offset&limit=$limit&custcode=$custcode";
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

  Future<ApiResponse> getSaleReturnList({
    int limit = 0,
    int offset = 0,
    String search = "",
    String custcode = "",
  }) async {
    Dio client = Client().init();

    try {
      String query = "/transaction/sale-invoice-return/list?offset=$offset&limit=$limit&q=$search&custcode=$custcode";
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

  Future<ApiResponse> getAdjustList({
    int limit = 0,
    int offset = 0,
    String search = "",
  }) async {
    Dio client = Client().init();

    try {
      String query = "/transaction/stock-adjustment/list?offset=$offset&limit=$limit&q=$search";
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

  Future<ApiResponse> getStockPickupList({
    int limit = 0,
    int offset = 0,
    String search = "",
  }) async {
    Dio client = Client().init();

    try {
      String query = "/transaction/stock-prickup-product/list?offset=$offset&limit=$limit&q=$search";
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

  Future<ApiResponse> getStockReceiveList({
    int limit = 0,
    int offset = 0,
    String search = "",
  }) async {
    Dio client = Client().init();

    try {
      String query = "/transaction/stock-receive-product/list?offset=$offset&limit=$limit&q=$search";
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

  Future<ApiResponse> getStockReturnList({
    int limit = 0,
    int offset = 0,
    String search = "",
  }) async {
    Dio client = Client().init();

    try {
      String query = "/transaction/stock-return-product/list?offset=$offset&limit=$limit&q=$search";
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

  Future<ApiResponse> getTransferList({
    int limit = 0,
    int offset = 0,
    String search = "",
  }) async {
    Dio client = Client().init();

    try {
      String query = "/transaction/stock-transfer?offset=$offset&limit=$limit&q=$search";
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

  Future<ApiResponse> saveTrans(postData) async {
    Dio client = Client().init();
    try {
      final response = await client.post('/sml-transaction', data: postData);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> savePurchase(TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    // print(data);
    try {
      final response = await client.post('/transaction/purchase', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> updatePurchase(String guid, TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.put('/transaction/purchase/$guid', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> updatePurchaseReturn(String guid, TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.put('/transaction/purchase-return/$guid', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> updateSale(String guid, TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.put('/transaction/sale-invoice/$guid', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> updateSaleReturn(String guid, TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.put('/transaction/sale-invoice-return/$guid', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> updateAdjust(String guid, TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.put('/transaction/stock-adjustment/$guid', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> updateTransfer(String guid, TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.put('/transaction/stock-transfer/$guid', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  /// updateQuotation
  Future<ApiResponse> updateQuotation(String guid, TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.put('/transaction/quotation/$guid', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  /// updateSaleOrder
  Future<ApiResponse> updateSaleOrder(String guid, TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.put('/transaction/sale-order/$guid', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  /// updatePurchaseOrder
  Future<ApiResponse> updatePurchaseOrder(String guid, TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.put('/transaction/purchase-order/$guid', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  // updatePurchasePartial
  Future<ApiResponse> updatePurchasePartial(String guid, TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.put('/transaction/purchasepartial/$guid', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  // updateAccrualReceive
  Future<ApiResponse> updateAccrualReceive(String guid, TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.put('/transaction/accrualreceive/$guid', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> updateStockReceive(String guid, TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.put('/transaction/stock-receive-product/$guid', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> updateStockPickup(String guid, TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.put('/transaction/stock-prickup-product/$guid', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> updateStockReturn(String guid, TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.put('/transaction/stock-return-product/$guid', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> deletePurchase(String guid) async {
    Dio client = Client().init();

    try {
      final response = await client.delete('/transaction/purchase/$guid');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> deletePurchaseReturn(String guid) async {
    Dio client = Client().init();

    try {
      final response = await client.delete('/transaction/purchase-return/$guid');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> deleteSale(String guid) async {
    Dio client = Client().init();

    try {
      final response = await client.delete('/transaction/sale-invoice/$guid');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> deleteSaleReturn(String guid) async {
    Dio client = Client().init();

    try {
      final response = await client.delete('/transaction/sale-invoice-return/$guid');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> deleteAdjust(String guid) async {
    Dio client = Client().init();

    try {
      final response = await client.delete('/transaction/stock-adjustment/$guid');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> deleteTransfer(String guid) async {
    Dio client = Client().init();

    try {
      final response = await client.delete('/transaction/stock-transfer/$guid');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> deleteReceive(String guid) async {
    Dio client = Client().init();

    try {
      final response = await client.delete('/transaction/stock-receive-product/$guid');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> deleteStockPickup(String guid) async {
    Dio client = Client().init();

    try {
      final response = await client.delete('/transaction/stock-prickup-product/$guid');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> deleteReturn(String guid) async {
    Dio client = Client().init();

    try {
      final response = await client.delete('/transaction/stock-return-product/$guid');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> saveTransfer(TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    // print(data);
    try {
      final response = await client.post('/transaction/stock-transfer', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> savePurchaseReturn(TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.post('/transaction/purchase-return', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> saveSale(TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.post('/transaction/sale-invoice', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> saveSaleReturn(TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.post('/transaction/sale-invoice-return', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> saveAdjust(TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.post('/transaction/stock-adjustment', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> saveStockPickup(TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.post('/transaction/stock-prickup-product', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> saveStockReceive(TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.post('/transaction/stock-receive-product', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> saveStockReturn(TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.post('/transaction/stock-return-product', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  /// saveQuotation
  Future<ApiResponse> saveQuotation(TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.post('/transaction/quotation', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  /// saveSaleOrder
  Future<ApiResponse> saveSaleOrder(TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.post('/transaction/sale-order', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  /// savePurchaseOrder
  Future<ApiResponse> savePurchaseOrder(TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.post('/transaction/purchase-order', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  // savePurchasePartial
  Future<ApiResponse> savePurchasePartial(TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.post('/transaction/purchasepartial', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  // saveAccrualReceive
  Future<ApiResponse> saveAccrualReceive(TransactionModel postData) async {
    Dio client = Client().init();
    final data = postData.toJson();
    try {
      final response = await client.post('/transaction/accrualreceive', data: data);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> updateTrans(String guid, postData) async {
    Dio client = Client().init();

    try {
      final response = await client.put('/sml-transaction/$guid', data: postData);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> deleteTrans(String guid) async {
    Dio client = Client().init();

    try {
      final response = await client.delete('/sml-transaction/$guid');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> deleteManyTrans(List<String> guids) async {
    Dio client = Client().init();

    try {
      final response = await client.delete('/sml-transaction', data: guids);
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> deleteStockBalance(String guid) async {
    Dio client = Client().init();

    try {
      final response = await client.delete('/transaction/stock-balance/$guid');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  // deleteSaleOrder
  Future<ApiResponse> deleteSaleOrder(String guid) async {
    Dio client = Client().init();

    try {
      final response = await client.delete('/transaction/sale-order/$guid');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  // deletePurchaseOrder
  Future<ApiResponse> deletePurchaseOrder(String guid) async {
    Dio client = Client().init();
    try {
      final response = await client.delete('/transaction/purchase-order/$guid');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  // deleteQuotation
  Future<ApiResponse> deleteQuotation(String guid) async {
    Dio client = Client().init();
    try {
      final response = await client.delete('/transaction/quotation/$guid');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  // deletePurchasePartial
  Future<ApiResponse> deletePurchasePartial(String guid) async {
    Dio client = Client().init();
    try {
      final response = await client.delete('/transaction/purchasepartial/$guid');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  // deleteAccrualReceive
  Future<ApiResponse> deleteAccrualReceive(String guid) async {
    Dio client = Client().init();
    try {
      final response = await client.delete('/transaction/accrualreceive/$guid');
      try {
        return ApiResponse.fromMap(response.data);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioException catch (ex) {
      String errorMessage = ex.response.toString();
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getStockBalanceList({
    int limit = 0,
    int offset = 0,
    String search = "",
    String custcode = "",
  }) async {
    Dio client = Client().init();
    try {
      String query = "/transaction/stock-balance/list?offset=$offset&limit=$limit&q=$search&custcode=$custcode";
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

  /// ใบสั่งขาย
  Future<ApiResponse> getSaleOrderList({
    int limit = 0,
    int offset = 0,
    String search = "",
    String custcode = "",
  }) async {
    Dio client = Client().init();
    try {
      String query = "/transaction/sale-order/list?offset=$offset&limit=$limit&q=$search&custcode=$custcode";
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

  /// ใบสั่งซื้อ
  Future<ApiResponse> getPurchaseOrderList({
    int limit = 0,
    int offset = 0,
    String search = "",
    String custcode = "",
  }) async {
    Dio client = Client().init();
    try {
      String query = "/transaction/purchase-order/list?offset=$offset&limit=$limit&q=$search&custcode=$custcode";
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

  /// ใบเสนอราคา
  Future<ApiResponse> getQuotationList({
    int limit = 0,
    int offset = 0,
    String search = "",
    String custcode = "",
  }) async {
    Dio client = Client().init();
    try {
      String query = "/transaction/quotation/list?offset=$offset&limit=$limit&q=$search&custcode=$custcode";
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

  /// ทะยอยรับ getPurchasePartialList
  Future<ApiResponse> getPurchasePartialList({
    int limit = 0,
    int offset = 0,
    String search = "",
    String custcode = "",
  }) async {
    Dio client = Client().init();

    try {
      String query = "/transaction/purchasepartial/list?offset=$offset&limit=$limit&q=$search&custcode=$custcode";
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

  /// ตั้งหนี้จากการทยอยรับ getAccrualReceiveList
  Future<ApiResponse> getAccrualReceiveList({
    int limit = 0,
    int offset = 0,
    String search = "",
    String custcode = "",
  }) async {
    Dio client = Client().init();

    try {
      String query = "/transaction/accrualreceive/list?offset=$offset&limit=$limit&q=$search&custcode=$custcode";
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
}
