import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smlaicloud/model/transaction_model.dart';
import 'package:smlaicloud/model/customer_model.dart';
import 'package:smlaicloud/model/employee_model.dart';
import 'package:smlaicloud/repositories/customer_repository.dart';
import 'package:smlaicloud/repositories/employee_repository.dart';
import 'package:smlaicloud/utils/date_picker.dart';
import 'package:smlaicloud/global.dart' as global;
import 'package:smlaicloud/screen_search/company_branch_search_screen.dart';
import 'package:smlaicloud/model/global_model.dart';
import 'package:intl/intl.dart';

class DocumentHeaderWidget extends StatelessWidget {
  final TransactionModel screenData;
  final global.TransactionTypeEnum transactionType;
  final Function(void Function()) setState;
  final BuildContext context;
  final TextEditingController custCodeController;
  final TextEditingController custnamesController;
  final TextEditingController saleCodeController;
  final TextEditingController saleNameController;
  final TextEditingController docRefNumberController;
  final TextEditingController taxDocNoController;
  final TextEditingController vatRateController;
  final TextEditingController descriptionController;
  final TextEditingController transportAmountController;
  final TextEditingController docDateController;
  final TextEditingController docTimeController;
  final bool docDateTimeValidated;
  final global.Debouncer debouncer;
  final Function() calTotalValue;
  final Function() headerTableDetail;
  final Function({required String word}) searchCustomer;
  final Function({required String word}) searchSupplier;
  final Function({required String word}) searchSale;
  final Function({required String word}) searchSaleChannel;

