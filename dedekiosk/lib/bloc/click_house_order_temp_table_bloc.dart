import 'package:dedekiosk/model/global_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/global.dart' as global;

abstract class ClickHouseOrderTempTableEvent {}

abstract class ClickHouseOrderTempTableState {
  //ClickHouseOrderTempTableModel result = ClickHouseOrderTempTableModel();
}

class ClickHouseOrderTempTableStateInitialized
    extends ClickHouseOrderTempTableState {}

class ClickHouseOrderTempTableLoadStart extends ClickHouseOrderTempTableEvent {
  ClickHouseOrderTempTableLoadStart();
}

class ClickHouseOrderTempTableLoadAllStart
    extends ClickHouseOrderTempTableEvent {
  ClickHouseOrderTempTableLoadAllStart();
}

class ClickHouseOrderTempTableLoadSuccess
    extends ClickHouseOrderTempTableState {
  List<OrderTempTableModel> clickHouseOrderTempTable;
  ClickHouseOrderTempTableLoadSuccess({required this.clickHouseOrderTempTable});
}

class ClickHouseOrderTempTableBloc
    extends Bloc<ClickHouseOrderTempTableEvent, ClickHouseOrderTempTableState> {
  ClickHouseOrderTempTableBloc()
      : super(ClickHouseOrderTempTableStateInitialized()) {
    on<ClickHouseOrderTempTableLoadStart>(_clickHouseOrderTempTableLoadStart);
    on<ClickHouseOrderTempTableLoadFinish>(_clickHouseOrderTempTableLoadFinish);
  }

  void _clickHouseOrderTempTableLoadStart(
      ClickHouseOrderTempTableLoadStart event,
      Emitter<ClickHouseOrderTempTableState> emit) async {
    emit(ClickHouseOrderTempTableLoading());
    List<OrderTempTableModel> orderDocList = [];
    try {
      String query =
          "SELECT ordertagnumber,sum(totalamount) as totalamount FROM ${global.clickHouseDatabaseName}.ordertempdocpaylater WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderpaysuccess=0 group by ordertagnumber";
      var result = await api.clickHouseSelect(query);
      ResponseDataModel responseData = ResponseDataModel.fromJson(result);
      for (int i = 0; i < responseData.data.length; i++) {
        orderDocList.add(OrderTempTableModel.fromJson(responseData.data[i]));
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
    }
    emit(ClickHouseOrderTempTableLoadSuccess(
        clickHouseOrderTempTable: orderDocList));
  }

  void _clickHouseOrderTempTableLoadFinish(
      ClickHouseOrderTempTableLoadFinish event,
      Emitter<ClickHouseOrderTempTableState> emit) async {
    emit(ClickHouseOrderTempTableLoadStop());
  }
}

class ClickHouseOrderTempTableLoadStop extends ClickHouseOrderTempTableState {}

class ClickHouseOrderTempTableLoadFinish
    extends ClickHouseOrderTempTableEvent {}

class ClickHouseOrderTempTableLoading extends ClickHouseOrderTempTableState {}
