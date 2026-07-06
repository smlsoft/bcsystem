import 'dart:math';
import 'package:pdf/pdf.dart'; // เพิ่มสำหรับ PdfColors

import 'package:smlaicloud/bloc/product/product_bloc.dart';
import 'package:smlaicloud/bloc/product_barcode/product_barcode_bloc.dart';
import 'package:smlaicloud/components/product_label_print_shelf.dart';
import 'package:smlaicloud/components/product_shelf_label_print.dart';
import 'package:smlaicloud/components/product_label_print_a4_shelf.dart';
import 'package:smlaicloud/model/global_model.dart';
import 'package:smlaicloud/model/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:split_view/split_view.dart';
import 'package:smlaicloud/global.dart' as global;

// รูปแบบข้อมูลสินค้าพร้อมจำนวนที่ต้องการพิมพ์
class ProductWithCopies {
  final SearchCodeAndNameAndUnitModel product;
  int copies;
  final List<LanguageDataModel>? unitname;

  ProductWithCopies({
    required this.product, 
    this.copies = 1, 
    this.unitname,
  });
}

class ProductBarcodeShelf extends StatefulWidget {
  const ProductBarcodeShelf({super.key});

  @override
  State<ProductBarcodeShelf> createState() => ProductBarcodeShelfState();
}

class ProductBarcodeShelfState extends State<ProductBarcodeShelf> {
  TextEditingController searchController = TextEditingController();
  List<ProductBarcodeModel> listData = [];
  bool loadingData = false;
  FocusNode searchFocusNode = FocusNode(skipTraversal: true);
  final _debouncer = global.Debouncer(1000);
  ScrollController listScrollController = ScrollController();
  ScrollController selectedProductsScrollController = ScrollController();

  // รายการสินค้าที่เลือกพร้อมจำนวน
  List<ProductWithCopies> selectedProducts = [];

  String searchText = "";
  late SplitViewController splitViewController;

  // เพิ่มตัวแปรสำหรับเก็บสีข้อความราคา
  PdfColor _priceTextColor = PdfColors.black; // ค่าเริ่มต้นเป็นสีดำ

  @override
  void initState() {
    loadProducts("");
    listScrollController.addListener(onScrollList);
    splitViewController = SplitViewController(limits: [null, WeightLimit(min: 0.2, max: 0.8)]);
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    listScrollController.dispose();
    selectedProductsScrollController.dispose();
    super.dispose();
  }

