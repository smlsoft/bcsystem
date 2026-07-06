import 'dart:async';
import 'dart:io';
import 'package:dedecashier/flavors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:dedecashier/services/barcode_api_service.dart';
import 'package:dedecashier/model/barcodecheck/barcodemaster_model.dart';
import 'package:dedecashier/model/unit_model.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/core/logger/app_logger.dart';

class ScannedItem {
  final String barcode;
  BarcodeMasterModel? product; // สินค้าจากร้านปัจจุบัน
  final BarcodeMasterModel? productCenter; // สินค้าจากร้านกลาง
  String status; // 'found', 'not_found', 'newly_created', 'copied_from_center', 'saved', 'data_inconsistent'
  double? editablePrice; // ราคาที่สามารถแก้ไขได้
  String? editableUnit; // หน่วยนับที่สามารถแก้ไขได้
  List<String>? inconsistencyDetails; // รายละเอียดความไม่สอดคล้อง

  ScannedItem({required this.barcode, this.product, this.productCenter, required this.status, this.editablePrice, this.editableUnit, this.inconsistencyDetails});
}

class BarcodeChecker extends StatefulWidget {
  const BarcodeChecker({super.key});

  @override
  State<BarcodeChecker> createState() => _BarcodeCheckerState();
}

class _BarcodeCheckerState extends State<BarcodeChecker> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  final BarcodeApiService _apiService = BarcodeApiService();
  final Color _themeColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);

  // State variables
  bool isScannerActive = false;
  bool isLoading = false;
  bool isSaving = false;
  List<ScannedItem> scannedItems = [];
  List<ScannedItem> itemsToSave = [];
  String lastScannedBarcode = '';
  BarcodeMasterModel? lastFoundProduct;

  // Form controllers
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _manualBarcodeController = TextEditingController();

  // Focus nodes
  final FocusNode _manualBarcodeFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();
  final Map<String, FocusNode> _priceFocusNodes = {}; // เก็บ FocusNode สำหรับ price field ของแต่ละ barcode
  final Map<String, FocusNode> _unitFocusNodes = {}; // เก็บ FocusNode สำหรับ unit field ของแต่ละ barcode

  // Units data
  List<UnitModel> availableUnits = [];
  String? selectedUnitCode;
  bool isLoadingUnits = false;
  Timer? _timer;

  // Barcode scanning variables
  String _barcodeBuffer = '';
  Timer? _barcodeTimer;
  int _lastKeyTime = 0;
  final int _bufferTimeout = 500; // milliseconds

  @override
  void dispose() {
    _timer?.cancel();
    _barcodeTimer?.cancel();
    controller?.dispose();
    _barcodeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _manualBarcodeController.dispose();
    _manualBarcodeFocusNode.dispose();
    _keyboardFocusNode.dispose();
    // Dispose all price focus nodes
    for (var focusNode in _priceFocusNodes.values) {
      focusNode.dispose();
    }
    _priceFocusNodes.clear();
    // Dispose all unit focus nodes
    for (var focusNode in _unitFocusNodes.values) {
      focusNode.dispose();
    }
    _unitFocusNodes.clear();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUnits();

    // เพิ่ม listener สำหรับ focus management
    _manualBarcodeFocusNode.addListener(() {
      if (!_manualBarcodeFocusNode.hasFocus && mounted) {
        // เมื่อ TextField หมด focus ให้ keyboard focus node รับ focus แทน
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !_manualBarcodeFocusNode.hasFocus && !_priceFocusNodes.values.any((fn) => fn.hasFocus)) {
            _keyboardFocusNode.requestFocus();
          }
        });
      }
    });

    // ให้ keyboard focus node รับ focus เริ่มต้น
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _keyboardFocusNode.requestFocus();
      }
    });
  } // Load units from API

  Future<void> _loadUnits() async {
    setState(() {
      isLoadingUnits = true;
    });

    try {
      final units = await _apiService.getUnits();
      setState(() {
        availableUnits = units;
        isLoadingUnits = false;
      });
    } catch (e) {
      setState(() {
        isLoadingUnits = false;
      });
      if (mounted) {
        _showError('ไม่สามารถโหลดข้อมูลหน่วยนับได้: $e');
      }
    }
  }

  // Initialize QR controller
  void onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (isScannerActive && scanData.code != null) {
        _handleBarcodeScanned(scanData.code!);
      }
    });
  }

  // Handle barcode scanning - ล้างรายการและเพิ่มใหม่ทุกครั้ง
  Future<void> _handleBarcodeScanned(String barcode) async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
      lastScannedBarcode = barcode;
      // ล้างรายการเก่าและเริ่มใหม่
      _clearPriceFocusNodes();
      scannedItems.clear();
      itemsToSave.clear();
    });

    try {
      // Pause camera while processing
      await controller?.pauseCamera();

      // Search for product in current shop and center shop
      BarcodeMasterModel? product;
      try {
        product = await _apiService.searchByBarcode(barcode, "");
      } catch (e) {
        product = null;
      }

      BarcodeMasterModel? productCenter;

      // Only search in center shop if mainShopId is not empty
      if (global.mainShopId.isNotEmpty && global.mainShopId != "" && global.productCenterType != 0) {
        try {
          productCenter = await _apiService.searchByBarcode(barcode, global.mainShopId);
        } catch (e) {
          productCenter = null;
        }
      }

      // Determine status based on search results
      String status;
      if (product != null) {
        status = 'found';
      } else if (productCenter != null) {
        status = 'found_center_only';
      } else {
        status = 'not_found';
      }

      // Add to list with both product data
      _addToScannedList(ScannedItem(barcode: barcode, product: product, productCenter: productCenter, status: status));

      // ตรวจสอบและดึงบาร์โค้ดที่เกี่ยวข้อง
      await _fetchRelatedBarcodes(product, productCenter, barcode);

      // จัดเรียงให้บาร์โค้ดหลักขึ้นก่อน และเตรียมรายการสำหรับบันทึก
      _prepareItemsForSaving();
    } catch (e) {
      // Add to list even if error
      _addToScannedList(ScannedItem(barcode: barcode, product: null, productCenter: null, status: 'not_found'));
    } finally {
      setState(() {
        isLoading = false;
      });

      // Resume camera after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        if (isScannerActive && mounted) {
          controller?.resumeCamera();
        }
      });
    }
  }

  // Add item to scanned list
  void _addToScannedList(ScannedItem item) {
    setState(() {
      // Remove if already exists and add to top
      scannedItems.removeWhere((existingItem) => existingItem.barcode == item.barcode);
      scannedItems.insert(0, item);

      // Keep only last 50 items
      if (scannedItems.length > 50) {
        scannedItems = scannedItems.take(50).toList();
      }
    });
  }

  // จัดเรียงและเตรียมรายการสำหรับบันทึก
  void _prepareItemsForSaving() {
    setState(() {
      itemsToSave.clear();

      // แยกบาร์โค้ดหลักและรอง
      List<ScannedItem> mainItems = [];
      List<ScannedItem> subItems = [];

      for (var item in scannedItems) {
        // ตรวจสอบว่าเป็นบาร์โค้ดหลักหรือรอง (ใช้ product เป็นหลัก ถ้าไม่มีใช้ productCenter)
        bool isSubBarcode = false;

        // ตรวจสอบจาก product ในร้านปัจจุบันก่อน
        if (item.product != null && item.product!.refbarcodes.isNotEmpty) {
          isSubBarcode = true;
        }
        // ถ้าไม่มี product ในร้านปัจจุบัน ให้ตรวจสอบจาก productCenter
        else if (item.product == null && item.productCenter != null && item.productCenter!.refbarcodes.isNotEmpty) {
          isSubBarcode = true;
        }

        // ตรวจสอบความตรงกันของข้อมูลถ้ามีทั้งในร้านปัจจุบันและร้านกลาง
        if (item.product != null && item.productCenter != null) {
          _validateProductDataConsistency(item);
        }

        if (isSubBarcode) {
          subItems.add(item);
        } else {
          mainItems.add(item);
        }
      }

      // เรียงลำดับ: บาร์โค้ดหลัก (refbarcodes = []) ก่อน แล้วตามด้วยบาร์โค้ดรอง
      itemsToSave.addAll(mainItems);
      itemsToSave.addAll(subItems);

      // เรียงลำดับใน scannedItems ด้วยเพื่อให้ UI แสดงผลตามลำดับที่ถูกต้อง
      scannedItems.clear();
      scannedItems.addAll(mainItems);
      scannedItems.addAll(subItems);

      // คัดลอกสินค้าจากร้านกลางอัตโนมัติถ้าไม่พบในร้านปัจจุบัน
      for (var item in itemsToSave) {
        if (item.status == 'found_center_only' && item.productCenter != null) {
          _createProductFromCenter(item);
        }
      }

      // กรองเฉพาะสินค้าที่ต้องพิจารณาสำหรับการบันทึก (ไม่รวมสินค้าที่มีในร้านแล้ว)
      itemsToSave = itemsToSave
          .where(
            (item) => item.status != 'found', // ไม่เอาสินค้าที่มีในร้านแล้ว
          )
          .toList();
    });
  }

  // สร้างสินค้าจากร้านกลางอัตโนมัติ
  void _createProductFromCenter(ScannedItem item) {
    if (item.productCenter == null) return;

    var centerProduct = item.productCenter!;

    // สร้าง BarcodeMasterModel ใหม่จากข้อมูลร้านกลาง
    BarcodeMasterModel newProduct = BarcodeMasterModel(
      barcode: item.barcode,
      names: centerProduct.names,
      prices: centerProduct.prices,
      itemunitcode: centerProduct.itemunitcode,
      itemunitnames: centerProduct.itemunitnames,
      refguidfixed: centerProduct.guidfixed,
      refbarcodes: centerProduct.refbarcodes,
      itemcode: centerProduct.itemcode,
      imageuri: centerProduct.imageuri,
    );

    // อัปเดต item ให้มีข้อมูล product ใหม่
    item.product = newProduct;
    item.status = 'copied_from_center';
    // ตั้งค่าราคาที่สามารถแก้ไขได้
    item.editablePrice = centerProduct.prices.isNotEmpty ? centerProduct.prices.first.price : 0.0;
  }

  // ตรวจสอบความสอดคล้องของข้อมูลสินค้าระหว่างร้านปัจจุบันและร้านกลาง
  void _validateProductDataConsistency(ScannedItem item) {
    if (item.product == null || item.productCenter == null) return;

    var currentProduct = item.product!;
    var centerProduct = item.productCenter!;

    List<String> inconsistencies = [];

    // เปรียบเทียบชื่อสินค้า
    if (currentProduct.names.isNotEmpty && centerProduct.names.isNotEmpty) {
      String currentName = currentProduct.names.first.name;
      String centerName = centerProduct.names.first.name;
      if (currentName != centerName) {
        inconsistencies.add('ชื่อสินค้า: "${currentName}" ≠ "${centerName}"');
      }
    }

    // เปรียบเทียบหน่วยนับ
    if (currentProduct.itemunitcode != centerProduct.itemunitcode) {
      String currentUnit = currentProduct.itemunitnames.isNotEmpty ? currentProduct.itemunitnames.first.name : currentProduct.itemunitcode;
      String centerUnit = centerProduct.itemunitnames.isNotEmpty ? centerProduct.itemunitnames.first.name : centerProduct.itemunitcode;
      inconsistencies.add('หน่วยนับ: "${currentUnit}" ≠ "${centerUnit}"');
    }

    // เปรียบเทียบ refbarcodes
    if (!_compareRefBarcodes(currentProduct.refbarcodes, centerProduct.refbarcodes)) {
      inconsistencies.add('บาร์โค้ดอ้างอิง: ไม่ตรงกัน');
    }

    // อัปเดตสถานะถ้ามีความไม่สอดคล้อง
    if (inconsistencies.isNotEmpty) {
      item.status = 'data_inconsistent';
      item.inconsistencyDetails = inconsistencies;
    }
  }

  // เปรียบเทียบ refbarcodes
  bool _compareRefBarcodes(List<dynamic> refBarcodes1, List<dynamic> refBarcodes2) {
    if (refBarcodes1.length != refBarcodes2.length) return false;

    // ถ้าทั้งคู่เป็น list ว่าง ถือว่าตรงกัน
    if (refBarcodes1.isEmpty && refBarcodes2.isEmpty) return true;

    // เปรียบเทียบแต่ละ element
    for (int i = 0; i < refBarcodes1.length; i++) {
      var ref1 = refBarcodes1[i];
      var ref2 = refBarcodes2[i];

      if (ref1 is Map<String, dynamic> && ref2 is Map<String, dynamic>) {
        // เปรียบเทียบ barcode field
        if (ref1['barcode'] != ref2['barcode']) return false;
      } else {
        // เปรียบเทียบค่าโดยตรง
        if (ref1 != ref2) return false;
      }
    }

    return true;
  }

  // ฟังก์ชันช่วยสำหรับ clear และ dispose price และ unit focus nodes
  void _clearPriceFocusNodes() {
    for (var focusNode in _priceFocusNodes.values) {
      focusNode.dispose();
    }
    _priceFocusNodes.clear();
    for (var focusNode in _unitFocusNodes.values) {
      focusNode.dispose();
    }
    _unitFocusNodes.clear();
  }

  // บันทึกสินค้าทั้งหมด
  Future<void> _saveAllItems() async {
    if (itemsToSave.isEmpty) {
      _showError('ไม่มีรายการที่ต้องบันทึก');
      return;
    }

    // ตรวจสอบว่ามีสินค้าที่ข้อมูลไม่สอดคล้องหรือไม่
    final inconsistentItems = itemsToSave.where((item) => item.status == 'data_inconsistent').toList();
    if (inconsistentItems.isNotEmpty) {
      _showError('ไม่สามารถบันทึกได้ เพราะมีสินค้า ${inconsistentItems.length} รายการที่ข้อมูลไม่ตรงกับร้านกลาง');
      return;
    }

    setState(() {
      isSaving = true;
    });

    bool isDialogShowing = false;

    try {
      int successCount = 0;
      int errorCount = 0;

      // แยกสินค้าที่ต้องบันทึกออกเป็น 2 กลุ่ม: สินค้าหลักและสินค้ารอง
      List<ScannedItem> mainItems = [];
      List<ScannedItem> subItems = [];

      for (var item in itemsToSave) {
        if (item.product != null && (item.status == 'copied_from_center' || item.status == 'newly_created')) {
          // ตรวจสอบว่าเป็นสินค้าหลักหรือรอง
          bool isSubProduct = item.product!.refbarcodes.isNotEmpty;

          if (isSubProduct) {
            subItems.add(item);
          } else {
            mainItems.add(item);
          }
        }
      }

      // บันทึกสินค้าหลักก่อน (ตามลำดับ)
      for (int i = 0; i < mainItems.length; i++) {
        var item = mainItems[i];

        // ปิด dialog เก่าก่อน (ถ้ามี)
        if (isDialogShowing && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        // แสดง loading dialog
        _showSavingDialog(context, 'กำลังบันทึกสินค้าหลัก', item.barcode, i + 1, mainItems.length + subItems.length);
        isDialogShowing = true;

        // รอให้ dialog แสดงก่อนเริ่มบันทึก
        await Future.delayed(const Duration(milliseconds: 100));

        try {
          // อัปเดตราคาถ้ามีการแก้ไข
          if (item.editablePrice != null && item.product!.prices.isNotEmpty) {
            item.product!.prices.first.price = item.editablePrice!;
          }

          final success = await _apiService.addNewProduct(item.product!);
          if (success) {
            successCount++;
            item.status = 'saved';
            if (mounted) {
              setState(() {}); // อัปเดต UI ให้แสดงสถานะใหม่
            }
          } else {
            errorCount++;
            if (isDialogShowing && Navigator.canPop(context)) {
              Navigator.of(context).pop(); // ปิด loading dialog
              isDialogShowing = false;
            }
            _showError('บันทึกสินค้าหลัก (${item.barcode}) ล้มเหลว - หยุดการบันทึก');
            setState(() {
              isSaving = false;
            });
            return; // หยุดการบันทึกทันที
          }
        } catch (e) {
          errorCount++;
          AppLogger.error('Error saving main item ${item.barcode}: $e');
          if (isDialogShowing && Navigator.canPop(context)) {
            Navigator.of(context).pop(); // ปิด loading dialog
            isDialogShowing = false;
          }
          _showError('เกิดข้อผิดพลาดในการบันทึกสินค้าหลัก (${item.barcode}): $e - หยุดการบันทึก');
          setState(() {
            isSaving = false;
          });
          return; // หยุดการบันทึกทันที
        }
      }

      // บันทึกสินค้ารองหลังจากสินค้าหลักบันทึกเสร็จแล้ว (ตามลำดับ)
      for (int i = 0; i < subItems.length; i++) {
        var item = subItems[i];

        // ปิด dialog เก่าก่อน (ถ้ามี)
        if (isDialogShowing && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        // แสดง loading dialog
        _showSavingDialog(context, 'กำลังบันทึกสินค้ารอง', item.barcode, mainItems.length + i + 1, mainItems.length + subItems.length);
        isDialogShowing = true;

        // รอให้ dialog แสดงก่อนเริ่มบันทึก
        await Future.delayed(const Duration(milliseconds: 100));

        try {
          // อัปเดตราคาถ้ามีการแก้ไข
          if (item.editablePrice != null && item.product!.prices.isNotEmpty) {
            item.product!.prices.first.price = item.editablePrice!;
          }

          final success = await _apiService.addNewProduct(item.product!);
          if (success) {
            successCount++;
            item.status = 'saved';
            if (mounted) {
              setState(() {}); // อัปเดต UI ให้แสดงสถานะใหม่
            }
          } else {
            errorCount++;
            if (isDialogShowing && Navigator.canPop(context)) {
              Navigator.of(context).pop(); // ปิด loading dialog
              isDialogShowing = false;
            }
            _showError('บันทึกสินค้ารอง (${item.barcode}) ล้มเหลว - หยุดการบันทึก');
            setState(() {
              isSaving = false;
            });
            return; // หยุดการบันทึกทันที
          }
        } catch (e) {
          errorCount++;
          AppLogger.error('Error saving sub item ${item.barcode}: $e');
          if (isDialogShowing && Navigator.canPop(context)) {
            Navigator.of(context).pop(); // ปิด loading dialog
            isDialogShowing = false;
          }
          _showError('เกิดข้อผิดพลาดในการบันทึกสินค้ารอง (${item.barcode}): $e - หยุดการบันทึก');
          setState(() {
            isSaving = false;
          });
          return; // หยุดการบันทึกทันที
        }
      }

      // รอ 1 วินาทีก่อนปิด dialog และดึงข้อมูลใหม่
      await Future.delayed(const Duration(seconds: 1));

      // หาบาร์โค้ดหลักจากรายการที่บันทึกสำเร็จ
      String? mainBarcodeToRefresh;
      for (var item in [...mainItems, ...subItems]) {
        if (item.status == 'saved' && item.product != null) {
          if (item.product!.refbarcodes.isEmpty) {
            // นี่คือบาร์โค้ดหลัก
            mainBarcodeToRefresh = item.barcode;
            break;
          } else if (item.product!.refbarcodes.isNotEmpty) {
            // นี่คือบาร์โค้ดรอง ให้หาบาร์โค้ดหลักจาก refbarcodes
            var firstRefBarcode = item.product!.refbarcodes.first;
            if (firstRefBarcode is Map<String, dynamic> && firstRefBarcode.containsKey('barcode')) {
              mainBarcodeToRefresh = firstRefBarcode['barcode']?.toString() ?? '';
              break;
            }
          }
        }
      }

      // ปิด loading dialog
      if (isDialogShowing && Navigator.canPop(context)) {
        Navigator.of(context).pop();
        isDialogShowing = false;
      }

      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('บันทึกสำเร็จ $successCount รายการ${errorCount > 0 ? ' (ล้มเหลว $errorCount รายการ)' : ''}'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        // ล้างรายการหลังบันทึกสำเร็จ
        setState(() {
          _clearPriceFocusNodes();
          scannedItems.clear();
          itemsToSave.clear();
        });

        // ดึงข้อมูลบาร์โค้ดหลักใหม่หลังจากบันทึกสำเร็จ
        if (mainBarcodeToRefresh != null && mainBarcodeToRefresh.isNotEmpty) {
          await Future.delayed(const Duration(milliseconds: 500)); // รอให้ UI อัปเดตก่อน
          await _handleBarcodeScanned(mainBarcodeToRefresh);
        }
      } else {
        _showError('ไม่สามารถบันทึกรายการได้');
      }
    } catch (e) {
      // ปิด dialog ถ้ายังแสดงอยู่
      if (isDialogShowing && Navigator.canPop(context)) {
        Navigator.of(context).pop();
        isDialogShowing = false;
      }
      _showError('เกิดข้อผิดพลาดในการบันทึก: $e');
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  // ดึงบาร์โค้ดที่เกี่ยวข้องตาม logic ใหม่
  Future<void> _fetchRelatedBarcodes(BarcodeMasterModel? product, BarcodeMasterModel? productCenter, String scannedBarcode) async {
    try {
      String mainBarcode = "";

      if (product != null && product.refbarcodes.isEmpty) {
        // สินค้าหลักจากร้านปัจจุบัน
        mainBarcode = scannedBarcode;
      } else if (productCenter != null && productCenter.refbarcodes.isEmpty) {
        // สินค้าหลักจากร้านกลาง
        mainBarcode = scannedBarcode;
      } else if (product != null && product.refbarcodes.isNotEmpty) {
        // สินค้าย่อยจากร้านปัจจุบัน - หา mainBarcode จาก refbarcodes
        var firstRefBarcode = product.refbarcodes.first;
        if (firstRefBarcode is Map<String, dynamic> && firstRefBarcode.containsKey('barcode')) {
          mainBarcode = firstRefBarcode['barcode']?.toString() ?? '';
        }
      } else if (productCenter != null && productCenter.refbarcodes.isNotEmpty) {
        // สินค้าย่อยจากร้านกลาง - หา mainBarcode จาก refbarcodes
        var firstRefBarcode = productCenter.refbarcodes.first;
        if (firstRefBarcode is Map<String, dynamic> && firstRefBarcode.containsKey('barcode')) {
          mainBarcode = firstRefBarcode['barcode']?.toString() ?? '';
        }
      }

      if (mainBarcode.isNotEmpty) {
        // ดึงบาร์โค้ดที่เกี่ยวข้องจาก API ทั้งสองร้าน
        List<BarcodeMasterModel> relatedProducts = [];
        Set<String> processedBarcodes = {};

        // ดึงจากร้านปัจจุบัน
        try {
          List<BarcodeMasterModel> currentShopRelated = await _apiService.getRelatedBarcodes(mainBarcode, shopsid: "");
          for (var product in currentShopRelated) {
            if (product.barcode.isNotEmpty && !processedBarcodes.contains(product.barcode)) {
              relatedProducts.add(product);
              processedBarcodes.add(product.barcode);
            }
          }
        } catch (e) {
          AppLogger.error('Error fetching related barcodes from current shop: $e');
        }

        // ดึงจากร้านกลาง
        if (global.mainShopId.isNotEmpty && global.productCenterType != 0) {
          try {
            List<BarcodeMasterModel> centerShopRelated = await _apiService.getRelatedBarcodes(mainBarcode, shopsid: global.mainShopId);
            for (var product in centerShopRelated) {
              if (product.barcode.isNotEmpty && !processedBarcodes.contains(product.barcode)) {
                relatedProducts.add(product);
                processedBarcodes.add(product.barcode);
              }
            }
          } catch (e) {
            AppLogger.error('Error fetching related barcodes from center shop: $e');
          }
        }

        // เพิ่ม mainBarcode เข้ารายการถ้าไม่ใช่บาร์โค้ดที่สแกน
        if (mainBarcode != scannedBarcode) {
          await _addBarcodeToList(mainBarcode);
        }

        // เพิ่มบาร์โค้ดที่เกี่ยวข้องทั้งหมด
        for (var relatedProduct in relatedProducts) {
          if (relatedProduct.barcode.isNotEmpty && relatedProduct.barcode != scannedBarcode) {
            await _addBarcodeToList(relatedProduct.barcode);
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error in _fetchRelatedBarcodes: $e');
    }
  }

  // เพิ่มบาร์โค้ดใหม่เข้ารายการ โดยค้นหาในทั้งสองร้าน
  Future<void> _addBarcodeToList(String barcode) async {
    // เช็คว่ามีในรายการแล้วหรือไม่
    if (scannedItems.any((item) => item.barcode == barcode)) {
      return;
    }

    try {
      // ค้นหาในร้านปัจจุบัน
      BarcodeMasterModel? product;
      try {
        product = await _apiService.searchByBarcode(barcode, "");
      } catch (e) {
        product = null;
      }

      // ค้นหาในร้านกลาง
      BarcodeMasterModel? productCenter;
      if (global.mainShopId.isNotEmpty && global.productCenterType != 0) {
        try {
          productCenter = await _apiService.searchByBarcode(barcode, global.mainShopId);
        } catch (e) {
          productCenter = null;
        }
      }

      // กำหนด status
      String status;
      if (product != null) {
        status = 'found';
      } else if (productCenter != null) {
        status = 'found_center_only';
      } else {
        status = 'not_found';
      }

      // เพิ่มเข้ารายการ
      _addToScannedList(ScannedItem(barcode: barcode, product: product, productCenter: productCenter, status: status));
    } catch (e) {
      AppLogger.error('Error adding barcode $barcode to list: $e');
    }
  }

  Future<void> _processManualBarcode() async {
    AppLogger.debug('Processing manual barcode: ${_manualBarcodeController.text}');
    final barcode = _manualBarcodeController.text.trim();
    if (barcode.isEmpty) {
      _showError('กรุณาใส่บาร์โค้ด');
      return;
    }

    await _handleBarcodeScanned(barcode);
    setState(() {
      _manualBarcodeController.clear();
    });
  }

  // Handle keyboard events for barcode scanner
  void _handleKeyEvent(KeyEvent event) {
    try {
      AppLogger.debug("KeyEvent received: ${event.runtimeType} - ${event.logicalKey}");

      if (event is! KeyDownEvent) return;
      if (!mounted) return;

      if (kDebugMode) {
        AppLogger.debug('KeyDownEvent processed, mounted: $mounted');
        AppLogger.debug('Manual barcode focus: ${_manualBarcodeFocusNode.hasFocus}');
        AppLogger.debug('Keyboard focus: ${_keyboardFocusNode.hasFocus}');
      }

      // ถ้า manual barcode TextField หรือ price TextField มี focus ให้ข้าม
      if (_manualBarcodeFocusNode.hasFocus) {
        AppLogger.debug("Manual barcode TextField has focus, skipping KeyboardListener");
        return;
      }

      // ตรวจสอบว่า price focus nodes มี focus หรือไม่
      for (var focusNode in _priceFocusNodes.values) {
        if (focusNode.hasFocus) {
          AppLogger.debug("Price TextField has focus, skipping KeyboardListener");
          return;
        }
      }

      // ตรวจสอบว่า unit focus nodes มี focus หรือไม่
      for (var focusNode in _unitFocusNodes.values) {
        if (focusNode.hasFocus) {
          AppLogger.debug("Unit TextField has focus, skipping KeyboardListener");
          return;
        }
      }

      // ตรวจสอบว่า keyboard focus node ยังใช้งานได้
      if (!_keyboardFocusNode.hasFocus) {
        AppLogger.debug("Keyboard focus node lost focus, requesting focus");
        _keyboardFocusNode.requestFocus();
        return;
      }

      // Get character from key event
      String character = _getCharacterFromKeyEvent(event);
      AppLogger.debug("Character extracted: '$character'");
      if (character.isEmpty) return;

      int currentTime = DateTime.now().millisecondsSinceEpoch;

      // ตรวจสอบความเร็วการพิมพ์ (barcode scanner จะพิมพ์เร็วมาก)
      bool isPossibleScanner = (_lastKeyTime > 0 && (currentTime - _lastKeyTime) < 50);
      _lastKeyTime = currentTime;

      if (isPossibleScanner && kDebugMode) {
        AppLogger.debug('Rapid input detected - possible scanner');
      }

      // ตรวจสอบ Enter key (จบการสแกน)
      if (_isEnterKeyEvent(event)) {
        AppLogger.debug("Enter key detected, processing barcode: '$_barcodeBuffer'");
        _processScannedBarcode();
        return;
      }

      // เพิ่มตัวอักษรเข้า buffer
      _barcodeBuffer += character;
      AppLogger.debug("Barcode buffer updated: '$_barcodeBuffer'");

      // รีเซ็ต timer
      _barcodeTimer?.cancel();
      _barcodeTimer = Timer(Duration(milliseconds: _bufferTimeout), () {
        AppLogger.debug("Buffer timeout, processing barcode: '$_barcodeBuffer'");
        _processScannedBarcode();
      });
    } catch (e) {
      AppLogger.error("Error in _handleKeyEvent: $e");
    }
  }

  // ดึงตัวอักษรจาก KeyEvent
  String _getCharacterFromKeyEvent(KeyEvent event) {
    final logicalKey = event.logicalKey;

    AppLogger.debug("KeyEvent details: ${event.runtimeType} - ${event.logicalKey} - Character: '${event.character}' - Unicode: ${event.character?.codeUnits}");

    // ตรวจสอบ Unicode code point สำหรับ Zebra Scanner และ scanner อื่นๆ
    if (event.character != null && event.character!.isNotEmpty) {
      String char = event.character!;

      // ตรวจสอบว่าเป็น Unicode code points หรือไม่
      if (_isUnicodeCodePoints(char)) {
        String converted = _convertUnicodeCodePointsToString(char);
        AppLogger.debug("Unicode converted: '$char' -> '$converted'");
        return converted;
      }

      // ถ้าเป็น printable character ปกติ
      if (char.codeUnitAt(0) >= 32 && char.codeUnitAt(0) <= 126) {
        return char;
      }
    }

    String result = '';

    // Handle numbers (0-9)
    if (logicalKey == LogicalKeyboardKey.digit0)
      result = '0';
    else if (logicalKey == LogicalKeyboardKey.digit1)
      result = '1';
    else if (logicalKey == LogicalKeyboardKey.digit2)
      result = '2';
    else if (logicalKey == LogicalKeyboardKey.digit3)
      result = '3';
    else if (logicalKey == LogicalKeyboardKey.digit4)
      result = '4';
    else if (logicalKey == LogicalKeyboardKey.digit5)
      result = '5';
    else if (logicalKey == LogicalKeyboardKey.digit6)
      result = '6';
    else if (logicalKey == LogicalKeyboardKey.digit7)
      result = '7';
    else if (logicalKey == LogicalKeyboardKey.digit8)
      result = '8';
    else if (logicalKey == LogicalKeyboardKey.digit9)
      result = '9';
    // Handle numpad numbers
    else if (logicalKey == LogicalKeyboardKey.numpad0)
      result = '0';
    else if (logicalKey == LogicalKeyboardKey.numpad1)
      result = '1';
    else if (logicalKey == LogicalKeyboardKey.numpad2)
      result = '2';
    else if (logicalKey == LogicalKeyboardKey.numpad3)
      result = '3';
    else if (logicalKey == LogicalKeyboardKey.numpad4)
      result = '4';
    else if (logicalKey == LogicalKeyboardKey.numpad5)
      result = '5';
    else if (logicalKey == LogicalKeyboardKey.numpad6)
      result = '6';
    else if (logicalKey == LogicalKeyboardKey.numpad7)
      result = '7';
    else if (logicalKey == LogicalKeyboardKey.numpad8)
      result = '8';
    else if (logicalKey == LogicalKeyboardKey.numpad9)
      result = '9';
    // Handle letters (A-Z)
    else if (logicalKey == LogicalKeyboardKey.keyA)
      result = 'A';
    else if (logicalKey == LogicalKeyboardKey.keyB)
      result = 'B';
    else if (logicalKey == LogicalKeyboardKey.keyC)
      result = 'C';
    else if (logicalKey == LogicalKeyboardKey.keyD)
      result = 'D';
    else if (logicalKey == LogicalKeyboardKey.keyE)
      result = 'E';
    else if (logicalKey == LogicalKeyboardKey.keyF)
      result = 'F';
    else if (logicalKey == LogicalKeyboardKey.keyG)
      result = 'G';
    else if (logicalKey == LogicalKeyboardKey.keyH)
      result = 'H';
    else if (logicalKey == LogicalKeyboardKey.keyI)
      result = 'I';
    else if (logicalKey == LogicalKeyboardKey.keyJ)
      result = 'J';
    else if (logicalKey == LogicalKeyboardKey.keyK)
      result = 'K';
    else if (logicalKey == LogicalKeyboardKey.keyL)
      result = 'L';
    else if (logicalKey == LogicalKeyboardKey.keyM)
      result = 'M';
    else if (logicalKey == LogicalKeyboardKey.keyN)
      result = 'N';
    else if (logicalKey == LogicalKeyboardKey.keyO)
      result = 'O';
    else if (logicalKey == LogicalKeyboardKey.keyP)
      result = 'P';
    else if (logicalKey == LogicalKeyboardKey.keyQ)
      result = 'Q';
    else if (logicalKey == LogicalKeyboardKey.keyR)
      result = 'R';
    else if (logicalKey == LogicalKeyboardKey.keyS)
      result = 'S';
    else if (logicalKey == LogicalKeyboardKey.keyT)
      result = 'T';
    else if (logicalKey == LogicalKeyboardKey.keyU)
      result = 'U';
    else if (logicalKey == LogicalKeyboardKey.keyV)
      result = 'V';
    else if (logicalKey == LogicalKeyboardKey.keyW)
      result = 'W';
    else if (logicalKey == LogicalKeyboardKey.keyX)
      result = 'X';
    else if (logicalKey == LogicalKeyboardKey.keyY)
      result = 'Y';
    else if (logicalKey == LogicalKeyboardKey.keyZ)
      result = 'Z';
    // Handle special characters commonly found in barcodes
    else if (logicalKey == LogicalKeyboardKey.minus)
      result = '-';
    else if (logicalKey == LogicalKeyboardKey.period)
      result = '.';
    else if (logicalKey == LogicalKeyboardKey.slash)
      result = '/';
    else if (logicalKey == LogicalKeyboardKey.space)
      result = ' ';

    AppLogger.debug("Character extracted from LogicalKey: '$result'");

    return result;
  }

  // ตรวจสอบว่าเป็น Unicode code points หรือไม่
  bool _isUnicodeCodePoints(String input) {
    // ถ้า string มี code units ที่มีค่ามากกว่า 127 (ASCII) และมีรูปแบบคล้าย Unicode
    if (input.length > 10 && input.codeUnits.any((unit) => unit > 127)) {
      return true;
    }

    // ตรวจสอบรูปแบบ Unicode code points ที่ได้จาก Zebra Scanner
    // รูปแบบ 4 หลัก: '0056005600530048004800560054004900530048005100530055'
    if (RegExp(r'^\d{4,}$').hasMatch(input) && input.length % 4 == 0) {
      return true;
    }

    // รูปแบบ 3 หลัก zero-padded ASCII: '056056053048048056054049053048051053055'
    if (RegExp(r'^\d{3,}$').hasMatch(input) && input.length % 3 == 0) {
      return true;
    }

    return false;
  }

  // แปลง Unicode code points เป็น string ปกติ
  String _convertUnicodeCodePointsToString(String unicodeString) {
    try {
      String result = '';

      AppLogger.debug("Converting Unicode string: '$unicodeString'");

      // ลองแปลงแบบ 4 หลักก่อน (UTF-16)
      if (unicodeString.length % 4 == 0) {
        for (int i = 0; i < unicodeString.length; i += 4) {
          String codePointStr = unicodeString.substring(i, i + 4);
          int? codePoint = int.tryParse(codePointStr);
          if (codePoint != null && codePoint >= 32 && codePoint <= 126) {
            result += String.fromCharCode(codePoint);
          }
        }
        if (result.isNotEmpty) {
          AppLogger.debug("4-digit conversion result: '$result'");
          return result;
        }
      }

      // ลองแปลงแบบ 3 หลัก (zero-padded ASCII)
      if (unicodeString.length % 3 == 0) {
        result = '';
        for (int i = 0; i < unicodeString.length; i += 3) {
          String codePointStr = unicodeString.substring(i, i + 3);
          int? codePoint = int.tryParse(codePointStr);
          if (codePoint != null && codePoint >= 32 && codePoint <= 126) {
            result += String.fromCharCode(codePoint);
          }
        }
        if (result.isNotEmpty) {
          AppLogger.debug("3-digit conversion result: '$result'");
          return result;
        }
      }

      // ถ้าแปลงไม่ได้ ให้ return string เดิม
      return result.isNotEmpty ? result : unicodeString;
    } catch (e) {
      AppLogger.error("Error converting Unicode: $e");
      return unicodeString;
    }
  }

  // ทำความสะอาด barcode - รองรับ Zebra Scanner Unicode
  String _cleanBarcode(String barcode) {
    if (kDebugMode) {
      AppLogger.debug("Cleaning barcode: '$barcode' (length: ${barcode.length})");
      AppLogger.debug('Code units: ${barcode.codeUnits}');
    }

    // ตรวจสอบว่าเป็น Unicode code points หรือไม่
    if (_isUnicodeCodePoints(barcode)) {
      String converted = _convertUnicodeCodePointsToString(barcode);
      AppLogger.debug("Unicode barcode converted: '$barcode' -> '$converted'");
      return converted.trim();
    }

    // ลบ whitespace และ control characters
    String cleaned = barcode.replaceAll(RegExp(r'[\s\r\n\t\x00-\x1F\x7F]'), '');

    // ลบ non-printable characters แต่เก็บ ASCII printable characters
    cleaned = cleaned.replaceAll(RegExp(r'[^\x20-\x7E]'), '');

    AppLogger.debug("Cleaned barcode: '$cleaned'");

    return cleaned.trim();
  }

  // ตรวจสอบว่า barcode ถูกต้องหรือไม่
  bool _isValidBarcode(String barcode) {
    // ตรวจสอบความยาว
    if (barcode.length < 3 || barcode.length > 50) {
      AppLogger.debug("Invalid barcode length: ${barcode.length}");
      return false;
    }

    // ตรวจสอบ pattern ของ barcode
    if (!RegExp(r'^[A-Za-z0-9\-\.\/\s]+$').hasMatch(barcode)) {
      AppLogger.debug("Invalid barcode pattern: '$barcode'");
      return false;
    }

    // ตรวจสอบ format ที่พบบ่อย
    return _isCommonBarcodeFormat(barcode);
  }

  // ตรวจสอบ format ของ barcode ที่พบบ่อย
  bool _isCommonBarcodeFormat(String barcode) {
    // EAN-13 (13 หลัก)
    if (RegExp(r'^\d{13}$').hasMatch(barcode)) return true;

    // EAN-8 (8 หลัก)
    if (RegExp(r'^\d{8}$').hasMatch(barcode)) return true;

    // UPC-A (12 หลัก)
    if (RegExp(r'^\d{12}$').hasMatch(barcode)) return true;

    // Code 128 (alphanumeric, 4+ ตัวอักษร)
    if (RegExp(r'^[A-Za-z0-9\-\.\/]{4,}$').hasMatch(barcode)) return true;

    // Custom formats - เพิ่มตามความต้องการของร้าน
    if (RegExp(r'^[PS]\d{6,}$').hasMatch(barcode)) return true; // เริ่มด้วย P หรือ S

    return false;
  }

  // ตรวจสอบว่าเป็น Enter key หรือไม่
  bool _isEnterKeyEvent(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter;
  }

  // ประมวลผลบาร์โค้ดที่สแกนได้
  void _processScannedBarcode() {
    AppLogger.debug("_processScannedBarcode called with buffer: '$_barcodeBuffer'");

    if (_barcodeBuffer.isNotEmpty) {
      final barcode = _barcodeBuffer.trim();
      _barcodeBuffer = '';
      _barcodeTimer?.cancel();

      AppLogger.debug("Processing scanned barcode: '$barcode'");

      if (barcode.isNotEmpty) {
        // ทำความสะอาดและตรวจสอบ barcode
        String cleanBarcode = _cleanBarcode(barcode);

        AppLogger.debug("Cleaned barcode: '$cleanBarcode'");

        if (_isValidBarcode(cleanBarcode)) {
          _handleBarcodeScanned(cleanBarcode);
        } else {
          AppLogger.debug("Invalid barcode rejected: '$cleanBarcode'");
        }
      }
    }
  } // Show add product dialog for specific barcode

  Future<void> _showAddProductDialog(String barcode, {BarcodeMasterModel? centerProduct}) async {
    _barcodeController.text = barcode;

    // ถ้ามี centerProduct ให้กรอกข้อมูลจากร้านกลาง
    if (centerProduct != null) {
      // กรอกชื่อสินค้า
      if (centerProduct.names.isNotEmpty) {
        _nameController.text = centerProduct.names.first.name;
      } else {
        _nameController.clear();
      }

      // กรอกราคา
      if (centerProduct.prices.isNotEmpty) {
        _priceController.text = centerProduct.prices.first.price.toString();
      } else {
        _priceController.text = '0';
      }

      // กรอกหน่วย - ต้องใช้ itemunitcode จาก centerProduct
      selectedUnitCode = centerProduct.itemunitcode;

      // ตรวจสอบว่ามีหน่วยนับที่ตรงกันในระบบหรือไม่
      final matchingUnit = availableUnits.firstWhere(
        (unit) => unit.unitcode == centerProduct.itemunitcode,
        orElse: () => UnitModel(guidfixed: '', unitcode: '', unitname1: '', names: []),
      );

      // ถ้าไม่พบหน่วยนับที่ตรงกัน ให้แจ้งเตือน
      if (matchingUnit.unitcode.isEmpty) {
        // ยังคงใช้ itemunitcode แต่จะแสดงเตือนภายหลัง
        selectedUnitCode = centerProduct.itemunitcode;
      }
    } else {
      // ถ้าไม่มี centerProduct ให้เคลียร์ข้อมูลเหมือนเดิม
      _nameController.clear();
      _priceController.text = '0'; // Default price to 0

      // Set default unit to "ชิ้น" if available
      if (availableUnits.isNotEmpty) {
        final defaultUnit = availableUnits.firstWhere((unit) => unit.unitcode != '', orElse: () => availableUnits.first);
        if (selectedUnitCode == null || selectedUnitCode!.isEmpty) {
          selectedUnitCode = defaultUnit.unitcode;
        }
      }
    }

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(centerProduct != null ? Icons.content_copy : Icons.add_shopping_cart, color: centerProduct != null ? Colors.blue : Colors.orange[700]),
              const SizedBox(width: 8),
              Text(centerProduct != null ? 'คัดลอกสินค้าจากร้านกลาง' : 'เพิ่มสินค้าใหม่'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (centerProduct != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue, width: 1),
                    ),
                    child: const Text('ข้อมูลด้านล่างมาจากร้านกลาง คุณสามารถแก้ไขได้ก่อนบันทึก', style: TextStyle(fontSize: 12, color: Colors.blue)),
                  ),
                TextField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(labelText: 'บาร์โค้ด', border: OutlineInputBorder()),
                  enabled: false,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'ชื่อสินค้า * (บังคับ)', border: OutlineInputBorder(), helperText: 'ต้องไม่เป็นค่าว่าง'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'ราคา (keynumber 1)', border: OutlineInputBorder(), suffixText: 'บาท', helperText: 'ค่าเริ่มต้น: 0'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatefulBuilder(
                        builder: (context, setDropdownState) {
                          // ตรวจสอบว่าหน่วยนับจาก centerProduct มีในระบบหรือไม่
                          bool isUnitNotFound = centerProduct != null && !availableUnits.any((unit) => unit.unitcode == centerProduct.itemunitcode);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                value: selectedUnitCode,
                                decoration: InputDecoration(labelText: 'หน่วย', border: const OutlineInputBorder(), helperText: centerProduct != null ? 'หน่วยจากร้านกลาง' : 'เลือกหน่วยนับ'),
                                isExpanded: true,
                                items: centerProduct != null
                                    ? [
                                        // สำหรับการคัดลอก แสดงเฉพาะหน่วยจาก centerProduct
                                        DropdownMenuItem<String>(
                                          value: centerProduct.itemunitcode,
                                          child: Text(centerProduct.itemunitnames.isNotEmpty ? centerProduct.itemunitnames.first.name : centerProduct.itemunitcode),
                                        ),
                                      ]
                                    : availableUnits.map((unit) {
                                        String displayName = unit.names.isNotEmpty ? unit.names.first.name : unit.unitcode;
                                        return DropdownMenuItem<String>(value: unit.unitcode, child: Text(displayName));
                                      }).toList(),
                                onChanged: centerProduct != null
                                    ? null // ปิดการเลือกเมื่อเป็นการคัดลอก
                                    : isLoadingUnits
                                    ? null
                                    : (String? newValue) {
                                        setDropdownState(() {
                                          selectedUnitCode = newValue;
                                        });
                                      },
                                hint: isLoadingUnits
                                    ? const Row(
                                        children: [
                                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                          SizedBox(width: 8),
                                          Text('กำลังโหลด...'),
                                        ],
                                      )
                                    : const Text('เลือกหน่วยนับ'),
                              ),
                              // แสดงข้อความเตือนเมื่อหน่วยจาก centerProduct ไม่มีในระบบ
                              if (isUnitNotFound)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.orange, width: 1),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning, color: Colors.orange[700], size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'หน่วยนับ "${centerProduct.itemunitcode}" ไม่พบในระบบ',
                                          style: TextStyle(color: Colors.orange[700], fontSize: 11, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
                // แสดงข้อความเตือนถ้าไม่มีหน่วยนับ
                if (availableUnits.isEmpty && !isLoadingUnits)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ไม่พบหน่วยนับ กรุณาตรวจสอบการเชื่อมต่อ',
                            style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
            ),
            StatefulBuilder(
              builder: (context, setDialogState) {
                // ตรวจสอบว่าหน่วยนับจาก centerProduct มีในระบบหรือไม่
                bool isUnitNotFoundFromCenter = centerProduct != null && !availableUnits.any((unit) => unit.unitcode == centerProduct.itemunitcode);

                // ปุ่มจะ disable ถ้าไม่มีหน่วยนับ หรือกำลัง loading หรือไม่พบหน่วยนับจากร้านกลาง
                bool isButtonDisabled = isLoading || availableUnits.isEmpty || isLoadingUnits || isUnitNotFoundFromCenter;

                return ElevatedButton.icon(
                  onPressed: isButtonDisabled
                      ? null
                      : () async {
                          final success = await _addNewProduct(centerProduct: centerProduct);
                          if (success == true && mounted) {
                            Navigator.of(context).pop(true);
                            if (mounted) {
                              await _handleBarcodeScanned(barcode);
                            }
                          }
                          // ถ้า success == false ไม่ต้องปิด dialog หลัก
                        },
                  icon: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(centerProduct != null ? Icons.content_copy : Icons.save),
                  label: Text(
                    isLoading
                        ? 'กำลังบันทึก...'
                        : availableUnits.isEmpty
                        ? 'ไม่พบหน่วยนับ'
                        : (centerProduct != null ? 'คัดลอก' : 'บันทึก'),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: isButtonDisabled ? Colors.grey : (centerProduct != null ? Colors.blue : Colors.green), foregroundColor: Colors.white),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Add new product with validation and confirmation
  Future<bool> _addNewProduct({BarcodeMasterModel? centerProduct}) async {
    // ตรวจสอบหน่วยนับก่อน
    if (availableUnits.isEmpty) {
      _showError('ไม่พบหน่วยนับ กรุณาตรวจสอบการเชื่อมต่อและลองใหม่');
      return false;
    }

    // Validation
    final barcode = _barcodeController.text.trim();
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final unit = selectedUnitCode ?? 'ชิ้น';

    // Check required fields
    if (barcode.isEmpty) {
      _showError('กรุณาใส่บาร์โค้ด');
      return false;
    }

    if (name.isEmpty) {
      _showError('กรุณาใส่ชื่อสินค้า (names[0] ต้องไม่เป็นค่าว่าง)');
      return false;
    }

    if (selectedUnitCode == null || selectedUnitCode!.isEmpty) {
      _showError('กรุณาเลือกหน่วยนับ');
      return false;
    }

    // ตรวจสอบ refbarcodes - ถ้ามี refbarcodes แสดงว่าเป็นสินค้ารอง ต้องมีสินค้าหลักในร้านก่อน
    if (centerProduct != null && centerProduct.refbarcodes.isNotEmpty) {
      // หาบาร์โค้ดของสินค้าหลักจาก refbarcodes
      String mainBarcode = '';
      var firstRefBarcode = centerProduct.refbarcodes.first;
      if (firstRefBarcode is Map<String, dynamic> && firstRefBarcode.containsKey('barcode')) {
        mainBarcode = firstRefBarcode['barcode']?.toString() ?? '';
      }

      if (mainBarcode.isNotEmpty) {
        // ตรวจสอบว่ามีสินค้าหลักในร้านปัจจุบันหรือไม่
        try {
          final mainProduct = await _apiService.searchByBarcode(mainBarcode, "");
          if (mainProduct == null) {
            _showError('ไม่สามารถเพิ่มสินค้ารองได้\nต้องเพิ่มสินค้าหลัก (บาร์โค้ด: $mainBarcode) เข้าร้านก่อน');
            return false;
          }
        } catch (e) {
          _showError('ไม่สามารถตรวจสอบสินค้าหลักได้: $e');
          return false;
        }
      }
    }

    // Validate price (keynumber 1 must not be empty, default to 0)
    double price = 0.0;
    if (priceText.isNotEmpty) {
      price = double.tryParse(priceText) ?? 0.0;
      if (price < 0) {
        _showError('ราคาต้องมีค่าไม่น้อยกว่า 0');
        return false;
      }
    }

    // Get selected unit name
    final selectedUnit = availableUnits.firstWhere(
      (unit) => unit.unitcode == selectedUnitCode,
      orElse: () => UnitModel(
        guidfixed: '',
        unitcode: unit,
        unitname1: '',
        names: [UnitName(code: 'th', name: unit, isauto: false, isdelete: false)],
      ),
    );
    final unitName = selectedUnit.names.isNotEmpty
        ? selectedUnit.names
              .firstWhere(
                (name) => name.code == 'th',
                orElse: () => UnitName(code: 'th', name: unit, isauto: false, isdelete: false),
              )
              .name
        : unit;

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(barcode, name, price, unitName, isCopyFromCenter: centerProduct != null, centerProduct: centerProduct);
    if (!confirmed) return false;

    setState(() {
      isLoading = true;
    });

    List<ItemUnitName> itemUnitNames = [];
    selectedUnit.names.forEach((unitName) {
      itemUnitNames.add(ItemUnitName(code: unitName.code, name: unitName.name));
    });

    List<ItemName> itemNames = [];
    if (centerProduct != null && centerProduct.names.isNotEmpty) {
      // ใช้ชื่อจาก centerProduct ถ้ามี
      centerProduct.names.forEach((name) {
        itemNames.add(ItemName(code: name.code, name: name.name));
      });
    } else {
      // ถ้าไม่มี ให้ใช้ชื่อที่กรอกในฟอร์ม
      itemNames.add(ItemName(code: "th", name: name));
    }

    try {
      BarcodeMasterModel newProduct = BarcodeMasterModel(
        barcode: barcode,
        names: itemNames,
        prices: [PriceInfo(keynumber: 1, price: price)],
        itemunitcode: unit,
        itemunitnames: itemUnitNames,
        refguidfixed: centerProduct?.guidfixed ?? '',
        refbarcodes: centerProduct != null ? centerProduct.refbarcodes : [],
        itemcode: centerProduct != null ? centerProduct.itemcode : '',
      );

      final success = await _apiService.addNewProduct(newProduct);
      if (success) {
        // อัปเดต ScannedItem ในรายการ scannedItems
        final existingItemIndex = scannedItems.indexWhere((item) => item.barcode == barcode);
        if (existingItemIndex != -1) {
          setState(() {
            scannedItems[existingItemIndex].product = newProduct;
            scannedItems[existingItemIndex].status = centerProduct != null ? 'copied_from_center' : 'newly_created';
          });
        }

        // อัปเดต ScannedItem ในรายการ itemsToSave
        final existingSaveItemIndex = itemsToSave.indexWhere((item) => item.barcode == barcode);
        if (existingSaveItemIndex != -1) {
          setState(() {
            itemsToSave[existingSaveItemIndex].product = newProduct;
            itemsToSave[existingSaveItemIndex].status = centerProduct != null ? 'copied_from_center' : 'newly_created';
            // ตั้งค่าราคาแก้ไขได้ถ้าเป็นการคัดลอกหรือสร้างใหม่
            if (newProduct.prices.isNotEmpty) {
              itemsToSave[existingSaveItemIndex].editablePrice = newProduct.prices.first.price;
            }
          });
        } else {
          // ถ้าไม่มีใน itemsToSave ให้เพิ่มเข้าไป (กรณีสร้างใหม่)
          setState(() {
            itemsToSave.add(
              ScannedItem(
                barcode: barcode,
                product: newProduct,
                productCenter: centerProduct,
                status: centerProduct != null ? 'copied_from_center' : 'newly_created',
                editablePrice: newProduct.prices.isNotEmpty ? newProduct.prices.first.price : 0.0,
              ),
            );
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(centerProduct != null ? Icons.content_copy : Icons.add_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(centerProduct != null ? 'คัดลอกสินค้าจากร้านกลางสำเร็จ' : 'เพิ่มสินค้าใหม่สำเร็จ'),
              ],
            ),
            backgroundColor: centerProduct != null ? Colors.blue : Colors.green,
          ),
        );

        return true;
      }
    } catch (e) {
      _showError('ไม่สามารถเพิ่มสินค้าได้: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
    return false;
  }

  // Show confirmation dialog before adding new product
  Future<bool> _showConfirmationDialog(String barcode, String name, double price, String unit, {bool isCopyFromCenter = false, BarcodeMasterModel? centerProduct}) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(isCopyFromCenter ? Icons.content_copy : Icons.help_outline, color: isCopyFromCenter ? Colors.blue : Colors.orange),
                  const SizedBox(width: 8),
                  Text(isCopyFromCenter ? 'ยืนยันการคัดลอกสินค้า' : 'ยืนยันการเพิ่มสินค้า'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isCopyFromCenter ? 'กรุณาตรวจสอบข้อมูลก่อนคัดลอก:' : 'กรุณาตรวจสอบข้อมูลก่อนบันทึก:', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildInfoRow('บาร์โค้ด:', barcode),
                  _buildInfoRow('ชื่อสินค้า:', name),
                  _buildInfoRow('ราคา:', '${price.toStringAsFixed(2)} บาท'),
                  _buildInfoRow('หน่วย:', unit),
                  // แสดงเลขอ้างอิงถ้าเป็นการคัดลอก
                  if (isCopyFromCenter && centerProduct != null) _buildInfoRow('เลขอ้างอิง:', centerProduct.guidfixed.isNotEmpty ? centerProduct.guidfixed : 'ไม่มีเลขอ้างอิง'),
                  // แสดงประเภทสินค้าและบาร์โค้ดหลักถ้าเป็นสินค้ารอง
                  if (isCopyFromCenter && centerProduct != null && centerProduct.refbarcodes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.orange[700], size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'สินค้ารอง',
                                style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('บาร์โค้ดหลัก: ${(centerProduct.refbarcodes.first as Map<String, dynamic>)['barcode'] ?? 'ไม่ระบุ'}', style: TextStyle(color: Colors.orange[700], fontSize: 11)),
                          Text(
                            'หมายเหตุ: สินค้าหลักได้ถูกตรวจสอบแล้วว่ามีอยู่ในร้าน',
                            style: TextStyle(color: Colors.orange[700], fontSize: 10, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCopyFromCenter ? Colors.blue[50] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue, width: 1),
                    ),
                    child: Text(
                      isCopyFromCenter ? 'หมายเหตุ: สินค้าจะถูกคัดลอกจากร้านกลางพร้อมรหัสอ้างอิง' : 'หมายเหตุ: ข้อมูลนี้จะถูกบันทึกลงในระบบและไม่สามารถยกเลิกได้',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('ยกเลิก'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(isCopyFromCenter ? 'คัดลอก' : 'ยืนยัน'),
                  style: ElevatedButton.styleFrom(backgroundColor: isCopyFromCenter ? Colors.blue : Colors.green, foregroundColor: Colors.white),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Helper widget for confirmation dialog info rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // สร้าง widget สำหรับแสดง item แต่ละรายการ
  Widget _buildScannedItemCard(ScannedItem item, int index) {
    // Determine icon and color based on status
    IconData icon;
    Color iconColor;
    String statusText;

    switch (item.status) {
      case 'saved':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        statusText = 'บันทึกแล้ว';
        break;
      case 'copied_from_center':
        icon = Icons.content_copy;
        iconColor = Colors.blue;
        statusText = 'คัดลอกจากร้านกลาง';
        break;
      case 'found':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        statusText = 'พบในร้าน';
        break;
      case 'found_center_only':
        icon = Icons.info;
        iconColor = Colors.orange;
        statusText = 'พบเฉพาะในร้านกลาง';
        break;
      case 'data_inconsistent':
        icon = Icons.warning;
        iconColor = Colors.red;
        statusText = 'ข้อมูลไม่ตรงกับร้านกลาง';
        break;
      case 'not_found':
      default:
        icon = Icons.error;
        iconColor = Colors.red;
        statusText = 'ไม่พบสินค้า';
        break;
    }

    // Get product to display
    BarcodeMasterModel? displayProduct = item.product ?? item.productCenter;

    // ตรวจสอบว่าเป็นสินค้าหลักหรือรอง เพื่อแสดงป้าย
    String productTypeText = 'สินค้าหลัก';
    Color productTypeColor = Colors.blue[600]!;
    IconData productTypeIcon = Icons.star;

    // ตรวจสอบจาก product ในร้านปัจจุบันก่อน
    if (item.product != null && item.product!.refbarcodes.isNotEmpty) {
      productTypeText = 'สินค้ารอง';
      productTypeColor = Colors.orange[600]!;
      productTypeIcon = Icons.link;
    }
    // ถ้าไม่มี product ในร้านปัจจุบัน ให้ตรวจสอบจาก productCenter
    else if (item.product == null && item.productCenter != null && item.productCenter!.refbarcodes.isNotEmpty) {
      productTypeText = 'สินค้ารอง';
      productTypeColor = Colors.orange[600]!;
      productTypeIcon = Icons.link;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Colors.grey[50]!], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: iconColor.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: iconColor.withOpacity(0.3)),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.barcode,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                          ),
                          const SizedBox(width: 8),
                          // ป้ายแสดงประเภทสินค้า (หลัก/รอง)
                          if (displayProduct != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: productTypeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: productTypeColor.withOpacity(0.3), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(productTypeIcon, size: 10, color: productTypeColor),
                                  const SizedBox(width: 3),
                                  Text(
                                    productTypeText,
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: productTypeColor),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      Text(
                        statusText,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: iconColor),
                      ),
                    ],
                  ),
                ),
                // ปุ่มลบ
                IconButton(
                  onPressed: () {
                    setState(() {
                      // ลบและ dispose focus node ของ item นี้
                      final priceFocusNode = _priceFocusNodes.remove(item.barcode);
                      priceFocusNode?.dispose();
                      final unitFocusNode = _unitFocusNodes.remove(item.barcode);
                      unitFocusNode?.dispose();

                      scannedItems.removeAt(index);
                      itemsToSave.removeWhere((saveItem) => saveItem.barcode == item.barcode);
                    });
                  },
                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  tooltip: 'ลบรายการ',
                ),
              ],
            ),

            // Product details
            if (displayProduct != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Product image
                    _buildProductThumbnail(displayProduct, size: 60),
                    const SizedBox(width: 12),
                    // Product info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ชื่อสินค้า (อ่านอย่างเดียว)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              _getProductName(displayProduct),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              // ราคา (แก้ไขได้เฉพาะ copied_from_center หรือ newly_created เท่านั้น)
                              Expanded(
                                child: (item.status == 'copied_from_center' || item.status == 'newly_created')
                                    ? Builder(
                                        builder: (context) {
                                          // สร้าง FocusNode สำหรับ item นี้ถ้ายังไม่มี
                                          _priceFocusNodes.putIfAbsent(item.barcode, () {
                                            final focusNode = FocusNode();
                                            // เพิ่ม listener เพื่อจัดการ focus
                                            focusNode.addListener(() {
                                              if (!focusNode.hasFocus && mounted) {
                                                // เมื่อ price field หมด focus ให้ keyboard focus node รับ focus แทน
                                                Future.delayed(const Duration(milliseconds: 100), () {
                                                  if (mounted && !_manualBarcodeFocusNode.hasFocus && !_priceFocusNodes.values.any((fn) => fn.hasFocus)) {
                                                    _keyboardFocusNode.requestFocus();
                                                  }
                                                });
                                              }
                                            });
                                            return focusNode;
                                          });

                                          return TextFormField(
                                            focusNode: _priceFocusNodes[item.barcode],
                                            initialValue: (item.editablePrice ?? _getProductPrice(displayProduct)).toStringAsFixed(2),
                                            decoration: InputDecoration(
                                              labelText: 'ราคา',
                                              suffixText: 'บาท',
                                              border: const OutlineInputBorder(),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              labelStyle: TextStyle(fontSize: 12, color: Colors.orange[700]),
                                            ),
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                            onChanged: (value) {
                                              double? newPrice = double.tryParse(value);
                                              if (newPrice != null && newPrice >= 0) {
                                                setState(() {
                                                  item.editablePrice = newPrice;
                                                  // อัปเดตราคาใน itemsToSave ด้วย
                                                  final saveItemIndex = itemsToSave.indexWhere((saveItem) => saveItem.barcode == item.barcode);
                                                  if (saveItemIndex != -1) {
                                                    itemsToSave[saveItemIndex].editablePrice = newPrice;
                                                  }
                                                });
                                              }
                                            },
                                          );
                                        },
                                      )
                                    : Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: item.status == 'found' ? Colors.grey[100] : Colors.green[50],
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: item.status == 'found' ? Colors.grey[300]! : Colors.green[200]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'ราคา',
                                              style: TextStyle(fontSize: 10, color: item.status == 'found' ? Colors.grey[600] : Colors.green[700], fontWeight: FontWeight.w500),
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  '฿${_getProductPrice(displayProduct).toStringAsFixed(2)}',
                                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: item.status == 'found' ? Colors.grey[700] : Colors.green[700]),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 8),
                              // หน่วย (แก้ไขได้เฉพาะ copied_from_center หรือ newly_created เท่านั้น)
                              Expanded(
                                child: (item.status == 'copied_from_center' || item.status == 'newly_created')
                                    ? Builder(
                                        builder: (context) {
                                          // สร้าง FocusNode สำหรับ unit field ของ item นี้ถ้ายังไม่มี
                                          _unitFocusNodes.putIfAbsent(item.barcode, () {
                                            final focusNode = FocusNode();
                                            // เพิ่ม listener เพื่อจัดการ focus
                                            focusNode.addListener(() {
                                              if (!focusNode.hasFocus && mounted) {
                                                // เมื่อ unit field หมด focus ให้ keyboard focus node รับ focus แทน
                                                Future.delayed(const Duration(milliseconds: 100), () {
                                                  if (mounted &&
                                                      !_manualBarcodeFocusNode.hasFocus &&
                                                      !_priceFocusNodes.values.any((fn) => fn.hasFocus) &&
                                                      !_unitFocusNodes.values.any((fn) => fn.hasFocus)) {
                                                    _keyboardFocusNode.requestFocus();
                                                  }
                                                });
                                              }
                                            });
                                            return focusNode;
                                          });

                                          return TextFormField(
                                            readOnly: true,
                                            focusNode: _unitFocusNodes[item.barcode],
                                            initialValue: item.editableUnit ?? _getProductUnit(displayProduct),
                                            decoration: InputDecoration(
                                              labelText: 'หน่วยนับ',
                                              prefixIcon: Icon(Icons.straighten, size: 18, color: Colors.blue[700]),
                                              border: const OutlineInputBorder(),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              labelStyle: TextStyle(fontSize: 12, color: Colors.blue[700]),
                                            ),
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                                            onChanged: (value) {
                                              setState(() {
                                                item.editableUnit = value;
                                                // อัปเดตหน่วยใน itemsToSave ด้วย
                                                final saveItemIndex = itemsToSave.indexWhere((saveItem) => saveItem.barcode == item.barcode);
                                                if (saveItemIndex != -1) {
                                                  itemsToSave[saveItemIndex].editableUnit = value;
                                                }
                                              });
                                            },
                                          );
                                        },
                                      )
                                    : Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: item.status == 'found' ? Colors.grey[100] : Colors.blue[50],
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: item.status == 'found' ? Colors.grey[300]! : Colors.blue[200]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.straighten, size: 12, color: item.status == 'found' ? Colors.grey[600] : Colors.blue[700]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'หน่วยนับ',
                                                  style: TextStyle(fontSize: 10, color: item.status == 'found' ? Colors.grey[600] : Colors.blue[700], fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  _getProductUnit(displayProduct),
                                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: item.status == 'found' ? Colors.grey[700] : Colors.blue[800]),
                                                ),
                                              ],
                                            ),
                                          ],
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

              // แสดงรายละเอียดความไม่สอดคล้องถ้ามี
              if (item.status == 'data_inconsistent' && item.inconsistencyDetails != null && item.inconsistencyDetails!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'ข้อมูลไม่ตรงกับร้านกลาง',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...item.inconsistencyDetails!
                          .map(
                            (detail) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '• ',
                                    style: TextStyle(color: Colors.red[600], fontWeight: FontWeight.bold),
                                  ),
                                  Expanded(
                                    child: Text(detail, style: TextStyle(fontSize: 12, color: Colors.red[700])),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.red[700], size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'ไม่สามารถบันทึกข้อมูลได้ กรุณาตรวจสอบข้อมูลกับร้านกลาง',
                                style: TextStyle(fontSize: 11, color: Colors.red[700], fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else if (item.status == 'not_found') ...[
              // แสดงปุ่มเพิ่มสินค้าสำหรับรายการที่ไม่พบ
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(Icons.add_shopping_cart, size: 48, color: Colors.orange[600]),
                    const SizedBox(height: 12),
                    Text(
                      'ไม่พบสินค้านี้ในระบบ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.orange[800]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'คุณสามารถเพิ่มสินค้าใหม่เข้าสู่ระบบได้',
                      style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddProductDialog(item.barcode),
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('เพิ่มสินค้าใหม่', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  // แสดง dialog loading ขณะบันทึก
  void _showSavingDialog(BuildContext context, String title, String barcode, int current, int total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // ป้องกันการปิด dialog โดยการกด back
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    'บาร์โค้ด: $barcode',
                    style: TextStyle(fontSize: 14, color: Colors.blue[700], fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      Text(
                        'ความคืบหน้า',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: current / total, backgroundColor: Colors.grey[300], valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue)),
                      const SizedBox(height: 8),
                      Text(
                        '$current / $total รายการ',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'กรุณารอสักครู่...',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Get product name from multilingual names
  String _getProductName(BarcodeMasterModel product) {
    if (product.names.isNotEmpty) {
      return product.names.first.name;
    }
    return 'ไม่มีชื่อ';
  }

  // Get product price
  double _getProductPrice(BarcodeMasterModel product) {
    if (product.prices.isNotEmpty) {
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

  // Build product thumbnail widget
  Widget _buildProductThumbnail(BarcodeMasterModel product, {double size = 60}) {
    if (product.imageuri.isEmpty) {
      // แสดง placeholder icon ถ้าไม่มีรูป
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: size * 0.5),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Image.network(
          product.imageuri,
          fit: BoxFit.cover,
          width: size,
          height: size,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[100],
              child: Center(
                child: SizedBox(
                  width: size * 0.3,
                  height: size * 0.3,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue[400],
                    value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Icon(Icons.broken_image, color: Colors.grey[400], size: size * 0.5),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // คลิกที่ไหนก็ได้เพื่อให้ KeyboardListener ได้รับ focus
        if (!_manualBarcodeFocusNode.hasFocus) {
          _keyboardFocusNode.requestFocus();
          AppLogger.debug("GestureDetector tapped, requesting keyboard focus");
        }
      },
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text('ตรวจสอบบาร์โค้ด', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
              ],
            ),
            backgroundColor: _themeColor,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context, true); // ส่งค่ากลับเมื่อปิดหน้าจอ
              },
            ),
            actions: [
              // Debug button for testing keyboard input
              if (kDebugMode)
                IconButton(
                  icon: const Icon(Icons.keyboard),
                  onPressed: () {
                    _keyboardFocusNode.requestFocus();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Keyboard focus requested. Try typing or scanning now.'), duration: Duration(seconds: 2)));
                  },
                  tooltip: 'Test Keyboard Focus',
                ),
              if (Platform.isAndroid || Platform.isIOS)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        isScannerActive = !isScannerActive;
                      });
                    },
                    icon: Icon(isScannerActive ? Icons.stop : Icons.qr_code_scanner, size: 18),
                    label: Text(isScannerActive ? 'หยุดสแกน' : 'เริ่มสแกน', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isScannerActive ? Colors.red[600] : Colors.green[600],
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Manual barcode input section
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_themeColor.withOpacity(0.2)!, _themeColor.withOpacity(0.5)!], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _themeColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _themeColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: _themeColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: const Icon(Icons.keyboard, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'กรอกบาร์โค้ดด้วยตนเอง',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _themeColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _themeColor.withOpacity(0.5), width: 1.5),
                                boxShadow: [BoxShadow(color: _themeColor.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                              ),
                              child: TextField(
                                controller: _manualBarcodeController,
                                focusNode: _manualBarcodeFocusNode,
                                decoration: InputDecoration(
                                  hintText: 'พิมพ์บาร์โค้ดที่นี่...',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                ),
                                onSubmitted: (_) => _processManualBarcode(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: isLoading ? null : _processManualBarcode,
                              icon: isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search, size: 20),
                              label: const Text('ค้นหา', style: TextStyle(fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _themeColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Scanner section
              if (isScannerActive) ...[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 300,
                      child: Stack(
                        children: [
                          QRView(key: qrKey, onQRViewCreated: onQRViewCreated, formatsAllowed: const [BarcodeFormat.code128, BarcodeFormat.code39, BarcodeFormat.upcE]),
                          if (isLoading)
                            Container(
                              color: Colors.black.withOpacity(0.7),
                              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                            ),
                          // Enhanced scanner overlay
                          Center(
                            child: Container(
                              width: 250,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green, width: 3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.green[600]!, Colors.green[700]!], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.center_focus_strong, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'วางบาร์โค้ดในกรอบสีเขียว',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],

              // Scanned items list
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (scannedItems.isNotEmpty) ...[
                        // ปุ่มบันทึกทั้งหมด - แสดงเฉพาะเมื่อ productCenterType != 0 และมีสินค้าที่สามารถบันทึกได้
                        if (itemsToSave.isNotEmpty && global.productCenterType == 2 && itemsToSave.any((item) => item.status != 'not_found'))
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Builder(
                              builder: (context) {
                                // ตรวจสอบว่ามีสินค้าที่ข้อมูลไม่สอดคล้องหรือไม่
                                final hasInconsistentData = itemsToSave.any((item) => item.status == 'data_inconsistent');
                                final isButtonDisabled = isSaving || hasInconsistentData;

                                return Container(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: isButtonDisabled ? null : _saveAllItems,
                                    icon: isSaving
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : Icon(hasInconsistentData ? Icons.block : Icons.save, size: 20),
                                    label: Text(
                                      isSaving
                                          ? 'กำลังบันทึก...'
                                          : hasInconsistentData
                                          ? 'ข้อมูลไม่สอดคล้อง'
                                          : 'บันทึกทั้งหมด (${itemsToSave.length})',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: hasInconsistentData ? Colors.red[400] : Colors.green[600],
                                      foregroundColor: Colors.white,
                                      elevation: 3,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      // เพิ่ม disabled style
                                      disabledBackgroundColor: hasInconsistentData ? Colors.red[300] : Colors.grey[400],
                                      disabledForegroundColor: Colors.white70,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [_themeColor.withOpacity(0.5), _themeColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: _themeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: const Icon(Icons.list_alt, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'รายการที่สแกนแล้ว',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _themeColor),
                                    ),
                                    Text(
                                      '${scannedItems.length} รายการ',
                                      style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.red[200]!, width: 1),
                                ),
                                child: TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _clearPriceFocusNodes();
                                      scannedItems.clear();
                                      itemsToSave.clear();
                                    });
                                  },
                                  icon: Icon(Icons.clear_all, size: 16, color: Colors.red[600]),
                                  label: Text(
                                    'ล้างทั้งหมด',
                                    style: TextStyle(color: Colors.red[600], fontWeight: FontWeight.w600, fontSize: 12),
                                  ),
                                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: scannedItems.length,
                            itemBuilder: (context, index) {
                              final item = scannedItems[index];
                              return _buildScannedItemCard(item, index);
                            },
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [Colors.grey[300]!, Colors.grey[400]!], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                      borderRadius: BorderRadius.circular(50),
                                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                                    ),
                                    child: Icon(Icons.qr_code_2, size: 48, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'ยังไม่มีรายการ',
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue[200]!),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.info_outline, color: Colors.blue[600], size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'พิมพ์บาร์โค้ดในช่องด้านบนหรือเปิดกล้องสแกน',
                                          style: TextStyle(color: Colors.blue[600], fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (kDebugMode) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.orange[200]!),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.bug_report, color: Colors.orange[600], size: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Debug Info',
                                                style: TextStyle(color: Colors.orange[600], fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text('Keyboard Focus: ${_keyboardFocusNode.hasFocus}', style: TextStyle(color: Colors.orange[600], fontSize: 11)),
                                          Text('Manual Focus: ${_manualBarcodeFocusNode.hasFocus}', style: TextStyle(color: Colors.orange[600], fontSize: 11)),
                                          Text('Barcode Buffer: "$_barcodeBuffer"', style: TextStyle(color: Colors.orange[600], fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
