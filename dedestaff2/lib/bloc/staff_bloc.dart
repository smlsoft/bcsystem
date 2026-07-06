import 'package:dedeorder/global_model.dart';
import 'package:dedeorder/model/global_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedeorder/utility/api.dart' as api;
import 'package:dedeorder/global.dart' as global;

abstract class StaffEvent {}

abstract class StaffState {}

class StaffGetData extends StaffEvent {
  StaffGetData();
}

class StaffGetDataSuccess extends StaffState {
  List<StaffModel> result;

  StaffGetDataSuccess({required this.result});
}

class StaffBloc extends Bloc<StaffEvent, StaffState> {
  StaffBloc() : super(StaffInitial()) {
    on<StaffGetData>(_staffGetData);
    on<StaffGetDataFinish>(_selectFinish);
  }

  void _staffGetData(StaffGetData event, Emitter<StaffState> emit) async {
    emit(StaffGetDataProcess());
    emit(StaffGetDataSuccess(result: await api.getStaff()));
  }

  void _selectFinish(StaffGetDataFinish event, Emitter<StaffState> emit) async {
    emit(StaffGetDataStop());
  }
}

class StaffGetDataProcess extends StaffState {}

class StaffGetDataFinish extends StaffEvent {}

class StaffGetDataStop extends StaffState {}

class StaffInitial extends StaffState {}
