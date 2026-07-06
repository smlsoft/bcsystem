import 'package:smlaicloud/screens/Option/option_add.dart';
import 'package:smlaicloud/components/appbar.dart';
import 'package:smlaicloud/components/textfield_input.dart';
import 'package:smlaicloud/model/choice_model.dart';

import 'package:flutter/material.dart';

class OptionDetailScreen extends StatefulWidget {
  final ChoiceModel choices;

  const OptionDetailScreen({
    Key? key,
    required this.choices,
  }) : super(key: key);

  @override
  _OptionDetailScreenState createState() => _OptionDetailScreenState();
}

class _OptionDetailScreenState extends State<OptionDetailScreen> {
  bool createMode = true;
  // from
  final _formKey = GlobalKey<FormState>();

  final _barcode = TextEditingController();
  final _name1 = TextEditingController();
  final _name2 = TextEditingController();
  final _name3 = TextEditingController();
  final _name4 = TextEditingController();
  final _name5 = TextEditingController();
  final _priceController = TextEditingController();
  final _qty = TextEditingController();
  final _qtymax = TextEditingController();
  final _suggestcode = TextEditingController();
  final _itemunit = TextEditingController();
  bool _selected = false;
  bool _default = true;

  bool _displayNewTextFieldName2 = false;
  bool _displayNewTextFieldName3 = false;
  bool _displayNewTextFieldName4 = false;
  bool _displayNewTextFieldName5 = false;

