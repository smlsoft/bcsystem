import 'dart:convert';

import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'package:flutter/material.dart';

class PrinterConfigSelectFormPage extends StatefulWidget {
  final PrinterLocalStrongDataModel printer;

  const PrinterConfigSelectFormPage({super.key, required this.printer});

  @override
  State<PrinterConfigSelectFormPage> createState() => _PrinterConfigSelectFormPageState();
}

class _PrinterConfigSelectFormPageState extends State<PrinterConfigSelectFormPage> {
  Future<String> selectForm() async {
    String result = "";
    await showDialog(
        context: context,
        builder: (context) => SimpleDialog(
              title: Text(global.language('printer_select_form')),
              children: [
                for (var item in global.formDesignList)
                  SimpleDialogOption(
                    onPressed: () {
                      result = item.code;
                      Navigator.pop(context);
                    },
                    child: Text("${item.code} : ${global.getNameFromJsonLanguage(item.names_json, global.userScreenLanguage)}"),
                  )
              ],
            ));
    return result;
  }

  void saveData() {
    var jsonString = const JsonEncoder().convert(widget.printer.toJson());
    global.appStorage.write(widget.printer.code, jsonString);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${global.language('printer_select_form')} : ${widget.printer.name}"),
      ),
      body: Center(
          child: Container(
        width: 500,
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                    flex: 5,
                    child: Text(
                      "ใบสรุปยอด",
                      textAlign: TextAlign.right,
                    )),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                    flex: 5,
                    child: ElevatedButton(
                        onPressed: () async {
                          widget.printer.formSummeryCode = await selectForm();
                          saveData();
                          setState(() {});
                        },
                        child: Text((widget.printer.formSummeryCode.isNotEmpty) ? widget.printer.formSummeryCode : global.language("select")))),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                    flex: 1,
                    child: IconButton(
                        onPressed: (widget.printer.formSummeryCode.isNotEmpty)
                            ? () {
                                setState(() {
                                  widget.printer.formSummeryCode = "";
                                });
                              }
                            : null,
                        icon: const Icon(Icons.clear)))
              ],
            ),
            Row(
              children: [
                const Expanded(
                    flex: 5,
                    child: Text(
                      "ใบเสร็จรับเงิน/กำกับภาษีอย่างย่อ",
                      textAlign: TextAlign.right,
                    )),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                    flex: 5,
                    child: ElevatedButton(
                        onPressed: () async {
                          widget.printer.formTaxCode = await selectForm();
                          saveData();
                          setState(() {});
                        },
                        child: Text((widget.printer.formTaxCode.isNotEmpty) ? widget.printer.formTaxCode : global.language("select")))),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                    flex: 1,
                    child: IconButton(
                        onPressed: (widget.printer.formTaxCode.isNotEmpty)
                            ? () {
                                setState(() {
                                  widget.printer.formTaxCode = "";
                                });
                              }
                            : null,
                        icon: const Icon(Icons.clear)))
              ],
            ),
            Row(
              children: [
                const Expanded(
                    flex: 5,
                    child: Text(
                      "ใบเสร็จรับเงิน/กำกับภาษีอย่างเต็ม",
                      textAlign: TextAlign.right,
                    )),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                    flex: 5,
                    child: ElevatedButton(
                        onPressed: () async {
                          widget.printer.formFullTaxCode = await selectForm();
                          saveData();
                          setState(() {});
                        },
                        child: Text((widget.printer.formFullTaxCode.isNotEmpty) ? widget.printer.formFullTaxCode : global.language("select")))),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                    flex: 1,
                    child: IconButton(
                        onPressed: (widget.printer.formFullTaxCode.isNotEmpty)
                            ? () {
                                setState(() {
                                  widget.printer.formFullTaxCode = "";
                                });
                              }
                            : null,
                        icon: const Icon(Icons.clear)))
              ],
            ),
          ],
        ),
      )),
    );
  }
}
