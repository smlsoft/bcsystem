import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedeorder/bloc/delivery_ticket_bloc.dart';
import 'package:dedeorder/delivery/delivery_ticket_open_page.dart';
import 'package:dedeorder/order/order_cancel_page.dart';
import 'package:dedeorder/order/order_page.dart';
import 'package:dedeorder/product_update_status.dart';
import 'package:dedeorder/table/table_manager_info_page.dart';
import 'package:flutter/material.dart';
import 'package:dedeorder/global.dart' as global;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedeorder/utility/api.dart' as api;
import 'package:intl/intl.dart';
import 'package:slider_captcha/slider_captcha.dart';

import '../utility/connect_terminal.dart';

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});

  @override
  State<DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  bool getDeviceSuccess = false;
  late Timer timerRefresh;
  late Timer timerLoadData;
  List<Widget> ticketList = [];
  // 0=แสดงรายการปัจจุบัน, 1=แสดงรายการที่เสร็จแล้ว
  int displayTicketMode = 0;
  SliderController sliderController = SliderController();

  @override
  void initState() {
    super.initState();
    global.getDevice().then((value) {
      setState(() {
        getDeviceSuccess = true;
      });
    });
    timerRefresh = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      reloadData();
      setState(() {});
    });
    timerLoadData =
        Timer.periodic(const Duration(seconds: 10), (Timer t) async {
      global.loadDataFromTerminal();
    });
  }

  @override
  void dispose() {
    timerRefresh.cancel();
    timerLoadData.cancel();
    super.dispose();
  }

  Widget menuElevatedButton({
    required List<String> labels,
    required IconData icon,
    required Color color,
    required Function() onPressed,
  }) {
    double elevatedButtonBorderRadiusCircular = 5;
    double elevatedButtonPadding = 5;
    double elevatedButtonIconSize = 50;

    return ElevatedButton(
      onPressed: () {
        onPressed();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.only(
            left: elevatedButtonPadding,
            right: elevatedButtonPadding,
            top: elevatedButtonPadding * 2,
            bottom: elevatedButtonPadding * 2),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(elevatedButtonBorderRadiusCircular),
        ),
      ),
      child: FittedBox(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: elevatedButtonIconSize,
          ),
          const SizedBox(height: 10.0),
          for (var label in labels)
            Text(
              label,
              style: const TextStyle(
                fontSize: 15.0,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      )),
    );
  }

  void reloadData() {
    // displayTicketMode 0=แสดงรายการปัจจุบัน, 1=แสดงรายการที่เสร็จแล้ว
    context.read<DeliveryTicketBloc>().add(DeliveryTicketLoadData(
        sendSuccess: (displayTicketMode == 0) ? false : true));
  }

  @override
  Widget build(BuildContext context) {
    return (getDeviceSuccess == false)
        ? Container()
        : BlocListener<DeliveryTicketBloc, DeliveryTicketState>(
            listener: (context, state) {
              if (state is DeliveryTicketLoadSuccess) {
                ticketList = [];
                for (var ticket in state.result) {
                  Duration diffTime =
                      DateTime.now().difference(ticket.table_open_datetime);
                  String diffTimeString = "";
                  if (diffTime.inDays > 0) {
                    diffTimeString += "${diffTime.inDays} วัน ";
                    diffTime -= Duration(days: diffTime.inDays);
                  }
                  if (diffTime.inHours > 0) {
                    diffTimeString += "${diffTime.inHours} ชม. ";
                    diffTime -= Duration(hours: diffTime.inHours);
                  }
                  if (diffTime.inMinutes > 0) {
                    diffTimeString += "${diffTime.inMinutes} นาที";
                  }

                  ticketList.add(Container(
                      width: 200,
                      decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(5)),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(
                              global.getDeliveryName(
                                  code: ticket.delivery_code),
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            )),
                            CachedNetworkImage(
                              imageUrl: global.getDeliveryLogo(
                                  code: ticket.delivery_code),
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                height: 25.0,
                                width: 30.0,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                          ]),
                          const SizedBox(height: 4),
                          Text("หมายเลข Order : ${ticket.delivery_number}"),
                          Text(
                              "เวลารับ Order : ${DateFormat('dd-HH:mm').format(ticket.table_open_datetime)}"),
                          Text("รับ Order มาแล้ว : ${diffTimeString}"),
                          Text(
                              "จำนวนสินค้า : ${global.moneyFormat.format(ticket.order_count)} ชิ้น"),
                          Text(
                              "จำนวนเงิน : ${global.moneyFormat.format(ticket.amount)} บาท"),
                          const SizedBox(
                            height: 4,
                          ),
                          if (displayTicketMode == 0)
                            Row(
                              children: [
                                Expanded(
                                    child: ElevatedButton(
                                        onPressed: () async {
                                          global.selectTable = ticket;
                                          global.selectTableNumber =
                                              ticket.guidfixed;
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const OrderPage()),
                                          );
                                          reloadData();
                                        },
                                        child: const FittedBox(
                                            child: Text("เพิ่มรายการ")))),
                                const SizedBox(
                                  width: 4,
                                ),
                                ElevatedButton(
                                    onPressed: () async {
                                      global.selectTable = ticket;
                                      global.selectTableNumber =
                                          ticket.guidfixed;
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const OrderCancelPage()),
                                      );
                                      reloadData();
                                    },
                                    child: const FittedBox(
                                        child: Text("ยกเลิกรายการ"))),
                              ],
                            ),
                          const SizedBox(
                            height: 4,
                          ),
                          if (displayTicketMode == 0)
                            Text((ticket.make_food_immediately == true)
                                ? "ทำอาหารทันที"
                                : "รอทำอาหาร"),
                          if (ticket.make_food_immediately == false &&
                              displayTicketMode == 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: double.infinity,
                              child: ElevatedButton(
                                  onPressed: (ticket.order_count != 0)
                                      ? () async {
                                          await showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text("ยืนยัน"),
                                                  content: const Text(
                                                      "ต้องการเริ่มประกอบอาหารใช่หรือไม่"),
                                                  actions: [
                                                    ElevatedButton(
                                                        onPressed: () async {
                                                          await api
                                                              .setKdsStartCooking(
                                                                  ticket
                                                                      .delivery_number);
                                                          if (mounted) {
                                                            Navigator.pop(
                                                                context);
                                                          }
                                                          setState(() {
                                                            reloadData();
                                                          });
                                                        },
                                                        child:
                                                            const Text("ใช่")),
                                                    ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child: const Text(
                                                            "ไม่ใช่"))
                                                  ],
                                                );
                                              });
                                        }
                                      : null,
                                  child: const Text("เริ่มประกอบอาหาร")),
                            ),
                          if (ticket.remark.isNotEmpty)
                            Text("หมายเหตุ : ${ticket.remark}"),
                          if (ticket.delivery_ticket_number.isNotEmpty)
                            Text(
                                "เลขที่ใบสั่ง : ${ticket.delivery_ticket_number}"),
                          if (ticket.customer_code_or_telephone.isNotEmpty)
                            Text(
                                "รหัสลูกค้าหรือเบอร์โทรศัพท์ : ${ticket.customer_code_or_telephone}"),
                          if (ticket.customer_name.isNotEmpty)
                            Text("ชื่อลูกค้า : ${ticket.customer_name}"),
                          if (ticket.customer_address.isNotEmpty)
                            Text("ที่อยู่ลูกค้า : ${ticket.customer_address}"),
                          const SizedBox(
                            height: 4,
                          ),
                          if (displayTicketMode == 0)
                            Row(
                              children: [
                                Expanded(
                                    child: ElevatedButton(
                                        onPressed: (ticket.order_count != 0)
                                            ? () async {
                                                await showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                            "ยืนยัน"),
                                                        content: const Text(
                                                            "อารหารเสร็จแล้วใช่หรือไม่"),
                                                        actions: [
                                                          ElevatedButton(
                                                              onPressed:
                                                                  () async {
                                                                ticket.delivery_cook_success =
                                                                    true;
                                                                ticket.delivery_cook_success_datetime =
                                                                    DateTime
                                                                        .now();
                                                                await api
                                                                    .updateTableToTerminal(
                                                                        ticket);
                                                                if (mounted) {
                                                                  Navigator.pop(
                                                                      context);
                                                                }
                                                                setState(() {
                                                                  reloadData();
                                                                });
                                                              },
                                                              child: const Text(
                                                                  "ใช่")),
                                                          ElevatedButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child: const Text(
                                                                  "ไม่ใช่"))
                                                        ],
                                                      );
                                                    });
                                              }
                                            : null,
                                        child: const FittedBox(
                                            child: Text("อาหารเสร็จ")))),
                                const SizedBox(
                                  width: 4,
                                ),
                                ElevatedButton(
                                    onPressed: () async {
                                      bool confirmCloseJob = false;
                                      await showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return StatefulBuilder(
                                              builder: (context, setState) {
                                            return AlertDialog(
                                              title: const Text("ยืนยัน"),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SliderCaptcha(
                                                    controller:
                                                        sliderController,
                                                    image: Image.asset(
                                                      'assets/images/captcha.png',
                                                      fit: BoxFit.fitWidth,
                                                    ),
                                                    colorBar: Colors.blue,
                                                    colorCaptChar: Colors.blue,
                                                    onConfirm: (value) =>
                                                        Future.delayed(
                                                                const Duration(
                                                                    seconds: 1))
                                                            .then(
                                                      (_) {
                                                        if (value == false) {
                                                          sliderController
                                                              .create();
                                                        } else {
                                                          setState(() {
                                                            confirmCloseJob =
                                                                true;
                                                          });
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  const Text(
                                                      "ต้องการปิดงานใช่หรือไม่"),
                                                ],
                                              ),
                                              actions: [
                                                ElevatedButton(
                                                    onPressed: (confirmCloseJob)
                                                        ? () async {
                                                            if (ticket
                                                                    .delivery_status ==
                                                                0) {
                                                              // กรณีสั่งกลับบ้าน ให้รอคิดเงินที่ Cashier
                                                              ticket.table_status =
                                                                  2;
                                                            } else {
                                                              // กรณี Delivery ที่จ่ายเงินด้วยระบบ App แล้ว ให้ปิดงาน เพราะถือว่าระบบเก็บเงินไปแล้ว
                                                              ticket.table_status =
                                                                  3;
                                                            }
                                                            ticket.delivery_send_success =
                                                                true;
                                                            ticket.delivery_send_success_datetime =
                                                                DateTime.now();
                                                            await api
                                                                .updateTableToTerminal(
                                                                    ticket);
                                                            if (mounted) {
                                                              Navigator.pop(
                                                                  context);
                                                            }
                                                            setState(() {
                                                              reloadData();
                                                            });
                                                          }
                                                        : null,
                                                    child: const Text("ใช่")),
                                                ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text("ไม่ใช่"))
                                              ],
                                            );
                                          });
                                        },
                                      );
                                    },
                                    child:
                                        const FittedBox(child: Text("ปิดงาน"))),
                              ],
                            ),
                          const SizedBox(
                            height: 4,
                          ),
                          SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                  onPressed: (ticket.order_count != 0 ||
                                          displayTicketMode == 1)
                                      ? () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    TableManagerInfoPage(
                                                        tableData: ticket)),
                                          );
                                        }
                                      : null,
                                  child: const FittedBox(
                                      child: Text("รายละเอียด"))))
                        ],
                      )));
                }
                setState(() {});
                context
                    .read<DeliveryTicketBloc>()
                    .add(DeliveryTicketLoadDataFinish());
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    Icon(Icons.sync,
                        color: (global.posTerminalDeviceConnected)
                            ? Colors.green
                            : Colors.red),
                    SizedBox(
                      width: 4,
                    ),
                    Text('Delivery')
                  ],
                ),
                backgroundColor: (displayTicketMode == 0)
                    ? Colors.green.shade900
                    : Colors.orange.shade900,
                actions: [
                  if (displayTicketMode == 1)
                    IconButton(
                      icon: const Icon(Icons.delivery_dining),
                      tooltip: 'Delivery',
                      onPressed: () {
                        displayTicketMode = 0;
                        reloadData();
                      },
                    ),
                  if (displayTicketMode == 0)
                    IconButton(
                      icon: const Icon(Icons.table_bar),
                      tooltip: 'Home',
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/home', (route) => false);
                      },
                    ),
                  if (displayTicketMode == 0)
                    IconButton(
                      icon: const Icon(Icons.history),
                      tooltip: 'History',
                      onPressed: () {
                        displayTicketMode = 1;
                        reloadData();
                      },
                    ),
                  if (displayTicketMode == 0)
                    IconButton(
                      icon: const Icon(Icons.sync),
                      tooltip: 'Connect to POS Terminal',
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ConnectTerminalPage()),
                        );
                        setState(() {});
                      },
                    ),
                ],
              ),
              body: (global.posTerminalDeviceName.isEmpty)
                  ? Center(
                      child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ConnectTerminalPage()),
                            );
                            setState(() {});
                          },
                          child:
                              const Text("ต้องเชื่อมต่อกับ POS Terminal ก่อน")),
                    )
                  : OrientationBuilder(builder: (context, orientation) {
                      return LayoutBuilder(builder:
                          (BuildContext context, BoxConstraints constraints) {
                        double menuChildAspectRatio = 2;
                        int menuCrossAxisCount = (constraints.maxWidth < 600)
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
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Wrap(
                                        runSpacing: 4,
                                        spacing: 4,
                                        children: ticketList)),
                                Container(
                                  margin:
                                      const EdgeInsets.only(top: 5, bottom: 5),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                  ),
                                  child: const SizedBox(
                                    height: 4,
                                  ),
                                ),
                                if (displayTicketMode == 0)
                                  Container(
                                    margin: const EdgeInsets.all(10),
                                    child: GridView.count(
                                        childAspectRatio: menuChildAspectRatio,
                                        padding: EdgeInsets.zero,
                                        crossAxisCount: menuCrossAxisCount,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                        shrinkWrap: true,
                                        children: [
                                          menuElevatedButton(
                                            labels: ["เปิดคำสั่งซื้อ"],
                                            icon: Icons.add_rounded,
                                            color: Colors.green.shade500,
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const DeliveryTicketOpenPage()),
                                              );
                                              reloadData();
                                            },
                                          ),
                                          menuElevatedButton(
                                            labels: [
                                              "ปรับปรุงสถานะ",
                                              "อาหาร/เครื่องดื่ม"
                                            ],
                                            icon: Icons.refresh,
                                            color: Colors.indigo.shade600,
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const ProductUpdateStatusPage(
                                                            updateMode: 0)),
                                              );
                                            },
                                          ),
                                          menuElevatedButton(
                                            labels: [
                                              "ปรับปรุงจำนวน",
                                              "อาหาร/เครื่องดื่ม"
                                            ],
                                            icon: Icons.update,
                                            color: Colors.indigo.shade600,
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const ProductUpdateStatusPage(
                                                            updateMode: 0)),
                                              );
                                            },
                                          ),
                                        ]),
                                  )
                              ])),
                        );
                      });
                    }),
            ));
  }
}
