import 'dart:convert';

import 'package:cocomerchant_lite/model/pos_media_model.dart';
import 'package:cocomerchant_lite/repositories/pos_media_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/model/master_model.dart';
import 'package:cocomerchant_lite/repositories/client.dart';
import 'dart:io';

part 'pos_media_event.dart';
part 'pos_media_state.dart';

class PosMediaBloc extends Bloc<PosMediaEvent, PosMediaState> {
  final PosMediaRepository _posMediaRepository;

  PosMediaBloc({required PosMediaRepository posMediaRepository})
      : _posMediaRepository = posMediaRepository,
        super(PosMediaInitial()) {
    on<PosMediaLoadList>(onPosMediaLoad);
    on<PosMediaSave>(onPosMediaSave);
    on<PosMediaUpdate>(onPosMediaUpdate);
    on<PosMediaDelete>(onPosMediaDelete);
    on<PosMediaDeleteMany>(onPosMediaDeleteMany);
    on<PosMediaGet>(onPosMediaGet);
    on<PosMediaWithImageSave>(onPosMediaWithImageSave);
    on<PosMediaWithImageUpdate>(onPosMediaWithImageUpdate);
  }

  void onPosMediaLoad(PosMediaLoadList event, Emitter<PosMediaState> emit) async {
    emit(PosMediaInProgress());

    try {
      final results = await _posMediaRepository.getPosList(offset: event.offset, limit: event.limit, search: event.search);

      if (results.success) {
        List<PosMediaModel> posMedias = (results.data as List).map((posMedias) => PosMediaModel.fromJson(posMedias)).toList();
        emit(PosMediaLoadSuccess(posMedias: posMedias));
      } else {
        emit(const PosMediaLoadFailed(message: 'Pos Settings Not Found'));
      }
    } catch (e) {
      emit(PosMediaLoadFailed(message: e.toString()));
    }
  }

  void onPosMediaDelete(PosMediaDelete event, Emitter<PosMediaState> emit) async {
    emit(PosMediaDeleteInProgress());
    try {
      await _posMediaRepository.deletePos(event.guid);

      emit(PosMediaDeleteSuccess());
    } catch (e) {
      emit(PosMediaDeleteFailed());
    }
  }

  void onPosMediaDeleteMany(PosMediaDeleteMany event, Emitter<PosMediaState> emit) async {
    emit(PosMediaDeleteManyInProgress());
    try {
      await _posMediaRepository.deletePosMany(event.guid);

      emit(PosMediaDeleteManySuccess());
    } catch (e) {
      emit(PosMediaDeleteFailed());
    }
  }

  void onPosMediaSave(PosMediaSave event, Emitter<PosMediaState> emit) async {
    emit(PosMediaSaveInProgress());
    try {
      await _posMediaRepository.savePos(event.posMedia);
      emit(PosMediaSaveSuccess());
    } catch (e) {
      final error = jsonDecode(e.toString());
      emit(PosMediaSaveFailed(message: error['message']));
    }
  }

  void onPosMediaUpdate(PosMediaUpdate event, Emitter<PosMediaState> emit) async {
    emit(PosMediaUpdateInProgress());
    try {
      await _posMediaRepository.updatePos(event.guid, event.posMedia);
      emit(PosMediaUpdateSuccess());
    } catch (e) {
      final error = jsonDecode(e.toString());
      emit(PosMediaUpdateFailed(message: error['message']));
    }
  }

  void onPosMediaGet(PosMediaGet event, Emitter<PosMediaState> emit) async {
    emit(PosMediaGetInProgress());
    try {
      final result = await _posMediaRepository.getPos(event.guid);
      if (result.success) {
        PosMediaModel posMedia = PosMediaModel.fromJson(result.data);
        emit(PosMediaGetSuccess(posMedia: posMedia));
      } else {
        emit(const PosMediaGetFailed(message: 'PosMedia Not Found'));
      }
    } catch (e) {
      emit(PosMediaGetFailed(message: e.toString()));
    }
  }

  void onPosMediaWithImageSave(PosMediaWithImageSave event, Emitter<PosMediaState> emit) async {
    emit(PosMediaSaveInProgress());
    try {
      List<String> uri = [];
      if (event.imageFile.isNotEmpty) {
        for (int i = 0; i < event.imageFile.length; i++) {
          if (event.imageFile[i].uri.toString() != '') {
            ApiResponse result = await _posMediaRepository.uploadImage(event.imageFile[i], event.imageWeb[i]);
            if (result.success) {
              UploadImageModel uploadImage = UploadImageModel.fromJson(result.data);
              uri.add(uploadImage.uri);
            } else {
              emit(PosMediaSaveFailed(message: result.message));
            }
          }
        }
        if (uri.isNotEmpty) {
          PosMediaModel posMedia = event.posMedia;

          for (int i = 0; i < uri.length; i++) {
            posMedia.resources[i].uri = uri[i];
          }

          await _posMediaRepository.savePos(posMedia);
          emit(PosMediaSaveSuccess());
        } else {
          emit(const PosMediaSaveFailed(message: 'image upload failed'));
        }
      } else {
        emit(const PosMediaSaveFailed(message: 'no image found'));
      }
    } catch (e) {
      final error = jsonDecode(e.toString());
      emit(PosMediaSaveFailed(message: error['message']));
    }
  }

  void onPosMediaWithImageUpdate(PosMediaWithImageUpdate event, Emitter<PosMediaState> emit) async {
    emit(PosMediaUpdateInProgress());
    try {
      List<String> uri = [];
      if (event.imagesUris.isNotEmpty) {
        for (int i = 0; i < event.imagesUris.length; i++) {
          if (event.imageWeb[i].isNotEmpty) {
            ApiResponse result = await _posMediaRepository.uploadImage(event.imageFiles[i], event.imageWeb[i]);
            if (result.success) {
              UploadImageModel uploadImage = UploadImageModel.fromJson(result.data);
              uri.add(uploadImage.uri);
            } else {
              emit(PosMediaUpdateFailed(message: result.message));
            }
          } else if (event.imagesUris[i].uri != '') {
            uri.add(event.imagesUris[i].uri);
          }
        }

        if (uri.isNotEmpty) {
          PosMediaModel posMedia = event.posMedia;

          for (int i = 0; i < uri.length; i++) {
            posMedia.resources[i].uri = uri[i];
          }

          await _posMediaRepository.updatePos(event.guid, posMedia);
          emit(PosMediaUpdateSuccess());
        } else {
          emit(const PosMediaUpdateFailed(message: 'image upload failed'));
        }
      } else {
        emit(const PosMediaUpdateFailed(message: 'no image found'));
      }
    } catch (e) {
      emit(PosMediaUpdateFailed(message: e.toString()));
    }
  }
}
