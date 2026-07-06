import 'dart:typed_data';

import 'package:smlaicloud/model/import_product_model.dart';
import 'package:smlaicloud/model/pagination.dart';
import 'package:smlaicloud/repositories/client.dart';
import 'package:smlaicloud/repositories/product_import_repository.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

part 'import_product_event.dart';
part 'import_product_state.dart';

class ImportProductBloc extends Bloc<ImportProductEvent, ImportProductState> {
  final ImportProductRepository _importProductRepository;

  ImportProductBloc({required ImportProductRepository importProductRepository})
      : _importProductRepository = ImportProductRepository(),
        super(ImportProductInitial()) {
    on<UploadFileExcel>(onUploadFileExcel);
    on<LoadImportProductByTaskid>(onLoadImportProductByTaskid);
    on<UpdateDetail>(onUpdateDetail);
    on<AddDetail>(onAddDetail);
    on<DeleteDetailByGuid>(onDeleteDetailByGuid);
    on<SaveTaskid>(onSaveTaskid);
    on<DeleteTaskid>(onDeleteTaskid);
    on<VerifyTaskid>(onVerifyTaskid);
  }

  /// upload file excel
  void onUploadFileExcel(UploadFileExcel event, Emitter<ImportProductState> emit) async {
    emit(UploadFileExcelInProgress());
    try {
      final result = await _importProductRepository.uploadFileExcel(event.file, event.filename);

      if (result.success) {
        UploadSuccessModel uploadSuccessModel = UploadSuccessModel(success: result.success, id: result.id);
        emit(UploadFileExcelSuccess(response: uploadSuccessModel));
      } else {
        emit(const UploadFileExcelFailed(message: 'Upload FileExcel Failure'));
      }
    } catch (e) {
      emit(UploadFileExcelFailed(message: e.toString()));
    }
  }

  /// load stock balance import by taskid
  void onLoadImportProductByTaskid(LoadImportProductByTaskid event, Emitter<ImportProductState> emit) async {
    emit(UploadFileExcelInProgress());
    try {
      final result = await _importProductRepository.getImportProduct(event.taskid, event.q, event.limit, event.page);

      if (result.success) {
        List<ImportProductModel> importProductModel = (result.data as List).map((tables) => ImportProductModel.fromJson(tables)).toList();
        Page page = result.page ?? Page.empty;

        Pagination pagination = Pagination(
          page: page.page,
          perPage: page.perPage,
          total: page.total,
          totalPage: page.totalPage,
          next: 0,
          prev: 0,
        );

        emit(LoadImportProductByTaskidSuccess(
          data: importProductModel,
          pagination: pagination,
        ));
      } else {
        emit(const LoadImportProductByTaskidFailed(message: 'Load Stock Balance Import By Taskid Failure'));
      }
    } catch (e) {
      emit(LoadImportProductByTaskidFailed(message: e.toString()));
    }
  }

  /// update detail
  void onUpdateDetail(UpdateDetail event, Emitter<ImportProductState> emit) async {
    emit(UpdateDetailInProgress());
    try {
      final result = await _importProductRepository.updateDetail(event.guid, event.importProductModel);

      if (result.success) {
        emit(UpdateDetailSuccess());
      } else {
        emit(const UpdateDetailFailed(message: 'Update Detail Failure'));
      }
    } catch (e) {
      emit(UpdateDetailFailed(message: e.toString()));
    }
  }

  /// add detail
  void onAddDetail(AddDetail event, Emitter<ImportProductState> emit) async {
    emit(AddDetailInProgress());
    try {
      final result = await _importProductRepository.addDetail(event.importProductModel);

      if (result.success) {
        emit(AddDetailSuccess());
      } else {
        emit(const AddDetailFailed(message: 'Add Detail Failure'));
      }
    } catch (e) {
      emit(AddDetailFailed(message: e.toString()));
    }
  }

  /// delete  detail stock balance import by guid
  void onDeleteDetailByGuid(DeleteDetailByGuid event, Emitter<ImportProductState> emit) async {
    emit(DeleteDetailByGuidInProgress());
    try {
      final result = await _importProductRepository.deleteDetailByGuid(event.guid);

      if (result.success) {
        emit(DeleteDetailByGuidSuccess());
      } else {
        emit(const DeleteDetailByGuidFailed(message: 'Delete Import Product Deltail By Guid Failure'));
      }
    } catch (e) {
      emit(DeleteDetailByGuidFailed(message: e.toString()));
    }
  }

  /// save taskid
  void onSaveTaskid(SaveTaskid event, Emitter<ImportProductState> emit) async {
    emit(SaveTaskidInProgress());
    try {
      final result = await _importProductRepository.saveTaskid(event.taskid, event.languangecode);

      if (result.success) {
        emit(SaveTaskidSuccess());
      } else {
        emit(const SaveTaskidFailed(message: 'Save Taskid Failure'));
      }
    } catch (e) {
      emit(SaveTaskidFailed(message: e.toString()));
    }
  }

  /// delete taskid
  void onDeleteTaskid(DeleteTaskid event, Emitter<ImportProductState> emit) async {
    emit(DeleteTaskidInProgress());
    try {
      final result = await _importProductRepository.deleteTaskid(event.taskid);

      if (result.success) {
        emit(DeleteTaskidSuccess());
      } else {
        emit(const DeleteTaskidFailed(message: 'Delete Task ID Failure'));
      }
    } catch (e) {
      emit(DeleteTaskidFailed(message: e.toString()));
    }
  }

  /// verify taskid
  void onVerifyTaskid(VerifyTaskid event, Emitter<ImportProductState> emit) async {
    emit(VerifyTaskidInProgress());
    try {
      final result = await _importProductRepository.verifyTaskid(event.taskid);

      if (result.success) {
        emit(VerifyTaskidSuccess());
      } else {
        emit(const VerifyTaskidFailed(message: 'Verify Task ID Failure'));
      }
    } catch (e) {
      emit(VerifyTaskidFailed(message: e.toString()));
    }
  }
}
