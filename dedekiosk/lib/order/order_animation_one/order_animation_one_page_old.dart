import 'dart:math';

import 'package:badges/badges.dart' as badges;
import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedekiosk/bloc/order_temp_bloc.dart';
import 'package:dedekiosk/model/category_model.dart';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/model/product_model.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/order/order_animation_one/order_animation_one_cart_page.dart';
import 'package:dedekiosk/order/order_animation_one/order_animation_one_util.dart';
import 'package:dedekiosk/page/order_select_page.dart';
import 'package:dedekiosk/page/select_language_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/order/order_util.dart' as util;
import 'package:dedekiosk/util/api.dart' as api;

class OrderAnimationOnePage extends StatefulWidget {
  const OrderAnimationOnePage({super.key});

  @override
  OrderAnimationOnePageState createState() => OrderAnimationOnePageState();
}

class OrderAnimationOnePageState extends State<OrderAnimationOnePage> with TickerProviderStateMixin {
  String oldProductListValue = "";
  List<Widget> productListWidget = [];
  bool loadProductProcessSuccess = false;
  TextEditingController searchController = TextEditingController();
  List<OrderTempDetailModel> orderTempDetailList = [];
  List<OrderTempDetailModel> orderTempSumByBarcodeList = [];
  Timer? _productReloadDebouncer;
  Timer? _searchDebouncer;
  bool _isLoadingProducts = false;
  Map<String, List<ProductProcessModel>> _productCache = {};
  DateTime _lastProductReloadTime = DateTime.now();

  late Timer timerCountDown;
  late Timer timerLoadProcess;
  double sumOrderQty = 0;
  double sumOrderAmount = 0;
  int machineCount = 0;
  int timeInterval = 0;
  String _searchQuery = "";
  bool isSearch = false;
  bool showCartMode = false;
  List<GlobalKey> categoryKeyList = <GlobalKey>[];
  int? previousIndex;
  final ScrollController productScrollController = ScrollController();
  bool productScrolling = false;
  bool isPortrait = true;
  String productSelectedBarcode = "";
  late ProductProcessModel productSelected;
  Widget productGridView = Container();
  List<Shadow> textStyleWhiteShadow = [
    const Shadow(
      color: Colors.white,
      offset: Offset(0, 0),
      blurRadius: 2,
    ),
    const Shadow(
      color: Colors.white,
      offset: Offset(0, 0),
      blurRadius: 2,
    ),
    const Shadow(
      color: Colors.white,
      offset: Offset(0, 0),
      blurRadius: 2,
    ),
    const Shadow(
      color: Colors.white,
      offset: Offset(0, 0),
      blurRadius: 2,
    ),
  ];
  double categoryWidth = 160;
  var styleBlackBorderShadow = [
    const Shadow(
      blurRadius: 1.0,
      color: Colors.black,
      offset: Offset(1.0, 1.0),
    ),
    const Shadow(
      blurRadius: 1.0,
      color: Colors.black,
      offset: Offset(-1.0, 1.0),
    ),
    const Shadow(
      blurRadius: 1.0,
      color: Colors.black,
      offset: Offset(1.0, -1.0),
    ),
    const Shadow(
      blurRadius: 1.0,
      color: Colors.black,
      offset: Offset(-1.0, -1.0),
    ),
  ];

  void productScrollToTop() {
    productScrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    productScrolling = false;
  }

  // void reloadProductList() {
  //   loadProductProcessSuccess = true;
  //   var jsonNewProductListValue = jsonEncode(global.productList);
  //   if (oldProductListValue != jsonNewProductListValue) {
  //     oldProductListValue = jsonNewProductListValue;
  //     productListWidget = [];
  //   }
  //   generateGridView();
  // }

  void reloadProductList() {
    // ยกเลิกการโหลดที่กำลังรอดำเนินการ
    _productReloadDebouncer?.cancel();

    // รอสักครู่ก่อนประมวลผลเพื่อป้องกันการทำงานซ้ำบ่อยเกินไป
    _productReloadDebouncer = Timer(const Duration(milliseconds: 300), () {
      if (_isLoadingProducts) return; // ป้องกันการทำงานซ้ำซ้อน

      _isLoadingProducts = true;

      try {
        loadProductProcessSuccess = true;

        // เปรียบเทียบข้อมูลเพื่อตรวจสอบการเปลี่ยนแปลง
        var jsonNewProductListValue = jsonEncode(global.productList);

        if (oldProductListValue != jsonNewProductListValue) {
          // มีการเปลี่ยนแปลงข้อมูล
          oldProductListValue = jsonNewProductListValue;

          if (mounted) {
            // สร้าง widget ใหม่
            generateGridView();
          }
        } else {
          // ข้อมูลไม่เปลี่ยนแปลง ไม่จำเป็นต้องสร้าง widget ใหม่
          if (kDebugMode) {
            print("ข้อมูลไม่เปลี่ยนแปลง ข้ามการสร้าง widget ใหม่");
          }
        }
      } catch (e, s) {
        if (kDebugMode) {
          print("เกิดข้อผิดพลาดในการโหลดสินค้า: $e");
          print(s);
        }
        loadProductProcessSuccess = false;
      } finally {
        _isLoadingProducts = false;
      }
    });
  }