  const DocumentHeaderWidget({
    Key? key,
    required this.screenData,
    required this.transactionType,
    required this.setState,
    required this.context,
    required this.custCodeController,
    required this.custnamesController,
    required this.saleCodeController,
    required this.saleNameController,
    required this.docRefNumberController,
    required this.taxDocNoController,
    required this.vatRateController,
    required this.descriptionController,
    required this.transportAmountController,
    required this.docDateController,
    required this.docTimeController,
    required this.docDateTimeValidated,
    required this.debouncer,
    required this.calTotalValue,
    required this.headerTableDetail,
    required this.searchCustomer,
    required this.searchSupplier,
    required this.searchSale,
    required this.searchSaleChannel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomDatePicker(
                    key: ValueKey(screenData.docdatetime),
                    labelText: global.language("doc_date"),
                    initialDate: DateTime.parse(screenData.docdatetime),
                    useBuddhistCalendar: true,
                    onDateSelected: (date) {
                      if (date != null) {
                        setState(() {
                          final currentTime = DateTime.parse(screenData.docdatetime);
                          final combinedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            currentTime.hour,
                            currentTime.minute,
                            currentTime.second,
                            currentTime.millisecond,
                          );

                          screenData.docdatetime = combinedDateTime.toLocal().toIso8601String();

                          // เมื่อเปลี่ยน docdatetime ให้ taxdocdate เปลี่ยนตามด้วย
                          final currentTaxTime = DateTime.parse(screenData.taxdocdate);
                          final newTaxDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            currentTaxTime.hour,
                            currentTaxTime.minute,
                            currentTaxTime.second,
                            currentTaxTime.millisecond,
                          );
                          screenData.taxdocdate = newTaxDateTime.toLocal().toIso8601String();

                          if (global.profileData.yeartype == "buddhist") {
                            docDateController.text = global.dateTimeBuddhist(
                              combinedDateTime,
                              format: global.DateTimeFormatEnum.dateDay,
                            );
                          } else {
                            docDateController.text = DateFormat('dd/MM/yyyy').format(combinedDateTime);
                          }

                          docTimeController.text = DateFormat('HH:mm').format(combinedDateTime);
                        });
                      }
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: global.language("doc_date"),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: global.language("doc_time"),
                    ),
                    controller: docTimeController,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            (transactionType == global.TransactionTypeEnum.purchase ||
                    transactionType == global.TransactionTypeEnum.purchaseorder ||
                    transactionType == global.TransactionTypeEnum.purchasepartial ||
                    transactionType == global.TransactionTypeEnum.purchasereturn ||
                    transactionType == global.TransactionTypeEnum.sale ||
                    transactionType == global.TransactionTypeEnum.saleorder ||
                    transactionType == global.TransactionTypeEnum.salereturn ||
                    transactionType == global.TransactionTypeEnum.accrualreceive)
                ? Row(
                    children: [
                      Expanded(
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (RawKeyEvent event) {
                            if (event is RawKeyDownEvent) {
                              if (event.logicalKey == LogicalKeyboardKey.f2) {
                                if (transactionType == global.TransactionTypeEnum.purchase ||
                                    transactionType == global.TransactionTypeEnum.purchaseorder ||
                                    transactionType == global.TransactionTypeEnum.purchasepartial ||
                                    transactionType == global.TransactionTypeEnum.purchasereturn ||
                                    transactionType == global.TransactionTypeEnum.accrualreceive) {
                                  searchSupplier(word: "");
                                } else {
                                  searchCustomer(word: "");
                                }
                              }
                            }
                          },
                          child: TextField(
                            onSubmitted: (value) {
                              if (kIsWeb) {}
                            },
                            onChanged: (code) {
                              debouncer.run(() {
                                try {
                                  if (code.trim().isNotEmpty) {
                                    if (transactionType == global.TransactionTypeEnum.purchase ||
                                        transactionType == global.TransactionTypeEnum.purchaseorder ||
                                        transactionType == global.TransactionTypeEnum.purchasepartial ||
                                        transactionType == global.TransactionTypeEnum.purchasereturn ||
                                        transactionType == global.TransactionTypeEnum.accrualreceive) {
                                      CustomerRepository().getSupplierByCode(code.trim()).then((value) {
                                        if (value.success && value.data != null) {
                                          CustomerModel cust = CustomerModel.fromJson(value.data);
                                          if (cust.iscreditor) {
                                            custnamesController.text = global.activeLangName(cust.names);
                                            screenData.custnames = cust.names;
                                          } else {
                                            custnamesController.text = global.language("Supplier Not Found");
                                            screenData.custnames = [];
                                          }
                                        } else {
                                          custnamesController.text = global.language("Supplier Not Found");
                                        }
                                      }).onError((error, stackTrace) {
                                        custnamesController.text = global.language("Supplier Not Found");
                                      });
                                      screenData.custcode = code;
                                    } else {
                                      CustomerRepository().getCustomerByCode(code.trim()).then((value) {
                                        if (value.success && value.data != null) {
                                          CustomerModel cust = CustomerModel.fromJson(value.data);
                                          custnamesController.text = global.activeLangName(cust.names);
                                          screenData.custnames = cust.names;
                                        } else {
                                          custnamesController.text = global.language("Customer Not Found");
                                        }
                                      }).onError((error, stackTrace) {
                                        custnamesController.text = global.language("Customer Not Found");
                                      });
                                      screenData.custcode = code;
                                    }
                                  } else {
                                    custnamesController.text = global.language("Customer Not Found");
                                  }
                                } catch (_) {}
                              });
                            },
                            textAlign: TextAlign.left,
                            controller: custCodeController,
                            decoration: InputDecoration(
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              border: const OutlineInputBorder(),
                              labelText: (transactionType == global.TransactionTypeEnum.purchase ||
                                      transactionType == global.TransactionTypeEnum.purchaseorder ||
                                      transactionType == global.TransactionTypeEnum.purchasepartial ||
                                      transactionType == global.TransactionTypeEnum.purchasereturn ||
                                      transactionType == global.TransactionTypeEnum.accrualreceive)
                                  ? global.language("supplier_code")
                                  : global.language("customer_code"),
                              suffixIcon: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    focusNode: FocusNode(skipTraversal: true),
                                    icon: const Icon(Icons.search),
                                    onPressed: () {
                                      if (transactionType == global.TransactionTypeEnum.purchase ||
                                          transactionType == global.TransactionTypeEnum.purchaseorder ||
                                          transactionType == global.TransactionTypeEnum.purchasepartial ||
                                          transactionType == global.TransactionTypeEnum.purchasereturn ||
                                          transactionType == global.TransactionTypeEnum.accrualreceive) {
                                        searchSupplier(word: "");
                                      } else {
                                        searchCustomer(word: "");
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          focusNode: null,
                          textAlign: TextAlign.left,
                          controller: custnamesController,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(10.0),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey, width: 0.0),
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: const OutlineInputBorder(),
                            labelText: (transactionType == global.TransactionTypeEnum.purchase ||
                                    transactionType == global.TransactionTypeEnum.purchaseorder ||
                                    transactionType == global.TransactionTypeEnum.purchasepartial ||
                                    transactionType == global.TransactionTypeEnum.purchasereturn ||
                                    transactionType == global.TransactionTypeEnum.accrualreceive)
                                ? global.language("supplier_name")
                                : global.language("customer_name"),
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: RawKeyboardListener(
                    focusNode: FocusNode(),
                    onKey: (RawKeyEvent event) {
                      if (event is RawKeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.f2) {
                          searchSale(word: "");
                        }
                      }
                    },
                    child: TextField(
                      onSubmitted: (value) {
                        if (kIsWeb) {}
                      },
                      onChanged: (code) {
                        debouncer.run(() {
                          if (code.trim().isNotEmpty) {
                            EmployeeRepository().getEmployeeByCode(code.trim()).then((value) {
                              if (value.success && value.data != null) {
                                EmployeeModel emp = EmployeeModel.fromJson(value.data);
                                saleNameController.text = emp.name;
                                screenData.salename = emp.name;
                                screenData.salecode = code;
                              } else {
                                saleNameController.text = global.language("Employee_not_found");
                                screenData.salename = "";
                                screenData.salecode = "";
                              }
                            }).onError((error, stackTrace) {
                              saleNameController.text = global.language("Employee_not_found");
                              screenData.salename = "";
                              screenData.salecode = "";
                            });
                          } else {
                            screenData.salename = "";
                            screenData.salecode = "";
                            saleNameController.text = global.language("Employee_not_found");
                          }
                        });
                      },
                      textAlign: TextAlign.left,
                      controller: saleCodeController,
                      decoration: InputDecoration(
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: const OutlineInputBorder(),
                        labelText: global.language("sale_code"),
                        suffixIcon: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              focusNode: FocusNode(skipTraversal: true),
                              icon: const Icon(Icons.search),
                              onPressed: () {
                                searchSale(word: "");
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: TextField(
                    readOnly: true,
                    focusNode: null,
                    textAlign: TextAlign.left,
                    controller: saleNameController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(10.0),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 0.0),
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: const OutlineInputBorder(),
                      labelText: global.language("sale_name"),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            (transactionType == global.TransactionTypeEnum.purchase ||
                    transactionType == global.TransactionTypeEnum.purchaseorder ||
                    transactionType == global.TransactionTypeEnum.purchasepartial ||
                    transactionType == global.TransactionTypeEnum.purchasereturn ||
                    transactionType == global.TransactionTypeEnum.sale ||
                    transactionType == global.TransactionTypeEnum.saleorder ||
                    transactionType == global.TransactionTypeEnum.salereturn ||
                    transactionType == global.TransactionTypeEnum.accrualreceive)
                ? Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: global.language('vat_type'),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          borderSide: const BorderSide(color: Colors.grey, width: 0.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Row(
                            children: [
                              Radio(
                                  value: 0,
                                  groupValue: screenData.vattype,
                                  onChanged: (value) {
                                    setState(() {
                                      screenData.vattype = 0;
                                      Future.delayed(const Duration(milliseconds: 200), () {
                                        calTotalValue();
                                      });
                                    });
                                  }),
                              Expanded(
                                  child: Text(
                                global.language("vat_exclude"),
                                overflow: TextOverflow.clip,
                              ))
                            ],
                          )),
                          Expanded(
                              child: Row(
                            children: [
                              Radio(
                                  value: 1,
                                  groupValue: screenData.vattype,
                                  onChanged: (value) {
                                    setState(() {
                                      screenData.vattype = 1;
                                      Future.delayed(const Duration(milliseconds: 200), () {
                                        calTotalValue();
                                      });
                                    });
                                  }),
                              Expanded(
                                  child: Text(
                                global.language("vat_include"),
                                overflow: TextOverflow.clip,
                              ))
                            ],
                          )),
                          Expanded(
                              child: Row(children: [
                            Radio(
                                value: 2,
                                groupValue: screenData.vattype,
                                activeColor: Colors.blue,
                                onChanged: (value) {
                                  setState(() {
                                    screenData.vattype = 2;
                                    Future.delayed(const Duration(milliseconds: 200), () {
                                      calTotalValue();
                                    });
                                  });
                                }),
                            Expanded(
                              child: Text(
                                global.language("vat_zero"),
                                overflow: TextOverflow.clip,
                              ),
                            )
                          ])),
                          Expanded(
                              child: Row(children: [
                            Radio(
                                value: 3,
                                groupValue: screenData.vattype,
                                activeColor: Colors.blue,
                                onChanged: (value) {
                                  setState(() {
                                    screenData.vattype = 3;
                                    Future.delayed(const Duration(milliseconds: 200), () {
                                      calTotalValue();
                                    });
                                  });
                                }),
                            Expanded(
                              child: Text(
                                global.language("vat_none"),
                                overflow: TextOverflow.clip,
                              ),
                            )
                          ])),
                        ],
                      ),
                    ),
                  )
                : Container(),
            (transactionType == global.TransactionTypeEnum.purchase || transactionType == global.TransactionTypeEnum.sale)
                ? Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: global.language('inquiry_type'),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          borderSide: const BorderSide(color: Colors.grey, width: 0.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Row(
                            children: [
                              Radio(
                                  value: 0,
                                  groupValue: screenData.inquirytype,
                                  onChanged: (value) {
                                    setState(() {
                                      screenData.inquirytype = 0;
                                    });
                                  }),
                              Expanded(
                                  child: Text(
                                global.language("credit"),
                                overflow: TextOverflow.clip,
                              ))
                            ],
                          )),
                          Expanded(
                              child: Row(
                            children: [
                              Radio(
                                  value: 1,
                                  groupValue: screenData.inquirytype,
                                  onChanged: (value) {
                                    setState(() {
                                      screenData.inquirytype = 1;
                                    });
                                  }),
                              Expanded(
                                  child: Text(
                                global.language("cash"),
                                overflow: TextOverflow.clip,
                              ))
                            ],
                          )),
                        ],
                      ),
                    ),
                  )
                : (transactionType == global.TransactionTypeEnum.purchasereturn || transactionType == global.TransactionTypeEnum.salereturn)
                    ? Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: global.language('inquiry_type'),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4.0),
                              borderSide: const BorderSide(color: Colors.grey, width: 0.0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Radio(
                                        value: 0,
                                        groupValue: screenData.inquirytype,
                                        onChanged: (value) {
                                          setState(() {
                                            screenData.inquirytype = 0;
                                          });
                                        }),
                                    Expanded(
                                        child: Text(
                                      (transactionType == global.TransactionTypeEnum.purchasereturn)
                                          ? global.language("return_credit_purchaser")
                                          : global.language("return_credit_sale"),
                                      overflow: TextOverflow.clip,
                                    ))
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Radio(
                                        value: 1,
                                        groupValue: screenData.inquirytype,
                                        onChanged: (value) {
                                          setState(() {
                                            screenData.inquirytype = 1;
                                          });
                                        }),
                                    Expanded(
                                        child: Text(
                                      (transactionType == global.TransactionTypeEnum.purchasereturn)
                                          ? global.language("reduce_credit_purchaser")
                                          : global.language("reduce_credit_sale"),
                                      overflow: TextOverflow.clip,
                                    ))
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Radio(
                                        value: 2,
                                        groupValue: screenData.inquirytype,
                                        onChanged: (value) {
                                          setState(() {
                                            screenData.inquirytype = 2;
                                          });
                                        }),
                                    Expanded(
                                        child: Text(
                                      (transactionType == global.TransactionTypeEnum.purchasereturn)
                                          ? global.language("return_cash_purchaser")
                                          : global.language("return_cash_sale"),
                                      overflow: TextOverflow.clip,
                                    ))
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Radio(
                                        value: 3,
                                        groupValue: screenData.inquirytype,
                                        onChanged: (value) {
                                          setState(() {
                                            screenData.inquirytype = 3;
                                          });
                                        }),
                                    Expanded(
                                        child: Text(
                                      (transactionType == global.TransactionTypeEnum.purchasereturn)
                                          ? global.language("reduce_cash_purchaser")
                                          : global.language("reduce_cash_sale"),
                                      overflow: TextOverflow.clip,
                                    ))
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Container(),

            (transactionType == global.TransactionTypeEnum.stockpickupproduct)
                ? Container(
                    margin: const EdgeInsets.only(bottom: 20, top: 10),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: global.language('inquiry_type'),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          borderSide: const BorderSide(color: Colors.grey, width: 0.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Radio(
                                    value: 0,
                                    groupValue: screenData.inquirytype,
                                    onChanged: (value) {
                                      setState(() {
                                        screenData.inquirytype = 0;
                                      });
                                    }),
                                Expanded(child: Text(global.language("withdraw_production"), overflow: TextOverflow.clip))
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Radio(
                                  value: 1,
                                  groupValue: screenData.inquirytype,
                                  onChanged: (value) {
                                    setState(() {
                                      screenData.inquirytype = 1;
                                    });
                                  },
                                ),
                                Expanded(child: Text(global.language("withdraw_for_your_own_use"), overflow: TextOverflow.clip))
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Radio(
                                    value: 2,
                                    groupValue: screenData.inquirytype,
                                    onChanged: (value) {
                                      setState(() {
                                        screenData.inquirytype = 2;
                                      });
                                    }),
                                Expanded(child: Text(global.language("pick_up_damaged_items"), overflow: TextOverflow.clip))
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Radio(
                                    value: 9,
                                    groupValue: screenData.inquirytype,
                                    onChanged: (value) {
                                      setState(() {
                                        screenData.inquirytype = 9;
                                      });
                                    }),
                                Expanded(child: Text(global.language("other"), overflow: TextOverflow.clip))
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(),
            (transactionType == global.TransactionTypeEnum.adjust)
                ? Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: global.language('adjust_type'),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          borderSide: const BorderSide(color: Colors.grey, width: 0.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Row(
                            children: [
                              Radio(
                                  value: 66,
                                  groupValue: screenData.transflag,
                                  onChanged: (value) {
                                    setState(() {
                                      screenData.transflag = 66;
                                      headerTableDetail();
                                    });
                                  }),
                              Expanded(
                                  child: Text(
                                global.language("increase"),
                                overflow: TextOverflow.clip,
                              ))
                            ],
                          )),
                          Expanded(
                              child: Row(
                            children: [
                              Radio(
                                  value: 68,
                                  groupValue: screenData.transflag,
                                  onChanged: (value) {
                                    setState(() {
                                      screenData.transflag = 68;
                                      headerTableDetail();
                                    });
                                  }),
                              Expanded(
                                  child: Text(
                                global.language("decrease"),
                                overflow: TextOverflow.clip,
                              ))
                            ],
                          )),
                          Expanded(
                              child: Row(
                            children: [
                              Radio(
                                  value: 866,
                                  groupValue: screenData.transflag,
                                  onChanged: (value) {
                                    setState(() {
                                      screenData.transflag = 866;
                                      headerTableDetail();
                                    });
                                  }),
                              Expanded(
                                  child: Text(
                                'ปรับปรุงมูลค่าเพิ่ม',
                                overflow: TextOverflow.clip,
                              ))
                            ],
                          )),
                          Expanded(
                              child: Row(
                            children: [
                              Radio(
                                  value: 868,
                                  groupValue: screenData.transflag,
                                  onChanged: (value) {
                                    setState(() {
                                      screenData.transflag = 868;
                                      headerTableDetail();
                                    });
                                  }),
                              Expanded(
                                  child: Text(
                                'ปรับปรุงมูลค่าลด',
                                overflow: TextOverflow.clip,
                              ))
                            ],
                          )),
                          // Expanded(
                          //     child: Row(
                          //   children: [
                          //     Radio(
                          //         value: 966,
                          //         groupValue: screenData.transflag,
                          //         onChanged: (value) {
                          //           setState(() {
                          //             screenData.transflag = 966;
                          //             headerTableDetail();
                          //           });
                          //         }),
                          //     Expanded(
                          //         child: Text(
                          //       global.language("adjust_cost"),
                          //       overflow: TextOverflow.clip,
                          //     ))
                          //   ],
                          // )),
                        ],
                      ),
                    ),
                  )
                : Container(),
            (transactionType == global.TransactionTypeEnum.purchase ||
                    transactionType == global.TransactionTypeEnum.purchaseorder ||
                    transactionType == global.TransactionTypeEnum.purchasepartial ||
                    transactionType == global.TransactionTypeEnum.purchasereturn ||
                    transactionType == global.TransactionTypeEnum.sale ||
                    transactionType == global.TransactionTypeEnum.saleorder ||
                    transactionType == global.TransactionTypeEnum.salereturn ||
                    transactionType == global.TransactionTypeEnum.accrualreceive)
                ? Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: global.language('var_rate'),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [global.NumberInputFormatter()],
                            controller: vatRateController,
                            onChanged: (value) {
                              setState(() {
                                screenData.vatrate = double.parse(value);
                                calTotalValue();
                              });
                            },
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: global.language('branch'),
                              suffixIcon: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    focusNode: FocusNode(skipTraversal: true),
                                    icon: const Icon(Icons.search),
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => const CompanyBranchSearchScreen(
                                                    word: "",
                                                  ))).then((value) {
                                        setState(() {
                                          SearchGuidCodeNameModel result = value;
                                          if (result.isCancel == false) {
                                            screenData.branch!.guidfixed = result.guid;
                                            screenData.branch!.code = result.code;
                                            screenData.branch!.names = result.names;
                                          }
                                        });
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            controller: TextEditingController(text: "${screenData.branch!.code!} ~ ${global.activeLangName(screenData.branch!.names!)}"),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: global.language('branch'),
                              suffixIcon: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    focusNode: FocusNode(skipTraversal: true),
                                    icon: const Icon(Icons.search),
                                    onPressed: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => const CompanyBranchSearchScreen(
                                                    word: "",
                                                  ))).then((value) {
                                        setState(() {
                                          SearchGuidCodeNameModel result = value;
                                          if (result.isCancel == false) {
                                            screenData.branch!.guidfixed = result.guid;
                                            screenData.branch!.code = result.code;
                                            screenData.branch!.names = result.names;
                                          }
                                        });
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            controller: TextEditingController(text: "${screenData.branch!.code!} ~ ${global.activeLangName(screenData.branch!.names!)}"),
                          ),
                        ),
                      ],
                    ),
                  ),

            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  (transactionType == global.TransactionTypeEnum.stockreceiveproduct || transactionType == global.TransactionTypeEnum.stockpickupproduct)
                      ? Expanded(
                          child: RawKeyboardListener(
                              focusNode: FocusNode(),
                              // onKey: (RawKeyEvent event) {
                              //   if (event is RawKeyDownEvent) {
                              //     if (event.logicalKey == LogicalKeyboardKey.f2) {
                              //       searchDocRef();
                              //     }
                              //   }
                              // },
                              child: TextField(
                                onSubmitted: (value) {
                                  if (kIsWeb) {}
                                },
                                onChanged: (value) {
                                  setState(() {
                                    screenData.docrefno = value;
                                  });
                                },
                                textAlign: TextAlign.left,
                                controller: docRefNumberController,
                                decoration: InputDecoration(
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                  border: const OutlineInputBorder(),
                                  labelText: global.language("doc_ref"),
                                  // suffixIcon: Row(
                                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                                  //   mainAxisSize: MainAxisSize.min,
                                  //   children: [
                                  //     IconButton(
                                  //       focusNode: FocusNode(skipTraversal: true),
                                  //       icon: const Icon(Icons.search),
                                  //       onPressed: () {
                                  //         searchDocRef();
                                  //       },
                                  //     ),
                                  //   ],
                                  // ),
                                ),
                              )))
                      : (transactionType != global.TransactionTypeEnum.purchasereturn &&
                              transactionType != global.TransactionTypeEnum.salereturn &&
                              transactionType != global.TransactionTypeEnum.stockreturnproduct)
                          ? Expanded(
                              child: TextField(
                                onSubmitted: (value) {
                                  if (kIsWeb) {}
                                },
                                onChanged: (value) {
                                  setState(() {
                                    screenData.docrefno = value;
                                  });
                                },
                                textAlign: TextAlign.left,
                                controller: docRefNumberController,
                                decoration: InputDecoration(
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                  border: const OutlineInputBorder(),
                                  labelText: global.language("doc_ref"),
                                ),
                              ),
                            )
                          : Container(),
                  const SizedBox(
                    width: 10,
                  ),
                  if (transactionType != global.TransactionTypeEnum.purchasereturn &&
                      transactionType != global.TransactionTypeEnum.salereturn &&
                      transactionType != global.TransactionTypeEnum.stockreturnproduct)
                    Expanded(
                      child: CustomDatePicker(
                        key: ValueKey(screenData.docrefdate),
                        labelText: global.language("doc_ref_date"),
                        initialDate: DateTime.parse(screenData.docrefdate),
                        useBuddhistCalendar: true,
                        onDateSelected: (date) {
                          if (date != null) {
                            setState(() {
                              // กำหนดเวลาจากวันที่ที่เลือกโดยรักษาเวลาเดิม
                              final currentTime = DateTime.parse(screenData.docrefdate);
                              final combinedDateTime = DateTime(date.year, date.month, date.day, currentTime.hour, currentTime.minute, currentTime.second, currentTime.millisecond);

                              screenData.docrefdate = combinedDateTime.toLocal().toIso8601String();
                            });
                          }
                        },
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: const OutlineInputBorder(),
                          labelText: global.language("doc_ref_date"),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            (transactionType == global.TransactionTypeEnum.purchase ||
                    transactionType == global.TransactionTypeEnum.purchaseorder ||
                    transactionType == global.TransactionTypeEnum.purchasepartial ||
                    transactionType == global.TransactionTypeEnum.purchasereturn ||
                    transactionType == global.TransactionTypeEnum.sale ||
                    transactionType == global.TransactionTypeEnum.saleorder ||
                    transactionType == global.TransactionTypeEnum.salereturn ||
                    transactionType == global.TransactionTypeEnum.stockreturnproduct ||
                    transactionType == global.TransactionTypeEnum.accrualreceive)
                ? Row(
                    children: [
                      Expanded(
                          child: TextField(
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: const OutlineInputBorder(),
                          labelText: global.language('tax_docno'),
                        ),
                        controller: taxDocNoController,
                        onChanged: (value) {
                          setState(() {
                            screenData.taxdocno = value;
                          });
                        },
                      )),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: CustomDatePicker(
                          key: ValueKey(screenData.taxdocdate),
                          labelText: global.language("tax_doc_date"),
                          initialDate: DateTime.parse(screenData.taxdocdate),
                          useBuddhistCalendar: true,
                          onDateSelected: (date) {
                            if (date != null) {
                              setState(() {
                                // กำหนดเวลาจากวันที่ที่เลือกโดยรักษาเวลาเดิม
                                final currentTime = DateTime.parse(screenData.taxdocdate);
                                final combinedDateTime =
                                    DateTime(date.year, date.month, date.day, currentTime.hour, currentTime.minute, currentTime.second, currentTime.millisecond);

                                screenData.taxdocdate = combinedDateTime.toLocal().toIso8601String();
                              });
                            }
                          },
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: const OutlineInputBorder(),
                            labelText: global.language("tax_doc_date"),
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(),
            const SizedBox(
              height: 20,
            ),

            Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                      child: TextField(
                    maxLines: 4,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: const OutlineInputBorder(),
                      labelText: global.language('disciption'),
                    ),
                    controller: descriptionController,
                    onChanged: (value) {
                      setState(() {
                        screenData.description = value;
                      });
                    },
                  )),
                ],
              ),
            ),

            /// isusedelivery and is use transport
            (transactionType == global.TransactionTypeEnum.sale)
                ? Column(
                    children: [
                      if (global.posVersion == global.PosVersionEnum.restaurant)
                        Row(
                          children: [
                            Switch(
                              value: screenData.isdelivery!,
                              onChanged: (value) {
                                setState(() {
                                  screenData.isdelivery = value;
                                });
                              },
                              activeTrackColor: Colors.lightGreenAccent,
                              activeColor: Colors.green,
                            ),
                            Text(global.language("is_use_delivery")),
                          ],
                        ),
                      const SizedBox(
                        height: 10,
                      ),
                      (screenData.isdelivery!)
                          ? Container(
                              padding: const EdgeInsets.only(left: 20, right: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      readOnly: true,
                                      textAlign: TextAlign.left,
                                      controller: TextEditingController(text: screenData.salechannelcode!),
                                      decoration: InputDecoration(
                                        floatingLabelBehavior: FloatingLabelBehavior.always,
                                        border: const OutlineInputBorder(),
                                        labelText: global.language("sale_channel_code"),
                                        suffixIcon: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              focusNode: FocusNode(skipTraversal: true),
                                              icon: const Icon(Icons.search),
                                              onPressed: () {
                                                searchSaleChannel(word: "");
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: TextField(
                                      enabled: false,
                                      focusNode: null,
                                      textAlign: TextAlign.left,
                                      controller: TextEditingController(text: screenData.salechannelgp!.toString()),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.all(10.0),
                                        enabledBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.grey, width: 0.0),
                                        ),
                                        floatingLabelBehavior: FloatingLabelBehavior.always,
                                        border: const OutlineInputBorder(),
                                        labelText: global.language("sale_channel_gp"),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    (screenData.salechannelgptype! == 0) ? "%" : global.language("money_symbol"),
                                    style: const TextStyle(fontSize: 12),
                                  )
                                ],
                              ),
                            )
                          : Container(),

                      // /// transport
                      // Row(
                      //   children: [
                      //     Switch(
                      //       value: screenData.istransport!,
                      //       onChanged: (value) {
                      //         setState(() {
                      //           screenData.istransport = value;
                      //         });
                      //       },
                      //       activeTrackColor: Colors.lightGreenAccent,
                      //       activeColor: Colors.green,
                      //     ),
                      //     Text(global.language("is_use_transport")),
                      //   ],
                      // ),
                      // const SizedBox(
                      //   height: 10,
                      // ),
                      // (screenData.istransport!)
                      //     ? Container(
                      //         padding: const EdgeInsets.only(left: 20, right: 20),
                      //         child: Row(
                      //           mainAxisAlignment: MainAxisAlignment.start,
                      //           children: [
                      //             Expanded(
                      //               child: TextField(
                      //                 readOnly: true,
                      //                 textAlign: TextAlign.left,
                      //                 controller: TextEditingController(text: screenData.transportcode!),
                      //                 decoration: InputDecoration(
                      //                   floatingLabelBehavior: FloatingLabelBehavior.always,
                      //                   border: const OutlineInputBorder(),
                      //                   labelText: global.language("transportchannel_code"),
                      //                   suffixIcon: Row(
                      //                     mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                      //                     mainAxisSize: MainAxisSize.min,
                      //                     children: [
                      //                       IconButton(
                      //                         focusNode: FocusNode(skipTraversal: true),
                      //                         icon: const Icon(Icons.search),
                      //                         onPressed: () {
                      //                           searchTransport(word: "");
                      //                         },
                      //                       ),
                      //                     ],
                      //                   ),
                      //                 ),
                      //               ),
                      //             ),
                      //             const SizedBox(width: 5),
                      //             Expanded(
                      //               ///transportamount  input number only and format number
                      //               child: TextField(
                      //                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      //                 inputFormatters: [global.NumberInputFormatter()],
                      //                 textAlign: TextAlign.left,
                      //                 controller: transportAmountController,
                      //                 decoration: InputDecoration(
                      //                   floatingLabelBehavior: FloatingLabelBehavior.always,
                      //                   border: const OutlineInputBorder(),
                      //                   labelText: global.language("transportchannel_amount"),
                      //                 ),
                      //                 onChanged: (value) {
                      //                   /// check value null
                      //                   if (value.isEmpty) {
                      //                     screenData.transportamount = 0.00;
                      //                   } else {
                      //                     screenData.transportamount = double.parse(value.replaceAll(',', ''));
                      //                   }
                      //                 },
                      //               ),
                      //             ),
                      //           ],
                      //         ),
                      //       )
                      //     : Container(),
                    ],
                  )
                : Container(),
            const SizedBox(
              height: 20,
            ),

            (screenData.cancelreason!.isNotEmpty)
                ? Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        "***เหตุผลในการยกเลิก : ${screenData.cancelreason!}***",
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 30,
                        ),
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}

