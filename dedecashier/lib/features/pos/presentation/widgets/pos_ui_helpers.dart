import 'package:flutter/material.dart';

/// Helper utilities สำหรับ POS Screen UI
/// แยกออกจาก pos_screen.dart เพื่อความเป็นระเบียบ
class PosUiHelpers {
  /// คำนวณขนาดฟอนต์แบบ dynamic ตาม listTextHeight
  static double getDynamicFontSize(double baseFontSize, double listTextHeight) {
    return baseFontSize * listTextHeight;
  }

  /// สร้างปุ่มแบบ compact พร้อม icon และ label
  static Widget buildCompactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required double Function(double) getDynamicFontSize,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 0,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.white,
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: color.withOpacity(0.9),
                      fontSize: getDynamicFontSize(12.0),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// สร้าง animated emoji widget (แบบ scale + rotation)
  static Widget buildAnimatedEmoji({
    required String emoji,
    required Animation<double> scaleAnimation,
    required AnimationController scaleController,
    double size = 18,
  }) {
    return ScaleTransition(
      scale: scaleAnimation,
      child: RotationTransition(
        turns: Tween<double>(begin: -0.05, end: 0.05).animate(scaleController),
        child: Text(emoji, style: TextStyle(fontSize: size)),
      ),
    );
  }

  /// สร้าง pulsing emoji widget (เต้นแบบหัวใจ)
  static Widget buildPulsingEmoji({
    required String emoji,
    required Animation<double> pulseAnimation,
    double size = 18,
  }) {
    return ScaleTransition(
      scale: pulseAnimation,
      child: Text(emoji, style: TextStyle(fontSize: size)),
    );
  }

  /// สร้างปุ่มสำหรับ AppBar
  static Widget buildAppBarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Tooltip(
              message: tooltip,
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
