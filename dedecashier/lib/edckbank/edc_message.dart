import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

class EdcMessage {
  /// 0x02
  final int STX = 0x02;

  /// 0x03
  final int ETX = 0x03;

  /// 0x03
  final int ACK = 0x06;
  final String TRANSPORT_HEADER_TYPE_VALUE = "60";
  final String TRANSPORT_DESTINATION_VALUE = "0000";
  final String TRANSPORT_SOURCE_VALUE = "0000";
  final String PRESENTATION_HEADER_TRANSACTION_CODE_SALE_VALUE = "20";

  /// Field Type Amount (40)
  final String FIELD_TYPE_SALE_AMOUNT = "40";

  final int FIELD_SEPARATOR = 0x1C;

  final String PRESENTATION_HEADER_FORMAT_VERSION_VALUE = "1";
  final String PRESENTATION_HEADER_REQUEST_INDICATOR_VALUE = "0";
  final String PRESENTATION_HEADER_TRANSACTION_CODE_SALE_WALLET_VALUE = "70";

  final String PRESENTATION_HEADER_TRANSACTION_CODE_RETRIEVE_TRASACTION_BY_TRACE_VALUE = "71";
  final String PRESENTATION_HEADER_RESPONSE_CODE_VALUE = "00";

  final String PRESENTATION_HEADER_MORE_INDICATOR_NONE_VALUE = "0";

  /// Field Type Reference 1 (R1)

  final String FIELD_TYPE_SALE_REF1 = "R1";

  /// Field Type Reference 2 (R2)
  final String FIELD_TYPE_SALE_REF2 = "R2";

  final String FIELD_TYPE_WALLET_COMMAND_TYPE = "A1";
  final String FIELD_TYPE_WALLET_COMMAND_TYPE_THAI_QR_PAYMENT = "03";
  final String FIELD_TYPE_WALLET_COMMAND_TYPE_CREDIT_QR_APPLICATION = "04";

  static List<int> stringToByteArray(String hex) {
    final Map<String, int> hexIndex = {for (int i = 0; i <= 255; i++) i.toRadixString(16).padLeft(2, '0').toUpperCase(): i};

    final List<int> hexRes = [];
    for (int i = 0; i < hex.length; i += 2) {
      int? value = hexIndex[hex.substring(i, i + 2).toUpperCase()];
      hexRes.add(value!);
    }
    return hexRes;
  }

  static int calcLRCXOR(List<int> byteData) {
    int result = 0;
    if (byteData.isNotEmpty) {
      for (int i = 1; i < byteData.length; i++) {
        result ^= byteData[i];
      }
      return result;
    }
    return 0;
  }

  static List<int> calcBCDLength(int dataLength) {
    int firstSize = (dataLength / 100).floor();
    int secondSize = dataLength % 100;

    String hexFirstStr = "0x$firstSize"; //firstSize.toRadixString(16);
    String hexSecondStr = "0x$secondSize";

    int byte1 = int.parse(hexFirstStr);
    int byte2 = int.parse(hexSecondStr);

    List<int> result = [byte1, byte2];
    return result;
  }

  /// Build Transport Header
  String _buildTransportHeader() {
    String transportHeader = '$TRANSPORT_HEADER_TYPE_VALUE$TRANSPORT_DESTINATION_VALUE$TRANSPORT_SOURCE_VALUE';
    return transportHeader;
  }

  List<int> _getBytesValue(String value) {
    return value.codeUnits;
  }

  static String formatNumberAmount(double amount) {
    //         NumberFormat nf = NumberFormat("0000000000.00");
    // string amountStr =  amount.toString("0000000000.00").Replace(".", string.Empty);
    var f = NumberFormat("0000000000.00", "en_US");
    String amountStr = f.format(amount).replaceAll('.', '');
    return amountStr;
  }

  /// Create Sale Amount Field
  List<int> _buildSaleAmountFieldElement(double amount) {
    String amountStr = formatNumberAmount(amount);

    List<int> fieldSaleTypeAmountBytes = _getBytesValue(FIELD_TYPE_SALE_AMOUNT);
    List<int> fieldAmountByte = _getBytesValue(amountStr);
    List<int> LLLL = calcBCDLength(amountStr.length);

    List<int> dataByte = [];
    dataByte.addAll(fieldSaleTypeAmountBytes);
    dataByte.addAll(LLLL);
    dataByte.addAll(fieldAmountByte);
    dataByte.add(FIELD_SEPARATOR);

    return dataByte;
  }

  /// Create Presentation Header
  String _buildPresentationHeader(String presentationHeaderType) {
    String presentationHeader =
        '$PRESENTATION_HEADER_FORMAT_VERSION_VALUE$PRESENTATION_HEADER_REQUEST_INDICATOR_VALUE$presentationHeaderType$PRESENTATION_HEADER_RESPONSE_CODE_VALUE$PRESENTATION_HEADER_MORE_INDICATOR_NONE_VALUE';
    return presentationHeader;
  }

  /// Create Ref 1 Field
  List<int> _buildSaleRef1FieldElement(String ref1) {
    List<int> fieldTypeRef1Bytes = _getBytesValue(FIELD_TYPE_SALE_REF1);
    List<int> fieldRef1Byte = _getBytesValue(ref1);
    List<int> LLLL = calcBCDLength(ref1.length);

    List<int> dataByte = [];
    dataByte.addAll(fieldTypeRef1Bytes);
    dataByte.addAll(LLLL);
    dataByte.addAll(fieldRef1Byte);
    dataByte.add(FIELD_SEPARATOR);

    return dataByte;
  }

