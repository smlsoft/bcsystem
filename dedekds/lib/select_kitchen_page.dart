import 'dart:async';
import 'package:dedekds/bloc/kitchen_bloc.dart';
import 'package:dedekds/model/kitchen_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedekds/scan_server_page.dart';
import 'package:flutter/material.dart';
import 'package:dedekds/global.dart' as global;
import 'package:dedekds/utility/util.dart' as util;

class SelectKitchenPage extends StatefulWidget {
  const SelectKitchenPage({super.key});

  @override
  State<SelectKitchenPage> createState() => _SelectKitchenPageState();
}

class _SelectKitchenPageState extends State<SelectKitchenPage> {
  List<KitchenObjectBoxStruct> kitchenList = [];
  @override
  void initState() {
    super.initState();
    BlocProvider.of<KitchenBloc>(context).add(KitchenGetData());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double menuMinWidth = 150;
    int widgetPerLine = int.parse(
        (MediaQuery.of(context).size.width / menuMinWidth).toStringAsFixed(0));

    return BlocListener<KitchenBloc, KitchenState>(
        listener: (context, state) {
          if (state is KitchenGetDataSuccess) {
            kitchenList = state.result;
            setState(() {});
          }
        },
        child: SafeArea(
            child: Scaffold(
                appBar: AppBar(
                  title: Text("เลือกห้องครั้วที่ต้องการเชื่อมต่อ"),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () async {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/scan_server', (route) => false);
                      },
                    ),
                  ],
                ),
                body: Container(
                  padding: EdgeInsets.all(10.0),
                  child: GridView.count(
                    childAspectRatio: 1,
                    padding: EdgeInsets.zero,
                    crossAxisCount: widgetPerLine,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                    shrinkWrap: true,
                    children: [
                      for (var item in kitchenList)
                        ElevatedButton(
                            onPressed: () async {
                              global.posKitchenId = item.code;
                              global.posKitchenName =
                                  global.getNameFromJsonLanguage(
                                      item.names, global.userLanguage);
                              await global.saveServerData();
                              if (mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                    context, '/home', (route) => false);
                              }
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.code,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.0,
                                  ),
                                ),
                                Text(
                                  global.getNameFromJsonLanguage(
                                      item.names, global.userLanguage),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.0,
                                  ),
                                ),
                              ],
                            )),
                    ],
                  ),
                ))));
  }
}
