import 'package:dedecashier/features/shop/presentation/bloc/select_shop_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TopBarShop extends StatelessWidget {
  final double height;

  const TopBarShop({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    late String shopName;

    final selectShopState = context.select((SelectShopBloc bloc) => bloc.state);

    if (selectShopState is SelectShopSubmitSuccessState) {
      shopName = selectShopState.shop.name;
    } else {
      shopName = '';
    }

    return SizedBox(
      height: 200,
      child: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(200),
              bottomRight: Radius.circular(200),
            ),
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [Color(0xFF007BFF), Color.fromARGB(150, 0, 123, 255)],
            ),
          ),
        ),
        ClipPath(
          clipper: LandscapeTopBarDashboardClipper(),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF005CBF),
            ),
          ),
        ),
        SizedBox(
          height: 170,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Text(
              shopName,
              style: const TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class LandscapeTopBarDashboardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.1);
    path.quadraticBezierTo(size.width * 0.1, size.height * 1.5, size.width * 1.1, 0);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
