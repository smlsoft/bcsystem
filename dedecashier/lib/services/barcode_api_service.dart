import 'dart:convert';
import 'package:dedecashier/api/client.dart';
import 'package:dedecashier/core/logger/logger.dart';
import 'package:dedecashier/core/service_locator.dart';
import 'package:dedecashier/model/barcodecheck/barcodemaster_model.dart';
import 'package:dedecashier/model/unit_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

class BarcodeApiService {
  static final BarcodeApiService _instance = BarcodeApiService._internal();
  factory BarcodeApiService() => _instance;
  BarcodeApiService._internal();

  /// ค้นหาสินค้าด้วยบาร์โค้ด - เชื่อมต่อกับ API จริง
  Future<BarcodeMasterModel?> searchByBarcode(
    String barcode,
    String shopid,
  ) async {
    Dio client = Client().init();

    try {
      final response = await client.get(
        '/product/barcode/pk/$barcode?shopsid=$shopid',
      );

      AppLogger.debug('Search barcode response: $response');

      // ตรวจสอบ response data
      dynamic rawData;
      if (response.data is String) {
        rawData = json.decode(response.data);
      } else {
        rawData = response.data;
      }

      AppLogger.debug('Parsed response data: $rawData');

      // ตรวจสอบ error
      if (rawData != null && rawData['error'] != null) {
        String errorMessage = '${rawData['code']}: ${rawData['message']}';
        AppLogger.error(errorMessage);
        if (kDebugMode) {
          AppLogger.error('API returned error in searchByBarcode: $errorMessage');
          AppLogger.debug('This is normal if barcode is not found');
        }
        return null;
      }

      // ตรวจสอบ success และ data
      if (rawData != null &&
          (rawData['success'] == true || rawData['success'] == 'true') &&
          rawData['data'] != null) {
        AppLogger.debug(
          'Attempting to parse BarcodeMasterModel from data: ${rawData['data']}',
        );

        try {
          // ลอง parse ทั้งหมดก่อน
          final data = rawData['data'] as Map<String, dynamic>;

          // เพิ่มค่าเริ่มต้นสำหรับ field ที่จำเป็นแต่อาจขาดหายจาก API
          if (!data.containsKey('groupnames') || data['groupnames'] == null) {
            data['groupnames'] = [];
          } else {
            // ตรวจสอบและแก้ไขข้อมูลใน groupnames
            List<dynamic> groupnames = data['groupnames'];
            for (int i = 0; i < groupnames.length; i++) {
              if (groupnames[i] != null) {
                if (groupnames[i]['code'] == null) {
                  groupnames[i]['code'] = '';
                }
                if (groupnames[i]['name'] == null) {
                  groupnames[i]['name'] = '';
                }
              }
            }
          }
          if (!data.containsKey('itemunitnames') ||
              data['itemunitnames'] == null) {
            data['itemunitnames'] = [];
          } else {
            // ตรวจสอบและแก้ไขข้อมูลใน itemunitnames
            List<dynamic> itemunitnames = data['itemunitnames'];
            for (int i = 0; i < itemunitnames.length; i++) {
              if (itemunitnames[i] != null) {
                if (itemunitnames[i]['code'] == null) {
                  itemunitnames[i]['code'] = '';
                }
                if (itemunitnames[i]['name'] == null) {
                  itemunitnames[i]['name'] = '';
                }
              }
            }
          }
          if (!data.containsKey('names') || data['names'] == null) {
            data['names'] = [];
          } else {
            // ตรวจสอบและแก้ไขข้อมูลใน names
            List<dynamic> names = data['names'];
            for (int i = 0; i < names.length; i++) {
              if (names[i] != null) {
                if (names[i]['code'] == null) {
                  names[i]['code'] = '';
                }
                if (names[i]['name'] == null) {
                  names[i]['name'] = '';
                }
              }
            }
          }
          if (!data.containsKey('prices') || data['prices'] == null) {
            data['prices'] = [];
          } else {
            // ตรวจสอบและแก้ไขข้อมูลใน prices
            List<dynamic> prices = data['prices'];
            for (int i = 0; i < prices.length; i++) {
              if (prices[i] != null) {
                if (prices[i]['keynumber'] == null) {
                  prices[i]['keynumber'] = 1;
                }
                if (prices[i]['price'] == null) {
                  prices[i]['price'] = 0.0;
                }
              }
            }
          }
          if (!data.containsKey('manufacturernames') ||
              data['manufacturernames'] == null) {
            data['manufacturernames'] = [];
          } else {
            // ตรวจสอบและแก้ไขข้อมูลใน manufacturernames
            List<dynamic> manufacturernames = data['manufacturernames'];
            for (int i = 0; i < manufacturernames.length; i++) {
              if (manufacturernames[i] != null) {
                if (manufacturernames[i]['code'] == null) {
                  manufacturernames[i]['code'] = '';
                }
                if (manufacturernames[i]['name'] == null) {
                  manufacturernames[i]['name'] = '';
                }
              }
            }
          }
          if (!data.containsKey('businesstypes') ||
              data['businesstypes'] == null) {
            data['businesstypes'] = [];
          } else {
            // ตรวจสอบและแก้ไขข้อมูลใน businesstypes
            List<dynamic> businesstypes = data['businesstypes'];
            for (int i = 0; i < businesstypes.length; i++) {
              if (businesstypes[i] != null) {
                if (businesstypes[i]['names'] == null) {
                  businesstypes[i]['names'] = [];
                } else {
                  // ตรวจสอบและแก้ไขข้อมูลใน businesstype.names
                  List<dynamic> names = businesstypes[i]['names'];
                  for (int j = 0; j < names.length; j++) {
                    if (names[j] != null) {
                      if (names[j]['code'] == null) {
                        names[j]['code'] = '';
                      }
                      if (names[j]['name'] == null) {
                        names[j]['name'] = '';
                      }
                    }
                  }
                }
                if (businesstypes[i]['guidfixed'] == null) {
                  businesstypes[i]['guidfixed'] = '';
                }
                if (businesstypes[i]['code'] == null) {
                  businesstypes[i]['code'] = '';
                }
                if (businesstypes[i]['isdefault'] == null) {
                  businesstypes[i]['isdefault'] = false;
                }
              }
            }
          }
          // เพิ่มการตรวจสอบ dimensions
          if (!data.containsKey('dimensions') || data['dimensions'] == null) {
            data['dimensions'] = [];
          }
          // เพิ่มการตรวจสอบ options
          if (!data.containsKey('options') || data['options'] == null) {
            data['options'] = [];
          }
          // เพิ่มการตรวจสอบ barcodes
          if (!data.containsKey('barcodes') || data['barcodes'] == null) {
            data['barcodes'] = [];
          }
          // เพิ่มการตรวจสอบ refbarcodes
          if (!data.containsKey('refbarcodes') || data['refbarcodes'] == null) {
            data['refbarcodes'] = [];
          }
          // เพิ่มการตรวจสอบ bom
          if (!data.containsKey('bom') || data['bom'] == null) {
            data['bom'] = [];
          }
          // เพิ่มการตรวจสอบ ordertypes
          if (!data.containsKey('ordertypes') || data['ordertypes'] == null) {
            data['ordertypes'] = [];
          }
          // เพิ่มการตรวจสอบ categorys
          if (!data.containsKey('categorys') || data['categorys'] == null) {
            data['categorys'] = [];
          }
          // เพิ่มการตรวจสอบ timeforsales
          if (!data.containsKey('timeforsales') ||
              data['timeforsales'] == null) {
            data['timeforsales'] = [];
          }
          // เพิ่มการตรวจสอบ fixedcost
          if (!data.containsKey('fixedcost') || data['fixedcost'] == null) {
            data['fixedcost'] = [];
          }
          // เพิ่มการตรวจสอบ ignorebranches
          if (!data.containsKey('ignorebranches') ||
              data['ignorebranches'] == null) {
            data['ignorebranches'] = [];
          }
          // เพิ่มการตรวจสอบ branches
          if (!data.containsKey('branches') || data['branches'] == null) {
            data['branches'] = [];
          }
          if (!data.containsKey('producttype') || data['producttype'] == null) {
            data['producttype'] = {'guidfixed': '', 'code': '', 'names': []};
          } else {
            // ตรวจสอบและแก้ไขข้อมูลใน producttype
            if (data['producttype']['names'] == null) {
              data['producttype']['names'] = [];
            } else {
              // ตรวจสอบและแก้ไขข้อมูลใน producttype.names
              List<dynamic> names = data['producttype']['names'];
              for (int i = 0; i < names.length; i++) {
                if (names[i] != null) {
                  if (names[i]['code'] == null) {
                    names[i]['code'] = '';
                  }
                  if (names[i]['name'] == null) {
                    names[i]['name'] = '';
                  }
                }
              }
            }
            if (data['producttype']['guidfixed'] == null) {
              data['producttype']['guidfixed'] = '';
            }
            if (data['producttype']['code'] == null) {
              data['producttype']['code'] = '';
            }
          }
          if (!data.containsKey('restaurant') || data['restaurant'] == null) {
            data['restaurant'] = {
              'isforrestaurant': true,
              'isfortakeaway': true,
              'isfordelivery': true,
              'isforcustomer': true,
              'isforcustomerpreorder': true,
            };
          }

          final product = BarcodeMasterModel.fromJson(data);

          AppLogger.debug(
            'Successfully parsed BarcodeMasterModel: ${product.barcode}',
          );

          return product;
        } catch (parseError) {
          if (kDebugMode) {
            AppLogger.error('Error parsing full model: $parseError');
            AppLogger.debug('Attempting to create minimal BarcodeMasterModel...');
          }

          try {
            // สร้าง BarcodeMasterModel แบบ minimal จากข้อมูลที่สำคัญ
            final minimalProduct = BarcodeMasterModel(
              barcode: rawData['data']['barcode']?.toString() ?? '',
              names:
                  (rawData['data']['names'] as List?)
                      ?.map((e) => ItemName.fromJson(e))
                      .toList() ??
                  [],
              prices:
                  (rawData['data']['prices'] as List?)
                      ?.map((e) => PriceInfo.fromJson(e))
                      .toList() ??
                  [],
              itemunitcode: rawData['data']['itemunitcode']?.toString() ?? '',
              itemunitnames:
                  (rawData['data']['itemunitnames'] as List?)
                      ?.map((e) => ItemUnitName.fromJson(e))
                      .toList() ??
                  [],
            );

            AppLogger.debug(
              'Successfully created minimal BarcodeMasterModel: ${minimalProduct.barcode}',
            );

            return minimalProduct;
          } catch (minimalError) {
            if (kDebugMode) {
              AppLogger.error('Error creating minimal model: $minimalError');
              AppLogger.success('This is normal if barcode data is incomplete');
            }
            AppLogger.error('Parse error: $minimalError');
            return null;
          }
        }
      }

      AppLogger.debug(
        'Conditions not met - success: ${rawData?['success']}, data exists: ${rawData?['data'] != null}',
      );

      return null; // ไม่พบสินค้า
    } on DioException catch (ex) {
      String errorMessage = 'Network error: ${ex.message}';
      AppLogger.error(errorMessage);

      if (kDebugMode) {
        AppLogger.error('DioException in searchByBarcode: $errorMessage');
        AppLogger.debug('This is normal if barcode is not found');
      }

      // ไม่ throw exception แต่ return null
      return null;
    } catch (ex) {
      AppLogger.error(ex);

      if (kDebugMode) {
        AppLogger.error('General error in searchByBarcode: $ex');
        AppLogger.debug('This is normal if barcode is not found');
      }

      // ไม่ throw exception แต่ return null
      return null;
    }
  }

