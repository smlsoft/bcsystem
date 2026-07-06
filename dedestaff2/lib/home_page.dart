import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:ui';
import 'package:animated_icon/animated_icon.dart';
import 'package:dedeorder/global_model.dart';
import 'package:dedeorder/order/order_cancel_page.dart';
import 'package:dedeorder/order/order_page.dart';
import 'package:dedeorder/paytypeconfig.dart';
import 'package:dedeorder/product_update_status.dart';
import 'package:dedeorder/table/table_manager_page.dart';
import 'package:dedeorder/utility/caller_page.dart';
import 'package:dedeorder/utility/checker_page.dart';
import 'package:dedeorder/utility/connect_terminal.dart';
import 'package:dedeorder/utility/printer_config_select_printer.dart';
import 'package:flutter/material.dart';
import 'package:dedeorder/global.dart' as global;
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool getDeviceSuccess = false;
  late Timer timer;
  late Timer timerNetwork;
  bool oldPosTerminalDeviceConnected = false;

  @override
  void initState() {
    super.initState();
    global.getDevice().then((value) {
      global.loadDataFromTerminal();
      setState(() {
        getDeviceSuccess = true;
      });
    });
    timer = Timer.periodic(const Duration(seconds: 30), (Timer t) async {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      var printer = sharedPreferences.getString("printer");
      if (printer != null) {
        var json = await jsonDecode(printer);
        global.printerConnectData = PrinterLocalStrongDataModel.fromJson(json);
        global.printerConnected = true;
        setState(() {});
      }
    });
    timerNetwork = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      if (global.posTerminalDeviceConnected != oldPosTerminalDeviceConnected) {
        oldPosTerminalDeviceConnected = global.posTerminalDeviceConnected;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    timerNetwork.cancel();
    super.dispose();
  }

  Widget menuElevatedButton({required List<String> labels, required IconData icon, required Color color, required bool openOrderPage, required bool openOpenCancelPage, required global.TableManagerEnum tableManagerMode}) {
    double elevatedButtonBorderRadiusCircular = 10;
    double elevatedButtonPadding = 5;
    double elevatedButtonIconSize = 50;

    return ElevatedButton(
      onPressed: (global.posTerminalDeviceConnected == false)
          ? null
          : () async {
              if (tableManagerMode == global.TableManagerEnum.caller) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CallerPage()),
                );
              } else {
                if (tableManagerMode == global.TableManagerEnum.checker) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CheckerPage()),
                  );
                } else if (tableManagerMode == global.TableManagerEnum.payScreenType) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PayTypeConfig()),
                  );
                } else {
                  if (tableManagerMode == global.TableManagerEnum.productUpdateStatus || tableManagerMode == global.TableManagerEnum.productUpdateQty) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ProductUpdateStatusPage(
                                updateMode: (tableManagerMode == global.TableManagerEnum.productUpdateStatus) ? 0 : 1,
                              )),
                    );
                    setState(() {});
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TableManagerPage(
                                tableManagerMode: tableManagerMode,
                                sourceTableNumber: "",
                                isOpenOrder: openOrderPage,
                                isCancelOrder: openOpenCancelPage,
                              )),
                    );
                    /*if (result != null && result[0].isNotEmpty) {
                      global.getDevice().then((_) async {
                        global.selectTableNumber = result[0];
                        global.selectTable = result[1];
                        global.selectTableMainNumber =
                            global.selectTableNumber.split("#")[0];
                        if (mounted) {
                          if (openOrderPage) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const OrderPage()),
                            );
                          } else if (openOpenCancelPage) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const OrderCancelPage()),
                            );
                          }
                          setState(() {});
                        }
                      });
                    }*/
                  }
                }
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.only(left: elevatedButtonPadding, right: elevatedButtonPadding, top: elevatedButtonPadding * 2, bottom: elevatedButtonPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(elevatedButtonBorderRadiusCircular),
        ),
        side: BorderSide(
          color: Colors.grey, // สีของกรอบ (สีขาว)
          width: 1, // ความกว้างของกรอบ
        ),
      ),
      child: FittedBox(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Positioned(
                top: 3, // ตำแหน่งเงาด้านบน
                left: 3, // ตำแหน่งเงาด้านซ้าย
                child: Icon(
                  icon,
                  color: Colors.black.withOpacity(0.25),
                  size: elevatedButtonIconSize,
                ),
              ),
              Icon(
                icon,
                color: Colors.white, // สีของไอคอน
                size: elevatedButtonIconSize,
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          for (var label in labels)
            Text(
              label,
              style: const TextStyle(
                fontSize: 18.0,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1), // ระยะเงา
                    blurRadius: 3.0, // ความฟุ้งของเงา
                    color: Colors.black, // สีของเงา
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> menuOrderList = [
      menuElevatedButton(
          labels: ["สั่งอาหาร/เครื่องดื่ม"],
          icon: Icons.restaurant_menu,
          color: Colors.green.shade800, // สีเขียวเข้มสำหรับการสั่งอาหาร
          openOpenCancelPage: false,
          openOrderPage: true,
          tableManagerMode: global.TableManagerEnum.selectTable),
      menuElevatedButton(
          labels: ["ยกเลิกรายการที่สั่ง"],
          icon: Icons.cancel,
          color: Colors.red.shade800, // สีแดงเข้มสำหรับยกเลิกรายการที่สั่ง
          openOpenCancelPage: true,
          openOrderPage: false,
          tableManagerMode: global.TableManagerEnum.selectTable),
    ];
    List<Widget> menuTableList = [
      menuElevatedButton(
          labels: ["เปิดโต๊ะ"],
          icon: Icons.event_seat,
          color: Colors.blue.shade900, // สีฟ้าเข้มสำหรับเปิดโต๊ะ
          openOpenCancelPage: false,
          openOrderPage: false,
          tableManagerMode: global.TableManagerEnum.openTable),
      menuElevatedButton(
          labels: ["ปิดโต๊ะ"],
          icon: Icons.remove_circle,
          color: Colors.purple.shade900, // สีม่วงเข้มสำหรับปิดโต๊ะ
          openOpenCancelPage: false,
          openOrderPage: false,
          tableManagerMode: global.TableManagerEnum.closeTable),
      /*menuElevatedButton(
          labels: ["ย้ายโต๊ะ"],
          icon: Icons.move_to_inbox,
          color: Colors.purple.shade600,
          openOpenCancelPage: false,
          openOrderPage: false,
          tableManagerMode: global.TableManagerEnum.moveTable),
      menuElevatedButton(
          labels: ["แยกโต๊ะ"],
          icon: Icons.group_remove,
          color: Colors.orange.shade600,
          openOpenCancelPage: false,
          openOrderPage: false,
          tableManagerMode: global.TableManagerEnum.splitTable),
      menuElevatedButton(
          labels: ["รวมโต๊ะ"],
          icon: Icons.group_add,
          color: Colors.purple.shade600,
          openOpenCancelPage: false,
          openOrderPage: false,
          tableManagerMode: global.TableManagerEnum.mergeTable),*/
      menuElevatedButton(
          labels: ["ยกเลิกปิดโต๊ะ"],
          icon: Icons.undo,
          color: Colors.orange.shade900, // สีส้มเข้มสำหรับยกเลิกปิดโต๊ะ
          openOpenCancelPage: false,
          openOrderPage: false,
          tableManagerMode: global.TableManagerEnum.closeTableCancel),
      menuElevatedButton(
          labels: ["แก้ไขโต๊ะ"],
          icon: Icons.edit,
          color: Colors.teal.shade800, // สีเขียวอมฟ้าเข้มสำหรับแก้ไขโต๊ะ
          openOpenCancelPage: false,
          openOrderPage: false,
          tableManagerMode: global.TableManagerEnum.updateTable),
      menuElevatedButton(
          labels: ["รายละเอียดโต๊ะ"],
          icon: Icons.info_outline,
          color: Colors.pink.shade800, // สีชมพูเข้มสำหรับรายละเอียดโต๊ะ
          openOpenCancelPage: false,
          openOrderPage: false,
          tableManagerMode: global.TableManagerEnum.informationTable),
    ];
    List<Widget> menuUtilityList = [
      menuElevatedButton(
          labels: ["ปรับปรุงสถานะ", "อาหาร/เครื่องดื่ม"],
          icon: Icons.update,
          color: Colors.yellow.shade900, // สีเหลืองเข้มสำหรับปรับปรุงสถานะ
          openOpenCancelPage: false,
          openOrderPage: false,
          tableManagerMode: global.TableManagerEnum.productUpdateStatus),
      menuElevatedButton(
          labels: ["ปรับปรุงจำนวน", "อาหาร/เครื่องดื่ม"],
          icon: Icons.exposure,
          color: Colors.cyan.shade900, // สีฟ้าสดเข้มสำหรับปรับปรุงจำนวน
          openOpenCancelPage: false,
          openOrderPage: false,
          tableManagerMode: global.TableManagerEnum.productUpdateQty),
      menuElevatedButton(
          labels: ["Checker"],
          icon: Icons.check_circle,
          color: Colors.deepPurple.shade900, // สีม่วงเข้มสำหรับ Checker
          openOpenCancelPage: false,
          openOrderPage: false,
          tableManagerMode: global.TableManagerEnum.checker),
      menuElevatedButton(
          labels: ["Caller"],
          icon: Icons.phone_in_talk,
          color: Colors.lime.shade900, // สีเขียวมะนาวเข้มสำหรับ Caller
          openOpenCancelPage: false,
          openOrderPage: false,
          tableManagerMode: global.TableManagerEnum.caller),
      menuElevatedButton(
          labels: ["ตั้งค่า", "การชำระเงิน"],
          icon: Icons.payment,
          color: Colors.teal.shade900, // สีเขียวเข้มสำหรับตั้งค่าการชำระเงิน
          openOpenCancelPage: false,
          openOrderPage: false,
          tableManagerMode: global.TableManagerEnum.payScreenType),
    ];

    return (getDeviceSuccess == false)
        ? Container()
        : (global.staffCode.isEmpty)
            ? SafeArea(
                child: Scaffold(
                  body: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade200, Colors.blue.shade100],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          color: Colors.indigo.shade600,
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              "DEDE Order v.${global.appVersion}",
                              style: TextStyle(
                                fontSize: 32,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            width: 320,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                (global.posTerminalDeviceConnected)
                                    ? Column(
                                        children: [
                                          const Text(
                                            "เชื่อมกับเครื่อง Cashier สำเร็จแล้ว",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.teal,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.teal,
                                                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                              onPressed: () {
                                                Navigator.pushNamedAndRemoveUntil(
                                                  context,
                                                  '/staff',
                                                  (route) => false,
                                                );
                                              },
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: const [
                                                  Icon(Icons.people, color: Colors.white),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    "เลือกพนักงาน",
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          const Text(
                                            "กำลังเชื่อมต่อกับเครื่อง Cashier",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.indigo,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          const SizedBox(
                                            width: 80,
                                            height: 80,
                                            child: CircularProgressIndicator(
                                              color: Colors.teal,
                                              strokeWidth: 6,
                                            ),
                                          ),
                                        ],
                                      ),
                                const SizedBox(height: 80),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade600,
                                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ConnectTerminalPage(),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.refresh, color: Colors.white),
                                        SizedBox(width: 10),
                                        Text(
                                          "เชื่อมกับเครื่อง Cashier ใหม่",
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  title: Text('ลูกค้านั่งในร้าน (${global.staffCode}/${global.staffName}) '),
                  backgroundColor: Colors.deepPurple.shade900,
                  actions: [
                    IconButton(
                      icon: Icon((global.callerAlert == true) ? Icons.alarm_on : Icons.alarm_off),
                      tooltip: 'Alert',
                      onPressed: () {
                        setState(() {
                          global.callerAlert = !global.callerAlert;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.people),
                      tooltip: 'Staff',
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/staff', (route) => false);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delivery_dining),
                      tooltip: 'Delivery',
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(context, '/delivery', (route) => false);
                      },
                    ),
                    if (global.printerConnected)
                      IconButton(
                        icon: Icon((global.printToLocalPrinter == true) ? Icons.print : Icons.print_disabled),
                        tooltip: 'Print',
                        onPressed: () {
                          setState(() {
                            global.printToLocalPrinter = !global.printToLocalPrinter;
                          });
                        },
                      ),
                    PopupMenuButton<int>(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 1, child: Text("Connect to POS Terminal")),
                        const PopupMenuItem(value: 2, child: Text("Connect Printer")),
                      ],
                      onSelected: (value) async {
                        switch (value) {
                          case 1:
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ConnectTerminalPage()),
                            );
                            break;
                          case 2:
                            if (mounted) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const PrinterConfigSelectPrinterScreen(
                                          printerCode: "",
                                          printerName: "",
                                        )),
                              );
                            }
                            break;
                        }
                      },
                      offset: Offset(0, AppBar().preferredSize.height),
                      color: Colors.white,
                      elevation: 2,
                    ),
                  ],
                ),
                body: (global.posTerminalDeviceName.isEmpty)
                    ? Center(
                        child: ElevatedButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ConnectTerminalPage()),
                              );
                            },
                            child: const Text("ต้องเชื่อมต่อกับ POS Terminal ก่อน")),
                      )
                    : OrientationBuilder(builder: (context, orientation) {
                        return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                          double childAspectRatio = 2.5;
                          int crossAxisCount = (constraints.maxWidth < 600)
                              ? 2
                              : (constraints.maxWidth < 900)
                                  ? 3
                                  : 4;
                          return ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context).copyWith(
                                dragDevices: {
                                  PointerDeviceKind.touch,
                                  PointerDeviceKind.mouse,
                                },
                              ),
                              child: SingleChildScrollView(
                                  child: Column(children: [
                                Container(
                                  margin: const EdgeInsets.all(10),
                                  child: GridView.count(
                                      childAspectRatio: childAspectRatio, padding: EdgeInsets.zero, crossAxisCount: crossAxisCount, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, shrinkWrap: true, children: menuOrderList),
                                ),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                  ),
                                  child: const SizedBox(
                                    height: 2,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.all(10),
                                  child: GridView.count(
                                      childAspectRatio: childAspectRatio, padding: EdgeInsets.zero, crossAxisCount: crossAxisCount, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, shrinkWrap: true, children: menuTableList),
                                ),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                  ),
                                  child: const SizedBox(
                                    height: 2,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.all(10),
                                  child: GridView.count(
                                      childAspectRatio: childAspectRatio, padding: EdgeInsets.zero, crossAxisCount: crossAxisCount, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, shrinkWrap: true, children: menuUtilityList),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text("${global.posTerminalDeviceName} : ${global.posTerminalDeviceIpAddress} : ${global.posTerminalDevicePort}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    )),
                                SizedBox(
                                  height: 10,
                                ),
                                Text(global.machineId,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    )),
                                Text("version.${global.appVersion}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    )),
                              ])));
                        });
                      }),
              );
  }
}
