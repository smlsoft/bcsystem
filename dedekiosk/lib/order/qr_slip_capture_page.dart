import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dedekiosk/global.dart' as global;

/// หน้าถ่ายภาพหลักฐานการโอนเงิน (QR Payment Proof)
class QrSlipCapturePage extends StatefulWidget {
  final String docNo;
  final double amount;

  const QrSlipCapturePage({
    super.key,
    required this.docNo,
    required this.amount,
  });

  @override
  State<QrSlipCapturePage> createState() => _QrSlipCapturePageState();
}

class _QrSlipCapturePageState extends State<QrSlipCapturePage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _capturedImage;
  bool _isCapturing = false;

  Future<void> _captureImage() async {
    if (_isCapturing) return;

    if (kDebugMode) {
      print("📷 _captureImage() called");
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      if (kDebugMode) {
        print("📷 Opening camera...");
      }
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 50,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (kDebugMode) {
        print("📷 Camera result: ${image?.path ?? 'null'}");
      }

      if (image != null) {
        setState(() {
          _capturedImage = image;
        });
        if (kDebugMode) {
          print("📷 Image captured and stored: ${_capturedImage?.path}");
        }
      } else {
        if (kDebugMode) {
          print("📷 No image captured (user cancelled or error)");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("📷 Camera error: $e");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${global.language("error")}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _retakeImage() async {
    if (kDebugMode) {
      print("📷 _retakeImage() called");
    }
    setState(() {
      _capturedImage = null;
    });
    await _captureImage();
  }

  void _confirmAndReturn() {
    if (kDebugMode) {
      print("📷 _confirmAndReturn() called - _capturedImage: ${_capturedImage?.path ?? 'null'}");
    }
    if (_capturedImage != null) {
      if (kDebugMode) {
        print("📷 Navigator.pop with path: ${_capturedImage!.path}");
      }
      Navigator.pop(context, _capturedImage!.path);
    } else {
      if (kDebugMode) {
        print("📷 ERROR: _capturedImage is null, cannot return path!");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print("📷 QrSlipCapturePage initState()");
    }
    // เปิดกล้องทันทีเมื่อเข้าหน้านี้
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureImage();
    });
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print("📷 QrSlipCapturePage dispose() - _capturedImage: ${_capturedImage?.path ?? 'null'}");
    }
    super.dispose();
  }

  void _cancelAndReturn() {
    if (kDebugMode) {
      print("📷 _cancelAndReturn() called - user wants to cancel");
    }
    Navigator.pop(context, null);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    final titleFontSize = isMobile ? 18.0 : (isTablet ? 22.0 : 26.0);
    final subtitleFontSize = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);
    final buttonFontSize = isMobile ? 14.0 : (isTablet ? 16.0 : 18.0);
    final iconSize = isMobile ? 60.0 : (isTablet ? 80.0 : 100.0);
    final containerPadding = isMobile ? 16.0 : 24.0;

    // ใช้ PopScope เพื่อป้องกัน back gesture ขณะที่กล้องกำลังเปิด
    return PopScope(
      canPop: false, // ป้องกัน iOS back gesture
      onPopInvokedWithResult: (didPop, result) {
        if (kDebugMode) {
          print("📷 PopScope onPopInvokedWithResult - didPop: $didPop, _isCapturing: $_isCapturing");
        }
        if (!didPop) {
          // ถ้ากำลังถ่ายรูปอยู่ ไม่อนุญาตให้ pop
          if (_isCapturing) {
            if (kDebugMode) {
              print("📷 PopScope: Blocked pop while camera is active");
            }
            return;
          }
          // ถ้ามีรูปแล้ว ถามก่อน pop
          if (_capturedImage != null) {
            _confirmAndReturn();
          } else {
            _cancelAndReturn();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: const Color(0xFFDA291C),
          foregroundColor: Colors.white,
          title: Text(
            global.language("payment_proof"),
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _isCapturing ? null : _cancelAndReturn, // Disable ขณะกล้องเปิด
          ),
        ),
        body: SafeArea(
          child: _capturedImage == null
              ? _buildCapturePrompt(
                  isMobile,
                  isTablet,
                  titleFontSize,
                  subtitleFontSize,
                  buttonFontSize,
                  iconSize,
                  containerPadding,
                )
              : _buildPreview(
                  isMobile,
                  isTablet,
                  titleFontSize,
                  subtitleFontSize,
                  buttonFontSize,
                  containerPadding,
                ),
        ),
      ),
    );
  }

  Widget _buildCapturePrompt(
    bool isMobile,
    bool isTablet,
    double titleFontSize,
    double subtitleFontSize,
    double buttonFontSize,
    double iconSize,
    double containerPadding,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(containerPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconSize * 1.5,
              height: iconSize * 1.5,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                size: iconSize,
                color: Colors.blue.shade400,
              ),
            ),
            SizedBox(height: isMobile ? 24 : 32),
            Text(
              global.language("please_capture_payment_proof"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "${global.language("amount")}: ${global.moneyFormat.format(widget.amount)} ${global.language("baht")}",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: subtitleFontSize,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: isMobile ? 32 : 48),
            if (_isCapturing)
              Column(
                children: [
                  CircularProgressIndicator(
                    color: Colors.blue.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    global.language("opening_camera"),
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _captureImage,
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  global.language("take_photo"),
                  style: TextStyle(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 32 : 48,
                    vertical: isMobile ? 14 : 18,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(
    bool isMobile,
    bool isTablet,
    double titleFontSize,
    double subtitleFontSize,
    double buttonFontSize,
    double containerPadding,
  ) {
    final imageMaxHeight = MediaQuery.of(context).size.height * (isMobile ? 0.5 : 0.6);

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(containerPadding),
            child: Column(
              children: [
                Text(
                  global.language("preview_payment_proof"),
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(maxHeight: imageMaxHeight),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(_capturedImage!.path),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(containerPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retakeImage,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    global.language("retake"),
                    style: TextStyle(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 18),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmAndReturn,
                  icon: const Icon(Icons.check),
                  label: Text(
                    global.language("confirm"),
                    style: TextStyle(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
