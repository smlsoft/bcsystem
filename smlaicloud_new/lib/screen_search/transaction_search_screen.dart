import 'dart:io';

import 'package:smlaicloud/bloc/trans/trans_bloc.dart';
import 'package:smlaicloud/global.dart';
import 'package:smlaicloud/model/transaction_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smlaicloud/global.dart' as global;
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class TransSearchScreen extends StatefulWidget {
  const TransSearchScreen({
    super.key,
    required this.type,
    required this.custcode,
  });
  final TransactionTypeEnum type;
  final String custcode;

  @override
  State<TransSearchScreen> createState() => TransSearchScreenState();
}

class TransSearchScreenState extends State<TransSearchScreen> with SingleTickerProviderStateMixin {
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode(skipTraversal: true);
  ScrollController listScrollController = ScrollController();
  String searchText = "";
  List<TransactionModel> transListData = [];
  bool isKeyUp = false;
  bool isKeyDown = false;
  String selectGuid = "";
  int currentListIndex = 0;
  final _debouncer = global.Debouncer(1000);
  int filterTransaction = 1;
  bool loadingData = false;

  TransactionModel emptyResult = TransactionModel(
    shopid: global.apiShopCode,
    guidref: '',
    docno: '',
    docdatetime: '',
    docrefno: '',
    docrefdate: '',
    docreftype: 0,
    doctype: 0,
    vattype: 0,
    custcode: '',
    custnames: [],
    salecode: '',
    salename: '',
    discountword: '',
    totalcost: 0,
    totalvalue: 0,
    totaldiscount: 0,
    totalvatvalue: 0,
    totalaftervat: 0,
    totalexceptvat: 0,
    totalamount: 0,
    cashiercode: '',
    posid: '',
    membercode: '',
    vatrate: 0,
    status: 0,
    inquirytype: 0,
    taxdocdate: '',
    taxdocno: '',
    totalbeforevat: 0,
    transflag: 0,
    iscancel: false,
    ismanualamount: false,
    description: '',
    details: <TransactionDetailModel>[],
    paymentdetailraw: "",
    billpayobjectboxstruct: [],
  );

  List<Widget> tableHeader = [];

  void setSystemLanguageList() async {
    // เพิ่มการ clear transListData
    transListData.clear();
    await global.setSystemLanguage(context);
    loadDataList(searchText, filterTransaction);
  }

