import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'qr_model.g.dart';

@JsonSerializable(explicitToJson: true)
class QrModel {
  String? guidfixed;
  String? code;
  List<LanguageDataModel>? qrnames;

  /// 100 = QR PromptPay , 110 =  Lugent PromptPat , 111 = Lugent AliPay , 112 = Lugent True Money , 113 = Lugent Line Pay
  int? qrtype;
  bool? isactive;
  String? logo;

  String? bankcode;
  List<LanguageDataModel>? banknames;
  String? bookbankcode;
  List<LanguageDataModel>? bookbanknames;
  List<ImagesModel>? bookbankimages;
  String? qrcode;
  String? apikey;
  String? billerCode;
  String? billerID;
  String? storeID;
  String? terminalID;
  String? merchantName;
  String? accessCode;
  String? bankcharge;
  String? customercharge;

  /// 0 = เงินเข้าทันที , 1 = สิ้นวัน , 2 = วันถัดไป
  int? closeqr;

  QrModel({
    String? guidfixed,
    String? code,
    List<LanguageDataModel>? qrnames,
    int? qrtype,
    bool? isactive,
    String? logo,
    String? bankcode,
    List<LanguageDataModel>? banknames,
    String? bookbankcode,
    List<LanguageDataModel>? bookbanknames,
    List<ImagesModel>? bookbankimages,
    String? qrcode,
    String? apikey,
    String? billerCode,
    String? billerID,
    String? storeID,
    String? terminalID,
    String? merchantName,
    String? accessCode,
    String? bankcharge,
    String? customercharge,
    int? closeqr,
  })  : guidfixed = guidfixed ?? '',
        code = code ?? '',
        qrnames = qrnames ?? [],
        qrtype = qrtype ?? 0,
        isactive = isactive ?? true,
        logo = logo ?? '',
        bankcode = bankcode ?? '',
        banknames = banknames ?? [],
        bookbankcode = bookbankcode ?? '',
        bookbanknames = bookbanknames ?? [],
        bookbankimages = bookbankimages ?? [],
        qrcode = qrcode ?? '',
        apikey = apikey ?? '',
        billerCode = billerCode ?? '',
        billerID = billerID ?? '',
        storeID = storeID ?? '',
        terminalID = terminalID ?? '',
        merchantName = merchantName ?? '',
        accessCode = accessCode ?? '',
        bankcharge = bankcharge ?? '',
        customercharge = customercharge ?? '',
        closeqr = closeqr ?? 0;

  factory QrModel.fromJson(Map<String, dynamic> json) => _$QrModelFromJson(json);

  Map<String, dynamic> toJson() => _$QrModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class QrModelList {
  String code;
  List<QrModel> qrlist;
  QrModelList({
    required this.code,
    required this.qrlist,
  });

  factory QrModelList.fromJson(Map<String, dynamic> json) => _$QrModelListFromJson(json);

  Map<String, dynamic> toJson() => _$QrModelListToJson(this);
}
