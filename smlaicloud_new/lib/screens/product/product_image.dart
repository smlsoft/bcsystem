import 'dart:io';
import 'dart:async';
import 'package:smlaicloud/screens/Product/product_add.dart';
import 'package:smlaicloud/bloc/image/image_upload_bloc.dart';
import 'package:smlaicloud/model/global_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_crop/image_crop.dart';
import 'package:image_picker/image_picker.dart';

class ProductEditImageScreen extends StatefulWidget {
  final bool useCamera;
  const ProductEditImageScreen(this.useCamera);

  @override
  _ProductEditImageState createState() => _ProductEditImageState();
}

class _ProductEditImageState extends State<ProductEditImageScreen> {
  final cropKey = GlobalKey<CropState>();
  File? _file;
  File? _sample;
  late File lastCropped;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _openImage();
  }

  @override
  void dispose() {
    super.dispose();
    /*_file?.delete();
    _sample?.delete();
    _lastCropped?.delete();*/
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocListener<ImageUploadBloc, ImageUploadState>(
        listener: (context, state) {
          if (state is ImageUploadSaveSuccess) {
            // // print('Url Response' + state.imageUpload.uri);
            Navigator.of(context, rootNavigator: true).pop(state.imageUpload);

            // Navigator.of(context).pushReplacement(
            //   MaterialPageRoute(
            //     builder: (_) => ProductAdd(url: state.imageUpload.uri),
            //   ),
            // );
          }
        },
        child: SafeArea(
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
            child: _sample == null ? _buildOpeningImage() : _buildCroppingImage(),
          ),
        ),
      ),
    );
  }

  Widget _buildOpeningImage() {
    return Center(child: _buildOpenImage());
  }

  Widget _buildOpenImage() {
    return TextButton(onPressed: () {}, child: Container());
  }

  Widget _buildCroppingImage() {
    return Column(
      children: <Widget>[
        Expanded(
          child: Crop.file(_sample!, key: cropKey),
        ),
        Container(
          padding: const EdgeInsets.only(top: 20.0),
          alignment: AlignmentDirectional.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              TextButton(
                child: Text(
                  'บันทึก',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
                ),
                onPressed: () => _cropImage(),
              ),
              TextButton(
                child: Text(
                  (widget.useCamera) ? "ถ่ายรูปใหม่ " : 'เลือกรูปใหม่',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
                ),
                onPressed: () => _openImage(),
              ),
            ],
          ),
        )
      ],
    );
  }

  Future<void> _openImage() async {
    if (widget.useCamera) {
      // _file =
      //     (await ImagePicker().pickImage(source: ImageSource.camera)) as File;
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      setState(() {
        if (image != null) {
          final File file = File(image.path);
          _file = file;
        } else {
          // print('No image selected.');
        }
      });

      // final File? file = File(image!.path);
    } else {
      // _file =
      //     (await ImagePicker().pickImage(source: ImageSource.gallery)) as File;
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      setState(() {
        if (image != null) {
          final File file = File(image.path);
          _file = file;
        } else {
          // print('No image selected.');
        }
      });
    }
    if (_file != null) {
      _sample = await ImageCrop.sampleImage(
        file: _file!,
        preferredSize: context.size?.longestSide.ceil(),
      );
    } else {
      Navigator.pop(context);
    }

    if (widget.useCamera) {
      /*final file = await ImagePicker.pickImage(source: ImageSource.camera);
      final sample = await ImageCrop.sampleImage(
        file: file,
        preferredSize: context.size.longestSide.ceil(),
      );*/

      //_sample?.delete();
      //_file?.delete();

      setState(() {
        /*_sample = sample;
        _file = file;*/
      });
    } else {
      /*final file = await ImagePicker.pickImage(source: ImageSource.gallery);
      final sample = await ImageCrop.sampleImage(
        file: file,
        preferredSize: context.size.longestSide.ceil(),
      );*/

      //_sample?.delete();
      //_file?.delete();

      setState(() {
        /*_sample = sample;
        _file = file;*/
      });
    }
  }

  Future<void> _cropImage() async {
    final scale = cropKey.currentState!.scale;
    final area = cropKey.currentState?.area;
    if (area == null) {
      // cannot crop, widget is not setup
      return;
    }

    // scale up to use maximum possible number of pixels
    // this will sample image in higher resolution to make cropped image larger
    final sample = await ImageCrop.sampleImage(
      file: _file!,
      preferredSize: (2000 / scale).round(),
    );

    final file = await ImageCrop.cropImage(
      file: sample,
      area: area,
    );

    // sample.delete();

    //_lastCropped?.delete();
    //_lastCropped = file;

    Image getImage = Image.file(file);
    ImageResponse response = ImageResponse(file.path, getImage);

    // print('File photo $file');

    ImageUpload url = ImageUpload(
      uri: file.path.toString(),
    );

    context.read<ImageUploadBloc>().add(ImageUploadSaved(imageUpload: url));
  }
}

class ImageResponse {
  final String? path;
  final Image? image;

  const ImageResponse(this.path, this.image);
}