  @override
  void initState() {
    setSystemLanguageList();
    listScrollController.addListener(onScrollList);
    searchText = '';
    searchController.text = searchText;

    tableHeader.add(
      Expanded(
          flex: 1,
          child: Text(
            global.language("doc_date"),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          )),
    );
    tableHeader.add(
      Expanded(
          flex: 1,
          child: Text(
            global.language("docno"),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          )),
    );
    if (widget.type != global.TransactionTypeEnum.adjust &&
        widget.type != global.TransactionTypeEnum.stocktransfer &&
        widget.type != global.TransactionTypeEnum.stockreceiveproduct &&
        widget.type != global.TransactionTypeEnum.stockpickupproduct &&
        widget.type != global.TransactionTypeEnum.stockreturnproduct &&
        widget.type != global.TransactionTypeEnum.stockbalance) {
      tableHeader.add(
        Expanded(
            flex: 1,
            child: Text(
                (widget.type == TransactionTypeEnum.purchase ||
                        widget.type == TransactionTypeEnum.purchasereturn ||
                        widget.type == TransactionTypeEnum.accrualreceive ||
                        widget.type == TransactionTypeEnum.purchasepartial ||
                        widget.type == TransactionTypeEnum.purchaseorder)
                    ? global.language("supplier")
                    : global.language("customer"),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center)),
      );
    }
    if (widget.type != global.TransactionTypeEnum.stockbalance) {
      tableHeader.add(
        Expanded(
          flex: 1,
          child: Text(
            textAlign: TextAlign.center,
            global.language("sale_name"),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    if (widget.type != global.TransactionTypeEnum.adjust &&
        widget.type != global.TransactionTypeEnum.stocktransfer &&
        widget.type != global.TransactionTypeEnum.stockreceiveproduct &&
        widget.type != global.TransactionTypeEnum.stockpickupproduct &&
        widget.type != global.TransactionTypeEnum.stockreturnproduct &&
        widget.type != global.TransactionTypeEnum.stockbalance) {
      tableHeader.add(
        Expanded(
          flex: 1,
          child: Text(
            textAlign: TextAlign.center,
            global.language("inquiry_type"),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    if (widget.type == global.TransactionTypeEnum.adjust) {
      tableHeader.add(
        Expanded(
          flex: 1,
          child: Text(
            textAlign: TextAlign.center,
            global.language("adjust_type"),
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    tableHeader.add(
      Expanded(
        flex: 1,
        child: Text(
          textAlign: TextAlign.center,
          global.language("product_list"),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
    if (widget.type != global.TransactionTypeEnum.adjust &&
        widget.type != global.TransactionTypeEnum.stocktransfer &&
        widget.type != global.TransactionTypeEnum.stockpickupproduct &&
        widget.type != global.TransactionTypeEnum.stockreturnproduct) {
      tableHeader.add(
        Expanded(
            flex: 1,
            child: Text(
              textAlign: TextAlign.center,
              global.language("total_value"),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            )),
      );
    }

    super.initState();
  }

  void loadDataList(String search, filterTransaction) {
    setState(() {
      loadingData = true;
      // เพิ่มการ clear transListData เมื่อเป็นการค้นหาใหม่
      if (searchText != search) {
        transListData.clear();
      }
    });
    searchText = search;
    context.read<TransBloc>().add(TransLoad(
          offset: (transListData.isEmpty) ? 0 : transListData.length,
          limit: global.loadDataPerPage,
          search: search,
          type: widget.type,
          custcode: widget.custcode,
          ispos: (filterTransaction == 2)
              ? "true"
              : (filterTransaction == 3)
                  ? "false"
                  : "null",
        ));
  }

  void onScrollList() {
    if (listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange) {
      loadDataList(searchText, filterTransaction);
    }
  }

  @override
  void dispose() {
    listScrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Widget listScreen({bool mobileScreen = false}) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: global.theme.appBarColor,
        automaticallyImplyLeading: false,
        title: Text(global.transactionName(widget.type)),
        leading: IconButton(
          focusNode: FocusNode(skipTraversal: true),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, emptyResult);
          },
        ),
      ),
      body: Focus(
          focusNode: FocusNode(skipTraversal: true, canRequestFocus: true),
          onKey: (node, event) {
            if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
              if (event is RawKeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.escape) {
                  Navigator.pop(context, emptyResult);
                }
                if (event.logicalKey == LogicalKeyboardKey.tab) {
                  if (selectGuid != "") {
                    Navigator.pop(context, emptyResult);
                  }
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  isKeyDown = false;
                  int index = transListData.indexOf(transListData.firstWhere((element) => element.guidfixed == selectGuid));
                  if (index > 0) {
                    selectGuid = transListData[index - 1].guidfixed!;
                    isKeyUp = true;
                  }
                  setState(() {});
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  isKeyUp = false;
                  int index = transListData.indexOf(transListData.firstWhere((element) => element.guidfixed == selectGuid));
                  if (index < transListData.length - 1) {
                    selectGuid = transListData[index + 1].guidfixed!;
                  }
                  isKeyDown = true;
                  setState(() {});
                }
              }
            }
            return KeyEventResult.ignored;
          },
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                color: global.theme.appBarColor,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            onFieldSubmitted: (value) {
                              searchFocusNode.requestFocus();
                            },
                            onChanged: (value) {
                              _debouncer.run(() {
                                try {
                                  setState(() {
                                    transListData = [];
                                  });
                                  loadDataList(value, filterTransaction);
                                } catch (_) {}
                              });
                            },
                            autofocus: true,
                            focusNode: searchFocusNode,
                            controller: searchController,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.only(top: 10, bottom: 10),
                              border: InputBorder.none,
                              hintText: global.language('search'),
                            ),
                          ),
                        ),
                        (widget.type == global.TransactionTypeEnum.sale)
                            ? IconButton(
                                onPressed: () async {
                                  filterTransaction = await filterBox(filterTransaction);
                                  transListData.clear();
                                  loadDataList(searchText, filterTransaction);
                                  setState(() {});
                                },
                                icon: Icon(
                                  (filterTransaction == 1) ? Icons.filter_alt_off : Icons.filter_alt,
                                  color: (filterTransaction == 1) ? Colors.black : Colors.blue,
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                  decoration: BoxDecoration(
                      color: global.theme.columnHeaderColor,
                      border: const Border(
                        bottom: BorderSide(width: 1.0, color: Colors.grey),
                      )),
                  child: Row(children: tableHeader)),
              Expanded(
                child: SingleChildScrollView(
                  controller: listScrollController,
                  child: Column(
                    children: transListData.map((value) => listObject(value)).toList(),
                  ),
                ),
              ),
              if (loadingData)
                Center(
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.blue,
                    size: 50,
                  ),
                ),
            ],
          )),
    );
  }

  Future<int> filterBox(int filterTransaction) async {
    int selectedOption = filterTransaction;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(global.language("filter")),
              content: SizedBox(
                width: 600.0,
                height: 600.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    Text(global.language("filter_transaction")),
                    RadioListTile(
                      title: Text(global.language("all")),
                      value: 1,
                      groupValue: selectedOption,
                      onChanged: (value) {
                        setState(() {
                          selectedOption = value!;
                        });
                      },
                    ),
                    RadioListTile(
                      title: Text(global.language("pos")),
                      value: 2,
                      groupValue: selectedOption,
                      onChanged: (value) {
                        setState(() {
                          selectedOption = value!;
                        });
                      },
                    ),
                    RadioListTile(
                      title: Text(global.language("merchant")),
                      value: 3,
                      groupValue: selectedOption,
                      onChanged: (value) {
                        setState(() {
                          selectedOption = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(global.language("confirm")),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(global.language("cancel")),
                ),
              ],
            );
          },
        );
      },
    );

    return selectedOption;
  }

  Widget listObject(TransactionModel value) {
    DateTime docDateTime = DateTime.parse(value.docdatetime);
    List<Widget> tableDetails = [];

    tableDetails.add(
      Expanded(
          flex: 1,
          child: Text(DateFormat('dd/MM/yyyy HH:mm').format(docDateTime.toLocal()),
              style: TextStyle(
                color: (value.iscancel == true) ? Colors.red : Colors.black,
              ))),
    );
    tableDetails.add(
      Expanded(
        flex: 1,
        child: Text(value.docno,
            style: TextStyle(
              color: (value.iscancel == true) ? Colors.red : Colors.black,
            )),
      ),
    );
    if (widget.type != global.TransactionTypeEnum.adjust &&
        widget.type != global.TransactionTypeEnum.stocktransfer &&
        widget.type != global.TransactionTypeEnum.stockreceiveproduct &&
        widget.type != global.TransactionTypeEnum.stockpickupproduct &&
        widget.type != global.TransactionTypeEnum.stockreturnproduct &&
        widget.type != global.TransactionTypeEnum.stockbalance) {
      tableDetails.add(Expanded(
          flex: 1,
          child: Text("${value.custcode} : ${global.activeLangName(value.custnames ?? [])}",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: (value.iscancel == true) ? Colors.red : Colors.black,
              ))));
    }
    if (widget.type != global.TransactionTypeEnum.stockbalance) {
      tableDetails.add(
        Expanded(
            flex: 1,
            child: Text(value.salename,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: (value.iscancel == true) ? Colors.red : Colors.black,
                ))),
      );
    }

    if (widget.type != global.TransactionTypeEnum.adjust &&
        widget.type != global.TransactionTypeEnum.stocktransfer &&
        widget.type != global.TransactionTypeEnum.stockreceiveproduct &&
        widget.type != global.TransactionTypeEnum.stockpickupproduct &&
        widget.type != global.TransactionTypeEnum.stockreturnproduct &&
        widget.type != global.TransactionTypeEnum.stockbalance) {
      tableDetails.add(
        Expanded(
            flex: 1,
            child: Text(value.inquirytype == 0 ? global.language('credit') : global.language('cash'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: (value.iscancel == true) ? Colors.red : Colors.black,
                ))),
      );
    }
    if (widget.type == global.TransactionTypeEnum.adjust) {
      tableDetails.add(
        Expanded(
            flex: 1,
            child: Text(
              value.transflag == 66
                  ? global.language('increase')
                  : value.transflag == 68
                      ? global.language('decrease')
                      : global.language('adjust_cost'),
              textAlign: TextAlign.center,
            )),
      );
    }
    if (widget.type != global.TransactionTypeEnum.stockbalance) {
      tableDetails.add(
        Expanded(
            flex: 1,
            child: Text(value.details!.length.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: (value.iscancel == true) ? Colors.red : Colors.black,
                ))),
      );
    } else {
      tableDetails.add(
        Expanded(
            flex: 1,
            child: Text(
              global.formatNumber(value.totalqty!),
              textAlign: TextAlign.right,
            )),
      );
    }

