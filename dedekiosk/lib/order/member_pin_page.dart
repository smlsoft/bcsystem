import 'package:dedekiosk/model/trans_model.dart';
import 'package:dedekiosk/order/order_util.dart';
import 'package:dedekiosk/util/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/util/api.dart' as api;

class MemberPinPage extends StatefulWidget {
  const MemberPinPage({super.key});

  @override
  State<MemberPinPage> createState() => _SelectMemberScreenState();
}

class _SelectMemberScreenState extends State<MemberPinPage> {
  TextEditingController pinController1 = TextEditingController();
  TextEditingController pinController2 = TextEditingController();
  TextEditingController pinController3 = TextEditingController();
  TextEditingController pinController4 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orangeAccent.shade100,
      body: Container(
        margin: const EdgeInsets.all(15),
        child: Center(
          child: Column(
            children: <Widget>[
              if (global.shopProfile!.orderstation.lineoaimg.isNotEmpty)
                Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: FittedBox(fit: BoxFit.fitWidth, child: Text(global.language("add_friend"), style: textStyleBorderWhite, textAlign: TextAlign.center))),
              if (global.shopProfile!.orderstation.lineoaimg.isNotEmpty)
                Image.network(
                  global.shopProfile!.orderstation.lineoaimg,
                  width: 200,
                ),
              Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: FittedBox(fit: BoxFit.fitWidth, child: Text(global.language("member_pin"), style: textStyleBorderWhite, textAlign: TextAlign.center))),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(4),
                      width: 100,
                      child: TextField(
                        controller: pinController1,
                        enabled: false,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        decoration: const InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Container(
                      width: 100,
                      margin: const EdgeInsets.all(4),
                      child: TextField(
                        controller: pinController2,
                        enabled: false,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        decoration: const InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Container(
                      width: 100,
                      margin: const EdgeInsets.all(4),
                      child: TextField(
                        controller: pinController3,
                        enabled: false,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        decoration: const InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Container(
                      width: 100,
                      margin: const EdgeInsets.all(4),
                      child: TextField(
                        controller: pinController4,
                        enabled: false,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        decoration: const InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Expanded(
                child: numberPad(),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10, top: 10),
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                global.memberCode = "";
                                global.priceIndex = 1;
                              });
                              Future.delayed(const Duration(seconds: 1), () {
                                Navigator.pushNamedAndRemoveUntil(context, "/order_select", (Route<dynamic> route) => false);
                              });
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: Text(
                              global.language('back'),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, top: 10),
                        child: SizedBox(
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () {
                              checkPin();
                            },
                            child: Text(
                              global.language('confirm'),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void checkPin() async {
    var pinData = await api.getMemberPin(pinController1.text + pinController2.text + pinController3.text + pinController4.text);
    if (pinData["success"]) {
      print(pinData);
      if (pinData["data"]["status"] == "active") {
        await api.useMemberPin(pinController1.text + pinController2.text + pinController3.text + pinController4.text);
        setState(() {
          global.isMember = true;
          global.memberCode = "";
          global.lineDestination = pinData["data"]["destination"];
          global.memberName = pinData["data"]["displayName"];
          global.memberEmail = pinData["data"]["email"];
          global.memberPicture = pinData["data"]["pictureUrl"];
          global.memberPinCode = pinController1.text + pinController2.text + pinController3.text + pinController4.text;
          global.priceIndex = 1;
        });

        var memberData = await api.getDebtorByLine(code: pinData["data"]["userId"]);
        Logger.d('MemberPinPage: getDebtorByLine response: success=${memberData.success}, error=${memberData.error}, message=${memberData.message}');

        // ตรวจสอบว่าเป็น "document not found" (ไม่มี debtor) หรือ error จริง
        String messageStr = (memberData.message ?? "").toString().toLowerCase();
        bool isDocumentNotFound = messageStr.contains("document not found") || messageStr.contains("not found");
        bool isRealError = memberData.error == true && !isDocumentNotFound && messageStr.isNotEmpty;

        if (isRealError) {
          Logger.w('MemberPinPage: API error (not "document not found"): ${memberData.message}');
        }

        if (!memberData.success) {
          Logger.d('MemberPinPage: Creating new debtor (isDocumentNotFound=$isDocumentNotFound)');
          setState(() {
            global.custNames = [
              TransNameInfoModel(name: global.memberName, code: "th", isauto: false, isdelete: false),
              TransNameInfoModel(name: global.memberName, code: "en", isauto: false, isdelete: false)
            ];
          });
          try {
            await api.createDebtor(code: pinData["data"]["userId"], name: global.memberName, email: global.memberEmail, img: global.memberPicture);
            Logger.d('MemberPinPage: Debtor created successfully');
          } catch (e) {
            Logger.e('MemberPinPage: Failed to create debtor', error: e);
          }
          // สมาชิกใหม่ใช้ราคา member (priceIndex = 1)
          global.memberPriceLevel = 1;
          global.priceIndex = 1;
        } else {
          Logger.d('MemberPinPage: Using existing debtor data');
          // ไม่ override isMember - เราผ่าน PIN แล้ว ถือว่าเป็นสมาชิก
          global.memberCode = memberData.data["code"] ?? "";
          // เก็บค่าตัวแปรใหม่จาก API
          String pointsCode = (memberData.data["pointscode"] ?? "").toString();
          global.memberPointsCode = pointsCode.isNotEmpty ? pointsCode : (memberData.data["code"] ?? "").toString();
          // แปลง pricelevel เป็น int
          var priceLevelRaw = memberData.data["pricelevel"];
          global.memberPriceLevel = (priceLevelRaw is int) ? priceLevelRaw : int.tryParse(priceLevelRaw?.toString() ?? "2") ?? 2;
          // ถ้า pricelevel เป็น 1 ให้เปลี่ยนเป็น 2 เพราะผ่าน PIN แล้ว
          if (global.memberPriceLevel == 1) {
            global.memberPriceLevel = 1;
          }
          global.memberGuidFixed = (memberData.data["guidfixed"] ?? "").toString();
          // แปลง pointbalance เป็น double
          var pointBalanceRaw = memberData.data["pointbalance"];
          if (pointBalanceRaw is double) {
            global.memberPointBalance = pointBalanceRaw;
          } else if (pointBalanceRaw is int) {
            global.memberPointBalance = pointBalanceRaw.toDouble();
          } else {
            global.memberPointBalance = double.tryParse(pointBalanceRaw?.toString() ?? "0") ?? 0;
          }
          global.priceIndex = global.memberPriceLevel;
          List<TransNameInfoModel> names = (memberData.data["names"] as List?)?.map((data) => TransNameInfoModel.fromJson(data)).toList() ?? global.custNames;
          setState(() {
            global.custNames = names;
          });
          Logger.d('MemberPinPage: Member data set - code=${global.memberCode}, priceLevel=${global.memberPriceLevel}, pointBalance=${global.memberPointBalance}');
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Container(
                color: Colors.white,
                height: 150,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // if (global.memberPicture.isNotEmpty) Image.network(global.memberPicture),
                    Text(
                      global.language("welcome") + " " + global.memberName,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.white,
                            offset: Offset(1.0, 1.0),
                          ),
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.white,
                            offset: Offset(-1.0, 1.0),
                          ),
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.white,
                            offset: Offset(1.0, -1.0),
                          ),
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.white,
                            offset: Offset(-1.0, -1.0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        // หลังจาก 3 วินาที ปิด dialog แล้วไปหน้า order_animation_one
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pop(); // ปิด dialog

          Navigator.pushNamedAndRemoveUntil(context, "/order_animation_one", (Route<dynamic> route) => false);
        });
      } else {
        showErrorDialog("pin_already_used");
        pinController1.text = "";
        pinController2.text = "";
        pinController3.text = "";
        pinController4.text = "";
        return;
      }
    } else {
      showErrorDialog("pin_not_found");
      pinController1.text = "";
      pinController2.text = "";
      pinController3.text = "";
      pinController4.text = "";
    }
  }

  void showErrorDialog(error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(global.language('error')),
          content: Text(global.language(error)),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(global.language('ok')),
            ),
          ],
        );
      },
    );
  }

  void textInputAdd(String word) {
    if (pinController1.text.length < 1) {
      pinController1.text = word;
    } else if (pinController2.text.length < 1) {
      pinController2.text = word;
    } else if (pinController3.text.length < 1) {
      pinController3.text = word;
    } else if (pinController4.text.length < 1) {
      pinController4.text = word;
    }
  }

  Widget numberPad() {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                  child: NumPadButton(
                margin: 2,
                text: '7',
                callBack: () => {textInputAdd("7")},
              )),
              Expanded(
                  child: NumPadButton(
                margin: 2,
                text: '8',
                callBack: () => {textInputAdd("8")},
              )),
              Expanded(
                  child: NumPadButton(
                margin: 2,
                text: '9',
                callBack: () => {textInputAdd("9")},
              )),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                  child: NumPadButton(
                text: '4',
                margin: 2,
                callBack: () => {textInputAdd("4")},
              )),
              Expanded(
                  child: NumPadButton(
                text: '5',
                margin: 2,
                callBack: () => {textInputAdd("5")},
              )),
              Expanded(
                  child: NumPadButton(
                margin: 2,
                text: '6',
                callBack: () => {textInputAdd("6")},
              )),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                  child: NumPadButton(
                margin: 2,
                text: '1',
                callBack: () => {textInputAdd("1")},
              )),
              Expanded(
                  child: NumPadButton(
                margin: 2,
                text: '2',
                callBack: () => {textInputAdd("2")},
              )),
              Expanded(
                  child: NumPadButton(
                margin: 2,
                text: '3',
                callBack: () => {textInputAdd("3")},
              )),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                  child: NumPadButton(
                margin: 2,
                text: '0',
                callBack: () => {textInputAdd("0")},
              )),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                  child: NumPadButton(
                margin: 2,
                textAndIconColor: Colors.black,
                icon: Icons.backspace,
                color: Colors.red.shade200,
                callBack: () {
                  if (pinController4.text.length > 0) {
                    pinController4.text = "";
                  } else if (pinController3.text.length > 0) {
                    pinController3.text = "";
                  } else if (pinController2.text.length > 0) {
                    pinController2.text = "";
                  } else if (pinController1.text.length > 0) {
                    pinController1.text = "";
                  }
                },
              )),
              Expanded(
                child: NumPadButton(
                  margin: 2,
                  text: 'C',
                  color: Colors.grey.shade400,
                  callBack: () {
                    pinController1.text = "";
                    pinController2.text = "";
                    pinController3.text = "";
                    pinController4.text = "";
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle textStyleBorderWhite = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(
        blurRadius: 2.0,
        color: Colors.white,
        offset: Offset(1.0, 1.0),
      ),
      Shadow(
        blurRadius: 2.0,
        color: Colors.white,
        offset: Offset(-1.0, 1.0),
      ),
      Shadow(
        blurRadius: 2.0,
        color: Colors.white,
        offset: Offset(1.0, -1.0),
      ),
      Shadow(
        blurRadius: 2.0,
        color: Colors.white,
        offset: Offset(-1.0, -1.0),
      ),
    ],
  );
}
