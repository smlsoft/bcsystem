import 'dart:convert';

import 'package:dedekds/model/order_temp_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedekds/global.dart' as global;
import 'package:dedekds/utility/api.dart' as api;

abstract class OrderTempEvent {}

abstract class OrderTempState {}

class OrderTempGetData extends OrderTempEvent {
  final String kitchenId;

  OrderTempGetData({required this.kitchenId});
}

class OrderTempGetDataSuccess extends OrderTempState {
  List<OrderTempObjectBoxStruct> result;

  OrderTempGetDataSuccess({required this.result});
}

class OrderTempBloc extends Bloc<OrderTempEvent, OrderTempState> {
  OrderTempBloc() : super(OrderTempInitial()) {
    on<OrderTempGetData>(_orderTempGetData);
    on<OrderTempGetDataFinish>(_selectFinish);
  }

  void _orderTempGetData(
      OrderTempGetData event, Emitter<OrderTempState> emit) async {
    emit(OrderTempGetDataProcess());
    List<OrderTempObjectBoxStruct> result =
        await api.getOrderTempByKitchenFromTerminal(kitchenId: event.kitchenId);
    emit(OrderTempGetDataSuccess(result: result));
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
