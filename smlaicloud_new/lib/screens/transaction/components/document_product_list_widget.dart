import 'dart:math';

import 'package:flutter/material.dart';
import 'package:smlaicloud/model/transaction_model.dart';
import 'package:smlaicloud/model/global_model.dart';
import 'package:smlaicloud/model/warehouse_model.dart';
import 'package:smlaicloud/model/location_model.dart';
import 'package:smlaicloud/model/product_model.dart';
import 'package:smlaicloud/model/price_model.dart';
import 'package:smlaicloud/screen_search/barcode_search_screen.dart';
import 'package:smlaicloud/screen_search/transaction_search_screen.dart';
import 'package:smlaicloud/screen_search/cart_search_screen.dart';
import 'package:smlaicloud/screens/transaction/components/add_product_buttom.dart';
import 'package:smlaicloud/global.dart' as global;
import 'package:intl/intl.dart';

class DocumentProductListWidget extends StatelessWidget {
  final TransactionModel screenData;
  final global.TransactionTypeEnum transactionType;
  final List<global.DataTableHeader> headers;
  final List<WarehouseModel> warehouseList;
  final String defualtwarehouse;
  final List<LanguageDataModel> defualtwarehousenames;
  final String defualtlocation;
  final List<LanguageDataModel> defualtlocationnames;
  final String defualttowarehouse;
  final List<LanguageDataModel> defualttowarehousenames;
  final String defualttolocation;
  final List<LanguageDataModel> defualttolocationnames;
  final int calcflag;
  final List<String> cartList;
  final List<dynamic> docrefs;
  final Function(void Function()) setState;
  final BuildContext context;

  // Callback functions
  final Future<WarehouseModel?> Function(BuildContext, List<WarehouseModel>) showWareHouseDefualtDialog;
  final Future<LocationModel?> Function(BuildContext, String) showWareHouseLocationDefualtDialog;
  final Function(String cmd, int index, TransactionDetailModel details) showDialogCommand;
  final Function(int index) deleteItemDetail;
  final Function() setGroupData;
  final Function() calTotalValue;
  final Function(List<PriceDataModel>?) getPrice;
  final Function() showBarcodeDialog;
  final Function(String, List<LanguageDataModel>, String, List<LanguageDataModel>, String, List<LanguageDataModel>, String, List<LanguageDataModel>) onWarehouseChanged;

