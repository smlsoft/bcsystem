import 'package:flutter/material.dart';
import 'package:dedeorder/global.dart' as global;
import 'package:shared_preferences/shared_preferences.dart';

class PayTypeConfig extends StatefulWidget {
  const PayTypeConfig({super.key});

  @override
  State<PayTypeConfig> createState() => _PayTypeConfigState();
}

class _PayTypeConfigState extends State<PayTypeConfig> {
  @override
  void initState() {
    global.getPayTypeEnableConfig();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งคค่าโหมดการชำระเงิน'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListTile(
              title: const Text('ชำระที่ Cashier'),
              trailing: Switch(
                value: global.payTypeEnableList[0],
                onChanged: (value) {
                  setState(() {
                    global.payTypeEnableList[0] = value;
                    global.setPayTypeEnableConfig();
                  });
                },
              ),
            ),
            // ListTile(
            //   title: const Text('ชำระทันทีด้วยเงินสด'),
            //   trailing: Switch(
            //     value: global.payTypeEnableList[1],
            //     onChanged: (value) {
            //       setState(() {
            //         global.payTypeEnableList[1] = value;
            //         global.setPayTypeEnableConfig();
            //       });
            //     },
            //   ),
            // ),
            ListTile(
              title: const Text('ชำระทันทีด้วยQrCode'),
              trailing: Switch(
                value: global.payTypeEnableList[2],
                onChanged: (value) {
                  setState(() {
                    global.payTypeEnableList[2] = value;
                    global.setPayTypeEnableConfig();
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('ชำระทันทีด้วยSMLQrCode'),
              trailing: Switch(
                value: global.payTypeEnableList[3],
                onChanged: (value) {
                  setState(() {
                    global.payTypeEnableList[3] = value;
                    global.setPayTypeEnableConfig();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
