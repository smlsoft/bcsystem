import 'dart:async';

import 'package:dedeorder/bloc/caller_bloc.dart';
import 'package:dedeorder/global_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:dedeorder/utility/api.dart' as api;
import 'package:dedeorder/global.dart' as global;

class CallerPage extends StatefulWidget {
  const CallerPage({super.key});

  @override
  _CallerPageState createState() => _CallerPageState();
}

class _CallerPageState extends State<CallerPage> {
  late Timer timer;
  List<CallerModel> callerList = [];

  @override
  void initState() {
    super.initState();
    reloadData();
    timer = Timer.periodic(Duration(seconds: 5), (Timer t) => reloadData());
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void reloadData() {
    context.read<CallerBloc>().add(CallerGetData());
  }

  Widget callerBody(CallerModel caller) {
    DateTime callDateTime =
        DateTime.parse(caller.calldatetime.toString()).toLocal();
    // นับจากเวลา callDateTime ถึงปัจจุบัน แล้วแสดงเป็น นาที
    int calcMinute = DateTime.now().difference(callDateTime).inMinutes;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color:
            (caller.actionstatus == 0) ? Colors.white : Colors.green.shade100,
        border: Border.all(color: Colors.black),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        children: [
          Text("${DateFormat('HH:mm').format(callDateTime)} : $calcMinute นาที",
              style: TextStyle(fontSize: 24)),
          Spacer(),
          Text(caller.command, style: TextStyle(fontSize: 24)),
          Spacer(),
          (caller.actionstatus == 0)
              ? ElevatedButton(
                  onPressed: () async {
                    // update status
                    await api.clickHouseExecute(
                        "alter table dedetemp.caller update actionstatus=1 where shopid='${global.posInformation.shop_id}' and refguid='${caller.refguid}'");
                    reloadData();
                  },
                  child: Text('รับทราบ', style: TextStyle(fontSize: 24)))
              : Text('รับทราบแล้ว', style: TextStyle(fontSize: 24)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallerBloc, CallerState>(
        listener: (context, state) {
          if (state is CallerGetDataSuccess) {
            context.read<CallerBloc>().add(CallerGetDataFinish());
            setState(() {
              callerList = state.result;
            });
          }
        },
        child: Scaffold(
            appBar: AppBar(
              title: Text('Caller Page'),
            ),
            body: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              child: Column(
                children: callerList.map((e) => callerBody(e)).toList(),
              ),
            )));
  }
}
