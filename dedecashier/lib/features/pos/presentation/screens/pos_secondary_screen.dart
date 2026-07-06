import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/json/customer_display_model.dart';
import 'package:dedecashier/model/json/pos_process_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/widgets/secondary_display.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:video_player/video_player.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

class PosSecondaryScreen extends StatefulWidget {
  const PosSecondaryScreen({super.key});

  @override
  PosSecondaryScreenState createState() => PosSecondaryScreenState();
}

class PosSecondaryScreenState extends State<PosSecondaryScreen> {
  // 1=Information, 2=Detail, 3=Pay
  int displayMode = 0;
  PosHoldProcessModel processResult = PosHoldProcessModel(code: "");
  final ItemScrollController detailScrollController = ItemScrollController();
  late Timer syncInformationTimer;
  int informationIndex = 0;
  Widget informationMedia = const SizedBox();
  int informationCountDownSecond = 0;
  late VideoPlayerController videoController;
  double sumTotalPayAmount = 0;
  double diffAmount = 0;
  double totalAfterDiscount = 0;
  int detailIndex = -1;
  late CustomerDisplayData receiveData;
  late CustomerDisplayQrData customerDisplayQrData;
  late CustomerDisplayPaySuccessData customerDisplayPaySuccessData;
  String customerDisplayCommand = "";
  String qrCodePayDataString = "";
  Widget qrGenerate = Container();
  List<InformationModel> infoList = [];
  @override
  void initState() {
    super.initState();

    syncInformationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // นับถอยหลัง Information (Image, Video)
      if (processResult.posProcess.details.isEmpty || detailIndex == -1) {
        if (infoList.isNotEmpty) {
          if (--informationCountDownSecond < 0) {
            changeMedia();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    syncInformationTimer.cancel();
    try {
      videoController.dispose();
    } catch (e) { AppLogger.debug("Intentionally ignored: `$e"); }
    super.dispose();
  }

  Widget detailWidget({
    required String productName,
    bool fullDetail = false,
    required bool isExtra,
    double qty = 0,
    double price = 0.0,
    double priceOriginal = 0.0,
    bool isActive = false,
    required double totalAmount,
    required TextStyle textStyle,
    required String barcode,
    required String unitName,
    required String imageUrl,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double fontSize = 14;
        List<TextSpan> productTextSpan = [];
        productTextSpan.add(
          TextSpan(
            text: productName,
            style: textStyle.copyWith(fontSize: fontSize),
          ),
        );
        if (qty != 0) {
          productTextSpan.add(
            TextSpan(
              text: " ${global.moneyFormat.format(qty)} $unitName",
              style: textStyle.copyWith(
                fontSize: fontSize,
                color: Colors.green,
              ),
            ),
          );
          if (price != priceOriginal) {
            productTextSpan.add(
              TextSpan(
                text: " ",
                style: textStyle.copyWith(
                  fontSize: fontSize,
                  color: Colors.grey,
                ),
              ),
            );
          }
          if (price != priceOriginal) {
            productTextSpan.add(
              TextSpan(
                text: " @${global.moneyFormat.format(priceOriginal)}",
                style: textStyle.copyWith(
                  fontSize: fontSize,
                  color: Colors.red,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            );
          }
          if (price * qty != totalAmount ||
              qty != 1 ||
              price != priceOriginal) {
            productTextSpan.add(
              TextSpan(
                text: " ",
                style: textStyle.copyWith(
                  fontSize: fontSize,
                  color: Colors.grey,
                ),
              ),
            );
            productTextSpan.add(
              TextSpan(
                text: " @${global.moneyFormat.format(price)}",
                style: textStyle.copyWith(
                  fontSize: fontSize,
                  color: Colors.orange,
                ),
              ),
            );
          }
        }
        RichText productText = RichText(
          text: TextSpan(
            style: textStyle.copyWith(fontSize: fontSize),
            children: productTextSpan,
          ),
        );
        return Row(
          children: [
            Expanded(
              flex: 7,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        productText,
                        if (isActive)
                          Text(
                            barcode,
                            style: textStyle.copyWith(
                              fontSize: fontSize * 0.75,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isActive && imageUrl.isNotEmpty)
                    Container(
                      width: 75,
                      margin: const EdgeInsets.only(right: 5),
                      padding: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.blueAccent),
                      ),
                      child: Center(
                        child: CachedNetworkImage(
                          fit: BoxFit.cover,
                          imageUrl: imageUrl,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: (totalAmount == 0)
                  ? Container()
                  : Text(
                      global.moneyFormatAndDot.format(totalAmount),
                      textAlign: TextAlign.right,
                      style: textStyle.copyWith(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget detailRow(
    int index,
    PosProcessDetailModel detail,
    Color backgroundColor,
  ) {
    TextStyle textStyle = const TextStyle(fontSize: 24, color: Colors.black);
    double extraAmount = 0.0;
    TextStyle extraTextStyle = TextStyle(
      fontSize: 10,
      fontWeight: textStyle.fontWeight,
      color: Colors.grey,
    );
    String description =
        "${global.getNameFromJsonLanguage(detail.item_name, global.userScreenLanguage)}${(detail.remark.isNotEmpty) ? " (${detail.remark})" : ""}";
    if (detail.is_except_vat) {
      description = "$description (ยกเว้นภาษี)";
    }
    for (final extra in detail.extra) {
      extraAmount += extra.total_amount;
    }
    List<Widget> columnList = [];
    columnList.add(
      detailWidget(
        isActive: true,
        fullDetail: true,
        isExtra: false,
        productName: "$index.$description",
        qty: detail.qty,
        price: detail.price,
        priceOriginal: detail.price_original,
        totalAmount: detail.total_amount,
        textStyle: textStyle,
        barcode: detail.barcode,
        unitName: global.getNameFromJsonLanguage(
          detail.unit_name,
          global.userScreenLanguage,
        ),
        imageUrl: detail.image_url,
      ),
    );
    for (final extra in detail.extra) {
      columnList.add(
        detailWidget(
          isExtra: true,
          productName: global.getNameFromJsonLanguage(
            extra.item_name,
            global.userScreenLanguage,
          ),
          qty: (extra.qty == 0) ? 0 : extra.qty,
          price: extra.price,
          priceOriginal: detail.price_original,
          totalAmount: (extra.price == 0) ? 0 : extra.total_amount,
          unitName: "",
          barcode: "",
          textStyle: extraTextStyle,
          imageUrl: "",
        ),
      );
    }
    if (extraAmount != 0) {
      columnList.add(
        detailWidget(
          isExtra: false,
          productName:
              " ${global.language("total")} : ${global.getNameFromJsonLanguage(detail.item_name, global.userScreenLanguage)}/${global.getNameFromJsonLanguage(detail.unit_name, global.userScreenLanguage)}",
          qty: 0,
          price: 0,
          priceOriginal: detail.price_original,
          unitName: "",
          totalAmount: detail.total_amount + extraAmount,
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: textStyle.fontWeight,
            color: Colors.black,
          ),
          barcode: detail.barcode,
          imageUrl: "",
        ),
      );
    }
    if (detail.discount != 0) {
      columnList.add(
        detailWidget(
          isExtra: false,
          productName:
              "${global.language("discount")} : ${detail.discount_text}",
          qty: 0,
          price: 0,
          priceOriginal: detail.price_original,
          unitName: "",
          totalAmount: detail.discount * -1,
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: textStyle.fontWeight,
            color: Colors.red,
          ),
          barcode: detail.barcode,
          imageUrl: "",
        ),
      );
      columnList.add(
        detailWidget(
          isExtra: false,
          productName:
              "${global.language("after_discount")} : ${detail.discount_text}",
          qty: 0,
          price: 0,
          priceOriginal: detail.price_original,
          unitName: "",
          totalAmount: (detail.total_amount + extraAmount) - detail.discount,
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: textStyle.fontWeight,
            color: Colors.blue,
          ),
          barcode: detail.barcode,
          imageUrl: "",
        ),
      );
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: const Border(bottom: BorderSide(color: Colors.grey, width: 1)),
      ),
      child: Column(children: columnList),
    );
  }

  Widget detailList() {
    return ScrollablePositionedList.builder(
      itemScrollController: detailScrollController,
      itemCount: processResult.posProcess.details.length,
      itemBuilder: (context, index) {
        Color? backgroundColor = (index.isOdd)
            ? Colors.white
            : Colors.grey[200];
        if (processResult.posProcess.details[index].guid ==
            processResult.activeLineGuid) {
          backgroundColor = Colors.cyan.shade100;
        }
        return detailRow(
          index + 1,
          processResult.posProcess.details[index],
          backgroundColor!,
        );
      },
    );
  }

  Widget summery() {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    global.language("unit_pc"),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    global.moneyFormat.format(
                      processResult.posProcess.total_piece,
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "ยอดรวม",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${global.moneyFormatAndDot.format(processResult.posProcess.total_amount)} ${global.language('money_symbol')}",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget detailHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF37474F), Color(0xFF263238)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Text(
              global.language("product_description"),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              global.language("product_qty"),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              global.language("product_amount"),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void checkEndVideo() {
    if (videoController.value.isInitialized &&
        (videoController.value.duration == videoController.value.position)) {
      changeMedia();
    }
  }

  void changeMedia() {
    // global.informationList = jsonDecode(receiveData.informationList.toString()).map<InformationModel>((e) => InformationModel.fromJson(e)).toList();
    if (infoList.isNotEmpty) {
      try {
        informationMedia = const SizedBox();
        try {
          videoController.dispose();
        } catch (e) { AppLogger.debug("Intentionally ignored: `$e"); }
        informationIndex = Random().nextInt(infoList.length);
        if (infoList[informationIndex].mode == 0) {
          // Show Image
          informationMedia = CachedNetworkImage(
            fit: BoxFit.fill,
            imageUrl: infoList[informationIndex].sourceUrl,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          );
          informationCountDownSecond = infoList[informationIndex].delaySecond;
          setState(() {});
        }
        if (infoList[informationIndex].mode == 1) {
          // Show Video
          videoController = VideoPlayerController.contentUri(
            Uri.parse(infoList[informationIndex].sourceUrl),
          );
          informationMedia = VideoPlayer(videoController);
          videoController.setLooping(false);
          videoController
              .initialize()
              .then((_) {
                setState(() {});
                videoController.play();
              })
              .onError((error, stackTrace) {
                informationCountDownSecond = 0;
              })
              .catchError((error, stackTrace) {
                informationCountDownSecond = 0;
              });
          videoController.removeListener(checkEndVideo);
          videoController.addListener(checkEndVideo);
          informationCountDownSecond = infoList[informationIndex].delaySecond;
        }
        setState(() {});
      } catch (e) { AppLogger.debug("Intentionally ignored: `$e"); }
    }
  }

  void reCalc() {
    sumTotalPayAmount =
        processResult.payScreenData.cash_amount +
        processResult.payScreenData.credit_amount +
        processResult.posProcess.total_coupon_amount +
        processResult.posProcess.total_credit_card_amount +
        processResult.posProcess.total_transfer_amount +
        processResult.posProcess.total_cheque_amount +
        processResult.posProcess.total_qr_code_amount;

    diffAmount =
        processResult.payScreenData.total_after_round - sumTotalPayAmount;
  }

  Widget paySummeryScreen() {
    String moneySymbol = global.language('money_symbol');
    reCalc();

    Widget payWidget = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.payment, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  global.language("pay_channel"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPaymentDetailRow(
                    global.language('total_amount'),
                    '${global.moneyFormatAndDot.format(processResult.posProcess.total_amount)} $moneySymbol',
                    Icons.receipt_long,
                    isHighlighted: true,
                  ),
                  const SizedBox(height: 12),
                  if (processResult.payScreenData.discount_amount != 0) ...[
                    _buildPaymentDetailRow(
                      "${global.language('total_pay_amount_discount')} ${processResult.payScreenData.discount_formula}",
                      '${global.moneyFormatAndDot.format(processResult.payScreenData.discount_amount)} $moneySymbol',
                      Icons.discount,
                      color: const Color(0xFFE53935),
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentDetailRow(
                      "ยอดรวมหลังหักส่วนลด",
                      '${global.moneyFormatAndDot.format(processResult.payScreenData.total_after_discount)} $moneySymbol',
                      Icons.calculate,
                      color: const Color(0xFF1976D2),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (processResult.payScreenData.round_amount != 0) ...[
                    _buildPaymentDetailRow(
                      "ปัดเศษ",
                      '${global.moneyFormatAndDot.format(processResult.payScreenData.round_amount)} $moneySymbol',
                      Icons.currency_exchange,
                      color: const Color(0xFF9C27B0),
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentDetailRow(
                      "ยอดรวมหลังปัดเศษ",
                      '${global.moneyFormatAndDot.format(processResult.payScreenData.total_after_round)} $moneySymbol',
                      Icons.calculate,
                      color: const Color(0xFF1976D2),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Divider(thickness: 1, color: Color(0xFFE0E0E0)),
                  const SizedBox(height: 12),
                  if (processResult.posProcess.total_coupon_amount != 0)
                    _buildPaymentDetailRow(
                      global.language('total_pay_amount_coupon'),
                      '${global.moneyFormatAndDot.format(processResult.posProcess.total_coupon_amount)} $moneySymbol',
                      Icons.local_offer,
                      color: const Color(0xFF4CAF50),
                    ),
                  if (processResult.posProcess.total_credit_card_amount != 0)
                    _buildPaymentDetailRow(
                      global.language('total_pay_amount_card'),
                      '${global.moneyFormatAndDot.format(processResult.posProcess.total_credit_card_amount)} $moneySymbol',
                      Icons.credit_card,
                      color: const Color(0xFF4CAF50),
                    ),
                  if (processResult.posProcess.total_transfer_amount != 0)
                    _buildPaymentDetailRow(
                      global.language('total_pay_amount_transfer'),
                      '${global.moneyFormatAndDot.format(processResult.posProcess.total_transfer_amount)} $moneySymbol',
                      Icons.account_balance,
                      color: const Color(0xFF4CAF50),
                    ),
                  if (processResult.posProcess.total_cheque_amount != 0)
                    _buildPaymentDetailRow(
                      global.language('total_pay_amount_cheque'),
                      '${global.moneyFormatAndDot.format(processResult.posProcess.total_cheque_amount)} $moneySymbol',
                      Icons.receipt,
                      color: const Color(0xFF4CAF50),
                    ),
                  if (processResult.posProcess.total_qr_code_amount != 0)
                    _buildPaymentDetailRow(
                      global.language('total_pay_amount_wallet'),
                      '${global.moneyFormatAndDot.format(processResult.posProcess.total_qr_code_amount)} $moneySymbol',
                      Icons.qr_code,
                      color: const Color(0xFF4CAF50),
                    ),
                  _buildPaymentDetailRow(
                    global.language('total_pay_amount_cash'),
                    '${global.moneyFormatAndDot.format(processResult.payScreenData.cash_amount)} $moneySymbol',
                    Icons.money,
                    color: const Color(0xFF4CAF50),
                  ),
                  if (processResult.payScreenData.credit_amount != 0)
                    _buildPaymentDetailRow(
                      global.language('credit'),
                      '${global.moneyFormatAndDot.format(processResult.payScreenData.credit_amount)} $moneySymbol',
                      Icons.credit_score,
                      color: const Color(0xFF4CAF50),
                    ),
                  if (processResult.payScreenData.cash_amount !=
                      sumTotalPayAmount) ...[
                    const SizedBox(height: 12),
                    _buildPaymentDetailRow(
                      global.language('total_pay_amount'),
                      '${global.moneyFormatAndDot.format(sumTotalPayAmount)} $moneySymbol',
                      Icons.payments,
                      color: const Color(0xFF2196F3),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildPaymentDetailRow(
                    global.language('total_pay_amount_diff'),
                    '${global.moneyFormatAndDot.format(diffAmount)} $moneySymbol',
                    Icons.trending_up,
                    color: const Color(0xFFFF5722),
                    isHighlighted: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // ตรวจสอบความกว้างของจอ
          bool isWideScreen = constraints.maxWidth > 720;

          if (isWideScreen) {
            // แสดงแบบ Row สำหรับจอกว้าง
            return Row(
              children: [
                // ฝั่งซ้าย - QR Code Section (เมื่อมี QR)
                if (receiveData.command == 'qr')
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // ฝั่งซ้าย - ข้อมูล QR Code
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ชื่อผู้ให้บริการ
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.qr_code_2,
                                      color: Color(0xFF1976D2),
                                      size: 32,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        global.getNameFromLanguage(
                                          customerDisplayQrData
                                              .provider
                                              .qrnames!,
                                          global.userScreenLanguage,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF263238),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // จำนวนเงิน
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF1976D2,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF1976D2),
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        global.language('money_amount'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${global.moneyFormatAndDot.format(customerDisplayQrData.amount)} ${global.language('money_symbol')}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 32,
                                          color: Color(0xFF1976D2),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // QR Code (ข้อความ)
                                if (customerDisplayQrData
                                    .provider
                                    .bookbanknames!
                                    .isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      global.getNameFromLanguage(
                                        customerDisplayQrData
                                            .provider
                                            .bookbanknames!,
                                        global.userScreenLanguage,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF424242),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 32),

                          // ฝั่งขวา - QR Code Image
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                const Text(
                                  'สแกนเพื่อชำระเงิน',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF263238),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  width: 200,
                                  height: 200,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF1976D2),
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child:
                                      (customerDisplayQrData
                                          .qrcodestring
                                          .isNotEmpty)
                                      ? QrImageView(
                                          data: customerDisplayQrData
                                              .qrcodestring,
                                          version: QrVersions.auto,
                                          backgroundColor: Colors.white,
                                        )
                                      : (customerDisplayQrData
                                            .qrcodeimage
                                            .isNotEmpty)
                                      ? Image.memory(
                                          base64Decode(
                                            customerDisplayQrData.qrcodeimage,
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.qr_code,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ฝั่งขวา - Payment Widget
                Expanded(
                  flex: receiveData.command == 'qr' ? 1 : 2,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    child: payWidget,
                  ),
                ),
              ],
            );
          } else {
            // แสดงแบบ Column สำหรับจอแคบ
            return Column(
              children: [
                if (receiveData.command == 'qr')
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // ชื่อผู้ให้บริการ
                        Row(
                          children: [
                            const Icon(
                              Icons.qr_code_2,
                              color: Color(0xFF1976D2),
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                global.getNameFromLanguage(
                                  customerDisplayQrData.provider.qrnames!,
                                  global.userScreenLanguage,
                                ),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF263238),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // จำนวนเงิน และ QR Code ในแถวเดียวกัน
                        Row(
                          children: [
                            // ฝั่งซ้าย - จำนวนเงิน
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF1976D2,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF1976D2),
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          global.language('money_amount'),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF666666),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${global.moneyFormatAndDot.format(customerDisplayQrData.amount)} ${global.language('money_symbol')}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            color: Color(0xFF1976D2),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (customerDisplayQrData
                                      .provider
                                      .bookbanknames!
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        global.getNameFromLanguage(
                                          customerDisplayQrData
                                              .provider
                                              .bookbanknames!,
                                          global.userScreenLanguage,
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF424242),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 20),

                            // ฝั่งขวา - QR Code Image
                            Column(
                              children: [
                                const Text(
                                  'สแกนเพื่อชำระเงิน',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF263238),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: 150,
                                  height: 150,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF1976D2),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child:
                                      (customerDisplayQrData
                                          .qrcodestring
                                          .isNotEmpty)
                                      ? QrImageView(
                                          data: customerDisplayQrData
                                              .qrcodestring,
                                          version: QrVersions.auto,
                                          backgroundColor: Colors.white,
                                        )
                                      : (customerDisplayQrData
                                            .qrcodeimage
                                            .isNotEmpty)
                                      ? Image.memory(
                                          base64Decode(
                                            customerDisplayQrData.qrcodeimage,
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.qr_code,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(child: payWidget),
              ],
            );
          }
        },
      ),
    );
  }

  void detailJumpToLine() {
    try {
      if (processResult.activeLineGuid.isNotEmpty) {
        for (
          int index = 0;
          index < processResult.posProcess.details.length;
          index++
        ) {
          if (processResult.posProcess.details[index].guid ==
              processResult.activeLineGuid) {
            detailScrollController.scrollTo(
              index: index,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
            break;
          }
        }
      }
    } catch (e) { AppLogger.debug("Intentionally ignored: `$e"); }
  }

  void buildFromValue() {
    AppLogger.debug("buildFromValue");
    PosHoldProcessModel processDecode = PosHoldProcessModel.fromJson(
      jsonDecode(receiveData.posdata) as Map<String, dynamic>,
    );
    processResult = processDecode;
    if (receiveData.qrdata.isNotEmpty) {
      customerDisplayQrData = CustomerDisplayQrData.fromJson(
        jsonDecode(receiveData.qrdata) as Map<String, dynamic>,
      );
    }
    if (receiveData.paysuccessdata.isNotEmpty) {
      customerDisplayPaySuccessData = CustomerDisplayPaySuccessData.fromJson(
        jsonDecode(receiveData.paysuccessdata) as Map<String, dynamic>,
      );
    }

    customerDisplayCommand = receiveData.command;

    for (int i = 0; i < processResult.posProcess.details.length; i++) {
      if (processResult.posProcess.details[i].guid ==
          processResult.activeLineGuid) {
        detailIndex = i;
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mainWidget = Container();
    switch (displayMode) {
      case 1:
        mainWidget = SizedBox.expand(child: informationMedia);
        break;
      case 2:
        mainWidget =
            (processResult.posProcess.details.isEmpty || detailIndex == -1)
            ? Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                  ),
                ),
                child: SizedBox.expand(child: informationMedia),
              )
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF5F5F5), Color(0xFFEEEEEE)],
                  ),
                ),
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1976D2),
                                    Color(0xFF1565C0),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                global.getNameFromJsonLanguage(
                                  processResult
                                      .posProcess
                                      .details[detailIndex]
                                      .item_name,
                                  global.userScreenLanguage,
                                ),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildDetailRow(
                              "จำนวน",
                              "${global.moneyFormat.format(processResult.posProcess.details[detailIndex].qty)} ${global.getNameFromJsonLanguage(processResult.posProcess.details[detailIndex].unit_name, global.userScreenLanguage)}",
                              Icons.shopping_cart_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              "ราคา",
                              "${global.moneyFormatAndDot.format(processResult.posProcess.details[detailIndex].price)} ${global.language('money_symbol')}",
                              Icons.attach_money_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                              "รวม",
                              "${global.moneyFormatAndDot.format(processResult.posProcess.details[detailIndex].total_amount)} ${global.language('money_symbol')}",
                              Icons.receipt_long_outlined,
                              isTotal: true,
                            ),
                            const SizedBox(height: 24),
                            if (processResult
                                .posProcess
                                .details[detailIndex]
                                .image_url
                                .isNotEmpty)
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: processResult
                                          .posProcess
                                          .details[detailIndex]
                                          .image_url,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey,
                                              size: 48,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        margin: const EdgeInsets.only(
                          top: 16,
                          right: 16,
                          bottom: 16,
                        ),
                        child: Column(
                          children: <Widget>[
                            summery(),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    detailHeader(),
                                    Expanded(child: detailList()),
                                  ],
                                ),
                              ),
                            ),
                            if (processResult
                                    .posProcess
                                    .detail_total_discount !=
                                0)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.receipt,
                                          color: Color(0xFF1976D2),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "รวมทั้งสิ้น",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Color(0xFF263238),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            global.moneyFormatAndDot.format(
                                              processResult
                                                  .posProcess
                                                  .detail_total_amount_before_discount,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color(0xFF263238),
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.discount,
                                          color: Color(0xFFE53935),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "ส่วนลด : ${processResult.posProcess.detail_discount_formula}",
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Color(0xFFE53935),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            global.moneyFormatAndDot.format(
                                              processResult
                                                  .posProcess
                                                  .detail_total_discount,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Color(0xFFE53935),
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.right,
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
                    ),
                  ],
                ),
              );
        break;
      case 3:
        mainWidget = Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF5F5F5), Color(0xFFE8EAF6)],
            ),
          ),
          child: (receiveData.command == '' || receiveData.command == 'qr')
              ? Row(
                  children: [
                    if (processResult.payScreenActive == 1)
                      Expanded(
                        flex: 2,
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          child: paySummeryScreen(),
                        ),
                      ),
                  ],
                )
              : Center(
                  child: Container(
                    width: 900,
                    height: 600,
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          "ชำระเงินสำเร็จ",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildPaymentSummaryRow(
                          global.language("total_amount_product_service"),
                          '${global.moneyFormatAndDot.format(customerDisplayPaySuccessData.totalamount)} ${customerDisplayPaySuccessData.moneysymbol}',
                        ),
                        const SizedBox(height: 20),
                        _buildPaymentSummaryRow(
                          global.language("total_payment_amount"),
                          '${global.moneyFormatAndDot.format(customerDisplayPaySuccessData.totalpaymentamount)} ${customerDisplayPaySuccessData.moneysymbol}',
                        ),
                        const SizedBox(height: 20),
                        _buildPaymentSummaryRow(
                          global.language("money_change"),
                          '${global.moneyFormatAndDot.format(customerDisplayPaySuccessData.moneychange.abs())} ${customerDisplayPaySuccessData.moneysymbol}',
                          isChange: true,
                        ),
                      ],
                    ),
                  ),
                ),
        );
        break;
      default:
        mainWidget = Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.display_settings,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Text(
                    "Waiting for data...",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        );
        break;
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SecondaryDisplay(
          callback: (argument) {
            receiveData = CustomerDisplayData.fromJson(argument);
            infoList = [];
            if (argument['information'] != null) {
              infoList = (jsonDecode(argument['information']) as List)
                  .map((e) => InformationModel.fromJson(e))
                  .toList();
            }
            if (kDebugMode) {
              AppLogger.debug('infoList.length = ${infoList.length}');
              AppLogger.debug('receiveData.mode = ${receiveData.mode}');
            }

            if (receiveData.mode == global.secondScreenCommandInformation) {
              displayMode = 1;
              detailIndex = -1;
              changeMedia();
              setState(() {});
            } else if (receiveData.mode ==
                global.secondScreenCommandProcessDetail) {
              displayMode = 2;
              buildFromValue();
              detailJumpToLine();
              setState(() {});
            } else if (receiveData.mode == global.secondScreenCommandPay) {
              displayMode = 3;
              buildFromValue();
              setState(() {});
            } else {
              buildFromValue();
              detailJumpToLine();
              if (customerDisplayQrData.qrcodepaydata.isNotEmpty) {
                var base64 = base64Decode(customerDisplayQrData.qrcodeimage);
                Image image = Image.memory(base64);
                qrGenerate = Container(child: image);
              }
            }
            setState(() {});
          },
          child: mainWidget,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isTotal = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isTotal
            ? const Color(0xFF1976D2).withOpacity(0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTotal ? const Color(0xFF1976D2) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isTotal ? const Color(0xFF1976D2) : const Color(0xFF666666),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: isTotal
                  ? const Color(0xFF1976D2)
                  : const Color(0xFF666666),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: isTotal
                    ? const Color(0xFF1976D2)
                    : const Color(0xFF263238),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryRow(
    String label,
    String value, {
    bool isChange = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isChange ? const Color(0xFF4CAF50) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isHighlighted = false,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFF1976D2).withOpacity(0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted ? const Color(0xFF1976D2) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color:
                color ??
                (isHighlighted
                    ? const Color(0xFF1976D2)
                    : const Color(0xFF666666)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    color ??
                    (isHighlighted
                        ? const Color(0xFF1976D2)
                        : const Color(0xFF666666)),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlighted ? 16 : 14,
              fontWeight: FontWeight.bold,
              color:
                  color ??
                  (isHighlighted
                      ? const Color(0xFF1976D2)
                      : const Color(0xFF263238)),
            ),
          ),
        ],
      ),
    );
  }
}
