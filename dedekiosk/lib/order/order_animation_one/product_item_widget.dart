import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:dedekiosk/model/category_model.dart';
import 'package:dedekiosk/model/product_model.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/util/api.dart' as api;

// แยก ProductItemWidget ออกมาเป็น StatelessWidget แยกเพื่อเพิ่มประสิทธิภาพ
class ProductItemWidget extends StatelessWidget {
  final CategoryCodeListModel product;
  final Function(CategoryCodeListModel) onProductTap;
  final Function(int, int) onUpdateQty;
  final Function() onReloadProducts;
  final List<Shadow> textStyleWhiteShadow;

  const ProductItemWidget({
    Key? key,
    required this.product,
    required this.onProductTap,
    required this.onUpdateQty,
    required this.onReloadProducts,
    required this.textStyleWhiteShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int productIndex = global.findProductByBarcode(product.barcode);
    if (productIndex == -1) return const SizedBox.shrink();

    // Pre-calculate values to avoid repeated calculations
    final productData = global.productList[productIndex];
    final bool productIsReady = productData.issell && !(productData.isstockforrestaurant == true && productData.stockqty <= 0) && global.findProductPrice(prices: productData.prices) > 0;

    String kitchenPrinter = "";
    String kitchenPrinterName = "";
    if (global.deviceConfig.machineCondition == 0 && global.shopProfile!.kitchens != null) {
      for (var kitchen in global.shopProfile!.kitchens!) {
        if (kitchen.products.contains(productData.barcode)) {
          kitchenPrinter = kitchen.code;
          kitchenPrinterName = global.getNameFromLanguage(kitchen.names, global.languageForCustomer);
          break;
        }
      }
    }

    // ใช้ RepaintBoundary เพื่อแยกการ repaint
    return RepaintBoundary(
      child: _buildProductCard(context, productData, productIsReady, kitchenPrinter, kitchenPrinterName, productIndex),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductProcessModel productData, bool productIsReady, String kitchenPrinter, String kitchenPrinterName, int productIndex) {
    var productCard = Card(
      elevation: 1,
      margin: const EdgeInsets.all(6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: (global.orderType == 5 || global.orderType == 6)
            ? null
            : productIsReady
                ? () => onProductTap(product)
                : null,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildOptimizedProductImage(),
                ),
                _buildProductInfo(context, kitchenPrinter, kitchenPrinterName, productIndex),
              ],
            ),
            // Overlay for unavailable products
            if (!productIsReady) _buildUnavailableOverlay(context, productData),
            // Order quantity badge
            if (product.orderqty != null && product.orderqty! > 0) _buildOrderBadge(context),
            // Status overlay for orderType 5
            if (global.orderType == 5) _buildStatusOverlay(context, productIndex),
          ],
        ),
      ),
    );

    // กรณี global.orderType == 6 และเป็นสินค้าที่ใช้ระบบสต็อก
    if (global.orderType == 6 && productData.isstockforrestaurant == true) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: productCard),
          _buildStockManagementButtons(context, productIndex),
        ],
      );
    }

    return productCard;
  }

  Widget _buildOptimizedProductImage() {
    // กรณีไม่มี URL รูปภาพ
    if (product.imageurl.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 42, color: Colors.grey),
        ),
      );
    }

    // ปรับปรุงการโหลดรูปภาพเพื่อเพิ่มประสิทธิภาพ
    return CachedNetworkImage(
      imageUrl: product.imageurl,
      fit: BoxFit.fill,
      memCacheWidth: 200, // ลดขนาดเพื่อประหยัด memory
      memCacheHeight: 150,
      placeholderFadeInDuration: const Duration(milliseconds: 100),
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
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 42, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context, String kitchenPrinter, String kitchenPrinterName, int productIndex) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Center(
            child: Text(
              global.getNameFromLanguage(product.names, global.languageForCustomer),
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: textStyleWhiteShadow,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (product.discountword!.isNotEmpty && global.priceIndex == 1) _buildDiscountInfo(),
        _buildPriceInfo(),
        if (global.productList[productIndex].isstockforrestaurant == true) _buildStockInfo(productIndex),
        if (global.deviceConfig.machineCondition == 0) _buildKitchenInfo(kitchenPrinter, kitchenPrinterName),
        if (global.deviceConfig.machineCondition == 0) _buildFoodTypeInfo(productIndex),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildDiscountInfo() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: [
              TextSpan(
                text: "${global.language("from_price")} ",
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
              TextSpan(
                text: global.moneyFormat.format(product.setprice),
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: textStyleWhiteShadow,
                ),
              ),
              const TextSpan(text: " ", style: TextStyle(color: Colors.red, fontSize: 14)),
              TextSpan(
                text: global.language("money_baht"),
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
              const TextSpan(text: "/", style: TextStyle(color: Colors.red, fontSize: 14)),
              TextSpan(
                text: global.getNameFromLanguage(product.unitnames, global.languageForCustomer),
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            "${global.language("discount")} ${product.discountword}",
            style: const TextStyle(color: Colors.black, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(children: [
          if (product.discountword!.isNotEmpty && global.priceIndex == 1)
            TextSpan(
              text: "${global.language("after_discount")} ",
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
          TextSpan(
            text: global.moneyFormat.format(global.findProductPrice(prices: product.prices!)),
            style: TextStyle(
              color: Colors.blue,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              shadows: textStyleWhiteShadow,
            ),
          ),
          const TextSpan(text: " ", style: TextStyle(color: Colors.black, fontSize: 14)),
          TextSpan(
            text: global.language("money_baht"),
            style: const TextStyle(color: Colors.black, fontSize: 14),
          ),
          const TextSpan(text: "/", style: TextStyle(color: Colors.black, fontSize: 14)),
          TextSpan(
            text: global.getNameFromLanguage(product.unitnames, global.languageForCustomer),
            style: const TextStyle(color: Colors.black, fontSize: 14),
          ),
        ]),
      ),
    );
  }

  Widget _buildStockInfo(int productIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        "${global.language("qty_balance")} ${global.moneyFormat.format(global.productList[productIndex].stockqty)} ${global.getNameFromLanguage(global.productList[productIndex].unitnames, global.languageForCustomer)}",
        style: TextStyle(
          color: Colors.red,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: textStyleWhiteShadow,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildKitchenInfo(String kitchenPrinter, String kitchenPrinterName) {
    return kitchenPrinter.isEmpty
        ? const Icon(Icons.print_disabled, color: Colors.red)
        : Text(
            "$kitchenPrinterName : $kitchenPrinter",
            style: const TextStyle(color: Colors.black, fontSize: 10),
            textAlign: TextAlign.center,
          );
  }

  Widget _buildFoodTypeInfo(int productIndex) {
    return Text(
      (global.productList[productIndex].foodtype == 0) ? global.language("food") : global.language("beverage"),
      style: TextStyle(
        color: (global.productList[productIndex].foodtype == 0) ? Colors.green : Colors.blue,
        fontSize: 10,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildUnavailableOverlay(BuildContext context, ProductProcessModel productData) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.1),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              productData.issell ? global.language("out_of_stock") : global.language("pause_sale"),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderBadge(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: badges.Badge(
        badgeStyle: badges.BadgeStyle(
          badgeColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.all(8),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        badgeContent: Text(
          global.moneyFormat.format(product.orderqty),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusOverlay(BuildContext context, int productIndex) {
    return Positioned.fill(
      child: InkWell(
        onTap: () async {
          if (global.productList[productIndex].issell == true) {
            await api.clickHouseExecute("INSERT INTO ${global.clickHouseDatabaseName}.ordertempbarcodecancel (shopid,branchid,barcode) VALUES ('${global.deviceConfig.shopId}', '${global.deviceConfig.branchId}', '${global.productList[productIndex].barcode}')");
            global.productList[productIndex].issell = false;
          } else {
            await api.clickHouseExecute("alter table ${global.clickHouseDatabaseName}.ordertempbarcodecancel delete where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and barcode='${global.productList[productIndex].barcode}'");
            global.productList[productIndex].issell = true;
          }
          onReloadProducts();
        },
        child: (global.productList[productIndex].issell == false)
            ? Container()
            : Container(
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    global.language("is_open"),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: textStyleWhiteShadow,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStockManagementButtons(BuildContext context, int productIndex) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            await onUpdateQty(0, productIndex);
            await api.reloadProductProcessFromServer();
            onReloadProducts();
          },
          icon: const Icon(Icons.update),
          label: Column(
            children: [
              Text(global.language("change")),
              Text(global.language("qty_balance")),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            await onUpdateQty(1, productIndex);
            await api.reloadProductProcessFromServer();
            onReloadProducts();
          },
          icon: const Icon(Icons.add),
          label: Text(global.language("replenish_products")),
        ),
      ],
    );
  }
}