  /// เพิ่มสินค้าใหม่เข้าระบบ - เชื่อมต่อกับ API จริง
  Future<bool> addNewProduct(BarcodeMasterModel product) async {
    Dio client = Client().init();
    try {
      // เตรียมข้อมูลสำหรับส่งไปยัง API
      final productData = product.toJson();

      AppLogger.debug('Creating new product: $productData');

      final response = await client.post('/product/barcode', data: productData);

      AppLogger.debug('Create product response: $response');

      // ตรวจสอบ response data
      dynamic rawData;
      if (response.data is String) {
        rawData = json.decode(response.data);
      } else {
        rawData = response.data;
      }

      AppLogger.debug('Parsed create response data: $rawData');

      // ตรวจสอบ error
      if (rawData != null && rawData['error'] != null) {
        String errorMessage = '${rawData['code']}: ${rawData['message']}';
        AppLogger.error(errorMessage);
        throw Exception(errorMessage);
      }

      // ตรวจสอบ success
      if (rawData != null &&
          (rawData['success'] == true || rawData['success'] == 'true')) {
        return true;
      }

      return false;
    } on DioException catch (ex) {
      String errorMessage = 'Network error: ${ex.message}';
      AppLogger.error(errorMessage);

      AppLogger.debug('DioException in addNewProduct: $errorMessage');

      // ไม่ใช้ mock data แล้ว - throw error
      throw Exception('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้: ${ex.message}');
    } catch (ex) {
      AppLogger.error(ex);

      AppLogger.debug(
        'General error in addNewProduct: $ex',
      ); // ไม่ใช้ mock data แล้ว - throw error
      throw Exception('เกิดข้อผิดพลาดในการเพิ่มสินค้า: $ex');
    }
  }

