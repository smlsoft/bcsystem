import 'package:dedecashier/widgets/numpad.dart';
import 'package:dedecashier/model/find/find_item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/bloc/find_item_by_code_name_barcode_bloc.dart';
// import 'package:last_qr_scanner/last_qr_scanner.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/json/pos_model.dart';

class FindItem extends StatefulWidget {
  const FindItem({super.key});

  @override
  State<FindItem> createState() => _FindItemState();
}

class _FindItemState extends State<FindItem> with TickerProviderStateMixin {
  final debouncer = global.Debounce(500);
  final List<FindItemModel> _findByCodeNameLastResult = [];
  ScrollController? _findByTextScrollController;
  final TextEditingController _textFindByTextController = TextEditingController();
  FocusNode? _textFindByTextFocus;

  @override
  void initState() {
    super.initState();
    _textFindByTextFocus = FocusNode();
    _findByTextScrollController = ScrollController()..addListener(_scrollListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
    _findByTextScrollController!.dispose();
    _textFindByTextFocus!.dispose();
  }

  void _scrollListener() {
    if (_findByTextScrollController!.hasClients) {
      if (_findByTextScrollController!.position.pixels == _findByTextScrollController!.position.maxScrollExtent) {
        //context.read<FindItemByCodeNameBarcodeBloc>().add(FindItemByCodeNameBarcodeLoadStart(_textFindByTextController.text, _findByCodeNameLastResult.length, 25));
      }
    }
  }

  Widget findByText() {
    return BlocBuilder<FindItemByCodeNameBarcodeBloc, FindItemByCodeNameBarcodeState>(builder: (context, state) {
      if (state is FindItemByCodeNameBarcodeLoadSuccess) {
        _findByCodeNameLastResult.addAll(state.result);
        context.read<FindItemByCodeNameBarcodeBloc>().add(FindItemByCodeNameBarcodeLoadFinish());
      }
      return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(255, 51, 204, 255), width: 1),
            borderRadius: BorderRadius.circular(5),
            shape: BoxShape.rectangle,
          ),
          child: Column(children: <Widget>[
            TextField(
                autofocus: true,
                focusNode: _textFindByTextFocus,
                controller: _textFindByTextController,
                onChanged: (string) {
                  debouncer.run(() {
                    _findByCodeNameLastResult.clear();
                    context.read<FindItemByCodeNameBarcodeBloc>().add(FindItemByCodeNameBarcodeLoadStart(words: _textFindByTextController.text, offset: 0, limit: 50));
                  });
                },
                decoration: InputDecoration(
                  hintText: "ข้อความบางส่วน (ชื่อ,รหัส)",
                  suffixIcon: IconButton(
                    onPressed: () => setState(() {
                      _findByCodeNameLastResult.clear();
                      _textFindByTextController.clear();
                    }),
                    icon: const Icon(Icons.clear),
                  ),
                )),
            const Row(children: [
              Expanded(flex: 3, child: Text("barcode/item_code")),
              Expanded(flex: 6, child: Text("item_name")),
              Expanded(flex: 2, child: Text("unit_name")),
              Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text("price"))),
              Expanded(flex: 1, child: Align(alignment: Alignment.center, child: Text("minus"))),
              Expanded(flex: 1, child: Align(alignment: Alignment.center, child: Text("qty"))),
              Expanded(flex: 1, child: Align(alignment: Alignment.center, child: Text("plus"))),
              Expanded(flex: 1, child: Align(alignment: Alignment.center, child: Text("save")))
            ]),
            Expanded(
                child: SingleChildScrollView(
                    child: Column(
              children: _findByCodeNameLastResult.map((value) {
                var index = _findByCodeNameLastResult.indexOf(value);
                var detail = _findByCodeNameLastResult[index];
                return Row(children: [
                  Expanded(flex: 3, child: Text("${detail.barcode}/${detail.item_code}")),
                  Expanded(flex: 6, child: Text(global.getNameFromJsonLanguage(detail.item_names, global.userScreenLanguage))),
                  Expanded(flex: 2, child: Text(global.getNameFromJsonLanguage(detail.unit_names, global.userScreenLanguage))),
                  Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text(global.moneyFormat.format(detail.prices[0])))),
                  Expanded(
                      flex: 1,
                      child: Align(
                          alignment: Alignment.center,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(2),
                              ),
                              onPressed: () {
                                setState(() {
                                  if (detail.qty > 0.0) {
                                    detail.qty = detail.qty - 1.0;
                                  }
                                });
                              },
                              child: const Icon(Icons.remove)))),
                  Expanded(
                      flex: 1,
                      child: Align(
                          alignment: Alignment.center,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(2),
                              ),
                              onPressed: () async {
                                await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return StatefulBuilder(builder: (context, setState) {
                                        return AlertDialog(
                                          content: SizedBox(
                                              height: 240,
                                              child: NumberPad(
                                                  title: Text('${detail.item_names[0]} qty ${global.moneyFormat.format(detail.qty)} ${detail.unit_names[0]}'),
                                                  onChange: (qty) => {
                                                        if (qty.isNotEmpty && double.parse(qty) > 0)
                                                          {
                                                            detail.qty = double.parse(qty),
                                                          }
                                                      })),
                                        );
                                      });
                                    });
                                setState(() {});
                              },
                              child: Text(global.qtyShortFormat.format(detail.qty))))),
                  Expanded(
                      flex: 1,
                      child: Align(
                          alignment: Alignment.center,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(2),
                              ),
                              onPressed: () {
                                setState(() {
                                  detail.qty = detail.qty + 1.0;
                                });
                              },
                              child: const Icon(Icons.add)))),
                  Expanded(
                      flex: 1,
                      child: Align(
                          alignment: Alignment.center,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(2),
                              ),
                              onPressed: () {
                                Navigator.pop(
                                    context,
                                    SelectItemConditionModel(
                                        command: 1,
                                        qty: detail.qty,
                                        prices: detail.prices,
                                        data: BarcodeModel(
                                            barcode: detail.barcode, item_code: detail.item_code, item_name: detail.item_names, unit_code: detail.unit_code, unit_name: detail.unit_names)));
                              },
                              child: const Icon(Icons.save))))
                ]);
              }).toList(),
            )))
          ]));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Item"),
      ),
      body: findByText(),
    );
  }
}
