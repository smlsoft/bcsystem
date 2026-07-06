import 'package:dedeorder/bloc/table_bloc.dart';
import 'package:dedeorder/model/table_model.dart';
import 'package:dedeorder/table/table_manager_close_page.dart';
import 'package:dedeorder/table/table_manager_info_page.dart';
import 'package:dedeorder/table/table_manager_splite_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slider_captcha/slider_captcha.dart';
import 'package:dedeorder/global.dart' as global;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:dedeorder/utility/api.dart' as api;
import 'package:dedeorder/utility/printer.dart' as printer;

class TableManagerPage extends StatefulWidget {
  final global.TableManagerEnum tableManagerMode;
  final String sourceTableNumber;
  final bool isOpenOrder;
  final bool isCancelOrder;

  const TableManagerPage({Key? key, required this.isOpenOrder, required this.isCancelOrder, required this.tableManagerMode, required this.sourceTableNumber}) : super(key: key);

  @override
  _TableManagerPageState createState() => _TableManagerPageState();
}

class _TableManagerPageState extends State<TableManagerPage> {
  List<String> zoneList = [];
  List<TableProcessObjectBoxStruct> tableList = [];
  int manCount = 0;
  int womanCount = 0;
  int childCount = 0;
  SliderController sliderController = SliderController();

  @override
  void initState() {
    super.initState();
    reloadData();
  }

  void reloadData() {
    context.read<TableBloc>().add(TableGetData());
  }

