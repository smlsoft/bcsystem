import 'package:dedecashier/global_model.dart';
import 'package:json_annotation/json_annotation.dart';
part 'sync_wallet_model.g.dart';

@JsonSerializable()
class SyncWalletModel {
  String guidfixed;
  String code;
  String bankcode;
  String bookbankname;
  String countrycode;
  double feerate;
  List<LanguageDataModel> names;
  String paymentcode;
  String paymentlogo;
  int paymenttype;
  int wallettype;

  SyncWalletModel({
    required this.guidfixed,
    required this.code,
    required this.bankcode,
    required this.bookbankname,
    required this.countrycode,
    required this.feerate,
    required this.names,
    required this.paymentcode,
    required this.paymentlogo,
    required this.paymenttype,
    required this.wallettype,
  });

  factory SyncWalletModel.fromJson(Map<String, dynamic> json) => _$SyncWalletModelFromJson(json);
  Map<String, dynamic> toJson() => _$SyncWalletModelToJson(this);
}
