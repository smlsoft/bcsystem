import 'dart:convert';

import 'package:dedekds/model/kitchen_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedekds/global.dart' as global;
import 'package:dedekds/utility/api.dart' as api;

abstract class KitchenEvent {}

abstract class KitchenState {}

class KitchenGetData extends KitchenEvent {
  KitchenGetData();
}

class KitchenGetDataSuccess extends KitchenState {
  List<KitchenObjectBoxStruct> result;

  KitchenGetDataSuccess({required this.result});
}

class KitchenBloc extends Bloc<KitchenEvent, KitchenState> {
  KitchenBloc() : super(KitchenInitial()) {
    on<KitchenGetData>(_KitchenGetData);
    on<KitchenGetDataFinish>(_selectFinish);
  }

  void _KitchenGetData(KitchenGetData event, Emitter<KitchenState> emit) async {
    emit(KitchenGetDataProcess());
    List<KitchenObjectBoxStruct> result = await api.getKitchenFromTerminal();
    emit(KitchenGetDataSuccess(result: result));
  }

  void _selectFinish(
      KitchenGetDataFinish event, Emitter<KitchenState> emit) async {
    emit(KitchenGetDataStop());
  }
}

class KitchenGetDataProcess extends KitchenState {}

class KitchenGetDataFinish extends KitchenEvent {}

class KitchenGetDataStop extends KitchenState {}

class KitchenInitial extends KitchenState {}
