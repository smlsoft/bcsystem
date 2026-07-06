import 'package:dedekiosk/util/api.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/model/global_model.dart';
import 'package:dedekiosk/model/order_pay_process_model.dart';
import 'package:flutter/foundation.dart';
import 'package:gbprimepay/gbprimepay.dart';
import 'package:gbprimepay/models/gb_inquiry_payment_response.dart';
import 'package:dedekiosk/util/logger.dart';

Future<void> checkPaymentOnline() async {
  String tableName = "dedeorder.orderpayprocess";

  if (global.deviceConfig.isServer) {
    Logger.d('Check payment');
    String query =
        'SELECT * FROM $tableName WHERE shopid=\'${global.deviceConfig.shopId}\' and paysuccess=0';
    // ตรวจสอบการชำระเงิน
    ResponseDataModel responseData =
        ResponseDataModel.fromJson(await clickHouseSelect(query));
    if (responseData.data.isNotEmpty) {
      List<OrderPayProcessModel> orderPayProcessList = responseData.data
          .map((i) => OrderPayProcessModel.fromJson(i))
          .toList();
      bool updateData = false;
      for (OrderPayProcessModel orderPayProcess in orderPayProcessList) {
        updateData = true;
        switch (orderPayProcess.wallettype) {
          case 131:
            // GB Pay
            Logger.d('GB Pay');
            GBPrimePay primePay = GBPrimePay(
                publicKey: global.profileQrPayment[0].apikey,
                accessToken: global.profileQrPayment[0].token,
                secretKey: global.profileQrPayment[0].accessCode);

            GBInquiryPaymentResponse response =
                await primePay.inquiryQRPayment(orderPayProcess.transid);
            if (response.isPaymentSuccess()) {
              Logger.d('Payment success');
              // อัพเดทสถานะการชำระเงิน
              query =
                  'alter table $tableName UPDATE paysuccess=1 WHERE shopid=\'${orderPayProcess.shopid}\' and transguid=\'${orderPayProcess.transguid}\'';
              await clickHouseExecute(query);
            }
            break;
        }
      }
      if (updateData) {
        // อัพเดทสถานะการชำระเงิน
        if (kDebugMode) {
          print('Delete if over 15 minutes (ClickHouse)');
        }
        String queryDelete =
            'alter table $tableName UPDATE paysuccess=-1 WHERE shopid=\'${global.deviceConfig.shopId}\' and paysuccess=0 and paydatetime < now() - INTERVAL 15 MINUTE';
        await clickHouseExecute(queryDelete);
      }
    }
  }
}
