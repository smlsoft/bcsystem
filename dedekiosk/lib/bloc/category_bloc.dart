import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/model/category_model.dart';
import 'package:dedekiosk/model/product_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class CategoryEvent {}

abstract class CategoryState {}

class CategoryStateInitialized extends CategoryState {}

class CategoryLoadStart extends CategoryEvent {
  CategoryLoadStart();
}

class CategoryLoadSuccess extends CategoryState {
  List<CategoryModel> category;
  CategoryLoadSuccess({required this.category});
}

class CategoryLoadFail extends CategoryState {
  String message;
  CategoryLoadFail({required this.message});
}

class CategoryMachineCountSuccess extends CategoryState {
  int count;
  CategoryMachineCountSuccess({required this.count});
}

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc() : super(CategoryStateInitialized()) {
    on<CategoryLoadStart>(_categoryLoadStart);
    on<CategoryLoadFinish>(_categoryLoadFinish);
  }
  void _categoryLoadStart(CategoryLoadStart event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());

    if (global.deviceConfig.shopId.isEmpty) {
      emit(CategoryLoadFail(message: "Shop ID not found"));
      return;
    }

    try {
      // 1. ดึงข้อมูลหมวดหมู่จากเซิร์ฟเวอร์
      var categoryValue = await api.getCategoryFromServer();
      CategoryResponseMainModel categoryResponse = CategoryResponseMainModel.fromJson(categoryValue);

      // 2. แปลงข้อมูลหมวดหมู่และรวบรวมบาร์โค้ด
      List<CategoryModel> categoryData = [];
      Set<String> barcodeSet = {};

      for (var category in categoryResponse.data) {
        categoryData.add(CategoryModel(
          guidfixed: category.guidfixed,
          parentguid: category.parentguid,
          imageuri: category.imageuri,
          coveruri: category.coveruri,
          names: category.names,
          xsorts: category.xsorts,
          codelist: category.codelist,
          timeforsales: category.timeforsales ?? [],
        ));

        for (var code in category.codelist) {
          barcodeSet.add(code.barcode);
        }
      }

      // 3. เรียงลำดับหมวดหมู่ตาม xorder
      categoryData.sort((a, b) => a.xsorts[0].xorder.compareTo(b.xsorts[0].xorder));

      // 3.1 ย้าย category ที่มี guidfixed = "00000000000000000" ไปไว้ท้ายสุด
      final zeroGuidCategories = categoryData.where((c) => c.guidfixed == "00000000000000000").toList();
      categoryData.removeWhere((c) => c.guidfixed == "00000000000000000");
      categoryData.addAll(zeroGuidCategories);

      // 4. ดึงข้อมูลสินค้าจากบาร์โค้ด
      var barcodeData = await api.getProductByBarcodeFromServer(barcodeSet.toList());
      List<ProductFromServerModel> productData = ProductResponseModel.fromJson(barcodeData).data;

      Map<String, ProductFromServerModel> productMap = {for (var product in productData) product.barcode: product};

      // 6. อัปเดตข้อมูลภาพและตัวเลือกในรายการสินค้า
      for (var category in categoryData) {
        for (var item in category.codelist) {
          if (productMap.containsKey(item.barcode)) {
            var product = productMap[item.barcode]!;
            item.imageurl = product.imageuri;
            item.useoption = product.options != null && product.options!.isNotEmpty;
            item.prices = product.prices;
          }
        }
      }

      // 6.1 กรอง category.codelist ตาม machineCondition
      for (var category in categoryData) {
        category.codelist.removeWhere((item) {
          if (!productMap.containsKey(item.barcode)) {
            return false; // ถ้าไม่มีข้อมูลสินค้า ให้เก็บไว้ตามเดิม
          }
          var product = productMap[item.barcode]!;
          bool isonlystaff = product.isonlystaff ?? false;

          if (global.deviceConfig.machineCondition == 0) {
            // machineCondition == 0: ไม่เช็คเงื่อนไขใดๆ (เก็บทั้งหมด)
            return false;
          } else if (global.deviceConfig.machineCondition == 1) {
            // machineCondition == 1: กรองเฉพาะสินค้าที่ isonlystaff = false
            return isonlystaff; // ลบออกถ้า isonlystaff = true
          }
          return false; // กรณีอื่นๆ เก็บไว้ทั้งหมด
        });
      }

      // 6.2 ลบ category ที่มี codelist ว่างเปล่า
      categoryData.removeWhere((category) => category.codelist.isEmpty);

      // 7. เตรียมข้อมูลสินค้าหลักและ Map สำหรับการเข้าถึงเร็ว

      List<ProductProcessModel> newProductList = [];
      Map<String, ProductProcessModel> productProcessMap = {};

      // 8. สร้างรายการสินค้าหลักจากข้อมูลบาร์โค้ดที่มีทั้งหมด
      for (var category in categoryData) {
        for (var item in category.codelist) {
          // ตรวจสอบว่าสินค้านี้เพิ่มแล้วหรือยัง และมีข้อมูลจากเซิร์ฟเวอร์หรือไม่
          if (productMap.containsKey(item.barcode) && !productProcessMap.containsKey(item.barcode)) {
            var product = productMap[item.barcode]!;

            // สร้างข้อมูลสินค้าพื้นฐาน
            ProductProcessModel productProcess = ProductProcessModel(
              type: 0,
              issplitunitprint: false,
              code: item.code,
              barcode: item.barcode,
              unitcode: item.unitcode,
              unitnames: item.unitnames,
              names: item.names,
              prices: product.prices,
              setprice: global.findProductPrice(prices: product.prices),
              discountword: product.discount ?? "",
              imageuri: product.imageuri,
              qty: 0,
              options: [],
              amount: 0,
              ordertypes: product.ordertypes ?? [],
              isAlacarte: product.isalacarte ?? false,
              orderguid: "",
              refcategoryguid: "",
              remark: "",
              foodtype: product.foodtype ?? 0,
              isexceptvat: product.vatcal == 1,
              manufacturerguid: item.manufacturerguid,
              isonlystaff: product.isonlystaff ?? false,
              isforcustomer: product.restaurant?.isforcustomer ?? false,
            );
            // เพิ่มเข้ารายการและ Map
            productProcess.isstockforrestaurant = product.isstockforrestaurant ?? false;

            // กรองสินค้าตาม machineCondition
            bool shouldAddProduct = true;
            if (global.deviceConfig.machineCondition == 0) {
              // machineCondition == 0: ไม่เช็คเงื่อนไขใดๆ (เก็บทั้งหมด)
              shouldAddProduct = true;
            } else if (global.deviceConfig.machineCondition == 1) {
              // machineCondition == 1: กรองเฉพาะสินค้าที่ isonlystaff = false
              shouldAddProduct = !productProcess.isonlystaff;
            }

            if (shouldAddProduct) {
              newProductList.add(productProcess);
              productProcessMap[item.barcode] = productProcess;
            }
          } else if (!productMap.containsKey(item.barcode) && kDebugMode) {
            print("error product not found ${item.barcode}");
          }
        }
      }

      // 9. เรียงรายการสินค้า
      newProductList.sort((a, b) => a.code.compareTo(b.barcode));

      // 10. จัดการตัวเลือกสินค้า
      for (var product in productData) {
        if (productProcessMap.containsKey(product.barcode)) {
          var productItem = productProcessMap[product.barcode]!;

          // 11. จัดการตัวเลือกสินค้า
          if (product.options != null) {
            for (var option in product.options!) {
              List<ProductProcessOptionChoiceModel> choices = [];

              for (var choice in option.choices) {
                choices.add(ProductProcessOptionChoiceModel(
                    guid: choice.guid,
                    names: choice.names,
                    imageuri: choice.imageuri,
                    price: choice.price,
                    qty: choice.qty,
                    discountWord: "",
                    discountAmount: 0,
                    selected: false,
                    amount: 0.0,
                    refbarcode: choice.refbarcode,
                    refunitcode: choice.refunitcode,
                    refunitnames: choice.refunitnames,
                    priceValue: double.tryParse(choice.price) ?? 0.0));
              }

              productItem.options.add(ProductProcessOptionModel(
                guid: option.guid,
                choicetype: option.choicetype,
                maxselect: option.maxselect,
                minselect: option.minselect,
                choices: choices,
                names: option.names,
              ));
            }
          }
        }
      }

      // // 12. สร้างหมวดหมู่ "ทั้งหมด"
      // CategoryModel allProduct = CategoryModel(
      //   guidfixed: "00000000-0000-0000-0000-000000000000",
      //   parentguid: "00000000-0000-0000-0000-000000000000",
      //   imageuri: "",
      //   coveruri: "",
      //   xsorts: [],
      //   names: [LanguageNameModel(code: "th", name: "ทั้งหมด"), LanguageNameModel(code: "en", name: "All")],
      //   codelist: [],
      //   timeforsales: [],
      // );

      // // 13. เพิ่มสินค้าทั้งหมดเข้าหมวดหมู่ "ทั้งหมด"
      // for (var product in newProductList) {
      //   allProduct.codelist.add(CategoryCodeListModel(
      //     barcode: product.barcode,
      //     code: product.code,
      //     unitcode: product.unitcode,
      //     unitnames: product.unitnames,
      //     names: product.names,
      //     imageurl: product.imageuri,
      //     manufacturerguid: product.manufacturerguid,
      //     xorder: 0,
      //   ));
      // }
      // categoryData.add(allProduct); // 14. คำนวณส่วนลดสำหรับราคาหน้าร้าน
      for (var product in newProductList) {
        int priceIndex = product.prices.indexWhere((price) => price.keynumber == 1);
        if (priceIndex != -1) {
          product.prices[priceIndex].price = product.setprice - global.calcDiscount(amount: product.setprice, discountWord: product.discountword);
        }
      }

      // 15. อัปเดตข้อมูลราคาและส่วนลดในรายการสินค้า
      for (var category in categoryData) {
        for (var item in category.codelist) {
          int index = newProductList.indexWhere((element) => element.barcode == item.barcode);
          if (index != -1) {
            item.setprice = newProductList[index].setprice;
            item.prices = newProductList[index].prices;
            item.discountword = newProductList[index].discountword;
          }
        }
      }

      // แทนที่ global.productList เมื่อข้อมูลพร้อมแล้ว
      global.productList = newProductList;

      emit(CategoryLoadSuccess(category: categoryData));
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
      emit(CategoryLoadFail(message: "Error : ${e.toString()}"));
    }
  }

  void _categoryLoadFinish(CategoryLoadFinish event, Emitter<CategoryState> emit) async {
    emit(CategoryLoadStop());
  }
}

class CategoryLoadStop extends CategoryState {}

class CategoryLoadFinish extends CategoryEvent {}

class CategoryLoading extends CategoryState {}
