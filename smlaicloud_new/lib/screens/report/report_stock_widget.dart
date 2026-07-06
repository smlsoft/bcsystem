import 'package:flutter/material.dart';
import 'package:smlaicloud/model/report_condition_model.dart';
import 'package:smlaicloud/utils/util.dart';
import 'package:smlaicloud/global.dart' as global;

class ReportStockConditionClass {
  final VoidCallback? onStateUpdate;

  List<ConditionWareHouseSelectModel> conditionWareHouseCodeList = [];
  List<String> conditionBarcodeList = [];
  bool showOnlyBalance = true;
  bool showOnlyWithMovement = true;

  ReportStockConditionClass({this.onStateUpdate}) {
    conditionWareHouseCodeList = [];
    conditionBarcodeList = [];
    if (onStateUpdate != null) {
      onStateUpdate!();
    }
  }

  Future<void> reloadWareHouseCode() async {
    conditionWareHouseCodeList.clear();
    List<String> getBarcodeRefList = [];
    for (var item in conditionBarcodeList) {
      getBarcodeRefList.add(item);
    }
    {
      String where = " where shopid = '${global.getShopId()}'";
      if (conditionBarcodeList.isNotEmpty) {
        where += " and barcoderef in (${conditionBarcodeList.map((e) => "'$e'").join(",")})";
        var response = await clickhouseSelectGroup(["select barcode from dedebi.productbarcodeprocess $where order by barcode"]);
        if (response["status"] == "success") {
          List<dynamic> data = response["data"];
          for (var item in data[0]) {
            getBarcodeRefList.add(item["barcode"]);
          }
        }
      }
    }
    {
      // ดึงข้อมูลคลังสินค้า
      String where = " where shopid = '${global.getShopId()}'";
      if (getBarcodeRefList.isNotEmpty) {
        where += " and barcode in (${getBarcodeRefList.map((e) => "'$e'").join(",")})";
      }
      var response = await clickhouseSelectGroup([
        "SELECT distinct whcode as whcode FROM dedebi.processstockdetail $where order by whcode",
      ]);
      if (response["status"] == "success") {
        List<dynamic> data = response["data"];
        for (var item in data[0]) {
          conditionWareHouseCodeList.add(ConditionWareHouseSelectModel(item["whcode"].toString(), item["whcode"].toString()));
        }
      }
    }
    {
      // ดึงข้อมูลที่เก็บสินค้า
      String where = " where shopid = '${global.getShopId()}'";
      if (getBarcodeRefList.isNotEmpty) {
        where += " and barcode in (${getBarcodeRefList.map((e) => "'$e'").join(",")})";
      }
      var response = await clickhouseSelectGroup([
        "SELECT distinct whcode as whcode,locationcode as locationcode FROM dedebi.processstockdetail $where order by whcode,locationcode",
      ]);
      if (response["status"] == "success") {
        List<dynamic> data = response["data"];
        for (var wareHouse in conditionWareHouseCodeList) {
          for (var location in data[0]) {
            if (location["whcode"].toString() == wareHouse.code) {
              wareHouse.locations.add(ConditionLocationSelectModel(location["locationcode"].toString(), location["locationcode"].toString()));
            }
          }
        }
        if (onStateUpdate != null) {
          onStateUpdate!();
        }
      }

      if (onStateUpdate != null) {
        onStateUpdate!();
      }
    }
  }

  // เลือกคลังสินค้า
  Widget selectWareHouseWidget({required Color primaryColor, required Color secondaryColor}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 4.0,
            runSpacing: 4.0,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  for (var item in conditionWareHouseCodeList) {
                    item.isSelected = true;
                  }

                  if (onStateUpdate != null) {
                    onStateUpdate!();
                  }
                },
                icon: const Icon(Icons.check_box, size: 18), // เพิ่มไอคอน "เพิ่ม"
                label: const Text("เลือกคลังสินค้าทั้งหมด"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600, // สีปุ่มน้ำเงินเข้ม
                  foregroundColor: Colors.white, // สีตัวอักษรและไอคอน
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: (conditionWareHouseCodeList.isNotEmpty)
                    ? () {
                        for (var item in conditionWareHouseCodeList) {
                          item.isSelected = false;
                        }

                        if (onStateUpdate != null) {
                          onStateUpdate!();
                        }
                      }
                    : null,
                icon: const Icon(Icons.delete, size: 18),
                label: const Text("ไม่เลือกคลังสินค้าทั้งหมด"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800, // สีปุ่มส้ม
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "เลือกคลังสินค้าที่ต้องการรายงาน (สามารถเลือกได้หลายรายการ ถ้าไม่เลือกจะรายงานทั้งหมด)",
                style: TextStyle(
                  color: Colors.grey.shade800, // สีเทาเข้มเพื่อความนุ่มนวล
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4.0,
            runSpacing: 4.0,
            children: conditionWareHouseCodeList.map((item) {
              return ElevatedButton(
                onPressed: () {
                  item.isSelected = !item.isSelected;
                  if (onStateUpdate != null) {
                    onStateUpdate!();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: item.isSelected ? Colors.blue.shade600 : Colors.blue.shade300,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Row(
                    children: [
                      Icon(
                        (item.isSelected) ? Icons.check_circle : Icons.circle,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  Text(item.code),
                ]),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // เลือกที่เก็บสินค้า
  Widget selectLocationWidget({required Color primaryColor, required Color secondaryColor}) {
    List<Widget> locationWidgetList = [];
    for (var wareHouse in conditionWareHouseCodeList) {
      if (wareHouse.isSelected) {
        locationWidgetList.add(Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "คลังสินค้า ${wareHouse.code}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      wareHouse.isSelected = false;
                      if (onStateUpdate != null) {
                        onStateUpdate!();
                      }
                    },
                  ),
                ],
              ),
              Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4.0,
                runSpacing: 4.0,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      for (var item in wareHouse.locations) {
                        item.isSelected = true;
                      }
                      if (onStateUpdate != null) {
                        onStateUpdate!();
                      }
                    },
                    icon: const Icon(Icons.check_box, size: 18), // เพิ่มไอคอน "เพิ่ม"
                    label: const Text("เลือกที่เก็บสินค้าทั้งหมด"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600, // สีปุ่มน้ำเงินเข้ม
                      foregroundColor: Colors.white, // สีตัวอักษรและไอคอน
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: (wareHouse.locations.isNotEmpty)
                        ? () {
                            for (var item in wareHouse.locations) {
                              item.isSelected = false;
                            }
                            if (onStateUpdate != null) {
                              onStateUpdate!();
                            }
                          }
                        : null,
                    icon: const Icon(Icons.delete, size: 18), // เพิ่มไอคอน "รีเฟรช"
                    label: const Text("ไม่เลือกที่เก็บสินค้าทั้งหมด"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800, // สีปุ่มส้ม
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "เลือกที่เก็บสินค้าที่ต้องการรายงาน (สามารถเลือกได้หลายรายการ ถ้าไม่เลือกจะรายงานทั้งหมด)",
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4.0,
                runSpacing: 4.0,
                children: wareHouse.locations.map((item) {
                  return ElevatedButton(
                    onPressed: () {
                      item.isSelected = !item.isSelected;
                      if (onStateUpdate != null) {
                        onStateUpdate!();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.isSelected ? Colors.blue.shade600 : Colors.blue.shade300,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Row(
                        children: [
                          Icon(
                            (item.isSelected) ? Icons.check_circle : Icons.circle,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                      Text(item.code),
                    ]),
                  );
                }).toList(),
              ),
            ],
          ),
        ));
      }
    }
    return Column(children: locationWidgetList);
  }
}
