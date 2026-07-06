import 'package:dedeorder/model/order_temp_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedeorder/utility/api.dart' as api;

abstract class OrderTempEvent {}

abstract class OrderTempState {}

class OrderTempCheckerGetData extends OrderTempEvent {
  OrderTempCheckerGetData();
}

class OrderTempGetData extends OrderTempEvent {
  final String orderId;
  final bool isOrder;
  final String machineId;

  OrderTempGetData(
      {required this.orderId, required this.isOrder, required this.machineId});
}

class OrderTempGetDataByOrderMain extends OrderTempEvent {
  final String orderMainId;
  final bool isOrder;
  final String machineId;

  OrderTempGetDataByOrderMain(
      {required this.orderMainId,
      required this.isOrder,
      required this.machineId});
}

class OrderTempLoadStart extends OrderTempEvent {
  final String orderId;
  final String barcode;
  final bool isOrder;
  final String machineId;

  OrderTempLoadStart(
      {required this.orderId,
      required this.barcode,
      required this.isOrder,
      required this.machineId});
}

class OrderTempLoadSuccess extends OrderTempState {
  List<OrderTempObjectBoxStruct> orderTemp;
  OrderTempLoadSuccess({required this.orderTemp});
}

class OrderTempGetDataSuccess extends OrderTempState {
  OrderTempStruct result;

  OrderTempGetDataSuccess({required this.result});
}

class OrderTempCheckerGetDataSuccess extends OrderTempState {
  List<OrderTempObjectBoxStruct> result;

  OrderTempCheckerGetDataSuccess({required this.result});
}

class OrderTempBloc extends Bloc<OrderTempEvent, OrderTempState> {
  OrderTempBloc() : super(OrderTempInitial()) {
    on<OrderTempGetData>(_orderTempGetData);
    on<OrderTempCheckerGetData>(_orderTempCheckerGetData);
    on<OrderTempGetDataByOrderMain>(_orderTempGetDataByOrderMain);
    on<OrderTempGetDataFinish>(_selectFinish);
    on<OrderTempLoadStart>(_orderTempLoadStart);
    on<OrderTempLoadFinish>(_orderTempLoadFinish);
  }

  void _orderTempLoadStart(
      OrderTempLoadStart event, Emitter<OrderTempState> emit) async {
    emit(OrderTempLoading());
    List<OrderTempObjectBoxStruct>? value =
        await api.getOrderTempByOrderIdAndBarcodeFromTerminal(
            orderId: event.orderId,
            barcode: event.barcode,
            isOrder: event.isOrder,
            machineId: event.machineId);
    emit(OrderTempLoadSuccess(orderTemp: value!));
  }

  void _orderTempLoadFinish(
      OrderTempLoadFinish event, Emitter<OrderTempState> emit) async {
    emit(OrderTempLoadStop());
  }

  void _orderTempGetDataByOrderMain(
      OrderTempGetDataByOrderMain event, Emitter<OrderTempState> emit) async {
    emit(OrderTempGetDataProcess());
    OrderTempStruct? result = await api.getOrderTempByOrderMainIdFromTerminal(
        orderMainId: event.orderMainId,
        isOrder: event.isOrder,
        machineId: event.machineId);
    emit(OrderTempGetDataSuccess(result: result!));
  }

  void _orderTempGetData(
      OrderTempGetData event, Emitter<OrderTempState> emit) async {
    emit(OrderTempGetDataProcess());
    OrderTempStruct? result = await api.getOrderTempByOrderIdFromTerminal(
        orderId: event.orderId,
        isOrder: event.isOrder,
        machineId: event.machineId);
    emit(OrderTempGetDataSuccess(result: result!));
  }

  void _orderTempCheckerGetData(
      OrderTempCheckerGetData event, Emitter<OrderTempState> emit) async {
    emit(OrderTempGetDataProcess());
    List<OrderTempObjectBoxStruct>? result =
        await api.getOrderTempCheckerFromTerminal();
    emit(OrderTempCheckerGetDataSuccess(result: result!));
  }

  void _selectFinish(
      OrderTempGetDataFinish event, Emitter<OrderTempState> emit) async {
    emit(OrderTempGetDataStop());
  }
}

class OrderTempGetDataProcess extends OrderTempState {}

class OrderTempGetDataFinish extends OrderTempEvent {}

class OrderTempGetDataStop extends OrderTempState {}

class OrderTempInitial extends OrderTempState {}

class OrderTempLoadFinish extends OrderTempEvent {}

class OrderTempLoading extends OrderTempState {}

class OrderTempLoadStop extends OrderTempState {}
