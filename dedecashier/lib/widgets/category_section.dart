import 'package:flutter/material.dart';
import 'package:dedecashier/widgets/product_category_card.dart';
import 'package:dedecashier/model/objectbox/product_category_struct.dart';
import 'package:dedecashier/global.dart' as global;

class CategorySection extends StatelessWidget {
  final List<ProductCategoryObjectBoxStruct> categories;
  final String selectedCategoryId;
  final Function(ProductCategoryObjectBoxStruct) onCategoryTap;
  final VoidCallback? onResetTap;
  final String title;
  final bool showResetButton;
  final double listTextHeight;

  const CategorySection({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategoryTap,
    this.onResetTap,
    this.title = '',
    this.showResetButton = false,
    this.listTextHeight = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty && !showResetButton) {
      return const SizedBox.shrink();
    }

    double cardSize = (global.isDesktopScreen() || global.isTabletScreen()) ? 85 : 70; // เพิ่มขนาดกล่องหมวดหมู่

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: showResetButton ? [Colors.blue.shade50, Colors.blue.shade100] : [Colors.grey.shade50, Colors.grey.shade100],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: showResetButton ? Colors.blue.shade200 : Colors.grey.shade300,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: (13 * listTextHeight).clamp(10.0, 18.0),
                  fontWeight: FontWeight.w600,
                  color: showResetButton ? Colors.blue.shade700 : Colors.grey.shade700,
                ),
              ),
            ),
          SizedBox(
            height: cardSize + 15, // เพิ่มพื้นที่สำหรับกล่องหมวดหมู่ที่ใหญ่ขึ้น
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                if (showResetButton && onResetTap != null) _buildResetButton(cardSize),
                ...categories.map((category) => ProductCategoryCard(
                      category: category,
                      size: cardSize,
                      listTextHeight: listTextHeight,
                      isSelected: selectedCategoryId == category.guid_fixed,
                      onTap: () => onCategoryTap(category),
                      showCount: true,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(double size) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(2),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(8),
        shadowColor: Colors.blue.withOpacity(0.25),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onResetTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade400,
                  Colors.blue.shade600,
                ],
              ),
              border: Border.all(
                color: Colors.blue.shade300,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.restart_alt,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 2),
                Text(
                  'รีเซ็ต',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (10 * listTextHeight).clamp(8.0, 14.0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
