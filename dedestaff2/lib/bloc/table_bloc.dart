import 'package:dedeorder/model/table_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedeorder/utility/api.dart' as api;

abstract class TableEvent {}

abstract class TableState {}

class TableGetData extends TableEvent {
  TableGetData();
}

class TableGetDataSuccess extends TableState {
  List<TableProcessObjectBoxStruct> result;

  TableGetDataSuccess({required this.result});
}

class TableBloc extends Bloc<TableEvent, TableState> {
  TableBloc() : super(TableInitial()) {
    on<TableGetData>(_tableGetData);
    on<TableGetDataFinish>(_selectFinish);
  }

  void _tableGetData(TableGetData event, Emitter<TableState> emit) async {
    emit(TableGetDataProcess());
    List<TableProcessObjectBoxStruct> result =
        await api.getAllTableFromTerminal();
    emit(TableGetDataSuccess(result: result));
  }

  void _selectFinish(TableGetDataFinish event, Emitter<TableState> emit) async {
    emit(TableGetDataStop());
  }
}

class TableGetDataProcess extends TableState {}

class TableGetDataFinish extends TableEvent {}

class TableGetDataStop extends TableState {}

class TableInitial extends TableState {}
