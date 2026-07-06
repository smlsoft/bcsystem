import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoadingWidget extends StatelessWidget {
  final bool isLoading;

  const LoadingWidget({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingAnimationWidget.staggeredDotsWave(
                  color: kPrimaryColor,
                  size: 50,
                ),
                const SizedBox(height: 15),
                Text(
                  global.language('loading'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
