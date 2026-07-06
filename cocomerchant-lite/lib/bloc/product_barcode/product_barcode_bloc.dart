import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cocomerchant_lite/model/product_bom_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:cocomerchant_lite/model/product_model.dart';
import 'package:cocomerchant_lite/model/master_model.dart';
import 'package:cocomerchant_lite/repositories/client.dart';
import 'package:cocomerchant_lite/repositories/product_barcode_repository.dart';

part 'product_barcode_event.dart';
part 'product_barcode_state.dart';

class ProductBarcodeBloc extends Bloc<ProductBarcodeEvent, ProductBarcodeState> {
  final ProductBarcodeRepository _productBarcodeRepository;

  ProductBarcodeBloc({required ProductBarcodeRepository productBarcodeRepository})
      : _productBarcodeRepository = productBarcodeRepository,
        super(ProductBarcodeInitial()) {
    on<ProductBarcodeLoadList>(onProductBarcodeLoad);
    on<ProductBarcodeSave>(onProductBarcodeSave);
    on<ProductBarcodeUpdate>(onProductBarcodeUpdate);
    on<ProductBarcodeDelete>(productbarcodeDelete);
    on<ProductBarcodeDeleteMany>(productbarcodeDeleteMany);
    on<ProductBarcodeGet>(onProductBarcodeGet);
    on<ProductBarcodeGetRef>(onProductBarcodeGetRef);
    on<ProductBarcodeWithImageSave>(onProductBarcodeWithImageSave);
    on<ProductBarcodeWithImageUpdate>(onProductBarcodeWithImageUpdate);
    on<ProductBarcodeGetBom>(onProductBarcodeGetBom);
    on<ProductBarcodeLoadListSearch>(onProductBarcodeLoadSearch);
  }

  void onProductBarcodeLoad(ProductBarcodeLoadList event, Emitter<ProductBarcodeState> emit) async {
    emit(ProductBarcodeInProgress());

    try {
      final results = await _productBarcodeRepository.getProductBarcodeList(
        offset: event.offset,
        limit: event.limit,
        search: event.search,
        itemtype: event.itemtype!,
        branchcode: event.branchcode,
        businesstypecode: event.businesstypecode,
        isbom: event.isbom!,
        isusesubbarcodes: event.isusesubbarcodes!,
      );

      if (results.success) {
        List<ProductBarcodeModel> productbarcodes = (results.data as List).map((productbarcode) => ProductBarcodeModel.fromJson(productbarcode)).toList();
        emit(ProductBarcodeLoadSuccess(productBarcodes: productbarcodes));
      } else {
        emit(const ProductBarcodeLoadFailed(message: 'ProductBarcode Not Found'));
      }
    } catch (e) {
      emit(ProductBarcodeLoadFailed(message: e.toString()));
    }
  }

  void onProductBarcodeLoadSearch(ProductBarcodeLoadListSearch event, Emitter<ProductBarcodeState> emit) async {
    emit(ProductBarcodeSearchInProgress());

    try {
      final results = await _productBarcodeRepository.getProductBarcodeList(
        offset: event.offset,
        limit: event.limit,
        search: event.search,
        itemtype: event.itemtype!,
        branchcode: event.branchcode,
        businesstypecode: event.businesstypecode,
        isbom: event.isbom!,
        isusesubbarcodes: event.isusesubbarcodes!,
      );

      if (results.success) {
        List<ProductBarcodeModel> productbarcodes = (results.data as List).map((productbarcode) => ProductBarcodeModel.fromJson(productbarcode)).toList();
        emit(ProductBarcodeLoadSearchSuccess(productBarcodes: productbarcodes));
      } else {
        emit(const ProductBarcodeLoadSearchFailed(message: 'ProductBarcode Not Found'));
      }
    } catch (e) {
      emit(ProductBarcodeLoadSearchFailed(message: e.toString()));
    }
  }

  void productbarcodeDelete(ProductBarcodeDelete event, Emitter<ProductBarcodeState> emit) async {
    emit(ProductBarcodeDeleteInProgress());
    try {
      await _productBarcodeRepository.deleteProductBarcode(event.guid);

      emit(ProductBarcodeDeleteSuccess());
    } catch (e) {
      // emit(ProductBarcodeDeleteFailure(message: e.toString()));
    }
  }

  void productbarcodeDeleteMany(ProductBarcodeDeleteMany event, Emitter<ProductBarcodeState> emit) async {
    emit(ProductBarcodeDeleteManyInProgress());
    try {
      await _productBarcodeRepository.deleteProductBarcodeMany(event.guid);

      emit(ProductBarcodeDeleteManySuccess());
    } catch (e) {
      emit(ProductBarcodeDeleteManyFailed(message: e.toString()));
    }
  }