  /// ดึงรายการหน่วยนับจาก API
  Future<List<UnitModel>> getUnits({int limit = 500}) async {
    Dio client = Client().init();
    try {
      final response = await client.get('/unit?limit=$limit');

      AppLogger.debug('Get units response: $response');

      // ตรวจสอบ response data
      dynamic rawData;
      if (response.data is String) {
        rawData = json.decode(response.data);
      } else {
        rawData = response.data;
      }

      AppLogger.debug('Parsed units response data: $rawData');

      // ตรวจสอบ error
      if (rawData != null && rawData['error'] != null) {
        String errorMessage = '${rawData['code']}: ${rawData['message']}';
        AppLogger.error(errorMessage);
        throw Exception(errorMessage);
      }

      // ตรวจสอบ success และ data
      if (rawData != null &&
          rawData['success'] == true &&
          rawData['data'] != null) {
        final unitResponse = UnitResponse.fromJson(rawData);
        return unitResponse.data;
      }

      return [];
    } on DioException catch (ex) {
      String errorMessage = 'Network error: ${ex.message}';
      AppLogger.error(errorMessage);

      AppLogger.debug('DioException in getUnits: $errorMessage');

      throw Exception('ไม่สามารถดึงข้อมูลหน่วยนับได้: ${ex.message}');
    } catch (ex) {
      AppLogger.error(ex);

      AppLogger.debug('General error in getUnits: $ex');

      throw Exception('เกิดข้อผิดพลาดในการดึงข้อมูลหน่วยนับ: $ex');
    }
  }

