import 'package:dedeorder/global_model.dart';
import 'package:dedeorder/model/global_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedeorder/utility/api.dart' as api;
import 'package:dedeorder/global.dart' as global;

abstract class CallerEvent {}

abstract class CallerState {}

class CallerGetData extends CallerEvent {
  CallerGetData();
}

class CallerGetDataSuccess extends CallerState {
  List<CallerModel> result;

  CallerGetDataSuccess({required this.result});
}

class CallerBloc extends Bloc<CallerEvent, CallerState> {
  CallerBloc() : super(CallerInitial()) {
    on<CallerGetData>(_callerGetData);
    on<CallerGetDataFinish>(_selectFinish);
  }

  void _callerGetData(CallerGetData event, Emitter<CallerState> emit) async {
    emit(CallerGetDataProcess());
    var getData = await api.clickHouseSelect(
        "select * from dedetemp.caller where shopid='${global.posInformation.shop_id}' order by calldatetime desc");
    ResponseDataModel response = ResponseDataModel.fromJson(getData);
    List<CallerModel> result = [];
    if (response.data.isNotEmpty) {
      for (var item in response.data) {
        result.add(CallerModel.fromJson(item));
      }
    }
    emit(CallerGetDataSuccess(result: result));
  }

  void _selectFinish(
      CallerGetDataFinish event, Emitter<CallerState> emit) async {
    emit(CallerGetDataStop());
  }
}

class CallerGetDataProcess extends CallerState {}

class CallerGetDataFinish extends CallerEvent {}

class CallerGetDataStop extends CallerState {}

class CallerInitial extends CallerState {}
