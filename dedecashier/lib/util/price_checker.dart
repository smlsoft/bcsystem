import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dedecashier/services/barcode_api_service.dart';
import 'package:dedecashier/model/barcodecheck/barcodemaster_model.dart';

class PriceChecker extends StatefulWidget {
  const PriceChecker({super.key});

  @override
  State<PriceChecker> createState() => _PriceCheckerState();
}

class _PriceCheckerState extends State<PriceChecker> {
  final BarcodeApiService _apiService = BarcodeApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  List<BarcodeMasterModel> products = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentOffset = 0;
  int limit = 50;
  String searchQuery = '';
  Timer? _searchTimer;
  BarcodeMasterModel? selectedProduct;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _priceController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  // Load products from API
  Future<void> _loadProducts({bool refresh = false}) async {
    if (isLoading) return;

    setState(() {
      if (refresh) {
        currentOffset = 0;
        products.clear();
        hasMore = true;
      }
      isLoading = refresh;
      isLoadingMore = !refresh;
    });

    try {
      final response = await _apiService.getProductList(
        search: searchQuery.isEmpty ? null : searchQuery,
        offset: currentOffset,
        limit: limit,
        zeroprice: true,
      );

      if (response['success'] == true) {
        List<dynamic> dataList = response['data'] ?? [];
        List<BarcodeMasterModel> newProducts = dataList.map((json) => BarcodeMasterModel.fromJson(json)).toList();

        setState(() {
          if (refresh) {
            products = newProducts;
          } else {
            products.addAll(newProducts);
          }

          currentOffset += newProducts.length;
          hasMore = newProducts.length >= limit;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('เกิดข้อผิดพลาดในการดึงข้อมูล: $e');
      }
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  // Handle scroll for pagination
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (hasMore && !isLoadingMore && !isLoading) {
        _loadProducts();
      }
    }
  }

  // Handle search
  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      if (searchQuery != value) {
        searchQuery = value;
        _loadProducts(refresh: true);
      }
    });
  }

  // Show price edit dialog
  Future<void> _showPriceEditDialog(BarcodeMasterModel product) async {
    selectedProduct = product;
    double currentPrice = _getProductPrice(product);
    _priceController.text = currentPrice > 0 ? currentPrice.toString() : '';

    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text('แก้ไขราคาสินค้า'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'บาร์โค้ด: ${product.barcode}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ชื่อสินค้า: ${_getProductName(product)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'หน่วยนับ: ${_getProductUnit(product)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ราคาปัจจุบัน: ${currentPrice.toStringAsFixed(2)} บาท',
                        style: TextStyle(
                          fontSize: 14,
                          color: currentPrice > 0 ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Price input
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ราคาใหม่ (บาท)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณาใส่ราคา';
                    }
                    if (double.tryParse(value) == null) {
                      return 'กรุณาใส่ตัวเลขที่ถูกต้อง';
                    }
                    if (double.parse(value) < 0) {
                      return 'ราคาต้องมากกว่าหรือเท่ากับ 0';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => _updatePrice(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
              ),
              child: const Text(
                'บันทึก',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Update product price
  Future<void> _updatePrice() async {
    if (selectedProduct == null) return;

    final priceText = _priceController.text.trim();
    if (priceText.isEmpty) {
      _showError('กรุณาใส่ราคา');
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null) {
      _showError('กรุณาใส่ตัวเลขที่ถูกต้อง');
      return;
    }

    if (price < 0) {
      _showError('ราคาต้องมากกว่าหรือเท่ากับ 0');
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('กำลังอัปเดตราคา...'),
          ],
        ),
      ),
    );

    try {
      await _apiService.updateProductPrice(selectedProduct!.guidfixed, price);

      // Close loading dialog
      if (Navigator.canPop(context)) Navigator.pop(context);

      // Close price edit dialog
      if (Navigator.canPop(context)) Navigator.pop(context);

      // Update product in list
      setState(() {
        int index = products.indexWhere((p) => p.guidfixed == selectedProduct!.guidfixed);
        if (index >= 0) {
          // Update price in the first price entry (keynumber 1)
          if (products[index].prices.isNotEmpty) {
            products[index].prices[0].price = price;
          }
        }
      });

      _showSuccess('อัปเดตราคาสำเร็จ');
    } catch (e) {
      // Close loading dialog
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showError('เกิดข้อผิดพลาดในการอัปเดตราคา: $e');
    }
  }

  // Build product item card
  Widget _buildProductCard(BarcodeMasterModel product) {
    double price = _getProductPrice(product);
    String productName = _getProductName(product);
    String unit = _getProductUnit(product);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showPriceEditDialog(product),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product thumbnail
              _buildProductThumbnail(product, size: 60),
              const SizedBox(width: 12),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'บาร์โค้ด: ${product.barcode}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'หน่วยนับ: $unit',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Price display
                    Row(
                      children: [
                        Icon(
                          Icons.money,
                          size: 16,
                          color: price > 0 ? Colors.green[700] : Colors.red[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          price > 0 ? '${price.toStringAsFixed(2)} บาท' : 'ยังไม่มีราคา',
                          style: TextStyle(
                            color: price > 0 ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Edit icon
              Icon(
                Icons.edit,
                color: Colors.blue[600],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build product thumbnail
  Widget _buildProductThumbnail(BarcodeMasterModel product, {double size = 60}) {
    if (product.imageuri.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.inventory_2,
          color: Colors.grey[400],
          size: size * 0.5,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          product.imageuri,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: size,
              height: size,
              color: Colors.grey[200],
              child: Icon(
                Icons.broken_image,
                color: Colors.grey[400],
                size: size * 0.5,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Get product name
  String _getProductName(BarcodeMasterModel product) {
    if (product.names.isNotEmpty) {
      return product.names.first.name;
    }
    return 'ไม่มีชื่อ';
  }

  // Get product price
  double _getProductPrice(BarcodeMasterModel product) {
    if (product.prices.isNotEmpty) {
      // Find price with keynumber 1
      for (var price in product.prices) {
        if (price.keynumber == 1) {
          return price.price;
        }
      }
      // If keynumber 1 not found, return first price
      return product.prices.first.price;
    }
    return 0.0;
  }

  // Get product unit
  String _getProductUnit(BarcodeMasterModel product) {
    if (product.itemunitnames.isNotEmpty) {
      return product.itemunitnames.first.name;
    }
    return product.itemunitcode;
  }

  // Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
      ),
    );
  }

  // Show success message
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มราคาสินค้า'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'ค้นหาสินค้า...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          searchQuery = '';
                          _loadProducts(refresh: true);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadProducts(refresh: true),
        child: Column(
          children: [
            // Summary info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'รายการสินค้าทั้งหมด: ${products.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (searchQuery.isNotEmpty)
                    Text(
                      'ค้นหา: "$searchQuery"',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            // Product list
            Expanded(
              child: isLoading && products.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                searchQuery.isNotEmpty ? 'ไม่พบสินค้าที่ค้นหา' : 'ไม่มีข้อมูลสินค้า',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: products.length + (isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= products.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _buildProductCard(products[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
