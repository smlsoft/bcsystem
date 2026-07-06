// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:group_radio_button/group_radio_button.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:smlaicloud/components/appbar.dart';
import 'package:smlaicloud/components/background_main.dart';
import 'package:smlaicloud/components/textfield_input.dart';
import 'package:flutter/material.dart';
import 'package:smlaicloud/components/appbar.dart';
import 'package:smlaicloud/components/background_main.dart';

class PurchaseAdd extends StatefulWidget {
  const PurchaseAdd({Key? key}) : super(key: key);

  @override
  State<PurchaseAdd> createState() => _PurchaseAddState();
}

class _PurchaseAddState extends State<PurchaseAdd> {
  final memberId = TextEditingController();
  final fristName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  String _purchaseType = "ซื้อเงินสด";
  String _taxType = "ภาษีรวมใน";
  final creditDay = TextEditingController();

  final houseNo = TextEditingController();
  final villageNo = TextEditingController();
  final village = TextEditingController();
  final tambon = TextEditingController();
  final amper = TextEditingController();
  final province = TextEditingController();
  final zipCode = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: BaseAppBar(
        title: const Text('สร้างเอกสารซื้อสินค้า'),
        appBar: AppBar(),
        widgets: const <Widget>[],
      ),
      body: BackgroundMain(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 8.0, right: 8.0),
                height: size.height * 0.34,
                child: Column(
                  children: [
                    Expanded(
                      child: Card(
                        margin: const EdgeInsets.all(8.0),
                        child: Container(
                          margin: const EdgeInsets.all(10.0),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.only(
                                  left: 8.0,
                                  right: 8.0,
                                  top: 15.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: Text('เลขที่เอกสาร'),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: TextFieldInput(
                                        keyboardType: TextInputType.text,
                                        controller: houseNo,
                                        labelText: 'เลขที่เอกสาร',
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: Text('วันที่เอกสาร'),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: TextFieldInput(
                                        keyboardType: TextInputType.text,
                                        controller: villageNo,
                                        labelText: 'วันที่เอกสาร',
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: Text('เอกสารอ้างอิง'),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: TextFieldInput(
                                        keyboardType: TextInputType.text,
                                        controller: village,
                                        labelText: 'เอกสารอ้างอิง',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.only(
                                  left: 8.0,
                                  right: 8.0,
                                  top: 15.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: Text('เจ้าหนี้'),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: TextFieldInput(
                                        keyboardType: TextInputType.text,
                                        controller: houseNo,
                                        labelText: 'เจ้าหนี้',
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: Text('เลขที่ใบกำกับ'),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: TextFieldInput(
                                        keyboardType: TextInputType.text,
                                        controller: villageNo,
                                        labelText: 'เลขที่ใบกำกับ',
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: Text('วันนที่ใบกำกับ'),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: TextFieldInput(
                                        keyboardType: TextInputType.text,
                                        controller: village,
                                        labelText: 'วันนที่ใบกำกับ',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.only(
                                  left: 8.0,
                                  right: 8.0,
                                  top: 0.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: Text('ประเภทการซื้อ'),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          RadioButton(
                                            description: "ซื้อเงินสด",
                                            value: "ซื้อเงินสด",
                                            groupValue: _purchaseType,
                                            onChanged: (value) => setState(
                                              () => _purchaseType = value.toString(),
                                            ),
                                          ),
                                          RadioButton(
                                            description: "ซื้อเงินเชื่อ",
                                            value: "ซื้อเงินเชื่อ",
                                            groupValue: _purchaseType,
                                            activeColor: Colors.red,
                                            onChanged: (value) => setState(
                                              () => _purchaseType = value.toString(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: Text('ประเภทภาษี'),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          RadioButton(
                                            description: "ภาษีรวมใน",
                                            value: "ภาษีรวมใน",
                                            groupValue: _taxType,
                                            onChanged: (value) => setState(
                                              () => _taxType = value.toString(),
                                            ),
                                          ),
                                          RadioButton(
                                            description: "ภาษีแยกนอก",
                                            value: "ภาษีแยกนอก",
                                            groupValue: _taxType,
                                            activeColor: Colors.red,
                                            onChanged: (value) => setState(
                                              () => _taxType = value.toString(),
                                            ),
                                          ),
                                          RadioButton(
                                            description: "ภาษีอัตราศูนย์",
                                            value: "ภาษีอัตราศูนย์",
                                            groupValue: _taxType,
                                            activeColor: Colors.orange,
                                            onChanged: (value) => setState(
                                              () => _taxType = value.toString(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
              Container(
                margin: const EdgeInsets.only(left: 8.0, right: 8.0),
                height: size.height * 0.34,
                child: Column(
                  children: [
                    Expanded(
                      child: Card(
                        margin: const EdgeInsets.all(8.0),
                        child: Container(
                          margin: const EdgeInsets.all(10.0),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.only(
                                  left: 8.0,
                                  right: 8.0,
                                  top: 15.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: Text('เลขที่เอกสาร'),
                                      ),
                                    ),
                                  ],
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
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.green,
        child: const Icon(Icons.save),
      ),
    );
  }
}
