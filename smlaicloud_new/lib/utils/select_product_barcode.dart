import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smlaicloud/utils/util.dart';
import 'package:smlaicloud/global.dart' as global;

class SelectProductBarcodeWidget extends StatefulWidget {
  const SelectProductBarcodeWidget({super.key});

  @override
  _SelectProductBarcodeWidgetState createState() =>
      _SelectProductBarcodeWidgetState();
}

class _SelectProductBarcodeWidgetState
    extends State<SelectProductBarcodeWidget> {
  List<Map<String, dynamic>> _products = [];
  String? _error;
  late TextEditingController _searchController;
  int _timeCount = 0;
  late Timer _timer;
  String _lastSearchText = "";
  late FocusNode _searchFocusNode;
  final List<String> _barcodeSelected = [];
  bool _isLoading = false;

  // เพิ่มตัวแปรสำหรับควบคุมขนาดตัวอักษร
  double _fontSizeScale = 1.0; // ค่าเริ่มต้น 1.0

  // คำนวณขนาดอักษรตามสเกล
  double _fontSize(double baseSize) => baseSize * _fontSizeScale;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchController.addListener(() {
      _timeCount = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _timeCount++;
      if (_timeCount > 2) {
        _timeCount = 0;
        String searchText = _searchController.text.trim();
        if (_lastSearchText != searchText) {
          _fetchProducts();
          if (searchText != _lastSearchText) {
            _lastSearchText = searchText;
            setState(() {});
          }
        }
      }
    });
    _fetchProducts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      String where =
          "shopid = '${global.getShopId()}'"; // Always include shopid

      // Only add search conditions if search text exists
      if (_searchController.text.trim().isNotEmpty) {
        List<String> _searchList = _searchController.text.trim().split(" ");
        List<String> _fieldName = ["barcode", "name"];

        for (var i = 0; i < _searchList.length; i++) {
          String searchText = _searchList[i].trim();
          if (searchText.isNotEmpty) {
            where += " and (";
            for (var j = 0; j < _fieldName.length; j++) {
              String fieldName = _fieldName[j];
              if (j > 0) {
                where += " or ";
              }
              where += "$fieldName ilike '%$searchText%'";
            }
            where += ")";
          }
        }
      }

      where =
          " where $where"; // Now we always have at least shopid in the where clause
      var response = await clickhouseSelectGroup([
        "SELECT barcode,name0 as name FROM dedebi.productbarcodeprocess $where order by barcode limit 200",
      ]);
      if (response["status"] != "success" || response["data"] == null) {
        setState(() {
          _products = [];
          _isLoading = false;
        });
        return;
      }
      List<dynamic> data = response["data"];
      if (data.isEmpty) {
        setState(() {
          _products = [];
          _isLoading = false;
        });
        return;
      }
      List<Map<String, dynamic>> productsData =
          List<Map<String, dynamic>>.from(data[0]);
      setState(() {
        _products = productsData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getProductName(String barcode) {
    for (var product in _products) {
      if (product["barcode"] == barcode) {
        return product["name"] ?? "";
      }
    }
    return "";
  }

  // ฟังก์ชันเพิ่มขนาดตัวอักษร
  void _increaseFontSize() {
    setState(() {
      _fontSizeScale += 0.1;
      if (_fontSizeScale > 1.5) _fontSizeScale = 1.5; // ขนาดสูงสุด
    });
  }

  // ฟังก์ชันลดขนาดตัวอักษร
  void _decreaseFontSize() {
    setState(() {
      _fontSizeScale -= 0.1;
      if (_fontSizeScale < 0.8) _fontSizeScale = 0.8; // ขนาดต่ำสุด
    });
  }

  @override
  Widget build(BuildContext context) {
    double padding = 4.0;
    double widgetMinWidth = 160;
    double maxWidth = MediaQuery.of(context).size.width - (padding * 2);
    int maxColumn = maxWidth ~/ widgetMinWidth;

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("เลือกสินค้า"),
        backgroundColor: Colors.blue.shade700,
        elevation: 2,
        actions: [
          // เพิ่มปุ่มปรับขนาดตัวอักษร
          IconButton(
            icon: const Icon(Icons.text_decrease),
            tooltip: "ลดขนาดตัวอักษร",
            onPressed: _decreaseFontSize,
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            tooltip: "เพิ่มขนาดตัวอักษร",
            onPressed: _increaseFontSize,
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(padding),
        color: Colors.grey.shade100,
        child: Column(
          children: [
            Card(
              elevation: 2,
              margin:
                  const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  style: TextStyle(
                      fontSize: _fontSize(16)), // ปรับขนาดตัวอักษรในช่องค้นหา
                  decoration: InputDecoration(
                    labelText: 'ค้นหาสินค้า',
                    labelStyle:
                        TextStyle(fontSize: _fontSize(16)), // ปรับขนาดป้ายกำกับ
                    hintText: 'กรอกบาร์โค้ดหรือชื่อสินค้า',
                    hintStyle:
                        TextStyle(fontSize: _fontSize(14)), // ปรับขนาดคำแนะนำ
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 8.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.blue.shade500, width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _products = [];
                        });
                      },
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ),

            // แสดงรายการสินค้าที่เลือกแล้ว
            if (_barcodeSelected.isNotEmpty)
              Card(
                elevation: 2,
                margin:
                    const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_cart,
                              color: Colors.blue, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            "สินค้าที่เลือก (${_barcodeSelected.length})",
                            style: TextStyle(
                              fontSize: _fontSize(16), // ปรับขนาดตัวอักษร
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            icon: const Icon(Icons.delete_sweep,
                                color: Colors.red, size: 18),
                            label: Text(
                              "ล้างทั้งหมด",
                              style: TextStyle(
                                  color: Colors.red, fontSize: _fontSize(14)),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 0),
                            ),
                            onPressed: () {
                              setState(() {
                                _barcodeSelected.clear();
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _barcodeSelected.map((barcode) {
                          final name = _getProductName(barcode);
                          return Chip(
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.all(2),
                            labelPadding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            backgroundColor: Colors.blue.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.blue.shade300),
                            ),
                            label: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  barcode,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: _fontSize(14), // ปรับขนาดตัวอักษร
                                  ),
                                ),
                                if (name.isNotEmpty)
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize:
                                          _fontSize(12), // ปรับขนาดตัวอักษร
                                      color: Colors.grey.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            deleteIcon: const Icon(
                              Icons.cancel,
                              size: 18,
                              color: Colors.red,
                            ),
                            onDeleted: () {
                              setState(() {
                                _barcodeSelected.remove(barcode);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

            // สถานะการโหลด
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              ),

            // แสดงรายการสินค้าที่ค้นหา
            Expanded(
              child: _products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchController.text.isEmpty
                                ? Icons.search
                                : Icons.inventory_2_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchController.text.isEmpty
                                ? "กรุณากรอกข้อมูลที่ต้องการค้นหา"
                                : "ไม่พบข้อมูลสินค้าที่ค้นหา",
                            style: TextStyle(
                              fontSize: _fontSize(16), // ปรับขนาดตัวอักษร
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(4.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: maxColumn,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        final barcode = product["barcode"] ?? "";
                        final isSelected = _barcodeSelected.contains(barcode);

                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.blue.shade500
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          color:
                              isSelected ? Colors.blue.shade50 : Colors.white,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _barcodeSelected.remove(barcode);
                                } else {
                                  _barcodeSelected.add(barcode);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.grey,
                                        size: 18,
                                      ),
                                      const Spacer(),
                                      if (isSelected)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "เลือกแล้ว",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: _fontSize(
                                                  10), // ปรับขนาดตัวอักษร
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          product["name"] ?? "",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: _fontSize(
                                                14), // ปรับขนาดตัวอักษร
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            barcode,
                                            style: TextStyle(
                                              fontSize: _fontSize(
                                                  12), // ปรับขนาดตัวอักษร
                                              color: Colors.grey.shade700,
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
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _barcodeSelected.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context, _barcodeSelected);
              },
              backgroundColor: Colors.green,
              icon: const Icon(Icons.check, size: 20),
              label: Text(
                "ยืนยัน (${_barcodeSelected.length})",
                style: TextStyle(fontSize: _fontSize(14)), // ปรับขนาดตัวอักษร
              ),
            )
          : null,
    );
  }
}