  /// ดึงข้อมูลหน่วยสินค้าทั้งหมด - เชื่อมต่อกับ API จริง
  Future<List<ItemUnitName>> fetchAllUnits() async {
    Dio client = Client().init();
    try {
      final response = await client.get('/product/units');

      AppLogger.debug('Fetch units response: $response');

      // ตรวจสอบ response data
      dynamic rawData;
      if (response.data is String) {
        rawData = json.decode(response.data);
      } else {
        rawData = response.data;
      }

      AppLogger.debug('Parsed units response data: $rawData');

      // ตรวจสอบ error
      if (rawData != null && rawData['error'] != null) {
        String errorMessage = '${rawData['code']}: ${rawData['message']}';
        AppLogger.error(errorMessage);
        throw Exception(errorMessage);
      }

      // ตรวจสอบ success และ data
      if (rawData != null &&
          (rawData['success'] == true || rawData['success'] == 'true') &&
          rawData['data'] != null) {
        // แปลงข้อมูลหน่วยสินค้าเป็น List<ItemUnitName>
        final units = (rawData['data'] as List)
            .map((e) => ItemUnitName.fromJson(e))
            .toList();

        return units;
      }

      return []; // คืนค่าเป็นลิสต์ว่างถ้าไม่พบข้อมูลหน่วยสินค้า
    } on DioException catch (ex) {
      String errorMessage = 'Network error: ${ex.message}';
      AppLogger.error(errorMessage);

      AppLogger.debug('DioException in fetchAllUnits: $errorMessage');

      // ไม่ใช้ mock data แล้ว - throw error
      throw Exception('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้: ${ex.message}');
    } catch (ex) {
      AppLogger.error(ex);

      AppLogger.debug('General error in fetchAllUnits: $ex');

      // ไม่ใช้ mock data แล้ว - throw error
      throw Exception('เกิดข้อผิดพลาดในการดึงข้อมูลหน่วยสินค้า: $ex');
    }
  }