  Widget peopleCount(String label, int count, Function(int) callBack) {
    return Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 5),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                onPressed: () {
                  if (count > 0) {
                    setState(() {
                      count--;
                      callBack(count);
                    });
                  }
                },
                child: const Icon(
                  Icons.remove_rounded,
                )),
            SizedBox(width: 50, child: Center(child: Text(count.toString()))),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    count++;
                    callBack(count);
                  });
                },
                child: const Icon(Icons.add_rounded)),
          ])
        ]));
  }

  Widget peopleCountByIcon(Icon icon, int count, Function(int) callBack) {
    return Container(
        margin: const EdgeInsets.only(top: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 10; i++)
              InkWell(
                  onTap: () {
                    setState(() {
                      count = i + 1;
                      callBack(count);
                    });
                  },
                  child: Icon(icon.icon, color: i < count ? Colors.orange : Colors.grey))
          ],
        ));
  }

  Future<void> tableOpen(int tableIndex, bool clearData) async {
    if (tableList[tableIndex].customer_nationality_code.isEmpty) {
      tableList[tableIndex].customer_nationality_code = "th";
    }
    if (tableList[tableIndex].table_status == 0) {
      // เปิดโต๊ะใหม่
      tableList[tableIndex].table_al_la_crate_mode = (global.buffetModeLists.isEmpty) ? true : false;
    }
    if (clearData == false) {
      // ถามีการเปิดโต๊ะไปแล้ว แก้ไขจำนวนคน
      manCount = tableList[tableIndex].man_count;
      womanCount = tableList[tableIndex].woman_count;
      childCount = tableList[tableIndex].child_count;
    }
    await showDialog(
        context: context,
        builder: (context) {
          switch (tableList[tableIndex].table_status) {
            case 0:
              global.speak("เปิดโต๊ะ${tableList[tableIndex].number} โปรดระบุจำนวนลูกค้าโต๊ะ${tableList[tableIndex].number}");
              break;
            case 1:
              global.speak("แก้ไขจำนวนลูกค้าโต๊ะ${tableList[tableIndex].number}");
              break;
          }
          return AlertDialog(
            contentPadding: const EdgeInsets.all(10),
            insetPadding: const EdgeInsets.all(0),
            title: Center(child: Text("${(clearData) ? "เปิดโต๊ะ" : "แก้ไข"} : ${tableList[tableIndex].number}")),
            content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              bool okValid = manCount + womanCount + childCount > 0 ? true : false;
              if (okValid == true) {
                if (tableList[tableIndex].table_al_la_crate_mode == false && tableList[tableIndex].buffet_code.isEmpty) {
                  okValid = false;
                }
              }
              return SingleChildScrollView(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // เลือกภาษา ชาวต่างชาติ
                  Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(10),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          for (var i = 0; i < global.countryCodes.length; i++)
                            Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey, width: 1), // เพิ่มกรอบ
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3), // สีของเงา
                                    blurRadius: 8.0, // ความเบลอของเงา
                                    offset: const Offset(4, 4), // ตำแหน่งของเงา
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(2), // เพิ่มมุมโค้ง
                                color: (global.countryCodes[i] == tableList[tableIndex].customer_nationality_code) ? Colors.blue.shade400 : Colors.white, // สีพื้นหลังปุ่ม
                              ),
                              child: Material(
                                color: Colors.transparent, // ทำให้ background โปร่งใส
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(2), // เพิ่มมุมโค้งให้ปุ่ม
                                  onTap: () {
                                    setState(() {
                                      tableList[tableIndex].customer_nationality_code = global.countryCodes[i];
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Column(
                                      children: [
                                        Image.asset(
                                          'assets/flags/${global.countryCodes[i]}.png',
                                          width: 40,
                                          height: 30,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(global.countryNames[i], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )),
                  //
                  Center(
                    child: Text("ลูกค้า : ${global.countryNames[global.countryCodes.indexOf(tableList[tableIndex].customer_nationality_code)]}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                  //
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (tableList[tableIndex].table_al_la_crate_mode) ? Colors.blueAccent.shade700 : Colors.grey,
                      ),
                      onPressed: () {
                        if (tableList[tableIndex].table_status == 0) {
                          if (global.buffetModeLists.isNotEmpty) {
                            setState(() {
                              tableList[tableIndex].table_al_la_crate_mode = !tableList[tableIndex].table_al_la_crate_mode;
                              if (tableList[tableIndex].table_al_la_crate_mode) {
                                tableList[tableIndex].buffet_code = "";
                              }
                            });
                          }
                        }
                      },
                      child: Row(
                        children: [
                          const Text("อลาคาร์ท"),
                          const Spacer(),
                          (tableList[tableIndex].table_al_la_crate_mode) ? const Icon(Icons.check) : const Icon(Icons.cancel),
                        ],
                      )),
                  SizedBox(height: 10),
                  for (var buffet in global.buffetModeLists)
                    Container(
                        padding: const EdgeInsets.only(top: 5),
                        margin: const EdgeInsets.only(bottom: 5),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (tableList[tableIndex].buffet_code == buffet.code) ? Colors.blueAccent.shade700 : Colors.grey,
                            ),
                            onPressed: () {
                              if (tableList[tableIndex].table_status == 0) {
                                setState(() {
                                  tableList[tableIndex].buffet_code = buffet.code;
                                  tableList[tableIndex].table_al_la_crate_mode = false;
                                });
                              }
                            },
                            child: Row(children: [
                              Text(buffet.names[0]),
                              const Spacer(),
                              (tableList[tableIndex].buffet_code == buffet.code) ? const Icon(Icons.check) : const Icon(Icons.cancel),
                            ]))),
                  peopleCount(
                      "ผู้ชาย",
                      manCount,
                      (value) => {
                            setState(() {
                              manCount = value;
                            })
                          }),
                  peopleCount(
                      "ผู้หญิง",
                      womanCount,
                      (value) => {
                            setState(() {
                              womanCount = value;
                            })
                          }),
                  peopleCount(
                      "เด็ก",
                      childCount,
                      (value) => {
                            setState(() {
                              childCount = value;
                            })
                          }),
                  const SizedBox(height: 20),
                  peopleCountByIcon(
                      const Icon(Icons.man),
                      manCount,
                      (value) => {
                            setState(() {
                              manCount = value;
                            })
                          }),
                  peopleCountByIcon(
                      const Icon(Icons.woman),
                      womanCount,
                      (value) => {
                            setState(() {
                              womanCount = value;
                            })
                          }),
                  peopleCountByIcon(
                      const Icon(Icons.child_care),
                      childCount,
                      (value) => {
                            setState(() {
                              childCount = value;
                            })
                          }),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                          child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text(
                                "ยกเลิก",
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ))),
                      const SizedBox(
                        width: 3,
                      ),
                      Expanded(
                          child: ElevatedButton(
                              onPressed: (okValid)
                                  ? () {
                                      if (manCount + womanCount + childCount > 0) {
                                        // เปิดโต๊ให้ NumberMain = Number (โต๊ะหลัก)
                                        tableList[tableIndex].number_main = tableList[tableIndex].number;
                                        tableList[tableIndex].man_count = manCount;
                                        tableList[tableIndex].woman_count = womanCount;
                                        tableList[tableIndex].child_count = childCount;
                                        if (tableList[tableIndex].table_status == 0) {
                                          tableList[tableIndex].table_open_datetime = DateTime.now();
                                          tableList[tableIndex].qr_code = const Uuid().v4().replaceAll("-", "");
                                        }
                                        tableList[tableIndex].table_status = 1;
                                        tableList[tableIndex].make_food_immediately = true;

                                        if (!clearData) {
                                          tableList[tableIndex].isUpdate = true; // แก้ไขโต๊ะ
                                        } else {
                                          tableList[tableIndex].isUpdate = false; // เปิดโต๊ะใหม่
                                        }
                                        api.updateTableToTerminal(tableList[tableIndex]);
                                        if (global.printToLocalPrinter) {
                                          printer.printTableQrCode(
                                            table: tableList[tableIndex],
                                            qrCode: tableList[tableIndex].qr_code,
                                          );
                                        }
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text(
                                "ตกลง",
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ))),
                    ],
                  )
                ],
              ));
            }),
          );
        });
  }

  Future<void> tableMove(int tableIndex) async {
    bool confirm = false;

    var result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => TableManagerPage(
                tableManagerMode: global.TableManagerEnum.moveTableTarget,
                sourceTableNumber: tableList[tableIndex].number,
                isCancelOrder: false,
                isOpenOrder: false,
              )),
    );
    if (result != null) {
      String moveToTable = result[0];
      if (mounted) {
        await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("ยืนยันการย้ายโต๊ะจาก ${tableList[tableIndex].number} ไปยังโต๊ะ $moveToTable"),
                content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                  return SingleChildScrollView(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SliderCaptcha(
                        controller: sliderController,
                        image: Image.asset(
                          'assets/images/captcha.png',
                          fit: BoxFit.fitWidth,
                        ),
                        colorBar: Colors.blue,
                        colorCaptChar: Colors.blue,
                        onConfirm: (value) => Future.delayed(const Duration(seconds: 1)).then(
                          (_) {
                            if (value == false) {
                              sliderController.create();
                            } else {
                              setState(() {
                                confirm = true;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: const Text(
                                "ยกเลิก",
                                style: TextStyle(fontSize: 16),
                              )),
                          const Spacer(),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade500,
                              ),
                              onPressed: (confirm)
                                  ? () {
                                      api.moveTableToTerminal(tableList[tableIndex].number, moveToTable);
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    }
                                  : null,
                              child: const Text(
                                "ย้ายโต๊ะ",
                                style: TextStyle(fontSize: 16),
                              ))
                        ],
                      )
                    ],
                  ));
                }),
              );
            });
      }
    }
  }

  Future<void> tableMerge(int tableIndex) async {
    bool confirm = false;

    var result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => TableManagerPage(
                tableManagerMode: global.TableManagerEnum.mergeTableTarget,
                sourceTableNumber: tableList[tableIndex].number,
                isCancelOrder: false,
                isOpenOrder: false,
              )),
    );
    if (result != null) {
      String mergeSourceTableNumber = result[0];
      if (mounted) {
        await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("ยืนยันการรวมโต๊ะจาก ${tableList[tableIndex].number} ไปรวมกับโต๊ะ $mergeSourceTableNumber"),
                content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                  return SingleChildScrollView(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SliderCaptcha(
                        controller: sliderController,
                        image: Image.asset(
                          'assets/images/captcha.png',
                          fit: BoxFit.fitWidth,
                        ),
                        colorBar: Colors.blue,
                        colorCaptChar: Colors.blue,
                        onConfirm: (value) => Future.delayed(const Duration(seconds: 1)).then(
                          (_) {
                            if (value == false) {
                              sliderController.create();
                            } else {
                              setState(() {
                                confirm = true;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: const Text(
                                "ยกเลิก",
                                style: TextStyle(fontSize: 16),
                              )),
                          const Spacer(),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade500,
                              ),
                              onPressed: (confirm)
                                  ? () {
                                      api.mergeTableToTerminal(tableList[tableIndex].number, mergeSourceTableNumber);
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    }
                                  : null,
                              child: const Text(
                                "รวมโต๊ะ",
                                style: TextStyle(fontSize: 16),
                              ))
                        ],
                      )
                    ],
                  ));
                }),
              );
            });
      }
    }
  }

  Future<void> tableCloseCancel(int tableIndex) async {
    bool confirm = false;

    global.speak("ยกเลิกปิดโต๊ะ ${tableList[tableIndex].number}");
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("ยกเลิกปิดโต๊ะ ${tableList[tableIndex].number} เพื่อทำรายการต่อ"),
            content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderCaptcha(
                    controller: sliderController,
                    image: Image.asset(
                      'assets/images/captcha.png',
                      fit: BoxFit.fitWidth,
                    ),
                    colorBar: Colors.blue,
                    colorCaptChar: Colors.blue,
                    onConfirm: (value) => Future.delayed(const Duration(seconds: 1)).then(
                      (_) {
                        if (value == false) {
                          sliderController.create();
                        } else {
                          setState(() {
                            confirm = true;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "ยกเลิก",
                            style: TextStyle(fontSize: 16),
                          )),
                      const Spacer(),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade500,
                          ),
                          onPressed: (confirm)
                              ? () {
                                  tableList[tableIndex].table_status = 1;
                                  api.updateCancelCloseTableToTerminal(tableList[tableIndex]);
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                }
                              : null,
                          child: const Text(
                            "ยืนยัน",
                            style: TextStyle(fontSize: 16),
                          ))
                    ],
                  )
                ],
              ));
            }),
          );
        });
  }

  Widget table(String zone) {
    List<String> tableWhere = [];
    for (var table in tableList.where((element) => element.zone == zone)) {
      switch (widget.tableManagerMode) {
        case global.TableManagerEnum.openTable:
          if (table.table_status == 0 && table.table_child_count == 0 && table.number.contains("#") == false) {
            tableWhere.add(table.number);
          }
          break;
        case global.TableManagerEnum.updateTable:
          if (table.table_status == 1 && table.number.contains("#") == false) {
            tableWhere.add(table.number);
          }
          break;
        case global.TableManagerEnum.informationTable:
          if (table.table_status == 1 || table.table_status == 2) {
            tableWhere.add(table.number);
          }
          break;
        case global.TableManagerEnum.closeTable:
          if (table.table_status == 1) {
            tableWhere.add(table.number);
          }
          break;
        case global.TableManagerEnum.closeTableCancel:
          if (table.table_status == 2) {
            tableWhere.add(table.number);
          }
          break;
        case global.TableManagerEnum.selectTable:
          if (table.table_status == 1) {
            tableWhere.add(table.number);
          }
          break;
        case global.TableManagerEnum.moveTable:
          if (table.table_status == 1) {
            tableWhere.add(table.number);
          }
          break;
        case global.TableManagerEnum.moveTableTarget:
          if (table.table_status == 0) {
            tableWhere.add(table.number);
          }
          break;
        case global.TableManagerEnum.mergeTable:
          if (table.table_status == 1) {
            tableWhere.add(table.number);
          }
          break;
        case global.TableManagerEnum.mergeTableTarget:
          if (table.table_status == 1 && table.number != widget.sourceTableNumber && table.table_al_la_crate_mode == true) {
            tableWhere.add(table.number);
          }
          break;
        case global.TableManagerEnum.splitTable:
          if (table.table_status == 1 && !table.number.contains("#") && table.table_al_la_crate_mode == true) {
            tableWhere.add(table.number);
          }
          break;
        case global.TableManagerEnum.productUpdateQty:
          break;
        case global.TableManagerEnum.productUpdateStatus:
          break;
        case global.TableManagerEnum.checker:
          break;
        case global.TableManagerEnum.caller:
          break;
        case global.TableManagerEnum.payScreenType:
          break;
      }
    }
    return OrientationBuilder(builder: (context, orientation) {
      return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
        int calcWidth = (constraints.maxWidth / 180).round();
        double menuWidth = ((constraints.maxWidth) / calcWidth) - 10;
        return Container(
            padding: const EdgeInsets.all(8),
            child: Center(
                child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: List.generate(
                tableWhere.length,
                (index) {
                  Color color = Colors.green;
                  Widget tableStatus = Container();
                  int tableListIndex = tableList.indexWhere((element) => element.number == tableWhere[index]);
                  String tableStatusName = "";
                  switch (tableList[tableListIndex].table_status) {
                    case 0: // ว่าง
                      color = Colors.green.shade600;
                      tableStatusName = "ว่าง";
                      break;
                    case 1: // มีลูกค้า
                      color = Colors.red.shade600;
                      tableStatusName = "มีลูกค้า";
                      break;
                    case 2: // รอชำระเงิน
                      color = Colors.orange.shade600;
                      tableStatusName = "รอชำระเงิน";
                  }
                  Text tableNumber = Text("โต๊ะ ${tableWhere[index]} ($tableStatusName)",
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.grey,
                          offset: Offset(2.0, 2.0),
                        ),
                      ]));
                  if (tableList[tableListIndex].table_status != 0) {
                    int maxTimeMinute = 120;
                    Duration diff = tableList[tableListIndex].table_open_datetime.difference(DateTime.now());
                    String dateTimeDiff = "";
                    if (maxTimeMinute == 0) {
                      // สั่งแบบ อาราคัส
                      dateTimeDiff = "${diff.inMinutes % 60} นาที";
                      if (diff.inHours > 0) {
                        dateTimeDiff = "เวลา : ${diff.inHours} ชม. $dateTimeDiff";
                      }
                    } else {
                      // สั่งแบบ บุฟเฟ่ต์
                      DateTime endTime = tableList[tableListIndex].table_open_datetime.add(Duration(
                            minutes: maxTimeMinute,
                          ));
                      diff = endTime.difference(DateTime.now());
                      dateTimeDiff = "${diff.inMinutes % 60} นาที";
                      if (diff.inHours > 0) {
                        dateTimeDiff = "เหลือเวลา : ${diff.inHours} ชม. $dateTimeDiff";
                      }
                    }
                    String orderType = "";
                    if (tableList[tableListIndex].table_al_la_crate_mode) {
                      orderType = "อาราคัส";
                    } else {
                      int findBuffetIndex = global.findBuffetModeIndex(tableList[tableListIndex].buffet_code);
                      if (findBuffetIndex != -1) {
                        orderType = orderType = global.buffetModeLists[findBuffetIndex].names[0];
                      }
                    }
                    tableStatus = Column(children: [
                      tableNumber,
                      Text("รวมเงิน : ${global.moneyFormat.format(tableList[tableListIndex].amount.toDouble())} บาท", style: const TextStyle(color: Colors.white, fontSize: 12)),
                      Text((tableList[tableListIndex].order_count == 0) ? "ยังไม่มีการสั่ง" : "จำนวนการสั่ง : ${global.moneyFormat.format(tableList[tableListIndex].order_count.toDouble())}",
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                      if (tableList[tableListIndex].order_cancel_count != 0)
                        Text("จำนวนยกเลิก : ${global.moneyFormat.format(tableList[tableListIndex].order_cancel_count.toDouble())}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                      if (tableList[tableListIndex].order_served_count != 0)
                        Text("จำนวนเสิร์ฟ : ${global.moneyFormat.format(tableList[tableListIndex].order_served_count.toDouble())}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                      if (tableList[tableListIndex].order_served_count != 0 && tableList[tableListIndex].order_served_count < tableList[tableListIndex].order_count)
                        Text("ยังเสิร์ฟไม่ครบ", style: const TextStyle(color: Colors.white, fontSize: 18)),
                      if (tableList[tableListIndex].order_served_count != 0 && tableList[tableListIndex].order_served_count >= tableList[tableListIndex].order_count)
                        Text("เสิร์ฟครบ",
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 18,
                            )),
                      Text("ประเภท : $orderType", style: const TextStyle(color: Colors.white, fontSize: 12)),
                      if (tableList[tableListIndex].man_count != 0)
                        Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.man, color: Colors.white, size: 12),
                          SizedBox(width: 5),
                          Text("ผู้ชาย : ${global.moneyFormat.format(tableList[tableListIndex].man_count.toDouble())}", style: const TextStyle(color: Colors.white, fontSize: 12))
                        ]),
                      if (tableList[index].woman_count != 0)
                        Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.woman, color: Colors.white, size: 12),
                          SizedBox(width: 5),
                          Text("ผู้หญิง : ${global.moneyFormat.format(tableList[tableListIndex].woman_count.toDouble())}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ]),
                      if (tableList[tableListIndex].child_count != 0)
                        Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.child_care, color: Colors.white, size: 12),
                          SizedBox(width: 5),
                          Text("เด็ก : ${global.moneyFormat.format(tableList[tableListIndex].child_count.toDouble())}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ]),
                      Text("เวลาเปิดโต๊ะ : ${DateFormat('dd-HH:mm').format(tableList[tableListIndex].table_open_datetime)}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                      if (tableList[tableListIndex].table_al_la_crate_mode == false) Text(dateTimeDiff, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      if (tableList[tableListIndex].table_child_count != 0)
                        Text("จำนวนโต๊ะแยก : ${global.moneyFormat.format(tableList[tableListIndex].table_child_count)}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                      Container(
                          margin: const EdgeInsets.all(2),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey, width: 1), // เพิ่มกรอบ
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3), // สีของเงา
                                blurRadius: 8.0, // ความเบลอของเงา
                                offset: const Offset(4, 4), // ตำแหน่งของเงา
                              ),
                            ],
                            borderRadius: BorderRadius.circular(2), // เพิ่มมุมโค้ง
                            color: Colors.white, // สีพื้นหลังปุ่ม
                          ),
                          child: Image.asset(
                            'assets/flags/${tableList[tableListIndex].customer_nationality_code}.png',
                            width: 30,
                            height: 20,
                          )),
                    ]);
                  } else {
                    tableStatus = Center(child: tableNumber);
                  }
                  return Container(
                      width: menuWidth,
                      constraints: const BoxConstraints(minHeight: 100),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              backgroundColor: color,
                              padding: const EdgeInsets.all(10),
                              textStyle: const TextStyle(fontSize: 20)),
                          child: tableStatus,
                          onPressed: () async {
                            switch (widget.tableManagerMode) {
                              case global.TableManagerEnum.openTable:
                                await tableOpen(tableListIndex, true);
                                break;
                              case global.TableManagerEnum.updateTable:
                                await tableOpen(tableListIndex, false);
                                break;
                              case global.TableManagerEnum.closeTable:
                                await Navigator.push(context, MaterialPageRoute(builder: (context) => TableManagerClosePage(tableData: tableList[tableListIndex])));
                                break;
                              case global.TableManagerEnum.closeTableCancel:
                                await tableCloseCancel(tableListIndex);
                                break;
                              case global.TableManagerEnum.moveTable:
                                await tableMove(tableListIndex);
                                break;
                              case global.TableManagerEnum.moveTableTarget:
                                Navigator.pop(context, [tableList[tableListIndex].number]);
                                break;
                              case global.TableManagerEnum.mergeTable:
                                await tableMerge(tableListIndex);
                                break;
                              case global.TableManagerEnum.mergeTableTarget:
                                Navigator.pop(context, [tableList[tableListIndex].number]);
                                break;
                              case global.TableManagerEnum.splitTable:
                                await Navigator.push(context, MaterialPageRoute(builder: (context) => TableManagerSplitPage(tableProcess: tableList[tableListIndex])));
                                reloadData();
                                break;
                              case global.TableManagerEnum.informationTable:
                                await Navigator.push(context, MaterialPageRoute(builder: (context) => TableManagerInfoPage(tableData: tableList[tableListIndex])));
                                break;
                              case global.TableManagerEnum.selectTable:
                                global.selectTableNumber = tableList[tableListIndex].number;
                                global.selectTable = tableList[tableListIndex];
                                global.selectTableMainNumber = global.selectTableNumber.split("#")[0];
                                if (widget.isOpenOrder) {
                                  // สั่งอาหาร
                                  Navigator.pushNamedAndRemoveUntil(context, '/order', (route) => false);
                                }
                                if (widget.isCancelOrder) {
                                  // ยกเลิกอาหาร
                                  Navigator.pushNamedAndRemoveUntil(context, '/ordercancel', (route) => false);
                                }
                                break;
                              case global.TableManagerEnum.productUpdateStatus:
                                break;
                              case global.TableManagerEnum.productUpdateQty:
                                break;
                              case global.TableManagerEnum.checker:
                                break;
                              case global.TableManagerEnum.caller:
                                break;
                              case global.TableManagerEnum.payScreenType:
                                break;
                            }
                            setState(() {});
                          }));
                },
              ),
            )));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    late String title;
    switch (widget.tableManagerMode) {
      case global.TableManagerEnum.openTable:
        title = "table_open";
        break;
      case global.TableManagerEnum.updateTable:
        title = "table_update";
        break;
      case global.TableManagerEnum.closeTable:
        title = "table_close";
        break;
      case global.TableManagerEnum.closeTableCancel:
        title = "table_close_cancel";
        break;
      case global.TableManagerEnum.moveTable:
        title = "table_move";
        break;
      case global.TableManagerEnum.mergeTable:
        title = "table_merge";
        break;
      case global.TableManagerEnum.mergeTableTarget:
        title = "table_merge_to";
        break;
      case global.TableManagerEnum.splitTable:
        title = "table_split";
        break;
      case global.TableManagerEnum.informationTable:
        title = "table_information";
        break;
      case global.TableManagerEnum.selectTable:
        title = "table_select";
        break;
      case global.TableManagerEnum.moveTableTarget:
        title = "table_move_to";
        break;
      case global.TableManagerEnum.productUpdateStatus:
        title = "product_update_status";
        break;
      case global.TableManagerEnum.productUpdateQty:
        title = "product_update_qty";
        break;
      case global.TableManagerEnum.checker:
        title = "checker";
        break;
      case global.TableManagerEnum.caller:
        title = "caller";
        break;
      case global.TableManagerEnum.payScreenType:
        title = "pay_screen_type";
        break;
    }
    return BlocListener<TableBloc, TableState>(
        listener: (context, state) {
          if (state is TableGetDataSuccess) {
            for (var table in state.result) {
              if (table.zone.isEmpty) {
                table.zone = "X";
              }
              if (!zoneList.contains(table.zone) && table.zone != "") {
                zoneList.add(table.zone);
              }
            }
            tableList = state.result;
            setState(() {});
            context.read<TableBloc>().add(TableGetDataFinish());
          }
        },
        child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.deepPurple.shade900,
              title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
            ),
            body: SingleChildScrollView(
                child: Column(
              children: [
                for (var zone in zoneList)
                  Column(
                    children: [
                      if (zoneList.length > 1)
                        Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              border: Border.all(color: Colors.blue),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 1,
                                  blurRadius: 1,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              (zone == "X") ? "ไม่ระบุโซน" : "โซน : $zone",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )),
                      table(zone),
                    ],
                  ),
              ],
            ))));
  }
}
