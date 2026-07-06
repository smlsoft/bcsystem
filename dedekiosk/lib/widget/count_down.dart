import 'package:flutter/material.dart';
import 'dart:async';

class CountdownTimerWidget extends StatefulWidget {
  final VoidCallback onCountdownComplete;
  final Duration duration;

  const CountdownTimerWidget({
    super.key,
    required this.onCountdownComplete,
    required this.duration,
  });

  @override
  CountdownTimerWidgetState createState() => CountdownTimerWidgetState();
}

class CountdownTimerWidgetState extends State<CountdownTimerWidget>
    with SingleTickerProviderStateMixin {
  late Timer timer;
  late AnimationController animationController;
  late int start;
  bool isPaused = false;

  void onStart() {
    setState(() {
      isPaused = false;
      animationController = AnimationController(
        vsync: this,
        duration: Duration(seconds: start),
      )..addListener(() {
          setState(() {});
        });
      animationController.forward();
    });

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (start > 0 && !isPaused) {
        setState(() {
          start--;
        });
      } else if (start == 0) {
        timer.cancel();
        widget.onCountdownComplete();
      }
    });
  }

  void onPause() {
    setState(() {
      isPaused = true;
      animationController.stop();
    });
  }

  void onResume() {
    setState(() {
      isPaused = false;
      animationController.forward();
    });
  }

  void onReset() {
    setState(() {
      isPaused = false;
      start = widget.duration.inSeconds;
      animationController.reset();
      animationController.duration = Duration(seconds: start);
      onStart();
    });
  }

  @override
  void initState() {
    super.initState();
    start = widget.duration.inSeconds;
    onStart(); // เริ่มต้นนับถอยหลังทันทีเมื่อเริ่มต้น
  }

  @override
  void dispose() {
    timer.cancel();
    animationController.dispose();
    super.dispose();
  }

  String get timerText {
    Duration duration = Duration(seconds: start);
    return '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: animationController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: animationController.value,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                Text(
                  timerText,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
