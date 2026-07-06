import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

abstract class ServerEvent {}

abstract class ServerState {}

class ServerSelect extends ServerEvent {
  final List<String> query;

  ServerSelect({required this.query});
}

class ServerSelectSuccess extends ServerState {
  String resultString;
  ServerSelectSuccess({required this.resultString});
}

class ServerBloc extends Bloc<ServerEvent, ServerState> {
  ServerBloc() : super(ServerInitial()) {
    on<ServerSelect>(_select);
    on<ServerSelectFinish>(_selectFinish);
  }

  void _select(ServerSelect event, Emitter<ServerState> emit) async {
    /*emit(ServerSelectProcess());
    var _url = "http://" + global.serverIp + ":" + global.serverPort.toString();
    var _uri = Uri.parse(_url);
    try {
      http.Response _response = await http
          .post(_uri,
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(HttpPost(command: 'select', query: event.query).toJson()))
          .timeout(const Duration(seconds: 2));
      if (_response.statusCode == 200) {
        _result = _response.body;
      }
    } catch (e) {
      AppLogger.error('failed : ' + e.toString());
    }
    
    emit(ServerSelectSuccess(resultString: _result));*/
  }

  void _selectFinish(
      ServerSelectFinish event, Emitter<ServerState> emit) async {
    emit(ServerSelectStop());
  }
}

class ServerSelectProcess extends ServerState {}

class ServerSelectFinish extends ServerEvent {}

class ServerSelectStop extends ServerState {}

class ServerInitial extends ServerState {}
