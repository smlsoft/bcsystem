import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/model/find/find_employee_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FindEmployeeByNameLoadStart extends FindEmployeeByNameEvent {
  final String words;

  FindEmployeeByNameLoadStart(this.words);
}

class FindEmployeeByNameLoadSuccess extends FindEmployeeByNameState {
  List<FindEmployeeModel> result;

  FindEmployeeByNameLoadSuccess({required this.result});
}

class FindEmployeeByNameBloc extends Bloc<FindEmployeeByNameEvent, FindEmployeeByNameState> {
  final RestApiFindEmployeeByWord apiFindEmployeeByName;

  final int? offset;
  final int? limit;

  FindEmployeeByNameBloc({required this.apiFindEmployeeByName, this.offset, this.limit}) : super(FindEmployeeByNameInitial()) {
    on<FindEmployeeByNameLoadStart>(_findEmployeeByWord);
    on<FindEmployeeByNameLoadFinish>(_findEmployeeByNameLoadFinish);
  }

  void _findEmployeeByWord(FindEmployeeByNameLoadStart event, Emitter<FindEmployeeByNameState> emit) async {
    emit(FindEmployeeByNameLoading());
    List<FindEmployeeModel> result = await apiFindEmployeeByName.findEmployeeByWord(event.words);
    emit(FindEmployeeByNameLoadSuccess(result: result));
  }

  void _findEmployeeByNameLoadFinish(FindEmployeeByNameLoadFinish event, Emitter<FindEmployeeByNameState> emit) async {
    emit(FindEmployeeByNameLoadStop());
  }
}

abstract class FindEmployeeByNameEvent {}

class FindEmployeeByNameLoadFinish extends FindEmployeeByNameEvent {}

abstract class FindEmployeeByNameState {}

class FindEmployeeByNameInitial extends FindEmployeeByNameState {}

class FindEmployeeByNameLoading extends FindEmployeeByNameState {}

class FindEmployeeByNameLoaded extends FindEmployeeByNameState {}

class FindEmployeeByNameFound extends FindEmployeeByNameState {}

class FindEmployeeByNameNotFound extends FindEmployeeByNameState {}

class FindEmployeeByNameLoadStop extends FindEmployeeByNameState {}