// Helper function for backward compatibility
Widget editDocumentWidget({
  required TransactionModel screenData,
  required global.TransactionTypeEnum transactionType,
  required Function(void Function()) setState,
  required BuildContext context,
  required TextEditingController custCodeController,
  required TextEditingController custnamesController,
  required TextEditingController saleCodeController,
  required TextEditingController saleNameController,
  required TextEditingController docRefNumberController,
  required TextEditingController taxDocNoController,
  required TextEditingController vatRateController,
  required TextEditingController descriptionController,
  required TextEditingController transportAmountController,
  required TextEditingController docDateController,
  required TextEditingController docTimeController,
  required bool docDateTimeValidated,
  required global.Debouncer debouncer,
  required Function() calTotalValue,
  required Function() headerTableDetail,
  required Function({required String word}) searchCustomer,
  required Function({required String word}) searchSupplier,
  required Function({required String word}) searchSale,
  required Function({required String word}) searchSaleChannel,
}) {
  return DocumentHeaderWidget(
    screenData: screenData,
    transactionType: transactionType,
    setState: setState,
    context: context,
    custCodeController: custCodeController,
    custnamesController: custnamesController,
    saleCodeController: saleCodeController,
    saleNameController: saleNameController,
    docRefNumberController: docRefNumberController,
    taxDocNoController: taxDocNoController,
    vatRateController: vatRateController,
    descriptionController: descriptionController,
    transportAmountController: transportAmountController,
    docDateController: docDateController,
    docTimeController: docTimeController,
    docDateTimeValidated: docDateTimeValidated,
    debouncer: debouncer,
    calTotalValue: calTotalValue,
    headerTableDetail: headerTableDetail,
    searchCustomer: searchCustomer,
    searchSupplier: searchSupplier,
    searchSale: searchSale,
    searchSaleChannel: searchSaleChannel,
  );
}
