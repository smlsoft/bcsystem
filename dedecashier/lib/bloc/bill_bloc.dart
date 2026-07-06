import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/objectbox/bill_struct.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/db/bill_helper.dart';

abstract class BillEvent {}

abstract class BillState {}

class BillStateInitialized extends BillState {}

class BillLoadSuccess extends BillState {
  List<BillObjectBoxStruct> result;

  BillLoadSuccess({required this.result});
}

class BillLoadByDocNumberSuccess extends BillState {
  BillObjectBoxStruct? bill;
  BillLoadByDocNumberSuccess({required this.bill});
}

class BillBloc extends Bloc<BillEvent, BillState> {
  BillBloc() : super(BillStateInitialized()) {
    on<BillLoad>(billLoadStart);
    on<BillLoadFinish>(billLoadFinish);
    on<BillLoadByDocNumber>(billLoadByDocNumberStart);
    on<BillLoadByDocNumberFinish>(billLoadByDocNumberFinish);
  }

  void billLoadStart(BillLoad event, Emitter<BillState> emit) async {
    emit(BillLoading());
    List<BillObjectBoxStruct> bills = BillHelper().selectOrderByDateTimeDesc(posScreenMode: global.posScreenToInt(event.posScreenMode));
    emit(BillLoadSuccess(result: bills));
  }

  void billLoadByDocNumberStart(BillLoadByDocNumber event, Emitter<BillState> emit) async {
    emit(BillLoadingByDocNumber());
    BillObjectBoxStruct? bill = BillHelper().selectByDocNumber(docNumber: event.docNumber, posScreenMode: global.posScreenToInt(event.posScreenMode));
    emit(BillLoadByDocNumberSuccess(bill: bill));
  }

  void billLoadFinish(BillLoadFinish event, Emitter<BillState> emit) async {
    emit(BillLoadStop());
  }

  void billLoadByDocNumberFinish(BillLoadByDocNumberFinish event, Emitter<BillState> emit) async {
    emit(BillLoadByDocNumberStop());
  }
}

class BillLoadStop extends BillState {}

class BillLoad extends BillEvent {
  final global.PosScreenModeEnum posScreenMode;

  BillLoad({required this.posScreenMode});
}

class BillLoadFinish extends BillEvent {}

class BillLoading extends BillState {}

class BillLoadByDocNumber extends BillEvent {
  final String docNumber;
  final global.PosScreenModeEnum posScreenMode;

  BillLoadByDocNumber({required this.docNumber, required this.posScreenMode});
}

class BillLoadByDocNumberStop extends BillState {}

class BillLoadByDocNumberFinish extends BillEvent {}

class BillLoadingByDocNumber extends BillState {}
