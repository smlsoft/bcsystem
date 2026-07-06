import 'dart:async';
import 'dart:ui';
import 'package:dedeorder/model/table_model.dart';
import 'package:dedeorder/utility/widget.dart' as widget;
import 'package:flutter/material.dart';
import 'package:dedeorder/global.dart' as global;
import 'package:slider_captcha/slider_captcha.dart';
import 'package:uuid/uuid.dart';
import 'package:dedeorder/utility/api.dart' as api;

class DeliveryTicketOpenPage extends StatefulWidget {
  const DeliveryTicketOpenPage({super.key});

  @override
  State<DeliveryTicketOpenPage> createState() => _DeliveryTicketOpenPageState();
}

class _DeliveryTicketOpenPageState extends State<DeliveryTicketOpenPage> {
  bool getDeviceSuccess = false;
  late Timer timer;
  int providerIndex = 0;
  bool makeImmediately = true;
  SliderController sliderController = SliderController();
  bool confirm = false;
  TextEditingController customerCodeOrTelephoneController =
      TextEditingController();
  TextEditingController customerNameController = TextEditingController();
  TextEditingController customerAddressController = TextEditingController();
  TextEditingController deliveryTicketNumberController =
      TextEditingController();
  TextEditingController remarkController = TextEditingController();
  int deliveryStatus = 0;

  @override
  void initState() {
    super.initState();
    global.getDevice().then((value) {
      setState(() {
        getDeviceSuccess = true;
      });
    });
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    timer.cancel();
    customerCodeOrTelephoneController.dispose();
    customerNameController.dispose();
    customerAddressController.dispose();
    deliveryTicketNumberController.dispose();
    remarkController.dispose();
    super.dispose();
  }

  Widget menuElevatedButton({
    required List<String> labels,
    required String route,
    required IconData icon,
    required Color color,
  }) {
    double elevatedButtonBorderRadiusCircular = 5;
    double elevatedButtonPadding = 5;
    double elevatedButtonIconSize = 50;

    return ElevatedButton(
      onPressed: () async {
        Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
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

  Future<void> createTicket() async {
    String guid = const Uuid().v4();
    TableProcessObjectBoxStruct ticket = TableProcessObjectBoxStruct(
      id: 0,
      guidfixed: guid,
      number: guid,
      number_main: "",
      names: "",
      zone: "",
      table_status: 0,
      table_child_count: 0,
      order_count: 0,
      order_cancel_count: 0,
      order_served_count: 0,
      amount: 0,
      order_success: false,
      qr_code: "",
      table_open_datetime: DateTime.now(),
      man_count: 0,
      woman_count: 0,
      child_count: 0,
      table_al_la_crate_mode: true,
      customer_code_or_telephone: customerCodeOrTelephoneController.text,
      customer_name: customerNameController.text,
      customer_address: customerAddressController.text,
      delivery_ticket_number: deliveryTicketNumberController.text,
      remark: remarkController.text,
      open_by_staff_code: "",
      delivery_code: global.posSaleChannelLists[providerIndex].code,
      delivery_number: "",
      buffet_code: "",
      make_food_immediately: makeImmediately,
      is_delivery: true,
      delivery_cook_success: false,
      delivery_cook_success_datetime: DateTime.now(),
      delivery_send_success: false,
      delivery_send_success_datetime: DateTime.now(),
      delivery_status: deliveryStatus,
      detail_discount_formula: "",
      customer_nationality_code: "th",
    );
    String result = await api.insertTicketToTerminal(ticket);
    if (result.isNotEmpty) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text('DEDE Staff : Delivery Ticket Open'),
            ),
            body: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: SingleChildScrollView(
                    child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Column(children: [
                          widget.posSaleChannelList(
                              selectedIndex: providerIndex,
                              onTab: (index) {
                                setState(() {
                                  providerIndex = index;
                                  deliveryStatus = (providerIndex == 0) ? 0 : 1;
                                });
                              }),
                          if (deliveryStatus == 0)
                            Container(
                                margin: const EdgeInsets.only(top: 10),
                                child: Column(children: [
                                  TextFormField(
                                    controller:
                                        customerCodeOrTelephoneController,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'รหัสลูกค้า/หมายเลขโทรศัพท์',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: customerNameController,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'ชื่อลูกค้า',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: customerAddressController,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      labelText: 'ที่อยู่ลูกค้า',
                                    ),
                                  ),
                                ])),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: deliveryTicketNumberController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Delivery Ticket No.',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: remarkController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'หมายเหตุ',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: makeImmediately
                                              ? Colors.green
                                              : Colors.grey),
                                      onPressed: () {
                                        setState(() {
                                          makeImmediately = true;
                                        });
                                      },
                                      child: (makeImmediately == true)
                                          ? const Row(children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              Text('ทำอาหารทันที')
                                            ])
                                          : const Text('ทำอาหารทันที'))),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: makeImmediately
                                              ? Colors.grey
                                              : Colors.green),
                                      onPressed: () {
                                        setState(() {
                                          makeImmediately = false;
                                        });
                                      },
                                      child: (makeImmediately == false)
                                          ? const Row(children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              SizedBox(
                                                width: 5,
                                              ),
                                              Text('ทำอาหารทีหลัง')
                                            ])
                                          : const Text('ทำอาหารทีหลัง'))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SliderCaptcha(
                            controller: sliderController,
                            image: Image.asset(
                              'assets/images/captcha.png',
                              fit: BoxFit.fitWidth,
                            ),
                            colorBar: Colors.blue,
                            colorCaptChar: Colors.blue,
                            onConfirm: (value) =>
                                Future.delayed(const Duration(seconds: 1)).then(
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
                              Expanded(
                                  child: ElevatedButton(
                                      onPressed: (confirm)
                                          ? () {
                                              createTicket();
                                            }
                                          : null,
                                      child: const Text('ยืนยันรายการ'))),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red),
                                      onPressed: () {
                                        Navigator.pushNamedAndRemoveUntil(
                                            context,
                                            '/delivery',
                                            (route) => false);
                                      },
                                      child: const Text('ยกเลิก'))),
                            ],
                          ),
                        ]))))));
  }
}
