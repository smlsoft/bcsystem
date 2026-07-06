import 'package:flutter/material.dart';

class CustomRootScreenShapeClipper extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    final Path path = Path();
    path.lineTo(0.0, size.height * 0.5);

    var firstEndpoint = Offset(size.width * 0.7, size.height * 0);
    var firstControlPoint = Offset(size.width * 0.75, size.height * 0.45);

    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndpoint.dx, firstEndpoint.dy);

    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    return true;
  }
}

class CustomRootScreenShapeClipper2 extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    final Path path = Path();
    path.moveTo(size.width * 0.3, size.height);
    path.lineTo(size.width * 0.3, size.height);
    path.lineTo(size.width, size.height * 0.5);

    var firstEndpoint = Offset(size.width * 0.3, size.height);
    var firstControlPoint = Offset(size.width * 0.25, size.height * 0.75);

    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndpoint.dx, firstEndpoint.dy);

//    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    return true;
  }
}

//************************ for login design 1 *********************************
class CustomLoginShapeClipper1 extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    final Path path = Path();
    path.lineTo(0.0, size.height * 0.5);

    var firstEndpoint = Offset(size.width, size.height * 0.25);
    var firstControlPoint = Offset(size.width * 0.75, size.height * 0.5);

    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndpoint.dx, firstEndpoint.dy);

    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    return true;
  }
}

class CustomLoginShapeClipper2 extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    final Path path = Path();
    path.lineTo(0.0, size.height * 0.85);

    var firstEndpoint = Offset(size.width, size.height * 0.7);
    var firstControlPoint = Offset(size.width * 0.6, size.height * 0.85);

    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndpoint.dx, firstEndpoint.dy);

    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    return true;
  }
}

class VFPosLoginShapeClipper extends CustomClipper<Path> {
  @override
  getClip(Size size) {
    final Path path = Path();
    path.lineTo(0.0, size.height * 0.4);

    var firstEndpoint = Offset(size.width, size.height * 0.1);
    var firstControlPoint = Offset(size.width * 0.6, size.height * 0.5);

    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndpoint.dx, firstEndpoint.dy);

    path.lineTo(size.width, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) {
    return true;
  }
}
