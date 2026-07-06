// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:smlaicloud/bloc/export_csv/export_csv_bloc.dart';
import 'package:smlaicloud/imports_bloc.dart';
import 'package:smlaicloud/model/book_bank_model.dart';
import 'package:smlaicloud/model/company_branch_model.dart';
import 'package:smlaicloud/model/employee_model.dart';
import 'package:smlaicloud/model/global_model.dart';
import 'package:smlaicloud/model/location_model.dart';
import 'package:smlaicloud/model/price_model.dart';
import 'package:smlaicloud/model/product_model.dart';
import 'package:smlaicloud/model/sale_channel_model.dart';
import 'package:smlaicloud/model/transaction_model.dart';
import 'package:smlaicloud/model/transport_channel_model.dart';
import 'package:smlaicloud/model/warehouse_model.dart';
import 'package:smlaicloud/pdfgen/pdfpreview.dart';
import 'package:smlaicloud/repositories/product_barcode_repository.dart';
import 'package:smlaicloud/screen_search/barcode_search_screen.dart';
import 'package:smlaicloud/screen_search/bookbank_select_screen.dart';

import 'package:smlaicloud/screen_search/customer_search_screen.dart';
import 'package:smlaicloud/screen_search/employee_search_screen.dart';
import 'package:smlaicloud/screen_search/sale_chanels_search_screen.dart';
import 'package:smlaicloud/screen_search/supplier_search_screen.dart';
import 'package:smlaicloud/screen_search/transaction_search_screen.dart';
import 'package:smlaicloud/screen_search/transport_search_screen.dart';

import 'package:smlaicloud/screens/transaction/components/coupon_widget.dart';
import 'package:smlaicloud/screens/transaction/components/document_header_widget.dart';
import 'package:smlaicloud/screens/transaction/components/document_preview_widget.dart';
import 'package:smlaicloud/screens/transaction/components/document_product_list_widget.dart';
import 'package:smlaicloud/utils/cart_websocket_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smlaicloud/utils/date_picker.dart';
import 'package:split_view/split_view.dart';
import 'package:uuid/uuid.dart';
import 'package:smlaicloud/global.dart' as global;
// ignore: library_prefixes
import 'package:smlaicloud/calamount.dart' as calAmount;
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

enum TransactionEditScreenModule { header, detail, footer }

class TransactionEditScreen extends StatefulWidget {
  final global.TransactionTypeEnum type;

  const TransactionEditScreen({super.key, required this.type});

  @override
  State<TransactionEditScreen> createState() => TransactionEditScreenState();
}

class TransactionEditScreenState extends State<TransactionEditScreen> with TickerProviderStateMixin {
  late SplitViewController splitViewController;
  late TabController tabController;
  late TabController editTabController;
  late TransactionModel screenData;
  late TransactionModel screenDataTemp;
  late TransactionEditScreenModule moduleEdit;
  final ProductBarcodeRepository _productBarcodeRepository = ProductBarcodeRepository();
  TextEditingController docNumberController = TextEditingController();
  TextEditingController docDateController = TextEditingController();
  TextEditingController docTimeController = TextEditingController();
  TextEditingController docRefNumberController = TextEditingController();
  TextEditingController docRefDateController = TextEditingController();
  TextEditingController taxDocNoController = TextEditingController();
  TextEditingController taxDocDateController = TextEditingController();
  TextEditingController docRefTypeController = TextEditingController();
  TextEditingController docTypeController = TextEditingController();
  TextEditingController vatTypeController = TextEditingController();
  TextEditingController custCodeController = TextEditingController();
  TextEditingController custnamesController = TextEditingController();
  TextEditingController saleCodeController = TextEditingController();
  TextEditingController saleNameController = TextEditingController();
  TextEditingController discountWordController = TextEditingController();
  TextEditingController totalCostController = TextEditingController();
  TextEditingController totalValueController = TextEditingController();
  TextEditingController totalDiscountController = TextEditingController();
  TextEditingController totalVatValueController = TextEditingController();
  TextEditingController totalAfterVatController = TextEditingController();
  TextEditingController totalExceptVatController = TextEditingController();
  TextEditingController totalAmountController = TextEditingController();
  TextEditingController cashierCodeController = TextEditingController();
  TextEditingController posIdController = TextEditingController();
  TextEditingController memberCodeController = TextEditingController();
  TextEditingController vatRateController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  TextEditingController docDiscountWordController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController detailTotalDiscount = TextEditingController();
  TextEditingController totalDiscountVatAmount = TextEditingController();
  TextEditingController totalDiscountExceptVatAmount = TextEditingController();
  TextEditingController roundAmount = TextEditingController();
  TextEditingController totalAmountAfterDiscount = TextEditingController();
  TextEditingController detailDiscountFormula = TextEditingController();
  TextEditingController detailTotalAmount = TextEditingController();

  TextEditingController payCashAmountController = TextEditingController();
  TextEditingController roundAmountController = TextEditingController();
  TextEditingController detaildiscountformulaController = TextEditingController();
  TextEditingController payDeliveryCashAmountController = TextEditingController();

  TextEditingController transportAmountController = TextEditingController();

  List<TextEditingController> payTransferAmountController = [];
  List<TextEditingController> payCreditCardAmountController = [];
  List<TextEditingController> payChequeAmountController = [];
  List<TextEditingController> payCouponAmountController = [];
  List<TextEditingController> payQrAmountController = [];

  List<TextEditingController> creditCardDateController = [];
  List<TextEditingController> transferDateController = [];
  List<TextEditingController> chequeDateController = [];
  List<TextEditingController> chequeDueDateDateController = [];
  List<TextEditingController> couponDateController = [];
  List<TextEditingController> qrDateController = [];

  late DateTime selectedDate = DateTime.now();
  late List<WarehouseModel> warehouseList = [];
  String defualtwarehouse = "";
  List<LanguageDataModel> defualtwarehousenames = [];
  String defualtlocation = "";
  List<LanguageDataModel> defualtlocationnames = [];
  String defualttowarehouse = "";
  List<LanguageDataModel> defualttowarehousenames = [];
  String defualttolocation = "";
  List<LanguageDataModel> defualttolocationnames = [];
  List<Widget> tab = [];
  List<Widget> childrens = [];
  List<String> groupedItems = [];
  int transflag = 0;
  int calcflag = 0;
  bool docDateTimeValidated = false;
  late String fieldNameCustCode;
  late String fieldNamecustnames;
  final _debouncer = global.Debouncer(1000);
  int showPayDetail = 0;
  String docnoFormat = "";
  bool isMember = false;
  int configvattype = 0;
  int configinquirytype = 0;
  double payTotalBill = 0;
  String enumtype = '';
  bool _isLoading = false;
  String _loadingMessage = 'กำลังประมวลผล...';

  //  pricelevel ของลูกค้า
  int customerPriceLevel = 1; // ค่าเริ่มต้นเป็น 1

  final CartWebSocketService _cartService = CartWebSocketService();
  String? clientId;

  List<global.DataTableHeader> headers = [
    global.DataTableHeader(code: "delete", label: "", width: 5, textAlign: TextAlign.center, alignment: Alignment.center),
    global.DataTableHeader(code: "line_number", label: global.language('line_number'), width: 10, textAlign: TextAlign.center, alignment: Alignment.center),
    global.DataTableHeader(code: "barcode", label: global.language('barcode'), width: 20),
    global.DataTableHeader(code: "product_name", label: global.language('product_name'), width: 40),
    global.DataTableHeader(code: "product_ware_house", label: global.language('product_ware_house'), width: 15),
    global.DataTableHeader(code: "product_location", label: global.language('product_location'), width: 10),
    global.DataTableHeader(code: "product_unit", label: global.language('product_unit'), width: 10),
    global.DataTableHeader(code: "product_qty", label: global.language('product_qty'), width: 10, alignment: Alignment.centerRight, textAlign: TextAlign.right),
    global.DataTableHeader(code: "product_price", label: global.language('product_price'), alignment: Alignment.centerRight, width: 20, textAlign: TextAlign.right),
    global.DataTableHeader(
      code: "product_discount",
      label: global.language('product_discount'),
      width: 10,
      alignment: Alignment.centerRight,
      textAlign: TextAlign.right,
    ),
    global.DataTableHeader(code: "product_amount", label: global.language('product_amount'), alignment: Alignment.centerRight, width: 30, textAlign: TextAlign.right),
  ];

  List<BillPayObjectBoxStruct> payTransfer = [];
  List<BillPayObjectBoxStruct> payCreditCard = [];
  List<BillPayObjectBoxStruct> payCheque = [];
  List<BillPayObjectBoxStruct> payCoupon = [];
  List<BillPayObjectBoxStruct> payQr = [];

  /// model ใหม่จาก pos
  List<CouponModel>? couPons = [];

  List<dynamic> docrefs = [];
  List<String> cartList = [];

  void setSystemLanguageList() async {
    clearScreenData();
    await global.setSystemLanguage(context);

    headerTableDetail();
  }

  @override
  void initState() {
    super.initState();
    // ตั้งค่า callbacks สำหรับ CartWebSocketService
    _cartService.initialize(onClientIdReceived: (receivedClientId) {
      if (mounted) {
        setState(() {
          clientId = receivedClientId;
        });
      }
    }, onCartDeleted: (success, message) {
      if (kDebugMode) {
        print('ผลการลบตะกร้า: ${success ? "สำเร็จ" : "ไม่สำเร็จ"} - $message');
      }
    }
        // callback อื่นๆ สามารถเพิ่มตามต้องการ
        );

    // เชื่อมต่อกับ WebSocket
    _cartService.connect(context);

    global.getDeviceModel(context);
    switch (widget.type) {
      case global.TransactionTypeEnum.purchase:
        fieldNameCustCode = "doc_supplier_code";
        fieldNamecustnames = "doc_supplier_name";

        break;
      case global.TransactionTypeEnum.purchaseorder:
        fieldNameCustCode = "doc_supplier_code";
        fieldNamecustnames = "doc_supplier_name";
        break;

      case global.TransactionTypeEnum.purchasepartial:
        fieldNameCustCode = "doc_supplier_code";
        fieldNamecustnames = "doc_supplier_name";

        break;
      case global.TransactionTypeEnum.purchasereturn:
        fieldNameCustCode = "doc_supplier_code";
        fieldNamecustnames = "doc_supplier_name";

        break;
      case global.TransactionTypeEnum.accrualreceive:
        fieldNameCustCode = "doc_supplier_code";
        fieldNamecustnames = "doc_supplier_name";

        break;
      case global.TransactionTypeEnum.sale:
        fieldNameCustCode = "doc_customer_code";
        fieldNamecustnames = "doc_customer_name";

        break;
      case global.TransactionTypeEnum.saleorder:
        fieldNameCustCode = "doc_customer_code";
        fieldNamecustnames = "doc_customer_name";

        break;
      case global.TransactionTypeEnum.salereturn:
        fieldNameCustCode = "doc_customer_code";
        fieldNamecustnames = "doc_customer_name";

        break;

      default:
        fieldNameCustCode = "";
        fieldNamecustnames = "";
        break;
    }

    setSystemLanguageList();
    splitViewController = SplitViewController(limits: [null, WeightLimit(min: 0.1, max: 0.9)]);
    splitViewController.weights = [0.30, 0.70];
    tabController = TabController(length: 2, vsync: this);

    if (widget.type != global.TransactionTypeEnum.stocktransfer &&
        widget.type != global.TransactionTypeEnum.stockreceiveproduct &&
        widget.type != global.TransactionTypeEnum.stockpickupproduct &&
        widget.type != global.TransactionTypeEnum.stockreturnproduct &&
        widget.type != global.TransactionTypeEnum.adjust &&
        widget.type != global.TransactionTypeEnum.saleorder &&
        widget.type != global.TransactionTypeEnum.purchaseorder &&
        widget.type != global.TransactionTypeEnum.quotation &&
        widget.type != global.TransactionTypeEnum.purchasepartial) {
      editTabController = TabController(length: 3, vsync: this);
    } else {
      editTabController = TabController(length: 2, vsync: this);
    }

    context.read<WarehouseBloc>().add(const WarehouseLoadList(offset: 0, limit: 100, search: ''));
  }

  @override
  void dispose() {
    _cartService.disconnect();
    splitViewController.dispose();
    tabController.dispose();
    editTabController.dispose();
    docNumberController.dispose();
    docDateController.dispose();
    docTimeController.dispose();
    docRefNumberController.dispose();
    docRefDateController.dispose();
    docRefTypeController.dispose();
    docTypeController.dispose();
    vatTypeController.dispose();
    custCodeController.dispose();
    custnamesController.dispose();
    saleCodeController.dispose();
    saleNameController.dispose();
    docDiscountWordController.dispose();
    totalCostController.dispose();
    totalValueController.dispose();
    totalDiscountController.dispose();
    totalVatValueController.dispose();
    totalAfterVatController.dispose();
    totalExceptVatController.dispose();
    totalAmountController.dispose();
    cashierCodeController.dispose();
    posIdController.dispose();
    memberCodeController.dispose();
    vatRateController.dispose();
    statusController.dispose();
    descriptionController.dispose();
    payCashAmountController.dispose();
    payDeliveryCashAmountController.dispose();
    roundAmountController.dispose();
    detaildiscountformulaController.dispose();
    detailTotalDiscount.dispose();
    totalDiscountVatAmount.dispose();
    totalDiscountExceptVatAmount.dispose();
    roundAmount.dispose();
    totalAmountAfterDiscount.dispose();
    detailDiscountFormula.dispose();
    detailTotalAmount.dispose();

    for (var element in payTransferAmountController) {
      element.dispose();
    }

    for (var element in payCreditCardAmountController) {
      element.dispose();
    }

    for (var element in payChequeAmountController) {
      element.dispose();
    }

    for (var element in payCouponAmountController) {
      element.dispose();
    }

    for (var element in payQrAmountController) {
      element.dispose();
    }

    for (var element in creditCardDateController) {
      element.dispose();
    }

    for (var element in transferDateController) {
      element.dispose();
    }

    for (var element in chequeDateController) {
      element.dispose();
    }

    for (var element in chequeDueDateDateController) {
      element.dispose();
    }

    for (var element in couponDateController) {
      element.dispose();
    }

    for (var element in qrDateController) {
      element.dispose();
    }

    super.dispose();
  }

  void headerTableDetail() {
    if (widget.type == global.TransactionTypeEnum.stocktransfer) {
      headers = [
        global.DataTableHeader(code: "delete", label: "", width: 5, textAlign: TextAlign.center, alignment: Alignment.center),
        global.DataTableHeader(code: "line_number", label: global.language('line_number'), width: 10, textAlign: TextAlign.center, alignment: Alignment.center),
        global.DataTableHeader(code: "barcode", label: global.language('barcode'), width: 20),
        global.DataTableHeader(code: "item_code", label: global.language('item_code'), width: 15), // เพิ่มคอลัมน์ itemcode
        global.DataTableHeader(code: "product_name", label: global.language('product_name'), width: 40),
        global.DataTableHeader(code: "product_unit", label: global.language('product_unit'), width: 10),
      ];

      headers.add(global.DataTableHeader(code: "product_ware_house", label: global.language('product_ware_house'), width: 10));
      headers.add(global.DataTableHeader(code: "product_location", label: global.language('product_location'), width: 10));
      headers.add(global.DataTableHeader(code: "product_to_ware_house", label: global.language('product_to_ware_house'), width: 10));
      headers.add(global.DataTableHeader(code: "product_to_location", label: global.language('product_to_location'), width: 10));

      headers.addAll([global.DataTableHeader(code: "product_qty", label: global.language('product_qty'), width: 10, alignment: Alignment.centerRight, textAlign: TextAlign.right)]);
    } else if (widget.type == global.TransactionTypeEnum.stockreceiveproduct) {
      headers = [
        global.DataTableHeader(code: "delete", label: "", width: 5, textAlign: TextAlign.center, alignment: Alignment.center),
        global.DataTableHeader(code: "line_number", label: global.language('line_number'), width: 10, textAlign: TextAlign.center, alignment: Alignment.center),
        global.DataTableHeader(code: "barcode", label: global.language('barcode'), width: 20),
        global.DataTableHeader(code: "item_code", label: global.language('item_code'), width: 15), // เพิ่มคอลัมน์ itemcode
        global.DataTableHeader(code: "product_name", label: global.language('product_name'), width: 40),
        global.DataTableHeader(code: "product_unit", label: global.language('product_unit'), width: 10),
      ];

      headers.add(global.DataTableHeader(code: "product_ware_house", label: global.language('product_ware_house'), width: 10));
      headers.add(global.DataTableHeader(code: "product_location", label: global.language('product_location'), width: 10));
      headers.addAll([
        global.DataTableHeader(code: "product_qty", label: global.language('product_qty'), width: 10, alignment: Alignment.centerRight, textAlign: TextAlign.right),
        global.DataTableHeader(code: "product_price", label: global.language('product_cost'), width: 10, alignment: Alignment.centerRight, textAlign: TextAlign.right),
        global.DataTableHeader(code: "product_amount", label: global.language('product_amount'), alignment: Alignment.centerRight, width: 30, textAlign: TextAlign.right),
      ]);
    } else if (widget.type == global.TransactionTypeEnum.stockpickupproduct ||
        widget.type == global.TransactionTypeEnum.stockreturnproduct ||
        widget.type == global.TransactionTypeEnum.adjust) {
      headers = [
        global.DataTableHeader(code: "delete", label: "", width: 5, textAlign: TextAlign.center, alignment: Alignment.center),
        global.DataTableHeader(code: "line_number", label: global.language('line_number'), width: 10, textAlign: TextAlign.center, alignment: Alignment.center),
        global.DataTableHeader(code: "barcode", label: global.language('barcode'), width: 20),
        global.DataTableHeader(code: "item_code", label: global.language('item_code'), width: 15), // เพิ่มคอลัมน์ itemcode
        global.DataTableHeader(code: "product_name", label: global.language('product_name'), width: 40),
        global.DataTableHeader(code: "product_unit", label: global.language('product_unit'), width: 10),
      ];

      headers.add(global.DataTableHeader(code: "product_ware_house", label: global.language('product_ware_house'), width: 10));
      headers.add(global.DataTableHeader(code: "product_location", label: global.language('product_location'), width: 10));
      headers.add(global.DataTableHeader(
          code: _getColumnCodeByTransFlag(screenData.transflag),
          label: global.language(_getColumnCodeByTransFlag(screenData.transflag)),
          width: 10,
          alignment: Alignment.centerRight,
          textAlign: TextAlign.right));
    } else {
      headers = [
        global.DataTableHeader(code: "delete", label: "", width: 5, textAlign: TextAlign.center, alignment: Alignment.center),
        global.DataTableHeader(code: "line_number", label: global.language('line_number'), width: 10, textAlign: TextAlign.center, alignment: Alignment.center),
        global.DataTableHeader(code: "barcode", label: global.language('barcode'), width: 20),
        global.DataTableHeader(code: "item_code", label: global.language('item_code'), width: 15), // เพิ่มคอลัมน์ itemcode
        global.DataTableHeader(code: "product_name", label: global.language('product_name'), width: 40),
      ];

      headers.add(global.DataTableHeader(code: "product_ware_house", label: global.language('product_ware_house'), width: 10));
      headers.add(global.DataTableHeader(code: "product_location", label: global.language('product_location'), width: 10));
      headers.addAll([
        global.DataTableHeader(code: "product_unit", label: global.language('product_unit'), width: 10),
        global.DataTableHeader(code: "product_qty", label: global.language('product_qty'), width: 10, alignment: Alignment.centerRight, textAlign: TextAlign.right),
        global.DataTableHeader(code: "product_price", label: global.language('product_price'), alignment: Alignment.centerRight, width: 15, textAlign: TextAlign.right),
        global.DataTableHeader(code: "product_discount", label: global.language('product_discount'), width: 15, alignment: Alignment.centerRight, textAlign: TextAlign.right),
        global.DataTableHeader(code: "product_amount", label: global.language('product_amount'), alignment: Alignment.centerRight, width: 15, textAlign: TextAlign.right)
      ]);
    }
  }

  String _getColumnCodeByTransFlag(int transflag) {
    /// 66 = ปรับปรุง stock เพิ่ม
    /// 68 = ปรับปรุง stock ลด
    /// 866 = ปรับปรุงมูลค่าเพิ่ม
    /// 868 = ปรับปรุงมูลค่าลด
    /// 966 = ปรับปรุงต้นทุน
    if (transflag == 66 || transflag == 68) {
      return "product_qty";
    } else if (transflag == 866 || transflag == 868) {
      return "product_amount";
    } else if (transflag == 966) {
      return "product_price_adjust";
    } else {
      return "product_qty"; // default
    }
  }

