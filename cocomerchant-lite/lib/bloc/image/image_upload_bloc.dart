import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocomerchant_lite/repositories/image_upload_repository.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:equatable/equatable.dart';

part 'image_upload_event.dart';
part 'image_upload_state.dart';

class ImageUploadBloc extends Bloc<ImageUploadEvent, ImageUploadState> {
  final ImageUploadRepository _imageUploadRepository;

  ImageUploadBloc({required ImageUploadRepository imageUploadRepository})
      : _imageUploadRepository = imageUploadRepository,
        super(ImageUploadInitial()) {
    on<ImageUploadSaved>(_onImageUpload);
    on<ImageUploadFileSaved>(_onImageUploadFile);
    on<LogoUploadFileSaved>(_onLogoUploadFile);
  }
  void _onImageUpload(ImageUploadSaved event, Emitter<ImageUploadState> emit) async {
    emit(ImageUploadSaveInProgress());
    try {
      final result = await _imageUploadRepository.uploadImage(event.imageUpload);

      if (result.success) {
        ImageUpload imageUpload = ImageUpload.fromJson(result.data);
        emit(ImageUploadSaveSuccess(imageUpload: imageUpload));
      } else {
        emit(const ImageUploadSaveFailure(message: 'ImageUpload Not Found'));
      }
    } catch (e) {
      emit(ImageUploadSaveFailure(message: e.toString()));
    }
  }

  void _onImageUploadFile(ImageUploadFileSaved event, Emitter<ImageUploadState> emit) async {
    emit(ImageUploadSaveInProgress());
    try {
      final result = await _imageUploadRepository.uploadImageFile(event.imageFiles[0], event.imageWeb[0]);

      if (result.success) {
        ImageUpload imageUpload = ImageUpload.fromJson(result.data);
        emit(ImageUploadSaveSuccess(imageUpload: imageUpload));
      } else {
        emit(const ImageUploadSaveFailure(message: 'ImageUpload Not Found'));
      }
    } catch (e) {
      emit(ImageUploadSaveFailure(message: e.toString()));
    }
  }

  void _onLogoUploadFile(LogoUploadFileSaved event, Emitter<ImageUploadState> emit) async {
    emit(ImageUploadSaveInProgress());
    try {
      final result = await _imageUploadRepository.uploadImageFile(event.imageFiles[0], event.imageWeb[0]);

      if (result.success) {
        ImageUpload imageUpload = ImageUpload.fromJson(result.data);
        emit(LogoUploadSaveSuccess(imageUpload: imageUpload));
      } else {
        emit(const ImageUploadSaveFailure(message: 'ImageUpload Not Found'));
      }
    } catch (e) {
      emit(ImageUploadSaveFailure(message: e.toString()));
    }
  }
}
