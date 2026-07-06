import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dedecashier/model/objectbox/product_barcode_struct.dart';
import 'package:dedecashier/core/performance/app_performance_manager.dart';
import 'package:dedecashier/global.dart' as global;

class ProductCard extends StatelessWidget {
  final ProductBarcodeObjectBoxStruct product;
  final VoidCallback onTap;
  final VoidCallback? onCountTap;
  final bool isMember;
  final double listTextHeight; // เพิ่ม parameter สำหรับ listTextHeight

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onCountTap,
    this.isMember = false,
    this.listTextHeight = 1.0, // ค่าเริ่มต้น
  });

  @override
  Widget build(BuildContext context) {
    String name = global.getNameFromJsonLanguage(product.names, global.userScreenLanguage);
    String unitName = global.getNameFromJsonLanguage(product.unit_names, global.userScreenLanguage);
    double price = global.getProductPrice(product.prices, isMember ? 2 : 1);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
              border: Border.all(
                color: Colors.grey.shade200,
                width: 0.5,
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: _buildContent(name, unitName, price),
                ),
                if (product.product_count > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onCountTap?.call();
                      },
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              spreadRadius: 0,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          global.formatDoubleTrailingZero(product.product_count),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: (11 * listTextHeight).clamp(9.0, 14.0), // ใช้ listTextHeight
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _buildContent(String name, String unitName, double price) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: product.image_or_color == false ? global.colorFromHex(product.color_select_hex.replaceAll("#", "")).withOpacity(0.1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // เพิ่มพื้นที่ให้รูปภาพมากขึ้น
          Expanded(
            flex: product.images_url.trim().isNotEmpty ? 4 : 3, // เพิ่ม flex ให้รูปภาพ
            child: product.images_url.trim().isNotEmpty ? _buildImageContent(name) : _buildTextContent(name),
          ),
          // ลดพื้นที่ของส่วนข้อมูลและใช้ความสูงแบบยืดหยุ่น
          Container(
            constraints: BoxConstraints(
              maxHeight: (45 * listTextHeight).clamp(40.0, 65.0), // เพิ่มความสูงเพื่อรองรับฟอนต์ใหญ่ขึ้น
            ),
            child: _buildInfoSection(name, unitName, price),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(String name) {
    return Container(
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
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
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
        child: Image(
          image: AppImageCacheManager.getCachedNetwork(product.images_url),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.grey.shade400,
                    size: 28, // ลดขนาด icon
                  ),
                  const SizedBox(height: 1), // ลดระยะห่าง
                  Text(
                    'ไม่มีรูปภาพ',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: (8 * listTextHeight).clamp(7.0, 10.0), // เพิ่มขนาด default เล็กน้อย
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextContent(String name) {
    return Container(
      margin: const EdgeInsets.all(2), // ลด margin
      child: Center(
        child: Text(
          name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: (13 * listTextHeight).clamp(11.0, 16.0), // เพิ่มขนาด default และขยายช่วง
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 3,
        ),
      ),
    );
  }

  Widget _buildInfoSection(String name, String unitName, double price) {
    return Container(
      padding: EdgeInsets.fromLTRB(2, 2, 2, 1), // เพิ่ม padding เล็กน้อยเพื่อให้มีพื้นที่มากขึ้น
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox(
                height: (13 * listTextHeight).clamp(14.0, 24.0), // เพิ่มความสูงให้รองรับฟอนต์ใหญ่ขึ้น
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: (14 * listTextHeight).clamp(10.0, 22.0), // เพิ่มขนาด default
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 1, bottom: 2, right: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (unitName.isNotEmpty)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                      child: Text(
                        unitName,
                        style: TextStyle(
                          fontSize: (11 * listTextHeight).clamp(7.0, 16.0), // เพิ่มขนาด default
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade700],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        spreadRadius: 0,
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    global.moneyFormat.format(price),
                    style: TextStyle(
                      fontSize: (13 * listTextHeight).clamp(9.0, 16.0), // เพิ่มขนาด default
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