  @override
  void initState() {
    _barcode.text = widget.choices.barcode;
    _name1.text = widget.choices.name1;
    if (widget.choices.name2 != '') {
      _name2.text = widget.choices.name2;
      _displayNewTextFieldName2 = true;
    }
    if (widget.choices.name3 != '') {
      _name3.text = widget.choices.name3;
      _displayNewTextFieldName3 = true;
    }
    if (widget.choices.name4 != '') {
      _name4.text = widget.choices.name4;
      _displayNewTextFieldName4 = true;
    }
    if (widget.choices.name5 != '') {
      _name5.text = widget.choices.name5;
      _displayNewTextFieldName5 = true;
    }
    if (widget.choices.price.toString() != '0.0') {
      _priceController.text = widget.choices.price.toString();
    }
    if (widget.choices.qty.toString() != '0.0') {
      _qty.text = widget.choices.qty.toString();
    }
    if (widget.choices.qtymax.toString() != '0.0') {
      _qtymax.text = widget.choices.qtymax.toString();
    }

    _suggestcode.text = widget.choices.suggestcode;
    _itemunit.text = widget.choices.itemunit;
    if (widget.choices.selected == true) {
      setState(() {
        _selected = true;
      });
    }
    if (widget.choices.isdefault == true) {
      setState(() {
        _default = true;
      });
    }

    createMode = false;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future _saveData() async {
    double _price = double.parse(_priceController.text.toString());

    if (_qty.text == '') {
      _qty.text = '0';
    }
    if (_qtymax.text == '') {
      _qtymax.text = '0';
    }

    ChoiceModel _result = ChoiceModel(
      barcode: _barcode.text,
      name1: _name1.text,
      name2: _name2.text,
      name3: _name3.text,
      name4: _name4.text,
      name5: _name5.text,
      price: _price,
      qty: double.parse(_qty.text),
      qtymax: double.parse(_qtymax.text),
      suggestcode: _suggestcode.text,
      itemunit: _itemunit.text,
      selected: _selected,
      isdefault: _default,
    );

    // // print(_result.toJson());

    Navigator.pop(context, _result);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.blue[10],
      appBar: BaseAppBar(
        title: (createMode) ? const Text("เพิ่มตัวเลือกย่อย") : const Text("แก้ไขตัวเลือกย่อย"),
        appBar: AppBar(),
        widgets: const <Widget>[],
      ),
      body: Container(
        margin: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: _barcode,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      labelText: 'Barcode',
                      isDense: true,
                      contentPadding: const EdgeInsets.all(10),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณาระบุ Barcode';
                      }
                      return null;
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _name1,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              labelText: 'ชื่อกลุ่มตัวเลือก 1',
                              isDense: true,
                              contentPadding: const EdgeInsets.all(10),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณาระบุ ชื่อกลุ่มตัวเลือก';
                              }
                              return null;
                            },
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 30.0,
                            width: 30.0,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 30.0,
                              icon: const Icon(Icons.add_circle_outline),
                              color: _displayNewTextFieldName2 == true ? Colors.grey : Colors.blue,
                              onPressed: () {
                                _displayNewTextFieldName2 != true
                                    ? setState(() {
                                        _displayNewTextFieldName2 = true;
                                      })
                                    : null;
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: _displayNewTextFieldName2,
                    child: Container(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFieldInput(
                              controller: _name2,
                              keyboardType: TextInputType.text,
                              labelText: 'ชื่อกลุ่มตัวเลือก 2',
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                SizedBox(
                                  height: 30.0,
                                  width: 30.0,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    iconSize: 30.0,
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: _displayNewTextFieldName3 == true ? Colors.grey : Colors.blue,
                                    onPressed: () {
                                      _displayNewTextFieldName3 != true
                                          ? setState(() {
                                              _displayNewTextFieldName3 = true;
                                            })
                                          : null;
                                    },
                                  ),
                                ),
                                SizedBox(
                                  height: 30.0,
                                  width: 30.0,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    iconSize: 30.0,
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: Colors.red,
                                    onPressed: () {
                                      setState(() {
                                        _name2.clear();
                                        _displayNewTextFieldName2 = false;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: _displayNewTextFieldName3,
                    child: Container(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFieldInput(
                              controller: _name3,
                              keyboardType: TextInputType.text,
                              labelText: 'ชื่อกลุ่มตัวเลือก 3',
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                SizedBox(
                                  height: 30.0,
                                  width: 30.0,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    iconSize: 30.0,
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: _displayNewTextFieldName4 == true ? Colors.grey : Colors.blue,
                                    onPressed: () {
                                      _displayNewTextFieldName4 != true
                                          ? setState(() {
                                              _displayNewTextFieldName4 = true;
                                            })
                                          : null;
                                    },
                                  ),
                                ),
                                SizedBox(
                                  height: 30.0,
                                  width: 30.0,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    iconSize: 30.0,
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: Colors.red,
                                    onPressed: () {
                                      setState(() {
                                        _name3.clear();
                                        _displayNewTextFieldName3 = false;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: _displayNewTextFieldName4,
                    child: Container(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFieldInput(
                              controller: _name4,
                              keyboardType: TextInputType.text,
                              labelText: 'ชื่อกลุ่มตัวเลือก 4',
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                SizedBox(
                                  height: 30.0,
                                  width: 30.0,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    iconSize: 30.0,
                                    icon: const Icon(Icons.add_circle_outline),
                                    color: _displayNewTextFieldName5 == true ? Colors.grey : Colors.blue,
                                    onPressed: () {
                                      _displayNewTextFieldName5 != true
                                          ? setState(() {
                                              _displayNewTextFieldName5 = true;
                                            })
                                          : null;
                                    },
                                  ),
                                ),
                                SizedBox(
                                  height: 30.0,
                                  width: 30.0,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    iconSize: 30.0,
                                    icon: const Icon(Icons.remove_circle_outline),
                                    color: Colors.red,
                                    onPressed: () {
                                      setState(() {
                                        _name4.clear();
                                        _displayNewTextFieldName4 = false;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: _displayNewTextFieldName5,
                    child: Container(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFieldInput(
                              controller: _name5,
                              keyboardType: TextInputType.text,
                              labelText: 'ชื่อกลุ่มตัวเลือก 5',
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 30.0,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 30.0,
                                icon: const Icon(Icons.remove_circle_outline),
                                color: Colors.red,
                                onPressed: () {
                                  setState(() {
                                    _name5.clear();
                                    _displayNewTextFieldName5 = false;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        labelText: 'ราคา',
                        isDense: true,
                        contentPadding: const EdgeInsets.all(10),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "กรุณาระบุ ราคา";
                        }
                        return null;
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextFormField(
                      controller: _qty,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        labelText: 'จำนวน',
                        isDense: true,
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextFormField(
                      controller: _qtymax,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        labelText: 'จำนวนสูงสุด',
                        isDense: true,
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextFormField(
                      controller: _suggestcode,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        labelText: 'รหัสแนะนำ',
                        isDense: true,
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextFormField(
                      controller: _itemunit,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        labelText: 'หน่วยนับ',
                        isDense: true,
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Checkbox(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(5.0),
                            ),
                          ),
                          checkColor: Colors.white,
                          value: _selected,
                          onChanged: (bool? value) {
                            setState(() {
                              _selected = value!;
                            });
                          },
                        ),
                        const Text(
                          'เลือกให้เลย',
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(5.0),
                          ),
                        ),
                        checkColor: Colors.white,
                        value: _default,
                        onChanged: (bool? value) {
                          setState(() {
                            _default = value!;
                          });
                        },
                      ),
                      const Text(
                        'ค่าเริ่มต้น',
                      ), //
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _saveData();
          }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.save),
      ),
    );
  }
}
