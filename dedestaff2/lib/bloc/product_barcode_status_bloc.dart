import 'package:dedeorder/model/global_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedeorder/utility/api.dart' as api;

abstract class ProductBarcodeStatusEvent {}

abstract class ProductBarcodeStatusState {}

class ProductBarcodeStatusGetData extends ProductBarcodeStatusEvent {
  ProductBarcodeStatusGetData();
}

class ProductBarcodeStatusGetDataSuccess extends ProductBarcodeStatusState {
  List<ProductBarcodeStatusObjectBoxStruct> result;

  ProductBarcodeStatusGetDataSuccess({required this.result});
}

class ProductBarcodeStatusBloc
    extends Bloc<ProductBarcodeStatusEvent, ProductBarcodeStatusState> {
  ProductBarcodeStatusBloc() : super(ProductBarcodeStatusInitial()) {
    on<ProductBarcodeStatusGetData>(_productBarcodeStatusGetData);
    on<ProductBarcodeStatusGetDataFinish>(_selectFinish);
  }

  void _productBarcodeStatusGetData(ProductBarcodeStatusGetData event,
      Emitter<ProductBarcodeStatusState> emit) async {
    emit(ProductBarcodeStatusGetDataProcess());
    List<ProductBarcodeStatusObjectBoxStruct> result =
        await api.getProductBarcodeStatusFromTerminal();
    emit(ProductBarcodeStatusGetDataSuccess(result: result));
  }

  void _selectFinish(ProductBarcodeStatusGetDataFinish event,
      Emitter<ProductBarcodeStatusState> emit) async {
    emit(ProductBarcodeStatusGetDataStop());
  }
}

class ProductBarcodeStatusGetDataProcess extends ProductBarcodeStatusState {}

class ProductBarcodeStatusGetDataFinish extends ProductBarcodeStatusEvent {}

class ProductBarcodeStatusGetDataStop extends ProductBarcodeStatusState {}

class ProductBarcodeStatusInitial extends ProductBarcodeStatusState {}
