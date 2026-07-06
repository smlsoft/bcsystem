import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:dedeorder/global.dart' as global;

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }
    return MaterialApp(
        home: SafeArea(
            child: Column(
      children: [
        Expanded(
            child: Center(
                child: SizedBox(
                    width: 500,
                    height: 1000,
                    child: CameraPreview(controller)))),
        Row(children: [
          Expanded(
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('ยกเลิก'))),
          const SizedBox(width: 10),
          Expanded(
              child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await _initializeControllerFuture;
                      final image = await controller.takePicture();
                      if (mounted) {
                        Navigator.pop(context, image.path);
                      }
                    } catch (e, s) {
                      print(e);
                      global.sendErrorToDevTeam("TakePictureScreenState:$e $s");
                    }
                  },
                  child: const Text('ถ่ายรูป SLIP'))),
        ]),
      ],
    )));
  }
}
