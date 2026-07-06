import 'package:dedeorder/model/table_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedeorder/utility/api.dart' as api;

abstract class DeliveryTicketEvent {}

abstract class DeliveryTicketState {}

class DeliveryTicketLoadData extends DeliveryTicketEvent {
  bool sendSuccess;
  DeliveryTicketLoadData({required this.sendSuccess});
}

class DeliveryTicketLoadSuccess extends DeliveryTicketState {
  List<TableProcessObjectBoxStruct> result;

  DeliveryTicketLoadSuccess({required this.result});
}

class DeliveryTicketBloc
    extends Bloc<DeliveryTicketEvent, DeliveryTicketState> {
  DeliveryTicketBloc() : super(DeliveryTicketInitial()) {
    on<DeliveryTicketLoadData>(_deliveryTicketLoadData);
    on<DeliveryTicketLoadDataFinish>(_selectFinish);
  }

  void _deliveryTicketLoadData(
      DeliveryTicketLoadData event, Emitter<DeliveryTicketState> emit) async {
    emit(DeliveryTicketLoadDataProcess());
    List<TableProcessObjectBoxStruct> result =
        await api.getDeliveryTicketFromTerminal(sendSuccess: event.sendSuccess);
    emit(DeliveryTicketLoadSuccess(result: result));
  }

  void _selectFinish(DeliveryTicketLoadDataFinish event,
      Emitter<DeliveryTicketState> emit) async {
    emit(DeliveryTicketLoadDataStop());
  }
}

class DeliveryTicketLoadDataProcess extends DeliveryTicketState {}

class DeliveryTicketLoadDataFinish extends DeliveryTicketEvent {}

class DeliveryTicketLoadDataStop extends DeliveryTicketState {}

class DeliveryTicketInitial extends DeliveryTicketState {}
