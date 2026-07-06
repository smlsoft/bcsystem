import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:flutter_svg/svg.dart';

class RoundPayMenu extends StatelessWidget {
  final String label;

  final Function()? onPressed;

  final int actived;
  final String img;
  const RoundPayMenu({
    super.key,
    required this.label,
    this.onPressed,
    required this.actived,
    this.img = "setting.svg",
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
                padding: const EdgeInsets.only(right: 10),
                width: 40,
                child: SvgPicture.asset(
                  'assets/icons/pay_screen/$img',
                  height: (size.height / 100) * 4,
                  allowDrawingOutsideViewBox: true,
                )),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            )
          ],
        ),
      ),
    );
  }
}
