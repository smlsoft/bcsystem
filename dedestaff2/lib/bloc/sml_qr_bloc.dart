import 'package:dedeorder/model/global_model.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedeorder/utility/api.dart' as api;

abstract class SmlQrEvent {}

abstract class SmlQrState {}

class SmlQrGetData extends SmlQrEvent {
  SmlQrGetData();
}

class SmlQrGetDataSuccess extends SmlQrState {
  List<ProfileQrPaymentModel> result;

  SmlQrGetDataSuccess({required this.result});
}

class SmlQrBloc extends Bloc<SmlQrEvent, SmlQrState> {
  SmlQrBloc() : super(SmlQrInitial()) {
    on<SmlQrGetData>(_tmlQrGetData);
    on<SmlQrGetDataFinish>(_selectFinish);
  }

  void _tmlQrGetData(SmlQrGetData event, Emitter<SmlQrState> emit) async {
    emit(SmlQrGetDataProcess());
    List<ProfileQrPaymentModel> result = await api.getSMLQRFromTerminal();
    emit(SmlQrGetDataSuccess(result: result));
  }

  void _selectFinish(SmlQrGetDataFinish event, Emitter<SmlQrState> emit) async {
    emit(SmlQrGetDataStop());
  }
}

class SmlQrGetDataProcess extends SmlQrState {}

class SmlQrGetDataFinish extends SmlQrEvent {}

class SmlQrGetDataStop extends SmlQrState {}

class SmlQrInitial extends SmlQrState {}
