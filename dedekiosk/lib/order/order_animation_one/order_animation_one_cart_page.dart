import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedekiosk/bloc/click_house_order_temp_bloc.dart';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/model/product_model.dart';
import 'package:dedekiosk/objectbox/objectbox.g.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/order/order_animation_one/order_animation_one_util.dart';
import 'package:dedekiosk/order/order_save.dart';
import 'package:dedekiosk/order/pay_discount.dart';
import 'package:dedekiosk/order/widgets/payment_choice_dialog.dart';
import 'package:dedekiosk/util/point_calculation_helper.dart';
import 'package:dedekiosk/util/print_queue.dart';
import 'package:dedekiosk/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/util/api.dart' as api;
import 'package:badges/badges.dart' as badges;
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedekiosk/model/trans_model.dart';
import 'package:qr_flutter/qr_flutter.dart';

class OrderAnimationOneCartPage extends StatefulWidget {
  /// รหัสบาร์โค้ด โต๊ะ
  final String barcode;

  /// 0=จ่ายก่อนกิน,1=กินก่อนจ่าย,9=สรุปยอดกินก่อนจ่าย
  final int mode;

  const OrderAnimationOneCartPage({
    super.key,
    required this.barcode,
    required this.mode,
  });

  @override
  OrderAnimationOneCartPageState createState() =>
      OrderAnimationOneCartPageState();
}