  void onProductBarcodeSave(ProductBarcodeSave event, Emitter<ProductBarcodeState> emit) async {
    emit(ProductBarcodeSaveInProgress());
    try {
      await _productBarcodeRepository.saveProductBarcode(event.productBarcode);
      emit(ProductBarcodeSaveSuccess());
    } catch (e) {
      final error = jsonDecode(e.toString());
      emit(ProductBarcodeSaveFailed(message: error['message']));
    }
  }

  void onProductBarcodeUpdate(ProductBarcodeUpdate event, Emitter<ProductBarcodeState> emit) async {
    emit(ProductBarcodeUpdateInProgress());
    try {
      await _productBarcodeRepository.updateProductBarcode(event.guid, event.productBarcode);
      emit(ProductBarcodeUpdateSuccess());
    } catch (e) {
      emit(ProductBarcodeUpdateFailed(message: e.toString()));
    }
  }

  void onProductBarcodeGet(ProductBarcodeGet event, Emitter<ProductBarcodeState> emit) async {
    emit(ProductBarcodeGetInProgress());
    // print(event.guid);
    try {
      final result = await _productBarcodeRepository.getProductBarcode(event.guid);
      if (result.success) {
        ProductBarcodeModel productBarcode = ProductBarcodeModel.fromJson(result.data);
        emit(ProductBarcodeGetSuccess(productBarcode: productBarcode));
      } else {
        emit(const ProductBarcodeGetFailed(message: 'ProductBarcode Not Found'));
      }
    } catch (e) {
      // emit(ProductBarcodeDeleteFailure(message: e.toString()));
    }
  }

  void onProductBarcodeGetRef(ProductBarcodeGetRef event, Emitter<ProductBarcodeState> emit) async {
    emit(ProductBarcodeGetRefInProgress());
    // print(event.guid);
    try {
      final result = await _productBarcodeRepository.getProductBarcodeRef(event.guid);
      if (result.success) {
        List<ProductBarcodeModel> productbarcodes = (result.data as List).map((productbarcode) => ProductBarcodeModel.fromJson(productbarcode)).toList();
        emit(ProductBarcodeGetRefSuccess(productBarcodes: productbarcodes));
      } else {
        emit(const ProductBarcodeGetRefFailed(message: 'ProductBarcodeRef Not Found'));
      }
    } catch (e) {
      emit(ProductBarcodeGetRefFailed(message: e.toString()));
    }
  }

  void onProductBarcodeWithImageSave(ProductBarcodeWithImageSave event, Emitter<ProductBarcodeState> emit) async {
    emit(ProductBarcodeSaveInProgress());
    try {
      ApiResponse result = await _productBarcodeRepository.uploadImage(event.imageFile, event.imageWeb!);
      if (result.success) {
        UploadImageModel uploadImage = UploadImageModel.fromJson(result.data);
        ProductBarcodeModel productBarcodeModel = event.productBarcode;
        productBarcodeModel.imageuri = uploadImage.uri;
        await _productBarcodeRepository.saveProductBarcode(productBarcodeModel);
        emit(ProductBarcodeSaveSuccess());
      } else {
        emit(ProductBarcodeSaveFailed(message: result.message));
      }
    } catch (e) {
      emit(ProductBarcodeSaveFailed(message: e.toString()));
    }
  }

  void onProductBarcodeWithImageUpdate(ProductBarcodeWithImageUpdate event, Emitter<ProductBarcodeState> emit) async {
    emit(ProductBarcodeUpdateInProgress());
    try {
      ApiResponse result = await _productBarcodeRepository.uploadImage(event.imageFile, event.imageWeb);
      if (result.success) {
        UploadImageModel uploadImage = UploadImageModel.fromJson(result.data);
        ProductBarcodeModel productBarcodeModel = event.productBarcode;
        productBarcodeModel.imageuri = uploadImage.uri;
        await _productBarcodeRepository.updateProductBarcode(event.guid, productBarcodeModel);
        emit(ProductBarcodeUpdateSuccess());
      } else {
        emit(ProductBarcodeUpdateFailed(message: result.message));
      }
    } catch (e) {
      emit(ProductBarcodeUpdateFailed(message: e.toString()));
    }
  }

  void onProductBarcodeGetBom(ProductBarcodeGetBom event, Emitter<ProductBarcodeState> emit) async {
    emit(ProductBarcodeGetBomInProgress());
    try {
      final result = await _productBarcodeRepository.getProductBarcodeBom(event.barcode);
      if (result.success) {
        ProductBomModel productbom = ProductBomModel.fromJson(result.data);
        if (productbom.bom!.isNotEmpty) {}

        emit(ProductBarcodeGetBomSuccess(productBom: productbom));
      } else {
        emit(const ProductBarcodeGetBomFailed(message: 'ProductBarcodeBom Not Found'));
      }
    } catch (e) {
      emit(ProductBarcodeGetBomFailed(message: e.toString()));
    }
  }
}
