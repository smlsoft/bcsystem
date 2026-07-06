import 'package:dedeorder/model/pos_process_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedeorder/utility/api.dart' as api;

abstract class ProcessEvent {}

abstract class ProcessState {}

class ProcessGetData extends ProcessEvent {
  String holdId;
  String discountWord;
  bool isCash;

  ProcessGetData({required this.holdId, required this.discountWord, required this.isCash});
}

class ProcessGetDataSuccess extends ProcessState {
  PosProcessModel result;

  ProcessGetDataSuccess({required this.result});
}

class ProcessBloc extends Bloc<ProcessEvent, ProcessState> {
  ProcessBloc() : super(ProcessInitial()) {
    on<ProcessGetData>(_processGetData);
    on<ProcessGetDataFinish>(_selectFinish);
  }

  void _processGetData(ProcessGetData event, Emitter<ProcessState> emit) async {
    emit(ProcessGetDataProcess());
    PosProcessModel result = await api.getProcessFromTerminal(event.holdId, event.discountWord, event.isCash);
    emit(ProcessGetDataSuccess(result: result));
  }

  void _selectFinish(ProcessGetDataFinish event, Emitter<ProcessState> emit) async {
    emit(ProcessGetDataStop());
  }
}

class ProcessGetDataProcess extends ProcessState {}

class ProcessGetDataFinish extends ProcessEvent {}

class ProcessGetDataStop extends ProcessState {}

class ProcessInitial extends ProcessState {}