class OrderAnimationOneCartPageState extends State<OrderAnimationOneCartPage>
    with TickerProviderStateMixin {
  double sumOrderAmount = 0;
  double sumOrderQty = 0;
  List<OrderTempDetailModel> orderTempDetailList = [];
  late ProductProcessModel product;
  late Timer screenTimer;
  String discountWord = "";
  double discountAmount = 0;
  double roundAmount = 0;
  double diffAmount = 0;
  double vatAmount = 0;
  double saveAmount = 0;
  BillCalcAmount bill = BillCalcAmount();
  bool _isSummaryExpanded = false; // State for summary visibility
  bool _isPaying =
      false; // ป้องกันกดปุ่มจ่ายซ้ำระหว่างที่ payAndSave กำลังทำงาน
  double pointsUsed = 0; // จำนวนแต้มที่ใช้
  double pointsDiscount = 0; // ส่วนลดจากแต้ม (pointusagetype = 1)
  double pointsPayment = 0; // ยอดชำระจากแต้ม (pointusagetype = 2)
  double earnedPoints = 0; // แต้มที่จะได้รับจากการซื้อ
  int pointUsageType = 1; // 1 = ส่วนลด, 2 = ชำระเงิน

  // Flash Animation
  late AnimationController _flashAnimationController;
  late Animation<double> _flashScaleAnimation;
  late Animation<double> _flashOpacityAnimation;
  late Animation<double> _flashPositionAnimation;
  bool _showFlash = false;
  double _flashQty = 0;
  double _flashAmount = 0;

  /// Get primary theme color from config
  Color get primaryThemeColor {
    return _hexToColor(global.deviceConfig.primaryThemeColor);
  }

  /// Convert hex string to Color
  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  void initState() {
    super.initState();

    // Initialize Flash Animation
    _flashAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Scale: 0.5 -> 1.0 (ขยายขึ้น) ในช่วงแรก
    _flashScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.1), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _flashAnimationController,
      curve: Curves.easeOut,
    ));

    // Opacity: 0 -> 1 -> 0 (แสดงแล้วจาง)
    _flashOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _flashAnimationController,
      curve: Curves.easeInOut,
    ));

    // Position: 0 -> 1 (จากกลางจอลงไปด้านล่าง)
    _flashPositionAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _flashAnimationController,
      curve: Curves.easeInOut,
    ));

    _flashAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showFlash = false;
        });
      }
    });

    if (widget.barcode.isNotEmpty) {
      product = global.productList[global.productList
          .indexWhere((element) => element.barcode == widget.barcode)];
    }
    reload();
    screenTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
    global.textToSpeech(global.findLanguage(
        code: "order_in_cart_detail",
        languageCode: global.languageForCustomer));
  }

  @override
  void dispose() {
    screenTimer.cancel();
    _flashAnimationController.dispose();
    super.dispose();
  }

  /// แสดง Flash Animation
  void _showFlashAnimation() {
    if (!mounted) return;
    setState(() {
      _flashQty = sumOrderQty;
      _flashAmount = bill.totalAmount;
      _showFlash = true;
    });
    _flashAnimationController.reset();
    _flashAnimationController.forward();
  }

  /// Widget สำหรับ Flash Animation Overlay
  Widget _buildFlashOverlay() {
    if (!_showFlash) return const SizedBox.shrink();

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return AnimatedBuilder(
      animation: _flashAnimationController,
      builder: (context, child) {
        // คำนวณตำแหน่ง Y จากกลางจอไปด้านล่าง
        final startY = screenHeight * 0.35;
        final endY = screenHeight * 0.7;
        final currentY =
            startY + (_flashPositionAnimation.value * (endY - startY));

        return Positioned(
          top: currentY,
          left: 0,
          right: 0,
          child: Center(
            child: Opacity(
              opacity: _flashOpacityAnimation.value,
              child: Transform.scale(
                scale: _flashScaleAnimation.value,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 32,
                    vertical: isMobile ? 16 : 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryThemeColor.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                    border: Border.all(
                      color: primaryThemeColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon และจำนวนรายการ
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryThemeColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shopping_cart,
                              color: primaryThemeColor,
                              size: isMobile ? 28 : 36,
                            ),
                          ),
                          SizedBox(width: isMobile ? 12 : 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_flashQty.toInt()} ${global.language("items")}',
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${global.moneyFormatAndDot.format(_flashAmount)} ฿',
                                style: TextStyle(
                                  fontSize: isMobile ? 28 : 36,
                                  fontWeight: FontWeight.bold,
                                  color: primaryThemeColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Widget แสดงข้อมูลสมาชิกและปุ่มใช้แต้ม หรือแสดงปุ่มเพิ่มสมาชิกถ้ายังไม่ได้ลงทะเบียน
  Widget _buildMemberInfoSection() {
    // ถ้าไม่ได้เปิดใช้ระบบสมาชิก ไม่แสดงอะไร
    if (!global.deviceConfig.useMember) return const SizedBox.shrink();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // ถ้ายังไม่เป็นสมาชิก แสดงกล่องเชิญชวนเพิ่มสมาชิก
    if (!global.isMember) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => _showAddMemberDialog(),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 14 : 16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: isMobile ? 48 : 54,
                    height: isMobile ? 48 : 54,
                    decoration: BoxDecoration(
                      color: primaryThemeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: isMobile ? 24 : 28,
                    ),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  // Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          global.language("add_friend_collect_points"),
                          style: TextStyle(
                            fontSize: isMobile ? 15 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          global.language("enter_member_pin"),
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                    size: isMobile ? 24 : 28,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } // ถ้าเป็นสมาชิกแล้ว แสดงข้อมูลสมาชิก
    // คำนวณส่วนลดจากราคาพิเศษ (เทียบราคาปกติกับราคาตาม priceIndex)
    // ✅ FIX: รองรับทุก priceIndex (ไม่ใช่แค่ 2)
    double memberPriceSaving = 0;
    if (global.priceIndex != 1) {
      for (var order in orderTempDetailList) {
        int productIndex =
            global.productList.indexWhere((p) => p.barcode == order.barcode);
        if (productIndex != -1) {
          var productData = global.productList[productIndex];
          // ราคาปกติ (keynumber = 1)
          double normalPrice = 0;
          for (var price in productData.prices) {
            if (price.keynumber == 1) {
              normalPrice = price.price;
              break;
            }
          }
          // ราคาสมาชิก
          double memberPrice =
              global.findProductPrice(prices: productData.prices);
          // คำนวณผลต่าง
          if (normalPrice > memberPrice) {
            memberPriceSaving += (normalPrice - memberPrice) * order.qty;
          }
        }
      }
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Member Info
          Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 16),
            child: Row(
              children: [
                // Profile Picture
                Container(
                  width: isMobile ? 48 : 54,
                  height: isMobile ? 48 : 54,
                  decoration: BoxDecoration(
                    color: primaryThemeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: global.memberPicture.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            global.memberPicture,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person_rounded,
                              color: primaryThemeColor,
                              size: isMobile ? 26 : 30,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person_rounded,
                          color: primaryThemeColor,
                          size: isMobile ? 26 : 30,
                        ),
                ),
                SizedBox(width: isMobile ? 12 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        global.memberName.isNotEmpty
                            ? global.memberName
                            : global.memberCode,
                        style: TextStyle(
                          fontSize: isMobile ? 15 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Points display และส่วนลดราคาสมาชิก
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                color: Colors.amber.shade600,
                                size: isMobile ? 16 : 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${global.moneyFormat.format(global.memberPointBalance)} ${global.language("points")}',
                                style: TextStyle(
                                  fontSize: isMobile ? 13 : 14,
                                  color: Colors.amber.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          // แสดงส่วนลดจากราคาสมาชิก
                          if (memberPriceSaving > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 6 : 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: Colors.red.shade200, width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_offer_rounded,
                                    color: Colors.red.shade600,
                                    size: isMobile ? 12 : 14,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${global.language("save")} ฿${global.moneyFormat.format(memberPriceSaving)}',
                                    style: TextStyle(
                                      fontSize: isMobile ? 11 : 12,
                                      color: Colors.red.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ), // ปุ่มใช้แต้ม / แก้ไข + ยกเลิก
                // if (global.memberPointBalance > 0 || pointsUsed > 0)
                //   Padding(
                //     padding: const EdgeInsets.only(right: 8),
                //     child: pointsUsed > 0
                //         // ถ้าใช้แต้มแล้ว: แสดงปุ่ม "แก้ไข" + "ยกเลิก"
                //         ? Row(
                //             mainAxisSize: MainAxisSize.min,
                //             children: [
                //               // ปุ่มแก้ไข
                //               Material(
                //                 color: Colors.blue.shade500,
                //                 borderRadius: BorderRadius.circular(8),
                //                 child: InkWell(
                //                   onTap: () => _showUsePointsDialog(),
                //                   borderRadius: BorderRadius.circular(8),
                //                   child: Padding(
                //                     padding: EdgeInsets.symmetric(
                //                       horizontal: isMobile ? 10 : 12,
                //                       vertical: isMobile ? 8 : 9,
                //                     ),
                //                     child: Row(
                //                       mainAxisSize: MainAxisSize.min,
                //                       children: [
                //                         Icon(
                //                           Icons.edit_rounded,
                //                           color: Colors.white,
                //                           size: isMobile ? 14 : 16,
                //                         ),
                //                         const SizedBox(width: 4),
                //                         Text(
                //                           global.language("edit"),
                //                           style: TextStyle(
                //                             fontSize: isMobile ? 12 : 13,
                //                             fontWeight: FontWeight.w600,
                //                             color: Colors.white,
                //                           ),
                //                         ),
                //                       ],
                //                     ),
                //                   ),
                //                 ),
                //               ),
                //               const SizedBox(width: 6),
                //               // ปุ่มยกเลิกใช้แต้ม
                //               Material(
                //                 color: Colors.red.shade500,
                //                 borderRadius: BorderRadius.circular(8),
                //                 child: InkWell(
                //                   onTap: () => _cancelUsePoints(),
                //                   borderRadius: BorderRadius.circular(8),
                //                   child: Padding(
                //                     padding: EdgeInsets.symmetric(
                //                       horizontal: isMobile ? 10 : 12,
                //                       vertical: isMobile ? 8 : 9,
                //                     ),
                //                     child: Row(
                //                       mainAxisSize: MainAxisSize.min,
                //                       children: [
                //                         Icon(
                //                           Icons.cancel_rounded,
                //                           color: Colors.white,
                //                           size: isMobile ? 14 : 16,
                //                         ),
                //                         const SizedBox(width: 4),
                //                         Text(
                //                           global.language("cancel"),
                //                           style: TextStyle(
                //                             fontSize: isMobile ? 12 : 13,
                //                             fontWeight: FontWeight.w600,
                //                             color: Colors.white,
                //                           ),
                //                         ),
                //                       ],
                //                     ),
                //                   ),
                //                 ),
                //               ),
                //             ],
                //           )
                //         // ถ้ายังไม่ได้ใช้แต้ม: แสดงปุ่ม "ใช้แต้ม"
                //         : Material(
                //             color: primaryThemeColor,
                //             borderRadius: BorderRadius.circular(10),
                //             child: InkWell(
                //               onTap: () => _showUsePointsDialog(),
                //               borderRadius: BorderRadius.circular(10),
                //               child: Padding(
                //                 padding: EdgeInsets.symmetric(
                //                   horizontal: isMobile ? 14 : 16,
                //                   vertical: isMobile ? 10 : 11,
                //                 ),
                //                 child: Row(
                //                   mainAxisSize: MainAxisSize.min,
                //                   children: [
                //                     Icon(
                //                       Icons.stars_rounded,
                //                       color: Colors.white,
                //                       size: isMobile ? 16 : 18,
                //                     ),
                //                     const SizedBox(width: 6),
                //                     Text(
                //                       global.language("use_points"),
                //                       style: TextStyle(
                //                         fontSize: isMobile ? 13 : 14,
                //                         fontWeight: FontWeight.w600,
                //                         color: Colors.white,
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //               ),
                //             ),
                //           ),
                //   ),
                // // ปุ่มลบสมาชิก
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => _removeMember(),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.grey.shade400,
                        size: isMobile ? 22 : 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // แสดงส่วนลดจากแต้ม ถ้ามี
          if (pointsUsed > 0)
            Container(
              margin: EdgeInsets.fromLTRB(
                isMobile ? 14 : 16,
                0,
                isMobile ? 14 : 16,
                isMobile ? 14 : 16,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 14,
                vertical: isMobile ? 10 : 12,
              ),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green.shade600,
                        size: isMobile ? 18 : 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${global.language("used_points")}: ${global.moneyFormat.format(pointsUsed)}',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '-${global.moneyFormat.format(pointsDiscount + pointsPayment)} ฿',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 15,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// คำนวณราคาใหม่ตาม priceIndex ปัจจุบัน และอัพเดทใน ObjectBox
  Future<void> _recalcPricesForPriceIndex() async {
    Logger.d(
        '_recalcPricesForPriceIndex: Start - priceIndex=${global.priceIndex}');

    if (widget.mode == 9) {
      // กินก่อนจ่าย - ไม่ต้องอัพเดท ObjectBox
      Logger.d('_recalcPricesForPriceIndex: Skip - mode 9 (กินก่อนจ่าย)');
      return;
    }

    // ดึงข้อมูลจาก ObjectBox
    var data = global.objectBoxStore
        .box<OrderTempObjectBoxModel>()
        .query(OrderTempObjectBoxModel_.istakeaway.equals(global.orderType))
        .build()
        .find();
    Logger.d(
        '_recalcPricesForPriceIndex: Found ${data.length} items in ObjectBox');

    int updatedCount = 0;
    for (var order in data) {
      // หา product ที่ตรงกับ barcode
      int productIndex =
          global.productList.indexWhere((p) => p.barcode == order.barcode);
      if (productIndex != -1) {
        var productData = global.productList[productIndex];
        // Log available prices for debugging
        String pricesInfo = productData.prices
            .map((p) => 'keynumber=${p.keynumber}:price=${p.price}')
            .join(', ');
        Logger.d(
            '_recalcPricesForPriceIndex: ${order.barcode} - available prices: [$pricesInfo]');
        // คำนวณราคาใหม่ตาม priceIndex ปัจจุบัน
        double newPrice = global.findProductPrice(prices: productData.prices);
        double newAmount = newPrice * order.qty + order.optionamount;

        // อัพเดทใน ObjectBox ถ้าราคาเปลี่ยน
        if (order.price != newPrice || order.amount != newAmount) {
          Logger.d(
              '_recalcPricesForPriceIndex: ${order.barcode} - oldPrice=${order.price}, newPrice=$newPrice, oldAmount=${order.amount}, newAmount=$newAmount');
          order.price = newPrice;
          order.amount = newAmount;
          global.objectBoxStore.box<OrderTempObjectBoxModel>().put(order);
          updatedCount++;
        }
      } else {
        Logger.d(
            '_recalcPricesForPriceIndex: Product not found for barcode ${order.barcode}');
      }
    }
    Logger.d(
        '_recalcPricesForPriceIndex: Completed - updated $updatedCount items');
  }

  /// ลบข้อมูลสมาชิก
  void _removeMember() async {
    // Reset member data
    global.isMember = false;
    global.memberCode = "";
    global.memberName = "";
    global.memberEmail = "";
    global.memberPicture = "";
    global.memberPinCode = "";
    global.memberPointBalance = 0;
    global.memberPointsCode = "";
    global.memberGuidFixed = "";
    global.memberPriceLevel = 1;
    global.lineDestination = "";
    global.priceIndex = 1;

    // Reset points used
    pointsUsed = 0;
    pointsDiscount = 0;
    pointsPayment = 0;
    earnedPoints = 0;

    // Update global point data
    _updateGlobalPointData();

    // คำนวณราคาใหม่ตาม priceIndex และอัพเดทใน ObjectBox
    await _recalcPricesForPriceIndex();

    // Reload และ recalc
    reload();
  }

  /// เลือกแสดง Dialog สมาชิกตามประเภท (BC Member หรือ PIN)
  void _showAddMemberDialog() {
    if (global.shopProfile?.isbcmember == true) {
      // BC Member - แสดง code รอยืนยัน
      _showBCMemberDialog();
    } else {
      // แบบเดิม - กรอก PIN
      _showMemberPinDialog();
    }
  }

  /// แสดง Dialog สำหรับ BC Member (แสดง QR Code สำหรับสแกนผ่าน LINE LIFF)
  Future<void> _showBCMemberDialog() async {
    String sessionId = '';
    String liffUrl = '';
    String status = 'loading'; // loading, pending, success, expired, error
    String errorMessage = '';
    DateTime? expiresAt;
    Timer? statusCheckTimer;
    Timer? countdownTimer; // Timer สำหรับ update UI ทุก 1 วินาที
    bool isRequestingSession = false; // ป้องกันการเรียก API ซ้ำ

    // ฟังก์ชันขอ QR Session ใหม่
    Future<void> requestNewSession(StateSetter setDialogState) async {
      if (isRequestingSession) return; // ป้องกันการเรียกซ้ำ
      isRequestingSession = true;

      setDialogState(() {
        status = 'loading';
        errorMessage = '';
      });

      try {
        final response =
            await api.getBCMemberQRSession(global.deviceConfig.shopId);

        if (response['session_id'] != null && response['liff_url'] != null) {
          setDialogState(() {
            sessionId = response['session_id'].toString();
            liffUrl = response['liff_url'].toString();
            status = 'pending';
            // ตั้งเวลาหมดอายุจาก API หรือ default 5 นาที
            if (response['expires_at'] != null) {
              // expires_at เป็น Unix timestamp (seconds since epoch)
              final expiresAtRaw = response['expires_at'];
              if (expiresAtRaw is int) {
                expiresAt =
                    DateTime.fromMillisecondsSinceEpoch(expiresAtRaw * 1000);
              } else if (expiresAtRaw is double) {
                expiresAt = DateTime.fromMillisecondsSinceEpoch(
                    (expiresAtRaw * 1000).toInt());
              } else {
                // ลองแปลงเป็น int ก่อน ถ้าไม่ได้ให้ลอง parse เป็น DateTime string
                final parsed = int.tryParse(expiresAtRaw.toString());
                if (parsed != null) {
                  expiresAt =
                      DateTime.fromMillisecondsSinceEpoch(parsed * 1000);
                } else {
                  expiresAt = DateTime.tryParse(expiresAtRaw.toString()) ??
                      DateTime.now().add(const Duration(minutes: 5));
                }
              }
            } else {
              expiresAt = DateTime.now().add(const Duration(minutes: 5));
            }
          });

          // เริ่ม countdown timer สำหรับ update UI ทุก 1 วินาที
          countdownTimer?.cancel();
          countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (status != 'pending') {
              timer.cancel();
              return;
            }
            setDialogState(() {}); // trigger UI rebuild
          });

          // เริ่ม timer เช็ค status ทุก 3 วินาที
          statusCheckTimer?.cancel();
          statusCheckTimer =
              Timer.periodic(const Duration(seconds: 3), (timer) async {
            if (status != 'pending') {
              timer.cancel();
              return;
            }

            // เช็คว่าหมดเวลาหรือยัง
            if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) {
              timer.cancel();
              countdownTimer?.cancel();
              setDialogState(() {
                status = 'expired';
              });
              return;
            }

            try {
              final statusResponse =
                  await api.getBCMemberLoginStatus(sessionId);
              if (statusResponse['status'] == 'success') {
                timer.cancel();
                countdownTimer?.cancel();

                // Set member data
                global.isMember = true;
                global.memberCode = statusResponse['line_user_id'] ?? '';
                global.memberName = statusResponse['display_name'] ?? '';
                global.memberPicture = statusResponse['picture_url'] ?? '';
                global.priceIndex = 1;

                // ✅ BC Member: เก็บ line_user_id สำหรับส่ง Sale Invoice
                global.memberPinCode = statusResponse['line_user_id'] ?? '';

                // BC Member: ใช้ข้อมูลจาก API โดยตรง ไม่ต้องดึง debtor
                Logger.d(
                    'BCMemberDialog: Using data from BC Member API directly (skip getDebtorByLine)');

                // ดึง point_balance จาก BC Member API
                var bcPointBalanceRaw = statusResponse['point_balance'];
                double bcPointBalance = 0;
                if (bcPointBalanceRaw is double) {
                  bcPointBalance = bcPointBalanceRaw;
                } else if (bcPointBalanceRaw is int) {
                  bcPointBalance = bcPointBalanceRaw.toDouble();
                } else if (bcPointBalanceRaw != null) {
                  bcPointBalance =
                      double.tryParse(bcPointBalanceRaw.toString()) ?? 0;
                }

                // ตั้งค่า default สำหรับ BC Member
                global.custNames = [
                  TransNameInfoModel(
                      name: global.memberName,
                      code: "th",
                      isauto: false,
                      isdelete: false),
                  TransNameInfoModel(
                      name: global.memberName,
                      code: "en",
                      isauto: false,
                      isdelete: false),
                ];
                global.memberPriceLevel = 1;
                global.priceIndex = 1;
                global.memberPointBalance = bcPointBalance;

                Logger.d(
                    'BCMemberDialog: point_balance from API = $bcPointBalance');

                setDialogState(() {
                  status = 'success';
                });

                Logger.d(
                    'BCMemberDialog: Member linked - ${global.memberName}');
              }
            } catch (e) {
              Logger.e('BCMemberDialog: Error checking status', error: e);
            }
          });
        } else {
          setDialogState(() {
            status = 'error';
            errorMessage = 'ไม่สามารถสร้าง QR Code ได้';
          });
        }
      } catch (e) {
        Logger.e('BCMemberDialog: Error requesting QR session', error: e);
        setDialogState(() {
          status = 'error';
          errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
        });
      } finally {
        isRequestingSession = false;
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // ขอ QR Session เมื่อเปิด dialog ครั้งแรก
            if (status == 'loading' && sessionId.isEmpty) {
              Future.microtask(() => requestNewSession(setDialogState));
            }

            // คำนวณเวลาที่เหลือ
            String remainingTime = '';
            if (status == 'pending' && expiresAt != null) {
              final remaining = expiresAt!.difference(DateTime.now());
              if (remaining.isNegative) {
                Future.microtask(() {
                  setDialogState(() {
                    status = 'expired';
                  });
                });
              } else {
                final minutes = remaining.inMinutes;
                final seconds = remaining.inSeconds % 60;
                remainingTime =
                    '$minutes:${seconds.toString().padLeft(2, '0')}';
              }
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;
                final isSmallScreen = screenWidth < 600;

                final dialogWidth = isSmallScreen ? screenWidth * 0.9 : 450.0;
                final logoSize = isSmallScreen ? 70.0 : 100.0;
                final titleFontSize = isSmallScreen ? 18.0 : 22.0;
                final qrSize = isSmallScreen ? 200.0 : 250.0;
                final padding = isSmallScreen ? 16.0 : 24.0;

                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: dialogWidth,
                    constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header with close button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    statusCheckTimer?.cancel();
                                    countdownTimer?.cancel();
                                    Navigator.of(dialogContext).pop();
                                  },
                                  icon: const Icon(Icons.close),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),

                            // // LINE OA Logo
                            // Container(
                            //   width: logoSize,
                            //   height: logoSize,
                            //   decoration: BoxDecoration(
                            //     color: const Color(0xFF06C755),
                            //     borderRadius: BorderRadius.circular(logoSize * 0.2),
                            //   ),
                            //   child: ClipRRect(
                            //     borderRadius: BorderRadius.circular(logoSize * 0.2),
                            //     child: (global.shopProfile?.orderstation.lineoaimg ?? '').isNotEmpty
                            //         ? CachedNetworkImage(
                            //             imageUrl: global.shopProfile!.orderstation.lineoaimg,
                            //             fit: BoxFit.cover,
                            //             placeholder: (context, url) => const Center(
                            //               child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            //             ),
                            //             errorWidget: (context, url, error) => Center(
                            //               child: Text('LINE', style: TextStyle(color: Colors.white, fontSize: logoSize * 0.16, fontWeight: FontWeight.bold)),
                            //             ),
                            //           )
                            //         : Center(
                            //             child: Text('LINE', style: TextStyle(color: Colors.white, fontSize: logoSize * 0.16, fontWeight: FontWeight.bold)),
                            //           ),
                            //   ),
                            // ),
                            // SizedBox(height: isSmallScreen ? 12 : 16),

                            // Title
                            Text(
                              global.language("add_friend_collect_points"),
                              style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),

                            // Content based on status
                            if (status == 'loading') ...[
                              const SizedBox(height: 40),
                              CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      primaryThemeColor)),
                              const SizedBox(height: 16),
                              Text('กำลังสร้าง QR Code...',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 40),
                            ] else if (status == 'pending') ...[
                              Text(
                                'สแกน QR Code ด้วยแอป LINE',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 20),

                              // QR Code display
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: primaryThemeColor.withAlpha(100),
                                      width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: QrImageView(
                                  data: liffUrl,
                                  version: QrVersions.auto,
                                  size: qrSize,
                                  backgroundColor: Colors.white,
                                  errorStateBuilder: (cxt, err) {
                                    return Center(
                                      child: Text(
                                        'ไม่สามารถสร้าง QR Code ได้',
                                        style: TextStyle(
                                            color: Colors.red.shade600),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Waiting indicator
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.grey.shade400),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'รอการสแกน... (หมดอายุใน $remainingTime)',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ] else if (status == 'success') ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.check,
                                    color: Colors.green.shade600, size: 48),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                global.language("welcome_member"),
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                global.memberName,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () async {
                                  statusCheckTimer?.cancel();
                                  Navigator.of(dialogContext).pop();

                                  // คำนวณราคาใหม่
                                  await _recalcPricesForPriceIndex();

                                  // แสดง welcome dialog
                                  _showMemberWelcomeDialogSimple();

                                  // Reload
                                  reload();
                                  setState(() {});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryThemeColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('ตกลง'),
                              ),
                              const SizedBox(height: 20),
                            ] else if (status == 'expired') ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.timer_off,
                                    color: Colors.orange.shade600, size: 48),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'QR Code หมดอายุ',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'กรุณาสร้าง QR Code ใหม่',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    requestNewSession(setDialogState),
                                icon: const Icon(Icons.refresh),
                                label: const Text('สร้าง QR ใหม่'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryThemeColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ] else if (status == 'error') ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.error_outline,
                                    color: Colors.red.shade600, size: 48),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'เกิดข้อผิดพลาด',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                errorMessage,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey.shade600),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    requestNewSession(setDialogState),
                                icon: const Icon(Icons.refresh),
                                label: const Text('ลองใหม่'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryThemeColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    ).then((_) {
      statusCheckTimer?.cancel();
    });
  }

  /// Dialog สำหรับแสดง PIN สมาชิก (Shop-initiated PIN)
  /// Flow: ร้านขอ PIN → แสดง PIN ให้ลูกค้ากรอกใน LINE → Polling เช็คสถานะ
  Future<void> _showMemberPinDialog() async {
    String generatedPin = '';
    String status = 'loading'; // loading, pending, success, expired, error
    String errorMessage = '';
    Timer? statusCheckTimer;
    Timer? countdownTimer;
    int remainingSeconds = 0;
    bool isRequestingPin = false;

    // ฟังก์ชันประมวลผลข้อมูลสมาชิก (ประกาศก่อนใช้)
    Future<void> processMemberData(Map<String, dynamic> customerData,
        String pinCode, StateSetter setDialogState) async {
      setDialogState(() {
        status = 'success';
      });

      // Set member data to global
      global.isMember = true;
      global.memberCode = "";
      global.lineDestination = customerData["destination"] ?? "";
      global.memberName = customerData["displayName"] ?? "";
      global.memberEmail = customerData["email"] ?? "";
      global.memberPicture = customerData["pictureUrl"] ?? "";
      global.memberPinCode = pinCode;
      global.priceIndex = 1;

      String lineUserId = customerData["userId"] ?? "";

      // Get or create debtor
      var memberData = await api.getDebtorByLine(code: lineUserId);
      Logger.d(
          'MemberPinDialog: getDebtorByLine response: success=${memberData.success}, error=${memberData.error}, message=${memberData.message}, data=${memberData.data}');

      String messageStr = (memberData.message ?? "").toString().toLowerCase();
      bool isDocumentNotFound = messageStr.contains("document not found") ||
          messageStr.contains("not found");

      if (!memberData.success) {
        Logger.d(
            'MemberPinDialog: Creating new debtor (success=false, isDocumentNotFound=$isDocumentNotFound)');
        global.custNames = [
          TransNameInfoModel(
              name: global.memberName,
              code: "th",
              isauto: false,
              isdelete: false),
          TransNameInfoModel(
              name: global.memberName,
              code: "en",
              isauto: false,
              isdelete: false),
        ];
        try {
          await api.createDebtor(
            code: lineUserId,
            name: global.memberName,
            email: global.memberEmail,
            img: global.memberPicture,
          );
          Logger.d('MemberPinDialog: Debtor created successfully');
        } catch (e) {
          Logger.e('MemberPinDialog: Failed to create debtor', error: e);
        }
        global.memberPriceLevel = 1;
        global.priceIndex = 1;
      } else {
        Logger.d('MemberPinDialog: Using existing debtor data');
        global.memberCode = memberData.data["code"] ?? "";
        String pointsCode = (memberData.data["pointscode"] ?? "").toString();
        global.memberPointsCode = pointsCode.isNotEmpty
            ? pointsCode
            : (memberData.data["code"] ?? "").toString();
        var priceLevelRaw = memberData.data["pricelevel"];
        global.memberPriceLevel = (priceLevelRaw is int)
            ? priceLevelRaw
            : int.tryParse(priceLevelRaw?.toString() ?? "2") ?? 2;
        if (global.memberPriceLevel == 1) {
          global.memberPriceLevel = 1;
        }
        global.memberGuidFixed =
            (memberData.data["guidfixed"] ?? "").toString();
        var pointBalanceRaw = memberData.data["pointbalance"];
        if (pointBalanceRaw is double) {
          global.memberPointBalance = pointBalanceRaw;
        } else if (pointBalanceRaw is int) {
          global.memberPointBalance = pointBalanceRaw.toDouble();
        } else {
          global.memberPointBalance =
              double.tryParse(pointBalanceRaw?.toString() ?? "0") ?? 0;
        }
        global.priceIndex = global.memberPriceLevel;
        List<TransNameInfoModel> names = (memberData.data["names"] as List?)
                ?.map((data) => TransNameInfoModel.fromJson(data))
                .toList() ??
            global.custNames;
        global.custNames = names;
      }

      Logger.d(
          'MemberPinDialog: Final priceIndex=${global.priceIndex}, memberPriceLevel=${global.memberPriceLevel}');

      // Delay เล็กน้อยเพื่อให้เห็น success state
      await Future.delayed(const Duration(milliseconds: 800));

      // ปิด dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // คำนวณราคาใหม่
      await _recalcPricesForPriceIndex();
      reload();

      // แสดง welcome dialog
      if (mounted) {
        _showMemberWelcomeDialogSimple();
      }
      Logger.d(
          'MemberPinDialog: Member linked successfully - ${global.memberName}');
    }

    // ฟังก์ชันขอ PIN ใหม่
    Future<void> requestNewPin(StateSetter setDialogState) async {
      if (isRequestingPin) return;
      isRequestingPin = true;

      setDialogState(() {
        status = 'loading';
        errorMessage = '';
      });

      try {
        var result = await api.shopRequestMemberPin(global.deviceConfig.shopId);
        Logger.d('shopRequestMemberPin result: $result');

        if (result['success'] == true && result['data'] != null) {
          generatedPin = result['data']['pin'] ?? '';
          remainingSeconds = result['data']['expiresIn'] ?? 300;

          setDialogState(() {
            status = 'pending';
          });

          // เริ่ม countdown timer
          countdownTimer?.cancel();
          countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (remainingSeconds > 0) {
              remainingSeconds--;
              setDialogState(() {});
            } else {
              timer.cancel();
              statusCheckTimer?.cancel();
              setDialogState(() {
                status = 'expired';
              });
            }
          });

          // เริ่ม polling เช็คสถานะทุก 3 วินาที
          statusCheckTimer?.cancel();
          statusCheckTimer =
              Timer.periodic(const Duration(seconds: 3), (timer) async {
            if (status != 'pending') {
              timer.cancel();
              return;
            }

            try {
              var statusResult = await api.shopCheckMemberPinStatus(
                  generatedPin, global.deviceConfig.shopId);
              Logger.d('shopCheckMemberPinStatus result: $statusResult');

              if (statusResult['success'] == true &&
                  statusResult['data'] != null) {
                String pinStatus = statusResult['data']['status'] ?? '';

                if (pinStatus == 'success') {
                  timer.cancel();
                  countdownTimer?.cancel();

                  // ดึงข้อมูลลูกค้า
                  var customerData = statusResult['data']['customer'];
                  if (customerData != null) {
                    await processMemberData(
                        customerData, generatedPin, setDialogState);
                  }
                }
              } else if (statusResult['success'] == false) {
                // PIN หมดอายุหรือไม่พบ
                String error = statusResult['error'] ?? '';
                if (error.contains('expired') || error.contains('not found')) {
                  timer.cancel();
                  countdownTimer?.cancel();
                  setDialogState(() {
                    status = 'expired';
                  });
                }
              }
            } catch (e) {
              Logger.e('Error polling PIN status', error: e);
            }
          });
        } else {
          setDialogState(() {
            status = 'error';
            errorMessage = result['error'] ??
                global.language("error_occurred_please_try_again");
          });
        }
      } catch (e) {
        Logger.e('requestNewPin error', error: e);
        setDialogState(() {
          status = 'error';
          errorMessage = global.language("error_occurred_please_try_again");
        });
      } finally {
        isRequestingPin = false;
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // ขอ PIN เมื่อเปิด dialog ครั้งแรก
            if (status == 'loading' &&
                generatedPin.isEmpty &&
                !isRequestingPin) {
              Future.microtask(() => requestNewPin(setDialogState));
            }

            final screenWidth = MediaQuery.of(context).size.width;
            final isMobile = screenWidth < 600;
            final pinBoxSize = isMobile ? 52.0 : 60.0;
            final lineOaImg = global.shopProfile?.orderstation.lineoaimg ?? "";

            // Format remaining time
            String formatTime(int seconds) {
              int mins = seconds ~/ 60;
              int secs = seconds % 60;
              return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              titlePadding: EdgeInsets.zero,
              contentPadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        global.language("add_friend_collect_points"),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 17 : 19,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        statusCheckTimer?.cancel();
                        countdownTimer?.cancel();
                        Navigator.pop(dialogContext);
                      },
                      icon: Icon(Icons.close,
                          color: Colors.grey.shade400, size: 22),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              content: Container(
                width: isMobile ? 320 : 360,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // LINE OA QR Image
                    if (lineOaImg.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              global.language("add_friend"),
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                lineOaImg,
                                width: isMobile ? 100 : 120,
                                height: isMobile ? 100 : 120,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: isMobile ? 100 : 120,
                                  height: isMobile ? 100 : 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.qr_code_2,
                                      size: 50, color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Content based on status
                    if (status == 'loading') ...[
                      const SizedBox(height: 20),
                      CircularProgressIndicator(color: primaryThemeColor),
                      const SizedBox(height: 16),
                      Text(
                        global.language("loading"),
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else if (status == 'pending') ...[
                      // PIN Label
                      Text(
                        global.language("enter_pin_in_line"),
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // PIN Display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: generatedPin.split('').map((digit) {
                          return Container(
                            width: pinBoxSize,
                            height: pinBoxSize,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: primaryThemeColor.withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryThemeColor.withAlpha(100),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                digit,
                                style: TextStyle(
                                  fontSize: pinBoxSize * 0.5,
                                  fontWeight: FontWeight.bold,
                                  color: primaryThemeColor,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // Countdown Timer
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: remainingSeconds <= 60
                              ? Colors.red.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 18,
                              color: remainingSeconds <= 60
                                  ? Colors.red.shade600
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${global.language("expires_in")} ${formatTime(remainingSeconds)}',
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                fontWeight: FontWeight.w500,
                                color: remainingSeconds <= 60
                                    ? Colors.red.shade600
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Waiting indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            global.language("waiting_for_confirmation"),
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Refresh PIN button
                      TextButton.icon(
                        onPressed: () => requestNewPin(setDialogState),
                        icon: Icon(Icons.refresh,
                            size: 18, color: primaryThemeColor),
                        label: Text(
                          global.language("request_new_pin"),
                          style: TextStyle(color: primaryThemeColor),
                        ),
                      ),
                    ] else if (status == 'success') ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: 48,
                          color: Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        global.language("verification_successful"),
                        style: TextStyle(
                          fontSize: isMobile ? 15 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else if (status == 'expired') ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.timer_off,
                          size: 48,
                          color: Colors.orange.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        global.language("pin_expired"),
                        style: TextStyle(
                          fontSize: isMobile ? 15 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => requestNewPin(setDialogState),
                        icon: const Icon(Icons.refresh),
                        label: Text(global.language("request_new_pin")),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryThemeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ] else if (status == 'error') ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage.isNotEmpty
                            ? errorMessage
                            : global
                                .language("error_occurred_please_try_again"),
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: Colors.red.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => requestNewPin(setDialogState),
                        icon: const Icon(Icons.refresh),
                        label: Text(global.language("try_again")),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryThemeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      statusCheckTimer?.cancel();
      countdownTimer?.cancel();
    });
  }

  /// แสดง Dialog ต้อนรับสมาชิก (แบบง่าย)
  void _showMemberWelcomeDialogSimple() {
    if (!mounted) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        // Auto close after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });

        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile picture
                if (global.memberPicture.isNotEmpty)
                  CircleAvatar(
                    radius: isMobile ? 40 : 50,
                    backgroundImage: NetworkImage(global.memberPicture),
                    onBackgroundImageError: (_, __) {},
                  )
                else
                  CircleAvatar(
                    radius: isMobile ? 40 : 50,
                    backgroundColor: Colors.amber.shade100,
                    child: Icon(Icons.person,
                        size: isMobile ? 40 : 50, color: Colors.amber.shade800),
                  ),
                const SizedBox(height: 16),
                // Welcome text
                Text(
                  '${global.language("welcome")}!',
                  style: TextStyle(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
                const SizedBox(height: 8),
                // Member name
                Text(
                  global.memberName,
                  style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Points info
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${global.language("point_balance")}: ${global.moneyFormat.format(global.memberPointBalance)}',
                        style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Check icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.green.shade100, shape: BoxShape.circle),
                  child: Icon(Icons.check,
                      color: Colors.green.shade800, size: isMobile ? 28 : 32),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// อัพเดทตัวแปร global สำหรับข้อมูลแต้มสะสม
  void _updateGlobalPointData() {
    global.usePoint = pointsUsed;
    global.getPoint = earnedPoints;
    global.pointDiscountAmount = pointsDiscount;
    global.pointAmount = pointsPayment;
    // คำนวณแต้มคงเหลือ: (แต้มเดิม - แต้มที่ใช้) + แต้มที่ได้รับ
    global.currentPointBalance =
        (global.memberPointBalance - pointsUsed) + earnedPoints;
    if (global.currentPointBalance < 0) global.currentPointBalance = 0;
  }

  /// ยกเลิกการใช้แต้ม
  void _cancelUsePoints() {
    setState(() {
      global.countDownForHome = global.countDownForHomeMax;
      pointsUsed = 0;
      pointsDiscount = 0;
      pointsPayment = 0;
      _updateGlobalPointData();
      recalc();
    });
    // BC Member: ดึง get_point จาก API
    if (global.shopProfile?.isbcmember == true) {
      _fetchBCMemberPoints();
    }
    Logger.i('_cancelUsePoints: Points usage cancelled');
  }

  /// Dialog สำหรับใส่จำนวนแต้มที่ต้องการใช้ (ใช้ numpad)
  void _showUsePointsDialog() {
    String inputValue = pointsUsed > 0 ? pointsUsed.toInt().toString() : '';
    global.countDownForHome = global.countDownForHomeMax;
    // Max dialog width constraint
    const maxDialogWidth = 500.0;

    // ดึง pointconfig จาก shopProfile
    final pointConfig = global.shopProfile?.orderstation.branch.pointconfig;

    // รับ pointUsageType จาก config
    final configPointUsageType =
        PointCalculationHelper.getPointUsageType(pointConfig);

    // คำนวณยอดก่อนหักส่วนลดแต้ม
    double originalTotalAmount =
        bill.totalAmount + pointsDiscount + pointsPayment;

    // คำนวณแต้มสูงสุดที่ใช้ได้ ตาม pointconfig
    double maxPointsCanUse = PointCalculationHelper.calculateMaxUsablePoints(
      pointBalance: global.memberPointBalance,
      totalAmount: originalTotalAmount,
      pointConfig: pointConfig,
    );

    // รับข้อความอธิบายการใช้แต้ม
    String pointUsageDesc =
        PointCalculationHelper.getPointUsageDescription(pointConfig);
    if (pointUsageDesc.isEmpty) {
      pointUsageDesc = '1 ${global.language("points")} = 1 ฿';
    }

    // เพิ่มข้อความอธิบายประเภทการใช้แต้ม
    String usageTypeDesc =
        configPointUsageType == 1 ? '(ใช้เป็นส่วนลด)' : '(ใช้เป็นการชำระเงิน)';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        String errorMessage = '';
        PointCalculationResult previewResult = PointCalculationResult.empty();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Recalculate responsive values inside builder for orientation changes
            final currentScreenWidth = MediaQuery.of(context).size.width;
            final currentScreenHeight = MediaQuery.of(context).size.height;
            final currentIsMobile = currentScreenWidth < 600;
            final currentIsTablet =
                currentScreenWidth >= 600 && currentScreenWidth < 900;

            // Responsive sizes
            final responsiveDialogWidth = currentIsMobile
                ? currentScreenWidth * 0.92
                : currentIsTablet
                    ? currentScreenWidth * 0.6
                    : currentScreenWidth * 0.45;
            final constrainedWidth = responsiveDialogWidth > maxDialogWidth
                ? maxDialogWidth
                : responsiveDialogWidth;

            // Responsive button size based on available width
            final availableWidth = constrainedWidth - 40; // padding
            final buttonSize = currentIsMobile
                ? (availableWidth / 5).clamp(44.0, 56.0)
                : (availableWidth / 5).clamp(52.0, 68.0);

            // Responsive font sizes
            final headerFontSize =
                currentIsMobile ? 18.0 : (currentIsTablet ? 20.0 : 22.0);
            final displayFontSize =
                currentIsMobile ? 32.0 : (currentIsTablet ? 40.0 : 48.0);
            final labelFontSize = currentIsMobile ? 11.0 : 13.0;
            final valueFontSize =
                currentIsMobile ? 16.0 : (currentIsTablet ? 24.0 : 34.0);
            final smallFontSize = currentIsMobile ? 11.0 : 14.0;

            // Responsive padding
            final dialogPadding = currentIsMobile ? 14.0 : 20.0;
            final sectionSpacing = currentIsMobile ? 12.0 : 16.0;

            // คำนวณผลลัพธ์ตัวอย่างเมื่อกรอกแต้ม
            double inputPoints = double.tryParse(inputValue) ?? 0;
            previewResult = PointCalculationHelper.calculatePointTransaction(
              pointsToUse: inputPoints,
              totalAmount: originalTotalAmount,
              pointBalance: global.memberPointBalance,
              pointConfig: pointConfig,
            );

            // ตรวจสอบ error
            if (inputPoints > maxPointsCanUse) {
              errorMessage =
                  'สูงสุด ${global.moneyFormat.format(maxPointsCanUse)} แต้ม';
            } else {
              errorMessage = '';
            }

            // Numpad functions
            void addDigit(String digit) {
              if (inputValue.length < 10) {
                setDialogState(() {
                  inputValue = inputValue + digit;
                });
              }
            }

            void removeDigit() {
              if (inputValue.isNotEmpty) {
                setDialogState(() {
                  inputValue = inputValue.substring(0, inputValue.length - 1);
                });
              }
            }

            void clearInput() {
              setDialogState(() {
                inputValue = '';
              });
            }

            void useMaxPoints() {
              setDialogState(() {
                inputValue = maxPointsCanUse.toInt().toString();
              });
            }

            void confirmPoints() {
              double pts = double.tryParse(inputValue) ?? 0;
              if (pts > maxPointsCanUse) {
                setDialogState(() {
                  errorMessage = global.language("not_enough_points");
                });
                return;
              }
              // คำนวณผลลัพธ์แต้มตาม pointconfig
              final result = PointCalculationHelper.calculatePointTransaction(
                pointsToUse: pts,
                totalAmount: originalTotalAmount,
                pointBalance: global.memberPointBalance,
                pointConfig: pointConfig,
              );
              setState(() {
                pointsUsed = result.usePoint;
                pointsDiscount = result.pointDiscountAmount;
                pointsPayment = result.pointAmount;
                earnedPoints = result.getPoint;
                pointUsageType = result.pointUsageType;
              });
              _updateGlobalPointData();
              recalc();
              // BC Member: ดึง get_point จาก API
              if (global.shopProfile?.isbcmember == true) {
                _fetchBCMemberPoints();
              }
              Navigator.pop(dialogContext);
            }

            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: constrainedWidth,
                constraints: BoxConstraints(
                  maxHeight: currentScreenHeight * 0.9,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(dialogPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(currentIsMobile ? 6 : 8),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.redeem,
                                color: Colors.amber.shade700,
                                size: currentIsMobile ? 20 : 24,
                              ),
                            ),
                            SizedBox(width: currentIsMobile ? 10 : 12),
                            Expanded(
                              child: Text(
                                global.language("use_points"),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: headerFontSize,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: Icon(Icons.close,
                                  color: Colors.red.shade700,
                                  size: currentIsMobile ? 20 : 30),
                              splashRadius: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        SizedBox(height: sectionSpacing),

                        // แสดงแต้มคงเหลือ และ สูงสุดที่ใช้ได้
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding:
                                    EdgeInsets.all(currentIsMobile ? 10 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${global.language("point_balance")}',
                                      style: TextStyle(
                                          fontSize: labelFontSize,
                                          color: Colors.amber.shade800),
                                    ),
                                    SizedBox(height: currentIsMobile ? 2 : 4),
                                    Text(
                                      '${global.moneyFormat.format(global.memberPointBalance)}',
                                      style: TextStyle(
                                          fontSize: valueFontSize,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber.shade900),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: currentIsMobile ? 8 : 10),
                            Expanded(
                              child: Container(
                                padding:
                                    EdgeInsets.all(currentIsMobile ? 10 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'ใช้ได้สูงสุด',
                                      style: TextStyle(
                                          fontSize: labelFontSize,
                                          color: Colors.grey.shade700),
                                    ),
                                    SizedBox(height: currentIsMobile ? 2 : 4),
                                    Text(
                                      '${global.moneyFormat.format(maxPointsCanUse)}',
                                      style: TextStyle(
                                          fontSize: valueFontSize,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: sectionSpacing),

                        // แสดงจำนวนแต้มที่กรอก
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              vertical: currentIsMobile ? 14 : 18,
                              horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: inputValue.isNotEmpty
                                    ? Colors.amber.shade400
                                    : Colors.grey.shade200,
                                width: 1.5),
                          ),
                          child: Column(
                            children: [
                              Text(
                                inputValue.isEmpty ? '0' : inputValue,
                                style: TextStyle(
                                  fontSize: displayFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: inputValue.isEmpty
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade800,
                                ),
                              ),
                              SizedBox(height: currentIsMobile ? 2 : 4),
                              Text(
                                global.language("points"),
                                style: TextStyle(
                                    fontSize: smallFontSize,
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),

                        // Error message
                        if (errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              errorMessage,
                              style: TextStyle(
                                  fontSize: smallFontSize,
                                  color: Colors.red.shade600),
                            ),
                          ),

                        // แสดงตัวอย่างส่วนลด
                        if (previewResult.usePoint > 0 && errorMessage.isEmpty)
                          Container(
                            margin:
                                EdgeInsets.only(top: currentIsMobile ? 10 : 12),
                            padding: EdgeInsets.all(currentIsMobile ? 8 : 10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    configPointUsageType == 1
                                        ? 'ส่วนลดที่จะได้รับ:'
                                        : 'ยอดชำระจากแต้ม:',
                                    style: TextStyle(
                                        fontSize: smallFontSize,
                                        color: Colors.green.shade800),
                                  ),
                                ),
                                Text(
                                  '-${global.moneyFormat.format(configPointUsageType == 1 ? previewResult.pointDiscountAmount : previewResult.pointAmount)} ฿',
                                  style: TextStyle(
                                      fontSize: currentIsMobile ? 14 : 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700),
                                ),
                              ],
                            ),
                          ),

                        SizedBox(height: currentIsMobile ? 10 : 12),

                        // อัตราแลกแต้ม
                        Text(
                          '$pointUsageDesc $usageTypeDesc',
                          style: TextStyle(
                              fontSize: smallFontSize,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: sectionSpacing),

                        // Numpad
                        _buildPointsNumpad(
                          onDigitPressed: addDigit,
                          onDeletePressed: removeDigit,
                          onClearPressed: clearInput,
                          onMaxPressed: useMaxPoints,
                          onConfirmPressed: confirmPoints,
                          buttonSize: buttonSize,
                          isMobile: currentIsMobile,
                        ),

                        // ปุ่มล้างแต้มที่ใช้ (ถ้ามีแต้มที่ใช้อยู่แล้ว)
                        if (pointsUsed > 0)
                          Padding(
                            padding:
                                EdgeInsets.only(top: currentIsMobile ? 10 : 12),
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  pointsUsed = 0;
                                  pointsDiscount = 0;
                                  pointsPayment = 0;
                                  earnedPoints = 0;
                                  pointUsageType = 1;
                                });
                                _updateGlobalPointData();
                                recalc();
                                // BC Member: ดึง get_point จาก API
                                if (global.shopProfile?.isbcmember == true) {
                                  _fetchBCMemberPoints();
                                }
                                Navigator.pop(dialogContext);
                              },
                              child: Text(
                                'ยกเลิกการใช้แต้ม',
                                style: TextStyle(
                                    color: Colors.red.shade600,
                                    fontSize: smallFontSize + 1),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Numpad สำหรับ dialog ใช้แต้ม
  Widget _buildPointsNumpad({
    required Function(String) onDigitPressed,
    required VoidCallback onDeletePressed,
    required VoidCallback onClearPressed,
    required VoidCallback onMaxPressed,
    required VoidCallback onConfirmPressed,
    required double buttonSize,
    required bool isMobile,
  }) {
    Widget buildButton(String digit,
        {Color? bgColor, Color? textColor, IconData? icon, String? label}) {
      return Container(
        margin: const EdgeInsets.all(3),
        child: Material(
          color: bgColor ?? Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => onDigitPressed(digit),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: buttonSize,
              height: buttonSize * 0.75,
              alignment: Alignment.center,
              child: icon != null
                  ? Icon(icon,
                      color: textColor ?? Colors.grey.shade700,
                      size: buttonSize * 0.35)
                  : Text(
                      label ?? digit,
                      style: TextStyle(
                        fontSize: buttonSize * 0.35,
                        fontWeight: FontWeight.w500,
                        color: textColor ?? Colors.grey.shade800,
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    Widget buildActionButton(
        {required VoidCallback onTap,
        required Color bgColor,
        required Color textColor,
        IconData? icon,
        String? label}) {
      return Container(
        margin: const EdgeInsets.all(3),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: buttonSize,
              height: buttonSize * 0.75,
              alignment: Alignment.center,
              child: icon != null
                  ? Icon(icon, color: textColor, size: buttonSize * 0.35)
                  : Text(
                      label ?? '',
                      style: TextStyle(
                          fontSize: buttonSize * 0.28,
                          fontWeight: FontWeight.w600,
                          color: textColor),
                    ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [buildButton('1'), buildButton('2'), buildButton('3')]),
        const SizedBox(height: 4),
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [buildButton('4'), buildButton('5'), buildButton('6')]),
        const SizedBox(height: 4),
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [buildButton('7'), buildButton('8'), buildButton('9')]),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ปุ่ม Clear
            buildActionButton(
              onTap: onClearPressed,
              bgColor: Colors.grey.shade200,
              textColor: Colors.grey.shade600,
              label: 'C',
            ),
            buildButton('0'),
            // ปุ่ม Delete
            buildActionButton(
              onTap: onDeletePressed,
              bgColor: Colors.grey.shade200,
              textColor: Colors.grey.shade600,
              icon: Icons.backspace_outlined,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ปุ่มใช้ทั้งหมด
            Container(
              margin: const EdgeInsets.all(3),
              child: Material(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onMaxPressed,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: buttonSize * 1.5 + 6,
                    height: buttonSize * 0.75,
                    alignment: Alignment.center,
                    child: Text(
                      'ใช้ทั้งหมด',
                      style: TextStyle(
                          fontSize: buttonSize * 0.26,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade800),
                    ),
                  ),
                ),
              ),
            ),
            // ปุ่มยืนยัน
            Container(
              margin: const EdgeInsets.all(3),
              child: Material(
                color: primaryThemeColor,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onConfirmPressed,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: buttonSize * 1.5 + 6,
                    height: buttonSize * 0.75,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check,
                            color: Colors.white, size: buttonSize * 0.3),
                        const SizedBox(width: 4),
                        Text(
                          global.language("confirm"),
                          style: TextStyle(
                              fontSize: buttonSize * 0.26,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive variables
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    // Responsive padding
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 20.0 : 28.0);
    final verticalPadding = isMobile ? 16.0 : 20.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(horizontalPadding, verticalPadding,
          horizontalPadding, verticalPadding - 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Title (center)
          Center(
            child: Text(
              global.language("order_summary"),
              style: TextStyle(
                fontFamily: 'Kanit',
                fontSize: isMobile ? 20 : (isTablet ? 42 : 48),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          // Countdown timer (top right)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 14,
                vertical: isMobile ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: global.countDownForHome <= 10
                    ? Colors.red.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: global.countDownForHome <= 10
                      ? Colors.red.shade300
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: isMobile ? 16 : 20,
                    color: global.countDownForHome <= 10
                        ? Colors.red.shade600
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${global.countDownForHome}',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 18,
                      fontWeight: FontWeight.w600,
                      color: global.countDownForHome <= 10
                          ? Colors.red.shade600
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void recalc() {
    Logger.d(
        'recalc: Start - orderTempDetailList.length=${orderTempDetailList.length}, priceIndex=${global.priceIndex}');
    sumOrderQty = 0;
    sumOrderAmount = 0;
    saveAmount = 0;

    // Reset bill values
    bill = BillCalcAmount();

    // คำนวณส่วนลดจากราคาสมาชิก (เทียบราคาปกติกับราคาสมาชิก)
    double memberPriceSaving = 0;
    if (global.isMember && global.priceIndex == 2) {
      for (var order in orderTempDetailList) {
        int productIndex =
            global.productList.indexWhere((p) => p.barcode == order.barcode);
        if (productIndex != -1) {
          var productData = global.productList[productIndex];
          // ราคาปกติ (keynumber = 1)
          double normalPrice = 0;
          for (var price in productData.prices) {
            if (price.keynumber == 1) {
              normalPrice = price.price;
              break;
            }
          }
          // ราคาสมาชิก
          double memberPrice =
              global.findProductPrice(prices: productData.prices);
          // คำนวณผลต่าง
          if (normalPrice > memberPrice) {
            memberPriceSaving += (normalPrice - memberPrice) * order.qty;
          }
        }
      }
    }

    // คำนวณยอดรวมและแยกประเภทสินค้า
    for (var order in orderTempDetailList) {
      Logger.d(
          'recalc: item ${order.barcode} - qty=${order.qty}, price=${order.price}, amount=${order.amount}, optionamount=${order.optionamount}');
      sumOrderQty += order.qty;
      sumOrderAmount += order.amount;
      saveAmount += order.discountamount ?? 0;

      if (order.is_except_vat == false) {
        bill.totalItemVatAmount += order.amount;
      } else {
        bill.totalItemExceptVatAmount += order.amount;
      }
      bill.detailTotalAmount += order.amount;
      bill.detailTotalAmountBeforeDiscount += order.amount;
    }

    // อัพเดท order qty ในรายการสินค้า
    for (var category in global.categoryList) {
      for (var product in category.codelist) {
        product.orderqty = 0;
        for (var order in orderTempDetailList) {
          if (product.barcode == order.barcode) {
            product.orderqty = product.orderqty! + order.qty;
          }
        }
      }
    }

    // ถ้าไม่มีรายการให้กลับ
    var orderTempListWhere = (widget.barcode.isEmpty)
        ? orderTempDetailList
        : orderTempDetailList
            .where((element) => element.barcode == widget.barcode);
    if (orderTempListWhere.isEmpty) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    // คำนวณส่วนลด
    discountAmount =
        global.calcDiscount(amount: sumOrderAmount, discountWord: discountWord);
    saveAmount += discountAmount;

    // ปัดเศษ (ไม่ใช้ในขณะนี้)
    roundAmount = 0;
    diffAmount = 0;

    if (global.shopProfile!.orderstation.isvatregister) {
      // จดทะเบียนภาษีมูลค่าเพิ่ม
      if (global.shopProfile!.orderstation.vattype == 0) {
        // ==========================================
        // VAT Type 0: รวม VAT (ภาษีรวมในราคา)
        // ลำดับการคำนวณ: หักส่วนลดก่อน -> คำนวณ VAT
        // ==========================================

        bill.totalDiscount = discountAmount;
        bill.shippingAmount = 0;
        bill.roundAmount = 0;
        bill.diffAmount = 0;

        // 1. คำนวณส่วนลดแยกตาม VAT/ไม่ VAT ตามสัดส่วน
        double totalItemAmount =
            bill.totalItemVatAmount + bill.totalItemExceptVatAmount;
        double discountVatAmount = 0;
        double discountExceptVatAmount = 0;

        if (totalItemAmount > 0) {
          double vatItemRatio = bill.totalItemVatAmount / totalItemAmount;
          discountVatAmount =
              global.roundDouble(discountAmount * vatItemRatio, 2);
          discountExceptVatAmount =
              global.roundDouble(discountAmount - discountVatAmount, 2);
        }

        // 2. ยอดสินค้าหลังหักส่วนลด (ปัดเศษเพื่อป้องกันข้อผิดพลาดทศนิยม)
        double vatAmountAfterDiscount =
            global.roundDouble(bill.totalItemVatAmount - discountVatAmount, 2);
        double exceptVatAmountAfterDiscount = global.roundDouble(
            bill.totalItemExceptVatAmount - discountExceptVatAmount, 2);

        // 3. คำนวณภาษี VAT จากยอดหลังหักส่วนลด (VAT รวมในราคา)
        // สูตร: (ยอดรวม VAT × อัตราภาษี) / (100 + อัตราภาษี)
        bill.totalVatAmount = global.roundDouble(
            (vatAmountAfterDiscount *
                    global.shopProfile!.orderstation.vatrate) /
                (100 + global.shopProfile!.orderstation.vatrate),
            2);

        // 4. ยอดก่อนภาษี = ยอดหลังหักส่วนลด - ภาษี
        bill.amountBeforeCalcVat =
            global.roundDouble(vatAmountAfterDiscount - bill.totalVatAmount, 2);

        // 5. ยอดสินค้าภาษีสุทธิ = ยอดหลังหักส่วนลด (ปัดเศษเพื่อป้องกันข้อผิดพลาดทศนิยม)
        bill.amountAfterCalcVat = global.roundDouble(vatAmountAfterDiscount, 2);

        // 6. สินค้ายกเว้นภาษีหลังหักส่วนลด (ปัดเศษเพื่อป้องกันข้อผิดพลาดทศนิยม)
        bill.amountExceptVat =
            global.roundDouble(exceptVatAmountAfterDiscount, 2);

        // 7. กำหนดค่าส่วนลดแยกประเภท
        bill.totalDiscountVatAmount = discountVatAmount;
        bill.totalDiscountExceptVatAmount = discountExceptVatAmount;

        // 8. ยอดรวมก่อนหักส่วนลด
        bill.totalAmountBeforeDiscount =
            bill.totalItemVatAmount + bill.totalItemExceptVatAmount;

        // 9. ยอดรวมหลังหักส่วนลด (ปัดเศษเพื่อป้องกันข้อผิดพลาดทศนิยม)
        bill.totalAmountAfterDiscount = global.roundDouble(
            bill.totalAmountBeforeDiscount - bill.totalDiscount, 2);

        // 10. ยอดชำระเงิน (ปัดเศษเพื่อป้องกันข้อผิดพลาดทศนิยม)
        bill.totalAmount = global.roundDouble(
            bill.totalAmountAfterDiscount +
                bill.shippingAmount +
                bill.diffAmount,
            2);

        // 11. ยอดประหยัด (รวมส่วนลดจากราคาสมาชิก)
        bill.saveAmount = saveAmount + memberPriceSaving;

        // อัพเดท vatAmount สำหรับใช้ในส่วนอื่น
        vatAmount = bill.totalVatAmount;
      } else if (global.shopProfile!.orderstation.vattype == 1) {
        // ==========================================
        // VAT Type 1: แยก VAT (คำนวณ VAT เพิ่มจากราคา)
        // ลำดับการคำนวณ: หักส่วนลดก่อน -> คำนวณ VAT หลัง
        // ==========================================

        bill.shippingAmount = 0;
        bill.roundAmount = 0;
        bill.diffAmount = 0;
        bill.totalDiscount = discountAmount;

        // 1. คำนวณส่วนลดแยกตาม VAT/ไม่ VAT ตามสัดส่วน
        double totalItemAmount =
            bill.totalItemVatAmount + bill.totalItemExceptVatAmount;
        double discountVatAmount = 0;
        double discountExceptVatAmount = 0;

        if (totalItemAmount > 0) {
          double vatItemRatio = bill.totalItemVatAmount / totalItemAmount;
          discountVatAmount =
              global.roundDouble(discountAmount * vatItemRatio, 2);
          discountExceptVatAmount =
              global.roundDouble(discountAmount - discountVatAmount, 2);
        }

        // 2. ยอดสินค้าหลังหักส่วนลด (ปัดเศษเพื่อป้องกันข้อผิดพลาดทศนิยม)
        double vatAmountAfterDiscount =
            global.roundDouble(bill.totalItemVatAmount - discountVatAmount, 2);
        double exceptVatAmountAfterDiscount = global.roundDouble(
            bill.totalItemExceptVatAmount - discountExceptVatAmount, 2);

        // 3. คำนวณ VAT เพิ่มจากราคาสินค้าหลังหักส่วนลด
        // สูตร: (ยอดก่อน VAT หลังหักส่วนลด) × อัตราภาษี / 100
        bill.totalVatAmount = global.roundDouble(
            (vatAmountAfterDiscount *
                (global.shopProfile!.orderstation.vatrate / 100)),
            2);

        // 4. ยอดก่อนภาษี = ยอดสินค้า VAT หลังหักส่วนลด
        bill.amountBeforeCalcVat = vatAmountAfterDiscount;

        // 5. ยอดหลังรวม VAT (ปัดเศษเพื่อป้องกันข้อผิดพลาดทศนิยม)
        bill.amountAfterCalcVat =
            global.roundDouble(vatAmountAfterDiscount + bill.totalVatAmount, 2);

        // 6. สินค้ายกเว้นภาษีหลังหักส่วนลด
        bill.amountExceptVat = exceptVatAmountAfterDiscount;

        // 7. กำหนดค่าส่วนลดแยกประเภท
        bill.totalDiscountVatAmount = discountVatAmount;
        bill.totalDiscountExceptVatAmount = discountExceptVatAmount;

        // 8. ยอดรวมก่อนหักส่วนลด
        bill.totalAmountBeforeDiscount =
            bill.totalItemVatAmount + bill.totalItemExceptVatAmount;

        // 9. ยอดรวมหลังหักส่วนลด (รวม VAT แล้ว) (ปัดเศษเพื่อป้องกันข้อผิดพลาดทศนิยม)
        bill.totalAmountAfterDiscount = global.roundDouble(
            bill.amountAfterCalcVat + bill.amountExceptVat, 2);

        // 10. ยอดชำระเงิน (ปัดเศษเพื่อป้องกันข้อผิดพลาดทศนิยม)
        bill.totalAmount = global.roundDouble(
            bill.totalAmountAfterDiscount +
                bill.shippingAmount +
                bill.diffAmount,
            2);

        // 11. ยอดประหยัด (รวมส่วนลดจากราคาสมาชิก)
        bill.saveAmount = saveAmount + memberPriceSaving;

        // อัพเดท vatAmount สำหรับใช้ในส่วนอื่น
        vatAmount = bill.totalVatAmount;
      }
    } else {
      // ==========================================
      // ไม่จดทะเบียนภาษีมูลค่าเพิ่ม
      // ไม่มีการคำนวณ VAT
      // ==========================================

      bill.totalDiscount = discountAmount;
      bill.totalVatAmount = 0;
      bill.amountBeforeCalcVat = global.roundDouble(
          bill.totalItemVatAmount + bill.totalItemExceptVatAmount, 2);
      bill.amountAfterCalcVat = bill.amountBeforeCalcVat;
      bill.amountExceptVat = 0;
      bill.shippingAmount = 0;
      bill.roundAmount = 0;
      bill.diffAmount = 0;

      // ยอดรวมก่อนหักส่วนลด
      bill.totalAmountBeforeDiscount = bill.amountBeforeCalcVat;

      // ยอดรวมหลังหักส่วนลด (ปัดเศษเพื่อป้องกันข้อผิดพลาดทศนิยม)
      bill.totalAmountAfterDiscount = global.roundDouble(
          bill.totalAmountBeforeDiscount - bill.totalDiscount, 2);

      // ยอดชำระเงิน (ปัดเศษเพื่อป้องกันข้อผิดพลาดทศนิยม)
      bill.totalAmount = global.roundDouble(
          bill.totalAmountAfterDiscount + bill.shippingAmount + bill.diffAmount,
          2);

      // ยอดประหยัด (รวมส่วนลดจากราคาสมาชิก)
      bill.saveAmount = saveAmount + memberPriceSaving;

      vatAmount = 0;
    }

    // ==========================================
    // หักส่วนลด/ยอดชำระจากแต้มสะสม (หักหลังจากคำนวณ VAT แล้ว)
    // pointusagetype: 1 = ส่วนลด (pointsDiscount), 2 = ชำระเงิน (pointsPayment)
    // ==========================================
    if (pointsUsed > 0) {
      // รวมยอดจากแต้ม (ส่วนลด + ยอดชำระ)
      double totalPointDeduction = pointsDiscount + pointsPayment;

      // ตรวจสอบไม่ให้เกินยอดชำระ
      if (totalPointDeduction > bill.totalAmount) {
        totalPointDeduction = bill.totalAmount;
        // คำนวณแต้มใหม่ตาม pointconfig
        final pointConfig = global.shopProfile?.orderstation.branch.pointconfig;
        final generalRule =
            PointCalculationHelper.getActiveGeneralRule(pointConfig);
        if (generalRule != null && generalRule.pointvalue > 0) {
          pointsUsed = totalPointDeduction * generalRule.pointvalue;
        } else {
          pointsUsed = totalPointDeduction;
        }
        // อัพเดทค่าตาม pointUsageType
        if (pointUsageType == 1) {
          pointsDiscount = totalPointDeduction;
          pointsPayment = 0;
        } else {
          pointsPayment = totalPointDeduction;
          pointsDiscount = 0;
        }
      }

      // หักยอดจากแต้ม
      bill.totalAmount =
          global.roundDouble(bill.totalAmount - totalPointDeduction, 2);
      bill.saveAmount =
          global.roundDouble(bill.saveAmount + totalPointDeduction, 2);
      saveAmount = bill.saveAmount;

      // อัพเดท global variables
      _updateGlobalPointData();
    }

    // คำนวณแต้มที่จะได้รับจากการซื้อ (ใช้ยอดหลังหักส่วนลดแต้ม)
    if (global.isMember) {
      if (global.shopProfile?.isbcmember == true &&
          global.memberPinCode.isNotEmpty) {
        // BC Member: จะดึง get_point จาก API แทน - เรียก _fetchBCMemberPoints() หลัง recalc()
        // ไม่คำนวณ earnedPoints ที่นี่ จะถูก update โดย _fetchBCMemberPoints()
        Logger.d(
            'recalc: isbcmember=true, skip local point calculation, will fetch from API');
      } else {
        // ใช้ pointconfig จาก shopProfile
        final pointConfig = global.shopProfile?.orderstation.branch.pointconfig;
        earnedPoints = PointCalculationHelper.calculateEarnedPoints(
          totalAmount: bill.totalAmount,
          pointConfig: pointConfig,
        );
        global.getPoint = earnedPoints;
      }
    }
    Logger.d(
        'recalc: Completed - sumOrderAmount=$sumOrderAmount, bill.totalAmount=${bill.totalAmount}');
  }

  /// BC Member: ดึง get_point จาก API แทนการคำนวณเอง
  /// เรียกหลัง recalc() เมื่อ isbcmember = true
  Future<void> _fetchBCMemberPoints() async {
    if (global.shopProfile?.isbcmember != true ||
        global.memberPinCode.isEmpty) {
      return;
    }
    if (!global.isMember || bill.totalAmount <= 0) {
      earnedPoints = 0;
      global.getPoint = 0;
      return;
    }

    try {
      final result = await api.calculateBCMemberPoint(
        amount: bill.totalAmount,
        lineUid: global.memberPinCode,
        usePoint: pointsUsed,
      );
      if (!mounted) return;

      if (result['success'] == true) {
        final getPointRaw = result['get_point'];
        double fetchedPoints = 0;
        if (getPointRaw is double) {
          fetchedPoints = getPointRaw;
        } else if (getPointRaw is int) {
          fetchedPoints = getPointRaw.toDouble();
        } else if (getPointRaw != null) {
          fetchedPoints = double.tryParse(getPointRaw.toString()) ?? 0;
        }

        setState(() {
          earnedPoints = fetchedPoints;
          global.getPoint = earnedPoints;
        });
        Logger.i(
            '_fetchBCMemberPoints: success - earnedPoints=$earnedPoints from API',
            tag: 'BCMember');
      } else {
        Logger.w(
            '_fetchBCMemberPoints: API returned success=false, error=${result['error']}',
            tag: 'BCMember');
        setState(() {
          earnedPoints = 0;
          global.getPoint = 0;
        });
      }
    } catch (e) {
      Logger.e('_fetchBCMemberPoints: error', error: e, tag: 'BCMember');
      if (!mounted) return;
      setState(() {
        earnedPoints = 0;
        global.getPoint = 0;
      });
    }
  }

  void reload() {
    Logger.d(
        'reload: Start - mode=${widget.mode}, priceIndex=${global.priceIndex}');
    if (widget.mode == 9) {
      // กินก่อนจ่าย ให้ไปดึงข้อมูลมาจาก server
      // bloc
      bill = BillCalcAmount();
      context.read<ClickHouseOrderTempBloc>().add(ClickHouseOrderTempLoadStart(
          tableNumber: global.tableNumberSelected.ordertagnumber));
    } else {
      // จ่ายก่อนกินให้ดึงจาก objectbox
      bill = BillCalcAmount();
      api
          .getOrderTempFromObjectBox(barcode: "", isTakeAway: global.orderType)
          .then((value) {
        if (!mounted) return;
        orderTempDetailList = value;
        recalc();
        // BC Member: ดึง get_point จาก API
        if (global.shopProfile?.isbcmember == true) {
          _fetchBCMemberPoints();
        }
        setState(() {});
        // Show flash animation when cart changes
        if (orderTempDetailList.isNotEmpty) {
          _showFlashAnimation();
        }
      });
    }
  }

  Future<void> updateDoc() async {
    // update มูลค่าใหม่
    String query =
        "SELECT * FROM ${global.orderTempTableName()} WHERE shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and ordertagnumber='${global.tableNumberSelected.ordertagnumber}' order by orderdatetime";
    var result = await api.clickHouseSelect(query);
    ResponseDataModel responseData = ResponseDataModel.fromJson(result);
    double totalAmount = 0;
    for (var data in responseData.data) {
      totalAmount += double.tryParse(data["amount"].toString()) ?? 0;
    }
    await api.clickHouseExecute(
        "alter table ${global.orderTempDocTableName()} update totalamount=$totalAmount where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and ordertagnumber='${global.tableNumberSelected.ordertagnumber}'");
  }

  Future<void> orderRemoveByOrderGuid(
      {required String orderGuid, required Function refresh}) async {
    // Show loading dialog
    if (mounted) {
      _showRemoveLoadingDialog();
    }

    try {
      debugPrint(
          '[orderRemoveByOrderGuid] Starting removal process for orderGuid: $orderGuid, mode: ${widget.mode}');

      if (widget.mode == 9) {
        // Mode 9: สรุปยอดกินก่อนจ่าย
        debugPrint(
            '[orderRemoveByOrderGuid] Mode 9: Removing from server ordertemp table');

        await api
            .clickHouseExecute(
                "alter table ${global.orderTempTableName()} delete where shopid='${global.deviceConfig.shopId}' and orderguid='$orderGuid';")
            .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException(
                'ลบรายการใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง');
          },
        );

        debugPrint('[orderRemoveByOrderGuid] Mode 9: Updating document');
        await updateDoc();
      } else {
        // Mode 0 or other modes: จ่ายก่อนกิน
        debugPrint(
            '[orderRemoveByOrderGuid] Mode ${widget.mode}: Finding local record');

        int id = -1;
        var getId = global.objectBoxStore
            .box<OrderTempObjectBoxModel>()
            .query(
              OrderTempObjectBoxModel_.orderguid.equals(orderGuid),
            )
            .build()
            .find();

        if (getId.isNotEmpty) {
          id = getId[0].id;
          debugPrint(
              '[orderRemoveByOrderGuid] Found local record with id: $id');
        }

        if (id != -1) {
          if (widget.mode == 0) {
            // จ่ายก่อนกิน - remove from local ObjectBox
            debugPrint(
                '[orderRemoveByOrderGuid] Mode 0: Removing from local ObjectBox');
            global.objectBoxStore.box<OrderTempObjectBoxModel>().remove(id);
          }
        }

        // Remove stock record from server (MUST await before refresh)
        debugPrint(
            '[orderRemoveByOrderGuid] Removing stock record from ordertempcalcqty');
        await api
            .clickHouseExecute(
                "alter table ${global.clickHouseDatabaseName}.ordertempcalcqty delete where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderguid='$orderGuid'")
            .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException(
                'ลบข้อมูล stock ใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง');
          },
        );
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Refresh the cart
      debugPrint('[orderRemoveByOrderGuid] Refreshing cart display');
      refresh();

      // Show success feedback
      if (mounted) {
        _showRemoveSuccessSnackBar();
      }

      debugPrint('[orderRemoveByOrderGuid] Item removed successfully');
    } on TimeoutException catch (e) {
      debugPrint('[orderRemoveByOrderGuid] Timeout error: $e');

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error dialog
      if (mounted) {
        await _showRemoveErrorDialog(
          title: 'หมดเวลา',
          message:
              e.message ?? 'การลบรายการใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง',
        );
      }
    } catch (e) {
      debugPrint('[orderRemoveByOrderGuid] Error: $e');

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error dialog
      if (mounted) {
        await _showRemoveErrorDialog(
          title: 'เกิดข้อผิดพลาด',
          message: 'ไม่สามารถลบรายการได้: ${e.toString()}',
        );
      }
    }
  }

  /// Show loading dialog while removing item
  void _showRemoveLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'กำลังลบรายการ...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'กรุณารอสักครู่',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show success snackbar after item removed
  void _showRemoveSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'ลบรายการสำเร็จ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show error dialog when removal fails
  Future<void> _showRemoveErrorDialog({
    required String title,
    required String message,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red.shade400,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'ปิด',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /*Future<void> orderEdit(
      {required BuildContext context,
      required OrderTempDetailModel orderTemp,
      required bool calcStockQty,
      required Function refresh}) async {
    int findProductIndex = global.productList
        .indexWhere((element) => element.barcode == orderTemp.barcode);
    var product = global.productList[findProductIndex];
    if (orderTemp.optionselected.isNotEmpty) {
      List<ProductProcessOptionModel> optionList =
          (jsonDecode(orderTemp.optionselected) as List)
              .map((e) => ProductProcessOptionModel.fromJson(e))
              .toList();
      product.options = optionList;
    }
    var result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => OrderStandardProductOptionPage(
                product: product,
                qty: orderTemp.qty,
                remark: orderTemp.remark,
              )),
    );
    if (result != null) {
      String remark = result['remark'];
      double qty = result['qty'];
      bool confirm = result['flag'];
      remark = result['remark'];
      if (confirm) {
        // อัพเดทรายการเก่า
        /*await api.clickHouseExecute(
            "alter table ordertemp update qty=$qty,optionselected='$jsonOptions',remark='$remark' where shopid='${global.deviceConfig.shopId}' and orderguid='${orderTemp.orderguid}';");*/
        var getId = global.objectBoxStore // อัพเดทรายการเก่า
            .box<OrderTempObjectBoxModel>()
            .query(
              OrderTempObjectBoxModel_.orderguid.equals(orderTemp.orderguid),
            )
            .build()
            .find();
        if (getId.isNotEmpty) {
          bool calcStockPass = true;
          if (calcStockQty) {
            // ตรวจสอบยอดคงเหลือ
            double oldQty = orderTemp.qty;
            var getStockQty = await api.clickHouseSelect(
                "select (sum(qty)+$oldQty)-$qty as qty from ordertempcalcqty where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and barcode='${orderTemp.barcode}'");
            ResponseDataModel responseData =
                ResponseDataModel.fromJson(getStockQty);
            if (responseData.data.isNotEmpty) {
              double stockQty =
                  double.tryParse(responseData.data[0]["qty"].toString()) ?? 0;
              if (stockQty < 0) {
                if (context.mounted) {
                  calcStockPass = false;
                  await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(global
                              .language("unable_to_complete_transaction")),
                          content:
                              Text(global.language("inventory_is_not_enough")),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(global.language("confirm")),
                            ),
                          ],
                        );
                      });
                }
              }
            }
          }
          if (calcStockPass) {
            OrderTempObjectBoxModel orderTempData = getId[0];
            orderTempData.qty = qty;
            orderTempData.optionselected =
                jsonEncode(product.options.map((e) => e.toJson()).toList());
            orderTempData.remark = remark;
            // คำนวณใหม่
            double amount = qty * product.setprice;
            if (findProductIndex != -1) {
              // discount
              amount = amount -
                  global.calcDiscount(
                      amount: amount,
                      discountWord:
                          global.productList[findProductIndex].discountword);
            }
            if (product.options.isNotEmpty) {
              for (var option in product.options) {
                for (var choice in option.choices) {
                  if (choice.selected) {
                    double calcAmount = choice.priceValue * qty;
                    double discount = global.calcDiscount(
                        amount: calcAmount, discountWord: choice.discountWord);
                    amount += (calcAmount - discount);
                  }
                }
              }
            }
            orderTempData.amount = amount;
            global.objectBoxStore
                .box<OrderTempObjectBoxModel>()
                .put(orderTempData, mode: PutMode.update);
            if (calcStockQty) {
              // update qty to server
              api.clickHouseExecute(
                  "alter table ${global.clickHouseDatabaseName}.ordertempcalcqty update qty=${qty * -1} where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and orderguid='${orderTempData.orderguid}'");
            }
          }
        }
      }
      setState(() {});
      refresh();
    }
  }*/

  Widget orderTempBody(
      {required BuildContext context,
      required OrderTempDetailModel order,
      required Function refresh}) {
    int productIndex = global.productList
        .indexWhere((element) => element.barcode == order.barcode);
    List<ProductProcessOptionModel> optionList =
        (order.optionselected.isNotEmpty)
            ? (jsonDecode(order.optionselected) as List)
                .map((e) => ProductProcessOptionModel.fromJson(e))
                .toList()
            : [];

    // Responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final imageSize = isMobile ? 80.0 : (isTablet ? 100.0 : 120.0);
    final titleFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 20.0);
    final subFontSize = isMobile ? 12.0 : (isTablet ? 13.0 : 14.0);

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 10 : 8),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image - Square thumbnail
              if (global.orderShowImage &&
                  global.productList[productIndex].imageuri.isNotEmpty)
                Container(
                  width: imageSize,
                  height: imageSize,
                  margin: EdgeInsets.only(right: isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: global.productList[productIndex].imageuri,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade100,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade100,
                        child: Icon(
                          Icons.restaurant_menu,
                          size: imageSize * 0.4,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name & Total Amount Row
                    Builder(
                      builder: (context) {
                        // หาราคาปกติ (keynumber = 1) สำหรับคำนวณยอดรวมปกติ
                        double normalPrice = 0;
                        if (productIndex != -1) {
                          for (var price
                              in global.productList[productIndex].prices) {
                            if (price.keynumber == 1) {
                              normalPrice = price.price;
                              break;
                            }
                          }
                        }
                        // คำนวณยอดรวมปกติ (ราคาปกติ × จำนวน + option)
                        double normalAmount =
                            normalPrice * order.qty + (order.optionamount ?? 0);
                        // ถ้าเป็นสมาชิกและยอดปกติมากกว่ายอดที่ซื้อ แสดงยอดปกติขีดทับ
                        bool showNormalAmount = global.isMember &&
                            normalAmount > order.amount &&
                            normalAmount > 0;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                global.getNameFromLanguage(
                                    global.productList[productIndex].names,
                                    global.languageForCustomer),
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // ยอดปกติขีดทับ (ถ้ามี)
                                if (showNormalAmount)
                                  Text(
                                    "${global.moneyFormat.format(normalAmount)} ฿",
                                    style: TextStyle(
                                      fontSize: titleFontSize - 3,
                                      color: Colors.grey.shade400,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: Colors.grey.shade400,
                                    ),
                                  ),
                                // ยอดสมาชิก/ยอดปัจจุบัน
                                Text(
                                  "${global.moneyFormat.format(order.amount)} ฿",
                                  style: TextStyle(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: showNormalAmount
                                        ? Colors.green.shade600
                                        : const Color(0xFFDA291C),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    SizedBox(height: isMobile ? 6 : 8),

                    // Quantity & Price Info - แสดงราคาปกติขีดทับถ้าเป็นราคาสมาชิก
                    Builder(
                      builder: (context) {
                        // หาราคาปกติ (keynumber = 1)
                        double normalPrice = 0;
                        if (productIndex != -1) {
                          for (var price
                              in global.productList[productIndex].prices) {
                            if (price.keynumber == 1) {
                              normalPrice = price.price;
                              break;
                            }
                          }
                        }
                        // ถ้าเป็นสมาชิกและราคาปกติมากกว่าราคาที่ซื้อ แสดงราคาปกติขีดทับ
                        bool showNormalPrice = global.isMember &&
                            normalPrice > order.price &&
                            normalPrice > 0;

                        return Row(
                          children: [
                            Text(
                              "${global.moneyFormat.format(order.qty)} ${global.getNameFromLanguage(global.productList[productIndex].unitnames, global.languageForCustomer)}",
                              style: TextStyle(
                                fontSize: subFontSize,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              "  ×  ",
                              style: TextStyle(
                                fontSize: subFontSize,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            // ราคาปกติขีดทับ (ถ้ามี)
                            if (showNormalPrice) ...[
                              Text(
                                "${global.moneyFormat.format(normalPrice)} ฿",
                                style: TextStyle(
                                  fontSize: subFontSize - 1,
                                  color: Colors.grey.shade400,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            // ราคาสมาชิก/ราคาปัจจุบัน
                            Text(
                              "${global.moneyFormat.format(order.price)} ฿",
                              style: TextStyle(
                                fontSize: subFontSize,
                                color: showNormalPrice
                                    ? Colors.green.shade600
                                    : Colors.grey.shade600,
                                fontWeight: showNormalPrice
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    // Options
                    if (optionList.isNotEmpty) ...[
                      SizedBox(height: isMobile ? 8 : 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (var option in optionList)
                            for (var choice in option.choices)
                              if (choice.selected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "${global.getNameFromLanguage(choice.names, global.languageForCustomer)}${choice.priceValue > 0 ? ' +${global.moneyFormat.format(choice.amount)}฿' : ''}",
                                    style: TextStyle(
                                      fontSize: isMobile ? 11 : 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ],

                    // Remark
                    if (order.remark.isNotEmpty) ...[
                      SizedBox(height: isMobile ? 8 : 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sticky_note_2_outlined,
                                size: 14, color: Colors.amber.shade700),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                order.remark,
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: isMobile ? 12 : 14),

                    // Action Buttons - Minimalist style
                    Row(
                      children: [
                        // Edit Button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              global.countDownForHome =
                                  global.countDownForHomeMax;
                              int findProductIndex = global.productList
                                  .indexWhere((element) =>
                                      element.barcode == order.barcode);
                              var product =
                                  global.productList[findProductIndex];
                              product.qty = order.qty;
                              product.remark = order.remark;
                              product.options = [];
                              if (order.optionselected.isNotEmpty) {
                                List<dynamic> jsonOptions =
                                    jsonDecode(order.optionselected);
                                for (var jsonOption in jsonOptions) {
                                  product.options.add(
                                      ProductProcessOptionModel.fromJson(
                                          jsonOption));
                                }
                              }
                              await showDialog(
                                  barrierDismissible: false,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return StatefulBuilder(builder:
                                        (context, StateSetter setState) {
                                      return AlertDialog(
                                        contentPadding: const EdgeInsets.all(8),
                                        content: StatefulBuilder(builder:
                                            (context, StateSetter setState) {
                                          return orderAnimationOneProductOptionWidget(
                                            orderGuid: order.orderguid,
                                            orderTemp: order,
                                            calcStockQty:
                                                product.isstockforrestaurant,
                                            isAppend: false,
                                            context: context,
                                            product: product,
                                            refresh: () {
                                              if (widget.mode == 9) {
                                                updateDoc();
                                              }
                                              setState(() {});
                                            },
                                            onClose: () async {
                                              Navigator.pop(context);
                                              refresh();
                                            },
                                          );
                                        }),
                                      );
                                    });
                                  });
                            },
                            icon: Icon(Icons.edit_outlined,
                                size: isMobile ? 16 : 18),
                            label: Text(
                              global.language("change"),
                              style: TextStyle(
                                  fontSize: isMobile ? 12 : 13,
                                  fontWeight: FontWeight.w500),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: EdgeInsets.symmetric(
                                  vertical: isMobile ? 8 : 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isMobile ? 8 : 10),
                        // Delete Button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              global.countDownForHome =
                                  global.countDownForHomeMax;
                              await orderRemoveByOrderGuid(
                                  orderGuid: order.orderguid, refresh: refresh);
                              int findProductIndex = global.productList
                                  .indexWhere((element) =>
                                      element.barcode == order.barcode);
                              if (findProductIndex != -1) {
                                var product =
                                    global.productList[findProductIndex];
                                String message = global.getNameFromLanguage(
                                    product.names, global.languageForCustomer);
                                message += " ";
                                message += global.findLanguage(
                                    code: "order_in_cart_remove_success",
                                    languageCode: global.languageForCustomer);
                                global.textToSpeech(message);
                              }
                            },
                            icon: Icon(Icons.delete_outline,
                                size: isMobile ? 16 : 18),
                            label: Text(
                              global.language("delete"),
                              style: TextStyle(
                                  fontSize: isMobile ? 12 : 13,
                                  fontWeight: FontWeight.w500),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Color(0xFFDA291C),
                              side: const BorderSide(color: Color(0xFFDA291C)),
                              padding: EdgeInsets.symmetric(
                                  vertical: isMobile ? 8 : 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for products list only - Minimalist List Style
  Widget orderProductsList(
      {required List<OrderTempDetailModel> orderTempList,
      required BuildContext context,
      required Function refresh}) {
    var orderTempListWhere = (widget.barcode.isEmpty)
        ? orderTempList
        : orderTempList.where((element) => element.barcode == widget.barcode);

    // Responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Empty State
        if (orderTempListWhere.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                vertical: isMobile ? 48 : 64, horizontal: 24),
            margin: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: isMobile ? 56 : 72,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  "ไม่มีรายการ${(widget.barcode.isEmpty) ? "" : " ${global.getNameFromLanguage(product.names, global.languageForCustomer)}"}",
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        // Products List - Vertical Layout
        else
          Column(
            children: orderTempListWhere
                .map((e) =>
                    orderTempBody(context: context, order: e, refresh: refresh))
                .toList(),
          ),
      ],
    );
  }

  // Widget for summary section (to be displayed at bottom)
  List<Widget> orderSummaryList(
      {required List<OrderTempDetailModel> orderTempList,
      required BuildContext context}) {
    List<Widget> orderList = [];

    // Responsive font sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    var headerStyle = TextStyle(
        fontSize: isMobile ? 12 : (isTablet ? 14 : 16),
        fontWeight: FontWeight.bold);
    var detailStyle = TextStyle(fontSize: isMobile ? 10 : (isTablet ? 12 : 14));
    List<int> expandedFlex = [2, 1, 1, 1];
    var orderTempListWhere = (widget.barcode.isEmpty)
        ? orderTempDetailList
        : orderTempDetailList
            .where((element) => element.barcode == widget.barcode);
    if (global.deviceConfig.machineCondition == 0 &&
        widget.barcode.isEmpty &&
        (widget.mode == 0 || widget.mode == 9) &&
        orderTempListWhere.isNotEmpty) {
      orderList.add(
        // Action Buttons Section

        Container(
          margin: EdgeInsets.only(top: 0, bottom: isMobile ? 12 : 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: isMobile ? 48 : 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    global.countDownForHome = global.countDownForHomeMax;
                    var result = await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            content: PayDiscountWidget(amount: sumOrderAmount),
                          );
                        });
                    if (result != null) {
                      setState(() {
                        discountWord = result;
                      });
                    }
                    reload();
                  },
                  icon: Icon(Icons.discount,
                      color: Colors.purple.shade600, size: isMobile ? 18 : 20),
                  label: Text(
                    discountWord.isEmpty
                        ? global.language("discount")
                        : "${global.language("discount")}: $discountWord",
                    style: TextStyle(
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 14 : 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Container(
                height: isMobile ? 48 : 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // พิมพ์ที่เครื่องตัวเอง
                    global.countDownForHome = global.countDownForHomeMax;
                    PayResultModel payResult = PayResultModel();
                    payResult.discountAmount = discountAmount;
                    payResult.diffAmount = diffAmount;
                    payResult.discountWord = discountWord;
                    payResult.saveAmount = saveAmount;
                    payResult.vatAmount = vatAmount;
                    payResult.totalAmount =
                        sumOrderAmount - (discountAmount - diffAmount);
                    // ข้อมูลแต้มสะสม
                    payResult.usePoint = pointsUsed;
                    payResult.getPoint = earnedPoints;
                    payResult.pointDiscountAmount = pointsDiscount;
                    payResult.payPointAmount = pointsPayment;
                    payResult.currentPointBalance = global.currentPointBalance;
                    payResult.memberName = global.memberName;
                    payResult.memberPhone = global.phoneNumber;
                    global.printQueue.add(PrintTicketClass(
                        docDate: DateTime.now(),
                        docNumber: "สรุป",
                        orderTagNumber: "",
                        orderId: "",
                        printType: 0,
                        printLogo: false,
                        orderType: global.orderType,
                        printHeader: false,
                        orderTempDetails: [],
                        queueNumber: 0,
                        saveToFile: true,
                        footer: "",
                        orderList: orderTempDetailList,
                        printerLocalConfig:
                            global.deviceConfig.printerForOrderStation,
                        payResult: payResult,
                        openCashDrawer: false,
                        qrCode: ""));

                    printQueueWorker();
                  },
                  icon: Icon(Icons.print,
                      color: Colors.blue.shade600, size: isMobile ? 18 : 20),
                  label: Text(
                    "พิมพ์ใบสรุป",
                    style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 14 : 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    for (var order in orderTempList) {
      var optionList = (order.optionselected.isNotEmpty)
          ? (jsonDecode(order.optionselected) as List)
              .map((e) => ProductProcessOptionModel.fromJson(e))
              .toList()
          : [];
      orderList.add(Row(children: [
        Expanded(
            flex: expandedFlex[0],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    global.getNameFromLanguage(
                        global
                            .productList[global.productList.indexWhere(
                                (element) => element.barcode == order.barcode)]
                            .names,
                        global.languageForCustomer),
                    style: detailStyle),
                if (optionList.isNotEmpty)
                  for (var option in optionList)
                    for (var choice in option.choices)
                      if (choice.selected)
                        Text(
                            "*${global.getNameFromLanguage(choice.names, global.languageForCustomer)}${(choice.priceValue > 0) ? " ${global.language("add_money")} ${global.moneyFormat.format(choice.priceValue - global.calcDiscount(amount: choice.priceValue, discountWord: choice.discountWord))} ${global.language("money_baht")}" : ""}",
                            style: detailStyle.apply(color: Colors.blue)),
                if (order.remark.isNotEmpty)
                  Text("${global.language("note")} : ${order.remark}",
                      style: detailStyle),
              ],
            )),
        Expanded(
            flex: expandedFlex[1],
            child: Text(
                "${global.moneyFormat.format(order.qty)} ${global.getNameFromLanguage(global.productList[global.productList.indexWhere((element) => element.barcode == order.barcode)].unitnames, global.languageForCustomer)}",
                style: detailStyle,
                textAlign: TextAlign.right)),
        Expanded(
          flex: expandedFlex[2],
          child: Text(global.moneyFormatAndDot.format((order.price)),
              style: detailStyle, textAlign: TextAlign.right),
        ),
        Expanded(
          flex: expandedFlex[3],
          child: (order.optionamount == 0)
              ? Text(global.moneyFormatAndDot.format(order.amount),
                  style: detailStyle, textAlign: TextAlign.right)
              : RichText(
                  textAlign: TextAlign.right,
                  text: TextSpan(
                    text: global.moneyFormatAndDot.format(order.amount),
                    style: detailStyle,
                    children: <TextSpan>[
                      TextSpan(
                          text:
                              "+${global.moneyFormatAndDot.format((order.optionamount))}",
                          style: detailStyle.apply(color: Colors.red)),
                      TextSpan(
                          text:
                              "\n=${global.moneyFormatAndDot.format(order.amount)}",
                          style: detailStyle.apply(color: Colors.blue))
                    ],
                  ),
                ),
        ),
      ]));
    }
    orderList.add(Row(children: [
      Expanded(
        flex: expandedFlex[0],
        child: Container(),
      ),
      Expanded(
        flex: expandedFlex[1],
        child: Container(),
      ),
      Expanded(
        flex: expandedFlex[2],
        child: Text(global.language("total_amount"),
            style: headerStyle, textAlign: TextAlign.right),
      ),
      Expanded(
        flex: expandedFlex[3],
        child: Text(
            "${global.moneyFormatAndDot.format(sumOrderAmount)} ${global.language("money_baht")}",
            style: headerStyle,
            textAlign: TextAlign.right),
      ),
    ]));
    if (bill.totalDiscount != 0) {
      orderList.add(Row(children: [
        Expanded(
          flex: expandedFlex[0],
          child: Container(),
        ),
        Expanded(
          flex: expandedFlex[1] + expandedFlex[2],
          child: Text("${global.language("discount")} : $discountWord",
              style: headerStyle, textAlign: TextAlign.right),
        ),
        Expanded(
          flex: expandedFlex[3],
          child: Text(
              "${global.moneyFormatAndDot.format(bill.totalDiscount)} ${global.language("money_baht")}",
              style: headerStyle,
              textAlign: TextAlign.right),
        ),
      ]));
      orderList.add(Row(children: [
        Expanded(
          flex: expandedFlex[0],
          child: Container(),
        ),
        Expanded(
          flex: expandedFlex[1] + expandedFlex[2],
          child: Text("ยอดรวมหลังหักส่วนลด",
              style: headerStyle, textAlign: TextAlign.right),
        ),
        Expanded(
          flex: expandedFlex[3],
          child: Text(
              "${global.moneyFormatAndDot.format(bill.totalAmountBeforeDiscount - bill.totalDiscount)} ${global.language("money_baht")}",
              style: headerStyle,
              textAlign: TextAlign.right),
        ),
      ]));
    }
    if (widget.mode == 0 || widget.mode == 9) {
      if (global.shopProfile!.orderstation.isvatregister) {
        // จดทะเบียนภาษีมูลค่าเพิ่ม
        if (global.shopProfile!.orderstation.vattype == 0) {
          // VAT Type 0: รวม VAT - แสดงยอดรวม VAT
          if (bill.amountAfterCalcVat != 0) {
            orderList.add(Row(children: [
              Expanded(
                flex: expandedFlex[0],
                child: Container(),
              ),
              Expanded(
                flex: expandedFlex[1] + expandedFlex[2],
                child: Text("${global.language("total_item_vat_amount")} ",
                    style: headerStyle, textAlign: TextAlign.right),
              ),
              Expanded(
                flex: expandedFlex[3],
                child: Text(
                    "${global.moneyFormatAndDot.format(bill.amountAfterCalcVat)} ${global.language("money_baht")}",
                    style: headerStyle,
                    textAlign: TextAlign.right),
              ),
            ]));
          }
        } else if (global.shopProfile!.orderstation.vattype == 1) {
          // VAT Type 1: แยก VAT - แสดงยอดก่อนรวม VAT
          if (bill.amountBeforeCalcVat != 0) {
            orderList.add(Row(children: [
              Expanded(
                flex: expandedFlex[0],
                child: Container(),
              ),
              Expanded(
                flex: expandedFlex[1] + expandedFlex[2],
                child: Text("${global.language("total_item_vat_amount")} ",
                    style: headerStyle, textAlign: TextAlign.right),
              ),
              Expanded(
                flex: expandedFlex[3],
                child: Text(
                    "${global.moneyFormatAndDot.format(bill.amountBeforeCalcVat)} ${global.language("money_baht")}",
                    style: headerStyle,
                    textAlign: TextAlign.right),
              ),
            ]));
          }
        }

        if (bill.amountBeforeCalcVat != 0) {
          orderList.add(Row(children: [
            Expanded(
              flex: expandedFlex[0],
              child: Container(),
            ),
            Expanded(
              flex: expandedFlex[1] + expandedFlex[2],
              child: Text("${global.language("before_vat")} ",
                  style: headerStyle, textAlign: TextAlign.right),
            ),
            Expanded(
              flex: expandedFlex[3],
              child: Text(
                  "${global.moneyFormatAndDot.format(bill.amountBeforeCalcVat)} ${global.language("money_baht")}",
                  style: headerStyle,
                  textAlign: TextAlign.right),
            ),
          ]));
        }

        if (bill.totalVatAmount != 0) {
          orderList.add(Row(children: [
            Expanded(
              flex: expandedFlex[0],
              child: Container(),
            ),
            Expanded(
              flex: expandedFlex[1] + expandedFlex[2],
              child: Text(
                  "${global.language("vat")} : ${global.moneyFormat.format(global.shopProfile!.orderstation.vatrate)}%",
                  style: headerStyle,
                  textAlign: TextAlign.right),
            ),
            Expanded(
              flex: expandedFlex[3],
              child: Text(
                  "${global.moneyFormatAndDot.format(bill.totalVatAmount)} ${global.language("money_baht")}",
                  style: headerStyle,
                  textAlign: TextAlign.right),
            ),
          ]));
        }
        if (bill.amountAfterCalcVat != 0) {
          orderList.add(Row(children: [
            Expanded(
              flex: expandedFlex[0],
              child: Container(),
            ),
            Expanded(
              flex: expandedFlex[1] + expandedFlex[2],
              child: Text(global.language("after_vat"),
                  style: headerStyle, textAlign: TextAlign.right),
            ),
            Expanded(
              flex: expandedFlex[3],
              child: Text(
                  "${global.moneyFormatAndDot.format(bill.amountAfterCalcVat)} ${global.language("money_baht")}",
                  style: headerStyle,
                  textAlign: TextAlign.right),
            ),
          ]));
        }

        if (bill.amountExceptVat != 0) {
          orderList.add(Row(children: [
            Expanded(
              flex: expandedFlex[0],
              child: Container(),
            ),
            Expanded(
              flex: expandedFlex[1] + expandedFlex[2],
              child: Text("${global.language("total_item_except_vat_amount")} ",
                  style: headerStyle, textAlign: TextAlign.right),
            ),
            Expanded(
              flex: expandedFlex[3],
              // แก้ไขตรงนี้: ใช้ amountExceptVat แทน totalItemExceptVatAmount
              child: Text(
                  "${global.moneyFormatAndDot.format(bill.amountExceptVat)} ${global.language("money_baht")}",
                  style: headerStyle,
                  textAlign: TextAlign.right),
            ),
          ]));
        }
      }

      if (bill.shippingAmount != 0) {
        orderList.add(Row(children: [
          Expanded(
            flex: expandedFlex[0],
            child: Container(),
          ),
          Expanded(
            flex: expandedFlex[1] + expandedFlex[2],
            child: Text(global.language("shipping_cost"),
                style: headerStyle, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: expandedFlex[3],
            child: Text(
                "${global.moneyFormatAndDot.format(bill.shippingAmount)} ${global.language("money_baht")}",
                style: headerStyle,
                textAlign: TextAlign.right),
          ),
        ]));
      }
      if (bill.roundAmount != 0) {
        orderList.add(Row(children: [
          Expanded(
            flex: expandedFlex[0],
            child: Container(),
          ),
          Expanded(
            flex: expandedFlex[1] + expandedFlex[2],
            child: Text(global.language("round_money"),
                style: headerStyle, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: expandedFlex[3],
            child: Text(
                "${global.moneyFormatAndDot.format(bill.roundAmount)} ${global.language("money_baht")}",
                style: headerStyle,
                textAlign: TextAlign.right),
          ),
        ]));
      }
      // แสดงส่วนลด/ยอดชำระจากแต้มสะสม
      if (pointsUsed > 0 && (pointsDiscount > 0 || pointsPayment > 0)) {
        String pointLabel = '';
        double pointDeduction = 0;

        if (pointUsageType == 1) {
          // pointusagetype = 1: ใช้เป็นส่วนลด
          pointLabel = global.language("points_discount");
          pointDeduction = pointsDiscount;
        } else {
          // pointusagetype = 2: ใช้เป็นการชำระเงิน
          pointLabel = "ชำระด้วยแต้ม";
          pointDeduction = pointsPayment;
        }

        orderList.add(Row(children: [
          Expanded(
            flex: expandedFlex[0],
            child: Container(),
          ),
          Expanded(
            flex: expandedFlex[1] + expandedFlex[2],
            child: Text(
                "$pointLabel (${global.moneyFormat.format(pointsUsed)} ${global.language("points")})",
                style: headerStyle.copyWith(color: Colors.green.shade700),
                textAlign: TextAlign.right),
          ),
          Expanded(
            flex: expandedFlex[3],
            child: Text(
                "-${global.moneyFormatAndDot.format(pointDeduction)} ${global.language("money_baht")}",
                style: headerStyle.copyWith(color: Colors.green.shade700),
                textAlign: TextAlign.right),
          ),
        ]));
      }
      // แสดงแต้มที่จะได้รับจากการซื้อ (ถ้าเป็นสมาชิก)
      if (global.isMember && earnedPoints > 0) {
        orderList.add(Row(children: [
          Expanded(
            flex: expandedFlex[0],
            child: Container(),
          ),
          Expanded(
            flex: expandedFlex[1] + expandedFlex[2],
            child: Text("แต้มที่จะได้รับ",
                style: headerStyle.copyWith(color: Colors.amber.shade700),
                textAlign: TextAlign.right),
          ),
          Expanded(
            flex: expandedFlex[3],
            child: Text(
                "+${global.moneyFormat.format(earnedPoints)} ${global.language("points")}",
                style: headerStyle.copyWith(color: Colors.amber.shade700),
                textAlign: TextAlign.right),
          ),
        ]));
      }
      orderList.add(Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey, width: 1),
              bottom: BorderSide(color: Colors.grey, width: 1),
            ),
          ),
          child: Row(children: [
            Expanded(
              flex: expandedFlex[0],
              child: Container(),
            ),
            Expanded(
              flex: expandedFlex[1] + expandedFlex[2],
              child: Text(global.language("payment_amount"),
                  style: headerStyle, textAlign: TextAlign.right),
            ),
            Expanded(
              flex: expandedFlex[3],
              child: Text(
                  "${global.moneyFormatAndDot.format(bill.totalAmount)} ${global.language("money_baht")}",
                  style: headerStyle,
                  textAlign: TextAlign.right),
            ),
          ])));
      if (bill.saveAmount != 0) {
        orderList.add(Row(children: [
          Expanded(
            flex: expandedFlex[0],
            child: Container(),
          ),
          Expanded(
            flex: expandedFlex[1] + expandedFlex[2],
            child: Text(global.language("save_amount"),
                style: headerStyle, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: expandedFlex[3],
            child: Text(
                "${global.moneyFormatAndDot.format(bill.saveAmount)} ${global.language("money_baht")}",
                style: headerStyle,
                textAlign: TextAlign.right),
          ),
        ]));
      }
    }

    return orderList;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClickHouseOrderTempBloc, ClickHouseOrderTempState>(
      listener: (context, state) {
        if (state is ClickHouseOrderTempLoadSuccess) {
          context
              .read<ClickHouseOrderTempBloc>()
              .add(ClickHouseOrderTempLoadFinish());
          orderTempDetailList.clear();
          for (var order in state.clickHouseOrderTemp) {
            for (var detail in order.orderDetails) {
              orderTempDetailList.add(detail);
            }
          }
          recalc();
          // BC Member: ดึง get_point จาก API
          if (global.shopProfile?.isbcmember == true) {
            _fetchBCMemberPoints();
          }
          setState(() {});
          // Show flash animation when cart changes
          if (orderTempDetailList.isNotEmpty) {
            _showFlashAnimation();
          }
        }
      },
      child: Scaffold(
        // appBar: AppBar(
        //   automaticallyImplyLeading: false,
        //   backgroundColor: Colors.white,
        //   elevation: 0,
        //   shadowColor: Colors.black.withOpacity(0.1),
        //   title: Row(
        //     children: [
        //       Container(
        //         decoration: BoxDecoration(
        //           color: Colors.grey.shade100,
        //           borderRadius: BorderRadius.circular(8),
        //         ),
        //         child: IconButton(
        //           onPressed: () {
        //             Navigator.pop(context);
        //           },
        //           icon: Icon(Icons.arrow_back_ios, color: Colors.grey.shade700),
        //         ),
        //       ),
        //       const SizedBox(width: 12),
        //       Expanded(
        //         child: Text(
        //           (widget.barcode.isEmpty) ? global.language("order_list") : global.getNameFromLanguage(product.names, global.languageForCustomer),
        //           style: const TextStyle(
        //             color: Colors.black87,
        //             fontSize: 20,
        //             fontWeight: FontWeight.bold,
        //           ),
        //         ),
        //       ),
        //       // Cart summary badge
        //       if (orderTempDetailList.isNotEmpty)
        //         Container(
        //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        //           decoration: BoxDecoration(
        //             gradient: LinearGradient(
        //               colors: [Colors.blue.shade400, Colors.blue.shade600],
        //             ),
        //             borderRadius: BorderRadius.circular(20),
        //           ),
        //           child: Row(
        //             mainAxisSize: MainAxisSize.min,
        //             children: [
        //               const Icon(Icons.shopping_cart, color: Colors.white, size: 16),
        //               const SizedBox(width: 4),
        //               Text(
        //                 "${orderTempDetailList.length} รายการ",
        //                 style: const TextStyle(
        //                   color: Colors.white,
        //                   fontSize: 12,
        //                   fontWeight: FontWeight.w600,
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ),        //     ],
        //   ),
        // ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5EBE0), // สีอิฐบ้านเชียง
              ),
              child: Column(
                children: [
                  _buildHeaderSection(),
                  // Member Info Section
                  _buildMemberInfoSection(),
                  // Scrollable Products List
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        return SingleChildScrollView(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          child: orderProductsList(
                              context: context,
                              orderTempList: orderTempDetailList,
                              refresh: reload),
                        );
                      },
                    ),
                  ),

                  // Fixed Summary Section at Bottom - Collapsible
                  if (orderTempDetailList.isNotEmpty &&
                      (widget.barcode.isEmpty || widget.mode == 9))
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        final isTablet = constraints.maxWidth >= 600 &&
                            constraints.maxWidth < 900;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                offset: const Offset(0, -4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Toggle Button Header
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _isSummaryExpanded = !_isSummaryExpanded;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 16 : 20,
                                    vertical: isMobile ? 12 : 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFC72C)
                                        .withOpacity(0.1),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: _isSummaryExpanded
                                            ? Colors.grey.shade200
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.receipt_long,
                                            color: Color(0xFFDA291C),
                                            size: isMobile ? 22 : 30,
                                          ),
                                          SizedBox(width: isMobile ? 8 : 12),
                                          Text(
                                            global.language("order_summary"),
                                            style: TextStyle(
                                              fontSize: isMobile
                                                  ? 14
                                                  : (isTablet ? 20 : 30),
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          SizedBox(width: isMobile ? 8 : 12),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isMobile ? 8 : 10,
                                              vertical: isMobile ? 3 : 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFDA291C),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              "${orderTempDetailList.length} ${global.language("items")}",
                                              style: TextStyle(
                                                fontSize: isMobile ? 15 : 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            "${global.moneyFormatAndDot.format(bill.totalAmount)} ฿",
                                            style: TextStyle(
                                              fontSize: isMobile
                                                  ? 16
                                                  : (isTablet ? 30 : 35),
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFDA291C),
                                            ),
                                          ),
                                          SizedBox(width: isMobile ? 6 : 8),
                                          AnimatedRotation(
                                            turns: _isSummaryExpanded ? 0.5 : 0,
                                            duration: const Duration(
                                                milliseconds: 200),
                                            child: Icon(
                                              Icons.keyboard_arrow_up,
                                              color: Colors.grey.shade600,
                                              size: isMobile ? 26 : 30,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Expandable Content
                              AnimatedCrossFade(
                                firstChild: const SizedBox.shrink(),
                                secondChild: SafeArea(
                                  top: false,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      maxHeight:
                                          MediaQuery.of(context).size.height *
                                              0.4,
                                    ),
                                    child: SingleChildScrollView(
                                      padding:
                                          EdgeInsets.all(isMobile ? 12 : 16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: orderSummaryList(
                                            context: context,
                                            orderTempList: orderTempDetailList),
                                      ),
                                    ),
                                  ),
                                ),
                                crossFadeState: _isSummaryExpanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 250),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            // Flash Animation Overlay
            _buildFlashOverlay(),
          ],
        ),
        bottomNavigationBar: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive sizing
            final isMobile = constraints.maxWidth < 600;
            final isTablet =
                constraints.maxWidth >= 600 && constraints.maxWidth < 900;
            final buttonHeight = isMobile ? 56.0 : (isTablet ? 85.0 : 90.0);
            final fontSize = isMobile ? 16.0 : (isTablet ? 26.0 : 30.0);
            final iconSize = isMobile ? 20.0 : (isTablet ? 26.0 : 30.0);
            final horizontalPadding =
                isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isMobile ? 12 : 16,
                  ),
                  child: Row(
                    children: [
                      // ปุ่มกลับ - Minimalist
                      Expanded(
                        flex: isMobile ? 2 : 3,
                        child: SizedBox(
                          height: buttonHeight,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.arrow_back,
                                color: Colors.grey.shade700, size: iconSize),
                            label: isMobile
                                ? const SizedBox.shrink()
                                : Text(
                                    global.language("back"),
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 16 : 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: isMobile ? 12 : 16),

                      // ปุ่มชำระเงิน - Modern & Clean
                      if (widget.barcode.isEmpty &&
                          orderTempDetailList.isNotEmpty)
                        Expanded(
                          flex: isMobile ? 5 : 7,
                          child: SizedBox(
                            height: buttonHeight,
                            child: ElevatedButton.icon(
                              onPressed: _isPaying
                                  ? null
                                  : () async {
                                      // ป้องกันกดจ่ายซ้ำระหว่าง payAndSave ทำงานอยู่
                                      setState(() => _isPaying = true);
                                      try {
                                        global.countDownForHome =
                                            global.countDownForHomeMax;
                                        if (widget.mode == 0 ||
                                            widget.mode == 9) {
                                          // จ่ายก่อนกิน หรือ กินก่อนจ่าย (ชำระเงิน)
                                          global.textToSpeech(global.findLanguage(
                                              code:
                                                  "please_select_serve_number_service",
                                              languageCode:
                                                  global.languageForCustomer));
                                          String orderTagNumber = "";
                                          if (widget.mode == 0) {
                                            // เลือก โต๊ะ หรือ ป้ายบริการ
                                            orderTagNumber = await global
                                                .selectOrderTagNumberOrTableNumber(
                                                    context: context);
                                          } else {
                                            orderTagNumber = global
                                                .tableNumberSelected
                                                .ordertagnumber;
                                          }
                                          String message = "";
                                          if (orderTagNumber.isNotEmpty) {
                                            message =
                                                "${global.findLanguage(code: "select_serve_number", languageCode: global.languageForCustomer)} $orderTagNumber";
                                          }
                                          message += " ";
                                          message += global.findLanguage(
                                              code: "total_money",
                                              languageCode:
                                                  global.languageForCustomer);
                                          message += " ";
                                          message += global.moneyFormat.format(
                                              sumOrderAmount -
                                                  (discountAmount -
                                                      diffAmount));
                                          message += " ";
                                          message += global.findLanguage(
                                              code: "money_baht",
                                              languageCode:
                                                  global.languageForCustomer);
                                          message += " ";
                                          message += global.findLanguage(
                                              code: "select_pay_type",
                                              languageCode:
                                                  global.languageForCustomer);
                                          global.textToSpeech(message);
                                          if (context.mounted &&
                                              (orderTagNumber.isNotEmpty ||
                                                  global.orderTagNumbers
                                                      .isEmpty)) {
                                            // ===== Choice screen: จ่ายทันที vs จ่ายที่ Cashier =====
                                            // เฉพาะ staff device (machineCondition==0) เท่านั้นที่เห็นตัวเลือก
                                            // customer device ข้ามไป payNow ทันที
                                            bool useCashier =
                                                widget.mode == 0 &&
                                                    global.deviceConfig
                                                            .machineCondition ==
                                                        0;
                                            if (useCashier && context.mounted) {
                                              final choice =
                                                  await PaymentChoiceDialog
                                                      .show(
                                                context,
                                                totalAmount: bill.totalAmount,
                                                orderTagNumber: orderTagNumber,
                                              );
                                              if (choice ==
                                                  PaymentChoice.cancel) {
                                                return; // ออกจาก onPressed
                                              }
                                              if (choice ==
                                                  PaymentChoice.payAtCashier) {
                                                await payAndSave(
                                                    totalAmount:
                                                        bill.totalAmount,
                                                    vatAmount: vatAmount,
                                                    saveAmount: saveAmount,
                                                    discountAmount:
                                                        discountAmount,
                                                    discountWord: discountWord,
                                                    diffAmount: diffAmount,
                                                    orderTagNumber:
                                                        orderTagNumber,
                                                    context: context,
                                                    payNow: true,
                                                    payAtCashier: true,
                                                    orderTempDetailList:
                                                        orderTempDetailList,
                                                    bill: bill);
                                                return;
                                              }
                                            }
                                            await payAndSave(
                                                totalAmount: bill.totalAmount,
                                                vatAmount: vatAmount,
                                                saveAmount: saveAmount,
                                                discountAmount: discountAmount,
                                                discountWord: discountWord,
                                                diffAmount: diffAmount,
                                                orderTagNumber: orderTagNumber,
                                                context: context,
                                                payNow: true,
                                                orderTempDetailList:
                                                    orderTempDetailList,
                                                bill: bill);
                                          }
                                        } else if (widget.mode == 1) {
                                          // กินก่อนจ่าย (Hold รายการ) ไม่แสดงหน้าจ่ายเงิน
                                          if (context.mounted) {
                                            await payAndSave(
                                                totalAmount: bill.totalAmount,
                                                vatAmount: vatAmount,
                                                saveAmount: saveAmount,
                                                discountAmount: discountAmount,
                                                discountWord: discountWord,
                                                diffAmount: diffAmount,
                                                orderTagNumber: global
                                                    .tableNumberSelected
                                                    .ordertagnumber,
                                                context: context,
                                                payNow: false,
                                                orderTempDetailList:
                                                    orderTempDetailList,
                                                bill: bill);
                                          }
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isPaying = false);
                                        }
                                      }
                                    },
                              icon: badges.Badge(
                                position: badges.BadgePosition.topEnd(
                                    top: -5, end: -5),
                                badgeContent: Text(
                                  global.moneyFormat.format(sumOrderQty),
                                  style: TextStyle(
                                    color: global.primaryTextColor,
                                    fontSize: isMobile ? 12 : 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: Icon(Icons.payment,
                                    size: iconSize,
                                    color: global.primaryTextColor),
                              ),
                              label: Text(
                                (widget.mode == 0 || widget.mode == 9)
                                    ? '${global.language("payment_amount")}: ${global.moneyFormatAndDot.format(bill.totalAmount)} ฿'
                                    : '${global.language("total_amount")}: ${global.moneyFormatAndDot.format(bill.totalAmount)} ฿',
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: global.primaryTextColor,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    global.primaryThemeColor, // McDonald's red
                                foregroundColor: global.primaryTextColor,
                                disabledBackgroundColor: Colors.grey.shade300,
                                disabledForegroundColor: Colors.grey.shade500,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 16 : 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
