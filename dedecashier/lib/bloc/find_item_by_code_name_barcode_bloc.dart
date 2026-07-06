import 'package:dedecashier/api/api_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/model/find/find_item_model.dart';

class FindItemByCodeNameBarcodeLoadStart extends FindItemByCodeNameBarcodeEvent {
  final String words;
  final int offset;
  final int limit;

  FindItemByCodeNameBarcodeLoadStart({required this.words, required this.offset, required this.limit});
}

class FindItemByCodeNameBarcodeLoadSuccess extends FindItemByCodeNameBarcodeState {
  List<FindItemModel> result;
  FindItemByCodeNameBarcodeLoadSuccess({required this.result});
}

class FindItemByCodeNameBarcodeBloc extends Bloc<FindItemByCodeNameBarcodeEvent, FindItemByCodeNameBarcodeState> {
  final RestApiFindItemByCodeNameBarcode apiFindItemByCodeNameBarcode;
  final int? offset;
  final int? limit;

  FindItemByCodeNameBarcodeBloc({required this.apiFindItemByCodeNameBarcode, this.offset, this.limit}) : super(FindItemByCodeNameBarcodeInitial()) {
    on<FindItemByCodeNameBarcodeLoadStart>(findItemByCodeNameBarcode);
    on<FindItemByCodeNameBarcodeLoadFinish>(findItemByCodeNameBarcodeLoadFinish);
  }

  void findItemByCodeNameBarcode(FindItemByCodeNameBarcodeLoadStart event, Emitter<FindItemByCodeNameBarcodeState> emit) async {
    emit(FindItemByCodeNameBarcodeLoading());
    List<FindItemModel> result = await apiFindItemByCodeNameBarcode.findItemByCodeNameBarcode(event.words, event.offset, event.limit);
    emit(FindItemByCodeNameBarcodeLoadSuccess(result: result));
  }

  void findItemByCodeNameBarcodeLoadFinish(FindItemByCodeNameBarcodeLoadFinish event, Emitter<FindItemByCodeNameBarcodeState> emit) async {
    emit(FindItemByCodeNameBarcodeLoadStop());
  }
}

abstract class FindItemByCodeNameBarcodeEvent {}

class FindItemByCodeNameBarcodeLoadFinish extends FindItemByCodeNameBarcodeEvent {}

abstract class FindItemByCodeNameBarcodeState {}

class FindItemByCodeNameBarcodeInitial extends FindItemByCodeNameBarcodeState {}

class FindItemByCodeNameBarcodeLoading extends FindItemByCodeNameBarcodeState {}

class FindItemByCodeNameBarcodeLoaded extends FindItemByCodeNameBarcodeState {}

class FindItemByCodeNameBarcodeFound extends FindItemByCodeNameBarcodeState {}

class FindItemByCodeNameBarcodeNotFound extends FindItemByCodeNameBarcodeState {}

class FindItemByCodeNameBarcodeLoadStop extends FindItemByCodeNameBarcodeState {}