  void loadDataToScreen() {
    headerTableDetail();
    DateTime docDateTimeFormat = DateTime.parse(screenData.docdatetime);
    DateTime docRefDateTimeFormat = DateTime.parse(screenData.docrefdate);
    DateTime taxDocDateTimeFormat = DateTime.parse(screenData.taxdocdate);

    docNumberController.text = screenData.docno;
    docDateController.text = DateFormat('dd/MM/yyyy').format(docDateTimeFormat.toLocal());
    docTimeController.text = DateFormat('HH:mm').format(docDateTimeFormat.toLocal());
    docRefNumberController.text = screenData.docrefno;
    docRefDateController.text = DateFormat('dd/MM/yyyy').format(docRefDateTimeFormat.toLocal());
    taxDocDateController.text = DateFormat('dd/MM/yyyy').format(taxDocDateTimeFormat.toLocal());
    taxDocNoController.text = screenData.taxdocno;
    docRefTypeController.text = screenData.docreftype.toString();
    docTypeController.text = screenData.doctype.toString();
    vatTypeController.text = screenData.vattype.toString();

    /// แก้ไขปัญหา ข้อมูลเดิม ประเภทภาษีผิด ต้องเป็น 3
    if (widget.type == global.TransactionTypeEnum.stockpickupproduct) {
      screenData.vattype = 3;
      vatTypeController.text = "3";
    } else if (widget.type == global.TransactionTypeEnum.stockreceiveproduct) {
      screenData.vattype = 3;
      vatTypeController.text = "3";
    } else if (widget.type == global.TransactionTypeEnum.stockreturnproduct) {
      screenData.vattype = 3;
      vatTypeController.text = "3";
    } else if (widget.type == global.TransactionTypeEnum.stocktransfer) {
      screenData.vattype = 3;
      vatTypeController.text = "3";
    } else if (widget.type == global.TransactionTypeEnum.adjust) {
      screenData.vattype = 3;
      vatTypeController.text = "3";
    }
    custCodeController.text = screenData.custcode;
    custnamesController.text = global.activeLangName(screenData.custnames ?? []);
    saleCodeController.text = screenData.salecode;
    saleNameController.text = screenData.salename;
    docDiscountWordController.text = screenData.discountword;
    totalCostController.text = screenData.totalcost.toString();
    totalValueController.text = screenData.totalvalue.toString();
    totalDiscountController.text = screenData.totaldiscount.toString();
    totalVatValueController.text = screenData.totalvatvalue.toString();
    totalAfterVatController.text = screenData.totalaftervat.toString();
    totalExceptVatController.text = screenData.totalexceptvat.toString();
    totalAmountController.text = screenData.totalamount.toString();

    totalDiscountVatAmount.text = screenData.totaldiscountvatamount.toString();
    totalDiscountExceptVatAmount.text = screenData.totaldiscountexceptvatamount.toString();
    totalAmountAfterDiscount.text = screenData.totalamountafterdiscount.toString();
    detailDiscountFormula.text = screenData.detaildiscountformula.toString();
    detailTotalAmount.text = screenData.detailtotalamount.toString();

    cashierCodeController.text = screenData.cashiercode;
    posIdController.text = screenData.posid;
    memberCodeController.text = screenData.membercode;
    vatRateController.text = screenData.vatrate.toString();
    statusController.text = screenData.status.toString();
    descriptionController.text = screenData.description.toString();

    transportAmountController.text = NumberFormat('#,##0.00', 'en_US').format(screenData.transportamount);

    if (global.profileData.yeartype == "buddhist") {
      docDateController.text = global.dateTimeBuddhist(docDateTimeFormat, format: global.DateTimeFormatEnum.dateDay);
      docRefDateController.text = global.dateTimeBuddhist(docRefDateTimeFormat, format: global.DateTimeFormatEnum.dateDay);
      taxDocDateController.text = global.dateTimeBuddhist(taxDocDateTimeFormat, format: global.DateTimeFormatEnum.dateDay);
    } else {
      docDateController.text = DateFormat('dd/MM/yyyy').format(docDateTimeFormat);
      docRefDateController.text = DateFormat('dd/MM/yyyy').format(docRefDateTimeFormat);
      taxDocDateController.text = DateFormat('dd/MM/yyyy').format(taxDocDateTimeFormat);
    }

    double totalPayCreditCard = 0;
    double totalPayTranfer = 0;
    double totalPayCheque = 0;
    double totalPayCoupon = 0;
    double totalPayQr = 0;

    payTransfer = [];
    payCreditCard = [];
    payCheque = [];
    payCoupon = [];
    payQr = [];

    /// model ใหม่จาก pos
    couPons = [];

    creditCardDateController = [];
    transferDateController = [];
    chequeDateController = [];
    chequeDueDateDateController = [];
    couponDateController = [];
    qrDateController = [];

    payTransferAmountController = [];
    payCreditCardAmountController = [];
    payChequeAmountController = [];
    payCouponAmountController = [];
    payQrAmountController = [];

    couPons = screenData.coupons ?? [];

    for (int i = 0; i < screenData.billpayobjectboxstruct!.length; i++) {
      /// บัตรเครดิต
      if (screenData.billpayobjectboxstruct![i].trans_flag == 1) {
        payCreditCard.add(screenData.billpayobjectboxstruct![i]);
        totalPayCreditCard += screenData.billpayobjectboxstruct![i].amount!;
        creditCardDateController.add(TextEditingController());
        payCreditCardAmountController.add(TextEditingController());

        for (int f = 0; f < creditCardDateController.length; f++) {
          if (global.profileData.yeartype == "buddhist") {
            creditCardDateController[f].text = global.dateTimeBuddhist(screenData.billpayobjectboxstruct![i].doc_date_time!, format: global.DateTimeFormatEnum.dateDay);
          } else {
            creditCardDateController[f].text = DateFormat('dd/MM/yyyy').format(screenData.billpayobjectboxstruct![i].doc_date_time!);
          }
          payCreditCardAmountController[f].text = screenData.billpayobjectboxstruct![i].amount.toString();
        }
      }

      /// เงินโอน
      if (screenData.billpayobjectboxstruct![i].trans_flag == 2) {
        payTransfer.add(screenData.billpayobjectboxstruct![i]);
        totalPayTranfer += screenData.billpayobjectboxstruct![i].amount!;
        transferDateController.add(TextEditingController());
        payTransferAmountController.add(TextEditingController());

        for (int f = 0; f < transferDateController.length; f++) {
          if (global.profileData.yeartype == "buddhist") {
            transferDateController[f].text = global.dateTimeBuddhist(screenData.billpayobjectboxstruct![i].doc_date_time!, format: global.DateTimeFormatEnum.dateDay);
          } else {
            transferDateController[f].text = DateFormat('dd/MM/yyyy').format(screenData.billpayobjectboxstruct![i].doc_date_time!);
          }
          payTransferAmountController[f].text = screenData.billpayobjectboxstruct![i].amount.toString();
        }
      }

      /// เช็ค
      if (screenData.billpayobjectboxstruct![i].trans_flag == 3) {
        payCheque.add(screenData.billpayobjectboxstruct![i]);
        totalPayCheque += screenData.billpayobjectboxstruct![i].amount!;
        chequeDateController.add(TextEditingController());
        chequeDueDateDateController.add(TextEditingController());
        payChequeAmountController.add(TextEditingController());

        for (int f = 0; f < transferDateController.length; f++) {
          if (global.profileData.yeartype == "buddhist") {
            chequeDateController[f].text = global.dateTimeBuddhist(screenData.billpayobjectboxstruct![i].doc_date_time!, format: global.DateTimeFormatEnum.dateDay);
            chequeDueDateDateController[f].text = global.dateTimeBuddhist(screenData.billpayobjectboxstruct![i].due_date!, format: global.DateTimeFormatEnum.dateDay);
          } else {
            chequeDateController[f].text = DateFormat('dd/MM/yyyy').format(screenData.billpayobjectboxstruct![i].doc_date_time!);
            chequeDueDateDateController[f].text = DateFormat('dd/MM/yyyy').format(screenData.billpayobjectboxstruct![i].due_date!);
          }
          payChequeAmountController[f].text = screenData.billpayobjectboxstruct![i].amount.toString();
        }
      }

      /// คูปอง
      if (screenData.billpayobjectboxstruct![i].trans_flag == 4) {
        payCoupon.add(screenData.billpayobjectboxstruct![i]);
        totalPayCoupon += screenData.billpayobjectboxstruct![i].amount!;
        couponDateController.add(TextEditingController());
        payCouponAmountController.add(TextEditingController());

        for (int f = 0; f < couponDateController.length; f++) {
          if (global.profileData.yeartype == "buddhist") {
            couponDateController[f].text = global.dateTimeBuddhist(screenData.billpayobjectboxstruct![i].doc_date_time!, format: global.DateTimeFormatEnum.dateDay);
          } else {
            couponDateController[f].text = DateFormat('dd/MM/yyyy').format(screenData.billpayobjectboxstruct![i].doc_date_time!);
          }
          payCouponAmountController[f].text = screenData.billpayobjectboxstruct![i].amount.toString();
        }
      }

      /// QR
      if (screenData.billpayobjectboxstruct![i].trans_flag == 5) {
        payQr.add(screenData.billpayobjectboxstruct![i]);
        totalPayQr += screenData.billpayobjectboxstruct![i].amount!;
        qrDateController.add(TextEditingController());
        payQrAmountController.add(TextEditingController());

        for (int f = 0; f < qrDateController.length; f++) {
          if (global.profileData.yeartype == "buddhist") {
            qrDateController[f].text = global.dateTimeBuddhist(screenData.billpayobjectboxstruct![i].doc_date_time!, format: global.DateTimeFormatEnum.dateDay);
          } else {
            qrDateController[f].text = DateFormat('dd/MM/yyyy').format(screenData.billpayobjectboxstruct![i].doc_date_time!);
          }
          payQrAmountController[f].text = screenData.billpayobjectboxstruct![i].amount.toString();
        }
      }
    }

    screenData.sumcreditcard = totalPayCreditCard;
    screenData.summoneytransfer = totalPayTranfer;
    screenData.sumcheque = totalPayCheque;
    screenData.sumcoupon = totalPayCoupon;
    screenData.sumqrcode = totalPayQr;
    // payCashAmountController.text = (screenData.paycashamount! - screenData.paycashchange!).toString();
    payCashAmountController.text = NumberFormat('#,##0.00', 'en_US').format((screenData.paycashamount!));
    payDeliveryCashAmountController.text = NumberFormat('#,##0.00', 'en_US').format(screenData.deliveryamount);
    roundAmountController.text = (screenData.roundamount != 0) ? (screenData.roundamount!).toString() : "0";
    detaildiscountformulaController.text = (screenData.detaildiscountformula!.isNotEmpty) ? screenData.detaildiscountformula.toString() : "0";
    discountWordController.text = (screenData.discountword.isNotEmpty) ? screenData.discountword.toString() : "0";
    _calPayTotal();
  }

  void clearScreenData() {
    if (widget.type == global.TransactionTypeEnum.purchase) {
      transflag = 12;
      calcflag = 1;
      docnoFormat = "PU";
      configvattype = global.config.vattypepurchase;
      configinquirytype = global.config.inquirytypepurchase;
    } else if (widget.type == global.TransactionTypeEnum.purchasereturn) {
      transflag = 16;
      calcflag = -1;
      docnoFormat = "PT";
      configvattype = global.config.vattypepurchase;
    } else if (widget.type == global.TransactionTypeEnum.sale) {
      transflag = 44;
      calcflag = -1;
      docnoFormat = "SI";
      configvattype = global.config.vattypesale;
      configinquirytype = global.config.inquirytypesale;
    } else if (widget.type == global.TransactionTypeEnum.salereturn) {
      transflag = 48;
      calcflag = 1;
      docnoFormat = "ST";
      configvattype = global.config.vattypesale;
    } else if (widget.type == global.TransactionTypeEnum.stockpickupproduct) {
      transflag = 56;
      calcflag = -1;
      docnoFormat = "IO";
      configvattype = 3;
    } else if (widget.type == global.TransactionTypeEnum.stockreceiveproduct) {
      transflag = 60;
      calcflag = 1;
      docnoFormat = "IF";
      configvattype = 3;
    } else if (widget.type == global.TransactionTypeEnum.stockreturnproduct) {
      transflag = 58;
      calcflag = 1;
      docnoFormat = "IR";
      configvattype = 3;
    } else if (widget.type == global.TransactionTypeEnum.stocktransfer) {
      transflag = 72;
      calcflag = -1;
      docnoFormat = "IF";
      configvattype = 3;
    } else if (widget.type == global.TransactionTypeEnum.adjust) {
      transflag = 66;
      calcflag = 1;
      docnoFormat = "AJ";
      configvattype = 3;
    } else if (widget.type == global.TransactionTypeEnum.quotation) {
      transflag = 30;
      calcflag = -1;
      docnoFormat = "QT";
      configvattype = global.config.vattypesale;
    } else if (widget.type == global.TransactionTypeEnum.purchaseorder) {
      transflag = 6;
      calcflag = 1;
      docnoFormat = "PO";
      configvattype = global.config.vattypepurchase;
      configinquirytype = global.config.inquirytypepurchase;
    } else if (widget.type == global.TransactionTypeEnum.saleorder) {
      transflag = 36;
      calcflag = -1;
      docnoFormat = "SO";
      configvattype = global.config.vattypesale;
      configinquirytype = global.config.inquirytypesale;
    } else if (widget.type == global.TransactionTypeEnum.purchasepartial) {
      transflag = 310;
      calcflag = 1;
      docnoFormat = "PI";
      configvattype = global.config.vattypesale;
      configinquirytype = global.config.inquirytypesale;
    } else if (widget.type == global.TransactionTypeEnum.accrualreceive) {
      transflag = 315;
      calcflag = 1;
      docnoFormat = "PIU";
      configvattype = global.config.vattypepurchase;
    }

    const uuid = Uuid();
    moduleEdit = TransactionEditScreenModule.header;
    screenData = TransactionModel(
      shopid: global.apiShopCode,
      guidref: uuid.v4(),
      docno: global.randomDocNo(docnoFormat, DateTime.now()),
      description: '',
      docdatetime: DateTime.now().toLocal().toIso8601String(),
      docrefno: '',
      docrefdate: DateTime.now().toLocal().toIso8601String(),
      docreftype: 0,
      doctype: 0,
      vattype: configvattype,
      custcode: '',
      custnames: [],
      salecode: '',
      salename: '',
      discountword: '0',
      totalcost: 0,
      totalvalue: 0,
      totaldiscount: 0,
      totalvatvalue: 0,
      totalaftervat: 0,
      totalexceptvat: 0,
      totalamount: 0,
      cashiercode: '',
      posid: '',
      membercode: '',
      vatrate: global.config.vatrate,
      status: 0,
      inquirytype: configinquirytype,
      taxdocdate: DateTime.now().toLocal().toIso8601String(),
      taxdocno: '',
      totalbeforevat: 0,
      transflag: transflag,
      details: <TransactionDetailModel>[],
      iscancel: false,
      ismanualamount: false,
      paymentdetailraw: "",
      billpayobjectboxstruct: [],
      sumcreditcard: 0,
      summoneytransfer: 0,
      sumcheque: 0,
      sumcoupon: 0,
      sumqrcode: 0,
      paycashamount: 0,
      paycashchange: 0,
      roundamount: 0,
      detaildiscountformula: '0',
      totaldiscountvatamount: 0,
      totaldiscountexceptvatamount: 0,
      totalamountafterdiscount: 0,
      detailtotalamount: 0,
      branch: BranchModel(
        guidfixed: global.companyBranchSelectData.guidfixed,
        code: global.companyBranchSelectData.code,
        names: global.companyBranchSelectData.names,
      ),
      reftotaloriginal: 0,
      reftotalcorrect: 0,
      reftotaldiff: 0,
      isdelivery: false,
      deliveryamount: 0,
      istransport: false,
      transportcode: '',
      transportamount: 0,
    );

    payTransfer = [];
    payCreditCard = [];
    payCheque = [];
    payCoupon = [];
    payQr = [];
    couPons = [];

    creditCardDateController = [];
    transferDateController = [];
    chequeDateController = [];
    chequeDueDateDateController = [];
    couponDateController = [];
    qrDateController = [];

    payTransferAmountController = [];
    payCreditCardAmountController = [];
    payChequeAmountController = [];
    payCouponAmountController = [];
    payQrAmountController = [];

    // รีเซ็ต customerPriceLevel เป็นค่าเริ่มต้น
    customerPriceLevel = 1;

    setState(() {
      loadDataToScreen();
      docDateTimeValidated = true;
    });
  }

  Future<BookBankModel?> bookBankSearch() async {
    Completer<BookBankModel?> completer = Completer<BookBankModel?>();

    Navigator.push(context, MaterialPageRoute(builder: (context) => const BookBankSelectScreen())).then((value) {
      completer.complete(value);
    });

    return completer.future;
  }

  // void _calTotalCharge(int index) {
  //   if (screenData.paymentdetail!.paymentcreditcards![index].chargeword != '') {
  //     if (screenData.paymentdetail!.paymentcreditcards![index].chargeword!.contains('%')) {
  //       double chargeValue = screenData.paymentdetail!.paymentcreditcards![index].amount! *
  //           (double.parse(screenData.paymentdetail!.paymentcreditcards![index].chargeword!.replaceAll('%', '')) / 100);
  //       screenData.paymentdetail!.paymentcreditcards![index].chargevalue = chargeValue;
  //       screenData.paymentdetail!.paymentcreditcards![index].totalnetworth = screenData.paymentdetail!.paymentcreditcards![index].amount! + chargeValue;
  //     } else {
  //       screenData.paymentdetail!.paymentcreditcards![index].chargevalue = double.parse(screenData.paymentdetail!.paymentcreditcards![index].chargeword!);
  //       screenData.paymentdetail!.paymentcreditcards![index].totalnetworth =
  //           screenData.paymentdetail!.paymentcreditcards![index].amount! + double.parse(screenData.paymentdetail!.paymentcreditcards![index].chargeword!);
  //     }
  //   } else {
  //     screenData.paymentdetail!.paymentcreditcards![index].chargeword = '0';
  //     screenData.paymentdetail!.paymentcreditcards![index].chargevalue = 0;
  //     screenData.paymentdetail!.paymentcreditcards![index].totalnetworth = screenData.paymentdetail!.paymentcreditcards![index].amount!;
  //   }
  //   setState(() {});
  // }

  Widget docPreview() {
    return DocumentPreviewWidget(
      screenData: screenData,
      transactionType: widget.type,
      docDateTimeValidated: docDateTimeValidated,
      fieldNameCustCode: fieldNameCustCode,
      fieldNamecustnames: fieldNamecustnames,
    );
  }

  double _getPrice(List<PriceDataModel>? result) {
    double price = 0;

    if (widget.type == global.TransactionTypeEnum.purchaseorder ||
        widget.type == global.TransactionTypeEnum.purchasepartial ||
        widget.type == global.TransactionTypeEnum.purchasereturn ||
        widget.type == global.TransactionTypeEnum.stockreceiveproduct ||
        widget.type == global.TransactionTypeEnum.purchase ||
        widget.type == global.TransactionTypeEnum.accrualreceive) {
      price = 0;
    } else if (widget.type == global.TransactionTypeEnum.sale) {
      if (result != null && result.isNotEmpty) {
        // หาราคาตาม pricelevel ของลูกค้า - ใช้ keynumber แทน priceNumber
        PriceDataModel? targetPrice = result.where((p) => p.keynumber == customerPriceLevel).firstOrNull;

        if (targetPrice != null) {
          price = targetPrice.price;
        }

        // ถ้าราคาเป็น 0 หรือไม่มีราคาตาม pricelevel ให้ใช้ keynumber = 1
        if (price == 0) {
          PriceDataModel? defaultPrice = result.where((p) => p.keynumber == 1).firstOrNull;
          price = defaultPrice?.price ?? 0;
        }
      }
    } else if (widget.type == global.TransactionTypeEnum.saleorder) {
      if (result != null && result.isNotEmpty) {
        // หาราคาตาม pricelevel ของลูกค้า - ใช้ keynumber แทน priceNumber
        PriceDataModel? targetPrice = result.where((p) => p.keynumber == customerPriceLevel).firstOrNull;

        if (targetPrice != null) {
          price = targetPrice.price;
        }

        // ถ้าราคาเป็น 0 หรือไม่มีราคาตาม pricelevel ให้ใช้ keynumber = 1
        if (price == 0) {
          PriceDataModel? defaultPrice = result.where((p) => p.keynumber == 1).firstOrNull;
          price = defaultPrice?.price ?? 0;
        }
      }
    } else {
      if (result!.isNotEmpty) {
        // หาราคาตาม pricelevel ของลูกค้า - ใช้ keynumber แทน priceNumber
        PriceDataModel? targetPrice = result.where((p) => p.keynumber == customerPriceLevel).firstOrNull;

        if (targetPrice != null) {
          price = targetPrice.price;
        }

        // ถ้าราคาเป็น 0 หรือไม่มีราคาตาม pricelevel ให้ใช้ keynumber = 1
        if (price == 0) {
          PriceDataModel? defaultPrice = result.where((p) => p.keynumber == 1).firstOrNull;
          price = defaultPrice?.price ?? 0;
        }
      } else {
        price = 0;
      }
    }

    return price;
  }

  Widget previewWidget() {
    return Container(
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.all(10),
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: docPreview());
  }

