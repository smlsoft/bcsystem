import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dedecashier/global.dart' as global;

class RoundMenu extends StatelessWidget {
  final String label;
  final Color fontColor;
  final int index;
  final int actived;
  final String img;
  final Function callBack;

  const RoundMenu({
    super.key,
    required this.label,
    required this.index,
    required this.actived,
    this.img = "setting.svg",
    required this.callBack,
    required this.fontColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () {
              callBack.call();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SvgPicture.asset(
                  'assets/icons/$img',
                  allowDrawingOutsideViewBox: true,
                ),
                Flexible(
                    child: Text(
                  label,
                  style: TextStyle(color: fontColor),
                ))
              ],
            ),
            /*        style: TextButton.styleFrom(
          backgroundColor: index == actived
              ? global.posTheme.secondary
              : global.posTheme.background,
        ),*/
          )),
    );
  }
}