  void backToHome() {
    // ล้างข้อมูลเก่าทิ้ง
    global.objectBoxStore.box<OrderTempObjectBoxModel>().removeAll();
    if (global.deviceConfig.machineCondition == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/order_select', (Route<dynamic> route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/', (Route<dynamic> route) => false);
    }
  }

  @override
  void initState() {
    super.initState();
    global.categoryIndex = 0;
    global.countDownForHome = global.countDownForHomeMax;
    context.read<OrderTempBloc>().add(OrderTempLoadStart(barcode: "", isTakeAway: global.orderType));
    timerCountDown = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      // กลับหน้าแรก ถ้าไม่ทำอะไรใน 5 นาที
      global.countDownForHome--;
      if (global.countDownForHome <= 0) {
        global.countDownForHome = global.countDownForHomeMax;
        backToHome();
      }
    });
    timerLoadProcess = Timer.periodic(const Duration(seconds: 10), (Timer t) async {
      // ดึงสถานะสินค้าจาก server
      api.reloadProductProcessFromServer().then((_) {
        reloadProductList();
      });
    });
    // api.reloadProductProcessFromServer().then((_) {
    //   reloadProductList();
    // });
    searchController.addListener(_onSearchChanged);

    // เรียก preload รูปภาพหลังจาก render แล้ว
    WidgetsBinding.instance.addPostFrameCallback((_) {
      preloadImagesForCurrentCategory();
    });

    // productScrollController.addListener(() {
    //   FocusScope.of(context).requestFocus(FocusNode());
    // });
  }

  void _onSearchChanged() {
    // ยกเลิก timer เดิม (ถ้ามี)
    if (_searchDebouncer?.isActive ?? false) {
      _searchDebouncer!.cancel();
    }

    // ตั้ง timer ใหม่ให้เรียก generateGridView หลังจาก 2 วินาที
    _searchDebouncer = Timer(const Duration(milliseconds: 2000), () {
      // เรียก generateGridView เมื่อครบเวลาที่กำหนด
      generateGridView();
    });
  }

  @override
  void dispose() {
    timerCountDown.cancel();
    timerLoadProcess.cancel();
    productScrollController.dispose();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _searchDebouncer?.cancel();

    super.dispose();
  }

  void refresh() {
    context.read<OrderTempBloc>().add(OrderTempLoadStart(barcode: "", isTakeAway: global.orderType));
  }

  Widget productPackOption(String optionJsonStr) {
    if (optionJsonStr.isEmpty) {
      return Container();
    }
    List<ProductProcessOptionModel> optionList = (jsonDecode(optionJsonStr) as List).map((e) => ProductProcessOptionModel.fromJson(e)).toList();
    List<Widget> result = [];
    for (int optionIndex = 0; optionIndex < optionList.length; optionIndex++) {
      bool isSelected = false;
      for (int choiceIndex = 0; choiceIndex < optionList[optionIndex].choices.length; choiceIndex++) {
        if (optionList[optionIndex].choices[choiceIndex].selected) {
          isSelected = true;
          break;
        }
      }
      if (isSelected) {
        result.add(
          Text(global.getNameFromLanguage(optionList[optionIndex].names, global.languageForCustomer), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        );
        for (int choiceIndex = 0; choiceIndex < optionList[optionIndex].choices.length; choiceIndex++) {
          if (optionList[optionIndex].choices[choiceIndex].selected) {
            result.add(Row(
              children: [
                Text(" - ${global.getNameFromLanguage(optionList[optionIndex].choices[choiceIndex].names, global.languageForCustomer)}", style: const TextStyle(fontSize: 12)),
                if (optionList[optionIndex].choices[choiceIndex].price.isNotEmpty)
                  Text(" ${global.language("add_money")}  ${optionList[optionIndex].choices[choiceIndex].price} ${global.language("money_baht")}",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ));
          }
        }
      }
    }
    return SizedBox(width: double.infinity, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: result));
  }

  Widget buildProductItem(ProductProcessModel product) {
    // สร้าง widget ของสินค้าแต่ละชิ้น
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // จัดการเมื่อกดที่สินค้า
          // selectProduct(product);
        },
        child: Card(
          color: product.issell ? Colors.white : Colors.grey.shade300,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // รูปภาพสินค้า
                product.imageuri.isNotEmpty
                    ? Image.network(
                        product.imageuri,
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 80,
                            width: 80,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      )
                    : Container(
                        height: 80,
                        width: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image),
                      ),

                const SizedBox(height: 8),

                // ชื่อสินค้า
                Text(
                  global.getNameFromLanguage(product.names, global.languageForCustomer),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                // ราคาสินค้า
                Text(
                  '฿${product.setprice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),

                // แสดงสถานะสต็อก (ถ้าใช้ระบบสต็อก)
                if (product.isstockforrestaurant)
                  Text(
                    'คงเหลือ: ${product.stockqty.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: product.stockqty > 0 ? Colors.green : Colors.red,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget dataProductBody(CategoryCodeListModel data) {
    Widget productIsNotReady = Container();
    int productSelectedIndex = global.findProductByBarcode(data.barcode);
    if (productSelectedIndex == -1) {
      return Container();
    }
    String kitchenPrinter = "";
    String kitchenPrinterName = "";
    if (global.deviceConfig.machineCondition == 0 && global.shopProfile!.kitchens != null) {
      for (var kitchen in global.shopProfile!.kitchens!) {
        for (var barcode in kitchen.products) {
          if (barcode == global.productList[productSelectedIndex].barcode) {
            kitchenPrinter = kitchen.code;
            kitchenPrinterName = global.getNameFromLanguage(kitchen.names, global.languageForCustomer);
            break;
          }
        }
      }
    }

    // สินค้าหยุดขาย หรือสินค้าหมด
    bool productIsReady = global.productList[productSelectedIndex].issell;
    if (global.productList[productSelectedIndex].isstockforrestaurant == true && global.productList[productSelectedIndex].stockqty <= 0) {
      productIsReady = false;
    }

    if (productIsReady == false && loadProductProcessSuccess) {
      if (global.productList[productSelectedIndex].issell == false) {
        // หยุดขายชั่วคราว
        productIsNotReady = Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.5),
          ),
          child: FittedBox(
              child: Text(
            global.language("pause_sale"),
            style: TextStyle(color: Colors.red, fontSize: 32, fontWeight: FontWeight.bold, shadows: textStyleWhiteShadow),
          )),
        );
      } else {
        if (global.productList[productSelectedIndex].isstockforrestaurant == true && global.productList[productSelectedIndex].stockqty <= 0) {
          // สินค้าหมด
          productIsNotReady = Container(
            padding: const EdgeInsets.all(4),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.5),
            ),
            child: FittedBox(
                child: Text(
              global.language("all_gone"),
              style: TextStyle(color: Colors.red, fontSize: 32, fontWeight: FontWeight.bold, shadows: textStyleWhiteShadow),
            )),
          );
        }
      }
    }
    var button = ElevatedButton(
      style: ElevatedButton.styleFrom(
        shadowColor: Colors.grey.shade100,
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.only(bottom: 4),
      ),
      onPressed: (global.orderType == 5 || global.orderType == 6)
          ? null
          : (productIsReady == false || global.findProductPrice(prices: global.productList[productSelectedIndex].prices) == 0)
              ? null
              : () async {
                  global.countDownForHome = global.countDownForHomeMax;
                  productSelectedBarcode = "";
                  productSelectedBarcode = data.barcode;
                  productSelected = global.productList[productSelectedIndex];
                  productSelected.qty = 1;
                  // clear
                  productSelected.remark = "";
                  for (int optionIndex = 0; optionIndex < productSelected.options.length; optionIndex++) {
                    for (int choiceIndex = 0; choiceIndex < productSelected.options[optionIndex].choices.length; choiceIndex++) {
                      productSelected.options[optionIndex].choices[choiceIndex].selected = false;
                    }
                  }
                  setState(() {
                    if (global.priceIndex == 2) {
                      productSelected.setprice = global.findProductPrice(prices: productSelected.prices);
                    }
                  });

                  if (mounted) {
                    await showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(builder: (context, StateSetter setState) {
                            String message = global.getNameFromLanguage(productSelected.names, global.languageForCustomer);
                            if (productSelected.options.isNotEmpty) {
                              message += " กรุณาเลือกเงื่อนไข และ";
                            }
                            message += " กดยืนยันเพื่อสั่ง";
                            global.textToSpeech(message);
                            return AlertDialog(
                              contentPadding: const EdgeInsets.all(8),
                              content: StatefulBuilder(builder: (context, StateSetter setState) {
                                return orderAnimationOneProductOptionWidget(
                                  orderGuid: "",
                                  calcStockQty: false,
                                  isAppend: true,
                                  context: context,
                                  product: productSelected,
                                  refresh: () {
                                    setState(() {});
                                  },
                                  onClose: () async {
                                    Navigator.pop(context);
                                    productListWidget = [];
                                    productSelectedBarcode = "";
                                    refresh();
                                  },
                                );
                              }),
                            );
                          });
                        });
                  }
                },
      child: Stack(
        children: [
          Column(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: data.imageurl != null && data.imageurl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: data.imageurl,
                        fit: BoxFit.fill,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.grey[200],
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
                        //resize the image

                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          width: double.infinity,
                          height: double.infinity,
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                        // ใช้ memCacheWidth และ memCacheHeight เพื่อลดการใช้หน่วยความจำ
                        memCacheWidth: 300, // ปรับตามขนาดที่แสดงจริง
                        memCacheHeight: 300,
                        // กำหนดการ fade in animation
                        fadeInDuration: const Duration(milliseconds: 200),
                      )
                    : Container(
                        color: Colors.grey[200],
                        width: double.infinity,
                        height: double.infinity,
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
              ),
            ),
            Container(
              width: double.infinity, // ทำให้กว้างเต็มพื้นที่
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
              child: Center(
                  child: Text(
                global.getNameFromLanguage(data.names, global.languageForCustomer),
                style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold, shadows: textStyleWhiteShadow),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )),
            ),
            if (data.discountword!.isNotEmpty && global.priceIndex == 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(children: [
                      TextSpan(
                          text: "${global.language("from_price")} ",
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          )),
                      TextSpan(text: global.moneyFormat.format(data.setprice), style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold, shadows: textStyleWhiteShadow)),
                      const TextSpan(
                          text: " ",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          )),
                      TextSpan(
                          text: global.language("money_baht"),
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          )),
                      const TextSpan(
                          text: "/",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          )),
                      TextSpan(
                          text: global.getNameFromLanguage(data.unitnames, global.languageForCustomer),
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          )),
                    ])),
              ),
            if (data.discountword!.isNotEmpty && global.priceIndex == 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  "${global.language("discount")} ${data.discountword}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(children: [
                    if (data.discountword!.isNotEmpty && global.priceIndex == 1)
                      TextSpan(
                          text: "${global.language("after_discount")} ",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                          )),
                    TextSpan(
                        text: global.moneyFormat.format(global.findProductPrice(prices: data.prices!)),
                        style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold, shadows: textStyleWhiteShadow)),
                    const TextSpan(
                        text: " ",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        )),
                    TextSpan(
                        text: global.language("money_baht"),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        )),
                    const TextSpan(
                        text: "/",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        )),
                    TextSpan(
                        text: global.getNameFromLanguage(data.unitnames, global.languageForCustomer),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        )),
                  ])),
            ),
            if (global.productList[productSelectedIndex].isstockforrestaurant == true)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  "${global.language("after_discount")} ${global.moneyFormat.format(global.productList[productSelectedIndex].stockqty)} ${global.getNameFromLanguage(global.productList[productSelectedIndex].unitnames, global.languageForCustomer)}",
                  style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold, shadows: textStyleWhiteShadow),
                  textAlign: TextAlign.center,
                ),
              ),
            if (global.deviceConfig.machineCondition == 0)
              if (kitchenPrinter.isEmpty)
                const Icon(Icons.print_disabled, color: Colors.red)
              else
                Text(
                  "$kitchenPrinterName : $kitchenPrinter",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
            if (global.deviceConfig.machineCondition == 0)
              Text(
                (global.productList[productSelectedIndex].foodtype == 0) ? global.language("food") : global.language("beverage"),
                style: TextStyle(
                  color: (global.productList[productSelectedIndex].foodtype == 0) ? Colors.green : Colors.blue,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
          ]),
          Positioned(
            top: 8,
            right: 8,
            child: (data.orderqty == null || data.orderqty == 0)
                ? Container()
                : SizedBox(
                    width: 30,
                    height: 30,
                    child: badges.Badge(
                      badgeStyle: const badges.BadgeStyle(
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                      badgeContent: Center(
                          child: Text(
                        global.moneyFormat.format(data.orderqty),
                        style: const TextStyle(color: Colors.white),
                      )),
                    )),
          ),
          // สถานะไม่พร้อมขาย
          if (productIsReady == false) Positioned.fill(child: productIsNotReady),
          // ปรับปรุงสถานะ
          if (global.orderType == 5)
            Positioned.fill(
              child: InkWell(
                  onTap: () async {
                    if (global.productList[productSelectedIndex].issell == true) {
                      // หยุดขายชั่วคราว
                      await api.clickHouseExecute(
                          "INSERT INTO ${global.clickHouseDatabaseName}.ordertempbarcodecancel (shopid,branchid,barcode) VALUES ('${global.deviceConfig.shopId}', '${global.deviceConfig.branchId}', '${global.productList[productSelectedIndex].barcode}')");
                      global.productList[productSelectedIndex].issell = false;
                    } else {
                      // เริ่มขายอีกครั้ง
                      await api.clickHouseExecute(
                          "alter table ${global.clickHouseDatabaseName}.ordertempbarcodecancel delete where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and barcode='${global.productList[productSelectedIndex].barcode}'");
                      global.productList[productSelectedIndex].issell = true;
                    }
                    productListWidget = [];
                    generateGridView();
                    setState(() {});
                  },
                  child: (global.productList[productSelectedIndex].issell == false)
                      ? Container()
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                              child: Text(
                            global.language("is_open"),
                            style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold, shadows: textStyleWhiteShadow),
                          )))),
            ),
        ],
      ),
    );
    return (global.orderType == 6 && global.productList[productSelectedIndex].isstockforrestaurant == true)
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: button),
              ElevatedButton.icon(
                onPressed: () async {
                  await updateQty(0, productSelectedIndex);
                },
                icon: const Icon(Icons.update),
                label: Column(children: [Text(global.language("change")), Text(global.language("qty_balance"))]),
              ),
              ElevatedButton.icon(
                  onPressed: () async {
                    await updateQty(1, productSelectedIndex);
                  },
                  icon: const Icon(Icons.add),
                  label: Text(global.language("replenish_products"))),
            ],
          )
        : button;
  }

  void preloadImagesForCurrentCategory() {
    if (global.categoryIndex == -1 || global.categoryList.isEmpty) return;

    final products = global.categoryList[global.categoryIndex].codelist;
    if (products.isEmpty) return;

    // Preload เฉพาะรูปภาพที่มีโอกาสจะถูกแสดงในหน้าจอเร็วๆ นี้
    // จำกัดจำนวนรูปที่จะ preload เพื่อไม่ให้ใช้ทรัพยากรมากเกินไป
    final preloadCount = min(10, products.length);

    for (int i = 0; i < preloadCount; i++) {
      final product = products[i];
      if (product.imageurl != null && product.imageurl.isNotEmpty) {
        // ใช้ precacheImage เพื่อโหลดรูปภาพเข้า cache
        precacheImage(
          CachedNetworkImageProvider(product.imageurl),
          context,
          size: const Size(300, 300), // ปรับตามขนาดที่ใช้จริง
        );
      }
    }
  }

  Future<void> updateQty(int mode, int productIndex) async {
    // mode : 0=เปลี่ยนจำนวน, 1=เพิ่มจำนวน
    /*
    กรณีเปลี่ยนจำนวน ให้ไปลบ isclolse=9 ออกทั้งหมด เพื่อไม่ให้กระทบกับยอดคงเหลือใหม่    
    */
    TextEditingController qtyController = TextEditingController();

    var result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title:
                Text("${(mode == 0) ? global.language("qty_change") : global.language("qty_add")} : ${global.getNameFromLanguage(global.productList[productIndex].names, global.languageForCustomer)}"),
            content: TextField(
              controller: qtyController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  border: const OutlineInputBorder(), labelText: '${global.language("qty")} :${global.getNameFromLanguage(global.productList[productIndex].unitnames, global.languageForCustomer)}'),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context, false);
                },
                child: Text(global.language("cancel")),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: Text(global.language("confirm")),
              ),
            ],
          );
        });
    if (result == true) {
      if (qtyController.text.isNotEmpty) {
        int qty = int.parse(qtyController.text);
        if (qty >= 0) {
          if (mode == 0) {
            if (global.productList[productIndex].isstockforrestaurant) {
              // เปลี่ยนจำนวน
              await api.clickHouseExecute(
                  "alter table ${global.clickHouseDatabaseName}.ordertempcalcqty delete where shopid='${global.deviceConfig.shopId}' and branchid='${global.deviceConfig.branchId}' and barcode='${global.productList[productIndex].barcode}' and (isclose=9 or isclose=1)");
              // เพิ่มจำนวนใหม่เข้าไป
              double qty = double.parse(qtyController.text) - await global.getBalanceQtyFromServer(barcode: global.productList[productIndex].barcode, isclose: 0);
              await api.clickHouseExecute(
                  "INSERT INTO ${global.clickHouseDatabaseName}.ordertempcalcqty (shopid,branchid,deviceid,barcode,qty,isclose,orderdatetime) VALUES ('${global.deviceConfig.shopId}', '${global.deviceConfig.branchId}', '${global.deviceConfig.orderStationCode}', '${global.productList[productIndex].barcode}', $qty,9,now())");
            }
          } else {
            if (global.productList[productIndex].isstockforrestaurant) {
              // เพิ่มจำนวนเข้าไป
              await api.clickHouseExecute(
                  "INSERT INTO ${global.clickHouseDatabaseName}.ordertempcalcqty (shopid,branchid,deviceid,barcode,qty,isclose,orderdatetime) VALUES ('${global.deviceConfig.shopId}', '${global.deviceConfig.branchId}', '${global.deviceConfig.orderStationCode}', '${global.productList[productIndex].barcode}', ${double.parse(qtyController.text)},9,now())");
            }
          }
          productSelectedBarcode = "";
          refresh();
        }
      }
    }
  }

  void animateItem(int index) {
    if (global.categoryIndex == index && global.categoryIndex != 0) return;

    productListWidget = [];
    productScrolling = true;
    previousIndex = global.categoryIndex;
    global.categoryIndex = index;
    productSelectedBarcode = "";
    refresh();
  }

  void generateGridView() {
    setState(() {
      // กรณีไม่มีสินค้า ให้แสดงข้อความแจ้งเตือน
      if (global.productList.isEmpty) {
        productListWidget = [
          const Center(
            child: Text(
              "ไม่พบรายการสินค้า",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          )
        ];

        preloadImagesForCurrentCategory();

        // ใช้ Wrap แทน GridView สำหรับกรณีไม่มีสินค้า
        productGridView = Center(
          child: productListWidget[0],
        );
        return;
      }

      // เริ่มต้นใหม่ทุกครั้ง
      productListWidget = [];

      // ตรวจสอบว่ามีการเลือกหมวดหมู่หรือไม่
      if (global.categoryIndex != -1) {
        final searchText = searchController.text.trim().toLowerCase();
        final bool isSearching = searchText.isNotEmpty;

        if (!isSearching) {
          // === กรณีแสดงสินค้าตามหมวดหมู่ ===

          // แยกสินค้าที่ขายได้กับขายไม่ได้
          final availableProducts = <CategoryCodeListModel>[];
          final unavailableProducts = <CategoryCodeListModel>[];

          // คัดแยกสินค้าตามสถานะการขาย
          for (var product in global.categoryList[global.categoryIndex].codelist) {
            final productIndex = global.findProductByBarcode(product.barcode);

            if (productIndex != -1) {
              final productItem = global.productList[productIndex];

              if (productItem.issell) {
                availableProducts.add(product);
              } else {
                unavailableProducts.add(product);
              }
            }
          }

          // เพิ่มสินค้าที่ขายได้ก่อน ตามด้วยสินค้าที่ขายไม่ได้
          _addProductsToWidget(
            availableProducts,
            isAvailable: true,
          );

          _addProductsToWidget(
            unavailableProducts,
            isAvailable: false,
          );
        } else {
          // === กรณีค้นหาสินค้า ===
          final searchResults = _searchProducts(searchText);
          _addSearchResultsToWidget(searchResults);
        }
      }

      // คำนวณความกว้างของแต่ละรายการสินค้า
      final screenWidth = MediaQuery.of(context).size.width;
      final maxColumn = (global.isMobileScreen) ? 2 : 4; // กำหนดให้จอ Mobile แสดง 2 รายการต่อแถว จอใหญ่แสดง 3 รายการ
      final itemWidth = (screenWidth / maxColumn) - 5; // ลบด้วยระยะห่างระหว่างไอเทม

      // สร้าง Wrap แทน GridView
      productGridView = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Wrap(
          spacing: 4, // ระยะห่างแนวนอน
          runSpacing: 4, // ระยะห่างแนวตั้ง
          alignment: WrapAlignment.start,
          children: productListWidget.map((widget) {
            // สร้าง Container ที่มีความกว้างคงที่เพื่อทำให้ Wrap แสดงผลคล้าย GridView
            return SizedBox(
              width: itemWidth,
              height: (global.orderType == 6) ? itemWidth * 2 : itemWidth * 1.33, // ปรับความสูงให้เป็นสัดส่วนเดียวกับ GridView (อิงตาม childAspectRatio)
              child: widget,
            );
          }).toList(),
        ),
      );
    });
  }

  /// เพิ่มสินค้าลงใน widget list
  ///
  /// [products] คือรายการสินค้าที่จะแสดง
  /// [isAvailable] บอกว่าเป็นสินค้าที่ขายได้หรือไม่ (ใช้สำหรับการแสดงผลที่แตกต่างกัน)
  void _addProductsToWidget(
    List<CategoryCodeListModel> products, {
    bool isAvailable = true,
  }) {
    for (var product in products) {
      productListWidget.add(
        Container(
          decoration: BoxDecoration(
            color: isAvailable ? Colors.white : Colors.grey[50],
            border: Border.all(
              color: isAvailable ? Colors.grey[300]! : Colors.grey[400]!,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isAvailable
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          margin: const EdgeInsets.all(4),
          child: dataProductBody(product),
        ),
      );
    }
  }

  /// ค้นหาสินค้าตามชื่อ
  ///
  /// [searchText] คือข้อความที่ใช้ในการค้นหา
  /// คืนค่าเป็นรายการสินค้าที่ตรงกับการค้นหา
  List<ProductProcessModel> _searchProducts(String searchText) {
    final results = <ProductProcessModel>[];

    for (var product in global.productList) {
      bool found = false;

      // ค้นหาจากทุกชื่อของสินค้า
      for (var name in product.names) {
        if (name.name.toLowerCase().contains(searchText)) {
          results.add(product);
          found = true;
          break; // พบชื่อที่ตรงแล้ว ไม่ต้องตรวจสอบชื่ออื่นๆ
        }
      }

      // ค้นหาจาก barcode ถ้ายังไม่พบจากชื่อ
      if (!found && product.barcode.toLowerCase().contains(searchText)) {
        results.add(product);
      }
    }

    return results;
  }

  /// เพิ่มผลลัพธ์การค้นหาลงใน widget
  ///
  /// [products] คือรายการสินค้าที่ค้นพบจากการค้นหา
  void _addSearchResultsToWidget(List<ProductProcessModel> products) {
    for (var product in products) {
      // สร้าง CategoryCodeListModel จาก ProductProcessModel
      final newProduct = CategoryCodeListModel(
        code: product.code,
        xorder: 0,
        barcode: product.barcode,
        unitcode: product.unitcode,
        unitnames: product.unitnames,
        names: product.names,
        imageurl: product.imageuri,
      );

      // กำหนดข้อมูลเพิ่มเติม
      newProduct.prices = product.prices;
      newProduct.useoption = product.options.isNotEmpty;
      newProduct.orderqty = 0;

      // ตรวจสอบจำนวนที่สั่งแล้ว
      for (var order in orderTempSumByBarcodeList) {
        if (product.barcode == order.barcode) {
          newProduct.orderqty = order.qty;
          break;
        }
      }

      // เพิ่มเข้าไปใน widget list
      productListWidget.add(
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!, width: 1),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
            ],
          ),
          margin: const EdgeInsets.all(4),
          child: dataProductBody(newProduct),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget categoryWidget = Container();
    if (global.isMobileScreen == true) {
      categoryWidget = Wrap(alignment: WrapAlignment.center, children: [
        for (int index = 0; index < global.categoryList.length; index++)
          ElevatedButton(
            onPressed: () {
              global.categoryIndex = index;
              productSelectedBarcode = "";
              refresh();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: (index == global.categoryIndex) ? Colors.blue.shade200 : Colors.white,
              padding: const EdgeInsets.all(4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Colors.blue, width: 1),
              ),
              elevation: 2,
              shadowColor: Colors.grey.withOpacity(0.5),
            ),
            child: Text(
              global.getNameFromLanguage(global.categoryList[index].names, global.languageForCustomer),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                shadows: textStyleWhiteShadow,
              ),
            ),
          )
      ]);
    } else {
      categoryWidget = Container(
        width: categoryWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.only(right: 1),
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            // ส่วนหัวของเมนูหมวดหมู่
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.category_rounded,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Categories",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // ส่วนรายการหมวดหมู่
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 0),
                itemCount: global.categoryList.length,
                itemBuilder: (context, index) {
                  bool isSelected = index == global.categoryIndex;
                  bool isPreviouslySelected = index == previousIndex;

                  // สร้างวิดเจ็ตข้อความชื่อหมวดหมู่
                  Widget categoryNameWidget = Text(
                    global.getNameFromLanguage(global.categoryList[index].names, global.languageForCustomer),
                    style: TextStyle(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                      fontSize: isSelected ? 14 : 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      shadows: textStyleWhiteShadow,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  );

                  // สร้างวิดเจ็ตแสดงหมวดหมู่ (รูปภาพหรือข้อความ)
                  Widget categoryWidget;

                  if (global.categoryList[index].imageuri.isEmpty) {
                    // กรณีไม่มีรูปภาพ
                    categoryWidget = Center(
                      child: Text(
                        global.getNameFromLanguage(global.categoryList[index].names, global.languageForCustomer),
                        style: TextStyle(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                          fontSize: isSelected ? 14 : 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          shadows: textStyleWhiteShadow,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  } else if (isSelected) {
                    // กรณีที่เลือกและมีรูปภาพ - แสดงแบบคอลัมน์
                    categoryWidget = Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            margin: const EdgeInsets.only(bottom: 4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                fit: BoxFit.cover,
                                imageUrl: global.categoryList[index].imageuri,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ),
                        categoryNameWidget,
                      ],
                    );
                  } else {
                    // กรณีไม่ได้เลือกและมีรูปภาพ - แสดงแบบแถว
                    categoryWidget = Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              fit: BoxFit.cover,
                              imageUrl: global.categoryList[index].imageuri,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: categoryNameWidget),
                      ],
                    );
                  }

                  // สร้าง GestureDetector สำหรับการเลือกหมวดหมู่
                  return GestureDetector(
                    onTap: () {
                      animateItem(index);
                      searchController.text = "";
                      isSearch = false;
                      setState(() {});
                    },
                    child: Container(
                      // duration: const Duration(milliseconds: 300),
                      // curve: Curves.easeInOut,
                      height: isSelected ? 100 : 60,
                      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: categoryWidget,
                    ),
                  );
                },
              ),
            ),

            // ส่วนท้ายของเมนูหมวดหมู่
            Column(
              children: [
                const Divider(height: 1),

                // ปุ่มเลือกภาษา
                if (global.orderType == 0 || global.orderType == 1)
                  InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SelectLanguagePage()),
                      );
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.asset(
                              'assets/flags/${global.languageForCustomer}.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              global.language("language"),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                // ปุ่มค้นหา
                InkWell(
                  onTap: () {
                    global.countDownForHome = global.countDownForHomeMax;
                    isSearch = !isSearch;
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            global.language("search"),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(isSearch ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20, color: Colors.grey),
                      ],
                    ),
                  ),
                ),

                // แสดงประเภทการสั่งอาหาร
                if (global.orderType == 0 || global.orderType == 1)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(
                          global.orderType == 0 ? Icons.restaurant : Icons.takeout_dining,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            global.language(global.orderType == 0 ? 'order_to_eat_at_the_restaurant' : 'order_takeout'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // แสดงข้อมูลช่องทางการขาย
                if (global.saleChannelCode.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      children: [
                        if (global.saleChannelImage.isNotEmpty)
                          Container(
                            height: 50,
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: global.saleChannelImage,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        Text(
                          global.saleChannelName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }
    Widget productWidget = (global.categoryIndex == -1)
        ? Container()
        : Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                if (isPortrait && global.isMobileScreen == false)
                  Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: (isSearch)
                          ? Row(
                              children: [
                                Expanded(
                                    child: TextField(
                                  controller: searchController,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    labelText: global.language("search"),
                                  ),
                                )),
                                IconButton(
                                  onPressed: () async {
                                    searchController.text = "";
                                    isSearch = false;

                                    searchController.clear();
                                    // สร้าง grid ทันทีเมื่อกดปุ่มล้าง
                                    generateGridView();
                                  },
                                  icon: const Icon(Icons.close_outlined),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                if (global.categoryList[global.categoryIndex].imageuri.isNotEmpty)
                                  CachedNetworkImage(
                                    imageUrl: global.categoryList[global.categoryIndex].imageuri,
                                    width: 60,
                                    height: 60,
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxHeight: 40,
                                        ),
                                        child: FittedBox(
                                            fit: BoxFit.fitHeight,
                                            child: Text(global.getNameFromLanguage(global.categoryList[global.categoryIndex].names, global.languageForCustomer),
                                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, shadows: [
                                                  Shadow(
                                                    color: Colors.grey,
                                                    offset: Offset(1, 1),
                                                    blurRadius: 1,
                                                  ),
                                                ]))))),
                              ],
                            )),
                // Expanded(
                //     child: Column(
                //   children: [
                //     Expanded(
                //         child: SingleChildScrollView(
                //       controller: productScrollController,
                //       child: productGridView,
                //     )),
                //     (orderTempDetailList.isEmpty)
                //         ? Container()
                //         : Container(
                //             padding: const EdgeInsets.only(top: 4),
                //             width: double.infinity,
                //             decoration: const BoxDecoration(
                //               color: Colors.white,
                //               border: Border(
                //                 top: BorderSide(width: 1.0, color: Colors.grey),
                //               ),
                //             ),
                //             child: Wrap(
                //                 alignment: WrapAlignment.start,
                //                 spacing: 4,
                //                 runSpacing: 4,
                //                 children: orderTempSumByBarcodeList
                //                     .map((e) => orderAnimationOneTempBody(
                //                         context: context,
                //                         order: e,
                //                         onTab: () async {
                //                           await Navigator.push(
                //                               context,
                //                               MaterialPageRoute(
                //                                   builder: (context) => OrderAnimationOneCartPage(
                //                                         barcode: e.barcode,
                //                                         mode: 0,
                //                                       )));
                //                           productGridView = const Center(child: CircularProgressIndicator());
                //                           setState(() {});
                //                           Future.delayed(const Duration(milliseconds: 200), () {
                //                             refresh();
                //                           });
                //                         }))
                //                     .toList(),),),
                //   ],
                // ))
              ],
            ));
    isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return BlocListener<OrderTempBloc, OrderTempState>(
        listener: (orderTempContext, orderTempState) {
          if (orderTempState is OrderTempLoadSuccess) {
            orderTempDetailList = orderTempState.orderTemp;
            sumOrderQty = 0;
            sumOrderAmount = 0;
            for (var order in orderTempDetailList) {
              sumOrderQty += order.qty;
              sumOrderAmount += order.amount;
              /*if (order.optionselected.isNotEmpty) {
                List<ProductProcessOptionModel> optionList =
                    (jsonDecode(order.optionselected) as List)
                        .map((e) => ProductProcessOptionModel.fromJson(e))
                        .toList();
                for (var option in optionList) {
                  for (var choice in option.choices) {
                    if (choice.selected) {
                      sumOrderAmount += choice.amount;
                    }
                  }
                }
              }*/
            }
            for (var category in global.categoryList) {
              for (var product in category.codelist) {
                product.orderqty = 0;
                for (var order in orderTempDetailList) {
                  if (product.barcode == order.barcode) {
                    product.orderqty = product.orderqty! + order.qty;
                    if (kDebugMode) {
                      print(product.orderqty);
                    }
                  }
                }
              }
            }
            // รวม จำนวน ตาม barcode
            orderTempSumByBarcodeList = [];
            for (var order in orderTempDetailList) {
              int index = orderTempSumByBarcodeList.indexWhere((element) => element.barcode == order.barcode);
              if (index == -1) {
                orderTempSumByBarcodeList.add(order);
              } else {
                orderTempSumByBarcodeList[index].qty = orderTempSumByBarcodeList[index].qty + order.qty;
              }
            }

            productListWidget = [];
            generateGridView();
            //  setState(() {});
          }
        },
        child: Scaffold(
            body: Stack(
          children: [
            Column(children: [
              if (global.categoryIndex != -1 && isPortrait && global.categoryList[global.categoryIndex].coveruri.isNotEmpty)
                SizedBox(
                    width: double.infinity,
                    child: CachedNetworkImage(
                      fit: BoxFit.fill,
                      imageUrl: global.categoryList[global.categoryIndex].coveruri,
                    )),
              Expanded(
                  child: (global.categoryList.isEmpty)
                      ? Container()
                      : (global.isMobileScreen == true)
                          ? Column(
                              children: [
                                categoryWidget,
                                Expanded(child: productWidget),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                categoryWidget,
                                Expanded(child: productWidget),
                              ],
                            )),
              Container(
                width: double.infinity,
                height: (global.isMobileScreen) ? 65 : 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, -2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: (global.orderType == 5 || global.orderType == 6)
                    // ปุ่มออกจากหน้าจอสำหรับหน้าเปลี่ยนสถานะสินค้า/ปรับปรุงสินค้า
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                        onPressed: () {
                          backToHome();
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "${global.language("exit_screen")} : ${(global.orderType == 5) ? global.language("change_product_status") : global.language("improve_product_balance")}",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        ),
                      )
                    // แถบปุ่มด้านล่างสำหรับหน้าสั่งสินค้าปกติ
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ส่วนแสดงเลขโต๊ะหรือช่องทางการขาย
                          if (global.deviceConfig.systemCondition == 1)
                            Expanded(
                              flex: 1,
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        (global.isTakeAway == 1 && global.saleChannelName.isNotEmpty)
                                            ? global.saleChannelName
                                            : "${global.language("table_number")} ${global.tableNumberSelected.ordertagnumber}",
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // ปุ่มเริ่มใหม่
                          Expanded(
                            flex: 1,
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey[400]!),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                ),
                                onPressed: () async {
                                  global.countDownForHome = global.countDownForHomeMax;
                                  if (sumOrderQty == 0) {
                                    backToHome();
                                    return;
                                  }
                                  await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          title: Text(
                                            global.language("delete_all_items"),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: Text(global.language("want_to_delete_all_item")),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text(global.language("cancel")),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () async {
                                                if (mounted) {
                                                  backToHome();
                                                }
                                              },
                                              child: Text(global.language("confirm")),
                                            ),
                                          ],
                                        );
                                      });
                                  setState(() {});
                                },
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    global.language("restart"),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ปุ่มรถเข็น/ตะกร้าสินค้า
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                elevation: sumOrderQty == 0 ? 0 : 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                disabledBackgroundColor: Colors.grey[300],
                                disabledForegroundColor: Colors.grey[600],
                              ),
                              onPressed: (sumOrderQty == 0)
                                  ? null
                                  : () async {
                                      global.countDownForHome = global.countDownForHomeMax;
                                      timerCountDown.cancel();
                                      await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => OrderAnimationOneCartPage(
                                                    barcode: "",
                                                    mode: (global.deviceConfig.systemCondition == 1) ? 1 : 0,
                                                  )));
                                      productGridView = const Center(child: CircularProgressIndicator());
                                      setState(() {});
                                      Future.delayed(const Duration(milliseconds: 200), () {
                                        refresh();
                                      });
                                    },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // ไอคอนรถเข็นพร้อมจำนวนสินค้า
                                  badges.Badge(
                                    position: badges.BadgePosition.topEnd(top: -8, end: -8),
                                    badgeStyle: const badges.BadgeStyle(
                                      badgeColor: Colors.red,
                                      padding: EdgeInsets.all(6),
                                    ),
                                    badgeContent: Text(
                                      global.moneyFormat.format(sumOrderQty),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.shopping_cart,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${global.language("total_amount")} ${global.moneyFormat.format(sumOrderAmount)} ${global.language("money_baht")}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              )
            ]),
          ],
        )));
  }
}
