import 'dart:async';
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/util/network_helper.dart';
import 'package:dedekiosk/model/server_trans_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ServerTransEvent {}

abstract class ServerTransState {
  //ServerTransModel result = ServerTransModel();
}

class ServerTransStateInitialized extends ServerTransState {}

class ServerTransLoadStart extends ServerTransEvent {
  final DateTime? fromDate;
  final DateTime? toDate;

  ServerTransLoadStart({this.fromDate, this.toDate});
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

    try {
      // Add timeout protection to transaction list loading
      var value = await api.getTransactionList(fromDate: event.fromDate, toDate: event.toDate).timeout(
            NetworkTimeouts.long, // 15 seconds for loading bills
            onTimeout: () => throw TimeoutException('Transaction list loading timeout'),
          );

      List<ServerTransModel> datas = [];
      for (var i = 0; i < value.data.length; i++) {
        datas.add(ServerTransModel.fromJson(value.data[i]));
      }
      emit(ServerTransLoadSuccess(data: datas));
    } on TimeoutException catch (e) {
      emit(ServerTransLoadError(message: 'Timeout: ${e.message}'));
    } catch (e) {
      emit(ServerTransLoadError(message: e.toString()));
    }
  }

  void _serverTransLoadFinish(ServerTransLoadFinish event, Emitter<ServerTransState> emit) async {
    emit(ServerTransLoadStop());
  }
}

class ServerTransLoadStop extends ServerTransState {}

class ServerTransLoadFinish extends ServerTransEvent {}

class ServerTransLoading extends ServerTransState {}

class ServerTransLoadError extends ServerTransState {
  final String message;
  ServerTransLoadError({required this.message});
}
