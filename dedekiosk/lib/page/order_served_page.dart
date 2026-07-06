import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedekiosk/bloc/click_house_order_temp_served_bloc.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/model/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_listener/flutter_barcode_listener.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class OrderServedPage extends StatefulWidget {
  const OrderServedPage({super.key});

  @override
  OrderServedPageState createState() => OrderServedPageState();
}

class OrderServedPageState extends State<OrderServedPage> {
  late Timer refreshTimer;
  List<OrderTempDocModel> orderDocTemp = [];

  // Track loading state for each orderDetailGuid
  final Set<String> _loadingItems = {};

  // Cache for product lookup to improve performance
  final Map<String, ProductProcessModel?> _productCache = {};

  @override
  void reassemble() {
    super.reassemble();
  }

  @override
  void initState() {
    super.initState();
    reload();
    refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // Check mounted before reload to prevent memory leak
      if (mounted) {
        reload();
      }
    });
  }

  @override
  void dispose() {
    refreshTimer.cancel();
    _productCache.clear();
    _loadingItems.clear();
    super.dispose();
  }

  Future<void> reload() async {
    if (!mounted) return;
    context.read<ClickHouseOrderTempServedBloc>().add(ClickHouseOrderTempServedLoadStart());
  }

  // Cached product lookup
  ProductProcessModel? _getProductByBarcode(String barcode) {
    if (_productCache.containsKey(barcode)) {
      return _productCache[barcode];
    }
    var productIndex = global.findProductByBarcode(barcode);
    ProductProcessModel? product = productIndex != -1 ? global.productList[productIndex] : null;
    _productCache[barcode] = product;
    return product;
  }

  Widget orderByQueueWidget(BuildContext context, int index) {
    var orderDoc = orderDocTemp[index];
    String title = (orderDoc.order.salechannelcode.isEmpty) ? ((orderDoc.order.istakeaway == 0) ? "กินที่ร้าน" : "สั่งกลับบ้าน") : orderDoc.order.salechannelcode;
    if (orderDoc.order.ordertagnumber.isNotEmpty) {
      title += " โต๊ะ ${orderDoc.order.ordertagnumber}";
    }

    String orderDateTime = DateFormat('HH:mm').format(orderDoc.order.orderdatetime.add(const Duration(hours: 7)));
    String diffTime = global.diffTime(orderDoc.order.orderdatetime.add(const Duration(hours: 7)), DateTime.now().add(const Duration(hours: 7)));

    // Determine status
    String statusText;
    Color statusColor;
    IconData statusIcon;
    if (orderDoc.order.servedsuccess) {
      statusText = "เสร็จแล้ว";
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle;
    } else if (orderDoc.order.kitchensuccess) {
      statusText = "พร้อมเสิร์ฟ";
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.restaurant;
    } else {
      statusText = "กำลังประกอบ";
      statusColor = const Color(0xFF6366F1);
      statusIcon = Icons.access_time;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 220;
        final headerPadding = isSmall ? 10.0 : 16.0;
        final queuePaddingH = isSmall ? 10.0 : 14.0;
        final queuePaddingV = isSmall ? 6.0 : 8.0;
        final queueFontSize = isSmall ? 14.0 : 16.0;
        final titleFontSize = isSmall ? 13.0 : 15.0;
        final statusFontSize = isSmall ? 11.0 : 13.0;
        final timeFontSize = isSmall ? 11.0 : 13.0;
        final itemsPadding = isSmall ? 8.0 : 12.0;

        return Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: headerPadding, vertical: headerPadding - 2),
                decoration: BoxDecoration(
                  color: orderDoc.order.servedsuccess ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: queuePaddingH, vertical: queuePaddingV),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "#${orderDoc.order.queuenumber}",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: queueFontSize,
                            ),
                          ),
                        ),
                        SizedBox(width: isSmall ? 8 : 14),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: const Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                              fontSize: titleFontSize,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmall ? 8 : 12),
                    Wrap(
                      spacing: isSmall ? 6 : 10,
                      runSpacing: 6,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12, vertical: isSmall ? 4 : 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: isSmall ? 12 : 16, color: statusColor),
                              SizedBox(width: isSmall ? 4 : 6),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: statusFontSize,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "สั่ง $orderDateTime",
                              style: TextStyle(
                                fontSize: timeFontSize,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(width: isSmall ? 6 : 12),
                            Text(
                              "รอ $diffTime",
                              style: TextStyle(
                                fontSize: timeFontSize,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Order Items
              Padding(
                padding: EdgeInsets.all(itemsPadding),
                child: Column(
                  children: [
                    for (int orderDetailIndex = 0; orderDetailIndex < orderDoc.orderDetails.length; orderDetailIndex++) _buildOrderItemWidget(orderDoc, orderDetailIndex),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderItemWidget(OrderTempDocModel orderDoc, int orderDetailIndex) {
    var orderDetail = orderDoc.orderDetails[orderDetailIndex];
    String barcode = orderDetail.barcode;
    ProductProcessModel? product = _getProductByBarcode(barcode);

    // Handle case when product is not found
    if (product == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "ไม่พบสินค้า (Barcode: $barcode)",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }
    List<ProductProcessOptionModel> optionList = [];
    if (orderDetail.optionselected.isNotEmpty) {
      try {
        optionList = (jsonDecode(orderDetail.optionselected) as List).map((e) => ProductProcessOptionModel.fromJson(e)).toList();
      } catch (e) {
        // Handle JSON decode error gracefully
        debugPrint('Error decoding options: $e');
      }
    }

    bool isCancelled = orderDetail.isservedcancel == 1;
    bool isComplete = orderDetail.qty == orderDetail.iscooked;
    bool isServedComplete = orderDetail.isserved >= orderDetail.qty;

    Color itemBgColor;
    if (isCancelled) {
      itemBgColor = const Color(0xFFFEE2E2);
    } else if (isServedComplete) {
      itemBgColor = const Color(0xFFD1FAE5);
    } else if (isComplete) {
      itemBgColor = const Color(0xFFD1FAE5);
    } else {
      itemBgColor = const Color(0xFFF8FAFC);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: itemBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCancelled
              ? const Color(0xFFFCA5A5)
              : (isServedComplete || isComplete)
                  ? const Color(0xFF6EE7B7)
                  : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: product.imageuri,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) {
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.image_not_supported, color: Colors.grey.shade400),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCancelled)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          global.language("cancel"),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    Text(
                      global.getNameFromLanguage(product.names, global.languageForCustomer),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isCancelled ? const Color(0xFF9CA3AF) : const Color(0xFF1E293B),
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Options
                    for (int i = 0; i < optionList.length; i++)
                      for (int j = 0; j < optionList[i].choices.length; j++)
                        if (optionList[i].choices[j].selected)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF6366F1),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    global.getNameFromLanguage(optionList[i].choices[j].names, global.languageForCustomer),
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF6366F1)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    // Remark
                    if (orderDetail.remark.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.notes, size: 12, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                orderDetail.remark,
                                style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ), // Progress info - always show served count
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              children: [
                _buildProgressChip(
                  icon: Icons.restaurant,
                  label: "ปรุงแล้ว",
                  count: "${orderDetail.iscooked.toInt()}/${orderDetail.qty.toInt()}",
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(height: 8),
                _buildProgressChip(
                  icon: Icons.room_service,
                  label: "เสิร์ฟแล้ว",
                  count: "${orderDetail.isserved.toInt()}/${orderDetail.qty.toInt()}",
                  color: isServedComplete ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                ),
              ],
            ),
          ),
          // Serve Button - hide if already served complete
          if (!orderDoc.order.servedsuccess && !isCancelled && !isServedComplete)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _loadingItems.contains(orderDetail.orderguid)
                      ? null
                      : () async {
                          setState(() => _loadingItems.add(orderDetail.orderguid));
                          try {
                            await global.updateServedQty(orderDetailGuid: orderDetail.orderguid, reload: () {});
                            reload();
                          } finally {
                            if (mounted) setState(() => _loadingItems.remove(orderDetail.orderguid));
                          }
                        },
                  icon: _loadingItems.contains(orderDetail.orderguid)
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    _loadingItems.contains(orderDetail.orderguid) ? "กำลังบันทึก..." : global.language("served"),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressChip({required IconData icon, required String label, required String count, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              count,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClickHouseOrderTempServedBloc, ClickHouseOrderTempServedState>(
        listener: (orderTempContext, orderTempState) {
          if (orderTempState is ClickHouseOrderTempServedLoadSuccess) {
            context.read<ClickHouseOrderTempServedBloc>().add(ClickHouseOrderTempServedLoadFinish());
            orderDocTemp = orderTempState.clickHouseOrderTempServed;
            // Clear cache when data reloads to get fresh product info
            _productCache.clear();
            if (mounted) setState(() {});
          }
        },
        child: SafeArea(
            child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1E293B),
            title: Row(
              children: [
                const Icon(Icons.room_service, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Text(
                  global.language("รายการเสริฟท์"),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/order_select', (Route<dynamic> route) => false);
              },
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      "${orderDocTemp.length}",
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFF1F5F9),
          body: BarcodeKeyboardListener(
            bufferDuration: const Duration(milliseconds: 200),
            onBarcodeScanned: (barcode) async {
              await global.updateServedQty(orderDetailGuid: barcode, reload: () {});
              reload();
            },
            child: orderDocTemp.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "ไม่มีรายการค้าง",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "รายการทั้งหมดถูกเสิร์ฟเรียบร้อยแล้ว",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (BuildContext innerContext, BoxConstraints constraints) {
                      double parentWidgetWidth = constraints.maxWidth;
                      int columnCount;
                      // Responsive column count
                      if (parentWidgetWidth < 400) {
                        columnCount = 1; // Very small screens (phones)
                      } else if (parentWidgetWidth < 600) {
                        columnCount = 2; // Small tablets / large phones
                      } else if (parentWidgetWidth < 900) {
                        columnCount = 3; // Tablets
                      } else if (parentWidgetWidth < 1200) {
                        columnCount = 4; // Large tablets / small desktops
                      } else {
                        columnCount = 5; // Large screens
                      }
                      double widgetWidth = parentWidgetWidth / columnCount;
                      return RefreshIndicator(
                        onRefresh: () async {
                          reload();
                          // Wait a bit for the bloc to process
                          await Future.delayed(const Duration(milliseconds: 500));
                        },
                        color: const Color(0xFF6366F1),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Wrap(
                            children: [
                              for (int index = 0; index < orderDocTemp.length; index++)
                                SizedBox(
                                  width: widgetWidth,
                                  child: orderByQueueWidget(context, index),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        )));
  }
}
