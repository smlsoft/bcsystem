import 'dart:convert';
import 'package:smlaicloud/model/point_transaction_model.dart';
import 'client.dart';
import 'package:dio/dio.dart';

class PointTransactionRepository {
  Future<ApiResponse> getPointTransactionsByDebtorCode(String debtorCode) async {
    Dio client = Client().init();
    
    try {
      String query = "/debtaccount/debtor/code/$debtorCode/pointtransactions";
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
      throw errorMessage;
    }
  }
}