  /// Create Ref 2 Field
  List<int> _buildSaleRef2FieldElement(String ref2) {
    List<int> fieldTypeRef2Bytes = _getBytesValue(FIELD_TYPE_SALE_REF2);
    List<int> fieldRef2Byte = _getBytesValue(ref2);
    List<int> LLLL = calcBCDLength(ref2.length);

    List<int> dataByte = [];
    dataByte.addAll(fieldTypeRef2Bytes);
    dataByte.addAll(LLLL);
    dataByte.addAll(fieldRef2Byte);
    dataByte.add(FIELD_SEPARATOR);

    return dataByte;
  }

  List<int> createSaleQRMessage(double amount, String ref1, String ref2) {
    List<int> saleMessageBody = _buildSaleQRCodeMessageData(amount, ref1, ref2);
    List<int> messageBytes = _buildMessageStruct(saleMessageBody);

    return messageBytes;
  }

  List<int> _buildMessageStruct(List<int> data) {
    List<int> _dataByte = [];

    List<int> LLLL = calcBCDLength(data.length);

    _dataByte.add(STX);
    _dataByte.addAll(LLLL);
    _dataByte.addAll(data);
    _dataByte.add(ETX);

    List<int> _dataByteXor = [];
    _dataByteXor.add(STX);
    _dataByteXor.addAll(LLLL);
    _dataByteXor.addAll(data);
    _dataByteXor.add(ETX);

    int lcr = calcLRCXOR(_dataByteXor);
    _dataByte.add(lcr);
    return _dataByte;
  }

  List<int> createSaleCreditCardMessage(double amount, String ref1, String ref2) {
    List<int> saleMessageBody = _buildSaleCreditCardMessageData(amount, ref1, ref2);
    List<int> messageBytes = _buildMessageStruct(saleMessageBody);

    return messageBytes;
  }

  List<int> _buildSaleCreditCardMessageData(double amount, String ref1, String ref2) {
    List<int> _dataByte = [];

    String transportHeader = _buildTransportHeader();
    String presentationHeader = _buildPresentationHeader(PRESENTATION_HEADER_TRANSACTION_CODE_SALE_VALUE);

    List<int> transportHeaderBytes = _getBytesValue(transportHeader);
    List<int> presentationHeaderBytes = _getBytesValue(presentationHeader);
    List<int> fieldAmountBytes = _buildSaleAmountFieldElement(amount);

    // pack byte
    _dataByte.addAll(transportHeaderBytes);
    _dataByte.addAll(presentationHeaderBytes);
    _dataByte.add(FIELD_SEPARATOR);
    _dataByte.addAll(fieldAmountBytes);

    if (ref1.isNotEmpty) {
      List<int> fieldRef1Bytes = _buildSaleRef1FieldElement(ref1);
      _dataByte.addAll(fieldRef1Bytes);
    }
    if (ref2.isNotEmpty) {
      List<int> fieldRef2Bytes = _buildSaleRef2FieldElement(ref2);
      _dataByte.addAll(fieldRef2Bytes);
    }

    return _dataByte;
  }

  List<int> _buildSaleThaiQRPaymentFieldElement() {
    List<int> fieldTypeRef2Bytes = _getBytesValue(FIELD_TYPE_WALLET_COMMAND_TYPE);
    List<int> fieldRef2Byte = _getBytesValue(FIELD_TYPE_WALLET_COMMAND_TYPE_THAI_QR_PAYMENT);
    List<int> LLLL = calcBCDLength(2);

    List<int> _dataByte = [];
    _dataByte.addAll(fieldTypeRef2Bytes);
    _dataByte.addAll(LLLL);
    _dataByte.addAll(fieldRef2Byte);
    _dataByte.add(FIELD_SEPARATOR);

    return _dataByte;
  }

  // Build Sale QR Code Message Data
  List<int> _buildSaleQRCodeMessageData(double amount, String ref1, String ref2) {
    List<int> _dataByte = [];

    String transportHeader = _buildTransportHeader();
    String presentationHeader = _buildPresentationHeader(PRESENTATION_HEADER_TRANSACTION_CODE_SALE_WALLET_VALUE);

    List<int> transportHeaderBytes = _getBytesValue(transportHeader);
    List<int> presentationHeaderBytes = _getBytesValue(presentationHeader);
    List<int> fieldAmountBytes = _buildSaleAmountFieldElement(amount);
    List<int> fieldWalletPaymentThaiQRPayment = _buildSaleThaiQRPaymentFieldElement();

    // pack byte
    _dataByte.addAll(transportHeaderBytes);
    _dataByte.addAll(presentationHeaderBytes);
    _dataByte.add(FIELD_SEPARATOR);
    _dataByte.addAll(fieldAmountBytes);
    _dataByte.addAll(fieldWalletPaymentThaiQRPayment);

    if (ref1.isNotEmpty) {
      List<int> fieldRef1Bytes = _buildSaleRef1FieldElement(ref1);
      _dataByte.addAll(fieldRef1Bytes);
    }

    if (ref2.isNotEmpty) {
      List<int> fieldRef2Bytes = _buildSaleRef2FieldElement(ref2);
      _dataByte.addAll(fieldRef2Bytes);
    }

    return _dataByte;
  }
}
