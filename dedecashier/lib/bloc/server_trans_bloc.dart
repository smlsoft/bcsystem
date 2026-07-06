import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/model/sync/server_trans_model.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ServerTransEvent {}

abstract class ServerTransState {
  //ServerTransModel result = ServerTransModel();
}

class ServerTransStateInitialized extends ServerTransState {}

class ServerTransLoadStart extends ServerTransEvent {
  ServerTransLoadStart();
}

class ServerTransLoadSuccess extends ServerTransState {
  List<ServerTransModel> data;
  ServerTransLoadSuccess({required this.data});
}

class ServerTransBloc extends Bloc<ServerTransEvent, ServerTransState> {
  ServerTransBloc() : super(ServerTransStateInitialized()) {
    on<ServerTransLoadStart>(_serverTransLoadStart);
    on<ServerTransLoadFinish>(_serverTransLoadFinish);
  }

  void _serverTransLoadStart(ServerTransLoadStart event, Emitter<ServerTransState> emit) async {
    emit(ServerTransLoading());
    ApiRepository apiRepository = ApiRepository();
    var value = await apiRepository.getTransactionList();
    List<ServerTransModel> datas = [];
    for (var i = 0; i < value.data.length; i++) {
      datas.add(ServerTransModel.fromJson(value.data[i]));
    }
    emit(ServerTransLoadSuccess(data: datas));
  }

  void _serverTransLoadFinish(ServerTransLoadFinish event, Emitter<ServerTransState> emit) async {
    emit(ServerTransLoadStop());
  }
}

class ServerTransLoadStop extends ServerTransState {}

class ServerTransLoadFinish extends ServerTransEvent {}

class ServerTransLoading extends ServerTransState {}
