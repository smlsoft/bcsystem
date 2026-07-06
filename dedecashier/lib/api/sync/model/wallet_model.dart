import 'package:dedecashier/global_model.dart';
import 'package:json_annotation/json_annotation.dart';
part 'wallet_model.g.dart';

@JsonSerializable()
class WalletModel {
  /// รหัส
  String code;

  /// ชื่อ
  List<LanguageDataModel> names;

  /// 0=Prompt Pay,1=Lugen
  int paymenttype;

  /// เชื่อมสมุดบัญชีธนาคาร
  String bookbankcode;

  /// Logo
  String paymentlogo;

  /// ค่าธรรมเนียมโดยประมาณ
  double feeRate;

  /// 0=Prompt Pay,1=Alipay,2=Line Pay,3=True Money
  int wallettype;

  /// API Key
  String apiKey;

  String billerCode;
  String billerID;
  String storeID;
  String terminalID;

  WalletModel({
    required this.code,
    required this.apiKey,
    required this.bookbankcode,
    required this.paymentlogo,
    required this.paymenttype,
    required this.feeRate,
    required this.wallettype,
    required this.names,
    required this.billerCode,
    required this.billerID,
    required this.storeID,
    required this.terminalID,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) => _$WalletModelFromJson(json);
  Map<String, dynamic> toJson() => _$WalletModelToJson(this);
}
