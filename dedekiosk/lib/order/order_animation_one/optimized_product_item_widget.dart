import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dedekiosk/model/category_model.dart';
import 'package:dedekiosk/model/product_model.dart';
import 'package:dedekiosk/global.dart' as global;

/// Optimized Product Item Widget for high-performance grid view
///
/// Key optimizations:
/// - StatelessWidget with const constructor
/// - Pre-computed values passed from parent
/// - Minimal widget rebuilds
/// - Efficient image caching
/// - Reduced widget tree depth
class OptimizedProductItemWidget extends StatelessWidget {
  final CategoryCodeListModel product;
  final ProductProcessModel productData;
  final bool productIsReady;
  final String kitchenPrinterName;
  final VoidCallback onTap;
  final bool showStockInfo;
  final double stockQty;
  final String unitName;

  const OptimizedProductItemWidget({
    super.key,
    required this.product,
    required this.productData,
    required this.productIsReady,
    required this.kitchenPrinterName,
    required this.onTap,
    this.showStockInfo = false,
    this.stockQty = 0,
    this.unitName = '',
  });
  @override
  Widget build(BuildContext context) {
    final productName = global.getNameFromLanguage(productData.names, global.languageForCustomer);
    final productPrice = global.findProductPrice(prices: productData.prices);
    final hasImage = product.imageurl.isNotEmpty;

    // ราคาปกติ (keynumber = 1)
    double normalPrice = 0;
    for (var price in productData.prices) {
      if (price.keynumber == 1) {
        normalPrice = price.price;
        break;
      }
    } // เช็คว่าเป็นราคาสมาชิกและราคาต่างกัน
    final bool showOriginalPrice = global.priceIndex == 2 && normalPrice > 0 && normalPrice != productPrice;

    // สีอิฐบ้านเชียง color scheme
    const brickRed = Color(0xFFB85C38);
    const brickYellow = Color(0xFFD4A373);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(2),
          topRight: Radius.circular(2),
          bottomLeft: Radius.circular(3),
          bottomRight: Radius.circular(3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: productIsReady ? onTap : null,
        splashColor: brickYellow.withOpacity(0.3),
        highlightColor: brickRed.withOpacity(0.1),
        child: Stack(
          children: [
            // Product card content
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product image (65% when showStockInfo, else 70% - McDonald's style)
                Expanded(
                  flex: showStockInfo ? 65 : 70,
                  child: hasImage ? _buildProductImage(product.imageurl) : _buildNoImagePlaceholder(),
                ), // Product info (35% of card height when showStockInfo, else 30%)
                Expanded(
                  flex: showStockInfo ? 35 : 30,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Product name (smaller - McDonald's style)
                        // ลด maxLines เป็น 1 เมื่อแสดง stock info เพื่อให้มีพื้นที่พอ
                        Flexible(
                          flex: showStockInfo ? 1 : 2,
                          child: Text(
                            productName,
                            style: TextStyle(
                              fontSize: showStockInfo ? 13 : 15,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                            maxLines: showStockInfo ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Stock info (if enabled) - แสดงยอดสต็อกเป็นสีเขียวเข้ม
                        if (showStockInfo)
                          Padding(
                            padding: const EdgeInsets.only(top: 2, bottom: 2),
                            child: Text(
                              '${global.language("qty_balance")} ${global.moneyFormat.format(stockQty)} $unitName',
                              style: TextStyle(
                                color: brickRed,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        // Product price (prominent - McDonald's style)
                        // แสดงราคาปกติขีดฆ่าถ้าเป็นราคาสมาชิก (อยู่บรรทัดเดียวกัน)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '฿${global.moneyFormat.format(productPrice)}',
                              style: TextStyle(
                                fontSize: showStockInfo ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: brickRed,
                                height: 1.0,
                              ),
                            ),
                            if (showOriginalPrice) ...[
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '฿${global.moneyFormat.format(normalPrice)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Colors.grey,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ), // Kitchen printer badge (top-left) - สีอิฐอ่อน
            if (kitchenPrinterName.isNotEmpty)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: brickYellow,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    kitchenPrinterName,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Out of stock overlay
            if (!productIsReady)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        global.language("out_of_stock"),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      memCacheWidth: 300,
      memCacheHeight: 300,
      fadeInDuration: const Duration(milliseconds: 100),
      placeholder: (context, url) => Container(
        color: Colors.grey.shade100,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ),
        ),
      ),
      errorWidget: (context, error, stackTrace) => Container(
        color: Colors.grey.shade200,
        child: Icon(
          Icons.image_not_supported,
          size: 42,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image_not_supported,
        size: 42,
        color: Colors.grey.shade400,
      ),
    );
  }
}