    if (widget.type != global.TransactionTypeEnum.adjust &&
        widget.type != global.TransactionTypeEnum.stocktransfer &&
        widget.type != global.TransactionTypeEnum.stockpickupproduct &&
        widget.type != global.TransactionTypeEnum.stockreturnproduct) {
      tableDetails.add(
        Expanded(
            flex: 1,
            child: Text(global.formatNumber(value.totalamount),
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: (value.iscancel == true) ? Colors.red : Colors.black,
                ))),
      );
    }
    return GestureDetector(
        onTap: () {
          Navigator.pop(context, value);
        },
        child: Container(
            decoration: BoxDecoration(
              color: (selectGuid == value.guidfixed) ? Colors.cyan[100] : Colors.white,
              border: const Border(
                bottom: BorderSide(width: 1.0, color: Colors.grey),
              ),
            ),
            padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: tableDetails)));
  }

  @override
  Widget build(BuildContext context) {
    for (int i = 0; i < transListData.length; i++) {
      if (transListData[i].guidfixed == selectGuid) {
        currentListIndex = i;
        break;
      }
    }
    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(builder: (context, constraints) {
          return BlocListener<TransBloc, TransState>(
              listener: (context, state) {
                // Load
                if (state is TransLoadSuccess) {
                  setState(() {
                    loadingData = false;
                    if (state.trans.isNotEmpty) {
                      transListData.addAll(state.trans);
                      if (transListData.isNotEmpty) {
                        selectGuid = transListData[0].guidfixed!;
                      } else {
                        selectGuid = "";
                      }
                    }
                  });
                }
              },
              child: (constraints.maxWidth > 800) ? listScreen(mobileScreen: false) : listScreen(mobileScreen: true));
        }));
  }
}
