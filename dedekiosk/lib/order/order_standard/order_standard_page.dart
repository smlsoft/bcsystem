import 'package:badges/badges.dart' as badges;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:animate_gradient/animate_gradient.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedekiosk/bloc/category_bloc.dart';
import 'package:dedekiosk/bloc/order_temp_bloc.dart';
import 'package:dedekiosk/model/category_model.dart';
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/objectbox/objectbox.g.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/model/product_model.dart';
import 'package:dedekiosk/page/order_select_page.dart';
import 'package:dedekiosk/order/order_standard/order_standard_cart_page.dart';
import 'package:dedekiosk/order/order_standard/order_standard_product_option_page.dart';
import 'package:dedekiosk/order/pay_page.dart';
import 'package:dedekiosk/util/print_queue.dart';
import 'package:dedekiosk/page/select_language_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/order/order_util.dart' as util;
import 'package:intl/intl.dart';
import 'package:objectbox/objectbox.dart';
import 'package:uuid/uuid.dart';
import 'package:visibility_detector/visibility_detector.dart';

class OrderStandardPage extends StatefulWidget {
  const OrderStandardPage({Key? key}) : super(key: key);
  @override
  OrderStandardPageState createState() => OrderStandardPageState();
}

class OrderStandardPageState extends State<OrderStandardPage> {
  TextEditingController searchController = TextEditingController();
  List<OrderTempDetailModel> orderTempList = [];
  late Timer timer;
  double sumOrderQty = 0;
  double sumOrderAmount = 0;
  int machineCount = 0;
  int timeInterval = 0;
  bool isSearch = false;
  bool showCartMode = false;
  List<GlobalKey> categoryKeyList = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
  }

  void refresh() {
    setState(() {});
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
                  Text(" ${global.language("add_money")}  ${optionList[optionIndex].choices[choiceIndex].price} ${global.language("money_baht")}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ));
          }
        }
      }
    }
    return SizedBox(width: double.infinity, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: result));
  }

  Widget dataProductBody(CategoryCodeListModel data) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          //await util.orderAddOne(context, data, false);
          refresh();
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (global.orderShowImage)
                    Expanded(
                      child: Center(
                        child: (data.imageurl! == "")
                            ? Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  imageUrl: data.imageurl!,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.orange.shade300,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                ),
                              ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    global.getNameFromLanguage(data.names, global.languageForCustomer),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        global.getNameFromLanguage(data.unitnames, global.languageForCustomer),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "${global.moneyFormat.format(data.prices)} ${global.language("money_baht")}",
                        style: TextStyle(
                          color: Colors.deepOrange.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
            if (data.orderqty != null && data.orderqty! > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      global.moneyFormat.format(data.orderqty),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    global.screenMode = (screenWidth < 600) ? 1 : 0;

    // Top Menu bar
    Widget menuLeft = Row(
      children: [
        if (sumOrderQty == 0)
          ElevatedButton.icon(
            icon: const Icon(Icons.home),
            label: Text(global.language('home')),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
          ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          icon: Icon(
            (global.orderType == 0) ? Icons.restaurant : Icons.takeout_dining,
            color: Colors.white,
          ),
          label: Text(
            global.language((global.orderType == 0) ? 'order_to_eat_at_the_restaurant' : 'order_takeout'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: (global.orderType == 0) ? Colors.blue.shade600 : Colors.red.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () async {
            if (global.deviceConfig.useOrderEatAtTheRestaurant == true && global.deviceConfig.useOrderTakeAway == true) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderSelectPage(),
                ),
              );
              setState(() {});
            }
          },
        ),
      ],
    );

    Widget menuRight = Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: () {
              setState(() {
                global.orderShowImage = !global.orderShowImage;
              });
            },
            icon: Icon(
              (global.orderShowImage) ? Icons.image : Icons.image_not_supported,
              color: Colors.black87,
            ),
            tooltip: global.language((global.orderShowImage) ? 'hide_images' : 'show_images'),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectLanguagePage(),
                  ),
                );
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/flags/${global.languageForCustomer}.png',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      global.languageForCustomer.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    double maxWidth = MediaQuery.of(context).size.width;
    int objectMinWidth = 160; // Larger minimum width for product cards
    double objectWidth = (global.categoryList.isEmpty) ? 0.0 : (maxWidth / global.categoryList.length);
    if (objectWidth < objectMinWidth) {
      objectWidth = objectMinWidth.toDouble();
    }

    int categoryObjectMinWidth = 100; // Larger minimum width for category buttons
    double categoryObjectWidth = (global.categoryList.isEmpty) ? 0.0 : (maxWidth / global.categoryList.length);
    if (categoryObjectWidth < categoryObjectMinWidth) {
      categoryObjectWidth = categoryObjectMinWidth.toDouble();
    }

    return BlocListener<OrderTempBloc, OrderTempState>(
      listener: (orderTempContext, orderTempState) {
        if (orderTempState is OrderTempLoadSuccess) {
          orderTempList = orderTempState.orderTemp;
          sumOrderQty = 0;
          sumOrderAmount = 0;
          for (var order in orderTempList) {
            sumOrderQty += order.qty;
            sumOrderAmount += order.amount;
            if (order.optionselected.isNotEmpty) {
              List<ProductProcessOptionModel> optionList = (jsonDecode(order.optionselected) as List).map((e) => ProductProcessOptionModel.fromJson(e)).toList();
              for (var option in optionList) {
                for (var choice in option.choices) {
                  if (choice.selected) {
                    sumOrderAmount += (choice.priceValue * order.qty);
                  }
                }
              }
            }
          }
          for (var category in global.categoryList) {
            for (var product in category.codelist) {
              product.orderqty = 0;
              for (var order in orderTempList) {
                if (product.barcode == order.barcode) {
                  product.orderqty = product.orderqty! + order.qty;
                }
              }
            }
          }
          context.read<OrderTempBloc>().add(OrderTempLoadFinish());
          setState(() {});
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Top Menu Bar with gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange.shade300,
                      Colors.orange.shade100,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                width: double.infinity,
                child: (global.screenMode == 0)
                    ? Row(
                        children: [
                          menuLeft,
                          const Spacer(),
                          menuRight,
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [menuLeft],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [menuRight],
                          ),
                        ],
                      ),
              ),

              // Category List
              (global.categoryList.isEmpty)
                  ? Container()
                  : Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: global.categoryList.map((e) {
                            bool isSelected = global.categoryList.indexWhere((element) => element.guidfixed == e.guidfixed) == global.categoryIndex;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    global.categoryIndex = global.categoryList.indexWhere((element) => element.guidfixed == e.guidfixed);
                                  });
                                },
                                child: Container(
                                  width: categoryObjectWidth,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.green.shade100 : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.green.withOpacity(0.2),
                                              spreadRadius: 1,
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (e.imageuri.isNotEmpty)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: CachedNetworkImage(
                                            fit: BoxFit.cover,
                                            height: 40,
                                            width: 40,
                                            imageUrl: e.imageuri,
                                            placeholder: (context, url) => Container(
                                              height: 40,
                                              width: 40,
                                              color: Colors.grey.shade200,
                                            ),
                                            errorWidget: (context, url, error) => const Icon(Icons.error),
                                          ),
                                        ),
                                      if (e.imageuri.isEmpty)
                                        Icon(
                                          Icons.category,
                                          size: 30,
                                          color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        global.getNameFromLanguage(e.names, global.languageForCustomer),
                                        style: TextStyle(
                                          color: isSelected ? Colors.green.shade800 : Colors.black87,
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

              // Product Grid
              Expanded(
                child: (global.categoryIndex == -1)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              global.language("select_category"),
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Builder(
                        builder: (context) {
                          // Sort products: available products first, out-of-stock/paused products last
                          final sortedProducts = List<CategoryCodeListModel>.from(
                              global.categoryList[global.categoryIndex].codelist);
                          sortedProducts.sort((a, b) {
                            int productIndexA = global.findProductByBarcode(a.barcode);
                            int productIndexB = global.findProductByBarcode(b.barcode);

                            bool aReady = true;
                            bool bReady = true;

                            if (productIndexA != -1) {
                              var productA = global.productList[productIndexA];
                              aReady = productA.issell &&
                                  !(productA.isstockforrestaurant == true && productA.stockqty <= 0) &&
                                  global.findProductPrice(prices: productA.prices) > 0;
                            }

                            if (productIndexB != -1) {
                              var productB = global.productList[productIndexB];
                              bReady = productB.issell &&
                                  !(productB.isstockforrestaurant == true && productB.stockqty <= 0) &&
                                  global.findProductPrice(prices: productB.prices) > 0;
                            }

                            if (aReady && !bReady) return -1;
                            if (!aReady && bReady) return 1;
                            return 0;
                          });

                          return Container(
                            color: Colors.grey.shade100,
                            padding: const EdgeInsets.all(8),
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: (maxWidth / objectWidth).floor(),
                                childAspectRatio: 0.75, // Taller cards for better layout
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                              itemCount: sortedProducts.length,
                              itemBuilder: (context, index) {
                                return dataProductBody(sortedProducts[index]);
                              },
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Clear Cart Button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          global.language("reset"),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: (sumOrderQty == 0)
                            ? null
                            : () async {
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                        global.language("delete_all"),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: Text(
                                        global.language("want_to_delete_all_item"),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            global.language("cancel"),
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red.shade600,
                                          ),
                                          onPressed: () async {
                                            global.objectBoxStore.box<OrderTempObjectBoxModel>().removeAll();
                                            refresh();
                                            if (mounted) {
                                              Navigator.pop(context);
                                            }
                                          },
                                          child: Text(
                                            global.language("confirm"),
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                setState(() {});
                              },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Checkout Button
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: sumOrderQty == 0 ? Colors.grey.shade400 : Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: (sumOrderQty == 0)
                            ? null
                            : () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderStandardCartPage(),
                                  ),
                                );
                              },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            badges.Badge(
                              position: badges.BadgePosition.topEnd(top: -10, end: -10),
                              badgeContent: Text(
                                global.moneyFormat.format(sumOrderQty),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              badgeStyle: badges.BadgeStyle(
                                badgeColor: Colors.red.shade600,
                                padding: const EdgeInsets.all(6),
                              ),
                              child: const Icon(
                                Icons.shopping_cart,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  global.language("total_money"),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${global.moneyFormat.format(sumOrderAmount)} ${global.language("money_baht")}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
}