  Widget editProductListReceiveDetailMobileWidget() {
    List<Widget> widgets = [];
    widgets.add(const SizedBox(
      height: 10,
    ));

    List<Widget> dataWidgets = [];
    for (var index = 0; index < screenData.details!.length; index++) {
      dataWidgets.add(Card(
        color: Colors.blue.shade100,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('barcode', index, screenData.details![index]);
                            },
                            child: Text(
                              '${screenData.details![index].barcode}~${global.activeLangName(screenData.details![index].itemnames!)}',
                              style: const TextStyle(fontSize: 12),
                            )),
                        IconButton(
                          onPressed: () {
                            deleteItemDetail(index);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        )
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(global.language("product_unit")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_unit', index, screenData.details![index]);
                            },
                            child: Text(
                              global.activeLangName(screenData.details![index].unitnames!),
                              style: const TextStyle(fontSize: 12),
                            )),
                        const SizedBox(width: 5),
                        Text(global.language("warehouse")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_ware_house', index, screenData.details![index]);
                            },
                            child: Text(
                              global.activeLangName(screenData.details![index].whnames!),
                              style: const TextStyle(fontSize: 12),
                            )),
                        const SizedBox(width: 5),
                        Text(global.language("location")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_location', index, screenData.details![index]);
                            },
                            child: Text(
                              global.activeLangName(screenData.details![index].locationnames!),
                              style: const TextStyle(fontSize: 12),
                            )),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(global.language("product_qty")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_qty', index, screenData.details![index]);
                            },
                            child: Text(
                              global.formatNumber(screenData.details![index].qty),
                              style: const TextStyle(fontSize: 12),
                            )),
                        const SizedBox(width: 5),
                        Text(global.language("product_cost")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              if (screenData.transflag == 966) {
                                showDialogCommand('product_price_adjust', index, screenData.details![index]);
                              } else {
                                showDialogCommand('product_price', index, screenData.details![index]);
                              }
                            },
                            child: Text(
                              global.formatNumber(screenData.details![index].price),
                              style: const TextStyle(fontSize: 12),
                            )),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${global.language("total_value")}: ${global.formatNumber(screenData.details![index].sumamount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ));
    }

    widgets.add(const SizedBox(
      height: 4,
    ));

    return Column(
      children: dataWidgets,
    );
  }

  Widget editProductListPickUpDetailMobileWidget() {
    List<Widget> widgets = [];
    widgets.add(const SizedBox(
      height: 10,
    ));

    List<Widget> dataWidgets = [];
    for (var index = 0; index < screenData.details!.length; index++) {
      dataWidgets.add(Card(
        color: Colors.blue.shade100,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('barcode', index, screenData.details![index]);
                            },
                            child: Text(
                              '${screenData.details![index].barcode}~${global.activeLangName(screenData.details![index].itemnames!)}',
                              style: const TextStyle(fontSize: 12),
                            )),
                        IconButton(
                          onPressed: () {
                            deleteItemDetail(index);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        )
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(global.language("product_unit")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_unit', index, screenData.details![index]);
                            },
                            child: Text(
                              global.activeLangName(screenData.details![index].unitnames!),
                              style: const TextStyle(fontSize: 12),
                            )),
                        const SizedBox(width: 5),
                        Text(global.language("warehouse")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_ware_house', index, screenData.details![index]);
                            },
                            child: Text(
                              global.activeLangName(screenData.details![index].whnames!),
                              style: const TextStyle(fontSize: 12),
                            )),
                        const SizedBox(width: 5),
                        Text(global.language("location")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_location', index, screenData.details![index]);
                            },
                            child: Text(
                              global.activeLangName(screenData.details![index].locationnames!),
                              style: const TextStyle(fontSize: 12),
                            )),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(global.language("product_qty")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_qty', index, screenData.details![index]);
                            },
                            child: Text(
                              global.formatNumber(screenData.details![index].qty),
                              style: const TextStyle(fontSize: 12),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ));
    }

    widgets.add(const SizedBox(
      height: 4,
    ));

    return Column(
      children: dataWidgets,
    );
  }

  Widget editProductListDetailMobileWidget() {
    List<Widget> widgets = [];
    widgets.add(const SizedBox(
      height: 10,
    ));

    List<Widget> dataWidgets = [];
    for (var index = 0; index < screenData.details!.length; index++) {
      for (var loop = 0; loop < headers.length; loop++) {
        // ignore: unused_local_variable
        String dataText = '';
        switch (headers[loop].code) {
          case "delete":
            dataText = "";
            break;
          case "line_number":
            dataText = (index + 1).toString();
            break;
          case "barcode":
            dataText = screenData.details![index].barcode;
            break;
          case "product_name":
            dataText = global.activeLangName(screenData.details![index].itemnames!);
            break;
          case "product_ware_house":
            dataText = global.activeLangName(screenData.details![index].whnames!);
            break;
          case "product_location":
            dataText = global.activeLangName(screenData.details![index].locationnames!);
            break;
          case "product_to_ware_house":
            dataText = global.activeLangName(screenData.details![index].towhnames!);
            break;
          case "product_to_location":
            dataText = global.activeLangName(screenData.details![index].tolocationnames!);
            break;
          case "product_unit":
            dataText = global.activeLangName(screenData.details![index].unitnames!);
            break;
          case "product_qty":
            dataText = global.formatNumber(screenData.details![index].qty);
            break;
          case "product_price_adjust":
            dataText = screenData.details![index].price.toString();
            break;
          case "product_price":
            dataText = screenData.details![index].price.toString();
            break;
          case "product_discount":
            dataText = screenData.details![index].discount;
            break;
          case "product_amount":
            dataText = global.formatNumber(screenData.details![index].sumamount);

            break;
        }
      }
      dataWidgets.add(Card(
        color: Colors.blue.shade100,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('barcode', index, screenData.details![index]);
                            },
                            child: Text(
                              '${screenData.details![index].barcode}~${global.activeLangName(screenData.details![index].itemnames!)}',
                              style: const TextStyle(fontSize: 12),
                            )),
                        IconButton(
                          onPressed: () {
                            deleteItemDetail(index);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        )
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(global.language("product_unit")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_unit', index, screenData.details![index]);
                            },
                            child: Text(
                              global.activeLangName(screenData.details![index].unitnames!),
                              style: const TextStyle(fontSize: 12),
                            )),
                        const SizedBox(width: 5),
                        Text(global.language("warehouse")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_ware_house', index, screenData.details![index]);
                            },
                            child: Text(
                              global.activeLangName(screenData.details![index].whnames!),
                              style: const TextStyle(fontSize: 12),
                            )),
                        const SizedBox(width: 5),
                        Text(global.language("location")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_location', index, screenData.details![index]);
                            },
                            child: Text(
                              global.activeLangName(screenData.details![index].locationnames!),
                              style: const TextStyle(fontSize: 12),
                            )),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(global.language("product_qty")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_qty', index, screenData.details![index]);
                            },
                            child: Text(
                              global.formatNumber(screenData.details![index].qty),
                              style: const TextStyle(fontSize: 12),
                            )),
                        const SizedBox(width: 5),
                        Text(global.language("price")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_price', index, screenData.details![index]);
                            },
                            child: Text(
                              global.formatNumber(screenData.details![index].price),
                              style: const TextStyle(fontSize: 12),
                            )),
                        const SizedBox(width: 5),
                        Text(global.language("discount")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_discount', index, screenData.details![index]);
                            },
                            child: Text(
                              screenData.details![index].discount,
                              style: const TextStyle(fontSize: 12),
                            )),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${global.language("total_value")}: ${global.formatNumber(screenData.details![index].sumamount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ));
    }

    widgets.add(const SizedBox(
      height: 4,
    ));

    return Column(
      children: dataWidgets,
    );
  }

  Widget editProductTransferListDetailMobileWidget() {
    List<Widget> widgets = [];
    widgets.add(const SizedBox(
      height: 10,
    ));

    List<Widget> dataWidgets = [];
    for (var index = 0; index < screenData.details!.length; index++) {
      dataWidgets.add(Card(
        color: Colors.blue.shade100,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('barcode', index, screenData.details![index]);
                            },
                            child: Text(
                              '${screenData.details![index].barcode}~${global.activeLangName(screenData.details![index].itemnames!)}',
                              style: const TextStyle(fontSize: 12),
                            )),
                        IconButton(
                          onPressed: () {
                            deleteItemDetail(index);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        )
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(global.language("product_unit")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_unit', index, screenData.details![index]);
                            },
                            child: Text(
                              global.activeLangName(screenData.details![index].unitnames!),
                              style: const TextStyle(fontSize: 12),
                            )),
                        const SizedBox(width: 5),
                        Text(global.language("warehouse")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_ware_house', index, screenData.details![index]);
                            },
                            child: Text(
                              global.activeLangName(screenData.details![index].whnames!),
                              style: const TextStyle(fontSize: 12),
                            )),
                        const SizedBox(width: 5),
                        Text(global.language("location")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_location', index, screenData.details![index]);
                            },
                            child: Text(
                              global.activeLangName(screenData.details![index].locationnames!),
                              style: const TextStyle(fontSize: 12),
                            )),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(global.language("to_warehouse")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_to_ware_house', index, screenData.details![index]);
                            },
                            child: Text(
                              global.activeLangName(screenData.details![index].towhnames!),
                              style: const TextStyle(fontSize: 12),
                            )),
                        const SizedBox(width: 5),
                        Text(global.language("location")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_to_location', index, screenData.details![index]);
                            },
                            child: Text(
                              global.activeLangName(screenData.details![index].tolocationnames!),
                              style: const TextStyle(fontSize: 12),
                            )),
                        const SizedBox(width: 5),
                        Text(global.language("product_qty")),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(4),
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(0)),
                              ),
                            ),
                            onPressed: () {
                              showDialogCommand('product_qty', index, screenData.details![index]);
                            },
                            child: Text(
                              global.formatNumber(screenData.details![index].qty),
                              style: const TextStyle(fontSize: 12),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ));
    }

    widgets.add(const SizedBox(
      height: 4,
    ));

    return Column(
      children: dataWidgets,
    );
  }

  Widget editProductListDetailWidget(double maxWidth, double sumWidth) {
    List<Widget> widgets = [];

    String groupName = "";
    for (var index = 0; index < screenData.details!.length; index++) {
      if (widget.type == global.TransactionTypeEnum.purchasereturn ||
          widget.type == global.TransactionTypeEnum.salereturn ||
          widget.type == global.TransactionTypeEnum.stockreturnproduct ||
          widget.type == global.TransactionTypeEnum.stockreceiveproduct) {
        if (screenData.details![index].docref! != groupName) {
          String dateTime = screenData.details![index].docrefdatetime.toString();
          String tolocaldateTime = DateTime.parse(dateTime).toLocal().toIso8601String();
          if (screenData.details![index].docref != "") {
            widgets.add(
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  (widget.type != global.TransactionTypeEnum.stockreceiveproduct)
                      ? Row(
                          children: [
                            Text(
                              screenData.details![index].docref!,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(tolocaldateTime)), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : Row(
                          children: [
                            Text(
                              'ชื่อตะกร้า : ${screenData.details![index].docref!}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ],
              ),
            );
          }
          groupName = screenData.details![index].docref!;
        }
      }
      List<Widget> dataWidgets = [];

      for (var loop = 0; loop < headers.length; loop++) {
        String dataText = '';

        switch (headers[loop].code) {
          case "delete":
            dataText = "";
            break;
          case "line_number":
            dataText = (index + 1).toString();
            break;
          case "barcode":
            dataText = screenData.details![index].barcode;
            break;
          case "product_name":
            dataText = global.activeLangName(screenData.details![index].itemnames!);
            break;
          case "product_ware_house":
            dataText = global.activeLangName(screenData.details![index].whnames!);
            break;
          case "product_location":
            dataText = global.activeLangName(screenData.details![index].locationnames!);
            break;
          case "product_to_ware_house":
            dataText = global.activeLangName(screenData.details![index].towhnames!);
            break;
          case "product_to_location":
            dataText = global.activeLangName(screenData.details![index].tolocationnames!);
            break;
          case "product_unit":
            dataText = global.activeLangName(screenData.details![index].unitnames!);
            break;
          case "product_qty":
            dataText = global.formatNumber(screenData.details![index].qty);
            break;
          case "product_price_adjust":
            dataText = global.formatNumber(screenData.details![index].price);
            break;
          case "product_price":
            dataText = global.formatNumber(screenData.details![index].price);
            break;
          case "product_discount":
            dataText = screenData.details![index].discount;
            break;
          case "product_amount":
            dataText = global.formatNumber(screenData.details![index].sumamount);

            break;
        }

        if (headers[loop].code == 'delete') {
          dataWidgets.add(SizedBox(
            width: maxWidth * headers[loop].width / sumWidth,
            child: IconButton(
              onPressed: () {
                deleteItemDetail(index);
              },
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ));
        } else {
          dataWidgets.add(
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
                onPressed: () {
                  showDialogCommand(headers[loop].code, index, screenData.details![index]);
                },
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
        Column(
          children: [
            Row(
              children: dataWidgets,
            ),
            productDescriptionWidget(maxWidth, sumWidth, screenData.details![index].description!),
            productOptionsListDetailWidget(maxWidth, sumWidth, screenData.details![index].extrajsonlist!),
          ],
        ),
      );
    }

    return Column(
      children: widgets,
    );
  }

  Widget productDescriptionWidget(double maxWidth, double sumWidth, String description) {
    List<Widget> widgets = [];
    if (description.isNotEmpty) {
      List<Widget> descriptions = [];

      for (var loop = 0; loop < headers.length; loop++) {
        String dataText = '';

        switch (headers[loop].code) {
          case "delete":
            dataText = "";
            break;
          case "line_number":
            dataText = "";
            break;
          case "barcode":
            dataText = "";
            break;
          case "product_name":
            dataText = "หมายเหตุ : $description";
            break;
          case "product_ware_house":
            dataText = "";
            break;
          case "product_location":
            dataText = "";
            break;
          case "product_to_ware_house":
            dataText = "";
            break;
          case "product_to_location":
            dataText = "";
            break;
          case "product_unit":
            dataText = "";
            break;
          case "product_qty":
            dataText = "";
            break;
          case "product_price_adjust":
            dataText = "";
            break;
          case "product_price":
            dataText = "";
            break;
          case "product_discount":
            dataText = "";
            break;
          case "product_amount":
            dataText = "";

            break;
        }

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

    return Column(
      children: widgets,
    );
  }

  Widget productOptionsListDetailWidget(double maxWidth, double sumWidth, List<ExtraJsonListModel> opstions) {
    List<Widget> widgets = [];
    if (opstions.isNotEmpty) {
      for (var index = 0; index < opstions.length; index++) {
        List<Widget> dataOptions = [];

        for (var loop = 0; loop < headers.length; loop++) {
          String dataText = '';

          switch (headers[loop].code) {
            case "delete":
              dataText = "";
              break;
            case "line_number":
              dataText = "";
              break;
            case "barcode":
              dataText = opstions[index].barcode!;
              break;
            case "product_name":
              dataText = "- ${global.activeLangName(opstions[index].itemnames!)}";
              break;
            case "product_ware_house":
              dataText = "";
              break;
            case "product_location":
              dataText = "";
              break;
            case "product_to_ware_house":
              dataText = "";
              break;
            case "product_to_location":
              dataText = "";
              break;
            case "product_unit":
              dataText = opstions[index].unit_name!;
              break;
            case "product_qty":
              dataText = global.formatNumber((opstions[index].qty == 0) ? 1 : opstions[index].qty!);
              break;
            case "product_price_adjust":
              dataText = "";
              break;
            case "product_price":
              dataText = global.formatNumber(opstions[index].price!);
              break;
            case "product_discount":
              dataText = "";
              break;
            case "product_amount":
              dataText = global.formatNumber(opstions[index].price! * ((opstions[index].qty == 0) ? 1 : opstions[index].qty!));

              break;
          }

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

    return Column(
      children: widgets,
    );
  }

  Widget editSummeryWidget() {
    List<Widget> sumDetails = [];
    List<Widget> paymentDetail = [];

    ///  ผลต่างจากบิลเดิม
    if (widget.type == global.TransactionTypeEnum.salereturn || widget.type == global.TransactionTypeEnum.purchasereturn) {
      sumDetails.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: TotalTextController(
                        readOnly: !screenData.ismanualamount,
                        title: global.language("text_form_ref_total_original"),
                        data: screenData.reftotaloriginal,
                        icon: null,
                        useColor: false,
                        onChanged: (value) {
                          if (value != '') {
                            screenData.totalamount = double.parse(value.replaceAll(',', ''));
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: TotalTextController(
                        readOnly: !screenData.ismanualamount,
                        title: global.language("text_form_ref_total_correct"),
                        data: screenData.reftotalcorrect,
                        icon: null,
                        useColor: false,
                        onChanged: (value) {
                          if (value != '') {
                            screenData.totalamount = double.parse(value.replaceAll(',', ''));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: TotalTextController(
                  readOnly: true,
                  title: global.language("text_form_ref_total_diff"),
                  data: screenData.reftotaldiff,
                  icon: null,
                  useColor: false,
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
        ),
      );
    }

    sumDetails.add(Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: TotalTextController(
              readOnly: !screenData.ismanualamount,
              title: global.language("doc_total_value"),
              data: screenData.totalvalue,
              icon: null,
              onChanged: (value) {
                if (value != '' && screenData.ismanualamount) {
                  screenData.totalvalue = double.parse(value.replaceAll(',', ''));
                }
              },
            ),
          ),
          (widget.type == global.TransactionTypeEnum.purchase ||
                  widget.type == global.TransactionTypeEnum.purchaseorder ||
                  widget.type == global.TransactionTypeEnum.purchasereturn ||
                  widget.type == global.TransactionTypeEnum.purchasepartial ||
                  widget.type == global.TransactionTypeEnum.accrualreceive)
              ? Expanded(
                  child: Row(
                  children: [
                    const SizedBox(
                      width: 10,
                    ),
                    Checkbox(
                      fillColor: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.red;
                        }
                        return null;
                      }),
                      value: screenData.ismanualamount,
                      onChanged: (bool? value) {
                        screenData.ismanualamount = value!;
                        if (!value) {
                          _calTotalValue();
                          _calPayTotal();
                        }
                        setState(() {});
                      },
                    ),
                    Expanded(
                      child: Text(
                        global.language("is_manual_amount"),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ))
              : Container(),
        ],
      ),
    ));
    if (widget.type == global.TransactionTypeEnum.sale ||
        widget.type == global.TransactionTypeEnum.saleorder ||
        widget.type == global.TransactionTypeEnum.salereturn ||
        widget.type == global.TransactionTypeEnum.purchase ||
        widget.type == global.TransactionTypeEnum.purchaseorder ||
        widget.type == global.TransactionTypeEnum.accrualreceive) {
      sumDetails.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  readOnly: false,
                  enabled: true,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: global.language("detail_discount_formula"),
                  ),
                  controller: detaildiscountformulaController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    // Allow digits (0-9), '%' and '.'
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9%.]')),
                  ],
                  onChanged: (value) {
                    if (value != '' && value.isNotEmpty) {
                      detaildiscountformulaController.value = TextEditingValue(text: value, selection: detaildiscountformulaController.selection);
                      screenData.detaildiscountformula = value;

                      RegExp regExp = RegExp(r'[0-9%.]');
                      if (regExp.hasMatch(value)) {
                        _calTotalValue();
                      }
                    } else {
                      _calTotalValue();
                    }
                  },
                  onEditingComplete: () {
                    if (detaildiscountformulaController.text == '') {
                      detaildiscountformulaController.text = '0';
                      screenData.detaildiscountformula = '0';
                      _calTotalValue();
                    }
                  },
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: TotalTextController(
                  readOnly: true,
                  title: 'ส่วนลดจากแต้ม',
                  data: screenData.pointdiscountamount,
                  icon: null,
                  onChanged: (value) {
                    if (value != '') {
                      screenData.pointdiscountamount = int.parse(value.replaceAll(',', ''));
                    }
                  },
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: TotalTextController(
                  readOnly: true,
                  title: 'ส่วนลดจากคูปอง',
                  data: screenData.coupondiscountamount,
                  icon: null,
                  onChanged: (value) {
                    if (value != '') {
                      screenData.coupondiscountamount = double.parse(value.replaceAll(',', ''));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );

      sumDetails.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: TotalTextController(
                  readOnly: !screenData.ismanualamount,
                  title: global.language("detail_total_discount"),
                  data: screenData.detailtotaldiscount,
                  icon: null,
                  onChanged: (value) {
                    if (value != '') {
                      screenData.detailtotaldiscount = double.parse(value.replaceAll(',', ''));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );

      sumDetails.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: TotalTextController(
                  readOnly: true,
                  title: global.language("total_discount_vat_amount"),
                  data: screenData.totaldiscountvatamount,
                  icon: null,
                  onChanged: (value) {
                    if (value != '') {
                      screenData.totaldiscountvatamount = double.parse(value.replaceAll(',', ''));
                    }
                  },
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: TotalTextController(
                  readOnly: true,
                  title: global.language("total_discount_except_vat_amount"),
                  data: screenData.totaldiscountexceptvatamount,
                  icon: null,
                  onChanged: (value) {
                    if (value != '') {
                      screenData.totaldiscountexceptvatamount = double.parse(value.replaceAll(',', ''));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
    if ((widget.type != global.TransactionTypeEnum.stockreceiveproduct)) {
      sumDetails.add(Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: TotalTextController(
                readOnly: (screenData.ismanualamount) ? false : true,
                title: global.language("doc_before_vat_amount"),
                data: screenData.totalbeforevat,
                icon: null,
                onChanged: (value) {
                  if (value != '' && screenData.ismanualamount) {
                    screenData.totalbeforevat = double.parse(value.replaceAll(',', ''));
                  }
                },
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: TotalTextController(
                readOnly: (screenData.ismanualamount) ? false : true,
                title: global.language("doc_vat_amount"),
                data: screenData.totalvatvalue,
                icon: null,
                onChanged: (value) {
                  if (value != '' && screenData.ismanualamount) {
                    screenData.totalvatvalue = double.parse(value.replaceAll(',', ''));
                  }
                },
              ),
            ),
          ],
        ),
      ));

      sumDetails.add(Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: TotalTextController(
                readOnly: (screenData.ismanualamount) ? false : true,
                title: global.language("doc_after_vat_amount"),
                data: screenData.totalaftervat,
                icon: null,
                onChanged: (value) {
                  if (value != '' && screenData.ismanualamount) {
                    screenData.totalaftervat = double.parse(value.replaceAll(',', ''));
                  }
                },
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: TotalTextController(
                readOnly: (screenData.ismanualamount) ? false : true,
                title: global.language("doc_except_vat_amount"),
                data: screenData.totalexceptvat,
                icon: null,
                onChanged: (value) {
                  if (value != '' && screenData.ismanualamount) {
                    screenData.totalexceptvat = double.parse(value.replaceAll(',', ''));
                  }
                },
              ),
            ),
          ],
        ),
      ));

      sumDetails.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: TotalTextController(
                  readOnly: (screenData.ismanualamount) ? false : true,
                  title: global.language("detail_total_amount"),
                  data: screenData.detailtotalamount,
                  icon: null,
                  onChanged: (value) {
                    if (value != '' && screenData.ismanualamount) {
                      screenData.detailtotalamount = double.parse(value.replaceAll(',', ''));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );

      /// ส่วนลดท้ายบิล  และ ยอดส่วนลด ปิดไว้ก่อน

      // sumDetails.add(Container(
      //   margin: const EdgeInsets.only(bottom: 10),
      //   child: Row(
      //     children: [
      //       Expanded(
      //         child: TextFormField(
      //           readOnly: false,
      //           enabled: true,
      //           decoration: InputDecoration(
      //             border: const OutlineInputBorder(),
      //             labelText: global.language("discount_word"),
      //           ),
      //           controller: discountWordController,
      //           keyboardType:
      //               const TextInputType.numberWithOptions(decimal: true),
      //           inputFormatters: [
      //             FilteringTextInputFormatter.allow(
      //                 RegExp(r'[0-9%.]')), // Allow digits (0-9) and '%'
      //           ],
      //           onChanged: (value) {
      //             if (value != '' && value.isNotEmpty) {
      //               discountWordController.value = TextEditingValue(
      //                   text: value,
      //                   selection: discountWordController.selection);
      //               screenData.discountword = value;

      //               RegExp regExp = RegExp(r'[0-9%.]');
      //               if (regExp.hasMatch(value)) {
      //                 if (!screenData.ismanualamount) {
      //                   _calTotalValue();
      //                 }
      //               }
      //             } else {
      //               if (!screenData.ismanualamount) {
      //                 _calTotalValue();
      //               }
      //             }
      //           },
      //           onEditingComplete: () {
      //             if (discountWordController.text == "") {
      //               discountWordController.text = "0";
      //               screenData.discountword = "0";
      //             }
      //             if (!screenData.ismanualamount) {
      //               screenData.discountword = discountWordController.text;
      //               _calTotalValue();
      //             }
      //           },
      //         ),
      //       ),
      //       const SizedBox(
      //         width: 10,
      //       ),
      //       Expanded(
      //         child: TotalTextController(
      //           readOnly: !screenData.ismanualamount,
      //           title: global.language("doc_discount_amount"),
      //           data: screenData.totaldiscount,
      //           icon: null,
      //           onChanged: (value) {
      //             if (value != '') {
      //               screenData.totaldiscount =
      //                   double.parse(value.replaceAll(',', ''));
      //             }
      //           },
      //         ),
      //       ),
      //     ],
      //   ),
      // ));

      sumDetails.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: TotalTextController(
                  readOnly: !screenData.ismanualamount,
                  title: global.language("doc_total_amount"),
                  data: screenData.totalamountafterdiscount,
                  icon: null,
                  onChanged: (value) {
                    if (value != '') {
                      screenData.totalamountafterdiscount = double.parse(value.replaceAll(',', ''));
                    }
                  },
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: TextFormField(
                  readOnly: false,
                  enabled: true,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: global.language("round_amount"),
                  ),
                  controller: roundAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [global.NumberInputFormatter()],
                  onChanged: (value) {
                    if (value != '' && value.isNotEmpty) {
                      roundAmountController.value = TextEditingValue(text: value, selection: roundAmountController.selection);

                      /// RegExp 0-9 if macth to function  _calPayTotal();
                      RegExp regExp = RegExp(r'[0-9]');
                      if (regExp.hasMatch(value)) {
                        if (!screenData.ismanualamount) {
                          _calPayTotal();
                        }
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      );

      sumDetails.add(
        Row(
          children: [
            Expanded(
              child: TotalTextController(
                readOnly: !screenData.ismanualamount,
                title: global.language("sum_pay"),
                data: screenData.totalamount + (screenData.roundamount ?? 0),
                icon: null,
                useColor: true,
                onChanged: (value) {
                  if (value != '') {
                    screenData.totalamount = double.parse(value.replaceAll(',', ''));
                  }
                },
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: TotalTextController(
                readOnly: true,
                title: global.language("total_amount"),
                data: payTotalBill,
                icon: null,
                useColor: true,
                onChanged: (value) {},
              ),
            ),
          ],
        ),
      );

      List<Widget> listTransfer = [];
      List<Widget> listCredit = [];
      List<Widget> listCheque = [];
      List<Widget> listCoupon = [];
      List<Widget> listQr = [];

      /// widget for transfer
      for (var i = 0; i < payTransfer.length; i++) {
        listTransfer.add(
          Card(
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${global.language("list_transfer")} ${i + 1}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 15),
                          child: IconButton(
                            onPressed: () {
                              payTransfer.removeAt(i);
                              transferDateController.removeAt(i);
                              payTransferAmountController.removeAt(i);
                              _calPayTotal();
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CustomDatePicker(
                            key: ValueKey(payTransfer[i].doc_date_time!),
                            labelText: global.language("doc_date"),
                            initialDate: payTransfer[i].doc_date_time!,
                            useBuddhistCalendar: true,
                            onDateSelected: (date) {
                              if (date != null) {
                                setState(() {
                                  // กำหนดเวลาจากวันที่ที่เลือกโดยรักษาเวลาเดิม
                                  final currentTime = payTransfer[i].doc_date_time!;
                                  final combinedDateTime =
                                      DateTime(date.year, date.month, date.day, currentTime.hour, currentTime.minute, currentTime.second, currentTime.millisecond);

                                  docDateTimeValidated = true;
                                  payTransfer[i].doc_date_time = combinedDateTime.toLocal();
                                });
                              }
                            },
                            decoration: InputDecoration(
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              border: const OutlineInputBorder(),
                              labelText: global.language("doc_ref_date"),
                            )),
                      ),
                      Expanded(
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          child: TextField(
                            readOnly: true,
                            textInputAction: TextInputAction.next,
                            controller: TextEditingController(text: payTransfer[i].book_bank_code),
                            textAlign: TextAlign.left,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey, width: 0.0),
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              suffixIcon: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    focusNode: FocusNode(skipTraversal: true),
                                    icon: const Icon(Icons.search),
                                    onPressed: () {
                                      bookBankSearch().then((value) {
                                        if (value != null) {
                                          payTransfer[i].book_bank_code = value.passbook;
                                          payTransfer[i].bank_code = value.bankcode;
                                          payTransfer[i].bank_name = value.banknames![0].name;
                                          setState(() {});
                                        }
                                      });
                                    },
                                  )
                                ],
                              ),
                              border: const OutlineInputBorder(),
                              labelText: global.language("pass_book"),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: global.language("bank"),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                            ),
                            controller: TextEditingController(
                              text: (payTransfer[i].bank_code != '') ? " ${payTransfer[i].bank_code} ~ ${payTransfer[i].bank_name ?? []}" : "",
                            )),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            textAlign: TextAlign.center, // Center-align the text
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            controller: payTransferAmountController[i],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [global.NumberInputFormatter()],
                            onChanged: (value) {
                              if (value == '' && value.isEmpty) {
                                payTransferAmountController[i].text = "0";
                                payTransfer[i].amount = 0;
                              } else {
                                payTransferAmountController[i].value = TextEditingValue(text: value.toUpperCase(), selection: payTransferAmountController[i].selection);
                                payTransfer[i].amount = double.parse(value.replaceAll(',', ''));
                              }

                              _calPayTotal();
                            },
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

      /// widget for credit card
      for (var i = 0; i < payCreditCard.length; i++) {
        listCredit.add(
          Card(
              child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${global.language("list_creditcard")} ${i + 1}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 15),
                        child: IconButton(
                          onPressed: () {
                            payCreditCard.removeAt(i);
                            creditCardDateController.removeAt(i);
                            payCreditCardAmountController.removeAt(i);
                            _calPayTotal();
                          },
                          icon: const Icon(Icons.delete),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: CustomDatePicker(
                          key: ValueKey(payCreditCard[i].doc_date_time!),
                          labelText: global.language("doc_date"),
                          initialDate: payCreditCard[i].doc_date_time!,
                          useBuddhistCalendar: true,
                          onDateSelected: (date) {
                            if (date != null) {
                              setState(() {
                                // กำหนดเวลาจากวันที่ที่เลือกโดยรักษาเวลาเดิม
                                final currentTime = payCreditCard[i].doc_date_time!;
                                final combinedDateTime =
                                    DateTime(date.year, date.month, date.day, currentTime.hour, currentTime.minute, currentTime.second, currentTime.millisecond);

                                docDateTimeValidated = true;
                                payCreditCard[i].doc_date_time = combinedDateTime.toLocal();
                              });
                            }
                          },
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: const OutlineInputBorder(),
                            labelText: global.language("doc_ref_date"),
                          )),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: global.language("creditnumber"),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        controller: TextEditingController(text: payCreditCard[i].card_number),
                        onChanged: (value) {
                          payCreditCard[i].card_number = value;
                        },
                        onSubmitted: (value) {},
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          child: TextField(
                            readOnly: true,
                            textInputAction: TextInputAction.next,
                            controller: TextEditingController(text: payCreditCard[i].book_bank_code),
                            textAlign: TextAlign.left,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey, width: 0.0),
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              suffixIcon: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    focusNode: FocusNode(skipTraversal: true),
                                    icon: const Icon(Icons.search),
                                    onPressed: () {
                                      bookBankSearch().then((value) {
                                        if (value != null) {
                                          payCreditCard[i].book_bank_code = value.passbook;
                                          payCreditCard[i].bank_code = value.bankcode;
                                          payCreditCard[i].bank_name = value.banknames![0].name;
                                          setState(() {});
                                        }
                                      });
                                    },
                                  )
                                ],
                              ),
                              border: const OutlineInputBorder(),
                              labelText: global.language("pass_book"),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: global.language("bank"),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                            ),
                            controller: TextEditingController(
                              text: (payCreditCard[i].bank_code != '') ? " ${payCreditCard[i].bank_code} ~ ${payCreditCard[i].bank_name ?? []}" : "",
                            )),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          textAlign: TextAlign.center, // Center-align the text
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          controller: payCreditCardAmountController[i],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [global.NumberInputFormatter()],
                          onChanged: (value) {
                            if (value == '' && value.isEmpty) {
                              payCreditCardAmountController[i].text = "0";
                              payCreditCard[i].amount = 0;
                            } else {
                              payCreditCardAmountController[i].value = TextEditingValue(text: value.toUpperCase(), selection: payCreditCardAmountController[i].selection);
                              payCreditCard[i].amount = double.parse(value.replaceAll(',', ''));
                            }

                            _calPayTotal();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        );
      }

      /// widget for cheque
      for (var i = 0; i < payCheque.length; i++) {
        listCheque.add(
          Card(
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${global.language("list_cheque")} ${i + 1}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 15),
                          child: IconButton(
                            onPressed: () {
                              payCheque.removeAt(i);
                              chequeDateController.removeAt(i);
                              chequeDueDateDateController.removeAt(i);
                              payChequeAmountController.removeAt(i);
                              _calPayTotal();
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: CustomDatePicker(
                              key: ValueKey(payCheque[i].doc_date_time!),
                              labelText: global.language("doc_date"),
                              initialDate: payCheque[i].doc_date_time!,
                              useBuddhistCalendar: true,
                              onDateSelected: (date) {
                                if (date != null) {
                                  setState(() {
                                    // กำหนดเวลาจากวันที่ที่เลือกโดยรักษาเวลาเดิม
                                    final currentTime = payCheque[i].doc_date_time!;
                                    final combinedDateTime =
                                        DateTime(date.year, date.month, date.day, currentTime.hour, currentTime.minute, currentTime.second, currentTime.millisecond);

                                    docDateTimeValidated = true;
                                    payCheque[i].doc_date_time = combinedDateTime.toLocal();
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                border: const OutlineInputBorder(),
                                labelText: global.language("doc_ref_date"),
                              ))),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          child: TextField(
                            readOnly: true,
                            textInputAction: TextInputAction.next,
                            controller: TextEditingController(text: payCheque[i].book_bank_code),
                            textAlign: TextAlign.left,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey, width: 0.0),
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              suffixIcon: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    focusNode: FocusNode(skipTraversal: true),
                                    icon: const Icon(Icons.search),
                                    onPressed: () {
                                      bookBankSearch().then((value) {
                                        if (value != null) {
                                          payCheque[i].book_bank_code = value.passbook;
                                          payCheque[i].bank_code = value.bankcode;
                                          payCheque[i].bank_name = value.banknames![0].name;
                                          setState(() {});
                                        }
                                      });
                                    },
                                  )
                                ],
                              ),
                              border: const OutlineInputBorder(),
                              labelText: global.language("pass_book"),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: global.language("bank"),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                            ),
                            controller: TextEditingController(
                              text: (payCheque[i].bank_code != '') ? " ${payCheque[i].bank_code} ~ ${payCheque[i].bank_name ?? []}" : "",
                            )),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomDatePicker(
                            key: ValueKey(payCheque[i].due_date!),
                            labelText: global.language("due_date"),
                            initialDate: payCheque[i].due_date!,
                            useBuddhistCalendar: true,
                            onDateSelected: (date) {
                              if (date != null) {
                                setState(() {
                                  // กำหนดเวลาจากวันที่ที่เลือกโดยรักษาเวลาเดิม
                                  final currentTime = payCheque[i].due_date!;
                                  final combinedDateTime =
                                      DateTime(date.year, date.month, date.day, currentTime.hour, currentTime.minute, currentTime.second, currentTime.millisecond);

                                  docDateTimeValidated = true;
                                  payCheque[i].due_date = combinedDateTime.toLocal();
                                });
                              }
                            },
                            decoration: InputDecoration(
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              border: const OutlineInputBorder(),
                              labelText: global.language("due_date"),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: global.language("cheque_number"),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                            ),
                            controller: TextEditingController(text: payCheque[i].cheque_number),
                            onChanged: (value) {
                              payCheque[i].card_number = value;
                            },
                            onSubmitted: (value) {},
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            textAlign: TextAlign.center, // Center-align the text
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            controller: payChequeAmountController[i],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [global.NumberInputFormatter()],
                            onChanged: (value) {
                              if (value == '' && value.isEmpty) {
                                payChequeAmountController[i].text = "0";
                                payCheque[i].amount = 0;
                              } else {
                                payChequeAmountController[i].value = TextEditingValue(text: value.toUpperCase(), selection: payChequeAmountController[i].selection);
                                payCheque[i].amount = double.parse(value.replaceAll(',', ''));
                              }

                              _calPayTotal();
                            },
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

      /// widget for coupon new
      if (couPons!.isNotEmpty) {
        listCoupon.add(
          CouponWidget(
            couPons: couPons!,
            isReadOnly: true,
            onCouponDeleted: (index) {
              couPons!.removeAt(index);
              _calPayTotal();
            },
            onAmountChanged: () {
              _calPayTotal();
            },
          ),
        );
      }

      /// widget for coupon
      for (var i = 0; i < payCoupon.length; i++) {
        listCoupon.add(
          Card(
              child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${global.language("list_coupon")} ${i + 1}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 15),
                        child: IconButton(
                          onPressed: () {
                            payCoupon.removeAt(i);
                            couponDateController.removeAt(i);
                            payCouponAmountController.removeAt(i);
                            _calPayTotal();
                          },
                          icon: const Icon(Icons.delete),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                        child: CustomDatePicker(
                            key: ValueKey(payCoupon[i].doc_date_time!),
                            labelText: global.language("doc_date"),
                            initialDate: payCoupon[i].doc_date_time!,
                            useBuddhistCalendar: true,
                            onDateSelected: (date) {
                              if (date != null) {
                                setState(() {
                                  // กำหนดเวลาจากวันที่ที่เลือกโดยรักษาเวลาเดิม
                                  final currentTime = payCoupon[i].doc_date_time!;
                                  final combinedDateTime =
                                      DateTime(date.year, date.month, date.day, currentTime.hour, currentTime.minute, currentTime.second, currentTime.millisecond);

                                  docDateTimeValidated = true;
                                  payCoupon[i].doc_date_time = combinedDateTime.toLocal();
                                });
                              }
                            },
                            decoration: InputDecoration(
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              border: const OutlineInputBorder(),
                              labelText: global.language("doc_ref_date"),
                              hintText: global.language("doc_ref_date_hint"),
                            ))),
                    const SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: global.language("coupon_number"),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        controller: TextEditingController(text: payCoupon[i].number),
                        onChanged: (value) {
                          payCoupon[i].number = value;
                        },
                        onSubmitted: (value) {},
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: TextField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: global.language("description"),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    controller: TextEditingController(text: payCoupon[i].description),
                    onChanged: (value) {
                      payCoupon[i].description = value;
                    },
                    onSubmitted: (value) {},
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          textAlign: TextAlign.center, // Center-align the text
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          controller: payCouponAmountController[i],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [global.NumberInputFormatter()],
                          onChanged: (value) {
                            if (value == '' && value.isEmpty) {
                              payCouponAmountController[i].text = "0";
                              payCoupon[i].amount = 0;
                            } else {
                              payCouponAmountController[i].value = TextEditingValue(text: value.toUpperCase(), selection: payCouponAmountController[i].selection);
                              payCoupon[i].amount = double.parse(value.replaceAll(',', ''));
                            }

                            _calPayTotal();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        );
      }

      /// widget for Qr code
      for (var i = 0; i < payQr.length; i++) {
        listQr.add(
          Card(
              child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${global.language("list_qr")} ${i + 1}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 15),
                        child: IconButton(
                          onPressed: () {
                            payQr.removeAt(i);
                            qrDateController.removeAt(i);
                            payQrAmountController.removeAt(i);
                            _calPayTotal();
                          },
                          icon: const Icon(Icons.delete),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                        child: CustomDatePicker(
                            key: ValueKey(payQr[i].doc_date_time!),
                            labelText: global.language("doc_date"),
                            initialDate: payQr[i].doc_date_time!,
                            useBuddhistCalendar: true,
                            onDateSelected: (date) {
                              if (date != null) {
                                setState(() {
                                  // กำหนดเวลาจากวันที่ที่เลือกโดยรักษาเวลาเดิม
                                  final currentTime = payQr[i].doc_date_time!;
                                  final combinedDateTime =
                                      DateTime(date.year, date.month, date.day, currentTime.hour, currentTime.minute, currentTime.second, currentTime.millisecond);

                                  docDateTimeValidated = true;
                                  payQr[i].doc_date_time = combinedDateTime.toLocal();
                                });
                              }
                            },
                            decoration: InputDecoration(
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              border: const OutlineInputBorder(),
                              labelText: global.language("doc_ref_date"),
                              hintText: global.language("doc_ref_date_hint"),
                            ))),
                    const SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: global.language("provider_code"),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        controller: TextEditingController(text: payQr[i].provider_code),
                        onChanged: (value) {
                          payQr[i].provider_code = value;
                        },
                        onSubmitted: (value) {},
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: global.language("provider_name"),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        controller: TextEditingController(text: payQr[i].provider_name),
                        onChanged: (value) {
                          payQr[i].provider_name = value;
                        },
                        onSubmitted: (value) {},
                      ),
                    ),
                  ],
                ),
                // const SizedBox(
                //   height: 10,
                // ),
                // Row(
                //   children: [
                //     Expanded(
                //       child: RawKeyboardListener(
                //         focusNode: FocusNode(),
                //         child: TextField(
                //           readOnly: true,
                //           textInputAction: TextInputAction.next,
                //           controller: TextEditingController(text: payQr[i].book_bank_code),
                //           textAlign: TextAlign.left,
                //           textCapitalization: TextCapitalization.characters,
                //           decoration: InputDecoration(
                //             enabledBorder: const OutlineInputBorder(
                //               borderSide: BorderSide(color: Colors.grey, width: 0.0),
                //             ),
                //             floatingLabelBehavior: FloatingLabelBehavior.always,
                //             suffixIcon: Row(
                //               mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                //               mainAxisSize: MainAxisSize.min,
                //               children: [
                //                 IconButton(
                //                   focusNode: FocusNode(skipTraversal: true),
                //                   icon: const Icon(Icons.search),
                //                   onPressed: () {
                //                     bookBankSearch().then((value) {
                //                       if (value != null) {
                //                         payQr[i].book_bank_code = value.passbook;
                //                         payQr[i].bank_code = value.bankcode;
                //                         payQr[i].bank_name = value.banknames![0].name;
                //                         setState(() {});
                //                       }
                //                     });
                //                   },
                //                 )
                //               ],
                //             ),
                //             border: const OutlineInputBorder(),
                //             labelText: global.language("pass_book"),
                //           ),
                //         ),
                //       ),
                //     ),
                //     const SizedBox(
                //       width: 5,
                //     ),
                //     Expanded(
                //       child: TextField(
                //           readOnly: true,
                //           decoration: InputDecoration(
                //             border: const OutlineInputBorder(),
                //             labelText: global.language("bank"),
                //             floatingLabelBehavior: FloatingLabelBehavior.always,
                //           ),
                //           controller: TextEditingController(
                //             text: (payQr[i].bank_code != '') ? " ${payQr[i].bank_code} ~ ${payQr[i].bank_name ?? []}" : "",
                //           )),
                //     ),
                //   ],
                // ),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          textAlign: TextAlign.center, // Center-align the text
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          controller: payQrAmountController[i],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [global.NumberInputFormatter()],
                          onChanged: (value) {
                            if (value == '' && value.isEmpty) {
                              payQrAmountController[i].text = "0";
                              payQr[i].amount = 0;
                            } else {
                              payQrAmountController[i].value = TextEditingValue(text: value.toUpperCase(), selection: payQrAmountController[i].selection);
                              payQr[i].amount = double.parse(value.replaceAll(',', ''));
                            }

                            _calPayTotal();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        );
      }

      if (widget.type == global.TransactionTypeEnum.purchase ||
          widget.type == global.TransactionTypeEnum.purchaseorder ||
          widget.type == global.TransactionTypeEnum.purchasepartial ||
          widget.type == global.TransactionTypeEnum.purchasereturn ||
          widget.type == global.TransactionTypeEnum.accrualreceive ||
          widget.type == global.TransactionTypeEnum.sale ||
          widget.type == global.TransactionTypeEnum.saleorder ||
          widget.type == global.TransactionTypeEnum.salereturn) {
        paymentDetail.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// pay menu
                    payMenuWidget(),
                    (showPayDetail == 0)
                        ? payCashWidget()
                        : (showPayDetail == 1)
                            ? payTransferWidget(listTransfer)
                            : (showPayDetail == 2)
                                ? payCreditCardWidget(listCredit)
                                : (showPayDetail == 3)
                                    ? payChequeWidget(listCheque)
                                    : (showPayDetail == 4)
                                        ? payCouponWidget(listCoupon)
                                        : (showPayDetail == 5)
                                            ? payQrWidget(listQr)
                                            : (showPayDetail == 6)
                                                ? payDeliveryWidget()
                                                : (showPayDetail == 7)
                                                    ? payPointWidget()
                                                    : Container(),
                  ],
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        readOnly: true,
                        enabled: (widget.type == global.TransactionTypeEnum.purchasereturn || widget.type == global.TransactionTypeEnum.salereturn)
                            ? screenData.inquirytype != 0 && screenData.inquirytype != 1
                            : screenData.inquirytype != 0,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: global.language("cash"),
                          suffixIcon: const IconButton(
                            icon: Icon(Icons.money),
                            onPressed: null,
                          ),
                        ),
                        controller: payCashAmountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [global.NumberInputFormatter()],
                        // onChanged: (value) {
                        //   payCashAmountController.value = TextEditingValue(text: value.toUpperCase(), selection: payCashAmountController.selection);
                        //   screenData.paycashamount = double.parse(value.replaceAll(',', ''));
                        // },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        readOnly: true,
                        enabled: (widget.type == global.TransactionTypeEnum.purchasereturn || widget.type == global.TransactionTypeEnum.salereturn)
                            ? screenData.inquirytype != 0 && screenData.inquirytype != 1
                            : screenData.inquirytype != 0,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: global.language("transfer"),
                          suffixIcon: const IconButton(
                            icon: Icon(Icons.transform_rounded),
                            onPressed: null,
                          ),
                        ),
                        controller: TextEditingController(text: global.formatNumber(screenData.summoneytransfer!)),
                      ),
                    ),
                    (widget.type == global.TransactionTypeEnum.sale)
                        ? Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: TextField(
                              readOnly: true,
                              enabled: (widget.type == global.TransactionTypeEnum.purchasereturn || widget.type == global.TransactionTypeEnum.salereturn)
                                  ? screenData.inquirytype != 0 && screenData.inquirytype != 1
                                  : screenData.inquirytype != 0,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: global.language("credit_card"),
                                suffixIcon: const IconButton(
                                  icon: Icon(Icons.credit_card),
                                  onPressed: null,
                                ),
                              ),
                              controller: TextEditingController(text: global.formatNumber(screenData.sumcreditcard!)),
                            ),
                          )
                        : Container(),
                    (widget.type == global.TransactionTypeEnum.sale)
                        ? Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: TextField(
                              readOnly: true,
                              enabled: (widget.type == global.TransactionTypeEnum.purchasereturn || widget.type == global.TransactionTypeEnum.salereturn)
                                  ? screenData.inquirytype != 0 && screenData.inquirytype != 1
                                  : screenData.inquirytype != 0,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: global.language("cheque"),
                                suffixIcon: const IconButton(
                                  icon: Icon(Icons.featured_play_list_outlined),
                                  onPressed: null,
                                ),
                              ),
                              controller: TextEditingController(text: global.formatNumber(screenData.sumcheque!)),
                            ),
                          )
                        : Container(),
                    (widget.type == global.TransactionTypeEnum.sale)
                        ? Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: TextField(
                              readOnly: true,
                              enabled: (widget.type == global.TransactionTypeEnum.purchasereturn || widget.type == global.TransactionTypeEnum.salereturn)
                                  ? screenData.inquirytype != 0 && screenData.inquirytype != 1
                                  : screenData.inquirytype != 0,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: global.language("coupon"),
                                suffixIcon: const IconButton(
                                  icon: Icon(Icons.card_giftcard),
                                  onPressed: null,
                                ),
                              ),
                              controller: TextEditingController(text: global.formatNumber(screenData.sumcoupon!)),
                            ),
                          )
                        : Container(),
                    (widget.type == global.TransactionTypeEnum.sale)
                        ? Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: TextField(
                              readOnly: true,
                              enabled: (widget.type == global.TransactionTypeEnum.purchasereturn || widget.type == global.TransactionTypeEnum.salereturn)
                                  ? screenData.inquirytype != 0 && screenData.inquirytype != 1
                                  : screenData.inquirytype != 0,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: global.language("qr_code"),
                                suffixIcon: const IconButton(
                                  icon: Icon(Icons.qr_code),
                                  onPressed: null,
                                ),
                              ),
                              controller: TextEditingController(text: global.formatNumber(screenData.sumqrcode!)),
                            ),
                          )
                        : Container(),
                    (widget.type == global.TransactionTypeEnum.sale)
                        ? Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: TextField(
                              readOnly: true,
                              enabled: (widget.type == global.TransactionTypeEnum.purchasereturn || widget.type == global.TransactionTypeEnum.salereturn)
                                  ? screenData.inquirytype != 0 && screenData.inquirytype != 1
                                  : screenData.inquirytype != 0,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: global.language("credit"),
                                suffixIcon: const IconButton(
                                  icon: Icon(Icons.person),
                                  onPressed: null,
                                ),
                              ),
                              controller: TextEditingController(text: global.formatNumber(screenData.sumcredit!)),
                            ),
                          )
                        : Container(),
                    (widget.type == global.TransactionTypeEnum.sale)
                        ? Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: TextFormField(
                              readOnly: true,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: global.language("delivery"),
                                suffixIcon: const IconButton(
                                  icon: Icon(Icons.delivery_dining_rounded),
                                  onPressed: null,
                                ),
                              ),
                              controller: payDeliveryCashAmountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [global.NumberInputFormatter()],
                            ),
                          )
                        : Container(),
                    (widget.type == global.TransactionTypeEnum.sale)
                        ? Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: TextField(
                              readOnly: true,
                              enabled: true,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: 'มูลค่าแต้ม',
                                suffixIcon: const Icon(Icons.star_rate_rounded),
                              ),
                              controller: TextEditingController(text: global.formatNumber(double.parse(screenData.paypointamount.toString()))),
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Column(
                  children: sumDetails,
                ),
                const SizedBox(
                  height: 10,
                ),
                Column(
                  children: paymentDetail,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget payMenuWidget() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showPayDetail = 0;
                      setState(() {});
                    },
                    icon: const Icon(Icons.money),
                    label: Text(
                      global.language("cash"),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (showPayDetail == 0) ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showPayDetail = 1;
                      setState(() {});
                    },
                    icon: const Icon(Icons.transform_rounded),
                    label: Text(
                      global.language("money_transfer"),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (showPayDetail == 1) ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),
              ),
              (widget.type == global.TransactionTypeEnum.sale)
                  ? Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showPayDetail = 2;
                            setState(() {});
                          },
                          icon: const Icon(Icons.credit_card),
                          label: Text(
                            global.language("credit_card"),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (showPayDetail == 2) ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ),
                    )
                  : Container(),
            ],
          ),
          (widget.type == global.TransactionTypeEnum.sale || widget.type == global.TransactionTypeEnum.saleorder)
              ? Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showPayDetail = 3;
                            setState(() {});
                          },
                          icon: const Icon(Icons.featured_play_list_outlined),
                          label: Text(
                            global.language("cheque"),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (showPayDetail == 3) ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showPayDetail = 4;
                            setState(() {});
                          },
                          icon: const Icon(Icons.card_giftcard),
                          label: Text(
                            global.language("coupon"),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (showPayDetail == 4) ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showPayDetail = 5;
                            setState(() {});
                          },
                          icon: const Icon(Icons.qr_code),
                          label: Text(
                            global.language("qr_code"),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (showPayDetail == 5) ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Container(),
          (widget.type == global.TransactionTypeEnum.sale || widget.type == global.TransactionTypeEnum.saleorder)
              ? Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showPayDetail = 6;
                            setState(() {});
                          },
                          icon: const Icon(Icons.delivery_dining_rounded),
                          label: Text(
                            global.language("delivery"),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (showPayDetail == 6) ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showPayDetail = 7;
                            setState(() {});
                          },
                          icon: const Icon(Icons.star_rate_rounded),
                          label: Text(
                            'แต้ม',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (showPayDetail == 7) ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(),
                    ),
                  ],
                )
              : Container(),
        ],
      ),
    );
  }

  Widget payCashWidget() {
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16), // Adjust the padding as needed
            child: TextFormField(
              textAlign: TextAlign.center, // Center-align the text
              enabled: (widget.type == global.TransactionTypeEnum.purchasereturn || widget.type == global.TransactionTypeEnum.salereturn)
                  ? screenData.inquirytype != 0 && screenData.inquirytype != 1
                  : screenData.inquirytype != 0,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: global.language("cash"),
              ),
              style: const TextStyle(fontSize: 28), // Adjust the font size as needed
              controller: payCashAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [global.NumberInputFormatter()],
              onChanged: (value) {
                if (value == '' && value.isEmpty) {
                  payCashAmountController.text = "0";
                } else {
                  payCashAmountController.value = TextEditingValue(text: value.toUpperCase(), selection: payCashAmountController.selection);
                }
                _calPayTotal();
              },
            ),
          ),
        ],
      ),
    ));
  }

  Widget payDeliveryWidget() {
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16), // Adjust the padding as needed
            child: TextFormField(
              textAlign: TextAlign.center, // Center-align the text
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: global.language("cash_amount"),
              ),
              style: const TextStyle(fontSize: 28), // Adjust the font size as needed
              controller: payDeliveryCashAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [global.NumberInputFormatter()],
              onChanged: (value) {
                if (value == '' && value.isEmpty) {
                  payDeliveryCashAmountController.text = "0";
                } else {
                  payDeliveryCashAmountController.value = TextEditingValue(text: value.toUpperCase(), selection: payDeliveryCashAmountController.selection);
                }
                _calPayTotal();
              },
            ),
          ),
        ],
      ),
    ));
  }

  Widget payPointWidget() {
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8), // Adjust the padding as needed
            child: TextFormField(
              textAlign: TextAlign.center, // Center-align the text
              readOnly: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'ใช้แต้ม',
              ),
              style: const TextStyle(fontSize: 20), // Adjust the font size as needed
              controller: TextEditingController(text: screenData.usepoint.toString()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [global.NumberInputFormatter()],
            ),
          ),

          /// มูลค่าแต้ม
          Container(
            padding: const EdgeInsets.all(8), // Adjust the padding as needed
            child: TextFormField(
              textAlign: TextAlign.center, // Center-align the text
              readOnly: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'มูลค่าแต้ม',
              ),
              style: const TextStyle(fontSize: 20), // Adjust the font size as needed
              controller: TextEditingController(text: screenData.paypointamount.toString()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [global.NumberInputFormatter()],
            ),
          ),

          /// รหัสสะสมแต้ม
          Container(
            padding: const EdgeInsets.all(8), // Adjust the padding as needed
            child: TextFormField(
              textAlign: TextAlign.center, // Center-align the text
              readOnly: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'รหัสสะสมแต้ม',
              ),
              style: const TextStyle(fontSize: 20), // Adjust the font size as needed
              controller: TextEditingController(text: screenData.pointscode),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [global.NumberInputFormatter()],
            ),
          ),

          /// แต้มที่ได้รับ
          Container(
            padding: const EdgeInsets.all(8), // Adjust the padding as needed
            child: TextFormField(
              textAlign: TextAlign.center, // Center-align the text
              readOnly: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'แต้มที่ได้รับ',
              ),
              style: const TextStyle(fontSize: 20), // Adjust the font size as needed
              controller: TextEditingController(text: screenData.getpoint.toString()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [global.NumberInputFormatter()],
            ),
          ),
        ],
      ),
    ));
  }

  Widget payCreditCardWidget(List<Widget> listCredit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 10, top: 5, bottom: 5),
          child: ElevatedButton.icon(
            onPressed: (screenData.inquirytype != 0)
                ? () {
                    creditCardDateController.add(TextEditingController());
                    payCreditCardAmountController.add(TextEditingController());

                    if (global.profileData.yeartype == "buddhist") {
                      creditCardDateController[creditCardDateController.length - 1].text = global.dateTimeBuddhist(DateTime.now(), format: global.DateTimeFormatEnum.dateDay);
                    } else {
                      creditCardDateController[creditCardDateController.length - 1].text =
                          DateFormat('dd/MM/yyyy').format(DateTime.parse(DateTime.now().toUtc().toIso8601String()));
                    }
                    payCreditCardAmountController[creditCardDateController.length - 1].text = "0";

                    payCreditCard.add(
                      BillPayObjectBoxStruct(
                        trans_flag: 1,
                      ),
                    );

                    setState(() {});
                  }
                : null,
            icon: const Icon(Icons.add),
            label: Text(
              global.language("add_credit"),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(5),
          child: Column(children: listCredit),
        ),
      ],
    );
  }

  Widget payTransferWidget(List<Widget> listTransfer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 10, top: 5, bottom: 5),
          child: ElevatedButton.icon(
            onPressed: (screenData.inquirytype != 0)
                ? () {
                    transferDateController.add(TextEditingController());
                    payTransferAmountController.add(TextEditingController());

                    if (global.profileData.yeartype == "buddhist") {
                      transferDateController[transferDateController.length - 1].text = global.dateTimeBuddhist(DateTime.now(), format: global.DateTimeFormatEnum.dateDay);
                    } else {
                      transferDateController[transferDateController.length - 1].text = DateFormat('dd/MM/yyyy').format(DateTime.parse(DateTime.now().toUtc().toIso8601String()));
                    }
                    payTransferAmountController[transferDateController.length - 1].text = "0";

                    payTransfer.add(
                      BillPayObjectBoxStruct(trans_flag: 2),
                    );

                    setState(() {});
                  }
                : null,
            icon: const Icon(Icons.add),
            label: Text(
              global.language("add_transfer"),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(5),
          child: Column(children: listTransfer),
        ),
      ],
    );
  }

  Widget payChequeWidget(List<Widget> listCheque) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 10, top: 5, bottom: 5),
          child: ElevatedButton.icon(
            onPressed: (screenData.inquirytype != 0)
                ? () {
                    chequeDateController.add(TextEditingController());
                    chequeDueDateDateController.add(TextEditingController());
                    payChequeAmountController.add(TextEditingController());

                    if (global.profileData.yeartype == "buddhist") {
                      chequeDateController[chequeDateController.length - 1].text = global.dateTimeBuddhist(DateTime.now(), format: global.DateTimeFormatEnum.dateDay);
                    } else {
                      chequeDateController[chequeDateController.length - 1].text = DateFormat('dd/MM/yyyy').format(DateTime.parse(DateTime.now().toUtc().toIso8601String()));
                    }

                    if (global.profileData.yeartype == "buddhist") {
                      chequeDueDateDateController[chequeDueDateDateController.length - 1].text = global.dateTimeBuddhist(DateTime.now(), format: global.DateTimeFormatEnum.dateDay);
                    } else {
                      chequeDueDateDateController[chequeDueDateDateController.length - 1].text =
                          DateFormat('dd/MM/yyyy').format(DateTime.parse(DateTime.now().toUtc().toIso8601String()));
                    }

                    payChequeAmountController[chequeDueDateDateController.length - 1].text = "0";

                    payCheque.add(
                      BillPayObjectBoxStruct(
                        trans_flag: 3,
                      ),
                    );
                    setState(() {});
                  }
                : null,
            icon: const Icon(Icons.add),
            label: Text(
              global.language("add_cheque"),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(5),
          child: Column(children: listCheque),
        ),
      ],
    );
  }

  Widget payCouponWidget(List<Widget> listCoupon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// แสดงเฉพาะ คูปองใน pos
        // Container(
        //   margin: const EdgeInsets.only(left: 10, top: 5, bottom: 5),
        //   child: ElevatedButton.icon(
        //     onPressed: (screenData.inquirytype != 0)
        //         ? () {
        //             couponDateController.add(TextEditingController());
        //             payCouponAmountController.add(TextEditingController());

        //             if (global.profileData.yeartype == "buddhist") {
        //               couponDateController[couponDateController.length - 1]
        //                       .text =
        //                   global.dateTimeBuddhist(DateTime.now(),
        //                       format: global.DateTimeFormatEnum.dateDay);
        //             } else {
        //               couponDateController[couponDateController.length - 1]
        //                       .text =
        //                   DateFormat('dd/MM/yyyy').format(DateTime.parse(
        //                       DateTime.now().toUtc().toIso8601String()));
        //             }

        //             payCouponAmountController[couponDateController.length - 1]
        //                 .text = "0";

        //             payCoupon.add(
        //               BillPayObjectBoxStruct(
        //                 trans_flag: 4,
        //               ),
        //             );
        //             setState(() {});
        //           }
        //         : null,
        //     icon: const Icon(Icons.add),
        //     label: Text(
        //       global.language("add_coupon"),
        //     ),
        //   ),
        // ),
        Container(
          padding: const EdgeInsets.all(5),
          child: Column(children: listCoupon),
        ),
      ],
    );
  }

  Widget payQrWidget(List<Widget> listQr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 10, top: 5, bottom: 5),
          child: ElevatedButton.icon(
            onPressed: (screenData.inquirytype != 0)
                ? () {
                    qrDateController.add(TextEditingController());
                    payQrAmountController.add(TextEditingController());

                    if (global.profileData.yeartype == "buddhist") {
                      qrDateController[qrDateController.length - 1].text = global.dateTimeBuddhist(DateTime.now(), format: global.DateTimeFormatEnum.dateDay);
                    } else {
                      qrDateController[qrDateController.length - 1].text = DateFormat('dd/MM/yyyy').format(DateTime.parse(DateTime.now().toUtc().toIso8601String()));
                    }

                    payQrAmountController[qrDateController.length - 1].text = "0";

                    payQr.add(
                      BillPayObjectBoxStruct(
                        trans_flag: 5,
                      ),
                    );
                    setState(() {});
                  }
                : null,
            icon: const Icon(Icons.add),
            label: Text(
              global.language("add_qr"),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(5),
          child: Column(children: listQr),
        ),
      ],
    );
  }

  Widget editProductListWidget() {
    return DocumentProductListWidget(
      screenData: screenData,
      transactionType: widget.type,
      headers: headers,
      warehouseList: warehouseList,
      defualtwarehouse: defualtwarehouse,
      defualtwarehousenames: defualtwarehousenames,
      defualtlocation: defualtlocation,
      defualtlocationnames: defualtlocationnames,
      defualttowarehouse: defualttowarehouse,
      defualttowarehousenames: defualttowarehousenames,
      defualttolocation: defualttolocation,
      defualttolocationnames: defualttolocationnames,
      calcflag: calcflag,
      cartList: cartList,
      setState: setState,
      context: context,
      docrefs: docrefs,
      showWareHouseDefualtDialog: _showWareHouseDefualtDialog,
      showWareHouseLocationDefualtDialog: _showWareHouseLocationDefualtDialog,
      showDialogCommand: showDialogCommand,
      deleteItemDetail: deleteItemDetail,
      setGroupData: setGroupData,
      calTotalValue: _calTotalValue,
      getPrice: _getPrice,
      showBarcodeDialog: () => _showBarcodeDialog(context),
      onWarehouseChanged: (
        String newDefualtwarehouse,
        List<LanguageDataModel> newDefualtwarehousenames,
        String newDefualtlocation,
        List<LanguageDataModel> newDefualtlocationnames,
        String newDefualttowarehouse,
        List<LanguageDataModel> newDefualttowarehousenames,
        String newDefualttolocation,
        List<LanguageDataModel> newDefualttolocationnames,
      ) {
        setState(() {
          defualtwarehouse = newDefualtwarehouse;
          defualtwarehousenames = newDefualtwarehousenames;
          defualtlocation = newDefualtlocation;
          defualtlocationnames = newDefualtlocationnames;
          defualttowarehouse = newDefualttowarehouse;
          defualttowarehousenames = newDefualttowarehousenames;
          defualttolocation = newDefualttolocation;
          defualttolocationnames = newDefualttolocationnames;
        });
      },
    );
  }

  void setGroupData() {
    if (widget.type == global.TransactionTypeEnum.purchasereturn ||
        widget.type == global.TransactionTypeEnum.salereturn ||
        widget.type == global.TransactionTypeEnum.stockreturnproduct ||
        widget.type == global.TransactionTypeEnum.stockreceiveproduct) {
      screenData.details!.sort((a, b) => a.docref!.compareTo(b.docref!));
    }
    setState(() {});
  }

  void addIfNotExists(List list, var item) {
    if (!list.contains(item)) {
      list.add(item);
    }
  }

  Widget editDocumentWidget() {
    return DocumentHeaderWidget(
      screenData: screenData,
      transactionType: widget.type,
      setState: setState,
      context: context,
      custCodeController: custCodeController,
      custnamesController: custnamesController,
      saleCodeController: saleCodeController,
      saleNameController: saleNameController,
      docRefNumberController: docRefNumberController,
      taxDocNoController: taxDocNoController,
      vatRateController: vatRateController,
      descriptionController: descriptionController,
      transportAmountController: transportAmountController,
      docDateController: docDateController,
      docTimeController: docTimeController,
      docDateTimeValidated: docDateTimeValidated,
      debouncer: _debouncer,
      calTotalValue: _calTotalValue,
      headerTableDetail: headerTableDetail,
      searchCustomer: searchCustomer,
      searchSupplier: searchSupplier,
      searchSale: searchSale,
      searchSaleChannel: searchSaleChannel,
    );
  }

  Widget editWidget() {
    List<Widget> tabx = [
      Tab(text: global.language("doc_header")),
      Tab(text: global.language("doc_details")),
    ];
    if (widget.type != global.TransactionTypeEnum.stocktransfer &&
        widget.type != global.TransactionTypeEnum.stockreceiveproduct &&
        widget.type != global.TransactionTypeEnum.stockpickupproduct &&
        widget.type != global.TransactionTypeEnum.stockreturnproduct &&
        widget.type != global.TransactionTypeEnum.adjust &&
        widget.type != global.TransactionTypeEnum.saleorder &&
        widget.type != global.TransactionTypeEnum.purchaseorder &&
        widget.type != global.TransactionTypeEnum.purchasepartial &&
        widget.type != global.TransactionTypeEnum.quotation) {
      tabx.add(Tab(text: global.language("total")));
    }
    List<Widget> childrenx = [
      editDocumentWidget(),
      editProductListWidget(),
    ];
    if (widget.type != global.TransactionTypeEnum.stocktransfer &&
        widget.type != global.TransactionTypeEnum.stockreceiveproduct &&
        widget.type != global.TransactionTypeEnum.stockpickupproduct &&
        widget.type != global.TransactionTypeEnum.stockreturnproduct &&
        widget.type != global.TransactionTypeEnum.adjust &&
        widget.type != global.TransactionTypeEnum.saleorder &&
        widget.type != global.TransactionTypeEnum.purchaseorder &&
        widget.type != global.TransactionTypeEnum.purchasepartial &&
        widget.type != global.TransactionTypeEnum.quotation) {
      childrenx.add(editSummeryWidget());
    }
    return Scaffold(
        appBar: AppBar(
          backgroundColor: global.theme.appBarColor,
          automaticallyImplyLeading: false,
          title: TabBar(
            controller: editTabController,
            tabs: tabx,
          ),
        ),
        body: RawKeyboardListener(
            focusNode: FocusNode(skipTraversal: true),
            onKey: (event) async {
              if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
                if (event is RawKeyUpEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.f10) {
                    if (screenData.details!.isNotEmpty) {
                      final result = await _showAlertConfirmSaveDialog(context, screenData.guidfixed ?? '');
                      if (result != null && result) {
                        saveOrUpdateData(taxInvoice: false);
                      }
                    }
                  }
                }
              }
            },
            child: TabBarView(controller: editTabController, children: childrenx)));
  }

  void deleteDoc() {
    context.read<TransBloc>().add(TransDelete(guid: screenData.guidfixed!, type: widget.type));
  }

  void saveOrUpdateData({required bool taxInvoice}) {
    // คำนวณใหม่
    if (widget.type != global.TransactionTypeEnum.adjust) {
      _calTotalValue();
    }

    if (verifyPayment()) {
      DateTime docDatetimeUtc = DateTime.parse(screenData.docdatetime);
      screenData.docdatetime = docDatetimeUtc.toUtc().toIso8601String();
      DateTime docRefDatetimeUtc = DateTime.parse(screenData.docrefdate);
      screenData.docrefdate = docRefDatetimeUtc.toUtc().toIso8601String();
      DateTime taxDocDatetimeUtc = DateTime.parse(screenData.taxdocdate);
      screenData.taxdocdate = taxDocDatetimeUtc.toUtc().toIso8601String();

      for (var data in screenData.details!) {
        data.linenumber = screenData.details!.indexOf(data) + 1;

        data.docdatetime = screenData.docdatetime;

        DateTime docrefdatetimeDetailUtc = DateTime.parse(data.docrefdatetime!);
        data.docrefdatetime = docrefdatetimeDetailUtc.toUtc().toIso8601String();

        ///   ดึงตัวตั้งตัวหารจาก บาร์โค้ดอ้างอิง
        if (data.itemtype == 0 && data.refbarcodes!.isNotEmpty) {
          for (var element in data.refbarcodes!) {
            data.standvalue = element.standvalue;
            data.dividevalue = element.dividevalue;
          }
        }
      }

      screenData.billpayobjectboxstruct = [];

      if (payTransfer.isNotEmpty) {
        screenData.billpayobjectboxstruct!.addAll(payTransfer);
      }

      if (payCheque.isNotEmpty) {
        screenData.billpayobjectboxstruct!.addAll(payCheque);
      }

      if (payCoupon.isNotEmpty) {
        screenData.billpayobjectboxstruct!.addAll(payCoupon);
      }

      if (payQr.isNotEmpty) {
        screenData.billpayobjectboxstruct!.addAll(payQr);
      }

      if (payCreditCard.isNotEmpty) {
        screenData.billpayobjectboxstruct!.addAll(payCreditCard);
      }

      screenData.paymentdetailraw = jsonEncode(screenData.billpayobjectboxstruct);

      if (screenData.ispos! && screenData.iscancel) {
        screenData = screenDataTemp;
      }

      /// ออกใบกำกับภาษีแบบเต็ม
      if (taxInvoice == true) {
        // ใช้ Event ใหม่สำหรับการสร้างใบกำกับภาษีแบบเต็ม
        context.read<TransBloc>().add(TransCreateFullInvoice(
              guid: screenData.guidfixed!,
              trans: screenData,
              type: widget.type,
            ));
      } else {
        if (screenData.guidfixed != '') {
          context.read<TransBloc>().add(TransUpdate(
                guid: screenData.guidfixed!,
                trans: screenData,
                type: widget.type,
              ));
        } else {
          context.read<TransBloc>().add(TransSave(trans: screenData, type: widget.type));
        }
      }
    }
  }

  bool verifyPayment() {
    if (screenData.iscancel) {
      return true;
    }

    List<String> errorList = [];

    // เพิ่มการตรวจสอบ custcode เมื่อ inquirytype == 0
    if (screenData.inquirytype == 0 && screenData.custcode.trim().isEmpty) {
      if (widget.type == global.TransactionTypeEnum.sale || widget.type == global.TransactionTypeEnum.saleorder || widget.type == global.TransactionTypeEnum.salereturn) {
        errorList.add(global.language("please_input_custcode_debtor"));
      } else if (widget.type == global.TransactionTypeEnum.purchase ||
          widget.type == global.TransactionTypeEnum.purchaseorder ||
          widget.type == global.TransactionTypeEnum.purchasereturn ||
          widget.type == global.TransactionTypeEnum.purchasepartial) {
        errorList.add(global.language("please_input_custcode_creditor"));
      }
    }

    // ถ้าเป็น purchaseorder หรือ saleorder และไม่มี error จาก custcode ให้ return true ทันที
    if (widget.type == global.TransactionTypeEnum.purchaseorder ||
        widget.type == global.TransactionTypeEnum.saleorder ||
        widget.type == global.TransactionTypeEnum.purchasepartial) {
      if (errorList.isNotEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Center(
              child: AlertDialog(
                title: Text(global.language("not_success_save")),
                content: Text(errorList.join(", ")),
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
        return false;
      } else {
        return true;
      }
    }

    // ตรวจสอบการชำระเงินสำหรับ transaction type อื่นๆ
    double totalWithRound = double.parse(screenData.totalamount.toStringAsFixed(2)) + double.parse(screenData.roundamount!.toString());

    if (widget.type == global.TransactionTypeEnum.purchasereturn || widget.type == global.TransactionTypeEnum.salereturn) {
      if (payTotalBill > totalWithRound && screenData.inquirytype == 2 && screenData.inquirytype == 3) {
        errorList.add(global.language("payment_over"));
      } else if (payTotalBill < (totalWithRound) && screenData.inquirytype == 2 && screenData.inquirytype == 3) {
        errorList.add(global.language("payment_less"));
      }
    } else {
      if (widget.type != global.TransactionTypeEnum.stockpickupproduct) {
        if (payTotalBill > totalWithRound && screenData.inquirytype == 1) {
          errorList.add(global.language("payment_over"));
        } else if (payTotalBill < (totalWithRound) && screenData.inquirytype == 1) {
          errorList.add(global.language("payment_less"));
        }
      }
    }

    if (errorList.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Center(
            child: AlertDialog(
              title: Text(global.language("not_success_save")),
              content: Text(errorList.join(", ")),
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
      return false;
    } else {
      return true;
    }
  }

  void showDialogCommand(String cmd, int index, TransactionDetailModel details) async {
    if (cmd == 'barcode') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => BarcodeSearchScreen(
                    word: details.barcode,
                    screen: (widget.type == global.TransactionTypeEnum.sale ||
                            widget.type == global.TransactionTypeEnum.saleorder ||
                            widget.type == global.TransactionTypeEnum.salereturn)
                        ? 'not_material'
                        : 'material',
                  ))).then((value) {
        ProductBarcodeModel result = value;
        if (result.barcode!.trim().isNotEmpty) {
          setState(() {
            screenData.details![index].itemguid = result.guidfixed;
            screenData.details![index].barcode = result.barcode!;
            screenData.details![index].itemcode = result.itemcode ?? "";
            screenData.details![index].itemnames = result.names;
            screenData.details![index].multiunit = true;
            screenData.details![index].unitcode = result.itemunitcode;
            screenData.details![index].dividevalue = result.dividevalue!;
            screenData.details![index].standvalue = result.standvalue!;
            screenData.details![index].unitnames = result.itemunitnames;
            screenData.details![index].whcode = defualtwarehouse;
            screenData.details![index].whnames = defualtwarehousenames;
            screenData.details![index].locationcode = defualtlocation;
            screenData.details![index].locationnames = defualtlocationnames;
            screenData.details![index].towhcode = defualttowarehouse;
            screenData.details![index].towhnames = defualttowarehousenames;
            screenData.details![index].tolocationcode = defualttolocation;
            screenData.details![index].tolocationnames = defualttolocationnames;
            screenData.details![index].taxtype = result.taxtype!;
            screenData.details![index].qty = 1;
            screenData.details![index].vatcal = result.vatcal;
            screenData.details![index].price = _getPrice(result.prices);
            screenData.details![index].manufacturerguid = result.manufacturerguid;
          });

          _calTotalValue();
        }
      });
    } else if (cmd == 'item_code') {
      // เพิ่ม case สำหรับ item_code
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => BarcodeSearchScreen(
                    word: details.itemcode, // ส่ง itemcode แทน barcode
                    screen: (widget.type == global.TransactionTypeEnum.sale ||
                            widget.type == global.TransactionTypeEnum.saleorder ||
                            widget.type == global.TransactionTypeEnum.salereturn)
                        ? 'not_material'
                        : 'material',
                  ))).then((value) {
        ProductBarcodeModel result = value;
        if (result.barcode!.trim().isNotEmpty) {
          setState(() {
            screenData.details![index].itemguid = result.guidfixed;
            screenData.details![index].barcode = result.barcode!;
            screenData.details![index].itemcode = result.itemcode ?? "";
            screenData.details![index].itemnames = result.names;
            screenData.details![index].multiunit = true;
            screenData.details![index].unitcode = result.itemunitcode;
            screenData.details![index].dividevalue = result.dividevalue!;
            screenData.details![index].standvalue = result.standvalue!;
            screenData.details![index].unitnames = result.itemunitnames;
            screenData.details![index].whcode = defualtwarehouse;
            screenData.details![index].whnames = defualtwarehousenames;
            screenData.details![index].locationcode = defualtlocation;
            screenData.details![index].locationnames = defualtlocationnames;
            screenData.details![index].towhcode = defualttowarehouse;
            screenData.details![index].towhnames = defualttowarehousenames;
            screenData.details![index].tolocationcode = defualttolocation;
            screenData.details![index].tolocationnames = defualttolocationnames;
            screenData.details![index].taxtype = result.taxtype!;
            screenData.details![index].qty = 1;
            screenData.details![index].vatcal = result.vatcal;
            screenData.details![index].price = _getPrice(result.prices);
            screenData.details![index].manufacturerguid = result.manufacturerguid;
          });

          _calTotalValue();
        }
      });
    } else if (cmd == 'product_name') {
      /// dialog description
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Center(
            child: AlertDialog(
              title: Text(global.language("description")),
              content: TextField(
                controller: TextEditingController(text: details.description),
                onChanged: (value) {
                  screenData.details![index].description = value;
                },
              ),
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
    } else if (cmd == 'product_ware_house') {
      if (details.itemguid.trim().isNotEmpty) {
        WarehouseModel? result = await _showWareHouseDialog(context, details.itemguid, warehouseList) ?? WarehouseModel(guidfixed: '', code: '');
        if (result.code.isNotEmpty) {
          setState(() {
            screenData.details![index].whcode = result.code;
            screenData.details![index].whnames = result.names;

            if (result.location.isNotEmpty) {
              screenData.details![index].locationcode = result.location[0].code;
              screenData.details![index].locationnames = result.location[0].names;
            } else {
              screenData.details![index].locationcode = "";
              screenData.details![index].locationnames = [];
            }
          });
        }
      }
    } else if (cmd == 'product_location') {
      if (details.itemguid.trim().isNotEmpty && details.whcode.trim().isNotEmpty) {
        LocationModel? result = await _showWareHouseLocationDialog(context, details.itemguid, details.whcode) ?? LocationModel(code: '');
        if (result.code.isNotEmpty) {
          setState(() {
            screenData.details![index].locationcode = result.code;
            screenData.details![index].locationnames = result.names;
          });
        }
      }
    } else if (cmd == 'product_to_ware_house') {
      if (details.itemguid.trim().isNotEmpty) {
        WarehouseModel? result = await _showWareHouseDialog(context, details.itemguid, warehouseList) ?? WarehouseModel(guidfixed: '', code: '');
        if (result.code.isNotEmpty) {
          setState(() {
            screenData.details![index].towhcode = result.code;
            screenData.details![index].towhnames = result.names;

            if (result.location.isNotEmpty) {
              screenData.details![index].tolocationcode = result.location[0].code;
              screenData.details![index].tolocationnames = result.location[0].names;
            } else {
              screenData.details![index].tolocationcode = "";
              screenData.details![index].tolocationnames = [];
            }
          });
        }
      }
    } else if (cmd == 'product_to_location') {
      if (details.itemguid.trim().isNotEmpty && details.towhcode!.trim().isNotEmpty) {
        LocationModel? result = await _showWareHouseLocationDialog(context, details.itemguid, details.towhcode!) ?? LocationModel(code: '');
        if (result.code.isNotEmpty) {
          setState(() {
            screenData.details![index].tolocationcode = result.code;
            screenData.details![index].tolocationnames = result.names;
          });
        }
      }
    } else if (cmd == 'product_unit') {
      if (details.itemguid.trim().isNotEmpty && details.multiunit == true) {
        ProductBarcodeModel? result = await _showUnitsDialog(context, details.itemguid) ?? ProductBarcodeModel(guidfixed: '');

        if (result.guidfixed.isNotEmpty) {
          screenData.details![index].docdatetime = DateTime.now().toLocal().toIso8601String();
          screenData.details![index].itemguid = result.guidfixed;
          screenData.details![index].barcode = result.barcode!;
          screenData.details![index].itemcode = result.itemcode ?? "";
          screenData.details![index].itemnames = result.names;
          screenData.details![index].unitcode = result.itemunitcode;
          screenData.details![index].qty = 1;
          screenData.details![index].price = _getPrice(result.prices);
          screenData.details![index].discount = '';
          screenData.details![index].sumofcost = 0;
          screenData.details![index].sumamount = 0;
          screenData.details![index].remark = '';
          screenData.details![index].linenumber = 0;
          screenData.details![index].shelfcode = '';
          screenData.details![index].totalvaluevat = 0;
          screenData.details![index].totalqty = 0;
          screenData.details![index].standvalue = result.standvalue!;
          screenData.details![index].dividevalue = result.dividevalue!;
          screenData.details![index].multiunit = true;
          screenData.details![index].unitnames = result.itemunitnames;
          screenData.details![index].calcflag = calcflag;
          screenData.details![index].vattype = 0;
          screenData.details![index].averagecost = 0;
          screenData.details![index].sumamountexcludevat = 0;
          screenData.details![index].discountamount = 0;
          screenData.details![index].ispos = 0;
          screenData.details![index].laststatus = 0;
          screenData.details![index].itemtype = 0;
          screenData.details![index].inquirytype = 0;
          screenData.details![index].priceexcludevat = 0;
          screenData.details![index].taxtype = result.taxtype!;
          screenData.details![index].vatcal = result.vatcal;
          screenData.details![index].towhcode = defualttowarehouse;
          screenData.details![index].towhnames = defualttowarehousenames;
          screenData.details![index].tolocationcode = defualttolocation;
          screenData.details![index].tolocationnames = defualtlocationnames;

          setGroupData();
          _calTotalValue();
          setState(() {});
        }
      }
    } else if (cmd == 'product_qty') {
      String? result = await _showQtyDialog(context, details.qty, global.activeLangName(details.itemnames!)) ?? screenData.details![index].qty.toString();
      final numbercheck = result.replaceAll(',', '');
      setState(() {
        screenData.details![index].qty = double.parse(numbercheck);
        _calTotalValue();
      });
    } else if (cmd == 'product_price' || cmd == 'product_price_adjust') {
      String? result = await _showPriceDialog(context, details.price, global.activeLangName(details.itemnames!)) ?? screenData.details![index].price.toString();
      final numbercheck = result.replaceAll(',', '');
      setState(() {
        screenData.details![index].sumamount = double.parse(numbercheck);
        _calTotalValue();
      });
    } else if (cmd == 'product_discount') {
      String? result = await _showDiscountDialog(context, details.discount, global.activeLangName(details.itemnames!)) ?? screenData.details![index].discount.toString();

      String numbercheck = result.replaceAll(',', '');

      screenData.details![index].discount = numbercheck;

      setState(() {
        _calTotalValue();
      });
    } else if (cmd == 'product_amount') {
      // เพิ่ม case สำหรับ product_amount โดยเฉพาะสำหรับ stockreceiveproduct
      if (widget.type == global.TransactionTypeEnum.stockreceiveproduct ||
          widget.type == global.TransactionTypeEnum.purchase ||
          widget.type == global.TransactionTypeEnum.purchaseorder ||
          widget.type == global.TransactionTypeEnum.purchasepartial ||
          widget.type == global.TransactionTypeEnum.accrualreceive ||
          widget.type == global.TransactionTypeEnum.adjust) {
        String? result = await _showAmountDialog(context, details.sumamount, global.activeLangName(details.itemnames!)) ?? screenData.details![index].sumamount.toString();
        final numbercheck = result.replaceAll(',', '');
        setState(() {
          screenData.details![index].sumamount = double.parse(numbercheck);
        });
      }
    }
  }

  Future<String?> _showAmountDialog(BuildContext context, double currentAmount, String itemnames) async {
    TextEditingController amount = TextEditingController();

    if (currentAmount > 0) {
      amount.text = currentAmount.toString();
    } else {
      amount.text = "";
    }
    return showDialog<String?>(
      context: context,
      barrierDismissible: true, // Allows tapping outside the dialog to close it
      builder: (BuildContext context) {
        // เลือกข้อความทั้งหมดหลังจาก widget สร้างเสร็จ
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (amount.text.isNotEmpty) {
            amount.selection = TextSelection(baseOffset: 0, extentOffset: amount.text.length);
          }
        });

        return AlertDialog(
          title: Text('$itemnames ${global.language("amount")}'),
          content: SizedBox(
            width: (global.isMobileScreen(context)) ? 350 : 400,
            child: TextField(
              autofocus: true,
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [global.NumberInputFormatter()],
              decoration: InputDecoration(
                labelText: global.language("amount"),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {
                    amount.clear();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
              onSubmitted: (value) {
                Navigator.pop(context, amount.text);
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(global.language("close")),
              onPressed: () {
                Navigator.pop(context, currentAmount.toString());
              },
            ),
            TextButton(
              child: Text(global.language("update")),
              onPressed: () {
                Navigator.pop(context, amount.text);
              },
            ),
          ],
        );
      },
    );
  }

  void deleteItemDetail(int index) {
    setState(() {
      screenData.details!.removeAt(index);
    });

    // ลบ มูลค่าเดิม , ผลต่าง , ผลต่างที่ถูกต้อง ตามเอกสารอ้างอิงที่มีใน Details
    if (widget.type == global.TransactionTypeEnum.salereturn ||
        widget.type == global.TransactionTypeEnum.purchasereturn ||
        widget.type == global.TransactionTypeEnum.sale ||
        widget.type == global.TransactionTypeEnum.purchase ||
        widget.type == global.TransactionTypeEnum.purchasepartial ||
        widget.type == global.TransactionTypeEnum.accrualreceive) {
      List<String> docrefsdetail = [];
      for (var val in screenData.details!) {
        if (val.docref!.isNotEmpty) {
          addIfNotExists(docrefsdetail, val.docref!);
        }
      }
      var docrefsremove = docrefs.where((element) => !docrefsdetail.contains(element['docref'])).toList();
      docrefs = docrefs.where((element) => docrefsdetail.contains(element['docref'])).toList();

      if (docrefsremove.isNotEmpty) {
        for (var val in docrefsremove) {
          screenData.reftotaloriginal = (screenData.reftotaloriginal! - val['totaloriginal']);
        }
        if (screenData.details!.isEmpty) {
          screenData.reftotaldiff = 0;
          screenData.reftotalcorrect = 0;
        }
      }
    }

    Future.delayed(const Duration(milliseconds: 200), () {
      _calTotalValue();
    });
  }

  void _calTotalValue() {
    double totalValue = 0;
    double totalQty = 0;
    String detaildiscountformulaData = "";
    String discountWordData = "";

    /// รวมสินค้ามีภาษี
    double totalAmountVatCale0 = 0;

    /// รวมสินค้ายกเว้นภาษี
    double totalAmountVatCale1 = 0;

    if (screenData.details!.isEmpty) {
      screenData.totalvalue = 0;
      screenData.totalqty = 0;
      screenData.detailtotaldiscount = 0;
      screenData.totaldiscountvatamount = 0;
      screenData.totaldiscountexceptvatamount = 0;
      screenData.totalbeforevat = 0;
      screenData.totalvatvalue = 0;
      screenData.totalaftervat = 0;
      screenData.totalexceptvat = 0;
      screenData.detailtotalamount = 0;
      screenData.totalamountafterdiscount = 0;
      screenData.totalamount = 0;
      screenData.discountword = "0";
      screenData.totaldiscount = 0;

      discountWordController.text = "0";
      detaildiscountformulaController.text = "0";

      setState(() {});
      return;
    }

    /// คำนวนพี่ฟิช
    screenData = calAmount.calTotalValue(screenData);

    for (var val in screenData.details!) {
      if (val.vatcal == 0) {
        totalAmountVatCale0 += val.sumamount;
      } else if (val.vatcal == 1) {
        totalAmountVatCale1 += val.sumamount;
      }

      totalValue += val.sumamount;
      totalQty += val.qty;
    }

    if (detaildiscountformulaController.text.isNotEmpty) {
      detaildiscountformulaData = detaildiscountformulaController.text;
    } else {
      detaildiscountformulaData = "0";
    }

    if (discountWordController.text.isNotEmpty) {
      discountWordData = discountWordController.text;
    } else {
      discountWordData = "0";
    }

    /// ส่วนลดก่อนชำระเงิน
    if (detaildiscountformulaData.contains('%')) {
      String detaildiscountformula = detaildiscountformulaData.replaceAll('%', '');
      screenData.detailtotaldiscount = double.parse(((totalValue * double.parse(detaildiscountformula)) / 100).toStringAsFixed(2));
    } else if (detaildiscountformulaData.replaceAll(',', '').trim().isNotEmpty) {
      screenData.detailtotaldiscount = double.parse(detaildiscountformulaData.replaceAll(',', '').trim());
    }

    screenData.totalqty = totalQty;

    /// ส่วนลดสินค้ามีภาษี
    screenData.totaldiscountvatamount = ((screenData.detailtotaldiscount! * totalAmountVatCale0) / screenData.totalvalue);

    screenData.totaldiscountvatamount = double.parse(screenData.totaldiscountvatamount!.toStringAsFixed(2));

    if (screenData.totaldiscountvatamount!.isNaN) {
      screenData.totaldiscountvatamount = 0;
    }

    /// ส่วนลดสินค้ายกเว้นภาษี
    screenData.totaldiscountexceptvatamount = screenData.detailtotaldiscount! - screenData.totaldiscountvatamount!;

    screenData.totaldiscountexceptvatamount = double.parse(screenData.totaldiscountexceptvatamount!.toStringAsFixed(2));

    if (screenData.totaldiscountexceptvatamount!.isNaN) {
      screenData.totaldiscountexceptvatamount = 0;
    }

    ///  0 = แยกนอก , 1 = รวมใน
    if (screenData.vattype == 0) {
      /// ยอดก่อนภาษี
      screenData.totalbeforevat = double.parse((totalAmountVatCale0 - screenData.totaldiscountvatamount!).toStringAsFixed(2));

      /// ภาษีมูลค่าเพิ่ม
      screenData.totalvatvalue = double.parse((screenData.totalbeforevat * (screenData.vatrate / 100)).toStringAsFixed(2));
    } else if (screenData.vattype == 1) {
      /// ภาษีมูลค่าเพิ่ม
      screenData.totalvatvalue =
          double.parse((((totalAmountVatCale0 - screenData.totaldiscountvatamount!) * (screenData.vatrate) / (100 + screenData.vatrate))).toStringAsFixed(2));

      /// ยอดก่อนภาษี
      screenData.totalbeforevat =
          double.parse(((totalAmountVatCale0 - screenData.totaldiscountvatamount!) - double.parse(screenData.totalvatvalue.toStringAsFixed(2))).toStringAsFixed(2));
    } else {
      /// ยอดก่อนภาษี
      screenData.totalbeforevat = double.parse((totalAmountVatCale0 - screenData.totaldiscountvatamount!).toStringAsFixed(2));

      /// ภาษีมูลค่าเพิ่ม
      screenData.totalvatvalue = 0;
    }

    if (screenData.totalbeforevat.isNaN) {
      screenData.totalbeforevat = 0;
    }

    if (screenData.totalvatvalue.isNaN) {
      screenData.totalvatvalue = 0;
    }

    /// ยอดรวมสินค้ามีภาษี
    screenData.totalaftervat = double.parse((screenData.totalbeforevat + screenData.totalvatvalue).toStringAsFixed(2));

    if (screenData.totalaftervat.isNaN) {
      screenData.totalaftervat = 0;
    }

    /// ยอดรวมสินค้ายกเว้นภาษี
    screenData.totalexceptvat = totalAmountVatCale1 - screenData.totaldiscountexceptvatamount!;

    if (screenData.totalexceptvat.isNaN) {
      screenData.totalexceptvat = 0;
    }

    /// ยอดรวมก่อนหักส่วนลดท้ายบิล
    screenData.detailtotalamount = double.parse((screenData.totalaftervat + screenData.totalexceptvat).toStringAsFixed(2));
    if (screenData.detailtotalamount!.isNaN) {
      screenData.detailtotalamount = 0;
    }

    /// ส่วนลดท้ายบิล

    if (discountWordData.contains('%')) {
      String discount = discountWordData.replaceAll('%', '');
      screenData.totaldiscount = double.parse(((screenData.detailtotalamount! * double.parse(discount)) / 100).toStringAsFixed(2));
    } else if (discountWordData.trim().isNotEmpty) {
      screenData.totaldiscount = double.parse(discountWordData.trim());
    }

    /// ยอดรวมทั้งสิ้น
    screenData.totalamountafterdiscount = double.parse((screenData.detailtotalamount! - screenData.totaldiscount).toStringAsFixed(2));
    if (screenData.totalamountafterdiscount!.isNaN) {
      screenData.totalamountafterdiscount = 0;
    }

    /// ยอดรวมสุทธิ
    screenData.totalamount = double.parse((screenData.detailtotalamount! - screenData.totaldiscount).toStringAsFixed(2));
    if (screenData.totalamount.isNaN) {
      screenData.totalamount = 0;
    }

    // if (screenData.totaldiscount > screenData.totalvalue) {
    //   screenData.totaldiscount = screenData.totalvalue;
    //   screenData.discountword = screenData.totalvalue.toString();
    //   docDiscountWordController.text = screenData.totalvalue.toString();

    //   _showAlertDiscountDialog(context);
    // }

    /// คำนวณผลต่างจากเอกสารเดิม
    if (widget.type == global.TransactionTypeEnum.salereturn || widget.type == global.TransactionTypeEnum.purchasereturn) {
      screenData.reftotaldiff = (screenData.totalbeforevat + screenData.totalexceptvat);
      screenData.reftotalcorrect = screenData.reftotaloriginal! - screenData.reftotaldiff!;
    }

    setState(() {});
  }

  void _calPayTotal() {
    double totalPayCash = 0;
    double totalPayDelivery = 0;
    double roundAmount = 0;
    double totalPayCreditCard = 0;
    double totalPayTransfer = 0;
    double totalPayCheque = 0;
    double totalPayCoupon = 0;
    double totalQr = 0;

    totalPayCash = double.parse(payCashAmountController.text.replaceAll(',', ''));
    totalPayDelivery = double.parse(payDeliveryCashAmountController.text.replaceAll(',', ''));

    roundAmount = double.parse(roundAmountController.text.replaceAll(',', ''));

    if (payTransferAmountController.isNotEmpty) {
      for (var element in payTransferAmountController) {
        totalPayTransfer += double.parse((element.text.isNotEmpty) ? element.text.replaceAll(',', '') : "0");
      }
    }

    if (payCreditCardAmountController.isNotEmpty) {
      for (var element in payCreditCardAmountController) {
        totalPayCreditCard += double.parse((element.text.isNotEmpty) ? element.text.replaceAll(',', '') : "0");
      }
    }

    for (var element in payChequeAmountController) {
      totalPayCheque += double.parse((element.text.isNotEmpty) ? element.text.replaceAll(',', '') : "0");
    }

    for (var element in payCouponAmountController) {
      totalPayCoupon += double.parse((element.text.isNotEmpty) ? element.text.replaceAll(',', '') : "0");
    }

    for (var element in payQrAmountController) {
      totalQr += double.parse((element.text.isNotEmpty) ? element.text.replaceAll(',', '') : "0");
    }

    screenData.paycashamount = totalPayCash;
    screenData.deliveryamount = totalPayDelivery;
    screenData.summoneytransfer = totalPayTransfer;
    screenData.sumcreditcard = totalPayCreditCard;
    screenData.sumcheque = totalPayCheque;
    screenData.sumcoupon = totalPayCoupon;
    screenData.sumqrcode = totalQr;
    screenData.roundamount = roundAmount;
    payTotalBill =
        totalPayCash + totalPayTransfer + totalPayCreditCard + totalPayCheque + totalPayCoupon + totalQr + screenData.sumcredit! + totalPayDelivery + screenData.paypointamount!;

    setState(() {});
  }

  void searchSale({required String word}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EmployeeSearchScreen(
                  word: word,
                ))).then((value) {
      EmployeeModel result = value;
      if (result.code.trim().isNotEmpty) {
        setState(() {
          saleCodeController.text = result.code;
          saleNameController.text = result.name;

          screenData.salecode = result.code;
          screenData.salename = result.name;
        });
      }
    });
  }

  /// searchSaleChannel
  void searchSaleChannel({required String word}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SalechannelsSearchScreen(
                  word: word,
                ))).then((value) {
      SaleChannelModel result = value;
      if (result.code!.trim().isNotEmpty) {
        setState(() {
          screenData.salechannelcode = result.code;
          screenData.salechannelgp = result.gp!;
          screenData.salechannelgptype = result.gptype!;
        });
      }
    });
  }

  /// searchTransport
  void searchTransport({required String word}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TransportSearchScreen(
                  word: word,
                ))).then((value) {
      TransportChannelModel result = value;
      if (result.code.trim().isNotEmpty) {
        setState(() {
          screenData.transportcode = result.code;
        });
      }
    });
  }

  void searchDocRef() {
    global.TransactionTypeEnum searchDocRefType = global.TransactionTypeEnum.purchase;
    String currentDocNo = screenData.docno;
    String currentDocDocDate = screenData.docdatetime;
    String currentGuidFixed = screenData.guidfixed!;
    if (widget.type == global.TransactionTypeEnum.purchasereturn) {
      searchDocRefType = global.TransactionTypeEnum.purchase;
    } else if (widget.type == global.TransactionTypeEnum.salereturn) {
      searchDocRefType = global.TransactionTypeEnum.sale;
    } else if (widget.type == global.TransactionTypeEnum.stockreturnproduct) {
      searchDocRefType = global.TransactionTypeEnum.stockpickupproduct;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TransSearchScreen(
                  custcode: screenData.custcode,
                  type: searchDocRefType,
                ))).then((value) {
      TransactionModel result = value;
      if (result.docno.isNotEmpty) {
        String docRef = result.docno;
        String docRefDate = result.docdatetime;
        screenData = result;
        screenData.guidfixed = currentGuidFixed;
        screenData.docno = currentDocNo;
        screenData.docdatetime = currentDocDocDate;
        screenData.docrefno = docRef;
        screenData.docrefdate = docRefDate;

        setState(() {});

        loadDataToScreen();
      }
    });
  }

  void searchTrans() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TransSearchScreen(
                  custcode: '',
                  type: widget.type,
                ))).then((value) {
      TransactionModel result = value;
      if (result.docno.isNotEmpty) {
        setState(() {
          DateTime localDateTime = DateTime.parse(result.docdatetime);
          screenData = result;
          // Store the initial copy in screenDataTemp to keep it unchanged
          screenDataTemp = result.copyWith(
            details: result.details?.map((detail) => detail.copyWith()).toList(),
            paymentdetail: result.paymentdetail?.copyWith(),
            billpayobjectboxstruct: result.billpayobjectboxstruct?.map((struct) => struct.copyWith()).toList(),
          );

          /// sort  linenumber
          screenData.details!.sort((a, b) => a.linenumber.compareTo(b.linenumber));
          screenData.docdatetime = localDateTime.toLocal().toIso8601String();
          showPayDetail == 0;

          loadDataToScreen();

          /// set index tabController to 0
          // editTabController.animateTo(0);
        });
      }
    });
  }

  void searchCustomer({required String word}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CustomerSearchScreen(
                  word: word,
                ))).then((value) {
      global.SearchDebtorModel result = value;
      if (result.code.trim().isNotEmpty) {
        // ตรวจสอบว่ามีรายการสินค้าอยู่แล้วและรหัสลูกค้าใหม่แตกต่างจากเดิมหรือไม่
        if (screenData.details!.isNotEmpty && custCodeController.text.trim() != result.code.trim()) {
          // แสดงข้อความแจ้งเตือน
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(global.language("alert")),
                content: const Text("มีการแก้ไขรหัสลูกค้า อาจจะทำให้ราคาสินค้าผิดพลาด"),
                actions: [
                  TextButton(
                    child: Text(global.language("cancel")),
                    onPressed: () {
                      Navigator.of(context).pop();
                      // ไม่ทำอะไรถ้าผู้ใช้กด cancel
                    },
                  ),
                  TextButton(
                    child: Text(global.language("confirm")),
                    onPressed: () {
                      Navigator.of(context).pop();
                      // ดำเนินการต่อเมื่อผู้ใช้กด confirm
                      _updateCustomerData(result);
                    },
                  ),
                ],
              );
            },
          );
        } else {
          // ถ้าไม่มีรายการสินค้าหรือรหัสลูกค้าเดิม ให้ดำเนินการปกติ
          _updateCustomerData(result);
        }
      }
    });
  }