  /// ดึงบาร์โค้ดที่เกี่ยวข้องจาก API /product/barcode/ref/{barcode}
  Future<List<BarcodeMasterModel>> getRelatedBarcodes(
    String barcode, {
    String shopsid = "",
  }) async {
    Dio client = Client().init();

    try {
      // สร้าง URL พร้อม query parameter
      String url = '/product/barcode/ref/$barcode';
      if (shopsid.isNotEmpty) {
        url += '?shopsid=$shopsid';
      }

      final response = await client.get(url);

      AppLogger.debug('Get related barcodes response: $response');

      // ตรวจสอบ response data
      dynamic rawData;
      if (response.data is String) {
        rawData = json.decode(response.data);
      } else {
        rawData = response.data;
      }

      AppLogger.debug('Parsed response data: $rawData');

      // ตรวจสอบ error
      if (rawData != null && rawData['error'] != null) {
        String errorMessage = '${rawData['code']}: ${rawData['message']}';
        AppLogger.error(errorMessage);
        if (kDebugMode) {
          AppLogger.error('API returned error in getRelatedBarcodes: $errorMessage');
          AppLogger.debug('This is normal if barcode has no related products');
        }
        return [];
      }

      // ตรวจสอบ success และ data
      if (rawData != null &&
          (rawData['success'] == true || rawData['success'] == 'true') &&
          rawData['data'] != null &&
          rawData['data'] is List) {
        List<BarcodeMasterModel> relatedProducts = [];
        List<dynamic> dataList = rawData['data'];

        for (var item in dataList) {
          if (item is Map<String, dynamic>) {
            try {
              // สร้าง BarcodeMasterModel จากข้อมูลที่ได้รับ
              // ต้องแปลงข้อมูลให้ตรงกับ structure ของ BarcodeMasterModel
              Map<String, dynamic> productData = {
                'guidfixed': item['guidfixed'] ?? '',
                'itemcode': item['itemcode'] ?? '',
                'itemunitcode': item['itemunitcode'] ?? '',
                'itemunitnames': item['itemunitnames'] ?? [],
                'ismainitem': item['ismainitem'] ?? false,
                'ismainbarcode': item['ismainbarcode'] ?? false,
                'groupcode': item['groupcode'] ?? '',
                'groupnames': item['groupnames'] ?? [],
                'barcode': item['barcode'] ?? '',
                'names': item['names'] ?? [],
                'prices': item['prices'] ?? [],
                'imageuri': item['imageuri'] ?? '',
                'useimageorcolor': item['useimageorcolor'] ?? true,
                'colorselect': item['colorselect'] ?? '',
                'colorselecthex': item['colorselecthex'] ?? '',
                'options': item['options'] ?? [],
                'parentguid': item['parentguid'] ?? '', // ใช้จาก API ถ้ามี
                'itemtype': item['itemtype'] ?? 0,
                'taxtype': item['taxtype'] ?? 0,
                'vattype': item['vattype'] ?? 0,
                'issumpoint': item['issumpoint'] ?? true,
                'maxdiscount': item['maxdiscount'] ?? '',
                'isdividend': item['isdividend'] ?? false,
                'barcodes': item['barcodes'] ?? [], // ใช้จาก API ถ้ามี
                'isusesubbarcodes': item['isusesubbarcodes'] ?? false,
                'condition': item['condition'] ?? false,
                'standvalue': item['standvalue'] ?? 1,
                'dividevalue': item['dividevalue'] ?? 1,
                'vatcal': item['vatcal'] ?? 0,
                'refbarcodes': item['refbarcodes'] ?? [],
                'bom': item['bom'] ?? [],
                'isalacarte': item['isalacarte'] ?? true,
                'ordertypes': item['ordertypes'] ?? [],
                'issplitunitprint': item['issplitunitprint'] ?? true,
                'isonlystaff': item['isonlystaff'] ?? false,
                'producttype': _validateProductType(item['producttype']),
                'foodtype': item['foodtype'] ?? 0,
                'showisdividend':
                    item['showisdividend'] ?? 0, // ใช้จาก API ถ้ามี
                'rownumber': item['rownumber'] ?? 0, // ใช้จาก API ถ้ามี
                'discount': item['discount'] ?? '',
                'isstockforrestaurant': item['isstockforrestaurant'] ?? false,
                'manufacturerguid': item['manufacturerguid'] ?? '',
                'manufacturercode': item['manufacturercode'] ?? '',
                'manufacturernames': item['manufacturernames'] ?? [],
                'dimensions': item['dimensions'] ?? [],
                'businesstypes': _validateBusinessTypes(item['businesstypes']),
                'ignorebranches': item['ignorebranches'] ?? [],
                'branches': item['branches'] ?? [], // ใช้จาก API ถ้ามี
                'isdiscountpointofpurchase':
                    item['isdiscountpointofpurchase'] ?? true,
                'restaurant': _validateRestaurant(item['restaurant']),
                'isalert': item['isalert'] ?? false,
                'alertdescription': item['alertdescription'] ?? '',
                'description': item['description'] ?? '',
                'isdisable': item['isdisable'] ?? false, // ใช้จาก API ถ้ามี
                'categorys': item['categorys'] ?? [], // ใช้จาก API ถ้ามี
                'timeforsales': item['timeforsales'] ?? [],
                'fixedcost': item['fixedcost'] ?? [],
                'materialtype': item['materialtype'] ?? 0,
                'refguidfixed': item['refguidfixed'] ?? '',
              };

              BarcodeMasterModel product = BarcodeMasterModel.fromJson(
                productData,
              );
              relatedProducts.add(product);

              AppLogger.debug(
                'Successfully parsed related barcode: ${product.barcode}',
              );
            } catch (e) {
              if (kDebugMode) {
                AppLogger.error('Error parsing related barcode item: $e');
                AppLogger.debug('Item data: $item');
              }
              AppLogger.error('Error parsing related barcode: $e');
            }
          }
        }

        return relatedProducts;
      }

      // ไม่พบข้อมูล
      return [];
    } on DioException catch (ex) {
      if (kDebugMode) {
        AppLogger.debug('DioException in getRelatedBarcodes: ${ex.message}');
        AppLogger.debug('This is normal if barcode has no related products');
      }

      // ไม่ throw exception แต่ return empty list
      return [];
    } catch (ex) {
      if (kDebugMode) {
        AppLogger.error('General error in getRelatedBarcodes: $ex');
        AppLogger.debug('This is normal if barcode has no related products');
      }

      // ไม่ throw exception แต่ return empty list
      return [];
    }
  }

