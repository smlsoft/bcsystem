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

class ReportStockBalanceLocationBarcode extends StatefulWidget {
  const ReportStockBalanceLocationBarcode({super.key});

  @override
  State<ReportStockBalanceLocationBarcode> createState() =>
      _ReportStockBalanceLocationBarcodeState();
}

class _ReportStockBalanceLocationBarcodeState
    extends State<ReportStockBalanceLocationBarcode>
    with SingleTickerProviderStateMixin {
  bool processSuccess = false;
  bool pdfCreated = false;
  bool pdfDownloaded = false;
  String pdfPath = "";
  String guid = "";
  Widget processWidgetStatus = Container();
  Widget resultScreenWidget = Container();
  Widget pdfViewWidget = Container();
  PdfViewerController pdfViewerController = PdfViewerController();
  TextEditingController pdfSearchController = TextEditingController();
  late Uint8List pdfData;
  DateTime conditionFinalDate = DateTime.now();
  late TabController tabController;
  double resultFontScale = 1.0;
  List<ReportStockBalanceLocationBarcodeModel> dataList = [];
  late ReportStockConditionClass reportCondition;
  ScrollController scrollController = ScrollController();
  int dataOffset = 200;
  bool isLoadingMore = false;
  bool showHelpTips = true;

  // Design constants
  final Color primaryColor = Colors.indigo;
  final Color secondaryColor = Colors.teal;
  final Color accentColor = Colors.amber;
  final Color backgroundColor = Colors.grey.shade50;
  final Color cardColor = Colors.white;
  final Color headerColor = Colors.indigo.shade100;
  final Color footerColor = Colors.indigo.shade50;
  final Color rowEvenColor = Colors.grey.shade50;
  final Color rowOddColor = Colors.white;
  final Color warehouseColor = Colors.amber.shade50;
  final Color locationColor = Colors.teal.shade50;
  final Color successColor = Colors.green.shade600;
  final Color errorColor = Colors.red.shade600;
  final Color warningColor = Colors.orange.shade600;
  final Color infoColor = Colors.blue.shade600;

  @override
  void initState() {
    super.initState();
    reportCondition = ReportStockConditionClass(
      onStateUpdate: () {
        setState(() {});
      },
    );
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
        setState(() {
          isLoadingMore = true;
        });
        reloadData(dataList.length, dataOffset).then((_) {
          setState(() {
            isLoadingMore = false;
          });
        }).catchError((error) {
          setState(() {
            isLoadingMore = false;
          });
        });
      }
    });
    reportCondition.reloadWareHouseCode();
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
          "command_id": "stock_balance_by_location_and_product_create_pdf",
          "guid": guid,
          "condition": "1",
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
              Text(
                "ไม่สามารถโหลด PDF ได้",
                style: TextStyle(
                    color: errorColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "กรุณาลองประมวลผลรายงานใหม่อีกครั้ง",
                style: TextStyle(color: Colors.grey.shade700),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text("ลองใหม่"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () async {
                  pdfCreated = false;
                  await reloadPdf();
                },
              )
            ],
          ),
        );
      });
    }
  }

  Widget renderData(List<ReportStockBalanceLocationBarcodeModel> dataList) {
    double fontSize = 12.0 * resultFontScale;

    // ส่วนหัวตาราง (Header)
    var header = Container(
      decoration: BoxDecoration(
        color: headerColor,
        border: Border.all(color: primaryColor.withOpacity(0.5)),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Row(children: [
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "รหัสคลังสินค้า",
                    style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: primaryColor),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "ที่เก็บ",
                    style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: primaryColor),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "รหัสสินค้า/บาร์โค้ด",
                    style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: primaryColor),
                  )),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "ชื่อสินค้า",
                    style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: primaryColor),
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "หน่วยนับ",
                    style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: primaryColor),
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
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: primaryColor),
                  )),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Text(
                    "จำนวนคงเหลือ(คำอ่าน)",
                    style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: primaryColor),
                  )),
            ),
          ]),
        ],
      ),
    );

    // ส่วนข้อมูล (Data)
    List<Widget> data = [];
    bool isEvenRow = true;
    TextStyle itemStyle =
        TextStyle(fontSize: fontSize, fontWeight: FontWeight.normal);

    if (dataList.isEmpty) {
      data.add(Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              "ไม่พบข้อมูลตามเงื่อนไขที่เลือก",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600),
            ),
            SizedBox(height: 8),
            Text(
              "ลองเปลี่ยนเงื่อนไขการค้นหาและประมวลผลใหม่อีกครั้ง",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ));
    } else {
      for (var item in dataList) {
        data.add(Container(
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
                    item.whCode,
                    style: itemStyle,
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    item.locationCode,
                    style: itemStyle,
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    item.barCodeMain,
                    style: itemStyle,
                  )),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    item.barCodeName,
                    style: itemStyle,
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    "${item.unitCode ?? ""}/${item.unitName ?? ""}",
                    style: itemStyle,
                  )),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    global.formatNumber(item.balanceQty ?? 0),
                    style: itemStyle,
                    textAlign: TextAlign.right,
                  )),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    item.balanceWord ?? "",
                    style: itemStyle,
                  )),
            ),
          ]),
        ));
        isEvenRow = !isEvenRow;
      }
    }

    resultScreenWidget = Container(
      margin: EdgeInsets.all(8),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            header,
            Expanded(
              child: SingleChildScrollView(
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
                      child: Column(children: data),
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
          dataList.add(ReportStockBalanceLocationBarcodeModel.fromJson(
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
            Text(
              "ไม่สามารถแสดงผลได้",
              style: TextStyle(
                  color: errorColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              "$e",
              style: TextStyle(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text("ลองใหม่"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              onPressed: () async {
                dataList.clear();
                await reloadData(0, dataOffset);
                setState(() {});
              },
            ),
          ],
        ),
      );
    }
    renderData(dataList);
  }

  // คำแนะนำวิธีการใช้งาน
  Widget _buildHelpTips() {
    if (!showHelpTips) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: primaryColor,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  "คำแนะนำวิธีการใช้งาน",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade700),
                  onPressed: () {
                    setState(() {
                      showHelpTips = false;
                    });
                  },
                  tooltip: "ซ่อนคำแนะนำ",
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHelpStep(
                  icon: Icons.date_range,
                  title: "1. เลือกวันที่",
                  description: "เลือกวันที่ที่ต้องการดูยอดคงเหลือของสินค้า",
                ),
                _buildHelpStep(
                  icon: Icons.filter_list,
                  title: "2. ตั้งค่าตัวกรอง",
                  description:
                      "เลือกแสดงเฉพาะสินค้าที่มียอดคงเหลือหรือแสดงทั้งหมด",
                ),
                _buildHelpStep(
                  icon: Icons.inventory_2,
                  title: "3. เลือกสินค้า",
                  description:
                      "เลือกสินค้าที่ต้องการแสดง หรือไม่เลือกเพื่อแสดงทั้งหมด",
                ),
                _buildHelpStep(
                  icon: Icons.location_on,
                  title: "4. เลือกคลังและตำแหน่ง",
                  description: "เลือกคลังสินค้าและตำแหน่งที่ต้องการแสดง",
                ),
                _buildHelpStep(
                  icon: Icons.play_arrow,
                  title: "5. ประมวลผล",
                  description: "กดปุ่ม \"ประมวลผลรายงาน\" เพื่อแสดงผล",
                ),
                _buildHelpStep(
                  icon: Icons.tab,
                  title: "6. ดูผลลัพธ์",
                  description:
                      "ดูรายงานในแท็บ \"แสดงผล\" หรือ PDF ในแท็บ \"PDF\"",
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpStep({
    required IconData icon,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          margin: EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
              if (!isLast)
                Container(
                  height: 24,
                  margin: EdgeInsets.only(left: 8),
                  child: VerticalDivider(
                    color: primaryColor.withOpacity(0.3),
                    thickness: 1,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConditionSelect() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // คำแนะนำวิธีการใช้งาน
          _buildHelpTips(),

          // ส่วนหัวรายงาน
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.place, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        "รายงานสินค้าคงเหลือ",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "ตามคลังสินค้า • ที่เก็บ • สินค้า",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "รายงานนี้แสดงยอดคงเหลือของสินค้าตามคลังสินค้าและตำแหน่งที่เก็บ ช่วยให้คุณติดตามสินค้าได้อย่างมีประสิทธิภาพ",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // เลือกวันที่รายงาน
          _buildReportSection(
            icon: Icons.calendar_today,
            title: "วันที่รายงาน",
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "เลือกวันที่ที่ต้องการทราบยอดคงเหลือของสินค้า",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 16),
                CustomDatePicker(
                  labelText: 'ยอดคงเหลือ ณ. วันที่',
                  initialDate: conditionFinalDate,
                  useBuddhistCalendar: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.event, color: secondaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: secondaryColor, width: 2),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    filled: true,
                    fillColor: Colors.white,
                    labelText: "เลือกวันที่",
                    hintText: "กดที่นี่เพื่อเลือกวันที่",
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                  ),
                  onDateSelected: (date) {
                    if (date != null) {
                      setState(() {
                        conditionFinalDate = date;
                      });
                    }
                  },
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: infoColor,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "รายงานจะแสดงข้อมูลยอดคงเหลือ ณ สิ้นวันของวันที่เลือก",
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: infoColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ตัวกรองข้อมูล
          _buildReportSection(
            icon: Icons.filter_list,
            title: "ตัวกรองข้อมูล",
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: secondaryColor.withOpacity(0.2)),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      "แสดงเฉพาะสินค้าที่มียอดคงเหลือ",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    subtitle: Text(
                      "ซ่อนรายการที่มีจำนวน 0 ชิ้น ช่วยให้รายงานกระชับขึ้น",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    value: reportCondition.showOnlyBalance,
                    activeColor: secondaryColor,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    secondary: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: reportCondition.showOnlyBalance
                            ? secondaryColor.withOpacity(0.1)
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        reportCondition.showOnlyBalance
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: reportCondition.showOnlyBalance
                            ? secondaryColor
                            : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        reportCondition.showOnlyBalance = value;
                      });
                    },
                  ),
                ),
                SizedBox(height: 8),
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: reportCondition.showOnlyBalance ? 48 : 0,
                  curve: Curves.easeInOut,
                  child: SingleChildScrollView(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 16, color: Colors.green.shade700),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "รายงานจะแสดงเฉพาะรายการที่มีสินค้าคงเหลือมากกว่า 0 เท่านั้น",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // เลือกสินค้า
          _buildReportSection(
            icon: Icons.inventory_2,
            title: "เลือกสินค้า",
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "เลือกสินค้าที่ต้องการแสดงในรายงาน หากไม่เลือกจะแสดงสินค้าทั้งหมด",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
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
                    OutlinedButton.icon(
                      onPressed:
                          (reportCondition.conditionBarcodeList.isNotEmpty)
                              ? () async {
                                  reportCondition.conditionBarcodeList.clear();
                                  reportCondition.conditionWareHouseCodeList
                                      .clear();
                                  await reportCondition.reloadWareHouseCode();
                                }
                              : null,
                      icon: Icon(Icons.refresh, size: 18),
                      label: Text("เริ่มใหม่"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: warningColor,
                        side: BorderSide(color: warningColor),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shopping_cart,
                              size: 16, color: primaryColor),
                          SizedBox(width: 8),
                          Text(
                            "สินค้าที่เลือก${reportCondition.conditionBarcodeList.isNotEmpty ? ' (${reportCondition.conditionBarcodeList.length})' : ''}:",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      reportCondition.conditionBarcodeList.isEmpty
                          ? Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 12),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 24,
                                      color: Colors.grey.shade400,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "ยังไม่ได้เลือกสินค้า (จะแสดงสินค้าทั้งหมด)",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: reportCondition.conditionBarcodeList
                                  .map((item) {
                                return Chip(
                                  avatar: Icon(Icons.inventory,
                                      size: 16, color: secondaryColor),
                                  label: Text(item),
                                  labelStyle: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  backgroundColor: Colors.white,
                                  elevation: 1,
                                  shadowColor: Colors.grey.shade200,
                                  side: BorderSide(
                                      color: secondaryColor.withOpacity(0.3)),
                                  deleteIconColor: errorColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  onDeleted: () async {
                                    setState(() {
                                      reportCondition.conditionBarcodeList
                                          .remove(item);
                                    });
                                    await reportCondition.reloadWareHouseCode();
                                  },
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // เลือกคลังสินค้าและตำแหน่ง
          _buildReportSection(
            icon: Icons.location_on,
            title: "คลังสินค้าและตำแหน่ง",
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.store, color: Colors.amber.shade800),
                          SizedBox(width: 8),
                          Text(
                            "เลือกคลังสินค้า",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      reportCondition.selectWareHouseWidget(
                        primaryColor: secondaryColor,
                        secondaryColor: secondaryColor,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.teal.shade800),
                          SizedBox(width: 8),
                          Text(
                            "เลือกตำแหน่งที่เก็บ",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade900,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      reportCondition.selectLocationWidget(
                        primaryColor: secondaryColor,
                        secondaryColor: secondaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ปุ่มประมวลผล
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                )
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ประมวลผลรายงาน",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "เมื่อตั้งค่าเงื่อนไขเรียบร้อยแล้ว กดปุ่มด้านล่างเพื่อประมวลผลรายงาน",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.play_arrow),
                    label: Text(
                      "ประมวลผลรายงาน",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: secondaryColor.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await _processReport();
                    },
                  ),
                ),
                SizedBox(height: 16),
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  height: processWidgetStatus is Container &&
                          (processSuccess || !processSuccess)
                      ? null
                      : 0,
                  child: processWidgetStatus,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSection({
    required IconData icon,
    required String title,
    required Widget content,
    bool isLastSection = false,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, isLastSection ? 0 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: primaryColor),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(20),
            child: content,
          ),
        ],
      ),
    );
  }

  Future<void> _processReport() async {
    dataList.clear();
    setState(() {
      processWidgetStatus = Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: infoColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: infoColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(infoColor),
              ),
            ),
            SizedBox(width: 12),
            Text(
              "กำลังประมวลผลรายงาน...",
              style: TextStyle(
                color: infoColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    });

    try {
      String barCodeList = "";
      for (var item in reportCondition.conditionBarcodeList) {
        if (barCodeList.isNotEmpty) {
          barCodeList += ",";
        }
        barCodeList += item;
      }

      var payload = {
        "shop_id": global.getShopId(),
        "command_id": "stock_balance_by_location_and_product_process",
        "condition": "1",
        "balance_only": reportCondition.showOnlyBalance.toString(),
        "barcode_list": barCodeList.toString(),
        "warehouse_list": reportCondition.conditionWareHouseCodeList,
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
          processWidgetStatus = Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: successColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: successColor),
                    SizedBox(width: 12),
                    Text(
                      "ประมวลผลสำเร็จ",
                      style: TextStyle(
                        color: successColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline, color: successColor, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "คลิกที่แท็บ \"แสดงผล\" เพื่อดูรายงาน หรือ \"PDF\" เพื่อพิมพ์/บันทึก",
                        style: TextStyle(
                          color: successColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
        guid = jsonResult['guid'];
        tabController.animateTo(1);
        await reloadData(0, dataOffset);
        setState(() {});
      } else {
        setState(() {
          processSuccess = false;
          processWidgetStatus = Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: errorColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: errorColor),
                    SizedBox(width: 12),
                    Text(
                      "ประมวลผลไม่สำเร็จ",
                      style: TextStyle(
                        color: errorColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  jsonResult['message'],
                  style: TextStyle(
                    color: errorColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        processSuccess = false;
        processWidgetStatus = Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: errorColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, color: errorColor),
                  SizedBox(width: 12),
                  Text(
                    "เกิดข้อผิดพลาด",
                    style: TextStyle(
                      color: errorColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                "$e",
                style: TextStyle(
                  color: errorColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      });
    }
  }

  Widget _buildResultsTab() {
    return Column(
      children: [
        // ส่วนหัวรายงาน
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, primaryColor],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.place, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "รายงานยอดคงเหลือตามคลังสินค้า/ที่เก็บ",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "ขนาดตัวอักษร",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            if (resultFontScale > 0.5) {
                              setState(() {
                                resultFontScale = resultFontScale - 0.1;
                                renderData(dataList);
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.remove,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            setState(() {
                              resultFontScale = resultFontScale + 0.1;
                              renderData(dataList);
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "ข้อมูล ณ วันที่ ${conditionFinalDate.day}/${conditionFinalDate.month}/${conditionFinalDate.year}",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ส่วนแสดงผลรายงาน
        if (!processSuccess)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 24),
                  Text(
                    "ยังไม่ได้ประมวลผลรายงาน",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "กลับไปที่แท็บ \"เงื่อนไข\" และกดปุ่ม \"ประมวลผลรายงาน\"",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: Icon(Icons.settings),
                    label: Text("ไปยังหน้าเงื่อนไข"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      tabController.animateTo(0);
                    },
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: dataList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(secondaryColor),
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          "กำลังโหลดข้อมูล...",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: secondaryColor,
                          ),
                        ),
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
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // คำอธิบาย
          Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: infoColor, size: 24),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "การใช้งาน PDF",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: infoColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "• คุณสามารถค้นหาข้อความในเอกสาร PDF ได้\n• บันทึกเอกสารเป็นไฟล์ PDF ไว้ในอุปกรณ์\n• สั่งพิมพ์รายงานผ่านเครื่องพิมพ์ที่เชื่อมต่อ",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ช่องค้นหาและปุ่มบันทึก/พิมพ์
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: pdfSearchController,
                    decoration: InputDecoration(
                      labelText: 'ค้นหาข้อความในเอกสาร',
                      hintText: 'พิมพ์คำที่ต้องการค้นหา',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon:
                                Icon(Icons.clear, color: Colors.grey.shade600),
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
                            },
                          ),
                        ],
                      ),
                    ),
                    onSubmitted: (value) {
                      pdfViewerController.searchText(value);
                    },
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
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: pdfDownloaded
                              ? () async {
                                  final dateTimeNow = DateTime.now();
                                  final formattedDate =
                                      "${dateTimeNow.year}-${dateTimeNow.month}-${dateTimeNow.day}-${dateTimeNow.hour}-${dateTimeNow.minute}-${dateTimeNow.second}";
                                  final pdfFileName =
                                      "รายงานสินค้าคงเหลือตามคลัง-ที่เก็บ_$formattedDate.pdf";
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
                            backgroundColor: secondaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
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
          SizedBox(height: 16),

          // แสดง PDF
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: !processSuccess
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 24),
                          Text(
                            "ยังไม่ได้ประมวลผลรายงาน",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "กลับไปที่แท็บ \"เงื่อนไข\" และกดปุ่ม \"ประมวลผลรายงาน\"",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: Icon(Icons.settings),
                            label: Text("ไปยังหน้าเงื่อนไข"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              tabController.animateTo(0);
                            },
                          ),
                        ],
                      ),
                    )
                  : !pdfDownloaded
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      secondaryColor),
                                ),
                              ),
                              SizedBox(height: 24),
                              Text(
                                "กำลังโหลด PDF...",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: pdfViewWidget,
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
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          automaticallyImplyLeading: false,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (processSuccess) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.warning, color: warningColor),
                          SizedBox(width: 12),
                          Text("ยืนยันการออกจากรายงาน"),
                        ],
                      ),
                      content: const Text("คุณต้องการออกจากรายงานนี้หรือไม่?"),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: Text(
                            "ยกเลิก",
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
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
            tooltip: "ย้อนกลับ",
          ),
          title: Text(
            "รายงานสินค้าคงเหลือตามที่เก็บ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.help_outline, color: Colors.white),
              tooltip: "แสดง/ซ่อนคำแนะนำ",
              onPressed: () {
                setState(() {
                  showHelpTips = !showHelpTips;
                });
              },
            ),
          ],
          bottom: TabBar(
            controller: tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(
                icon: Icon(Icons.settings),
                text: "เงื่อนไข",
              ),
              Tab(
                icon: Icon(Icons.table_chart),
                text: "แสดงผล",
              ),
              Tab(
                icon: Icon(Icons.picture_as_pdf),
                text: "PDF",
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: tabController,
          children: [
            _buildConditionSelect(),
            _buildResultsTab(),
            _buildPdfTab(),
          ],
        ),
        bottomNavigationBar: processSuccess
            ? Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  border: Border(
                    top: BorderSide(color: primaryColor.withOpacity(0.2)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: primaryColor, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "คำแนะนำ: เลือกแท็บ \"แสดงผล\" หรือ \"PDF\" เพื่อดูผลลัพธ์ของรายงาน",
                      style: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