  // สร้าง Widget สำหรับรายการสินค้า
  Widget buildProductListItem(int index, ProductBarcodeModel product) {
    final bool isEvenRow = index % 2 == 0;
    final bool productAlreadySelected = isProductSelected(product.barcode!);

    return Container(
      color: isEvenRow ? global.theme.columnAlternateEvenColor : global.theme.columnAlternateOddColor,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 4, child: Text(product.barcode!, maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 6, child: Text(global.activeLangName(product.names!), maxLines: 2, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: Text(global.activeLangName(product.itemunitnames!), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 3, child: Text(product.itemcode!, maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 4, child: Text(global.activeLangName(product.groupnames!), maxLines: 1, overflow: TextOverflow.ellipsis)),
          IconButton(
            onPressed: productAlreadySelected ? null : () => addProductToSelection(product),
            icon: Icon(
              Icons.add_circle,
              color: productAlreadySelected ? Colors.grey : Colors.green,
              size: 28,
            ),
            tooltip: productAlreadySelected ? 'สินค้านี้ถูกเลือกไปแล้ว' : 'เลือกสินค้านี้',
          ),
        ],
      ),
    );
  }

  // ตรวจสอบว่าสินค้าถูกเลือกไปแล้วหรือไม่
  bool isProductSelected(String barcode) {
    return selectedProducts.any((item) => item.product.barcode == barcode);
  }
  // เพิ่มสินค้าเข้าไปในรายการที่เลือก
  void addProductToSelection(ProductBarcodeModel product) {
    if (!isProductSelected(product.barcode!)) {
      setState(() {
        selectedProducts.add(
          ProductWithCopies(
            product: SearchCodeAndNameAndUnitModel(
              barcode: product.barcode!,
              code: product.itemcode!,
              name: product.names!,
              unitcode: product.itemunitcode!,
              unitname: product.itemunitnames ?? [], // Provide empty list if null
            ),
            copies: 1,
          ),
        );
      });
    }
  }

  // เพิ่มสินค้าทั้งหมดจากรายการที่แสดงอยู่
  void addAllProducts() {
    if (listData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่พบรายการสินค้าที่จะเพิ่ม'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int addedCount = 0;

    // ตรวจสอบแต่ละรายการสินค้า
    for (var product in listData) {
      // ตรวจสอบว่าสินค้านี้ถูกเลือกไปแล้วหรือไม่
      if (!isProductSelected(product.barcode!)) {
        // ถ้ายังไม่ได้เลือก ให้เพิ่มเข้าไปในรายการ
        selectedProducts.add(
          ProductWithCopies(
            product: SearchCodeAndNameAndUnitModel(
              barcode: product.barcode!,
              code: product.itemcode!,
              name: product.names!,
              unitcode: product.itemunitcode!,
              unitname: product.itemunitnames ?? [], // Provide empty list if null
            ),
            copies: 1,
          ),
        );
        addedCount++;
      }
    }

    // อัปเดต UI
    setState(() {});

    // แสดงข้อความแจ้งเตือน
    if (addedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เพิ่มสินค้าจำนวน $addedCount รายการ'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีสินค้าใหม่ที่จะเพิ่ม (ทุกรายการถูกเลือกแล้ว)'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // โหลดข้อมูลสินค้า
  void loadProducts(String search) {
    setState(() {
      loadingData = true;
    });
    searchText = search;
    context.read<ProductBarcodeBloc>().add(ProductBarcodeLoadList(
          offset: (listData.isEmpty) ? 0 : listData.length,
          limit: global.loadDataPerPage,
          search: search,
          branchcode: global.companyBranchSelectData.code,
          businesstypecode: global.companyBranchSelectData.businesstype!.code!,
        ));
  }

  // สร้างหน้าจอแสดงรายการสินค้า
  Widget buildProductListScreen() {
    return Scaffold(
      body: Column(
        children: [
          // ช่องค้นหาและตัวกรอง
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onSubmitted: (value) {
                searchFocusNode.requestFocus();
              },
              onChanged: (value) {
                _debouncer.run(() {
                  setState(() {
                    listData = [];
                  });
                  loadProducts(value);
                });
              },
              autofocus: false,
              focusNode: searchFocusNode,
              controller: searchController,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10), // เพิ่ม vertical padding
                border: InputBorder.none,
                hintText: global.language('search'),
              ),
            ),
          ),
          Container(
            color: global.theme.appBarColor,
            height: 6,
          ),

          // ส่วนหัวของตาราง
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            color: global.theme.columnHeaderColor,
            child: Row(
              children: [
                Expanded(flex: 4, child: Text(global.language("barcode"), style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 6, child: Text(global.language("product_name"), style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text(global.language("unit"), style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text(global.language("item_code"), style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text(global.language("product_group"), style: const TextStyle(fontWeight: FontWeight.bold))),
                // ปุ่มเพิ่มทั้งหมด
                if (listData.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.playlist_add, color: Colors.green),
                    onPressed: addAllProducts,
                    tooltip: 'เพิ่มสินค้าทั้งหมด',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),

          // รายการสินค้า
          Expanded(
            child: ListView.builder(
              controller: listScrollController,
              itemCount: listData.length,
              itemBuilder: (context, index) => buildProductListItem(index, listData[index]),
            ),
          ),

          // ตัวโหลดข้อมูล
          if (loadingData)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.blue,
                  size: 40,
                ),
              ),
            )
        ],
      ),
    );
  }

  // จัดการกับการเลื่อนรายการ
  void onScrollList() {
    if (listScrollController.position.pixels >= listScrollController.position.maxScrollExtent - 200 && !loadingData) {
      loadProducts(searchText);
    }
  }

// สร้างส่วนแสดงรายการสินค้าที่เลือก (GridView)
  Widget buildSelectedProductsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // ส่วนหัวของรายการ
          buildListHeader(),

          // Line separator
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.shade300,
          ),

          // รายการสินค้าที่เลือก
          Expanded(
            child: selectedProducts.isEmpty
                ? buildEmptySelectionView()
                : LayoutBuilder(builder: (context, constraints) {
                    // Calculate number of columns based on available width
                    // Adjust the divisor (150.0) to control card width
                    final double cardWidth = 150.0;
                    int crossAxisCount = max(1, (constraints.maxWidth / cardWidth).floor());

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(8),
                      child: GridView.builder(
                        controller: selectedProductsScrollController,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 1, // Square cards
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: selectedProducts.length,
                        itemBuilder: (context, index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: buildSelectedProductGridItem(selectedProducts[index]),
                        ),
                      ),
                    );
                  }),
          ),

