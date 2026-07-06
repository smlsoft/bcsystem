import 'dart:convert';
import 'dart:ui';
import 'package:animated_icon/animated_icon.dart';
import 'package:dedeorder/order/order_utils.dart' as util;
import 'package:dedeorder/utility/api.dart' as api;
import 'package:dedeorder/bloc/order_temp_bloc.dart';
import 'package:dedeorder/model/order_temp_model.dart';
import 'package:dedeorder/model/product_model.dart';
import 'package:dedeorder/order/product_option_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedeorder/global.dart' as global;

class CartPage extends StatefulWidget {
  final String orderId;
  final String barcode;

  const CartPage({super.key, required this.barcode, required this.orderId});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  int categoryIndex = 0;
  List<ProductProcessModel> orderSelected = [];
  double orderQty = 0.0;
  double orderAmount = 0.0;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    context.read<OrderTempBloc>().add(OrderTempLoadStart(
        orderId: widget.orderId,
        barcode: widget.barcode,
        isOrder: true,
        machineId: global.machineId));
  }

  Widget sendAllOrderButton() {
    return Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
          ),
          onPressed: () async {
            await showDialog(
                context: context,
                builder: (BuildContext xcontext) {
                  return AlertDialog(
                      title: const Text("ส่งรายการทั้งหมด"),
                      content: const Text("ต้องการส่งรายการทั้งหมดหรือไม่?"),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("ยกเลิก")),
                        TextButton(
                            onPressed: () async {
                              String orderId =
                                  (global.selectTableNumber.isEmpty)
                                      ? global.phoneNumber
                                      : global.selectTableNumber;
                              await api.orderTempSendOrderByOrderId(
                                  tableNumber: orderId,
                                  machineId: global.machineId);
                              if (mounted) {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop(true);
                              }
                            },
                            child: const Text("ส่ง")),
                      ]);
                });
          },
          child: const Text('ส่งทั้งหมด'),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderTempBloc, OrderTempState>(
        listener: (context, state) {
          if (state is OrderTempLoadSuccess) {
            var result = util.getOrderSelect(
                context: context, orderTemp: state.orderTemp);
            orderAmount = result.orderAmount;
            orderQty = result.orderQty;
            orderSelected = result.orderSelected;
            orderSelected.sort((a, b) => a.barcode.compareTo(b.barcode));
            setState(() {});
          }
        },
        child: SafeArea(
          child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.deepPurple.shade900,
                title: const Text('รายการที่สั่ง'),
                actions: [
                  if (widget.barcode.isEmpty) sendAllOrderButton(),
                ],
              ),
              body: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                return ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      },
                    ),
                    child: SingleChildScrollView(
                        child: util.orderSummery(
                            context: context,
                            orderSelected: orderSelected,
                            orderAmount: orderAmount,
                            orderQty: orderQty,
                            widgetWidth: 0,
                            refresh: refresh)));
              })),
        ));
  }
}
