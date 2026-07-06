import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data'; // เพิ่ม import
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/constants.dart';

class ImagePickerWidget extends StatelessWidget {
  final File? image;
  final String? imageUrl;
  final Uint8List? imageWeb; // เพิ่มพารามิเตอร์
  final Function(ImageSource) onImagePicked;
  final VoidCallback? onImageRemoved;
  final bool isLoading;

  const ImagePickerWidget({
    Key? key,
    this.image,
    this.imageUrl,
    this.imageWeb, // เพิ่มพารามิเตอร์
    required this.onImagePicked,
    this.onImageRemoved,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: () => _showImageSourceDialog(context),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _buildImageContent(),
              ),
            ),
            if (onImageRemoved != null)
              if (image != null || imageUrl != null || imageWeb != null)
                Positioned(
                  top: -10,
                  right: -10,
                  child: IconButton(
                    icon: Icon(Icons.cancel, color: Colors.red[700], size: 24),
                    onPressed: onImageRemoved,
                  ),
                ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'รูปภาพที่มีคุณภาพสูงมักเป็นที่นิยมมากกว่า',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'ขนาดสูงสุด 2 MB',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'ประเภทไฟล์ที่รับ: PNG, JPG',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent() {
    if (image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(image!, fit: BoxFit.cover),
      );
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.error, color: Colors.red, size: 40);
          },
        ),
      );
    } else if (imageWeb != null) {
      // ตรวจสอบ imageWeb
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(imageWeb!, fit: BoxFit.cover),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 40, color: kPrimaryColor),
          const SizedBox(height: 8),
          Text(
            global.language('add_photo'),
            style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
  }

  void _showImageSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(global.language('select_image_source'), style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library, color: kPrimaryColor),
                title: Text(global.language('gallery')),
                onTap: () {
                  Navigator.of(context).pop();
                  onImagePicked(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: kPrimaryColor),
                title: Text(global.language('camera')),
                onTap: () {
                  Navigator.of(context).pop();
                  onImagePicked(ImageSource.camera);
                },
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }
}