          // Bottom action bar
          if (selectedProducts.isNotEmpty) buildBottomActionBar(),
        ],
      ),
    );
  }

  // สร้างส่วนหัวของรายการ
  Widget buildListHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_cart,
            color: global.theme.appBarColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'เลือกสินค้า (${selectedProducts.length})', // แก้ไข syntax error
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: global.theme.appBarColor,
              ),
            ),
          ),
          if (selectedProducts.isNotEmpty)
            IconButton(
              onPressed: clearAllProducts,
              icon: const Icon(Icons.delete_sweep),
              tooltip: global.language("clear_all"),
              color: Colors.red.shade700,
            ),
        ],
      ),
    );
  }

  // สร้างส่วนแสดงเมื่อไม่มีสินค้าที่เลือก
  Widget buildEmptySelectionView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 68,
                color: global.theme.appBarColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'ไม่มีสินค้าที่เลือก',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'เลือกสินค้าจากรายการด้านซ้ายเพื่อเพิ่มลงในรายการนี้',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            Icon(
              Icons.arrow_back,
              size: 32,
              color: Colors.blue.shade300,
            ),
          ],
        ),
      ),
    );
  }

  // สร้างรายการสินค้าที่เลือก (ListView Item) - Space-efficient version
  Widget buildSelectedProductItem(ProductWithCopies product) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left side - Product info
            Expanded(
              flex: 7,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barcode badge - vertical orientation
                  Container(
                    width: 32,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300, width: 0.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code, size: 14, color: Colors.grey.shade700),
                        const SizedBox(height: 2),
                        RotatedBox(
                          quarterTurns: 1,
                          child: Text(
                            product.product.barcode.substring(product.product.barcode.length - 4),
                            style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'Monospace',
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Product name
                        Text(
                          global.packName(product.product.name),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 2),

                        // Barcode and unit in one row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.product.barcode,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'Monospace',
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue.shade100, width: 0.5),
                              ),
                              child: Text(
                                global.packName(product.product.unitname),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade700,
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

            // Right side - Controls
            Expanded(
              flex: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Compact quantity selector
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Decrease button
                        InkWell(
                          onTap: product.copies > 1 ? () => setState(() => product.copies--) : null,
                          child: Container(
                            width: 28,
                            height: 32,
                            decoration: BoxDecoration(
                              color: product.copies > 1 ? Colors.red.shade50 : Colors.grey.shade100,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                bottomLeft: Radius.circular(4),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.remove,
                              size: 14,
                              color: product.copies > 1 ? Colors.red.shade700 : Colors.grey.shade400,
                            ),
                          ),
                        ),

                        // Quantity display
                        InkWell(
                          onTap: () => openEditCopiesDialog(product),
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            child: Text(
                              '${product.copies}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ),

                        // Increase button
                        InkWell(
                          onTap: product.copies < 99 ? () => setState(() => product.copies++) : null,
                          child: Container(
                            width: 28,
                            height: 32,
                            decoration: BoxDecoration(
                              color: product.copies < 99 ? Colors.green.shade50 : Colors.grey.shade100,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(4),
                                bottomRight: Radius.circular(4),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.add,
                              size: 14,
                              color: product.copies < 99 ? Colors.green.shade700 : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Delete button
                  InkWell(
                    onTap: () => setState(() {
                      selectedProducts.removeWhere((item) => item.product.barcode == product.product.barcode);
                    }),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade100, width: 0.5),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
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

  // สร้างรายการสินค้าสำหรับ GridView
  Widget buildSelectedProductGridItem(ProductWithCopies product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barcode badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          product.product.barcode,
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'Monospace',
                            color: Colors.grey.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Product name
                Text(
                  global.activeLangName(product.product.name),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Unit
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    global.activeLangName(product.product.unitname),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),

                const Spacer(),

                // Quantity controls at bottom
                Row(
                  children: [
                    // Decrease button
                    InkWell(
                      onTap: product.copies > 1 ? () => setState(() => product.copies--) : null,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: product.copies > 1 ? Colors.red.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: product.copies > 1 ? Colors.red.shade200 : Colors.grey.shade300,
                            width: 0.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.remove,
                          size: 14,
                          color: product.copies > 1 ? Colors.red.shade700 : Colors.grey.shade400,
                        ),
                      ),
                    ),

                    // Quantity display
                    Expanded(
                      child: InkWell(
                        onTap: () => openEditCopiesDialog(product),
                        child: Container(
                          height: 26,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.blue.shade300,
                              width: 0.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${product.copies}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Increase button
                    InkWell(
                      onTap: product.copies < 99 ? () => setState(() => product.copies++) : null,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: product.copies < 99 ? Colors.green.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: product.copies < 99 ? Colors.green.shade200 : Colors.grey.shade300,
                            width: 0.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.add,
                          size: 14,
                          color: product.copies < 99 ? Colors.green.shade700 : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete button in top right corner
          Positioned(
            top: 0,
            right: 0,
            child: InkWell(
              onTap: () => setState(() {
                selectedProducts.removeWhere((item) => item.product.barcode == product.product.barcode);
              }),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom action bar with buttons
  Widget buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: openCopiesDialog,
              icon: const Icon(Icons.edit),
              label: Text('แก้ไขจำนวนพร้อมกันทั้งหมด'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: printLabels,
              icon: const Icon(Icons.print),
              label: Text('พิมพ์ฉลากสินค้า'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // เปิดหน้าต่างแก้ไขจำนวนพร้อมกันทั้งหมด
  void openCopiesDialog() {
    final TextEditingController copiesController = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('แก้ไขจำนวนพร้อมกันทั้งหมด'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: copiesController,
              decoration: InputDecoration(
                labelText: 'จำนวนที่ต้องการพิมพ์',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(global.language("cancel")),
          ),
          ElevatedButton(
            onPressed: () {
              final int copies = int.tryParse(copiesController.text) ?? 1;
              if (copies > 0 && copies <= 99) {
                setState(() {
                  for (var product in selectedProducts) {
                    product.copies = copies;
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(global.language("save")),
          ),
        ],
      ),
    );
  }
  // พิมพ์ฉลากสินค้า
  void printLabels() {
    if (selectedProducts.isNotEmpty) {
      final List<String> barcodes = selectedProducts.map((p) => p.product.barcode).toList();
      
      // แสดงตัวเลือกรูปแบบการพิมพ์
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('เลือกรูปแบบการพิมพ์'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('กรุณาเลือกรูปแบบการพิมพ์ฉลากสินค้า'),
              const SizedBox(height: 20),
              
              // ปุ่มพิมพ์ฉลากบนกระดาษ A4
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.read<ProductBloc>().add(ProductGetByBarcodes(barcodes: barcodes));
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.print, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'พิมพ์บนกระดาษ A4',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'รูปแบบดั้งเดิม สำหรับพิมพ์ติดสินค้า',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ปุ่มพิมพ์ฉลากติดชั้นวาง A4 - เปลี่ยนให้แสดงตัวเลือกสีทันที
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showColorSelectionForA4ShelfLabels(barcodes); // เรียกฟังก์ชันใหม่
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.grid_view, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'พิมพ์ฉลากติดชั้นวาง (A4)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'A4 แนวตั้ง 3 ฉลาก/แถว (6.5x3.5 ซม.)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(global.language('cancel')),
            ),
          ],
        ),
      );
    }
  }

  // ฟังก์ชันใหม่สำหรับแสดงตัวเลือกสีสำหรับฉลากติดชั้นวาง A4
  void _showColorSelectionForA4ShelfLabels(List<String> barcodes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกสีข้อความราคา'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('เลือกสีสำหรับข้อความราคาในฉลากติดชั้นวาง'),
            const SizedBox(height: 20),
            
            // ตัวเลือกสีดำ
            InkWell(
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _priceTextColor = PdfColors.black;
                });
                _printA4ShelfLabels(barcodes);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(
                    color: _priceTextColor == PdfColors.black ? Colors.green : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สีดำ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            'เหมาะสำหรับการพิมพ์ทั่วไป',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_priceTextColor == PdfColors.black)
                      const Icon(Icons.check_circle, color: Colors.green, size: 24),
                  ],
                ),
              ),
            ),
            
            // ตัวเลือกสีแดง
            InkWell(
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _priceTextColor = PdfColors.red;
                });
                _printA4ShelfLabels(barcodes);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(
                    color: _priceTextColor == PdfColors.red ? Colors.green : Colors.red.shade200,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สีแดง',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          Text(
                            'เหมาะสำหรับการเน้นราคาพิเศษ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_priceTextColor == PdfColors.red)
                      const Icon(Icons.check_circle, color: Colors.green, size: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(global.language('cancel')),
          ),
        ],
      ),
    );
  }

  // พิมพ์ฉลากสำหรับติดบนชั้นวางสินค้า
  void _printShelfLabels(List<String> barcodes) {
    context.read<ProductBloc>().add(ProductGetByBarcodes(barcodes: barcodes, source: 'shelf_label'));
  }

  // พิมพ์ฉลากติดชั้นว่าง A4
  void _printA4ShelfLabels(List<String> barcodes) {
    context.read<ProductBloc>().add(ProductGetByBarcodes(barcodes: barcodes, source: 'a4_shelf_label'));
  }

  // ล้างรายการสินค้าทั้งหมด
  void clearAllProducts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ยืนยันการล้างรายการสินค้า'),
        content: Text('คุณต้องการล้างรายการสินค้าทั้งหมดใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(global.language("cancel")),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                selectedProducts.clear();
              });
              Navigator.pop(context);
            },
            child: Text(global.language("clear_all")),
          ),
        ],
      ),
    );
  }

  // เปิดหน้าต่างแก้ไขจำนวนเฉพาะสินค้า
  void openEditCopiesDialog(ProductWithCopies product) {
    final TextEditingController copiesController = TextEditingController(text: product.copies.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('แก้ไขจำนวน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              global.packName(product.product.name),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: copiesController,
              decoration: InputDecoration(
                labelText: 'จำนวนที่ต้องการพิมพ์',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(global.language("cancel")),
          ),
          ElevatedButton(
            onPressed: () {
              final int copies = int.tryParse(copiesController.text) ?? 1;
              if (copies > 0 && copies <= 99) {
                setState(() {
                  product.copies = copies;
                });
                Navigator.pop(context);
              }
            },
            child: Text(global.language("save")),
          ),
        ],
      ),
    );
  }

  // แสดงตัวเลือกสีข้อความราคา - ฟังก์ชันเดิมสำหรับปุ่ม palette ใน app bar
  void _showPriceColorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เลือกสีข้อความราคา'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ตัวเลือกสีดำ
            ListTile(
              leading: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              title: const Text('สีดำ'),
              trailing: _priceTextColor == PdfColors.black 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                setState(() {
                  _priceTextColor = PdfColors.black;
                });
                Navigator.pop(context);
              },
            ),
            // ตัวเลือกสีแดง
            ListTile(
              leading: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.red,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              title: const Text('สีแดง'),
              trailing: _priceTextColor == PdfColors.red 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                setState(() {
                  _priceTextColor = PdfColors.red;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MultiBlocListener(
          listeners: [
            BlocListener<ProductBloc, ProductState>(
              listener: (context, state) {
                if (state is ProductGetByBarcodesSuccess) {
                  // ส่งข้อมูลจำนวนดวงไปด้วย
                  final List<int> copies = selectedProducts.map((item) => item.copies).toList();
                  
                  // ตรวจสอบว่าได้เรียกจากฟังก์ชันใดบ้าง
                  if (state.source == 'shelf_label') {
                    // พิมพ์ฉลากชั้นวางสินค้า
                    ProductShelfLabelPrint.showPdfPreview(
                      context,
                      state.products,
                      copies,
                    );
                  } else if (state.source == 'a4_shelf_label') {
                    // พิมพ์ฉลากติดชั้นว่าง A4 พร้อมส่งสีข้อความราคา
                    ProductLabelPrintA4Shelf.showPdfPreview(
                      context,
                      state.products,
                      copies,
                      priceTextColor: _priceTextColor, // ส่งสีที่เลือกไปด้วย
                    );
                  } else {
                    // พิมพ์ฉลาก A4 แบบเดิม
                    ProductLabelPrintShelf.showPdfPreview(
                      context,
                      state.products,
                      copies,
                    );
                  }
                } else if (state is ProductGetByBarcodesFailed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            BlocListener<ProductBarcodeBloc, ProductBarcodeState>(
              listener: (context, state) {
                if (state is ProductBarcodeLoadSuccess) {
                  setState(() {
                    loadingData = false;
                    if (state.productBarcodes.isNotEmpty) {
                      listData.addAll(state.productBarcodes);
                    }
                  });
                }
                if (state is ProductBarcodeLoadFailed) {
                  setState(() {
                    loadingData = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: global.theme.appBarColor,
              title: const Text('พิมพ์ Label สินค้า'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pushReplacementNamed(context, '/menu'),
              ),
              actions: [
                // เพิ่มปุ่มเลือกสีข้อความราคา
                if (selectedProducts.isNotEmpty)
                  IconButton(
                    onPressed: _showPriceColorDialog,
                    icon: Icon(
                      Icons.palette,
                      color: _priceTextColor == PdfColors.black ? Colors.black : Colors.red,
                    ),
                    tooltip: 'เลือกสีข้อความราคา',
                  ),
                if (selectedProducts.isNotEmpty)
                  IconButton(
                    onPressed: printLabels,
                    icon: const Icon(Icons.print),
                    tooltip: 'พิมพ์ Label สินค้า',
                  ),
              ],
            ),
            body: (constraints.maxWidth < 800.0)
                ? SplitView(
                    controller: splitViewController,
                    gripSize: 8,
                    gripColor: global.theme.appBarColor,
                    gripColorActive: Colors.blue,
                    viewMode: SplitViewMode.Vertical,
                    indicator: const SplitIndicator(viewMode: SplitViewMode.Vertical),
                    activeIndicator: const SplitIndicator(
                      viewMode: SplitViewMode.Vertical,
                      isActive: true,
                    ),
                    children: [
                      buildProductListScreen(),
                      buildSelectedProductsList(),
                    ],
                  )
                : SplitView(
                    controller: splitViewController,
                    gripSize: 8,
                    gripColor: global.theme.appBarColor,
                    gripColorActive: Colors.blue,
                    viewMode: SplitViewMode.Horizontal,
                    indicator: const SplitIndicator(viewMode: SplitViewMode.Horizontal),
                    activeIndicator: const SplitIndicator(
                      viewMode: SplitViewMode.Horizontal,
                      isActive: true,
                    ),
                    children: [
                      buildProductListScreen(),
                      buildSelectedProductsList(),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