  /// Helper method to validate businesstypes data
  List<dynamic> _validateBusinessTypes(dynamic businesstypes) {
    if (businesstypes == null) return [];

    if (businesstypes is List) {
      List<dynamic> validatedList = [];
      for (var item in businesstypes) {
        if (item is Map<String, dynamic>) {
          // สร้าง Map ใหม่ที่มี validation
          Map<String, dynamic> validatedItem = {
            'guidfixed': item['guidfixed'] ?? '',
            'code': item['code'] ?? '',
            'names': _validateBusinessTypeNames(item['names']),
            'isdefault': item['isdefault'] ?? false, // ป้องกัน null
          };
          validatedList.add(validatedItem);
        }
      }
      return validatedList;
    }

    return [];
  }

  /// Helper method to validate businesstype names
  List<dynamic> _validateBusinessTypeNames(dynamic names) {
    if (names == null) return [];

    if (names is List) {
      List<dynamic> validatedNames = [];
      for (var name in names) {
        if (name is Map<String, dynamic>) {
          Map<String, dynamic> validatedName = {
            'code': name['code'] ?? '',
            'name': name['name'] ?? '',
          };
          validatedNames.add(validatedName);
        }
      }
      return validatedNames;
    }

    return [];
  }

  /// Helper method to validate producttype data
  Map<String, dynamic> _validateProductType(dynamic producttype) {
    if (producttype == null) {
      return {'guidfixed': '', 'code': '', 'names': []};
    }

    if (producttype is Map<String, dynamic>) {
      return {
        'guidfixed': producttype['guidfixed'] ?? '',
        'code': producttype['code'] ?? '',
        'names': _validateProductTypeNames(producttype['names']),
      };
    }

    return {'guidfixed': '', 'code': '', 'names': []};
  }

  /// Helper method to validate producttype names
  List<dynamic> _validateProductTypeNames(dynamic names) {
    if (names == null) return [];

    if (names is List) {
      List<dynamic> validatedNames = [];
      for (var name in names) {
        if (name is Map<String, dynamic>) {
          Map<String, dynamic> validatedName = {
            'code': name['code'] ?? '',
            'name': name['name'] ?? '',
          };
          validatedNames.add(validatedName);
        }
      }
      return validatedNames;
    }

    return [];
  }

