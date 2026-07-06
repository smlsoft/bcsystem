import 'dart:math';

import 'package:dedeorder/bloc/staff_bloc.dart';
import 'package:dedeorder/model/global_model.dart';
import 'package:flutter/material.dart';
import 'package:dedeorder/global.dart' as global;
import 'package:flutter_bloc/flutter_bloc.dart';

class StaffSelectPage extends StatefulWidget {
  const StaffSelectPage({super.key});

  @override
  State<StaffSelectPage> createState() => _StaffSelectPageState();
}

class _StaffSelectPageState extends State<StaffSelectPage> {
  List<StaffModel> staffList = [];

  @override
  void initState() {
    super.initState();
    context.read<StaffBloc>().add(StaffGetData());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StaffBloc, StaffState>(
      listener: (context, state) {
        if (state is StaffGetDataSuccess) {
          context.read<StaffBloc>().add(StaffGetDataFinish());
          setState(() {
            staffList = state.result;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.person, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'เลือกพนักงาน',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(4),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              double spaceWidth = 4.0;
              double maxWidth = constraints.maxWidth;
              int calcCount = (maxWidth / 150).floor();
              double widgetWidth =
                  (maxWidth - (calcCount * spaceWidth)) / calcCount;

              return Wrap(
                spacing: spaceWidth,
                runSpacing: spaceWidth,
                children: List.generate(staffList.length, (index) {
                  final staff = staffList[index];
                  return SizedBox(
                    width: widgetWidth,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.cyan[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(spaceWidth),
                        ),
                      ),
                      onPressed: () {
                        global.staffCode = staff.code;
                        global.staffName = staff.name;
                        global.speak(
                            "เข้าสู่ระบบด้วยรหัสพนักงานรหัส ${staff.code} ชื่อพนักงาน ${staff.name}");
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/home', (route) => false);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 8.0, bottom: 0, left: 0, right: 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "รหัส : ${staff.code}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "ชื่อ : ${staff.name}",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}
