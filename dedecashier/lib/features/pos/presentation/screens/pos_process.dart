// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:dedecashier/core/core.dart';
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/pos_log_struct.dart';
import 'package:dedecashier/model/json/pos_process_model.dart';
import 'package:dedecashier/api/sync/model/promotion_model.dart';
import 'package:dedecashier/model/objectbox/product_barcode_struct.dart';
import 'package:dedecashier/model/objectbox/promotion_struct.dart';
import 'package:dedecashier/objectbox.g.dart';
import 'package:dedecashier/util/point_calculation_helper.dart';
import 'package:dedecashier/util/lru_cache.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_mock_promotion.dart';

class PosProcess {
  // 🗄️ LRU Cache สำหรับ Product Barcode (ลด DB queries 90%)
  static final LRUCache<String, ProductBarcodeObjectBoxStruct> _barcodeCache = LRUCache(maxSize: 500);

  // 🗄️ LRU Cache สำหรับ Product ค้นหาด้วย item_code
  static final LRUCache<String, ProductBarcodeObjectBoxStruct> _itemCodeCache = LRUCache(maxSize: 500);

  // 🗄️ LRU Cache สำหรับ JSON Options (ลด decode operations)
  static final LRUCache<String, List<dynamic>> _jsonOptionsCache = LRUCache(maxSize: 200);

  PosProcessModel processResult = PosProcessModel(details: [], select_promotion_temp_list: [], promotion_product_list: [], promotion_bottom_list: [], promotion_bonus_list: [], promotion_warning_list: [], promotion_coupon_list: []);

  PosProcessResultModel result = PosProcessResultModel();

  /// �️ Helper: ดึง Product Barcode จาก Cache หรือ DB
  /// - เช็ค cache ก่อน (O(1) lookup)
  /// - ถ้าไม่มี ค่อย query DB และ cache ผลลัพธ์
  /// - คาดว่าเร็วขึ้น 90% เมื่อ cache hit rate สูง
  Future<ProductBarcodeObjectBoxStruct?> _getCachedProductBarcode(String barcode) async {
    // ⚡ เช็ค cache ก่อน
    final cached = _barcodeCache.get(barcode);
    if (cached != null) {
      if (kDebugMode) {
        AppLogger.debug('[Cache] 🎯 HIT: $barcode');
      }
      return cached;
    }

    // 🔍 Cache miss - query DB
    if (kDebugMode) {
      AppLogger.debug('[Cache] ❌ MISS: $barcode - querying DB...');
    }

    final product = await global.productBarcodeHelper.selectByBarcodeFirst(barcode);

    // 💾 เก็บเข้า cache (ถ้าพบ)
    if (product != null) {
      _barcodeCache.put(barcode, product);
      if (kDebugMode) {
        AppLogger.debug('[Cache] 💾 STORED: $barcode (cache size: ${_barcodeCache.length}/${_barcodeCache.maxSize})');
      }
    }

    return product;
  }

  /// 🗄️ Helper: ดึง Product Barcode (base unit) จาก item_code โดยใช้ Cache
  ProductBarcodeObjectBoxStruct? _getCachedProductBarcodeByItemCode(String itemCode) {
    final cached = _itemCodeCache.get(itemCode);
    if (cached != null) {
      if (kDebugMode) AppLogger.debug('[Cache] 🎯 HIT (itemCode): $itemCode');
      return cached;
    }
    if (kDebugMode) AppLogger.debug('[Cache] ❌ MISS (itemCode): $itemCode - querying DB...');
    final product = global.productBarcodeHelper.selectByItemCodeFirst(itemCode);
    if (product != null) {
      _itemCodeCache.put(itemCode, product);
      if (kDebugMode) AppLogger.debug('[Cache] 💾 STORED (itemCode): $itemCode');
    }
    return product;
  }