  /// Helper method to validate restaurant data
  Map<String, dynamic> _validateRestaurant(dynamic restaurant) {
    if (restaurant == null) {
      return {
        'isforrestaurant': true,
        'isfortakeaway': true,
        'isfordelivery': true,
        'isforcustomer': true,
        'isforcustomerpreorder': true,
      };
    }

    if (restaurant is Map<String, dynamic>) {
      return {
        'isforrestaurant': restaurant['isforrestaurant'] ?? true,
        'isfortakeaway': restaurant['isfortakeaway'] ?? true,
        'isfordelivery': restaurant['isfordelivery'] ?? true,
        'isforcustomer': restaurant['isforcustomer'] ?? true,
        'isforcustomerpreorder': restaurant['isforcustomerpreorder'] ?? true,
      };
    }

    return {
      'isforrestaurant': true,
      'isfortakeaway': true,
      'isfordelivery': true,
      'isforcustomer': true,
      'isforcustomerpreorder': true,
    };
  }

  /// ดึงรายการสินค้าทั้งหมด สำหรับหน้าเพิ่มราคา
  Future<Map<String, dynamic>> getProductList({
    String? search,
    int offset = 0,
    int limit = 50,
    bool zeroprice = true,
  }) async {
    Dio client = Client().init();

    try {
      String queryParams = 'offset=$offset&limit=$limit&zeroprice=$zeroprice';
      if (search != null && search.isNotEmpty) {
        queryParams += '&q=$search';
      }

      final response = await client.get('/product/barcode/list?$queryParams');

      AppLogger.debug('Get product list response: $response');

      // ตรวจสอบ response data
      dynamic rawData;
      if (response.data is String) {
        rawData = json.decode(response.data);
      } else {
        rawData = response.data;
      }

      AppLogger.debug('Parsed product list data: $rawData');

      // ตรวจสอบ error
      if (rawData != null && rawData['error'] != null) {
        String errorMessage = '${rawData['code']}: ${rawData['message']}';
        AppLogger.error(errorMessage);
        throw Exception(errorMessage);
      }

      // ตรวจสอบ success และ data
      if (rawData != null &&
          (rawData['success'] == true || rawData['success'] == 'true')) {
        return {
          'success': true,
          'data': rawData['data'] ?? [],
          'total': rawData['total'] ?? 0,
        };
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      AppLogger.error(
        'Network error in getProductList: ${e.message}',
      );
      throw Exception('เกิดข้อผิดพลาดในการเชื่อมต่อเครือข่าย: ${e.message}');
    } catch (e) {
      AppLogger.error('Error in getProductList: $e');
      throw Exception('เกิดข้อผิดพลาดในการดึงข้อมูลสินค้า: $e');
    }
  }

  /// อัปเดตราคาสินค้า
  Future<bool> updateProductPrice(String guidfixed, double price) async {
    Dio client = Client().init();

    try {
      final requestData = {
        'prices': [
          {'keynumber': 1, 'price': price},
        ],
      };

      final response = await client.put(
        '/product/barcode/$guidfixed',
        data: requestData,
      );

      AppLogger.debug('Update product price response: $response');

      // ตรวจสอบ response data
      dynamic rawData;
      if (response.data is String) {
        rawData = json.decode(response.data);
      } else {
        rawData = response.data;
      }

      AppLogger.debug('Parsed update price data: $rawData');

      // ตรวจสอบ error
      if (rawData != null && rawData['error'] != null) {
        String errorMessage = '${rawData['code']}: ${rawData['message']}';
        AppLogger.error(errorMessage);
        throw Exception(errorMessage);
      }

      // ตรวจสอบ success
      if (rawData != null &&
          (rawData['success'] == true || rawData['success'] == 'true')) {
        return true;
      } else {
        throw Exception('Failed to update price');
      }
    } on DioException catch (e) {
      AppLogger.error(
        'Network error in updateProductPrice: ${e.message}',
      );
      throw Exception('เกิดข้อผิดพลาดในการเชื่อมต่อเครือข่าย: ${e.message}');
    } catch (e) {
      AppLogger.error('Error in updateProductPrice: $e');
      throw Exception('เกิดข้อผิดพลาดในการอัปเดตราคา: $e');
    }
  }
}
