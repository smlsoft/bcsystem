import 'package:dedecashier/global_model.dart';

class CustomerDisplayData {
  CustomerDisplayData(this.posdata, this.qrdata, this.command, this.paysuccessdata, this.mode);

  final String posdata;
  final String qrdata;
  final String command;
  final String paysuccessdata;
  final String mode;

  static CustomerDisplayData fromJson(dynamic json) {
    return CustomerDisplayData(json['posdata'] ?? "", json['qrdata'] ?? "", json['command'] ?? "", json['paysuccessdata'] ?? "", json['mode'] ?? "");
  }
}

class CustomerDisplayQrData {
  CustomerDisplayQrData(this.provider, this.amount, this.qrcodepaydata, this.qrcodeimage, this.qrcodestring);

  final ProfileQrPaymentModel provider;
  final double amount;
  final String qrcodestring;
  final String qrcodepaydata;
  final String qrcodeimage;

  static CustomerDisplayQrData fromJson(dynamic json) {
    return CustomerDisplayQrData(
      ProfileQrPaymentModel.fromJson(json['provider']),
      json['amount'],
      json['qrcodepaydata'],
      json['qrcodeimage'],
      json['qrcodestring'],
    );
  }

  Map<String, dynamic> toJson() => {
        'provider': provider.toJson(),
        'amount': amount,
        'qrcodepaydata': qrcodepaydata,
        'qrcodeimage': qrcodeimage,
        'qrcodestring': qrcodestring,
      };
}

class CustomerDisplayPaySuccessData {
  CustomerDisplayPaySuccessData(this.totalamount, this.totalpaymentamount, this.moneychange, this.moneysymbol);

  final double totalamount;
  final double totalpaymentamount;
  final double moneychange;
  final String moneysymbol;

  static CustomerDisplayPaySuccessData fromJson(dynamic json) {
    return CustomerDisplayPaySuccessData(json['totalamount'], json['totalpaymentamount'], json['moneychange'], json['moneysymbol']);
  }

  Map<String, dynamic> toJson() => {
        'totalamount': totalamount,
        'totalpaymentamount': totalpaymentamount,
        'moneychange': moneychange,
        'moneysymbol': moneysymbol,
      };
}
