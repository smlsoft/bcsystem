import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/model/global_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class OrderTempEvent {}

abstract class OrderTempState {
  //OrderTempModel result = OrderTempModel();
}

class OrderTempStateInitialized extends OrderTempState {}

class OrderTempLoadStart extends OrderTempEvent {
  final String barcode;
  int isTakeAway;

  OrderTempLoadStart({required this.barcode, required this.isTakeAway});
}

class OrderTempLoadAllStart extends OrderTempEvent {
  OrderTempLoadAllStart();
}

class OrderTempLoadSuccess extends OrderTempState {
  List<OrderTempDetailModel> orderTemp;
  OrderTempLoadSuccess({required this.orderTemp});
}

class OrderTempBloc extends Bloc<OrderTempEvent, OrderTempState> {
  OrderTempBloc() : super(OrderTempStateInitialized()) {
    //on<OrderTempLoadAllStart>(_orderTempLoadAllStart);
    on<OrderTempLoadStart>(_orderTempLoadStart);
    on<OrderTempLoadFinish>(_orderTempLoadFinish);
  }

  void _orderTempLoadStart(
      OrderTempLoadStart event, Emitter<OrderTempState> emit) async {
    emit(OrderTempLoading());
    List<OrderTempDetailModel> value = await api.getOrderTempFromObjectBox(
        barcode: event.barcode, isTakeAway: event.isTakeAway);
    emit(OrderTempLoadSuccess(orderTemp: value));
  }

  /*void _orderTempLoadAllStart(
      OrderTempLoadAllStart event, Emitter<OrderTempState> emit) async {
    emit(OrderTempLoading());
    List<OrderTempDetailModel> value = await api.getAllOrderTempFromServer();
    emit(OrderTempLoadSuccess(orderTemp: value));
  }*/

  void _orderTempLoadFinish(
      OrderTempLoadFinish event, Emitter<OrderTempState> emit) async {
    emit(OrderTempLoadStop());
  }
}

class OrderTempLoadStop extends OrderTempState {}

class OrderTempLoadFinish extends OrderTempEvent {}

class OrderTempLoading extends OrderTempState {}
