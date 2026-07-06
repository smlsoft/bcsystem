part of 'image_upload_bloc.dart';

abstract class ImageUploadEvent extends Equatable {
  const ImageUploadEvent();

  @override
  List<Object> get props => [];
}

class ImageUploadSaved extends ImageUploadEvent {
  final ImageUpload imageUpload;

  const ImageUploadSaved({
    required this.imageUpload,
  });

  @override
  List<Object> get props => [imageUpload];
}

class ImageUploadFileSaved extends ImageUploadEvent {
  final List<File> imageFiles;
  final List<Uint8List> imageWeb;

  const ImageUploadFileSaved({
    required this.imageWeb,
    required this.imageFiles,
  });

  @override
  List<Object> get props => [imageFiles];
}

class LogoUploadFileSaved extends ImageUploadEvent {
  final List<File> imageFiles;
  final List<Uint8List> imageWeb;

  const LogoUploadFileSaved({
    required this.imageWeb,
    required this.imageFiles,
  });

  @override
  List<Object> get props => [imageFiles];
}
