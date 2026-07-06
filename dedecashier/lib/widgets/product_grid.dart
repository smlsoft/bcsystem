import 'package:flutter/material.dart';
import 'package:dedecashier/widgets/product_card.dart';
import 'package:dedecashier/model/objectbox/product_barcode_struct.dart';
import 'package:dedecashier/global.dart' as global;

class ProductGrid extends StatelessWidget {
  final List<ProductBarcodeObjectBoxStruct> products;
  final Function(ProductBarcodeObjectBoxStruct) onProductTap;
  final Function(ProductBarcodeObjectBoxStruct)? onProductCountTap;
  final bool isMember;
  final double listTextHeight;

  const ProductGrid({
    super.key,
    required this.products,
    required this.onProductTap,
    this.onProductCountTap,
    this.isMember = false,
    this.listTextHeight = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return _buildEmptyState();
    }

    double screenWidth = MediaQuery.of(context).size.width;
    double cardMinWidth = (global.isTabletScreen() || global.isDesktopScreen()) ? 160 : 140; // เพิ่มขนาดกล่องสินค้า
    int crossAxisCount = (screenWidth / cardMinWidth).floor().clamp(2, 6);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
        ),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(8), // เพิ่ม padding รอบ grid
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.1, // เพิ่มความสูงเล็กน้อยเพื่อให้พอดี
          mainAxisSpacing: 8, // เพิ่มระยะห่างระหว่างแถว
          crossAxisSpacing: 8, // เพิ่มระยะห่างระหว่างคอลัมน์
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            product: product,
            isMember: isMember,
            listTextHeight: listTextHeight,
            onTap: () => onProductTap(product),
            onCountTap: onProductCountTap != null ? () => onProductCountTap!(product) : null,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.grey.shade400,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ไม่พบสินค้าในหมวดหมู่นี้',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'เลือกหมวดหมู่อื่นหรือเพิ่มสินค้าใหม่',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
