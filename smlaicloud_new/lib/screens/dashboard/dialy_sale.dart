import 'package:smlaicloud/screens/dashboard/dashboard_border.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class DashBoardDailySale extends StatefulWidget {
  const DashBoardDailySale({super.key});

  @override
  _DashBoardDailySaleState createState() => _DashBoardDailySaleState();
}

class _DashBoardDailySaleState extends State<DashBoardDailySale> {
  @override
  Widget build(BuildContext context) {
    DateTime dateTimeNow = DateTime.now();

    //String formattedDate = DateFormat.yMMMMEEEEd('th_TH').format(dateTimeNow);
    var thaiBuddhist = new DateFormat('วันที่ dd MMMM yyyy', 'th_TH');
    String fullDate = thaiBuddhist.format(dateTimeNow);
    String dayOfWeek = DateFormat.EEEE('th_TH').format(dateTimeNow);
    String monthYear = DateFormat.yMMMM('th_TH').format(dateTimeNow);
    String year = DateFormat.y('th_TH').format(dateTimeNow);

    Widget dailyWidget = Container(
      child: Column(
        children: [
          Text('ยอดขาย' + ' ' + dayOfWeek + ' ' + fullDate),
          Expanded(
              child: Center(
                  child: Text(
            '10,000 บาท',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blue),
          ))),
        ],
      ),
    );
    return Container(
      child: Row(children: [
        Expanded(child: Container(height: 100, child: DashBoardBorder(childWidget: dailyWidget))),
        Expanded(
            child: Container(
          height: 100,
          child: DashBoardBorder(
            childWidget: Column(
              children: [
                Text('ยอดขายเดือน' + ' ' + monthYear),
                Expanded(
                    child: Center(
                        child: Text(
                  '10,000 บาท',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blue),
                ))),
              ],
            ),
          ),
        )),
        Expanded(
            child: Container(
          height: 100,
          child: DashBoardBorder(
            childWidget: Column(
              children: [
                Text('ยอดขายปี' + ' ' + year),
                Expanded(
                    child: Center(
                        child: Text(
                  '10,000 บาท',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blue),
                ))),
              ],
            ),
          ),
        )),
      ]),
    );
  }
}