  const DocumentProductListWidget({
    Key? key,
    required this.screenData,
    required this.transactionType,
    required this.headers,
    required this.warehouseList,
    required this.defualtwarehouse,
    required this.defualtwarehousenames,
    required this.defualtlocation,
    required this.defualtlocationnames,
    required this.defualttowarehouse,
    required this.defualttowarehousenames,
    required this.defualttolocation,
    required this.defualttolocationnames,
    required this.calcflag,
    required this.cartList,
    required this.docrefs,
    required this.setState,
    required this.context,
    required this.showWareHouseDefualtDialog,
    required this.showWareHouseLocationDefualtDialog,
    required this.showDialogCommand,
    required this.deleteItemDetail,
    required this.setGroupData,
    required this.calTotalValue,
    required this.getPrice,
    required this.showBarcodeDialog,
    required this.onWarehouseChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              _buildWarehouseSelectionWidget(),
              _buildTableHeader(constraints),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildProductListDetail(constraints.maxWidth),
                ),
              ),
              _buildBottomBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWarehouseSelectionWidget() {
    if (transactionType != global.TransactionTypeEnum.stocktransfer) {
      return Container(
        height: 25,
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            const SizedBox(width: 15),
            Text(global.language("warehouse")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(2),
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                ),
              ),
              onPressed: () async {
                WarehouseModel? result = await showWareHouseDefualtDialog(context, warehouseList) ?? WarehouseModel(guidfixed: '', code: '');
                if (result.code.isNotEmpty) {
                  String newDefualtwarehouse = result.code;
                  List<LanguageDataModel> newDefualtwarehousenames = result.names;
                  String newDefualtlocation = "";
                  List<LanguageDataModel> newDefualtlocationnames = [];

                  if (result.location.isNotEmpty) {
                    newDefualtlocation = result.location[0].code;
                    newDefualtlocationnames = result.location[0].names;
                  }

                  onWarehouseChanged(
                    newDefualtwarehouse,
                    newDefualtwarehousenames,
                    newDefualtlocation,
                    newDefualtlocationnames,
                    defualttowarehouse,
                    defualttowarehousenames,
                    defualttolocation,
                    defualttolocationnames,
                  );
                }
              },
              child: Text(
                global.activeLangName(defualtwarehousenames),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 15),
            Text(global.language("location")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(2),
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                ),
              ),
              onPressed: () async {
                if (defualtwarehouse.isNotEmpty) {
                  LocationModel? result = await showWareHouseLocationDefualtDialog(context, defualtwarehouse) ?? LocationModel(code: '');
                  if (result.code.isNotEmpty) {
                    onWarehouseChanged(
                      defualtwarehouse,
                      defualtwarehousenames,
                      result.code,
                      result.names,
                      defualttowarehouse,
                      defualttowarehousenames,
                      defualttolocation,
                      defualttolocationnames,
                    );
                  }
                }
              },
              child: Text(
                global.activeLangName(defualtlocationnames),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        height: 25,
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            const SizedBox(width: 15),
            Text(global.language("from_warehouse")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(2),
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                ),
              ),
              onPressed: () async {
                WarehouseModel? result = await showWareHouseDefualtDialog(context, warehouseList) ?? WarehouseModel(guidfixed: '', code: '');
                if (result.code.isNotEmpty) {
                  String newDefualtwarehouse = result.code;
                  List<LanguageDataModel> newDefualtwarehousenames = result.names;
                  String newDefualtlocation = "";
                  List<LanguageDataModel> newDefualtlocationnames = [];

                  if (result.location.isNotEmpty) {
                    newDefualtlocation = result.location[0].code;
                    newDefualtlocationnames = result.location[0].names;
                  }

                  onWarehouseChanged(
                    newDefualtwarehouse,
                    newDefualtwarehousenames,
                    newDefualtlocation,
                    newDefualtlocationnames,
                    defualttowarehouse,
                    defualttowarehousenames,
                    defualttolocation,
                    defualttolocationnames,
                  );
                }
              },
              child: Text(
                global.activeLangName(defualtwarehousenames),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 15),
            Text(global.language("location")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(2),
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                ),
              ),
              onPressed: () async {
                if (defualtwarehouse.isNotEmpty) {
                  LocationModel? result = await showWareHouseLocationDefualtDialog(context, defualtwarehouse) ?? LocationModel(code: '');
                  if (result.code.isNotEmpty) {
                    onWarehouseChanged(
                      defualtwarehouse,
                      defualtwarehousenames,
                      result.code,
                      result.names,
                      defualttowarehouse,
                      defualttowarehousenames,
                      defualttolocation,
                      defualttolocationnames,
                    );
                  }
                }
              },
              child: Text(
                global.activeLangName(defualtlocationnames),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 15),
            Text(global.language("to_warehouse")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(2),
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                ),
              ),
              onPressed: () async {
                WarehouseModel? result = await showWareHouseDefualtDialog(context, warehouseList) ?? WarehouseModel(guidfixed: '', code: '');
                if (result.code.isNotEmpty) {
                  String newDefualttowarehouse = result.code;
                  List<LanguageDataModel> newDefualttowarehousenames = result.names;
                  String newDefualttolocation = "";
                  List<LanguageDataModel> newDefualttolocationnames = [];

                  if (result.location.isNotEmpty) {
                    newDefualttolocation = result.location[0].code;
                    newDefualttolocationnames = result.location[0].names;
                  }

                  onWarehouseChanged(
                    defualtwarehouse,
                    defualtwarehousenames,
                    defualtlocation,
                    defualtlocationnames,
                    newDefualttowarehouse,
                    newDefualttowarehousenames,
                    newDefualttolocation,
                    newDefualttolocationnames,
                  );
                }
              },
              child: Text(
                global.activeLangName(defualttowarehousenames),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 15),
            Text(global.language("location")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(2),
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                ),
              ),
              onPressed: () async {
                if (defualttowarehouse.isNotEmpty) {
                  LocationModel? result = await showWareHouseLocationDefualtDialog(context, defualttowarehouse) ?? LocationModel(code: '');
                  if (result.code.isNotEmpty) {
                    onWarehouseChanged(
                      defualtwarehouse,
                      defualtwarehousenames,
                      defualtlocation,
                      defualtlocationnames,
                      defualttowarehouse,
                      defualttowarehousenames,
                      result.code,
                      result.names,
                    );
                  }
                }
              },
              child: Text(
                global.activeLangName(defualttolocationnames),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTableHeader(BoxConstraints constraints) {
    double sumWidth = 0;
    for (var header in headers) {
      sumWidth += header.width;
    }

    if (MediaQuery.of(context).size.width > 799) {
      return Row(
        children: [
          for (var index = 0; index < headers.length; index++)
            Container(
              padding: (index == 0)
                  ? const EdgeInsets.only(left: 0)
                  : (index == headers.length - 1)
                      ? const EdgeInsets.only(right: 4, left: 4)
                      : const EdgeInsets.only(left: 4),
              width: constraints.maxWidth * headers[index].width / sumWidth,
              child: Text(
                headers[index].label,
                textAlign: headers[index].textAlign,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            )
        ],
      );
    }
    return Container();
  }

  Widget _buildProductListDetail(double maxWidth) {
    double sumWidth = 0;
    for (var header in headers) {
      sumWidth += header.width;
    }

    List<Widget> widgets = [];
    String groupName = "";

    for (var index = 0; index < screenData.details!.length; index++) {
      // Group header for specific transaction types
      if (_shouldShowGroupHeader()) {
        if (screenData.details![index].docref! != groupName) {
          widgets.add(_buildGroupHeader(screenData.details![index]));
          groupName = screenData.details![index].docref!;
        }
      }

      List<Widget> dataWidgets = [];
      for (var loop = 0; loop < headers.length; loop++) {
        String dataText = _getDataText(headers[loop].code, index);

        if (headers[loop].code == 'delete') {
          dataWidgets.add(_buildDeleteButton(maxWidth, sumWidth, headers[loop], index));
        } else {
          dataWidgets.add(_buildDataButton(maxWidth, sumWidth, headers[loop], loop, dataText, index));
        }
      }

      widgets.add(
        Column(
          children: [
            Row(children: dataWidgets),
            _buildProductDescription(maxWidth, sumWidth, screenData.details![index].description!),
            _buildProductOptions(maxWidth, sumWidth, screenData.details![index].extrajsonlist!),
          ],
        ),
      );
    }

    return Column(children: widgets);
  }

  Widget _buildGroupHeader(TransactionDetailModel detail) {
    String dateTime = detail.docrefdatetime.toString();
    String tolocaldateTime = DateTime.parse(dateTime).toLocal().toIso8601String();

    if (detail.docref != "") {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          (transactionType != global.TransactionTypeEnum.stockreceiveproduct)
              ? Row(
                  children: [
                    Text(
                      detail.docref!,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd/MM/yyyy').format(DateTime.parse(tolocaldateTime)),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Text(
                      'ชื่อตะกร้า : ${detail.docref!}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        ],
      );
    }
    return Container();
  }

  Widget _buildDeleteButton(double maxWidth, double sumWidth, global.DataTableHeader header, int index) {
    return SizedBox(
      width: maxWidth * header.width / sumWidth,
      child: IconButton(
        onPressed: () {
          deleteItemDetail(index);
        },
        icon: const Icon(Icons.delete, color: Colors.red),
      ),
    );
  }

  Widget _buildDataButton(double maxWidth, double sumWidth, global.DataTableHeader header, int loop, String dataText, int index) {
    return Container(
      padding: (loop == 0)
          ? const EdgeInsets.only(left: 0)
          : (loop == headers.length - 1)
              ? const EdgeInsets.only(right: 4, left: 4)
              : const EdgeInsets.only(left: 4),
      width: maxWidth * header.width / sumWidth,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(2),
          alignment: header.alignment,
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(0)),
          ),
        ),
        onPressed: () {
          showDialogCommand(
            header.code,
            index,
            screenData.details![index],
          );
        },
        child: Text(
          dataText,
          textAlign: header.textAlign,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildProductDescription(double maxWidth, double sumWidth, String description) {
    List<Widget> widgets = [];
    if (description.isNotEmpty) {
      List<Widget> descriptions = [];

      for (var loop = 0; loop < headers.length; loop++) {
        String dataText = _getDescriptionText(headers[loop].code, description);

        if (headers[loop].code == 'delete') {
          descriptions.add(
            SizedBox(
              width: maxWidth * headers[loop].width / sumWidth,
            ),
          );
        } else {
          descriptions.add(
            Container(
              padding: (loop == 0)
                  ? const EdgeInsets.only(left: 0)
                  : (loop == headers.length - 1)
                      ? const EdgeInsets.only(right: 4, left: 4)
                      : const EdgeInsets.only(left: 4),
              width: maxWidth * headers[loop].width / sumWidth,
              child: Text(
                dataText,
                textAlign: headers[loop].textAlign,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        }
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Row(
            children: descriptions,
          ),
        ),
      );
    }

    return Column(children: widgets);
  }

  Widget _buildProductOptions(double maxWidth, double sumWidth, List<ExtraJsonListModel> options) {
    List<Widget> widgets = [];
    if (options.isNotEmpty) {
      for (var index = 0; index < options.length; index++) {
        List<Widget> dataOptions = [];

        for (var loop = 0; loop < headers.length; loop++) {
          String dataText = _getOptionText(headers[loop].code, options[index]);

          if (headers[loop].code == 'delete') {
            dataOptions.add(
              SizedBox(
                width: maxWidth * headers[loop].width / sumWidth,
              ),
            );
          } else {
            dataOptions.add(
              Container(
                padding: (loop == 0)
                    ? const EdgeInsets.only(left: 0)
                    : (loop == headers.length - 1)
                        ? const EdgeInsets.only(right: 4, left: 4)
                        : const EdgeInsets.only(left: 4),
                width: maxWidth * headers[loop].width / sumWidth,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(2),
                    alignment: headers[loop].alignment,
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(0)),
                    ),
                  ),
                  onPressed: null,
                  child: Text(
                    dataText,
                    textAlign: headers[loop].textAlign,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            );
          }
        }

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: Row(
              children: dataOptions,
            ),
          ),
        );
      }
    }

    return Column(children: widgets);
  }

  Widget _buildBottomBar() {
    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              AddProductButtom(
                onSearchPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BarcodeSearchScreen(
                        word: '',
                        screen: (transactionType == global.TransactionTypeEnum.sale || transactionType == global.TransactionTypeEnum.salereturn) ? 'not_material' : 'material',
                      ),
                    ),
                  ).then((value) {
                    ProductBarcodeModel result = value;
                    if (result.barcode!.trim().isNotEmpty) {
                      _addProductFromBarcode(result);
                    }
                  });
                },
                onBarcodePressed: () async {
                  showBarcodeDialog();
                },
                onAddPressed: () {
                  _addEmptyProduct();
                },
              ),
              if (_shouldShowDocRefButton())
                ElevatedButton(
                  onPressed: () {
                    _handleDocRefButtonPressed();
                  },
                  child: Text(_getDocRefButtonText()),
                ),
              if (_shouldShowCartButton())
                ElevatedButton(
                  onPressed: () {
                    _handleCartButtonPressed();
                  },
                  child: Text('ดึงจากตะกร้าสินค้า'),
                ),
            ],
          ),
          if (_shouldShowTotalValue())
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '${global.language("total_value")} : ${global.formatNumber(screenData.totalvalue)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  // Helper methods
  /// แสดง เอกสารอ้างอิง
  bool _shouldShowGroupHeader() {
    return transactionType == global.TransactionTypeEnum.purchasereturn ||
        transactionType == global.TransactionTypeEnum.salereturn ||
        transactionType == global.TransactionTypeEnum.stockreturnproduct ||
        transactionType == global.TransactionTypeEnum.stockreceiveproduct ||
        transactionType == global.TransactionTypeEnum.sale ||
        transactionType == global.TransactionTypeEnum.purchase ||
        transactionType == global.TransactionTypeEnum.purchasepartial;
  }

  /// แสดงปุ่ม เอกสารอ้างอิง
  bool _shouldShowDocRefButton() {
    return transactionType == global.TransactionTypeEnum.purchasereturn ||
        transactionType == global.TransactionTypeEnum.purchase ||
        transactionType == global.TransactionTypeEnum.salereturn ||
        transactionType == global.TransactionTypeEnum.sale ||
        transactionType == global.TransactionTypeEnum.stockreturnproduct ||
        transactionType == global.TransactionTypeEnum.purchasepartial ||
        transactionType == global.TransactionTypeEnum.accrualreceive;
  }

  /// แสดงปุ่ม ดึงจากตะกร้าสินค้า
  bool _shouldShowCartButton() {
    return transactionType == global.TransactionTypeEnum.stockreceiveproduct ||
        transactionType == global.TransactionTypeEnum.stockpickupproduct ||
        transactionType == global.TransactionTypeEnum.stocktransfer;
  }

  bool _shouldShowTotalValue() {
    return !(transactionType == global.TransactionTypeEnum.stocktransfer ||
        transactionType == global.TransactionTypeEnum.stockpickupproduct ||
        transactionType == global.TransactionTypeEnum.stockreturnproduct ||
        transactionType == global.TransactionTypeEnum.adjust);
  }

  String _getDataText(String code, int index) {
    switch (code) {
      case "delete":
        return "";
      case "line_number":
        return (index + 1).toString();
      case "barcode":
        return screenData.details![index].barcode;
      case "item_code": // เพิ่ม case สำหรับ item_code
        return screenData.details![index].itemcode;
      case "product_name":
        return global.activeLangName(screenData.details![index].itemnames!);
      case "product_ware_house":
        return global.activeLangName(screenData.details![index].whnames!);
      case "product_location":
        return global.activeLangName(screenData.details![index].locationnames!);
      case "product_to_ware_house":
        return global.activeLangName(screenData.details![index].towhnames!);
      case "product_to_location":
        return global.activeLangName(screenData.details![index].tolocationnames!);
      case "product_unit":
        return global.activeLangName(screenData.details![index].unitnames!);
      case "product_qty":
        return global.formatNumber(screenData.details![index].qty);
      case "product_price_adjust":
        return global.formatNumber(screenData.details![index].price);
      case "product_price":
        return global.formatNumber(screenData.details![index].price);
      case "product_discount":
        return screenData.details![index].discount;
      case "product_amount":
        return global.formatNumber(screenData.details![index].sumamount);
      default:
        return "";
    }
  }

  String _getDescriptionText(String code, String description) {
    switch (code) {
      case "product_name":
        return "หมายเหตุ : $description";
      default:
        return "";
    }
  }

  String _getOptionText(String code, ExtraJsonListModel option) {
    switch (code) {
      case "barcode":
        return option.barcode!;
      case "product_name":
        return "- ${global.activeLangName(option.itemnames!)}";
      case "product_unit":
        return option.unit_name!;
      case "product_qty":
        return global.formatNumber((option.qty == 0) ? 1 : option.qty!);
      case "product_price":
        return global.formatNumber(option.price!);
      case "product_amount":
        return global.formatNumber(option.price! * ((option.qty == 0) ? 1 : option.qty!));
      default:
        return "";
    }
  }

  String _getDocRefButtonText() {
    if (transactionType == global.TransactionTypeEnum.purchasereturn) {
      return global.language('add_docref_purchasereturn');
    } else if (transactionType == global.TransactionTypeEnum.purchase || transactionType == global.TransactionTypeEnum.purchasepartial) {
      return 'อ้างอิง ใบสั่งซื้อ';
    } else if (transactionType == global.TransactionTypeEnum.salereturn) {
      return global.language('add_docref_salereturn');
    } else if (transactionType == global.TransactionTypeEnum.accrualreceive) {
      return 'อ้างอิง ใบรับสินค้า(แบบทยอย)';
    } else {
      return global.language('add_docref_stockreturnproduct');
    }
  }

  void _addProductFromBarcode(ProductBarcodeModel result) {
    String whcode = defualtwarehouse;
    List<LanguageDataModel> whnames = defualtwarehousenames;
    String locationcode = defualtlocation;
    List<LanguageDataModel> locationnames = defualtlocationnames;

    screenData.details!.add(
      TransactionDetailModel(
        docdatetime: DateTime.now().toLocal().toIso8601String(),
        itemguid: result.guidfixed,
        barcode: result.barcode!,
        itemcode: result.itemcode ?? "",
        itemnames: result.names,
        unitcode: result.itemunitcode,
        qty: (transactionType == global.TransactionTypeEnum.adjust) ? 0 : 1,
        price: (transactionType == global.TransactionTypeEnum.adjust) ? 0 : getPrice(result.prices),
        discount: '',
        sumofcost: 0,
        sumamount: 0,
        remark: '',
        linenumber: 0,
        whcode: whcode,
        whnames: whnames,
        shelfcode: '',
        locationcode: locationcode,
        locationnames: locationnames,
        totalvaluevat: 0,
        totalqty: 0,
        standvalue: result.standvalue!,
        dividevalue: result.dividevalue!,
        multiunit: true,
        unitnames: result.itemunitnames,
        calcflag: calcflag,
        vattype: 0,
        averagecost: 0,
        sumamountexcludevat: 0,
        discountamount: 0,
        ispos: 0,
        laststatus: 0,
        itemtype: 0,
        inquirytype: 0,
        priceexcludevat: 0,
        taxtype: result.taxtype!,
        vatcal: result.vatcal,
        towhcode: defualttowarehouse,
        towhnames: defualttowarehousenames,
        tolocationcode: defualttolocation,
        tolocationnames: defualttolocationnames,
        refbarcodes: result.refbarcodes,
        manufacturerguid: result.manufacturerguid,
      ),
    );
    setGroupData();
    calTotalValue();
    setState(() {});
  }

  void _addEmptyProduct() {
    screenData.details!.add(
      TransactionDetailModel(
        docdatetime: DateTime.now().toLocal().toIso8601String(),
        itemguid: '',
        barcode: '',
        itemcode: '',
        itemnames: [],
        unitcode: '',
        qty: 0,
        price: 0,
        discount: '',
        sumofcost: 0,
        sumamount: 0,
        remark: '',
        linenumber: 0,
        whcode: '',
        shelfcode: '',
        locationcode: '',
        totalvaluevat: 0,
        totalqty: 0,
        standvalue: 1,
        dividevalue: 1,
        calcflag: calcflag,
        vattype: 0,
        averagecost: 0,
        sumamountexcludevat: 0,
        discountamount: 0,
        ispos: 0,
        laststatus: 0,
        itemtype: 0,
        inquirytype: 0,
        multiunit: true,
        priceexcludevat: 0,
        taxtype: 0,
        vatcal: 0,
        manufacturerguid: '',
      ),
    );
    setState(() {});
    setGroupData();
  }

  void _handleDocRefButtonPressed() {
    if (transactionType != global.TransactionTypeEnum.stockreturnproduct) {
      if (screenData.custcode.isEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Center(
              child: AlertDialog(
                content: Text((transactionType == global.TransactionTypeEnum.purchasereturn ||
                        transactionType == global.TransactionTypeEnum.purchase ||
                        transactionType == global.TransactionTypeEnum.purchasepartial ||
                        transactionType == global.TransactionTypeEnum.accrualreceive)
                    ? global.language("please_input_custcode_creditor")
                    : global.language("please_input_custcode_debtor")),
                actions: [
                  TextButton(
                    child: Text(global.language("confirm")),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
        return;
      }
    }

    global.TransactionTypeEnum searchDocRefType = global.TransactionTypeEnum.purchase;

    if (transactionType == global.TransactionTypeEnum.purchasereturn) {
      searchDocRefType = global.TransactionTypeEnum.purchase;
    } else if (transactionType == global.TransactionTypeEnum.salereturn) {
      searchDocRefType = global.TransactionTypeEnum.sale;
    } else if (transactionType == global.TransactionTypeEnum.stockreturnproduct) {
      searchDocRefType = global.TransactionTypeEnum.stockpickupproduct;
    } else if (transactionType == global.TransactionTypeEnum.purchase || transactionType == global.TransactionTypeEnum.purchasepartial) {
      searchDocRefType = global.TransactionTypeEnum.purchaseorder;
    } else if (transactionType == global.TransactionTypeEnum.sale) {
      searchDocRefType = global.TransactionTypeEnum.saleorder;
    } else if (transactionType == global.TransactionTypeEnum.accrualreceive) {
      searchDocRefType = global.TransactionTypeEnum.purchasepartial;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransSearchScreen(
          custcode: screenData.custcode,
          type: searchDocRefType,
        ),
      ),
    ).then((value) {
      if (value != null) {
        TransactionModel result = value;
        if (result.docno.isNotEmpty) {
          screenData.details!.removeWhere((detail) => result.docno == detail.docref);

          for (var data in result.details!) {
            data.docref = result.docno;
            data.docrefdatetime = result.docdatetime;
            screenData.details!.add(data);
          }

          if (transactionType == global.TransactionTypeEnum.salereturn ||
              transactionType == global.TransactionTypeEnum.purchasereturn ||
              transactionType == global.TransactionTypeEnum.sale ||
              transactionType == global.TransactionTypeEnum.purchase ||
              transactionType == global.TransactionTypeEnum.purchasepartial ||
              transactionType == global.TransactionTypeEnum.accrualreceive) {
            /// ดึงมูลค่าบิลเดิม
            double reftotaloriginal = 0;
            reftotaloriginal = (result.totalbeforevat + result.totalexceptvat);

            screenData.reftotaloriginal = (screenData.reftotaloriginal! + reftotaloriginal);

            docrefs.add({
              "docref": result.docno,
              "totaloriginal": reftotaloriginal,
            });
          }

          setGroupData();
          calTotalValue();
          setState(() {});
        }
      }
    });
  }

  void _handleCartButtonPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartListSearchScreen(
          onCartSelected: (details, cartId) {
            if (details.isNotEmpty) {
              setState(() {
                screenData.details!.addAll(details);
              });
              cartList.add(cartId);
            }
          },
        ),
      ),
    );
  }
}
