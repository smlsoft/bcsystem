import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:printing/printing.dart' as printing;
import 'package:smlaicloud/global.dart' as global;
import 'package:smlaicloud/model/global_model.dart';
import 'package:smlaicloud/screens/report/report_stock_widget.dart';
import 'package:smlaicloud/utils/date_picker.dart';
import 'package:smlaicloud/utils/select_product_barcode.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../pdf_saver.dart';

class ReportStockMovementCost extends StatefulWidget {
  const ReportStockMovementCost({super.key});

  @override
  _ReportStockMovementCostState createState() =>
      _ReportStockMovementCostState();
}

class _ReportStockMovementCostState extends State<ReportStockMovementCost>
    with SingleTickerProviderStateMixin {
  bool processSuccess = false;
  bool pdfCreated = false;
  bool pdfDownloaded = false;
  String pdfPath = "";
  String guid = "";
  Widget processWidgetStatus = Container();
  // Add process state variable
  global.ProcessState processState = global.ProcessState.idle;
  Widget resultScreenWidget = Container();
  Widget pdfViewWidget = Container();
  PdfViewerController pdfViewerController = PdfViewerController();
  TextEditingController pdfSearchController = TextEditingController();
  late Uint8List pdfData;
  DateTime conditionBeginDate = DateTime.now();
  DateTime conditionFinalDate = DateTime.now();
  late TabController tabController;
  double resultFontScale = 1.0;
  List<ReportStockMovementModel> dataList = [];
  late ReportStockConditionClass reportCondition;
  ScrollController scrollController = ScrollController();
  int dataOffset = 50;
  bool showHelp = false;
  bool isLoadingMore = false;

  // สีและสไตล์ที่ใช้ในหน้ารายงาน
  final Color primaryColor = Colors.blue.shade700;
  final Color secondaryColor = Colors.blue.shade100;
  final Color accentColor = Colors.amber.shade600;
  final Color headerColor = Colors.blue.shade100;
  final Color footerColor = Colors.blue.shade50;
  final Color rowEvenColor = Colors.grey.shade50;
  final Color rowOddColor = Colors.white;
  final Color warehouseColor = Colors.amber.shade50;
  final Color locationColor = Colors.green.shade50;
  final Color helpColor = Colors.blue.shade50;
  final Color successColor = Colors.green.shade600;
  final Color errorColor = Colors.red.shade600;
  final Color backgroundColor = Colors.grey.shade100;

  // รูปแบบตัวอักษรแบบต่างๆ
  late TextStyle titleStyle;
  late TextStyle subtitleStyle;
  late TextStyle normalStyle;
  late TextStyle emphasisStyle;
  late TextStyle highlightStyle;

  @override
  void initState() {
    super.initState();
    // วันที่เริ่มต้นของปี
    conditionBeginDate = DateTime(
      DateTime.now().year,
      1,
      1,
    );
    // วันที่สิ้นสุดของเดือน
    conditionFinalDate = DateTime(
      DateTime.now().year,
      DateTime.now().month + 1,
      0,
    );

    _initializeStyles();
    reportCondition = ReportStockConditionClass(onStateUpdate: () {
      setState(() {});
    });
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(() async {
      if (tabController.indexIsChanging) {
        if (tabController.index == 2) {
          if (pdfDownloaded == false) {
            await reloadPdf();
          }
        }
        setState(() {});
      }
    });

    scrollController.addListener(() {
      if (scrollController.position.pixels ==
              scrollController.position.maxScrollExtent &&
          !isLoadingMore) {
        _loadMoreData();
      }
    });

    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        showHelp = true;
      });
    });

    reportCondition.reloadWareHouseCode();
  }

  void _initializeStyles() {
    titleStyle = TextStyle(
        fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor);

    subtitleStyle = TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primaryColor.withOpacity(0.8));

    normalStyle = TextStyle(fontSize: 13, color: Colors.grey.shade800);

    emphasisStyle = TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: primaryColor.withOpacity(0.9));

    highlightStyle = TextStyle(
        fontSize: 13, fontWeight: FontWeight.bold, color: accentColor);
  }

  void _loadMoreData() {
    if (isLoadingMore) return;
    setState(() {
      isLoadingMore = true;
    });

    reloadData(dataList.length, dataOffset).then((_) {
      if (mounted) {
        setState(() {
          isLoadingMore = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          isLoadingMore = false;
        });
      }
      if (kDebugMode) {
        print("Error loading more data: $error");
      }
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    pdfViewerController.dispose();
    pdfSearchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> reloadPdf() async {
    try {
      if (pdfCreated == false) {
        var payload = {
          "shop_id": global.getShopId(),
          "command_id": "stock_balance_by_warehouse_and_product_create_pdf",
          "guid": guid,
          "condition": "1",
          "begin_date":
              "${conditionBeginDate.year}-${conditionBeginDate.month.toString().padLeft(2, '0')}-${conditionBeginDate.day.toString().padLeft(2, '0')}",
          "final_date":
              "${conditionFinalDate.year}-${conditionFinalDate.month.toString().padLeft(2, '0')}-${conditionFinalDate.day.toString().padLeft(2, '0')}",
        };
        var jsonPayload = jsonEncode(payload);
        var jsonResult = await global.reportServicePost(jsonPayload);
        if (jsonResult['code'] == 200) {
          pdfCreated = true;
          pdfDownloaded = false;
          pdfPath = jsonResult['path'];
          await reloadPdf();
        } else {
          throw Exception('PDF Creation Error: ${jsonResult['message']}');
        }
      } else {
        if (pdfDownloaded == false) {
          var payload = {
            "shop_id": global.getShopId(),
            "command_id": "data_bin",
            "guid": guid,
            "path": pdfPath,
          };
          var jsonResult = await global.reportServiceGetBinary(payload);
          pdfDownloaded = true;
          pdfData = jsonResult['binaryData'];

          if (kIsWeb) {
            String base64Data = base64Encode(pdfData);
            String pdfInBase64 = "data:application/pdf;base64,$base64Data";
            pdfViewWidget = SfPdfViewer.network(
              pdfInBase64,
              controller: pdfViewerController,
            );
          } else {
            pdfViewWidget = SfPdfViewer.memory(
              pdfData,
              controller: pdfViewerController,
            );
          }
          setState(() {});
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading PDF: $e");
      }
      setState(() {
        pdfViewWidget = Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: errorColor, size: 48),
              SizedBox(height: 16),
              Text("ไม่สามารถโหลด PDF ได้",
                  style: TextStyle(
                      color: errorColor, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("กรุณาลองประมวลผลรายงานใหม่อีกครั้ง",
                  style: TextStyle(color: Colors.grey.shade800)),
            ],
          ),
        );
      });
    }
  }

  Widget renderData(List<ReportStockMovementModel> dataList) {
    double fontSize = 12.0 * resultFontScale;
    var header = Container(
      decoration: BoxDecoration(
        color: headerColor,
        border: Border.all(color: Colors.blue.shade300),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "Barcode/SKU",
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.bold),
                  )),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "ชื่อสินค้า",
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.bold),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "หน่วยนับ",
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.bold),
                  )),
            ),
          ]),
          Row(children: [
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "วันที่/เวลา",
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.normal),
                  )),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "เลขที่เอกสาร",
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.normal),
                  )),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "รายละเอียด",
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.normal),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "ประเภท",
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.normal),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "หน่วยนับ",
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.normal),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "คลัง/ที่เก็บ",
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.normal),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "จำนวนเพิ่ม",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.normal),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "ต้นทุนเพิ่ม",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.normal),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "มูลค่าเพิ่ม",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.normal),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "จำนวนลด",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.normal),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "ต้นทุนลด",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.normal),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "มูลค่าลด",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.normal),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "จำนวนคงเหลือ",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.normal),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "ต้นทุนเฉลี่ย",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.normal),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "มูลค่าคงเหลือ",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.normal),
                  )),
            ),
          ]),
        ],
      ),
    );

    List<Widget> data = [];
    bool isEvenRow = true;
    TextStyle itemStyle =
        TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold);
    TextStyle detailStyle =
        TextStyle(fontSize: fontSize, fontWeight: FontWeight.normal);

    for (var item in dataList) {
      data.add(Container(
        padding: EdgeInsets.only(left: 10, right: 10),
        decoration: BoxDecoration(
          color: isEvenRow ? rowEvenColor : rowOddColor,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: Row(children: [
          Expanded(
            flex: 1,
            child: Padding(
                padding: EdgeInsets.all(4),
                child: Text(
                  item.barcode,
                  style: itemStyle,
                )),
          ),
          Expanded(
            flex: 2,
            child: Padding(
                padding: EdgeInsets.all(4),
                child: Text(
                  item.name,
                  style: itemStyle,
                )),
          ),
          Expanded(
            flex: 1,
            child: Padding(
                padding: EdgeInsets.all(4),
                child: Text(
                  "${item.unitCode} ${item.unitName}",
                  style: itemStyle,
                )),
          ),
        ]),
      ));
      // details
      for (var detail in item.details) {
        String extendedDescription = "";
        double qtyAdd = 0.0;
        double costAdd = 0.0;
        double amountAdd = 0.0;
        double qtySub = 0.0;
        double costSub = 0.0;
        double amountSub = 0.0;

        if (detail.totalQty > 0) {
          qtyAdd = detail.totalQty * (detail.unitStand / detail.unitDivide);
          costAdd = detail.unitCost;
          amountAdd = detail.calcAmount;
        } else {
          qtySub = (detail.totalQty * (detail.unitStand / detail.unitDivide));
          costSub = detail.unitCost;
          amountSub = detail.calcAmount;
        }
        if (detail.barcodeuse != item.barcode) {
          extendedDescription =
              "${detail.barcodeuse} (${global.formatNumberRemoveBotttom(detail.unitStand)}/${global.formatNumberRemoveBotttom(detail.unitDivide)})";
        }
        if (detail.docRef != "") {
          if (extendedDescription.isNotEmpty) {
            extendedDescription += " ";
          }
          extendedDescription += "(#${detail.docRef})";
        }

        data.add(Container(
          padding: EdgeInsets.only(left: 10, right: 10),
          decoration: BoxDecoration(
            color: isEvenRow ? rowEvenColor : rowOddColor,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
          ),
          child: Row(children: [
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    global.docDateTimeFormateDDMMYYY(detail.docDateTime),
                    style: detailStyle,
                  )),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    detail.docNo,
                    style: detailStyle,
                  )),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    extendedDescription,
                    style: detailStyle,
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    "${global.getTransFlagText(detail.transFlag)}:${detail.transFlag}",
                    style: detailStyle,
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    detail.unitCode,
                    style: detailStyle,
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    "${detail.whCode}/${detail.locationCode}",
                    style: detailStyle,
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    global.formatNumber(qtyAdd),
                    textAlign: TextAlign.right,
                    style: detailStyle.copyWith(color: Colors.green.shade700),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    global.formatNumber(costAdd),
                    textAlign: TextAlign.right,
                    style: detailStyle.copyWith(color: Colors.green.shade700),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    global.formatNumber(amountAdd),
                    textAlign: TextAlign.right,
                    style: detailStyle.copyWith(color: Colors.green.shade700),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    global.formatNumber(qtySub * -1),
                    textAlign: TextAlign.right,
                    style: detailStyle.copyWith(color: Colors.red.shade700),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    global.formatNumber(costSub),
                    textAlign: TextAlign.right,
                    style: detailStyle.copyWith(color: Colors.red.shade700),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    global.formatNumber(amountSub * -1),
                    textAlign: TextAlign.right,
                    style: detailStyle.copyWith(color: Colors.red.shade700),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    global.formatNumber(detail.balanceQty),
                    textAlign: TextAlign.right,
                    style: detailStyle,
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    global.formatNumber(detail.averageCost),
                    textAlign: TextAlign.right,
                    style: detailStyle,
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    global.formatNumber(detail.balanceAmount),
                    textAlign: TextAlign.right,
                    style: detailStyle,
                  )),
            ),
          ]),
        ));
      }

      isEvenRow = !isEvenRow;
    }

    resultScreenWidget = Container(
      margin: EdgeInsets.all(8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            header,
            Expanded(
              child: dataList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox,
                              size: 48, color: Colors.grey.shade400),
                          SizedBox(height: 16),
                          Text(
                            "ไม่พบข้อมูลตามเงื่อนไขที่เลือก",
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 15),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "กรุณาเปลี่ยนเงื่อนไขการค้นหาและลองใหม่อีกครั้ง",
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      controller: scrollController,
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: data,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );

    return resultScreenWidget;
  }

  Future<void> reloadData(int offset, int limit) async {
    try {
      var payload = {
        "shop_id": global.getShopId(),
        "command_id": "data_json",
        "guid": guid,
        "offset": offset.toString(),
        "limit": limit.toString(),
      };

      var jsonResult = await global.reportServiceGet(payload);

      if (jsonResult['status'] == 'error') {
        throw Exception('API Error: ${jsonResult['message']}');
      }
      for (var item in jsonResult['data']) {
        try {
          dataList.add(ReportStockMovementModel.fromJson(
              jsonDecode(utf8.decode(base64.decode(item)))));
        } catch (e) {
          if (kDebugMode) {
            print("Error decoding item: $e");
          }
        }
      }
    } catch (e, t) {
      if (kDebugMode) {
        print("Error: $e\n$t");
      }
      resultScreenWidget = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: errorColor, size: 48),
            SizedBox(height: 16),
            Text("ไม่สามารถแสดงผลได้",
                style:
                    TextStyle(color: errorColor, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("$e", style: TextStyle(color: Colors.grey.shade700)),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text("ลองใหม่อีกครั้ง"),
              onPressed: () async {
                dataList.clear();
                await reloadData(0, dataOffset);
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    renderData(dataList);
  }

  Widget _buildHelpPanel() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: showHelp ? null : 0,
      child: Card(
        margin: EdgeInsets.all(8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: helpColor,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline, color: primaryColor, size: 24),
                  SizedBox(width: 12),
                  Text(
                    "วิธีการใช้งานรายงานเคลื่อนไหวสินค้า/ต้นทุน",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryColor,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade700),
                    onPressed: () {
                      setState(() {
                        showHelp = false;
                      });
                    },
                    tooltip: "ปิดหน้าต่างช่วยเหลือ",
                  )
                ],
              ),
              Divider(color: secondaryColor, thickness: 1.5),
              _buildHelpStep(
                "1",
                "เลือกวันที่",
                "เลือกวันที่ที่ต้องการแสดง วันที่เริ่มต้น และ วันที่สิ้นสุด",
                Icons.calendar_today,
              ),
              _buildHelpStep(
                "2",
                "ตัวเลือกการแสดงผล",
                "เลือกแสดงเฉพาะสินค้าที่มีการเคลื่อนไหวหรือแสดงทั้งหมด",
                Icons.filter_alt,
              ),
              _buildHelpStep(
                "3",
                "เลือกสินค้า",
                "เลือกสินค้าที่ต้องการแสดง หรือไม่เลือกเพื่อแสดงทั้งหมด",
                Icons.inventory,
              ),
              _buildHelpStep(
                "4",
                "เลือกคลังสินค้า",
                "เลือกคลังสินค้าที่ต้องการแสดง หรือไม่เลือกเพื่อแสดงทั้งหมด",
                Icons.store,
              ),
              _buildHelpStep(
                "5",
                "ประมวลผล",
                "กดปุ่ม \"ประมวลผล\" เพื่อสร้างรายงาน",
                Icons.search,
              ),
              _buildHelpStep(
                "6",
                "ดูผลลัพธ์",
                "หลังจากประมวลผลเสร็จ ดูผลลัพธ์ที่แท็บ \"แสดงผล\" หรือดูในรูปแบบ PDF ที่แท็บ \"PDF\"",
                Icons.visibility,
              ),
              SizedBox(height: 8),
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.help_outline),
                  label: Text("ซ่อนคำแนะนำ"),
                  onPressed: () {
                    setState(() {
                      showHelp = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.grey.shade800,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpStep(
      String step, String title, String description, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                step,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: primaryColor),
                    SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionSelect() {
    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _buildHelpPanel(),
            _buildReportHeader(),
            SizedBox(height: 12),
            _buildDateSelectionPanel(),
            SizedBox(height: 12),
            _buildFilterOptionsPanel(),
            SizedBox(height: 12),
            _buildProductSelectionPanel(),
            SizedBox(height: 12),
            _buildWarehouseSelectionPanel(),
            SizedBox(height: 12),
            _buildProcessButtonPanel(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHeader() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, primaryColor.withBlue(255)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Text(
                  "รายงานเคลื่อนไหวสินค้า/ต้นทุน",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Divider(color: Colors.white.withOpacity(0.3), height: 24),
            Text(
              "เลือกเงื่อนไขการแสดงผลรายงานเคลื่อนไหวสินค้า/ต้นทุน",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelectionPanel() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: primaryColor, size: 20),
                SizedBox(width: 10),
                Text("วันที่รายงาน", style: titleStyle),
                Tooltip(
                  message: "เลือกวันที่",
                  child: Icon(Icons.info_outline,
                      size: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              "โปรดเลือกวันที่ที่ต้องการ",
              style: normalStyle,
            ),
            SizedBox(height: 12),
            CustomDatePicker(
              labelText: 'เริ่มจากวันที่',
              initialDate: conditionBeginDate,
              useBuddhistCalendar: true,
              onDateSelected: (date) {
                if (date != null) {
                  setState(() {
                    conditionBeginDate = date;
                  });
                }
              },
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                labelText: 'เลือกวันที่',
                hintText: 'เลือกวันที่ที่ต้องการแสดงยอด',
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            SizedBox(height: 12),
            CustomDatePicker(
              labelText: 'สิ้นสุดวันที่',
              initialDate: conditionFinalDate,
              useBuddhistCalendar: true,
              onDateSelected: (date) {
                if (date != null) {
                  setState(() {
                    conditionFinalDate = date;
                  });
                }
              },
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                labelText: 'เลือกวันที่',
                hintText: '',
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOptionsPanel() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_alt, color: primaryColor, size: 20),
                SizedBox(width: 10),
                Text("ตัวเลือกการแสดงผล", style: titleStyle),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "กำหนดรูปแบบการแสดงผลรายงานตามต้องการ",
              style: normalStyle,
            ),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: CheckboxListTile(
                title: Text("แสดงเฉพาะสินค้าที่มีการเคลื่อนไหว",
                    style: emphasisStyle),
                subtitle: Text(
                  "หากเลือก ตัวเลือกนี้ ระบบจะแสดงเฉพาะสินค้าที่มีการเคลื่อนไหวในช่วงวันที่ที่เลือก",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                value: reportCondition.showOnlyBalance,
                secondary: Icon(
                  reportCondition.showOnlyBalance
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: primaryColor,
                ),
                onChanged: (value) {
                  setState(() {
                    reportCondition.showOnlyBalance = value!;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelectionPanel() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory, color: primaryColor, size: 20),
                SizedBox(width: 10),
                Text("เลือกสินค้า", style: titleStyle),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "เลือกสินค้าที่ต้องการแสดงในรายงาน หากไม่เลือก ระบบจะแสดงสินค้าทั้งหมด",
              style: normalStyle,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      var result = await showDialog(
                        context: context,
                        builder: (context) => SelectProductBarcodeWidget(),
                      );
                      if (result != null) {
                        for (var item in result) {
                          if (!reportCondition.conditionBarcodeList
                              .contains(item)) {
                            reportCondition.conditionBarcodeList.add(item);
                          }
                        }
                        await reportCondition.reloadWareHouseCode();
                        setState(() {});
                      }
                    },
                    icon: Icon(Icons.add_shopping_cart, size: 18),
                    label: Text("เลือกสินค้า"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: reportCondition.conditionBarcodeList.isNotEmpty
                      ? () async {
                          setState(() {
                            reportCondition.conditionBarcodeList.clear();
                          });
                          await reportCondition.reloadWareHouseCode();
                        }
                      : null,
                  icon: Icon(Icons.refresh, size: 18),
                  label: Text("เริ่มใหม่"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (reportCondition.conditionBarcodeList.isEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.grey.shade600, size: 18),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "ไม่มีสินค้าที่เลือก ระบบจะแสดงสินค้าทั้งหมด",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (reportCondition.conditionBarcodeList.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_cart,
                          size: 16, color: Colors.grey.shade700),
                      SizedBox(width: 8),
                      Text(
                        "สินค้าที่เลือก (${reportCondition.conditionBarcodeList.length} รายการ):",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          reportCondition.conditionBarcodeList.map((item) {
                        return Chip(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                          label: Text(item),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.blue.shade200),
                          labelStyle: TextStyle(
                              color: primaryColor, fontWeight: FontWeight.w500),
                          deleteIconColor: Colors.red.shade400,
                          avatar: Icon(Icons.inventory_2_outlined,
                              size: 16, color: primaryColor),
                          elevation: 1,
                          shadowColor: Colors.grey.shade200,
                          onDeleted: () async {
                            reportCondition.conditionBarcodeList.remove(item);
                            await reportCondition.reloadWareHouseCode();
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseSelectionPanel() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, color: primaryColor, size: 20),
                SizedBox(width: 10),
                Text("เลือกคลังสินค้า", style: titleStyle),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "เลือกคลังสินค้าที่ต้องการแสดงในรายงาน หากไม่เลือก ระบบจะแสดงทุกคลังสินค้า",
              style: normalStyle,
            ),
            SizedBox(height: 16),
            reportCondition.selectWareHouseWidget(
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessButtonPanel() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "เมื่อตั้งค่าเงื่อนไขเรียบร้อยแล้ว กดปุ่ม \"ประมวลผล\" เพื่อสร้างรายงาน",
              style: emphasisStyle,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.play_arrow),
                    label: Text(
                      "ประมวลผลรายงาน",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: Colors.blue.shade300,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      await _processReport();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Replace the condition with proper check based on processState
            if (processState != global.ProcessState.idle)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: () {
                    switch (processState) {
                      case global.ProcessState.processing:
                        return Colors.blue.shade50;
                      case global.ProcessState.success:
                        return Colors.green.shade50;
                      case global.ProcessState.error:
                        return Colors.red.shade50;
                      default:
                        return Colors.grey.shade50;
                    }
                  }(),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: () {
                      switch (processState) {
                        case global.ProcessState.processing:
                          return Colors.blue.shade300;
                        case global.ProcessState.success:
                          return Colors.green.shade300;
                        case global.ProcessState.error:
                          return Colors.red.shade300;
                        default:
                          return Colors.grey.shade300;
                      }
                    }(),
                  ),
                ),
                child: processWidgetStatus,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _processReport() async {
    dataList.clear();
    setState(() {
      // Set state to processing first
      processState = global.ProcessState.processing;
      processWidgetStatus = Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: primaryColor),
          ),
          SizedBox(width: 12),
          Text(
            "กำลังประมวลผล...",
            style: TextStyle(color: primaryColor),
          ),
        ],
      );
    });

    try {
      // Add a small delay to ensure the spinner is shown
      await Future.delayed(Duration(milliseconds: 300));

      String barCodeList = "";
      for (var item in reportCondition.conditionBarcodeList) {
        if (barCodeList.isNotEmpty) {
          barCodeList += ",";
        }
        barCodeList += item;
      }

      var payload = {
        "shop_id": global.getShopId(),
        "command_id": "stock_product_movement_and_cost_process",
        "condition": "1",
        "movement_only": reportCondition.showOnlyWithMovement.toString(),
        "barcode_list": barCodeList.toString(),
        "warehouse_list": reportCondition.conditionWareHouseCodeList,
        "from_date":
            "${conditionBeginDate.year}-${conditionBeginDate.month.toString().padLeft(2, '0')}-${conditionBeginDate.day.toString().padLeft(2, '0')}",
        "final_date":
            "${conditionFinalDate.year}-${conditionFinalDate.month.toString().padLeft(2, '0')}-${conditionFinalDate.day.toString().padLeft(2, '0')}",
      };

      var jsonPayload = jsonEncode(payload);
      var jsonResult = await global.reportServicePost(jsonPayload);

      if (jsonResult['code'] == 200) {
        pdfCreated = false;
        pdfDownloaded = false;
        setState(() {
          processSuccess = true;
          processState = global.ProcessState.success;
          processWidgetStatus = Row(
            children: [
              Icon(Icons.check_circle, color: successColor),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ประมวลผลสำเร็จ",
                      style: TextStyle(
                        color: successColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "คลิกที่แท็บ \"แสดงผล\" หรือ \"PDF\" เพื่อดูผลลัพธ์",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        });

        guid = jsonResult['guid'];
        tabController.index = 1;
        await reloadData(0, dataOffset);
        setState(() {});
      } else {
        setState(() {
          processSuccess = false;
          processState = global.ProcessState.error;
          processWidgetStatus = Row(
            children: [
              Icon(Icons.error, color: errorColor),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  jsonResult['message'],
                  style: TextStyle(
                    color: errorColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        });
      }
    } catch (e) {
      setState(() {
        processSuccess = false;
        processState = global.ProcessState.error;
        processWidgetStatus = Row(
          children: [
            Icon(Icons.error, color: errorColor),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "เกิดข้อผิดพลาด: $e",
                style: TextStyle(
                  color: errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      });
    }
  }

  Widget _buildResultTab() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, primaryColor.withBlue(255)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade300,
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory_2, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text(
                    "รายงานเคลื่อนไหวสินค้า/ต้นทุน",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )),
                  Tooltip(
                    message: "ลดขนาดตัวอักษร",
                    child: IconButton(
                      icon: Icon(Icons.remove, color: Colors.white),
                      onPressed: () {
                        if (resultFontScale > 0.5) {
                          setState(() {
                            resultFontScale = resultFontScale - 0.1;
                            renderData(dataList);
                          });
                        }
                      },
                    ),
                  ),
                  Tooltip(
                    message: "เพิ่มขนาดตัวอักษร",
                    child: IconButton(
                      icon: Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          resultFontScale = resultFontScale + 0.1;
                          renderData(dataList);
                        });
                      },
                    ),
                  ),
                ],
              ),
              Divider(color: Colors.white.withOpacity(0.2), height: 16),
              Text(
                "ข้อมูล ณ วันที่ ${conditionFinalDate.day}/${conditionFinalDate.month}/${conditionFinalDate.year}",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                "* ใช้ปุ่ม + หรือ - เพื่อปรับขนาดตัวอักษร และเลื่อนลงเพื่อดูข้อมูลเพิ่มเติม",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9), fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: dataList.isEmpty && processSuccess
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      SizedBox(height: 16),
                      Text("กำลังโหลดข้อมูล...", style: emphasisStyle),
                    ],
                  ),
                )
              : resultScreenWidget,
        ),
      ],
    );
  }

  Widget _buildPdfTab() {
    return Container(
      color: backgroundColor,
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: primaryColor),
                      SizedBox(width: 12),
                      Text("การใช้งาน PDF", style: titleStyle),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "ในแท็บนี้ คุณสามารถค้นหาข้อความในเอกสาร บันทึก PDF ไว้ในอุปกรณ์ หรือสั่งพิมพ์รายงานได้",
                    style: normalStyle,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: pdfSearchController,
                          decoration: InputDecoration(
                            labelText: 'ค้นหาข้อความ',
                            hintText: 'พิมพ์คำที่ต้องการค้นหาในเอกสาร',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            prefixIcon: Icon(Icons.search, color: primaryColor),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade400),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.clear,
                                      color: Colors.grey.shade600),
                                  tooltip: "ล้างการค้นหา",
                                  onPressed: () {
                                    pdfSearchController.clear();
                                    pdfViewerController.searchText("");
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.search, color: primaryColor),
                                  tooltip: "ค้นหาข้อความ",
                                  onPressed: () {
                                    pdfViewerController
                                        .searchText(pdfSearchController.text);
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                          onSubmitted: (value) {
                            pdfViewerController.searchText(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.save),
                          label: Text("บันทึกเป็นไฟล์ PDF"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: pdfDownloaded
                              ? () async {
                                  final dateTimeNow = DateTime.now();
                                  final formattedDate =
                                      "${dateTimeNow.year}-${dateTimeNow.month}-${dateTimeNow.day}-${dateTimeNow.hour}-${dateTimeNow.minute}-${dateTimeNow.second}";
                                  final pdfFileName =
                                      "รายงานเคลื่อนไหวสินค้า/ต้นทุน_$formattedDate.pdf";
                                  savePdf(pdfData, pdfFileName, context);
                                }
                              : null,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.print),
                          label: Text("พิมพ์รายงาน"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: pdfDownloaded
                              ? () async {
                                  await printing.Printing.layoutPdf(
                                    usePrinterSettings: true,
                                    dynamicLayout: true,
                                    onLayout:
                                        (pdf.PdfPageFormat format) async =>
                                            pdfData,
                                  );
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: pdfDownloaded
                      ? pdfViewWidget
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: primaryColor),
                              SizedBox(height: 16),
                              Text("กำลังโหลด PDF กรุณารอสักครู่...",
                                  style: emphasisStyle),
                              if (!processSuccess)
                                Padding(
                                  padding: EdgeInsets.only(top: 16),
                                  child: Text(
                                    "ยังไม่ได้ประมวลผลรายงาน กรุณากลับไปที่แท็บ \"เงื่อนไข\" และกดปุ่ม \"ประมวลผล\"",
                                    style:
                                        TextStyle(color: Colors.grey.shade700),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          automaticallyImplyLeading: false,
          elevation: 4,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              if (processSuccess == true) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.warning, color: accentColor),
                          SizedBox(width: 12),
                          Text("ยืนยันการออกจากรายงาน"),
                        ],
                      ),
                      content: const Text("คุณต้องการออกจากรายงานนี้หรือไม่?"),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: Text("ยกเลิก",
                              style: TextStyle(color: Colors.grey.shade700)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("ตกลง"),
                        ),
                      ],
                    );
                  },
                );
              } else {
                Navigator.of(context).pop();
              }
            },
            tooltip: "ปิดหน้ารายงาน",
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.help_outline, color: Colors.white),
              onPressed: () {
                setState(() {
                  showHelp = !showHelp;
                });
              },
              tooltip: "แสดง/ซ่อน คำอธิบายการใช้งาน",
            ),
          ],
          title: TabBar(
            controller: tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Icon(Icons.settings),
                    Text("เงื่อนไข"),
                  ],
                ),
              ),
              Tab(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Icon(Icons.table_chart),
                    Text("แสดงผล"),
                  ],
                ),
              ),
              Tab(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Icon(Icons.picture_as_pdf),
                    Text("PDF"),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(controller: tabController, children: [
          _buildConditionSelect(),
          _buildResultTab(),
          _buildPdfTab(),
        ]),
        bottomNavigationBar: processSuccess
            ? Container(
                color: Colors.blue.shade50,
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: primaryColor, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "เลือกแท็บ \"แสดงผล\" สำหรับดูข้อมูล หรือ \"PDF\" สำหรับพิมพ์และบันทึกรายงาน",
                      style: TextStyle(
                          color: primaryColor, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