// แยกส่วนการอัพเดทข้อมูลลูกค้าออกมาเป็นฟังก์ชันแยก
  void _updateCustomerData(global.SearchDebtorModel result) {
    setState(() {
      // เก็บ pricelevel ของลูกค้าที่เลือก
      customerPriceLevel = (result.pricelevel.isNotEmpty) ? int.parse(result.pricelevel) : 1;

      if (widget.type == global.TransactionTypeEnum.purchasereturn || widget.type == global.TransactionTypeEnum.salereturn) {
        if (screenData.details!.isNotEmpty) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Center(
                child: AlertDialog(
                  content: Text(global.language("remove_all_detail")),
                  actions: [
                    TextButton(
                      child: Text(global.language("cancel")),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text(
                        global.language("confirm"),
                        style: const TextStyle(color: Colors.red),
                      ),
                      onPressed: () {
                        screenData.discountword = '';
                        screenData.totalcost = 0;
                        screenData.totalvalue = 0;
                        screenData.totaldiscount = 0;
                        screenData.totalvatvalue = 0;
                        screenData.totalaftervat = 0;
                        screenData.totalexceptvat = 0;
                        screenData.totalamount = 0;
                        screenData.totalbeforevat = 0;
                        screenData.details = <TransactionDetailModel>[];
                        screenData.ismanualamount = false;
                        screenData.paymentdetailraw = "";
                        screenData.billpayobjectboxstruct = [];
                        screenData.reftotaloriginal = 0;
                        screenData.reftotalcorrect = 0;
                        screenData.reftotaldiff = 0;

                        custCodeController.text = result.code;
                        custnamesController.text = global.activeLangName(result.names);
                        screenData.custcode = result.code;
                        screenData.custnames = result.names;
                        _calTotalValue();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        } else {
          custCodeController.text = result.code;
          custnamesController.text = global.activeLangName(result.names);
          screenData.custcode = result.code;
          screenData.custnames = result.names;

          // อัพเดทราคาสินค้าที่มีอยู่แล้วตาม pricelevel ใหม่
          _updateExistingProductPrices();
        }
      } else {
        custCodeController.text = result.code;
        custnamesController.text = global.activeLangName(result.names);
        screenData.custcode = result.code;
        screenData.custnames = result.names;

        // อัพเดทราคาสินค้าที่มีอยู่แล้วตาม pricelevel ใหม่
        _updateExistingProductPrices();
      }
    });
  }

  void _updateExistingProductPrices() {
    for (int i = 0; i < screenData.details!.length; i++) {
      if (screenData.details![i].itemguid.isNotEmpty) {
        // ใช้ getProductBarcodeDetail แทน getByGuid
        _productBarcodeRepository.getProductBarcodeDetail(screenData.details![i].barcode).then((response) {
          if (response.success && response.data != null) {
            ProductBarcodeModel product = ProductBarcodeModel.fromJson(response.data);
            double newPrice = _getPrice(product.prices);

            setState(() {
              screenData.details![i].price = newPrice;
              // คำนวณยอดรวมใหม่สำหรับรายการนี้
              screenData.details![i].sumamount = screenData.details![i].qty * newPrice;
              _calTotalValue();
            });
          }
        }).catchError((error) {
          // จัดการ error ถ้าดึงข้อมูลไม่สำเร็จ
          if (kDebugMode) {
            print('Error updating price for item ${screenData.details![i].barcode}: $error');
          }
        });
      }
    }
  }

  void searchSupplier({required String word}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SupplierSearchScreen(
                  word: word,
                ))).then((value) {
      SearchGuidCodeNameModel result = value;
      if (result.code.trim().isNotEmpty) {
        setState(() {
          if (widget.type == global.TransactionTypeEnum.purchasereturn || widget.type == global.TransactionTypeEnum.salereturn) {
            if (screenData.details!.isNotEmpty) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Center(
                    child: AlertDialog(
                      content: Text(global.language("remove_all_detail")),
                      actions: [
                        TextButton(
                          child: Text(global.language("cancel")),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text(
                            global.language("confirm"),
                            style: const TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            screenData.discountword = '';
                            screenData.totalcost = 0;
                            screenData.totalvalue = 0;
                            screenData.totaldiscount = 0;
                            screenData.totalvatvalue = 0;
                            screenData.totalaftervat = 0;
                            screenData.totalexceptvat = 0;
                            screenData.totalamount = 0;
                            screenData.totalbeforevat = 0;
                            screenData.details = <TransactionDetailModel>[];
                            screenData.ismanualamount = false;
                            screenData.paymentdetailraw = "";
                            screenData.billpayobjectboxstruct = [];
                            screenData.reftotaloriginal = 0;
                            screenData.reftotalcorrect = 0;
                            screenData.reftotaldiff = 0;

                            custCodeController.text = result.code;
                            custnamesController.text = global.activeLangName(result.names);
                            screenData.custcode = result.code;
                            screenData.custnames = result.names;
                            _calTotalValue();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            } else {
              custCodeController.text = result.code;
              custnamesController.text = global.activeLangName(result.names);
              screenData.custcode = result.code;
              screenData.custnames = result.names;
            }
          } else {
            custCodeController.text = result.code;
            custnamesController.text = global.activeLangName(result.names);
            screenData.custcode = result.code;
            screenData.custnames = result.names;
          }
        });
      }
    });
  }

  void _showBarcodeDialog(BuildContext context) async {
    TextEditingController barcode = TextEditingController();
    FocusNode barcodefocus = FocusNode();
    barcode.text = "";
    return showDialog(
      context: context,
      barrierDismissible: true, // Allows tapping outside the dialog to close it
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(global.language("barcode")),
          content: SizedBox(
            width: (global.isMobileScreen(context)) ? 350 : 400,
            child: TextField(
              autofocus: true,
              controller: barcode,
              focusNode: barcodefocus,
              decoration: InputDecoration(
                labelText: '',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    barcode.text = '';
                  },
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  double inputQty = 1;
                  String barcodeValue = "";
                  if (value.trim().contains("*")) {
                    String numberValue = value.trim().split("*")[0];
                    if (numberValue != "" && numberValue != "0") {
                      inputQty = double.parse(value.trim().split("*")[0]);
                    }
                    barcodeValue = value.trim().split("*")[1];
                  } else {
                    barcodeValue = value.trim();
                  }
                  _productBarcodeRepository.getProductBarcodeDetail(barcodeValue).then((value) {
                    if (value.success && value.data != null) {
                      ProductBarcodeModel result = ProductBarcodeModel.fromJson(value.data);

                      if (widget.type == global.TransactionTypeEnum.sale ||
                          widget.type == global.TransactionTypeEnum.saleorder ||
                          widget.type == global.TransactionTypeEnum.salereturn) {
                        if (result.itemtype == 3) {
                          return;
                        }
                      }

                      screenData.details!.add(
                        TransactionDetailModel(
                          docdatetime: DateTime.now().toLocal().toIso8601String(),
                          itemguid: result.guidfixed,
                          barcode: result.barcode!,
                          itemcode: result.itemcode ?? "",
                          itemnames: result.names,
                          unitcode: result.itemunitcode,
                          qty: inputQty,
                          price: _getPrice(result.prices),
                          discount: '',
                          sumofcost: 0,
                          sumamount: 0,
                          remark: '',
                          linenumber: 0,
                          whcode: defualtwarehouse,
                          whnames: defualtwarehousenames,
                          shelfcode: '',
                          locationcode: defualtlocation,
                          locationnames: defualtlocationnames,
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
                          towhcode: defualttowarehouse,
                          towhnames: defualttowarehousenames,
                          tolocationcode: defualttolocation,
                          tolocationnames: defualttolocationnames,
                          vatcal: result.vatcal,
                          refbarcodes: result.refbarcodes,
                          manufacturerguid: result.manufacturerguid,
                        ),
                      );

                      _calTotalValue();
                      barcode.text = '';
                      Future.delayed(const Duration(milliseconds: 200), () {
                        FocusScope.of(context).requestFocus(barcodefocus);
                      });
                    }
                    setState(() {});
                  }).onError((error, stackTrace) {
                    barcode.text = '';
                    Future.delayed(const Duration(milliseconds: 200), () {
                      FocusScope.of(context).requestFocus(barcodefocus);
                    });
                  });
                } else {}
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(global.language("close")),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showSaveDocNoDialog(BuildContext context, String docno) async {
    FocusNode focusNode = FocusNode();

    void handleClose(String? button) {
      clearScreenData();
      if (button == "cancel") {
        Navigator.of(context).pop(); // Close the dialog
      }
      editTabController.animateTo(0);
    }

    // Show the dialog
    await showDialog(
      context: context,
      barrierDismissible: true, // Allows the dialog to be dismissed by tapping outside.
      builder: (BuildContext context) {
        // Listen for raw keyboard events
        focusNode.requestFocus();
        return RawKeyboardListener(
          focusNode: focusNode,
          onKey: (event) {
            if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
              // ESC key is pressed
              handleClose("");
            }
          },
          child: AlertDialog(
            title: Text(global.language("save_success")),
            content: Text("${global.language("docno")} : $docno  ${global.language("how_to_print")}"),
            actions: [
              TextButton(
                child: Text(global.language("cancel")),
                onPressed: () => handleClose("cancel"),
              ),
              TextButton.icon(
                icon: const Icon(Icons.print),
                label: Text(global.language("confirm")),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfPreviewPage(
                        screenData: screenData,
                        type: widget.type,
                      ),
                    ),
                  ).then((value) => handleClose("cancel"));
                },
              ),
            ],
          ),
        );
      },
    ).then((value) => handleClose("")); // Handle dialog dismiss by tapping outside or back button on Android
  }

  @override
  Widget build(BuildContext context) {
    global.TransactionTypeEnum transactionType = widget.type;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          focusNode: FocusNode(skipTraversal: true),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/menu', (route) => false);
          },
        ),
        backgroundColor: global.theme.appBarColor,
        title: Text(global.transactionName(widget.type)),
        actions: <Widget>[
          /// ออกใบกำกับแบบเต็ม
          (screenData.ispos == true && screenData.iscancel == false)
              ? Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: () async {
                      /// ยืนยันการ ออกใบกำกับเต็ม
                      final result = await _showAlertConfirmFullInvoiceDialog(context, screenData.docno);
                      if (result != null && result) {
                        saveOrUpdateData(taxInvoice: true);
                      }
                    },
                    icon: const Icon(
                      Icons.receipt_long_outlined,
                      size: 26.0,
                    ),
                  ),
                )
              : Container(),

          (screenData.slipurl != '')
              ? Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: () async {
                      /// show dialog preview image
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            content: Image.network(screenData.slipurl!),
                          );
                        },
                      );
                    },
                    icon: const Icon(
                      Icons.image_outlined,
                      size: 26.0,
                    ),
                  ),
                )
              : Container(),

          /// export csv
          (transactionType == global.TransactionTypeEnum.sale && screenData.guidfixed != '')
              ? Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: IconButton(
                    onPressed: () {
                      /// dialog select language code
                      showDialog<String>(
                        context: context,
                        builder: (BuildContext context) {
                          // Initialize the selected language outside of StatefulBuilder
                          LanguageModel? selectedLanguage = global.config.languages[0];

                          return AlertDialog(
                            title: Text(global.language('select_language')),
                            content: StatefulBuilder(
                              builder: (BuildContext context, StateSetter setState) {
                                return InputDecorator(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<LanguageModel>(
                                      value: selectedLanguage,
                                      icon: const Icon(Icons.arrow_drop_down),
                                      style: const TextStyle(color: Colors.deepPurple),
                                      underline: Container(
                                        color: Colors.deepPurpleAccent,
                                      ),
                                      onChanged: (LanguageModel? value) {
                                        setState(() {
                                          selectedLanguage = value!;
                                        });
                                      },
                                      isDense: true,
                                      isExpanded: true,
                                      items: global.config.languages.map<DropdownMenuItem<LanguageModel>>((LanguageModel value) {
                                        return DropdownMenuItem<LanguageModel>(
                                          value: value,
                                          child: Row(
                                            children: <Widget>[
                                              Image.asset(
                                                'assets/flags/${value.code}.png', // Ensure the image path is correct
                                                width: 30,
                                                height: 30,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(Icons.error); // Error icon if the image fails to load
                                                },
                                              ),
                                              const SizedBox(width: 10), // Spacing between the image and text
                                              Text(value.name!),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            actions: <Widget>[
                              // Text button cancel
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(global.language('cancel')),
                              ),

                              // Export button
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                onPressed: () {
                                  context.read<ExportCsvBloc>().add(SaleInvoiceExport(languageCode: selectedLanguage!.code!));
                                  Navigator.pop(context);
                                },
                                child: Text(global.language('export')),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(
                      Icons.download,
                    ),
                  ),
                )
              : Container(),
          (screenData.guidfixed != '' && screenData.iscancel == false)
              ? Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: () async {
                      final result = await _showAlertConfirmDeleteDialog(context, screenData.docno);
                      if (result != null && result) {
                        deleteDoc();
                      }
                    },
                    icon: const Icon(
                      Icons.delete,
                      size: 26.0,
                    ),
                  ))
              : Container(),

          (!screenData.iscancel && screenData.guidfixed != '')
              ? Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: () async {
                      if (screenData.details!.isNotEmpty) {
                        final result = await _showAlertConfirmCancelDialog(context);
                        if (result != null && result.isNotEmpty) {
                          screenData.iscancel = true;
                          screenData.cancelreason = result;
                          screenData.cancelusercode = global.profileData.username;
                          screenData.cancelusername = global.profileData.name;
                          screenData.canceldatetime = DateTime.now().toLocal().toIso8601String();
                          screenData.canceltime = DateTime.now().toLocal().toIso8601String();

                          screenDataTemp.iscancel = true;
                          screenDataTemp.cancelreason = result;
                          screenDataTemp.cancelusercode = global.profileData.username;
                          screenDataTemp.cancelusername = global.profileData.name;
                          screenDataTemp.canceldatetime = DateTime.now().toLocal().toIso8601String();
                          screenDataTemp.canceltime = DateTime.now().toLocal().toIso8601String();

                          saveOrUpdateData(taxInvoice: false);
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.cancel_rounded,
                      size: 26.0,
                    ),
                  ),
                )
              : Container(),
          (screenData.guidfixed != '' && screenData.ispos == false)
              ? Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: () async {
                      setState(() {});
                      if (screenData.details!.isEmpty) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('โปรดเลือกรายการสินค้า'),
                              actions: [
                                TextButton(
                                  child: Text(global.language("confirm")),
                                  onPressed: () {
                                    clearScreenData();
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PdfPreviewPage(
                              screenData: screenData,
                              type: widget.type,
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.print,
                      size: 26.0,
                    ),
                  ),
                )
              : Container(),
          Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: IconButton(
                focusNode: FocusNode(skipTraversal: true),
                onPressed: () async {
                  clearScreenData();
                },
                icon: const Icon(
                  Icons.add,
                  size: 26.0,
                ),
              )),

          Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: IconButton(
                focusNode: FocusNode(skipTraversal: true),
                onPressed: () async {
                  searchTrans();
                },
                icon: const Icon(
                  Icons.list_alt,
                  size: 26.0,
                ),
              )),
          (MediaQuery.of(context).size.width < 800)
              ? (tabController.index == 0)
                  ? Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: IconButton(
                        focusNode: FocusNode(skipTraversal: true),
                        onPressed: () {
                          setState(() {
                            tabController.animateTo(1);
                          });
                        },
                        icon: const Icon(
                          Icons.file_open,
                          size: 26.0,
                        ),
                      ))
                  : Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: IconButton(
                        focusNode: FocusNode(skipTraversal: true),
                        onPressed: () {
                          setState(() {
                            tabController.animateTo(0);
                          });
                        },
                        icon: const Icon(
                          Icons.text_fields,
                          size: 26.0,
                        ),
                      ))
              : Container(),
          (screenData.posid.isEmpty && screenData.iscancel == false)
              ? Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: () async {
                      if (screenData.details!.isNotEmpty) {
                        final result = await _showAlertConfirmSaveDialog(context, screenData.guidfixed ?? '');
                        if (result != null && result) {
                          saveOrUpdateData(taxInvoice: false);
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.save,
                      size: 26.0,
                    ),
                  ),
                )
              : Container(),
        ],
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return MultiBlocListener(
                  listeners: [
                    BlocListener<TransBloc, TransState>(
                      listener: (context, state) {
                        // จัดการ Loading States
                        if (state is TransInProgress) {
                          setState(() {
                            _isLoading = true;
                            _loadingMessage = 'กำลังโหลดข้อมูล...';
                          });
                        } else if (state is TransSaveInProgress) {
                          setState(() {
                            _isLoading = true;
                            _loadingMessage = 'กำลังบันทึกข้อมูล...';
                          });
                        } else if (state is TransUpdateInProgress) {
                          setState(() {
                            _isLoading = true;
                            _loadingMessage = 'กำลังอัพเดทข้อมูล...';
                          });
                        } else if (state is TransDeleteInProgress) {
                          setState(() {
                            _isLoading = true;
                            _loadingMessage = 'กำลังลบข้อมูล...';
                          });
                        } else if (state is TransDeleteManyInProgress) {
                          setState(() {
                            _isLoading = true;
                            _loadingMessage = 'กำลังลบข้อมูลหลายรายการ...';
                          });
                        } else if (state is TransGetInProgress) {
                          setState(() {
                            _isLoading = true;
                            _loadingMessage = 'กำลังดึงข้อมูล...';
                          });
                        } else if (state is TransFullInvoiceInProgress) {
                          setState(() {
                            _isLoading = true;
                            _loadingMessage = 'กำลังสร้างใบกำกับภาษีแบบเต็ม...';
                          });
                        }

                        // จัดการ Success/Failed States
                        else if (state is TransLoadSuccess) {
                          setState(() {
                            _isLoading = false;
                          });
                          // Handle load success
                        } else if (state is TransLoadFailed) {
                          setState(() {
                            _isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else if (state is TransSaveSuccess) {
                          setState(() {
                            _isLoading = false;
                          });

                          screenData.docno = state.docno;

                          // ทำการลบตะกร้าที่ใช้ไปแล้วผ่าน CartWebSocketService
                          if (cartList.isNotEmpty) {
                            // ตรวจสอบว่า service เชื่อมต่ออยู่หรือไม่
                            if (_cartService.isSocketConnected()) {
                              for (String cartId in cartList) {
                                try {
                                  // ใช้ฟังก์ชัน deleteCart ของ CartWebSocketService
                                  _cartService.deleteCart(cartId, global.getShopId());

                                  if (kDebugMode) {
                                    print('ลบตะกร้า ID: $cartId ผ่าน CartWebSocketService');
                                  }
                                } catch (e) {
                                  if (kDebugMode) {
                                    print('เกิดข้อผิดพลาดในการลบตะกร้า: $e');
                                  }
                                }
                              }
                            } else {
                              // กรณี service ไม่ได้เชื่อมต่อ ให้ทำการเชื่อมต่อก่อน
                              _cartService.connect(context).then((connected) {
                                if (connected) {
                                  for (String cartId in cartList) {
                                    _cartService.deleteCart(cartId, global.getShopId());
                                  }
                                }
                              });
                            }

                            // เคลียร์รายการตะกร้าหลังจากลบเสร็จ
                            cartList.clear();
                          }

                          showSaveDocNoDialog(context, state.docno);
                        } else if (state is TransSaveFailed) {
                          setState(() {
                            _isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else if (state is TransUpdateSuccess) {
                          setState(() {
                            _isLoading = false;
                          });
                          clearScreenData();
                          global.showSnackBar(
                              context,
                              const Icon(
                                Icons.edit,
                                color: Colors.white,
                              ),
                              global.language("edit_success"),
                              Colors.blue);
                        } else if (state is TransUpdateFailed) {
                          setState(() {
                            _isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else if (state is TransDeleteSuccess) {
                          setState(() {
                            _isLoading = false;
                          });
                          clearScreenData();
                          global.showSnackBar(
                              context,
                              const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                              global.language("delete_success"),
                              Colors.blue);
                        } else if (state is TransDeleteFailed) {
                          setState(() {
                            _isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else if (state is TransDeleteManySuccess) {
                          setState(() {
                            _isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ลบข้อมูลหลายรายการสำเร็จ'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (state is TransDeleteManyFailed) {
                          setState(() {
                            _isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ลบข้อมูลหลายรายการไม่สำเร็จ'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else if (state is TransGetSuccess) {
                          setState(() {
                            _isLoading = false;
                          });
                          // Handle get success
                          screenData = state.trans;
                          screenDataTemp = TransactionModel.fromJson(state.trans.toJson());
                        } else if (state is TransGetFailed) {
                          setState(() {
                            _isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } else if (state is TransFullInvoiceSuccess) {
                          _isLoading = false;
                          showSaveDocNoDialog(context, state.docno);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('สร้างใบกำกับภาษีแบบเต็มสำเร็จ'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (state is TransFullInvoiceFailed) {
                          setState(() {
                            _isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('สร้างใบกำกับภาษีแบบเต็มไม่สำเร็จ: ${state.message}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }

                        // Reset loading สำหรับ states อื่นๆ ที่ไม่ได้จัดการ
                        else {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                    ),
                    BlocListener<WarehouseBloc, WarehouseState>(
                      listener: (context, state) {
                        if (state is WarehouseLoadSuccess) {
                          warehouseList = state.warehouses;
                          if (warehouseList.isNotEmpty) {
                            setState(() {
                              /// find default warehouse code 00000

                              late WarehouseModel findWarehouse00000 = warehouseList.firstWhere((element) => element.code == '00000');

                              /// จากคลัง
                              defualtwarehouse = findWarehouse00000.code;
                              defualtwarehousenames = findWarehouse00000.names;

                              /// ไปคลัง
                              defualttowarehouse = findWarehouse00000.code;
                              defualttowarehousenames = findWarehouse00000.names;

                              if (findWarehouse00000.location.isNotEmpty) {
                                /// จากที่เก็บ
                                defualtlocation = findWarehouse00000.location[0].code;
                                defualtlocationnames = findWarehouse00000.location[0].names;

                                ///
                                defualttolocation = warehouseList[0].location[0].code;
                                defualttolocationnames = warehouseList[0].location[0].names;
                              }
                            });
                          }
                        }
                      },
                    ),
                    BlocListener<ExportCsvBloc, ExportCsvState>(listener: (context, state) {
                      /// download csv
                      if (state is SaleInvoiceExportInProgress) {
                        // Show a loading indicator if desired
                      } else if (state is SaleInvoiceExportSuccess) {
                        global.showSnackBar(
                            context,
                            const Icon(
                              Icons.save,
                              color: Colors.white,
                            ),
                            global.language("export_success"),
                            Colors.blue);
                      } else if (state is SaleInvoiceExportFailed) {
                        // Show an error message
                        global.showSnackBar(
                            context,
                            const Icon(
                              Icons.save,
                              color: Colors.white,
                            ),
                            "${global.language("not_export_success")} : ${state.message}",
                            Colors.red);
                      }
                    }),
                  ],
                  child: (constraints.maxWidth > 700)
                      ? SplitView(
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
                            previewWidget(),
                            editWidget(),
                          ],
                        )
                      : TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          controller: tabController,
                          children: [
                            editWidget(),
                            previewWidget(),
                          ],
                        ));
            },
          ),

          // Loading Overlay

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: global.theme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: global.theme.appBarColor.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Loading indicator ใช้สีธีมของแอป
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                          backgroundColor: Colors.blue.withOpacity(0.1),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Loading text ใช้สไตล์ที่เข้ากับแอป
                      Text(
                        _loadingMessage,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'กรุณารอสักครู่...',
                        style: TextStyle(
                          color: (Colors.black87).withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void setFocusNode(FocusNode focus) {
    focus.unfocus();
    Future.delayed(const Duration(milliseconds: 500), () {
      focus.requestFocus();
    });
  }
}

class TotalTextController extends StatelessWidget {
  const TotalTextController({Key? key, required this.readOnly, required this.title, required this.data, this.icon, required this.onChanged, this.useColor}) : super(key: key);

  final dynamic data;
  final String title;
  final Icon? icon;
  final Function(String) onChanged;
  final bool readOnly;
  final bool? useColor;

  @override
  Widget build(BuildContext context) {
    String initialText = '';
    if (data != null) {
      if (data is String) {
        try {
          // Attempt to parse the string as a double
          final double parsedValue = double.parse(data);
          initialText = global.formatNumber(parsedValue);
        } catch (e) {
          // Handle the case where parsing fails (e.g., if the string is not a valid number)
          initialText = ''; // Set to an empty string or any other default value you prefer
        }
      } else if (data is double) {
        // If data is already a double, just format it
        initialText = global.formatNumber(data);
      }
    }
    return TextField(
      readOnly: readOnly,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: title,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: icon,
        filled: useColor,
        fillColor: Colors.yellow[100],
      ),
      controller: TextEditingController(text: initialText),
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [global.NumberInputFormatter()],
    );
  }
}

Future<String?> _showDiscountDialog(BuildContext context, String currentdiscount, String itemnames) async {
  TextEditingController discount = TextEditingController();
  discount.text = currentdiscount.toString();
  return showDialog<String?>(
    context: context,
    barrierDismissible: true, // Allows tapping outside the dialog to close it
    builder: (BuildContext context) {
      // เลือกข้อความทั้งหมดหลังจาก widget สร้างเสร็จ
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (discount.text.isNotEmpty) {
          discount.selection = TextSelection(baseOffset: 0, extentOffset: discount.text.length);
        }
      });

      return AlertDialog(
        title: Text('$itemnames ${global.language("discount")}'),
        content: SizedBox(
          width: (global.isMobileScreen(context)) ? 350 : 400,
          child: TextField(
            autofocus: true,
            controller: discount,
            decoration: InputDecoration(
              labelText: global.language("enter_discount"),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  discount.text = '';
                },
              ),
            ),
            onSubmitted: (value) {
              Navigator.pop(context, discount.text);
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(global.language("close")),
            onPressed: () {
              Navigator.pop(context, currentdiscount.toString());
            },
          ),
          TextButton(
            child: Text(global.language("update")),
            onPressed: () {
              Navigator.pop(context, discount.text);
            },
          ),
        ],
      );
    },
  );
}

Future<String?> _showPriceDialog(BuildContext context, double currentprice, String itemnames) async {
  TextEditingController price = TextEditingController();

  if (currentprice > 0) {
    price.text = currentprice.toString();
  } else {
    price.text = "";
  }
  return showDialog<String?>(
    context: context,
    barrierDismissible: true, // Allows tapping outside the dialog to close it
    builder: (BuildContext context) {
      // เลือกข้อความทั้งหมดหลังจาก widget สร้างเสร็จ
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (price.text.isNotEmpty) {
          price.selection = TextSelection(baseOffset: 0, extentOffset: price.text.length);
        }
      });

      return AlertDialog(
        title: Text('$itemnames ${global.language("price")}'),
        content: SizedBox(
          width: (global.isMobileScreen(context)) ? 350 : 400,
          child: TextField(
            autofocus: true,
            controller: price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [global.NumberInputFormatter()],
            decoration: InputDecoration(
              labelText: global.language("enter_price"),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  price.text = '';
                },
              ),
            ),
            onSubmitted: (value) {
              Navigator.pop(context, price.text);
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(global.language("close")),
            onPressed: () {
              Navigator.pop(context, currentprice.toString());
            },
          ),
          TextButton(
            child: Text(global.language("update")),
            onPressed: () {
              Navigator.pop(context, price.text);
            },
          ),
        ],
      );
    },
  );
}

Future<String?> _showQtyDialog(BuildContext context, double currentqty, String itemnames) async {
  TextEditingController qty = TextEditingController();
  if (currentqty > 0) {
    qty.text = currentqty.toString();
  } else {
    qty.text = "";
  }

  return showDialog<String?>(
    context: context,
    barrierDismissible: true, // Allows tapping outside the dialog to close it
    builder: (BuildContext context) {
      // เลือกข้อความทั้งหมดหลังจาก widget สร้างเสร็จ
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (qty.text.isNotEmpty) {
          qty.selection = TextSelection(baseOffset: 0, extentOffset: qty.text.length);
        }
      });

      return AlertDialog(
        title: Text('$itemnames ${global.language("qty")}'),
        content: SizedBox(
          width: (global.isMobileScreen(context)) ? 350 : 400,
          child: TextField(
            autofocus: true,
            controller: qty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [global.NumberInputFormatter()],
            decoration: InputDecoration(
              labelText: global.language("enter_qty"),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  qty.clear();
                },
              ),
            ),
            onSubmitted: (value) {
              Navigator.pop(context, qty.text);
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(global.language("close")),
            onPressed: () {
              Navigator.pop(context, currentqty.toString());
            },
          ),
          TextButton(
            child: Text(global.language("update")),
            onPressed: () {
              Navigator.pop(context, qty.text);
            },
          ),
        ],
      );
    },
  );
}

Future<LocationModel?> _showWareHouseLocationDialog(BuildContext context, String itemguid, String whcode) async {
  context.read<WarehouseBloc>().add(WarehouseGetByCode(code: whcode));
  late List<LocationModel> location = [];
  return showDialog<LocationModel?>(
    context: context,
    barrierDismissible: true, // Allows tapping outside the dialog to close it
    builder: (BuildContext context) {
      return BlocBuilder<WarehouseBloc, WarehouseState>(
        builder: (context, state) {
          if (state is WarehouseGetSuccess) {
            if (state.warehouse.location.isNotEmpty) {
              location = state.warehouse.location;
            }
          }
          return AlertDialog(
            title: Text('${global.language("select_location_from_warehouse")} $whcode'),
            content: (state is WarehouseGetSuccess)
                ? SizedBox(
                    width: (global.isMobileScreen(context)) ? 350 : 400,
                    child: ListView.builder(
                      shrinkWrap: true, // Required for the ListView to be displayed properly
                      itemCount: location.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          title: Text('${location[index].code} ~ ${location[index].names.firstWhere((ele) => ele.code == global.userLanguage).name}'),
                          onTap: () {
                            Navigator.pop(context, location[index]);
                          },
                        );
                      },
                    ),
                  )
                : const Text(''),
            actions: <Widget>[
              TextButton(
                child: Text(global.language("close")),
                onPressed: () {
                  Navigator.pop(context, LocationModel(code: ''));
                },
              ),
            ],
          );
        },
      );
    },
  );
}

Future<LocationModel?> _showWareHouseLocationDefualtDialog(BuildContext context, String whcode) async {
  context.read<WarehouseBloc>().add(WarehouseGetByCode(code: whcode));
  late List<LocationModel> location = [];
  return showDialog<LocationModel?>(
    context: context,
    barrierDismissible: true, // Allows tapping outside the dialog to close it
    builder: (BuildContext context) {
      return BlocBuilder<WarehouseBloc, WarehouseState>(
        builder: (context, state) {
          if (state is WarehouseGetSuccess) {
            if (state.warehouse.location.isNotEmpty) {
              location = state.warehouse.location;
            }
          }
          return AlertDialog(
            title: Text('${global.language("select_location_from_warehouse")} $whcode'),
            content: (state is WarehouseGetSuccess)
                ? SizedBox(
                    width: (global.isMobileScreen(context)) ? 350 : 400,
                    child: ListView.builder(
                      shrinkWrap: true, // Required for the ListView to be displayed properly
                      itemCount: location.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          title: Text('${location[index].code} ~ ${location[index].names.firstWhere((ele) => ele.code == global.userLanguage).name}'),
                          onTap: () {
                            Navigator.pop(context, location[index]);
                          },
                        );
                      },
                    ),
                  )
                : const Text(''),
            actions: <Widget>[
              TextButton(
                child: Text(global.language("close")),
                onPressed: () {
                  Navigator.pop(context, LocationModel(code: ''));
                },
              ),
            ],
          );
        },
      );
    },
  );
}

Future<WarehouseModel?> _showWareHouseDialog(BuildContext context, String itemguid, List<WarehouseModel> warehouseList) async {
  return showDialog<WarehouseModel?>(
    context: context,
    barrierDismissible: true, // Allows tapping outside the dialog to close it
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(global.language("select_warehouse")),
        content: (SizedBox(
          width: (global.isMobileScreen(context)) ? 350 : 400,
          child: ListView.builder(
            shrinkWrap: true, // Required for the ListView to be displayed properly
            itemCount: warehouseList.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text('${warehouseList[index].code} ~ ${warehouseList[index].names.firstWhere((ele) => ele.code == global.userLanguage).name}'),
                onTap: () {
                  Navigator.pop(context, warehouseList[index]);
                },
              );
            },
          ),
        )),
        actions: <Widget>[
          TextButton(
            child: Text(global.language("close")),
            onPressed: () {
              Navigator.pop(context, WarehouseModel(guidfixed: '', code: ''));
            },
          ),
        ],
      );
    },
  );
}

Future<WarehouseModel?> _showWareHouseDefualtDialog(BuildContext context, List<WarehouseModel> warehouseList) async {
  late List<WarehouseModel> warehouse = warehouseList;
  return showDialog<WarehouseModel?>(
    context: context,
    barrierDismissible: true, // Allows tapping outside the dialog to close it
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(global.language("select_warehouse")),
        content: SizedBox(
          width: (global.isMobileScreen(context)) ? 350 : 400,
          child: ListView.builder(
            shrinkWrap: true, // Required for the ListView to be displayed properly
            itemCount: warehouse.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text('${warehouseList[index].code} ~ ${warehouseList[index].names.firstWhere((ele) => ele.code == global.userLanguage).name}'),
                onTap: () {
                  Navigator.pop(context, warehouse[index]);
                },
              );
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(global.language("close")),
            onPressed: () {
              Navigator.pop(context, WarehouseModel(guidfixed: '', code: ''));
            },
          ),
        ],
      );
    },
  );
}

Future<ProductBarcodeModel?> _showUnitsDialog(BuildContext context, String itemguid) async {
  context.read<ProductBarcodeBloc>().add(ProductBarcodeGet(guid: itemguid));
  late List<ProductBarcodeModel> productList = [];
  return showDialog<ProductBarcodeModel?>(
    context: context,
    barrierDismissible: true, // Allows tapping outside the dialog to close it
    builder: (BuildContext context) {
      return BlocBuilder<ProductBarcodeBloc, ProductBarcodeState>(
        builder: (context, state) {
          if (state is ProductBarcodeGetSuccess) {
            if (state.productBarcode.refbarcodes!.isNotEmpty) {
              for (var item in state.productBarcode.refbarcodes!) {
                productList.add(ProductBarcodeModel(
                  barcode: item.barcode,
                  guidfixed: item.guidfixed!,
                  names: item.names,
                  itemunitnames: item.itemunitnames,
                  itemunitcode: item.itemunitcode,
                  dividevalue: item.dividevalue,
                  standvalue: item.standvalue,
                ));
              }
              context.read<ProductBarcodeBloc>().add(ProductBarcodeGetRef(guid: state.productBarcode.refbarcodes![0].barcode));
            } else {
              productList.add(state.productBarcode);
              context.read<ProductBarcodeBloc>().add(ProductBarcodeGetRef(guid: state.productBarcode.barcode!));
            }
          }
          if (state is ProductBarcodeGetRefSuccess) {
            productList.addAll(state.productBarcodes);
          }
          return AlertDialog(
            title: Text(global.language("select_unit")),
            content: (state is ProductBarcodeGetRefSuccess)
                ? SizedBox(
                    width: (global.isMobileScreen(context)) ? 350 : 400,
                    child: ListView.builder(
                      shrinkWrap: true, // Required for the ListView to be displayed properly
                      itemCount: productList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${global.language("barcode")}: ${productList[index].barcode}'),
                              Text('${global.language("product_name")}: ${global.packName(productList[index].names!)}'),
                              Text('${global.language("product_unit_name")}: ${global.packName(productList[index].itemunitnames!)}'),
                            ],
                          ),
                          onTap: () {
                            Navigator.pop(context, productList[index]);
                          },
                        );
                      },
                    ),
                  )
                : const Text('Processing'),
            actions: <Widget>[
              TextButton(
                child: Text(global.language("close")),
                onPressed: () {
                  Navigator.pop(context, ProductBarcodeModel(barcode: '', guidfixed: ''));
                },
              ),
            ],
          );
        },
      );
    },
  );
}

/// _showAlertConfirmFullInvoiceDialog
Future<bool?> _showAlertConfirmFullInvoiceDialog(BuildContext context, String docno) async {
  return showDialog<bool?>(
    context: context,
    builder: (BuildContext context) {
      // Return the AlertDialog.
      return AlertDialog(
        title: Text(global.language("alert")),
        content: Text('คุณต้องการออกใบกำกับภาษีเต็มรูปแบบสำหรับเอกสาร $docno หรือไม่?'),
        actions: [
          TextButton(
            child: Text(global.language("cancel")),
            onPressed: () {
              // Do something here.
              Navigator.pop(context, false);
            },
          ),
          TextButton(
            child: Text(global.language("confirm")),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
        ],
      );
    },
  );
}

Future<bool?> _showAlertConfirmDeleteDialog(BuildContext context, String docno) async {
  return showDialog<bool?>(
    context: context,
    builder: (BuildContext context) {
      // Return the AlertDialog.
      return AlertDialog(
        title: Text(global.language("alert")),
        content: Text(global.language("confirm_delete")),
        actions: [
          TextButton(
            child: Text(global.language("cancel")),
            onPressed: () {
              // Do something here.
              Navigator.pop(context, false);
            },
          ),
          TextButton(
            child: Text(global.language("delete")),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
        ],
      );
    },
  );
}

Future<bool?> _showAlertConfirmSaveDialog(BuildContext context, String guid) async {
  return showDialog<bool?>(
    context: context,
    builder: (BuildContext context) {
      // Return the AlertDialog.
      return AlertDialog(
        title: Text(global.language("alert")),
        content: (guid == '') ? Text(global.language("confirm_save")) : Text(global.language("confirm_update")),
        actions: [
          TextButton(
            child: Text(global.language("cancel")),
            onPressed: () {
              // Do something here.
              Navigator.pop(context, false);
            },
          ),
          TextButton(
            child: Text(global.language("save")),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
        ],
      );
    },
  );
}

/// ยกเลิก
Future<String?> _showAlertConfirmCancelDialog(BuildContext context) async {
  TextEditingController controller = TextEditingController();
  final List<String> reasons = <String>['ชื่อ/ที่อยู่ ผิด', 'วันที่ผิด', 'จำนวน/มูลค่าผิด', 'สินค้าผิด', 'อื่นๆ'];
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool showOther = false;

  controller.text = reasons[0];

  String? result = await showDialog<String?>(
    context: context,
    barrierDismissible: true, // User must tap a button to close the dialog.
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text(global.language("alert")),
            content: Form(
              key: formKey,
              child: Container(
                width: 400,
                height: 180,
                margin: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: global.language("reason"),
                        ),
                        value: reasons[0],
                        onChanged: (String? newValue) {
                          controller.text = newValue!;
                          setState(() {
                            if (newValue == 'อื่นๆ') {
                              showOther = true;
                              controller.text = "";
                            } else {
                              showOther = false;
                            }
                          });
                        },
                        items: reasons.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter some text';
                          }
                          return null;
                        },
                      ),
                    ),
                    (showOther)
                        ? TextFormField(
                            controller: controller,
                            maxLines: 4,
                            decoration: InputDecoration(
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              border: const OutlineInputBorder(),
                              labelText: global.language('description'),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter some text';
                              }
                              return null;
                            },
                          )
                        : Container(),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: Text(global.language("cancel")),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: Text(global.language("save")),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, controller.text); // Return the text from the controller
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
  return result;
}
