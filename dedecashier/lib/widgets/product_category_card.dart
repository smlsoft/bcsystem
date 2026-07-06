import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dedecashier/model/objectbox/product_category_struct.dart';
import 'package:dedecashier/core/performance/app_performance_manager.dart';
import 'package:dedecashier/global.dart' as global;

class ProductCategoryCard extends StatelessWidget {
  final ProductCategoryObjectBoxStruct category;
  final double size;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showCount;
  final double listTextHeight; // เพิ่ม parameter สำหรับ listTextHeight

  const ProductCategoryCard({
    super.key,
    required this.category,
    required this.size,
    required this.isSelected,
    required this.onTap,
    this.showCount = false,
    this.listTextHeight = 1.0, // ค่าเริ่มต้น
  });

  @override
  Widget build(BuildContext context) {
    String name = global.getNameFromJsonLanguage(category.names, global.userScreenLanguage);

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(2),
      child: Material(
        elevation: isSelected ? 4 : 2,
        borderRadius: BorderRadius.circular(8),
        shadowColor: isSelected ? Colors.blue.withOpacity(0.3) : Colors.grey.withOpacity(0.15),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey.shade50,
                      ],
                    ),
              border: Border.all(
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildContent(name),
                ),
                if (showCount && category.category_count > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade500,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.25),
                            spreadRadius: 0,
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '${category.category_count}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (10 * listTextHeight).clamp(8.0, 12.0), // ใช้ listTextHeight
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(String name) {
    if (category.use_image_or_color && category.image_url.isNotEmpty) {
      return _buildImageContent(name);
    } else {
      return _buildTextContent(name);
    }
  }

  Widget _buildImageContent(String name) {
    return Column(
      children: [
        // เพิ่มพื้นที่ให้รูปภาพมากขึ้น
        Expanded(
          flex: 4, // รูปภาพใช้พื้นที่ 4 ส่วน
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  spreadRadius: 0,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image(
                image: AppImageCacheManager.getCachedNetwork(category.image_url),
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.category,
                      color: Colors.grey.shade400,
                      size: size * 0.4, // เพิ่มขนาด icon
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // ลดพื้นที่ของข้อความ
        Expanded(
          flex: 1, // ข้อความใช้พื้นที่ 1 ส่วน
          child: Container(
            padding: const EdgeInsets.fromLTRB(2, 1, 2, 2),
            child: Center(
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1, // ลดเหลือ 1 บรรทัด
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: (10 * listTextHeight).clamp(8.0, 14.0), // ใช้ listTextHeight
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextContent(String name) {
    Color backgroundColor = Colors.transparent;
    if (!category.use_image_or_color && category.colorselecthex.isNotEmpty) {
      backgroundColor = global.colorFromHex(category.colorselecthex.replaceAll("#", "")).withOpacity(0.3);
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor,
      ),
      child: Center(
        child: Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: (13 * listTextHeight).clamp(10.0, 18.0), // ใช้ listTextHeight
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
            height: 1.1,
            shadows: isSelected
                ? [
                    const Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black26,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