  /// 🗄️ Helper: ดึง JSON Options จาก Cache
  /// - Cache decoded JSON เพื่อหลีกเลี่ยง jsonDecode ซ้ำๆ
  Future<List<dynamic>> _getCachedJsonOptions(String optionsJson) async {
    // เช็ค empty/null
    if (optionsJson == "null" || optionsJson.isEmpty) {
      return [];
    }

    // ⚡ เช็ค cache ก่อน
    final cached = _jsonOptionsCache.get(optionsJson);
    if (cached != null) {
      return cached;
    }

    // 🔍 Cache miss - decode JSON
    try {
      final decoded = await jsonDecode(optionsJson) as List<dynamic>;
      _jsonOptionsCache.put(optionsJson, decoded);
      return decoded;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('[Cache] JSON decode error: $e');
      }
      return [];
    }
  }

  /// �🔧 Helper: แปลงจำนวนเป็นหน่วยฐาน
  /// Formula: baseQty = qty × (unit_dividend / unit_divisor)
  /// Example: 2 กล่อง × (12 / 1) = 24 ชิ้น (base unit)
  double convertToBaseUnit({required double qty, required double unitDividend, required double unitDivisor}) {
    if (unitDivisor == 0) {
      AppLogger.warning('⚠️ Warning: unitDivisor = 0, returning 0');
      return 0;
    }
    final baseQty = (qty * unitDividend) / unitDivisor;
    AppLogger.debug('🔢 convertToBaseUnit: $qty × ($unitDividend / $unitDivisor) = $baseQty');
    return baseQty;
  }

  /// 🔧 Helper: คำนวณราคาต่อหน่วยฐาน
  /// Formula: pricePerBase = price / (unit_dividend / unit_divisor)
  /// Example: ราคา 120 บาท / (12 / 1) = 10 บาท/ชิ้น
  double getPricePerBaseUnit({required double price, required double unitDividend, required double unitDivisor}) {
    if (unitDivisor == 0 || unitDividend == 0) {
      AppLogger.debug('[PosProcess] ⚠️ Warning: division by zero, returning price as-is');
      return price;
    }
    final ratio = unitDividend / unitDivisor;
    final pricePerBase = price / ratio;
    AppLogger.debug('[PosProcess] 💰 getPricePerBaseUnit: $price / ($unitDividend / $unitDivisor) = $pricePerBase');
    return pricePerBase;
  }

  void sumCategoryCount({required PosProcessModel value}) {
    for (var product in global.productListByCategory) {
      product.product_count = 0;
      for (var transDetail in value.details) {
        if (product.barcode == transDetail.barcode && transDetail.is_void == false) {
          product.product_count += transDetail.qty;
        }
      }
    }
  }

  int findByBarCodeAndPrice(String barcode, double price, {bool lastLineOnly = false}) {
    int result = -1;
    if (lastLineOnly) {
      if (processResult.details.isNotEmpty) {
        int index = processResult.details.length - 1;
        if (barcode == processResult.details[index].barcode && price == processResult.details[index].price && processResult.details[index].is_void == false) {
          result = index;
        }
      }
    } else {
      for (int index = 0; index < processResult.details.length; index++) {
        if (barcode == processResult.details[index].barcode && price == processResult.details[index].price && processResult.details[index].is_void == false) {
          result = index;
          break;
        }
      }
    }
    return result;
  }

  int findByGuid(String guid) {
    int result = -1;
    for (int index = 0; index < processResult.details.length; index++) {
      if (guid == processResult.details[index].guid) {
        result = index;
        break;
      }
    }
    return result;
  }

  void processCalc(int index) {
    for (int extraIndex = 0; extraIndex < processResult.details[index].extra.length; extraIndex++) {
      processResult.details[index].extra[extraIndex].qty = processResult.details[index].qty;
      processResult.details[index].extra[extraIndex].total_amount = processResult.details[index].extra[extraIndex].qty * (processResult.details[index].extra[extraIndex].price);
    }
    if (processResult.details.isNotEmpty && index < processResult.details.length) {
      double calc = double.parse((processResult.details[index].qty * (processResult.details[index].price)).toStringAsFixed(2));
      processResult.details[index].total_amount = double.parse((calc).toStringAsFixed(2));
      processResult.details[index].total_amount_with_extra = processResult.details[index].total_amount;
      for (var extra in processResult.details[index].extra) {
        processResult.details[index].total_amount_with_extra += extra.total_amount;
      }
    }
  }

  PosProcessModel processSummery(PosProcessModel process, {required String holdCode, required String detailDiscountFormula, required bool cashRoundAmount, required bool discountFoodOnly}) {
    // เก็บค่า point จากการประมวลผลครั้งก่อน (ถ้ามี)
    int pointHoldIndex = global.findPosHoldProcessResultIndex(holdCode);
    double existingUsepoint = 0.0;
    double existingPointdiscountamount = 0.0;
    if (pointHoldIndex != -1) {
      existingUsepoint = global.posHoldProcessResult[pointHoldIndex].posProcess.usepoint;
      existingPointdiscountamount = global.posHoldProcessResult[pointHoldIndex].posProcess.pointdiscountamount;
    }

    // รวม
    double totalPiece = 0;
    double totalPieceVat = 0;
    double totalPieceExceptVat = 0;
    double totalItemVatAmount = 0;
    double totalItemExceptVatAmount = 0;
    for (int index = 0; index < processResult.details.length; index++) {
      if (processResult.details[index].is_void == false) {
        switch (processResult.details[index].food_type) {
          case 0:
            // อาหาร
            processResult.total_food_amount += processResult.details[index].total_amount - processResult.details[index].discount;
            break;
          case 1:
            // เครื่องดื่ม
            processResult.total_drink_amount += processResult.details[index].total_amount - processResult.details[index].discount;
            break;
          case 2:
            // เครื่องดื่มแอลกอฮอล์
            processResult.total_alcohol_amount += processResult.details[index].total_amount - processResult.details[index].discount;
            break;
          default:
            // อื่นๆ
            processResult.total_other_amount += processResult.details[index].total_amount - processResult.details[index].discount;
            break;
        }

        if (processResult.details[index].is_except_vat == false) {
          // สินค้ามี vat
          totalItemVatAmount += processResult.details[index].total_amount - processResult.details[index].discount;
          totalPieceVat += processResult.details[index].qty;
        } else {
          // สินค้าไม่มี vat
          totalItemExceptVatAmount += processResult.details[index].total_amount - processResult.details[index].discount;
          totalPieceExceptVat += processResult.details[index].qty;
        }
        totalPiece += processResult.details[index].qty;
        for (int extraIndex = 0; extraIndex < processResult.details[index].extra.length; extraIndex++) {
          if (processResult.details[index].extra[extraIndex].is_void == false) {
            switch (processResult.details[index].food_type) {
              case 0:
                // อาหาร
                processResult.total_food_amount += processResult.details[index].extra[extraIndex].total_amount;
                break;
              case 1:
                // เครื่องดื่ม
                processResult.total_drink_amount += processResult.details[index].extra[extraIndex].total_amount;
                break;
              case 2:
                // เครื่องดื่มแอลกอฮอล์
                processResult.total_alcohol_amount += processResult.details[index].extra[extraIndex].total_amount;
                break;
              default:
                // อื่นๆ
                processResult.total_other_amount += processResult.details[index].extra[extraIndex].total_amount;
                break;
            }
            if (processResult.details[index].extra[extraIndex].is_except_vat == false) {
              // สินค้ามี vat
              totalItemVatAmount += processResult.details[index].extra[extraIndex].total_amount;
            } else {
              // สินค้าไม่มี vat
              totalItemExceptVatAmount += processResult.details[index].extra[extraIndex].total_amount;
            }
          }
        }
      }
    }
    // Test Discount
    /*totalItemVatAmount = 315;
    totalItemExceptVatAmount = 10;
    detailDiscountFormula = "20";*/
    //
    processResult.is_vat_register = global.posConfig.isvatregister;
    processResult.vat_type = global.posConfig.vattype;
    processResult.vat_rate = global.posConfig.vatrate;
    processResult.total_piece = totalPiece;
    processResult.total_piece_vat = totalPieceVat;
    processResult.total_piece_except_vat = totalPieceExceptVat;
    processResult.total_item_vat_amount = totalItemVatAmount;
    processResult.total_item_except_vat_amount = totalItemExceptVatAmount;
    processResult.detail_total_amount_before_discount = totalItemVatAmount + totalItemExceptVatAmount;
    if (detailDiscountFormula.isNotEmpty) {
      processResult.detail_discount_formula = detailDiscountFormula;
    } else {
      // ✅ FIX: ใช้ค่าจาก posHoldProcessResult ของ holdCode นี้แทน global.discountFormular
      // เพื่อป้องกัน race condition เมื่อมีหลาย staff เรียก get_process พร้อมกัน
      int discountHoldIdx = global.findPosHoldProcessResultIndex(holdCode);
      if (discountHoldIdx != -1) {
        processResult.detail_discount_formula = global.posHoldProcessResult[discountHoldIdx].posProcess.detail_discount_formula;
      } else {
        processResult.detail_discount_formula = "";
      }
    }
    processResult.usepoint = existingUsepoint;

    processResult.pointdiscountamount = existingPointdiscountamount;
    // ✅ FIX: ใช้ holdCode parameter แทน global.posHoldActiveCode
    // เพื่อป้องกัน race condition - รีเซ็ตค่าผิดโต๊ะเมื่อมีหลาย staff เรียกพร้อมกัน
    int holdIndex = global.findPosHoldProcessResultIndex(holdCode);
    if (holdIndex != -1) {
      global.posHoldProcessResult[holdIndex].payScreenData.point_amount = 0;
    }
    double pointDiscountForTax = 0.0;
    double couponDiscountForTax = 0.0; // เพิ่มส่วนลดจากคูปอง
    if (holdIndex != -1) {
      final branchModels = global.profileSetting.branch.where((element) => element.guidfixed == global.posConfig.branch.guidfixed);
      final branchModel = branchModels.isNotEmpty ? branchModels.first : null;

      // ถ้า pointusagetype = 1 ให้รวม pointdiscountamount ในการคำนวณภาษี
      if (branchModel?.pointconfig.pointusagetype == 1) {
        pointDiscountForTax = processResult.pointdiscountamount;
      }

      // เพิ่มส่วนลดจากคูปองในการคำนวณภาษี (เฉพาะ discount_amount ไม่รวม cash_voucher_amount)
      // ✅ FIX: Copy list ก่อน iterate เพื่อป้องกัน ConcurrentModificationException
      final couponList = List.from(global.posHoldProcessResult[holdIndex].payScreenData.coupon);
      for (var coupon in couponList) {
        couponDiscountForTax += coupon.discount_amount;
      }
    }

    processResult.detail_total_discount = global.roundDouble(
      global.calcDiscountFormula(totalAmount: (discountFoodOnly) ? processResult.total_food_amount : processResult.detail_total_amount_before_discount, discountText: processResult.detail_discount_formula) +
          processResult.total_discount_from_promotion + // ✅ หักส่วนลดโปรโมชั่น (product + bottom) ออกจากยอดรวม
          pointDiscountForTax + // เพิ่ม pointdiscountamount เข้าไปในการคำนวณภาษีเฉพาะ pointusagetype = 1
          couponDiscountForTax, // เพิ่มส่วนลดจากคูปองในการคำนวณภาษี
      2,
    );
    if (processResult.is_vat_register) {
      if (processResult.vat_type == 0) {
        // ภาษีรวมใน
        // เฉลี่ยส่วนลด สินค้ามีภาษี
        double discountVatAmount = (processResult.detail_total_discount == 0) ? 0 : global.roundDouble((processResult.detail_total_discount * totalItemVatAmount) / (totalItemVatAmount + totalItemExceptVatAmount), 2);
        // สินค้ามีภาษี (คำนวณภาษี)
        double calcVatAmount = global.roundDouble((discountVatAmount * processResult.vat_rate) / (100 + processResult.vat_rate), 2);
        double calcDiscountVatAmount = discountVatAmount - calcVatAmount;
        // ยอดรวมสินค้ามีภาษีสุทธิ (หลังหักส่วนลด)
        double amountAfterCalcVat = processResult.total_item_vat_amount - (calcVatAmount + calcDiscountVatAmount);
        // ส่วนลดสินค้ามีภาษี
        processResult.total_discount_vat_amount = calcDiscountVatAmount + calcVatAmount;
        // สินค้ายกเว้นภาษี
        // ส่วนลดสินค้ายกเว้นภาษี
        double calcDiscountExceptVatAmount = processResult.detail_total_discount - (calcDiscountVatAmount + calcVatAmount);
        double totalVatAmount = global.roundDouble((amountAfterCalcVat * processResult.vat_rate) / (100 + processResult.vat_rate), 2);
        // ส่วนลดสินค้ายกเว้นภาษี
        processResult.total_discount_except_vat_amount = calcDiscountExceptVatAmount;
        // สินค้ายกเว้นภาษีสุทธิ
        processResult.amount_except_vat = totalItemExceptVatAmount - calcDiscountExceptVatAmount;
        // มูลค่าก่อนคิดภาษี
        processResult.amount_before_calc_vat = amountAfterCalcVat - totalVatAmount;
        // คำนวณยอดภาษี
        processResult.total_vat_amount = totalVatAmount;
        processResult.amount_after_calc_vat = amountAfterCalcVat;
        // รวมทั้งสิ้น
        processResult.total_amount = (amountAfterCalcVat + processResult.amount_except_vat);
      } else {
        // ภาษีแยกนอก
        // สินค้าทั่วไป
        // เฉลี่ยส่วนลด สินค้ามีภาษี
        double discountVatAmount = (processResult.detail_total_discount == 0) ? 0 : global.roundDouble((processResult.detail_total_discount * totalItemVatAmount) / (totalItemVatAmount + totalItemExceptVatAmount), 2);
        // ยอดรวมสินค้ามีภาษีสุทธิ (หลังหักส่วนลด)
        double amountAfterCalcVat = processResult.total_item_vat_amount - discountVatAmount;
        // ส่วนลดสินค้ามีภาษี
        processResult.total_discount_vat_amount = discountVatAmount;
        // สินค้ายกเว้นภาษี
        // ส่วนลดสินค้ายกเว้นภาษี
        double calcDiscountExceptVatAmount = processResult.detail_total_discount - discountVatAmount;
        double totalVatAmount = global.roundDouble((amountAfterCalcVat * (processResult.vat_rate / 100)), 2);
        // ส่วนลดสินค้ายกเว้นภาษี
        processResult.total_discount_except_vat_amount = calcDiscountExceptVatAmount;
        // สินค้ายกเว้นภาษีสุทธิ
        processResult.amount_except_vat = totalItemExceptVatAmount - calcDiscountExceptVatAmount;
        // มูลค่าก่อนคิดภาษี
        processResult.amount_before_calc_vat = amountAfterCalcVat;
        // คำนวณยอดภาษี
        processResult.total_vat_amount = totalVatAmount;
        processResult.amount_after_calc_vat = amountAfterCalcVat + totalVatAmount;
        // รวมทั้งสิ้น
        processResult.total_amount = (amountAfterCalcVat + processResult.amount_except_vat + totalVatAmount);
      }
    } else {
      // ไม่จบทะเบียนภาษีมูลค่าเพิ่ม
      // เฉลี่ยส่วนลด สินค้ามีภาษี
      double discountVatAmount = (processResult.detail_total_discount == 0) ? 0 : global.roundDouble((processResult.detail_total_discount * totalItemVatAmount) / (totalItemVatAmount + totalItemExceptVatAmount), 2);
      // ยอดรวมสินค้ามีภาษีสุทธิ (หลังหักส่วนลด)
      double amountAfterCalcVat = processResult.total_item_vat_amount - discountVatAmount;
      // ส่วนลดสินค้ามีภาษี
      processResult.total_discount_vat_amount = discountVatAmount;
      // สินค้ายกเว้นภาษี
      // ส่วนลดสินค้ายกเว้นภาษี
      double calcDiscountExceptVatAmount = processResult.detail_total_discount - discountVatAmount;
      // ส่วนลดสินค้ายกเว้นภาษี
      processResult.total_discount_except_vat_amount = calcDiscountExceptVatAmount;
      // สินค้ายกเว้นภาษีสุทธิ
      processResult.amount_except_vat = totalItemExceptVatAmount - calcDiscountExceptVatAmount;
      // มูลค่าก่อนคิดภาษี
      processResult.amount_before_calc_vat = amountAfterCalcVat;
      // คำนวณยอดภาษี
      processResult.total_vat_amount = 0;
      processResult.amount_after_calc_vat = amountAfterCalcVat;
      // รวมทั้งสิ้น
      processResult.total_amount = (amountAfterCalcVat + processResult.amount_except_vat);
    }
    if (cashRoundAmount) {
      processResult.total_amount_pay = global.roundMoneyForPay(processResult.total_amount);
      processResult.cash_round_amount = global.roundDouble(processResult.total_amount_pay - processResult.total_amount, 2);
    } else {
      processResult.cash_round_amount = 0;
      processResult.total_amount_pay = global.roundDouble(processResult.total_amount, 2);
    }

    if (holdIndex != -1) {
      final branchModels = global.profileSetting.branch.where((element) => element.guidfixed == global.posConfig.branch.guidfixed);
      final branchModel = branchModels.isNotEmpty ? branchModels.first : null;

      // ถ้ามีการใช้แต้ม ให้คำนวณส่วนลดหรือ point_amount ตาม pointusagetype
      if (processResult.usepoint > 0) {
        double pointValue = PointCalculationHelper.calculatePointDiscountAmount(pointsUsed: processResult.usepoint, pointConfig: branchModel?.pointconfig);

        // เช็ค pointusagetype
        if (branchModel?.pointconfig.pointusagetype == 1) {
          // ใช้เป็นส่วนลด
          processResult.pointdiscountamount = pointValue;
        } else if (branchModel?.pointconfig.pointusagetype == 2) {
          // ใช้เป็นการจ่ายชำระเงิน
          processResult.pointdiscountamount = 0;
          global.posHoldProcessResult[holdIndex].payScreenData.point_amount = pointValue;
        }
      } // คำนวณแต้มที่ได้รับจากยอดรวมของสินค้าที่มี issumpoint = true เท่านั้น
      double pointCalculationAmount = processResult.details.where((detail) => detail.issumpoint && !detail.is_void).fold(0.0, (sum, detail) => sum + detail.total_amount);

      processResult.getpoint = PointCalculationHelper.calculateEarnedPoints(totalAmount: pointCalculationAmount, pointConfig: branchModel?.pointconfig);
    } else {
      // ไม่ได้เลือกลูกค้า ไม่คำนวณแต้ม
      processResult.getpoint = 0.0;
      processResult.usepoint = 0.0;
      processResult.pointdiscountamount = 0.0;
    }

    return process;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔧 Command Handler Methods (Extracted from process() for better readability)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 📦 Handle case 1: เพิ่มสินค้า
  Future<void> _handleAddProduct(PosLogObjectBoxStruct logData, int count) async {
    int findIndex = -1;

    // ⚡ ใช้ cache แทน DB query (เร็วขึ้น 90%)
    ProductBarcodeObjectBoxStruct productBarcode =
        await _getCachedProductBarcode(logData.barcode) ??
        ProductBarcodeObjectBoxStruct(
          barcode: "",
          names: "",
          name_all: "",
          prices: "",
          unit_code: "",
          unit_stand: 1,
          unit_divide: 1,
          unit_names: "",
          new_line: 0,
          color_select: "",
          image_or_color: true,
          color_select_hex: "",
          images_url: "",
          guid_fixed: "",
          item_code: "",
          item_guid: "",
          vat_type: 1,
          descriptions: "",
          options_json: "",
          isalacarte: true,
          ordertypes: "",
          is_except_vat: false,
          issplitunitprint: false,
          product_count: 0,
          food_type: 1,
          is_resterant_use_stock: false,
          ref_barcode_json: "",
          patterncode: "",
        );

    // ✅ ตรวจสอบว่าพบ barcode หรือไม่
    if (productBarcode.barcode.isEmpty) {
      // ❌ ไม่พบ barcode - แจ้งเตือนผู้ใช้
      result.barcodeNotFound = true;
      result.barcodeNotFoundText = logData.barcode;

      // เล่นเสียง error (ดังกว่าเสียง beep ปกติ)
      global.playSound(sound: global.SoundEnum.fail);

      // Vibration สำหรับ mobile devices
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          HapticFeedback.heavyImpact(); // Vibration แรงกว่า lightImpact
        } catch (e) {
          AppLogger.error('[PosProcess] Vibration error: $e');
        }
      }

      AppLogger.debug('[PosProcess] ❌ Barcode not found: ${logData.barcode}');

      // Skip การประมวลผลต่อเนื่องสำหรับ barcode ที่ไม่พบ
      return;
    } else {
      // ✅ พบ barcode - รีเซ็ต flag
      result.barcodeNotFound = false;
      result.barcodeNotFoundText = "";

      AppLogger.debug('[PosProcess] ✅ Barcode found: ${logData.barcode} - ${productBarcode.names}');
    }

    // productBarcode.new_line = 1 (ทดสอบขึ้นบรรทัดใหม่ทุกครั้ง)
    productBarcode.new_line = 1;
    // ทดสอบ
    productBarcode.new_line = 0;
    //
    if (productBarcode.barcode.isNotEmpty && productBarcode.new_line == 1 || global.posScreenNewDataStyle == global.PosScreenNewDataStyleEnum.newLineOnly) {
      // กรณีสินค้าเป็นประเภทขุึ้นบรรทัดใหม่ทุกครั้ง หรือ ระบบกำหนดให้ขึ้นบรรทัดใหม่ทุกครั้ง
      findIndex = -1;
    } else {
      // กรณีมี Extra ให้เพิ่มบรรทัดใหม่
      if (productBarcode.options_json != "null" && productBarcode.options_json.isNotEmpty) {
        // ⚡ ใช้ cached JSON แทน decode ซ้ำๆ
        var valueOption = await _getCachedJsonOptions(productBarcode.options_json);
        if (valueOption.isNotEmpty) {
          findIndex = -1;
        } else {
          if (global.posScreenNewDataStyle == global.PosScreenNewDataStyleEnum.addLastLine) {
            findIndex = findByBarCodeAndPrice(logData.barcode, logData.price, lastLineOnly: true);
          } else if (global.posScreenNewDataStyle == global.PosScreenNewDataStyleEnum.addAllLine) {
            findIndex = findByBarCodeAndPrice(logData.barcode, logData.price);
          }
        }
      }
    }
    if (findIndex == -1) {
      // เพิ่มบรรทัด
      PosProcessDetailModel detail = PosProcessDetailModel(
        extra: [],
        index: count,
        barcode: logData.barcode,
        item_code: logData.code,
        item_name: logData.name,
        price: logData.price,
        price_original: logData.price,
        qty: logData.qty,
        total_amount: double.parse((logData.price * logData.qty).toStringAsFixed(2)),
        unit_code: logData.unit_code,
        unit_dividend: logData.unit_stand,
        unit_divisor: logData.unit_divide,
        unit_name: logData.unit_name,
        guid: logData.guid_auto_fixed,
        discount_text: "",
        discount: 0.0,
        total_amount_with_extra: 0,
        is_void: false,
        remark: logData.remark,
        issumpoint: logData.issumpoint,
        image_url: productBarcode.images_url,
        price_exclude_vat_type: logData.price_exclude_vat_type,
        is_except_vat: logData.is_except_vat,
        vat_type: 0,
        price_exclude_vat: 0,
        food_type: productBarcode.food_type,
        pattern_code: productBarcode.patterncode,
      );
      processResult.details.add(detail);
      result.lineGuid = detail.guid;
    } else {
      // เพิ่มจำนวน
      result.lineGuid = processResult.details[findIndex].guid;
      processResult.details[findIndex].qty = (processResult.details[findIndex].qty + logData.qty);
      processCalc(findIndex);
    }
  }

  /// 📦 Handle case 101: Check Box Extra
  void _handleCheckBoxExtra(PosLogObjectBoxStruct logData) {
    if (logData.is_void == 0) {
      final findIndex = findByGuid(logData.guid_ref);
      if (findIndex != -1) {
        // เพิ่มบรรทัด (Extra)
        final extra = PosProcessDetailExtraModel(
          index: processResult.details[findIndex].extra.length + 1,
          guid_code_or_ref: logData.guid_code_ref,
          barcode: logData.barcode,
          refbarcode: logData.refbarcode,
          refunitcode: logData.refunitcode,
          item_code: logData.code,
          item_name: logData.name,
          price: logData.price,
          qty: logData.qty,
          qty_fixed: logData.qty_fixed,
          unit_code: logData.unit_code,
          unit_name: logData.unit_name,
          unit_dividend: logData.unit_stand,
          unit_divisor: logData.unit_divide,
          guid_category: "",
          price_exclude_vat_type: logData.price_exclude_vat_type,
          is_except_vat: logData.is_except_vat,
          guid_auto_fixed: logData.guid_auto_fixed,
          is_void: processResult.details[findIndex].is_void,
          vat_type: 0,
          price_exclude_vat: 0,
          total_amount: double.parse((double.parse((logData.price).toStringAsFixed(2)) * processResult.details[findIndex].qty).toStringAsFixed(2)),
        );
        processResult.details[findIndex].extra.add(extra);
      }
    }
  }

  /// 📦 Handle case 2: เพิ่มจำนวน + 1
  void _handleIncreaseQuantity(PosLogObjectBoxStruct logData) {
    final findIndex = findByGuid(logData.guid_ref);
    if (findIndex != -1) {
      processResult.details[findIndex].qty = (processResult.details[findIndex].qty + 1.0);
      for (int index = 0; index < processResult.details[findIndex].extra.length; index++) {
        processResult.details[findIndex].extra[index].qty = (processResult.details[findIndex].extra[index].qty + 1.0);
      }
      processCalc(findIndex);
    }
  }

  /// 📦 Handle case 3: ลดจำนวน - 1
  void _handleDecreaseQuantity(PosLogObjectBoxStruct logData) {
    final findIndex = findByGuid(logData.guid_ref);
    if (findIndex != -1) {
      processResult.details[findIndex].qty = (processResult.details[findIndex].qty - 1.0);
      processCalc(findIndex);
    }
  }

  /// 📦 Handle case 4: แก้จำนวน
  void _handleEditQuantity(PosLogObjectBoxStruct logData) {
    final findIndex = findByGuid(logData.guid_ref);
    if (findIndex != -1) {
      processResult.details[findIndex].qty = logData.qty;
      processCalc(findIndex);
    }
  }

  /// 📦 Handle case 5: แก้ราคา
  void _handleEditPrice(PosLogObjectBoxStruct logData) {
    final findIndex = findByGuid(logData.guid_ref);
    if (findIndex != -1) {
      processResult.details[findIndex].price = logData.price;
      processCalc(findIndex);
    }
  }

  /// 📦 Handle case 8: แก้หมายเหตุ
  void _handleEditRemark(PosLogObjectBoxStruct logData) {
    final findIndex = findByGuid(logData.guid_ref);
    if (findIndex != -1) {
      processResult.details[findIndex].remark = logData.remark;
      processCalc(findIndex);
    }
  }

  /// 📦 Handle case 9: ลบรายการ
  void _handleDeleteItem(PosLogObjectBoxStruct logData) {
    final findIndex = findByGuid(logData.guid_ref);
    if (findIndex != -1) {
      processResult.details[findIndex].is_void = true;
      processCalc(findIndex);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════

  Future<PosProcessModel> process({required String holdCode, required int docMode, required String detailDiscountFormula, required String discountFormula, required bool cashRoundAmount, required bool discountFoodOnly}) async {
    // ค้นหา Barcode
    List<PosLogObjectBoxStruct> valueLog = (global.objectBoxStore.box<PosLogObjectBoxStruct>().query(
      PosLogObjectBoxStruct_.hold_code.equals(holdCode) & PosLogObjectBoxStruct_.is_void.equals(0) & PosLogObjectBoxStruct_.doc_mode.equals(docMode) & PosLogObjectBoxStruct_.success.equals(0),
    )..order(PosLogObjectBoxStruct_.log_date_time)).build().find();
    int count = 0;
    for (int index = 0; index < valueLog.length; index++) {
      // ประมวลผล จำนวน,ราคา
      PosLogObjectBoxStruct logData = valueLog[index];
      //print('Command : ' + _index.toString() + " " + _logData.commandCode.toString() + " " + _logData.command.toString());
      /* 
        -- command
        1=เพิ่มสินค้า
        2=เพิ่มจำนวน + 1
        3=ลดจำนวน - 1
        4=แก้จำนวน
        5=แก้ราคา
        6=แก้ส่วนลด
        8=หมายเหตุ
        9=ลบรายการสินค้า
        80=เปิดลิ้นชัก
        99=เริ่มใหม่
        101=Check Box Extra
      */
      result.lastCommandCode = logData.command_code;
      switch (logData.command_code) {
        case 101:
          // 101=Check Box Extra
          _handleCheckBoxExtra(logData);
          break;
        case 1:
          // 1=เพิ่มสินค้า
          await _handleAddProduct(logData, count);
          if (result.lineGuid.isNotEmpty) {
            // เพิ่ม count เมื่อสร้างรายการใหม่
            int findIndex = findByGuid(result.lineGuid);
            if (findIndex != -1 && processResult.details[findIndex].index == count) {
              count++;
            }
          }
          break;
        case 2:
          // 2=เพิ่มจำนวน + 1
          _handleIncreaseQuantity(logData);
          break;
        case 3:
          // 3=ลดจำนวน - 1
          _handleDecreaseQuantity(logData);
          break;
        case 4:
          // 4=แก้จำนวน
          _handleEditQuantity(logData);
          break;
        case 5:
          // 5=แก้ราคา
          _handleEditPrice(logData);
          break;
        case 8:
          // 8=แก้หมายเหตุ
          _handleEditRemark(logData);
          break;
        case 9:
          // 9=ลบรายการ
          _handleDeleteItem(logData);
          break;
      }
    }
    for (int index = 0; index < valueLog.length; index++) {
      // ประมวลผลส่วนลด
      if (valueLog[index].command_code == 6) {
        PosLogObjectBoxStruct logData = valueLog[index];
        // 6=แก้ส่วนลด
        int findIndex = findByGuid(logData.guid_ref);
        if (findIndex != -1) {
          processResult.details[findIndex].discount_text = logData.discount_text;
          double extraTotalAmount = 0;
          for (int extraIndex = 0; extraIndex < processResult.details[findIndex].extra.length; extraIndex++) {
            extraTotalAmount += processResult.details[findIndex].extra[extraIndex].total_amount;
          }
          double totalAmount = processResult.details[findIndex].qty * processResult.details[findIndex].price + extraTotalAmount;

          double discount = processResult.details[findIndex].discount = global.calcDiscountFormula(totalAmount: totalAmount, discountText: logData.discount_text);
          serviceLocator<Log>().trace("$extraTotalAmount:$totalAmount:$discount:${logData.discount_text}");
          processResult.details[findIndex].discount = discount;
          processCalc(findIndex);
        }
      }
    }
    List<PromotionModel> promotion1 = [];

    global.promotionMain.clear();

    // ดึง Promotion จากฐานข้อมูล
    var promotionData = global.objectBoxStore.box<PromotionObjectBoxStruct>().getAll();

    AppLogger.header('Starting Promotion Processing');
    AppLogger.debug('Total Promotions in DB: ${promotionData.length}');

    for (var promotion in promotionData) {
      promotion1.add(
        PromotionModel(
          type: promotion.type,
          index: promotion.index,
          promotion_code: promotion.promotion_code,
          date_begin: promotion.date_begin,
          date_end: promotion.date_end,
          promotion_name: promotion.promotion_name,
          discount_text: promotion.discount_text,
          limit_qty: promotion.limit_qty,
          limit_amount: promotion.limit_amount,
          promotion_qty: promotion.promotion_qty,
          promotion_item_code_include_list: promotion.promotion_item_code_include_list,
          customer_only: promotion.customer_only,
        ),
      );
    }
    global.promotionMain.add(PromotionMainModel(promotion_list: promotion1));

    // 🎟️ Mock Promotion: House Brand - หมุนวงล้อชิงรางวัล (Type 101)
    // ย้ายไปไฟล์ pos_mock_promotion.dart เพื่อแก้ไขง่ายขึ้น
    /*global.promotionMain.add(
      PosMockPromotion.getHouseBrandSpinWheelPromotion(),
    );*/

    // 🎉 Mock Promotion: โปรโมชั่นราคาพิเศษสินค้าก่อสร้าง (Type 4)
    // ย้ายไปไฟล์ pos_mock_promotion.dart เพื่อแก้ไขง่ายขึ้น
    // ✅ ตรวจสอบก่อนว่ามี Type 4 (Construction Materials) อยู่แล้วหรือยัง
    bool hasType4 = global.promotionMain.any((pm) => pm.promotion_list.any((p) => p.type == 4));
    if (!hasType4) {
      global.promotionMain.add(PosMockPromotion.getConstructionMaterialsPromotion());
    }

    // 🎁 Mock Promotion: Tier Redemption - แลกของแถมตาม Tier (Type 102)
    // โหลดจาก CSV พร้อม cache 5 นาที
    // ✅ ตรวจสอบก่อนว่ามี Type 102 อยู่แล้วหรือยัง
    // bool hasType102 = global.promotionMain.any((pm) => pm.promotion_list.any((p) => p.type == 102));
    // if (!hasType102) {
    //   global.promotionMain.add(await global.loadTierPromotions());
    // }

    // ⚡ Performance Measurement
    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
      AppLogger.header('🚀 Starting Promotion Processing');
    }

    // ประมวล Promotion
    // 🔄 NEW: จัดกลุ่มตาม item_code เท่านั้น (ไม่สนใจอัตราส่วน) + แปลงเป็น base unit
    List<PromotionDetailModel> promotionDetailList = [];

    // 🗺️ Map สำหรับแปลง barcode → item_code (ใช้ apply promotion กลับไปที่ details)
    Map<String, String> barcodeToItemCode = {};

    // ⚡ Map สำหรับ O(1) lookup แทน nested loops
    // ⭐ Key = item_code เท่านั้น (รวมทุกอัตราส่วนเข้าด้วยกัน)
    Map<String, PromotionDetailModel> itemCodeToPromotionDetail = {};

    AppLogger.debug('[PosProcess] 🎯 Building promotionDetailList (item_code based, ratio multiplied)...');

    for (var detail in processResult.details) {
      if (detail.barcode.isNotEmpty && detail.is_void == false) {
        // ⚡ ดึงข้อมูลสินค้าจาก cache เพื่อหา item_code + unit ratio
        var productBarcode = await _getCachedProductBarcode(detail.barcode);

        if (productBarcode == null) continue;

        // เก็บ mapping barcode → item_code
        barcodeToItemCode[detail.barcode] = productBarcode.item_code;

        // 🎯 คำนวณจำนวนเป็น base unit (คูณอัตราส่วนเข้าไปเลย)
        double baseUnitQty = convertToBaseUnit(qty: detail.qty, unitDividend: productBarcode.unit_stand, unitDivisor: productBarcode.unit_divide);

        // คำนวณราคาต่อ base unit
        double pricePerBase = getPricePerBaseUnit(price: detail.price, unitDividend: productBarcode.unit_stand, unitDivisor: productBarcode.unit_divide);

        // ⚡ ใช้ Map O(1) lookup (เช็ค item_code เท่านั้น ไม่สนใจอัตราส่วน)
        PromotionDetailModel? existingPromotion = itemCodeToPromotionDetail[productBarcode.item_code];

        if (existingPromotion == null) {
          // เพิ่มใหม่ (เก็บข้อมูลเป็น base unit)
          final newPromotion = PromotionDetailModel(
            item_name: productBarcode.names,
            item_code: productBarcode.barcode ?? productBarcode.item_code,
            qty: baseUnitQty, // 🎯 รวมจำนวน base unit
            promotion_balance_qty: baseUnitQty,
            promotion_used_qty: 0,
            price: pricePerBase, // ราคาต่อ base unit
            total_amount: detail.total_amount,
            unit_dividend: 1.0, // ⭐ ไม่เก็บอัตราส่วน เพราะแปลงเป็น base unit แล้ว
            unit_divisor: 1.0,
          );
          promotionDetailList.add(newPromotion);
          itemCodeToPromotionDetail[productBarcode.barcode ?? productBarcode.item_code] = newPromotion;

          AppLogger.debug(
            '[PosProcess] ➕ Added: ${productBarcode.item_code} | '
            'barcode=${detail.barcode} | '
            'qty=${detail.qty} (ratio ${productBarcode.unit_stand}:${productBarcode.unit_divide}) → base_qty=$baseUnitQty',
          );
        } else {
          // ⚡ รวม base unit เข้าด้วยกัน (ไม่สนใจอัตราส่วนที่แตกต่าง)
          existingPromotion.qty += baseUnitQty;
          existingPromotion.promotion_balance_qty += baseUnitQty;
          existingPromotion.total_amount += detail.total_amount;

          AppLogger.debug(
            '[PosProcess] ➕ Merged: ${productBarcode.item_code} | '
            'barcode=${detail.barcode} | '
            'add_qty=$baseUnitQty (ratio ${productBarcode.unit_stand}:${productBarcode.unit_divide}) → total=${existingPromotion.qty}',
          );
        }
      }
    }

    if (kDebugMode && promotionDetailList.isNotEmpty) {
      AppLogger.debug('📊 promotionDetailList Summary:');
      for (var item in promotionDetailList) {
        AppLogger.debug('  - ${item.item_code}: ${item.qty} base units @ ${item.price}/unit');
      }
    }
    if (promotionDetailList.isNotEmpty) {
      // clear debug
      // ⭐ สร้าง copy ของ list เพื่อป้องกัน ConcurrentModificationException
      final promotionMainCopy = List<PromotionMainModel>.from(global.promotionMain);
      for (var promotionMain in promotionMainCopy) {
        // ค้นหาราคาของแถม
        for (var promotion in promotionMain.promotion_list) {
          if (promotion.type == 1 || promotion.type == 6) {
            // 1=แถมสินค้าเมื่อซื้อสินค้าครบตามจำนวน
            for (var promotionInclude in promotion.promotion_item_code_include_list) {
              for (var promotionProduct in promotionInclude.include_product) {
                if (promotionProduct.price == 0) {
                  // ⚡ ค้นหาด้วย item_code (ข้อมูลจาก sync) แทน barcode
                  var productBarcode = _getCachedProductBarcodeByItemCode(promotionProduct.item_code);
                  if (productBarcode != null) {
                    promotionProduct.name = productBarcode.names;
                    promotionProduct.price = global.getProductPrice(productBarcode.prices, 1);
                  }
                }
              }
            }
          }
        }
        // reset promotion_balance_qty
        for (int index = 0; index < promotionDetailList.length; index++) {
          promotionDetailList[index].promotion_balance_qty = promotionDetailList[index].qty - promotionDetailList[index].promotion_used_qty;
        }
        for (var promotionIndex = 0; promotionIndex < promotionMain.promotion_list.length; promotionIndex++) {
          var promotion = promotionMain.promotion_list[promotionIndex];

          // ✅ ตรวจสอบวันที่ promotion (รวมวันที่เท่ากันด้วย)
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day); // เอาแค่วันที่ ไม่เอาเวลา
          final beginDate = DateTime(promotion.date_begin.year, promotion.date_begin.month, promotion.date_begin.day);
          final endDate = DateTime(promotion.date_end.year, promotion.date_end.month, promotion.date_end.day);

          // ✅ FIX: ใช้ <= และ >= เพื่อรองรับวันเดียวกัน (date_begin = date_end)
          bool promotionActive = false;
          String inactiveReason = '';

          // เช็คด้วย comparison ที่รวมวันที่เท่ากัน:
          // - today >= beginDate AND today <= endDate = ACTIVE
          // - today < beginDate = ยังไม่เริ่ม
          // - today > endDate = หมดอายุแล้ว

          if (today.isBefore(beginDate)) {
            // ⏰ ยังไม่ถึงวันที่เริ่ม (today < beginDate)
            inactiveReason = 'ยังไม่ถึงวันที่เริ่ม';
          } else if (today.isAfter(endDate)) {
            // ❌ หมดอายุแล้ว (today > endDate)
            inactiveReason = 'หมดอายุแล้ว';
          } else {
            // ✅ อยู่ในช่วงวันที่ (beginDate <= today <= endDate)
            // รองรับทั้งช่วงหลายวัน และวันเดียว (beginDate = endDate = today)
            promotionActive = true;
          }

          if (kDebugMode) {
            String status = promotionActive ? '✅ ACTIVE' : '❌ INACTIVE';
            AppLogger.debug('');
            AppLogger.debug('🎯 Promotion #$promotionIndex - Type ${promotion.type}');
            AppLogger.debug('Code: ${promotion.promotion_code}');
            AppLogger.debug('   Name: ${global.getNameFromJsonLanguage(promotion.promotion_name, global.userScreenLanguage)}');
            AppLogger.debug('   Date: ${promotion.date_begin.toString().substring(0, 10)} → ${promotion.date_end.toString().substring(0, 10)}');
            AppLogger.debug('   Today: ${today.toString().substring(0, 10)}');
            AppLogger.debug('Status: $status');
            if (!promotionActive) {
              if (today.isBefore(beginDate)) {
                final daysUntil = beginDate.difference(today).inDays;
                AppLogger.debug('Reason: $inactiveReason (อีก $daysUntil วัน)');
              } else if (today.isAfter(endDate)) {
                final daysAgo = today.difference(endDate).inDays;
                AppLogger.debug('Reason: $inactiveReason (เมื่อ $daysAgo วันที่แล้ว)');
              }
            }
          }

          // ⚠️ เตือนโปรโมชั่นที่ไม่ active (หมดอายุหรือยังไม่เริ่ม)
          if (!promotionActive && inactiveReason.isNotEmpty) {
            String warningMessage = '';
            String colorHex = '#808080'; // grey สำหรับ inactive

            if (today.isBefore(beginDate)) {
              final daysUntil = beginDate.difference(today).inDays;
              final thaiDate = global.dateTimeFormatThaiShortMonth(beginDate);

              // สร้างรายละเอียดสินค้าที่อยู่ในตะกร้า (เฉพาะที่เข้าโปรนี้)
              String productDetails = '';
              final matchedProducts = <String>[];

              // หาสินค้าในตะกร้าที่ตรงกับโปรนี้
              for (var include in promotion.promotion_item_code_include_list) {
                for (var product in include.promotion_product) {
                  // ⭐ เช็คว่าสินค้านี้อยู่ในตะกร้าหรือไม่ (ใช้ item_code เท่านั้น)
                  final matchedDetail = itemCodeToPromotionDetail[product.item_code];
                  if (matchedDetail != null) {
                    final productName = global.getNameFromJsonLanguage(product.name, global.userScreenLanguage);

                    // หา barcode จาก barcodeToItemCode Map (reverse lookup)
                    String? barcode;
                    for (var entry in barcodeToItemCode.entries) {
                      if (entry.value == product.item_code) {
                        barcode = entry.key;
                        break;
                      }
                    }
                    final barcodeText = barcode ?? product.item_code;

                    // จำนวนที่อยู่ในตะกร้า (base unit)
                    final cartQty = matchedDetail.qty;
                    // จำนวนที่ต้องซื้อตามโปร (แปลงเป็น base unit ด้วย)
                    final requiredQty = convertToBaseUnit(qty: product.qty, unitDividend: product.stand_value, unitDivisor: product.dived_value);

                    // แสดงอัตราส่วนถ้าไม่ใช่ 1:1
                    String ratioText = '';
                    if (product.stand_value != 1 || product.dived_value != 1) {
                      ratioText = ' (อัตราส่วน ${product.stand_value.toStringAsFixed(0)}:${product.dived_value.toStringAsFixed(0)})';
                    }

                    if (promotion.type == 4) {
                      // Type 4: แสดงชื่อ + barcode + จำนวน(กำลังทำ/ต้องซื้อครบ) + ราคาพิเศษ
                      matchedProducts.add(
                        "$productName ($barcodeText) กำลังทำรายการ ${cartQty.toStringAsFixed(0)} ต้องซื้อครบ ${requiredQty.toStringAsFixed(0)} ${product.unit_name}$ratioText "
                        "จะได้ราคา ${global.moneyFormat.format(product.price)} บาท/${product.unit_name}",
                      );
                    } else if (promotion.type == 5) {
                      // Type 5: แสดงชื่อ + barcode + จำนวน(กำลังทำ/ต้องซื้อครบ) + เงื่อนไขส่วนลด
                      matchedProducts.add(
                        "$productName ($barcodeText) กำลังทำรายการ ${cartQty.toStringAsFixed(0)} ต้องซื้อครบ ${requiredQty.toStringAsFixed(0)} ${product.unit_name}$ratioText "
                        "จะได้ส่วนลด ${product.discount_text}",
                      );
                    } else {
                      // Type 1,2,3: แสดงชื่อ + barcode + จำนวน(กำลังทำ/ต้องซื้อครบ)
                      matchedProducts.add("$productName ($barcodeText) กำลังทำรายการ ${cartQty.toStringAsFixed(0)} ต้องซื้อครบ ${requiredQty.toStringAsFixed(0)} ${product.unit_name}$ratioText");
                    }
                  }
                }
              }
              if (matchedProducts.isNotEmpty) {
                productDetails = '\n   • ${matchedProducts.join('\n   • ')}';
              } else if (promotion.type == 6 || promotion.type == 7 || promotion.type == 8) {
                // Type 6,7,8: โปรแบบซื้อเงิน - แสดง limit amount
                productDetails = '\n   • ซื้อครบ ${global.moneyFormat.format(promotion.limit_amount)} บาท';
              }

              warningMessage =
                  "🕐 ${global.getNameFromJsonLanguage(promotion.promotion_name, global.userScreenLanguage)} "
                  "เริ่ม $thaiDate (อีก $daysUntil วัน)$productDetails";
              colorHex = '#FF0000';
            } else if (today.isAfter(endDate)) {
              final daysAgo = today.difference(endDate).inDays;
              final thaiDate = global.dateTimeFormatThaiShortMonth(endDate);
              warningMessage =
                  "❌ ${global.getNameFromJsonLanguage(promotion.promotion_name, global.userScreenLanguage)} "
                  "หมดอายุแล้ว $thaiDate "
                  "(เมื่อ $daysAgo วันที่แล้ว)";
              colorHex = '#FF0000';
            }

            if (warningMessage.isNotEmpty) {
              processResult.promotion_warning_list.add(
                PosProcessPromotionModel(colorHex: colorHex, promotion_code: promotion.promotion_code, promotion_name: promotion.promotion_name, description: warningMessage, discount_word: detailDiscountFormula, count: 0, discount_amount: 0, isAchieved: false),
              );

              if (kDebugMode) {
                AppLogger.warning('[PosProcess] ⚠️ Inactive Promotion Warning Added: $warningMessage');
              }
            }
          }

          if (promotionActive) {
            double totalAmountForDiscount = 0;
            if (promotion.promotion_item_code_include_list.isNotEmpty) {
              // ถ้ามีสินค้า Promotion

              if (promotion.type == 6) {
                // 6 = ซื้อครบ xxx บาท แถมสินค้า
                // ตรวจสอบว่า Promotion นี้เป็น Promotion ซื้อ xxx แถม xxx ชิ้น (ซื้ออะไรก็ได้ แถมอะไรก็ได้)
                bool foundPromotionProduct = false;
                for (var promotionInclude in promotion.promotion_item_code_include_list) {
                  double totalAmountBalance = 0;
                  // ⭐ ค้นหาโดย item_code (รวมทุกอัตราส่วนแล้ว)
                  for (var promotionProduct in promotionInclude.promotion_product) {
                    final matchedDetail = itemCodeToPromotionDetail[promotionProduct.item_code];
                    if (matchedDetail != null) {
                      totalAmountBalance += matchedDetail.total_amount;
                      foundPromotionProduct = true;
                    }
                  }

                  if (promotion.type == 6) {
                    // 6 = ซื้อครบ xxx บาท แถมสินค้า
                    // ตรวจสอบว่ามีสินค้าที่เข้า Promotion หรือไม่
                    bool loop = (promotionInclude.promotion_product.isNotEmpty) ? true : false;
                    double discountAmount = 0;
                    int onTopCount = 0;
                    int promotionCount = 0;
                    while (loop == true) {
                      if (totalAmountBalance >= promotion.limit_amount) {
                        promotionCount++;
                        totalAmountBalance -= promotion.limit_amount;
                        // แถมสินค้า
                        for (int index = 0; index < promotionInclude.include_product.length; index++) {
                          // ⭐ ค้นหาสินค้าที่จะแถม โดย item_code (อัตราส่วนคูณเข้าไปแล้ว)
                          for (var includeProduct in promotionInclude.include_product) {
                            // 🎯 คำนวณจำนวนที่ต้องการเป็น base unit
                            double requiredBaseQty = convertToBaseUnit(qty: includeProduct.qty, unitDividend: includeProduct.stand_value, unitDivisor: includeProduct.dived_value);

                            final promotionDetail = itemCodeToPromotionDetail[includeProduct.item_code];

                            if (promotionDetail != null && promotionDetail.promotion_balance_qty >= requiredBaseQty) {
                              discountAmount += includeProduct.price * includeProduct.qty;
                              promotionDetail.promotion_balance_qty -= requiredBaseQty;
                              promotionDetail.promotion_used_qty += requiredBaseQty;
                              onTopCount += 1;
                              break;
                            }
                          }
                        }
                      } else {
                        loop = false;
                      }
                    }
                    if (onTopCount > 0) {
                      // พบสินค้าที่เข้า Promotion แล้ว
                      processResult.promotion_product_list.add(
                        PosProcessPromotionModel(
                          // green
                          colorHex: '#00FF00',
                          promotion_code: promotion.promotion_code,
                          promotion_name: promotion.promotion_name,
                          description: "",
                          discount_word: detailDiscountFormula,
                          count: onTopCount,
                          discount_amount: discountAmount,
                        ),
                      );
                    }
                    // แนะนำ Promotion ที่ยังไม่ได้ใช้
                    if (foundPromotionProduct && promotion.limit_amount > 0) {
                      // เตือนให้ซื้อเพิ่ม
                      if (totalAmountBalance > 0) {
                        processResult.promotion_warning_list.add(
                          PosProcessPromotionModel(
                            // blue
                            colorHex: '#0000FF',
                            promotion_code: promotion.promotion_code,
                            promotion_name: promotion.promotion_name,
                            description: "ซื้อเพิ่มอีก ${global.moneyFormat.format(promotion.limit_amount - totalAmountBalance)} บาท ${global.getNameFromJsonLanguage(promotion.promotion_name, global.userScreenLanguage)}",
                            discount_word: detailDiscountFormula,
                            count: 0,
                            discount_amount: 0,
                            isAchieved: false, // กำลังจะได้
                          ),
                        );
                      }
                    }
                    {
                      // ตรวจสอบสินค้าว่าแถมครบหรือเปล่า เตือน
                      for (int loop = 0; loop < promotionCount - onTopCount; loop++) {
                        for (int index = 0; index < promotionInclude.include_product.length; index++) {
                          final product = promotionInclude.include_product[index];
                          processResult.promotion_warning_list.add(
                            PosProcessPromotionModel(
                              // red
                              colorHex: '#FF0000',
                              promotion_code: promotion.promotion_code,
                              promotion_name: promotion.promotion_name,
                              description:
                                  "ต้องแถม ${global.getNameFromJsonLanguage(product.name, global.userScreenLanguage)} "
                                  "จำนวน ${product.qty} ${global.getNameFromJsonLanguage(product.unit_name, global.userScreenLanguage)}",
                              discount_word: detailDiscountFormula,
                              count: 1,
                              discount_amount: 0,
                              isAchieved: true, // ได้แล้ว (ต้องแถม)
                            ),
                          );
                        }
                      }
                    }
                  }
                }
              } else if (promotion.type == 4) {
                // 4=ราคาพิเศษ (แก้ราคาสินค้าเมื่อซื้อครบตามจำนวน)
                if (kDebugMode) {
                  AppLogger.debug('[PosProcess] 🎯 Type 4 Processing: ${promotion.promotion_code}');
                  AppLogger.debug('[PosProcess]    Item lists: ${promotion.promotion_item_code_include_list.length}');
                }

                // ⚡ ใช้ Map O(1) แทน triple nested loops O(n³)
                for (var promotionProduct in promotion.promotion_item_code_include_list) {
                  for (var promotionBarcode in promotionProduct.promotion_product) {
                    // ⭐ ค้นหาโดย item_code (อัตราส่วนคูณเข้าไปแล้ว)
                    final promotionDetail = itemCodeToPromotionDetail[promotionBarcode.item_code];

                    if (kDebugMode) {
                      AppLogger.debug(
                        '[PosProcess]       Checking item_code: ${promotionBarcode.item_code} | '
                        'promo_ratio: ${promotionBarcode.stand_value}:${promotionBarcode.dived_value} | '
                        'found in cart: ${promotionDetail != null}',
                      );
                    }

                    if (promotionDetail != null) {
                      // 🎯 แปลงจำนวนโปรโมชั่นเป็น base unit
                      final promotionBaseQty = convertToBaseUnit(qty: promotionBarcode.qty, unitDividend: promotionBarcode.stand_value, unitDivisor: promotionBarcode.dived_value);

                      // 🔢 แปลง limit_qty เป็น base unit
                      final limitBaseQty = promotion.limit_qty * promotionBaseQty;

                      if (promotionDetail.qty >= limitBaseQty) {
                        // ✅ ครบเงื่อนไข: ลดราคาสินค้า
                        double totalDiscount = 0;
                        int itemCount = 0;

                        // 🎯 ใช้ item_code เท่านั้น (ไม่สนใจอัตราส่วน)
                        for (var detail in processResult.details) {
                          String? detailItemCode = barcodeToItemCode[detail.barcode];

                          // ⭐ เช็คเฉพาะ item_code (อัตราส่วนรวมกันแล้ว)
                          if (detailItemCode == promotionDetail.item_code) {
                            // 💾 เก็บราคาเดิมก่อนเปลี่ยน (สำหรับแสดงใน cart)
                            detail.price_original = detail.price;

                            // 🎯 คำนวณราคาพิเศษต่อ base unit ของสินค้าชนิดนี้
                            // ราคาโปรต้องแปลงตามอัตราส่วนของสินค้าด้วย
                            double pricePerBase = getPricePerBaseUnit(price: promotionBarcode.price, unitDividend: promotionBarcode.stand_value, unitDivisor: promotionBarcode.dived_value);

                            // ราคาพิเศษสำหรับหน่วยของ detail
                            double specialPriceForDetail = pricePerBase * (detail.unit_dividend / detail.unit_divisor);

                            // 🏷️ เปลี่ยนเป็นราคาพิเศษ
                            detail.price = specialPriceForDetail;
                            detail.total_amount = detail.price * detail.qty;

                            // คำนวณส่วนลดจากผลต่างราคา
                            final discountPerUnit = detail.price_original - specialPriceForDetail;
                            totalDiscount += discountPerUnit * detail.qty;
                            itemCount++;

                            AppLogger.debug(
                              '[PosProcess] 💰 Type 4 Applied: '
                              'item=${promotionDetail.item_code} | '
                              'barcode=${detail.barcode} | '
                              'detail_ratio=${detail.unit_dividend}:${detail.unit_divisor} | '
                              'promo_ratio=${promotionBarcode.stand_value}:${promotionBarcode.dived_value} | '
                              'old_price=${detail.price_original} | '
                              'new_price=$specialPriceForDetail | '
                              'discount_per_unit=$discountPerUnit',
                            );
                          }
                        }

                        // เพิ่มเข้า promotion_product_list เพื่อแสดงว่าได้โปร
                        // ⚠️ Type 4 เปลี่ยนราคาในตระกร้าแล้ว ไม่ต้องลดท้ายบิลอีก (discount_amount = 0)
                        if (totalDiscount > 0) {
                          processResult.promotion_product_list.add(
                            PosProcessPromotionModel(
                              colorHex: '#00FF00', // green - success
                              promotion_code: promotion.promotion_code,
                              promotion_name: promotion.promotion_name,
                              description: "ราคาพิเศษ ${promotionBarcode.name} (ประหยัด ${global.moneyFormat.format(totalDiscount)} บาท)",
                              discount_word: "ราคาพิเศษ ${global.moneyFormat.format(promotionBarcode.price)} บาท/${promotionBarcode.unit_name} × $itemCount รายการ",
                              count: itemCount,
                              discount_amount: 0, // ไม่ลดท้ายบิล เพราะราคาในตระกร้าลดแล้ว
                            ),
                          );
                        }
                      } else {
                        // ⚠️ ไม่ครบเงื่อนไข: เตือน
                        final remaining = limitBaseQty - promotionDetail.qty;
                        processResult.promotion_warning_list.add(
                          PosProcessPromotionModel(
                            // blue - กำลังจะได้
                            colorHex: '#0000FF',
                            promotion_code: promotion.promotion_code,
                            promotion_name: promotion.promotion_name,
                            description:
                                "ซื้อ ${promotionBarcode.name} เพิ่มอีก ${remaining.toStringAsFixed(0)} ${promotionBarcode.unit_name} "
                                "จะได้ราคาพิเศษ ${global.moneyFormat.format(promotionBarcode.price)} บาท/${promotionBarcode.unit_name}",
                            discount_word: detailDiscountFormula,
                            count: 0,
                            discount_amount: 0,
                            isAchieved: false, // กำลังจะได้
                          ),
                        );
                      }
                    }
                  }
                }
              } else if (promotion.type == 5) {
                // 5=ซื้อครบจำนวน ลด เปอร์เซ็นต์ หรือ บาท
                // ⭐ ค้นหาโดย item_code (อัตราส่วนคูณเข้าไปแล้ว)
                for (var promotionProduct in promotion.promotion_item_code_include_list) {
                  for (var promotionBarcode in promotionProduct.promotion_product) {
                    final promotionDetail = itemCodeToPromotionDetail[promotionBarcode.item_code];
                    if (promotionDetail != null) {
                      // 🎯 แปลงจำนวนโปรโมชั่นเป็น base unit
                      final promotionBaseQty = convertToBaseUnit(qty: promotionBarcode.qty, unitDividend: promotionBarcode.stand_value, unitDivisor: promotionBarcode.dived_value);

                      // 🔢 แปลง limit_qty เป็น base unit
                      final limitBaseQty = promotion.limit_qty * promotionBaseQty;

                      if (promotionDetail.qty >= limitBaseQty) {
                        // ✅ ครบเงื่อนไข: ลดราคา
                        // 🎯 ใช้ item_code เท่านั้น (ไม่สนใจอัตราส่วน)
                        for (int index = 0; index < processResult.details.length; index++) {
                          var detail = processResult.details[index];
                          String? detailItemCode = barcodeToItemCode[detail.barcode];

                          // ⭐ เช็คเฉพาะ item_code (อัตราส่วนรวมกันแล้ว)
                          if (detailItemCode == promotionDetail.item_code) {
                            detail.discount_text = promotionBarcode.discount_text;
                            detail.discount = global.calcDiscountFormula(totalAmount: detail.total_amount, discountText: promotionBarcode.discount_text);

                            AppLogger.debug(
                              '[PosProcess] 💸 Type 5 Applied: '
                              'item=${promotionDetail.item_code} | '
                              'barcode=${detail.barcode} | '
                              'detail_ratio=${detail.unit_dividend}:${detail.unit_divisor} | '
                              'promo_ratio=${promotionBarcode.stand_value}:${promotionBarcode.dived_value} | '
                              'discount=${promotionBarcode.discount_text}',
                            );
                          }
                        }
                      } else {
                        // เตือน Promotion
                        final remaining = limitBaseQty - promotionDetail.qty;
                        processResult.promotion_warning_list.add(
                          PosProcessPromotionModel(
                            // blue - กำลังจะได้
                            colorHex: '#0000FF',
                            promotion_code: promotion.promotion_code,
                            promotion_name: promotion.promotion_name,
                            description:
                                "ซื้อ ${promotionBarcode.name} เพิ่มอีก ${remaining.toStringAsFixed(0)} ${promotionBarcode.unit_name} "
                                "จะได้ส่วนลด ${promotionBarcode.discount_text}",
                            discount_word: detailDiscountFormula,
                            count: 0,
                            discount_amount: 0,
                            isAchieved: false, // กำลังจะได้
                          ),
                        );
                      }
                    }
                  }
                }
              } else if (promotion.type == 1 || promotion.type == 2 || promotion.type == 3) {
                // 1 = แถมสินค้า เมื่อซื้อสินค้าครบตามจำนวน
                // 2 = ส่วนลดเงินสด หรือเปอร์เซ็นต์ เมื่อซื้อครบตามจำนวน
                // 3 = ซื้อสินค้าตาม List แล้วแถมสินค้าตาม List
                // ตรวจสอบว่า Promotion นี้เป็น Promotion ซื้อ xxx แถม xxx ชิ้น (ซื้ออะไรก็ได้ แถมอะไรก็ได้)
                for (var promotionInclude in promotion.promotion_item_code_include_list) {
                  if (promotion.type == 3) {
                    // 3=ซื้ออะไรก็ได้ใน List แถมสินค้า ใน List (เช่น ซือ 1 แถม 1) เงื่อนไข ราคาเดียวกัน
                    double totalQty = 0;
                    double totalAmount = 0;
                    List<int> findPromotionDetailIndex = [];
                    // ⭐ ค้นหาโดย item_code (อัตราส่วนคูณเข้าไปแล้ว)
                    for (var promotionProduct in promotionInclude.promotion_product) {
                      final matchedDetail = itemCodeToPromotionDetail[promotionProduct.item_code];
                      if (matchedDetail != null) {
                        findPromotionDetailIndex.add(promotionDetailList.indexOf(matchedDetail));
                        totalQty += matchedDetail.qty;
                        totalAmount += matchedDetail.price * matchedDetail.qty;
                      }
                    }

                    // 🔢 คำนวณ limit_qty และ promotion_qty เป็น base unit
                    // สมมติว่า promotion_product รายการแรกเป็นตัวแทนของหน่วยนับ
                    double limitBaseQty = promotion.limit_qty;
                    double promotionBaseQty = promotion.promotion_qty;
                    if (promotionInclude.promotion_product.isNotEmpty) {
                      final firstProduct = promotionInclude.promotion_product.first;
                      final baseUnitRatio = convertToBaseUnit(qty: 1, unitDividend: firstProduct.stand_value, unitDivisor: firstProduct.dived_value);
                      limitBaseQty = promotion.limit_qty * baseUnitRatio;
                      promotionBaseQty = promotion.promotion_qty * baseUnitRatio;
                    }

                    int promotionOnTopQty = (totalQty / (limitBaseQty + promotionBaseQty)).floor();
                    if (promotionOnTopQty > 0) {
                      // พบสินค้าที่เข้า Promotion แล้ว
                      processResult.promotion_product_list.add(
                        PosProcessPromotionModel(
                          // green
                          colorHex: '#00FF00',
                          promotion_code: promotion.promotion_code,
                          promotion_name: promotion.promotion_name,
                          description: "",
                          discount_word: detailDiscountFormula,
                          count: promotionOnTopQty,
                          discount_amount: (totalAmount / totalQty) * (promotionBaseQty * promotionOnTopQty),
                        ),
                      );
                    }
                    // ตรวจสอบว่ามีสินค้าที่เข้า Promotion หรือไม่ (เตือน)
                    if (promotionOnTopQty != (totalQty / (limitBaseQty + promotionBaseQty))) {
                      // คำนวณจำนวนที่ต้องเพิ่มเพื่อถึง set ถัดไป
                      final nextSetThreshold = (promotionOnTopQty + 1) * (limitBaseQty + promotionBaseQty);
                      final remaining = nextSetThreshold - totalQty;

                      // ชื่อหน่วยนับ (ถ้ามี)
                      String unitName = promotionInclude.promotion_product.isNotEmpty ? promotionInclude.promotion_product.first.unit_name : "ชิ้น";

                      processResult.promotion_warning_list.add(
                        PosProcessPromotionModel(
                          // blue
                          colorHex: '#0000FF',
                          promotion_code: promotion.promotion_code,
                          promotion_name: promotion.promotion_name,
                          description:
                              "ซื้อสินค้าในชุด ${global.getNameFromJsonLanguage(promotion.promotion_name, global.userScreenLanguage)} "
                              "เพิ่มอีก ${remaining.toStringAsFixed(0)} $unitName จะได้แถม",
                          discount_word: detailDiscountFormula,
                          count: 1,
                          discount_amount: 0,
                          isAchieved: false, // กำลังจะได้
                        ),
                      );
                    }
                  }

                  if (promotion.type == 1 || promotion.type == 2) {
                    // ตามจำนวน
                    // ตรวจสอบว่ามีสินค้าที่เข้า Promotion หรือไม่
                    bool loop = (promotionInclude.promotion_product.isNotEmpty) ? true : false;
                    while (loop == true) {
                      for (var promotionBarcode in promotionInclude.promotion_product) {
                        // ⭐ ค้นหาโดย item_code (อัตราส่วนคูณเข้าไปแล้ว)
                        final matchedDetail = itemCodeToPromotionDetail[promotionBarcode.item_code];

                        // 🎯 แปลงจำนวนโปรโมชั่นเป็น base unit
                        final promotionBaseQty = convertToBaseUnit(qty: promotionBarcode.qty, unitDividend: promotionBarcode.stand_value, unitDivisor: promotionBarcode.dived_value);

                        bool foundPromotion = false;
                        if (matchedDetail != null && matchedDetail.promotion_balance_qty >= promotionBaseQty) {
                          // ลดจำนวนสินค้าลง
                          matchedDetail.promotion_balance_qty -= promotionBaseQty;
                          totalAmountForDiscount += matchedDetail.price * promotionBaseQty;
                          foundPromotion = true;
                        }

                        if (foundPromotion) {
                          // พบสินค้าที่เข้า Promotion แล้ว
                          // ค้นหา Promotion ที่ได้แล้ว จะได้บวกเพิ่ม
                          int findPromotionDetailIndex = -1;
                          for (int index = 0; index < processResult.promotion_product_list.length; index++) {
                            if (promotion.promotion_code == processResult.promotion_product_list[index].promotion_code) {
                              findPromotionDetailIndex = index;
                              break;
                            }
                          }
                          switch (promotion.type) {
                            case 1: // แถมสินค้าเมื่อซื้อสินค้าครบตามจำนวน
                              for (var includeProduct in promotionInclude.include_product) {
                                double discountAmount = 0;
                                bool foundIncludeProduct = false;
                                for (var promotionDetail in promotionDetailList) {
                                  // ⭐ เช็คทั้ง item_code + อัตราส่วน (unit_dividend/unit_divisor)
                                  bool itemCodeMatch = promotionDetail.item_code == includeProduct.item_code;
                                  bool ratioMatch = (promotionDetail.unit_dividend == includeProduct.stand_value && promotionDetail.unit_divisor == includeProduct.dived_value);

                                  if (itemCodeMatch && ratioMatch && promotionDetail.promotion_balance_qty > 0) {
                                    discountAmount = includeProduct.price * includeProduct.qty;
                                    promotionDetail.promotion_balance_qty -= includeProduct.qty;
                                    promotionDetail.promotion_used_qty += includeProduct.qty;
                                    foundIncludeProduct = true;

                                    AppLogger.debug(
                                      '[PosProcess] 🎁 Type 1 - Found giveaway item: '
                                      'item=${includeProduct.item_code} | '
                                      'ratio=${promotionDetail.unit_dividend}:${promotionDetail.unit_divisor}',
                                    );
                                    break;
                                  }
                                }
                                if (foundIncludeProduct == false) {
                                  processResult.promotion_warning_list.add(
                                    PosProcessPromotionModel(
                                      // red
                                      colorHex: '#FF0000',
                                      promotion_code: promotion.promotion_code,
                                      promotion_name: promotion.promotion_name,
                                      description:
                                          "เตือน ไม่พบสินค้า ${global.getNameFromJsonLanguage(includeProduct.name, global.userScreenLanguage)} ${global.getNameFromJsonLanguage(includeProduct.unit_name, global.userScreenLanguage)} (${includeProduct.item_code}) เพราะได้โปร ${global.getNameFromJsonLanguage(promotion.promotion_name, global.userScreenLanguage)}",
                                      discount_word: detailDiscountFormula,
                                      count: 1,
                                      discount_amount: 0,
                                      isAchieved: true, // ได้แล้ว (ต้องแถม)
                                    ),
                                  );
                                }
                                if (findPromotionDetailIndex == -1) {
                                  // ไม่พบ เพิ่มใหม่
                                  processResult.promotion_product_list.add(
                                    PosProcessPromotionModel(
                                      // green
                                      colorHex: '#00FF00',
                                      promotion_code: promotion.promotion_code,
                                      promotion_name: promotion.promotion_name,
                                      description: "",
                                      discount_word: detailDiscountFormula,
                                      count: 1,
                                      discount_amount: discountAmount,
                                    ),
                                  );
                                } else {
                                  // พบ Update ยอดเพิ่ม
                                  processResult.promotion_product_list[findPromotionDetailIndex].count++;
                                  processResult.promotion_product_list[findPromotionDetailIndex].discount_amount += discountAmount;
                                }
                              }
                              break;
                            case 2: // ส่วนลดเงินสด หรือ เปอร์เซ็นต์ เมื่อซื้อครบตามจำนวน
                              // คำนวณส่วนลด
                              double calcDiscount = global.calcDiscountFormula(totalAmount: totalAmountForDiscount, discountText: promotion.discount_text);
                              if (findPromotionDetailIndex == -1) {
                                // ไม่พบ เพิ่มใหม่
                                processResult.promotion_product_list.add(
                                  PosProcessPromotionModel(
                                    // green
                                    colorHex: '#00FF00',
                                    promotion_code: promotion.promotion_code,
                                    promotion_name: promotion.promotion_name,
                                    description: "",
                                    discount_word: detailDiscountFormula,
                                    count: 1,
                                    discount_amount: calcDiscount,
                                  ),
                                );
                              } else {
                                // พบ Update ยอดใหม่
                                processResult.promotion_product_list[findPromotionDetailIndex].count++;
                                processResult.promotion_product_list[findPromotionDetailIndex].discount_amount = calcDiscount * processResult.promotion_product_list[findPromotionDetailIndex].count;
                              }
                              break;
                          }
                        } else {
                          loop = false;
                          break;
                        }
                      }
                    }
                    // แนะนำ Promotion ที่ยังไม่ได้ใช้
                    // ⭐ ค้นหาโดย item_code (อัตราส่วนคูณเข้าไปแล้ว)
                    for (var promotionBarcode in promotionInclude.promotion_product) {
                      final matchedDetail = itemCodeToPromotionDetail[promotionBarcode.item_code];
                      if (matchedDetail != null) {
                        // 🎯 แปลงจำนวนโปรโมชั่นเป็น base unit
                        final promotionBaseQty = convertToBaseUnit(qty: promotionBarcode.qty, unitDividend: promotionBarcode.stand_value, unitDivisor: promotionBarcode.dived_value);

                        if (matchedDetail.promotion_balance_qty != 0 && matchedDetail.promotion_balance_qty < promotionBaseQty) {
                          // 🎯 คำนวณจำนวนที่ขาด (base unit)
                          final remainingBaseQty = promotionBaseQty - matchedDetail.promotion_balance_qty;

                          processResult.promotion_warning_list.add(
                            PosProcessPromotionModel(
                              // blue
                              colorHex: '#0000FF',
                              promotion_code: promotion.promotion_code,
                              promotion_name: promotion.promotion_name,
                              description:
                                  "ซื้อเพิ่มอีก ${remainingBaseQty.toStringAsFixed(0)} (base unit) ${global.getNameFromJsonLanguage(matchedDetail.item_name, global.userScreenLanguage)} จะได้โปร ${global.getNameFromJsonLanguage(promotion.promotion_name, global.userScreenLanguage)}",
                              discount_word: detailDiscountFormula,
                              count: 0,
                              discount_amount: 0,
                              isAchieved: false, // กำลังจะได้
                            ),
                          );
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    // ลบบรรทัดที่มีจำนวนเป็น 0 ทิ้ง
    for (int index = 0; index < processResult.details.length; index++) {
      if (processResult.details[index].qty == 0) {
        processResult.details.removeAt(index);
        index--;
      }
    }
    // ✅ Flag เพื่อจำกัดแต่ละบิลได้แค่ 1 Tier เท่านั้น
    bool hasTierRedemption = false;

    // ⭐ สร้าง copy ของ list เพื่อป้องกัน ConcurrentModificationException
    final promotionMainCopyForBottom = List<PromotionMainModel>.from(global.promotionMain);
    for (var promotionMain in promotionMainCopyForBottom) {
      // ตรวจ Promotion ท้ายบิล (ซื้อครบมูลค่า)
      double balanceAmount = 0;
      for (var detail in promotionDetailList) {
        balanceAmount += detail.price * detail.promotion_balance_qty;
      }
      //
      for (var promotionIndex = 0; promotionIndex < promotionMain.promotion_list.length; promotionIndex++) {
        var promotion = promotionMain.promotion_list[promotionIndex];

        // ✅ Date validation - รองรับ single-day promotion (date_begin = date_end)
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final beginDate = DateTime(promotion.date_begin.year, promotion.date_begin.month, promotion.date_begin.day);
        final endDate = DateTime(promotion.date_end.year, promotion.date_end.month, promotion.date_end.day);

        // Check if today is within date range (inclusive)
        // Logic: beginDate <= today <= endDate
        bool promotionActive = !today.isBefore(beginDate) && !today.isAfter(endDate);

        if (promotionActive) {
          if (promotion.type == 101) {
            // 101 = ซื้อครบ xxx บาท แลกคูปองส่วนลด (เฉพาะสินค้า HB)
            // คำนวณยอดรวมเฉพาะสินค้าที่มี pattern_code = "HB"

            if (kDebugMode) {
              AppLogger.debug('🎟️ Type 101 - House Brand Coupon Promotion');
              AppLogger.debug('Promotion Code: ${promotion.promotion_code}');
              AppLogger.debug('   Promotion Name: ${global.getNameFromJsonLanguage(promotion.promotion_name, global.userScreenLanguage)}');
              AppLogger.debug('Date: ${promotion.date_begin} → ${promotion.date_end}');
              AppLogger.debug('   Limit Amount: ${global.moneyFormat.format(promotion.limit_amount)}');
              AppLogger.debug('   House Brand List: ${promotion.promotion_house_brand_list.length} items');
            }

            for (var promotionDetail in promotion.promotion_house_brand_list) {
              if (promotionDetail.formatcode.startsWith("HB")) {
                AppLogger.debug('   Format Code: ${promotionDetail.formatcode}');

                // คำนวณยอดรวมเฉพาะสินค้า HB
                double houseBrandAmount = 0;
                int houseBrandItemCount = 0;

                for (var detail in processResult.details) {
                  if (detail.pattern_code == "HB" && detail.is_void == false) {
                    houseBrandAmount += detail.total_amount;
                    houseBrandItemCount++;

                    AppLogger.debug('      HB Item: ${detail.item_name} | Amount: ${global.moneyFormat.format(detail.total_amount)}');
                  }
                }

                if (kDebugMode) {
                  AppLogger.debug('   📊 Total HB Amount: ${global.moneyFormat.format(houseBrandAmount)} ($houseBrandItemCount items)');
                  AppLogger.debug('   🎯 Required: ${global.moneyFormat.format(promotion.limit_amount)}');
                }

                // เตือน Promotion
                if (houseBrandAmount >= promotion.limit_amount) {
                  // ✅ ครบแล้ว - เพิ่มเข้า promotion_coupon_list เพื่อพิมพ์ท้ายสุด

                  AppLogger.debug('   ✅ ACHIEVED! Adding to promotion_coupon_list');

                  /*processResult.promotion_coupon_list.add(
                    PosProcessPromotionModel(
                      // green - เปลี่ยนเป็นสีเขียวเพราะครบแล้ว
                      colorHex: '#00FF00',
                      promotion_code: promotion.promotion_code,
                      promotion_name: promotion.promotion_name,
                      description:
                          "🎉 ยินดีด้วย! ซื้อสินค้า House Brand ครบ ${global.moneyFormat.format(promotion.limit_amount)} บาท ได้สิทธิ์หมุนวงล้อชิงรางวัล ${global.getNameFromJsonLanguage(promotion.promotion_name, global.userScreenLanguage)}",
                      discount_word: detailDiscountFormula,
                      count: 1,
                      discount_amount: 0,
                    ),
                  );*/

                  AppLogger.debug('   📝 Coupon list count: ${processResult.promotion_coupon_list.length}');
                } else if (houseBrandAmount > 0) {
                  // ⚠️ มีสินค้า HB แต่ยังไม่ครบ - เตือนบนหน้าจอเท่านั้น (ไม่พิมพ์)
                  double remainingAmount = promotion.limit_amount - houseBrandAmount;

                  if (kDebugMode) {
                    AppLogger.warning('   ⚠️ NOT YET! Remaining: ${global.moneyFormat.format(remainingAmount)}');
                    AppLogger.warning('Adding to promotion_warning_list');
                  }

                  processResult.promotion_warning_list.add(
                    PosProcessPromotionModel(
                      // blue - สีฟ้าเพื่อเตือน
                      colorHex: '#0000FF',
                      promotion_code: promotion.promotion_code,
                      promotion_name: promotion.promotion_name,
                      description: "ซื้อสินค้า House Brand เพิ่มอีก ${global.moneyFormat.format(remainingAmount)} บาท จะได้สิทธิ์หมุนวงล้อชิงรางวัล ${global.getNameFromJsonLanguage(promotion.promotion_name, global.userScreenLanguage)}",
                      discount_word: detailDiscountFormula,
                      count: 0,
                      discount_amount: 0,
                      isAchieved: false, // กำลังจะได้
                    ),
                  );

                  AppLogger.debug('   📝 Warning list count: ${processResult.promotion_warning_list.length}');
                } else {
                  // ❌ ไม่มีสินค้า HB เลย
                  AppLogger.debug('   ❌ No House Brand items in cart');
                }
                // หมายเหตุ: ถ้าไม่มีสินค้า HB เลย (houseBrandAmount == 0) จะไม่แสดงเตือน
              }
            }
          }
          if (promotion.type == 7) {
            // 7 = ซื้อบิลครบ xxx บาท ส่วนลดเพิ่มอีก xxx บาท หรือ x%
            bool loop = (balanceAmount >= promotion.limit_amount) ? true : false;
            while (loop) {
              if (balanceAmount >= promotion.limit_amount) {
                balanceAmount -= promotion.limit_amount;
                int promotionIndex = -1;
                for (int index = 0; index < processResult.promotion_bottom_list.length; index++) {
                  if (promotion.promotion_code == processResult.promotion_bottom_list[index].promotion_code) {
                    promotionIndex = index;
                    break;
                  }
                }
                if (promotionIndex != -1) {
                  processResult.promotion_bottom_list[promotionIndex].count++;
                  processResult.promotion_bottom_list[promotionIndex].discount_amount += global.calcDiscountFormula(totalAmount: promotion.limit_amount, discountText: promotion.discount_text);
                } else {
                  processResult.promotion_bottom_list.add(
                    PosProcessPromotionModel(
                      // green
                      colorHex: '#00FF00',
                      promotion_code: promotion.promotion_code,
                      promotion_name: promotion.promotion_name,
                      description: "",
                      discount_word: detailDiscountFormula,
                      count: 1,
                      discount_amount: global.calcDiscountFormula(totalAmount: promotion.limit_amount, discountText: promotion.discount_text),
                    ),
                  );
                }
              }
              if (balanceAmount <= promotion.limit_amount || balanceAmount <= 0) {
                loop = false;
              }
            }
            if (balanceAmount < promotion.limit_amount) {
              // เตือน Promotion
              processResult.promotion_warning_list.add(
                PosProcessPromotionModel(
                  // blue
                  colorHex: '#0000FF',
                  promotion_code: promotion.promotion_code,
                  promotion_name: promotion.promotion_name,
                  description: "ซื้อเพิ่มอีก ${global.moneyFormat.format(promotion.limit_amount - balanceAmount)} จะได้โปร ${global.getNameFromJsonLanguage(promotion.promotion_name, global.userScreenLanguage)}",
                  discount_word: detailDiscountFormula,
                  count: 0,
                  discount_amount: 0,
                  isAchieved: false, // กำลังจะได้
                ),
              );
            }
          }
          if (promotion.type == 8) {
            // 8 = ซื้่อบิลครบ xxx บาท ได้สินค้ารางวัล
            bool loop = (balanceAmount >= promotion.limit_amount) ? true : false;
            while (loop) {
              if (balanceAmount >= promotion.limit_amount) {
                balanceAmount -= promotion.limit_amount;
                int promotionIndex = -1;
                for (int index = 0; index < processResult.promotion_bonus_list.length; index++) {
                  if (promotion.promotion_code == processResult.promotion_bonus_list[index].promotion_code) {
                    promotionIndex = index;
                    break;
                  }
                }
                if (promotionIndex != -1) {
                  processResult.promotion_bonus_list[promotionIndex].count++;
                  processResult.promotion_bonus_list[promotionIndex].discount_amount += global.calcDiscountFormula(totalAmount: promotion.limit_amount, discountText: promotion.discount_text);
                } else {
                  processResult.promotion_bonus_list.add(
                    PosProcessPromotionModel(
                      // green
                      colorHex: '#00FF00',
                      promotion_code: promotion.promotion_code,
                      promotion_name: promotion.promotion_name,
                      description: "",
                      discount_word: detailDiscountFormula,
                      count: 1,
                      discount_amount: global.calcDiscountFormula(totalAmount: promotion.limit_amount, discountText: promotion.discount_text),
                    ),
                  );
                }
              }
              if (balanceAmount <= promotion.limit_amount || balanceAmount <= 0) {
                loop = false;
              }
            }
            if (balanceAmount < promotion.limit_amount) {
              // เตือน Promotion
              processResult.promotion_warning_list.add(
                PosProcessPromotionModel(
                  // blue
                  colorHex: '#0000FF',
                  promotion_code: promotion.promotion_code,
                  promotion_name: promotion.promotion_name,
                  description: "ซื้อเพิ่มอีก ${global.moneyFormat.format(promotion.limit_amount - balanceAmount)} จะได้โปร ${global.getNameFromJsonLanguage(promotion.promotion_name, global.userScreenLanguage)}",
                  discount_word: detailDiscountFormula,
                  count: 0,
                  discount_amount: 0,
                  isAchieved: false, // กำลังจะได้
                ),
              );
            }
          }

          // 🎁 Type 102 = Tier-based Redemption (Auto-Select)
          // Logic:
          // 1. แต่ละ Tier มี CSV ของตัวเอง
          // 2. รวมยอดเฉพาะสินค้าที่อยู่ใน CSV ของ Tier นั้น
          // 3. เช็คว่ายอดรวมถึง threshold ของ Tier นั้นหรือไม่
          // 4. เลือก Tier สูงสุดที่ตรงเงื่อนไข (5→4→3→2→1)
          // ✅ แต่ละบิลได้แค่ 1 Tier เท่านั้น
          if (promotion.type == 102 && !hasTierRedemption) {
            // ✅ รวมยอดเฉพาะสินค้าที่อยู่ในรายการ Tier นี้
            double tierItemsAmount = 0;
            int tierItemsCount = 0;
            List<String> tierItemNames = []; // ⭐ เก็บชื่อสินค้า

            // ดึงรายการ item_code ทั้งหมดใน Tier นี้
            Set<String> tierItemCodes = {};
            for (var includeList in promotion.promotion_item_code_include_list) {
              for (var product in includeList.promotion_product) {
                tierItemCodes.add(product.item_code);
              }
            }

            // ✅ วนหาสินค้าในตะกร้าจาก processResult.details (ซึ่งมีราคาหลัก apply promotion แล้ว)
            for (var detail in processResult.details) {
              if (detail.is_void) continue; // ข้ามรายการที่ void

              // ดึง item_code จาก barcode
              var productBarcode = await _getCachedProductBarcode(detail.barcode);
              if (productBarcode == null) continue;

              if (tierItemCodes.contains(productBarcode.item_code)) {
                // ✅ ใช้ total_amount ซึ่งเป็นยอดหลังหักส่วนลดทุกประเภทแล้ว (รวม Type 4)
                final itemTotal = detail.total_amount;
                tierItemsAmount += itemTotal;
                tierItemsCount++;

                // ⭐ เก็บชื่อสินค้า (ตัดให้สั้น ไม่เกิน 35 ตัวอักษร)
                String itemName = global.getNameFromJsonLanguage(detail.item_name, global.userScreenLanguage);
                if (itemName.length > 35) {
                  itemName = '${itemName.substring(0, 35)}...';
                }

                // แสดงจำนวนและราคา
                String qtyStr = detail.qty.toStringAsFixed(detail.qty == detail.qty.toInt() ? 0 : 1);
                String priceStr = global.moneyFormat.format(itemTotal);
                tierItemNames.add('$qtyStr x $itemName (฿$priceStr)');

                if (kDebugMode) {
                  AppLogger.debug('  └─ ${productBarcode.item_code}: ${global.moneyFormat.format(itemTotal)} (after all discounts)');
                }
              }
            }

            // ดึง threshold ของ Tier นี้
            final tierThreshold = promotion.tier_threshold ?? 0.0;
            final tierLevel = promotion.index; // index = tier_level (1-5)

            if (kDebugMode) {
              AppLogger.debug('🎁 Type 102 - Tier Redemption Promotion');
              AppLogger.debug('Promotion Code: ${promotion.promotion_code}');
              AppLogger.debug('Tier Level: $tierLevel');
              AppLogger.debug('Tier Threshold: ฿${global.moneyFormat.format(tierThreshold)}');
              AppLogger.debug('Tier Items in Cart: $tierItemsCount items');
              AppLogger.debug('💰 Tier Items Total: ${global.moneyFormat.format(tierItemsAmount)}');
            }

            // ✅ เช็คว่ายอดของ Tier นี้ถึง threshold หรือไม่
            if (tierItemsAmount >= tierThreshold) {
              // ✅ ถึง threshold แล้ว → ตรวจสอบสต็อก
              final stock = global.getTierStock(tierLevel);
              final remainingStock = stock?.remaining_stock ?? 0;

              if (remainingStock > 0) {
                // ✅ มีสต็อก → เพิ่มเข้า bonus_list
                bool alreadyAdded = processResult.promotion_bonus_list.any((promo) => promo.promotion_code == promotion.promotion_code && promo.tier_level == tierLevel);

                if (!alreadyAdded) {
                  // ดึงข้อความรางวัลจาก PromotionModel
                  String rewardMessage = promotion.tier_reward_message ?? "แลกรับของแถม Tier $tierLevel";

                  // 🎯 สร้างรายละเอียดสินค้าที่เข้าเงื่อนไข Tier (แสดงทั้งหมด)
                  String itemsDetail;
                  if (tierItemNames.isEmpty) {
                    itemsDetail = 'ไม่มีสินค้าที่เข้าเงื่อนไข';
                  } else {
                    // ✅ แสดงรายละเอียดทั้งหมด (ไม่ตัด)
                    itemsDetail = tierItemNames.join('\n');
                  }

                  // 💰 แสดงยอดรวมที่ซื้อ
                  String amountDetail = global.moneyFormat.format(tierItemsAmount);

                  String detailDescription = "🛒 สินค้าที่เข้าเงื่อนไข:\n$itemsDetail\n💰 ยอดรวม ฿$amountDetail\n📦 ของแถมคงเหลือ: $remainingStock ชิ้น";

                  if (kDebugMode) {
                    AppLogger.info('📝 Tier Bonus Description: $detailDescription');
                  }

                  processResult.promotion_bonus_list.add(
                    PosProcessPromotionModel(
                      // gold/yellow - สีทอง
                      colorHex: '#FFD700',
                      promotion_code: promotion.promotion_code,
                      // ✅ แสดงข้อความของแถมเต็มรูปแบบให้ลูกค้าดีใจ
                      promotion_name: "🎁 $rewardMessage",
                      description: detailDescription,
                      discount_word: "",
                      count: 1,
                      discount_amount: 0, // ไม่มีส่วนลด เป็นของแถม
                      isAchieved: true,
                      tier_level: tierLevel, // ⭐ บันทึก tier_level
                    ),
                  );

                  // ✅ ตั้ง flag ว่าได้ Tier แล้ว - ไม่ต้องหา Tier อื่นต่อ
                  hasTierRedemption = true;

                  if (kDebugMode) {
                    AppLogger.info('✅ Tier $tierLevel selected: $rewardMessage (Stock: $remainingStock)');
                    AppLogger.info('🛑 Skip remaining Type 102 checks (1 Tier per bill)');
                  }
                }
              }
            }
          }
        }
      }
    }
    // รวมยอดส่วนลด Promotion (Product + Bottom)
    processResult.total_discount_from_promotion = 0;
    processResult.total_discount_from_promotion_bottom = 0;

    // รวมส่วนลดในรายการสินค้า (Type 1-7 Product)
    for (var promotion in processResult.promotion_product_list) {
      processResult.total_discount_from_promotion += promotion.discount_amount;
    }

    // รวมส่วนลดท้ายบิล (Type 1-7 Bottom)
    for (var promotion in processResult.promotion_bottom_list) {
      processResult.total_discount_from_promotion_bottom += promotion.discount_amount;
      processResult.total_discount_from_promotion += promotion.discount_amount; // รวมเข้า total ด้วย
    }

    // 📊 Debug Log - สรุปผลลัพธ์โปรโมชั่น
    if (kDebugMode) {
      // Separator
      AppLogger.info('📊 Promotion Processing Summary');
      // Separator
      AppLogger.debug('🎯 Product Promotions (ส่วนลดในรายการ): ${processResult.promotion_product_list.length} items');
      for (var promo in processResult.promotion_product_list) {
        AppLogger.debug('   - ${global.getNameFromJsonLanguage(promo.promotion_name, global.userScreenLanguage)}');
        AppLogger.debug('     Count: ${promo.count} | Discount: ${global.moneyFormat.format(promo.discount_amount)}');
      }

      AppLogger.debug('💰 Bottom Promotions (ส่วนลดท้ายบิล): ${processResult.promotion_bottom_list.length} items');
      for (var promo in processResult.promotion_bottom_list) {
        AppLogger.debug('   - ${global.getNameFromJsonLanguage(promo.promotion_name, global.userScreenLanguage)}');
        AppLogger.debug('     Count: ${promo.count} | Discount: ${global.moneyFormat.format(promo.discount_amount)}');
      }

      AppLogger.debug('🎁 Bonus Promotions (ของแถม): ${processResult.promotion_bonus_list.length} items');
      for (var promo in processResult.promotion_bonus_list) {
        AppLogger.debug('   - ${global.getNameFromJsonLanguage(promo.promotion_name, global.userScreenLanguage)}');
        AppLogger.debug('     Count: ${promo.count} | Value: ${global.moneyFormat.format(promo.discount_amount)}');
      }

      AppLogger.debug('🎟️ Coupon Promotions (คูปอง): ${processResult.promotion_coupon_list.length} items');
      for (var promo in processResult.promotion_coupon_list) {
        AppLogger.debug('   - ${global.getNameFromJsonLanguage(promo.promotion_name, global.userScreenLanguage)}');
        AppLogger.debug('Description: ${promo.description}');
      }

      // AppLogger.warning('⚠️ Warning List (เตือน): ${processResult.promotion_warning_list.length} items');
      int pendingCount = processResult.promotion_warning_list.where((w) => !w.isAchieved).length;
      int achievedCount = processResult.promotion_warning_list.where((w) => w.isAchieved).length;
      AppLogger.debug('- Pending (กำลังจะได้): $pendingCount');
      AppLogger.debug('- Achieved (ต้องแถม): $achievedCount');

      // Separator
      AppLogger.debug('💵 Total Discount (Product): ${global.moneyFormat.format(processResult.total_discount_from_promotion)}');
      AppLogger.debug('💵 Total Discount (Bottom): ${global.moneyFormat.format(processResult.total_discount_from_promotion_bottom)}');
      AppLogger.debug('💵 Grand Total Discount: ${global.moneyFormat.format(processResult.total_discount_from_promotion + processResult.total_discount_from_promotion_bottom)}');
      // Separator
    }

    // ⚡ Performance Logging - Promotion Processing
    if (kDebugMode && stopwatch != null) {
      stopwatch.stop();
      AppLogger.success('⚡ Promotion Processing completed in ${stopwatch.elapsedMilliseconds}ms');

      // Cache Statistics
      AppLogger.debug('📊 Cache Statistics:');
      AppLogger.debug(
        '   Barcode Cache: ${_barcodeCache.length}/${_barcodeCache.maxSize} '
        '(${(_barcodeCache.length / _barcodeCache.maxSize * 100).toStringAsFixed(1)}% full)',
      );
      AppLogger.debug(
        '   JSON Options Cache: ${_jsonOptionsCache.length}/${_jsonOptionsCache.maxSize} '
        '(${(_jsonOptionsCache.length / _jsonOptionsCache.maxSize * 100).toStringAsFixed(1)}% full)',
      );
    }

    return processSummery(processResult, holdCode: holdCode, detailDiscountFormula: detailDiscountFormula, cashRoundAmount: cashRoundAmount, discountFoodOnly: discountFoodOnly);
  }
}
