import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

Future<void> savePdf(Uint8List pdfData, String fileName, BuildContext context) async {
  final result = await FilePicker.platform.saveFile(
    dialogTitle: 'บันทึกไฟล์ PDF',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );
  if (result != null) {
    final file = File(result);
    await file.writeAsBytes(pdfData);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('บันทึกไฟล์เรียบร้อยแล้ว')),
    );
  }
}
