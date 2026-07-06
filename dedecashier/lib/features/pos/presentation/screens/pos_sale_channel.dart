import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;

class PosSaleChannelScreen extends StatefulWidget {
  const PosSaleChannelScreen({super.key});

  @override
  State<PosSaleChannelScreen> createState() => _PosSaleChannelScreenState();
}

class _PosSaleChannelScreenState extends State<PosSaleChannelScreen> {
  @override
  Widget build(BuildContext context) {
    List<Widget> list = [];
    for (int index = 0; index < global.posSaleChannelList.length; index++) {
      list.add(
        Container(
          padding: const EdgeInsets.all(5),
          height: 150,
          width: 150,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              global.posSaleChannelCode = global.posSaleChannelList[index].code;
              global.posSaleChannelLogoUrl = global.posSaleChannelList[index].logoUrl;
              Navigator.pop(context);
            },
            child: (global.posSaleChannelList[index].logoUrl.isEmpty)
                ? Center(child: Text(global.posSaleChannelList[index].name))
                : Column(children: [
                    (global.posSaleChannelList[index].logoUrl.isEmpty) ? Container() : Expanded(child: Image.network(global.posSaleChannelList[index].logoUrl)),
                    Center(child: Text(global.posSaleChannelList[index].name)),
                  ]),
          ),
        ),
      );
    }
    return Scaffold(
        backgroundColor: Colors.grey[400],
        appBar: AppBar(
          title: Text(global.language("sale_channel")),
        ),
        body: Wrap(
          children: list,
        ));
  }
}
