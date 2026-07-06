import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dedekiosk/model/member_qr_model.dart';
import 'package:dedekiosk/service/member_qr_service.dart';
import 'package:dedekiosk/global.dart' as global;

/// หน้าแสดง QR code สำหรับสมัครสมาชิก (New Flow)
/// ลูกค้าสแกน QR → LIFF ส่งข้อมูลไป backend → KIOSK poll ได้ข้อมูลสมาชิก
class MemberQrPage extends StatefulWidget {
  const MemberQrPage({super.key});

  @override
  State<MemberQrPage> createState() => _MemberQrPageState();
}

class _MemberQrPageState extends State<MemberQrPage> with SingleTickerProviderStateMixin {
  final MemberQrService _memberQrService = MemberQrService();
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _isLoading = true;

  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // If memberPinMode is true, this page should not be used
    // Navigate back or show error
    if (global.memberPinMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
      return;
    } // Setup pulse animation for QR code
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );

    // Setup callbacks
    _memberQrService.onMemberLinked = _handleMemberLinked;
    _memberQrService.onStatusChanged = _handleStatusChanged;
    _memberQrService.onError = _handleError;

    // Start countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _remainingSeconds = _memberQrService.remainingSeconds;
        });
      }
    });

    // Request new session
    _requestNewSession();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController?.dispose();
    super.dispose();
  }

  Future<void> _requestNewSession() async {
    setState(() {
      _isLoading = true;
    });

    await _memberQrService.requestNewSession();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleMemberLinked(MemberDataModel member) {
    if (mounted) {
      // Show welcome dialog then navigate
      _showWelcomeDialog(member);
    }
  }

  void _handleStatusChanged(MemberQrPollingStatus status) {
    if (mounted) {
      setState(() {});

      if (status == MemberQrPollingStatus.expired) {
        _showExpiredDialog();
      }
    }
  }

  void _handleError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showWelcomeDialog(MemberDataModel member) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Auto close after 2 seconds and navigate
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
          // Navigate to order page
          Navigator.pushNamedAndRemoveUntil(
            context,
            "/order_animation_one",
            (Route<dynamic> route) => false,
          );
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile picture
                if (member.pictureUrl.isNotEmpty)
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(member.pictureUrl),
                    onBackgroundImageError: (_, __) {},
                  )
                else
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green.shade100,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.green.shade800,
                    ),
                  ),
                const SizedBox(height: 16),

                // Success icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.green.shade800,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),

                // Welcome text
                Text(
                  global.language("welcome"),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),

                // Member name
                Text(
                  member.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Points info
                if (member.points > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars,
                          color: Colors.orange.shade800,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${member.points.toStringAsFixed(0)} ${global.language("points")}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.timer_off, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(global.language("qr_expired")),
            ],
          ),
          content: Text(global.language("scan_qr_instruction")),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _goBack();
              },
              child: Text(global.language("back")),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _requestNewSession();
              },
              icon: const Icon(Icons.refresh),
              label: Text(global.language("refresh")),
            ),
          ],
        );
      },
    );
  }

  void _goBack() {
    _memberQrService.clearSession();
    Navigator.pushNamedAndRemoveUntil(
      context,
      "/order_select",
      (Route<dynamic> route) => false,
    );
  }

  void _skipMember() {
    _memberQrService.clearSession();
    global.memberCode = "";
    global.memberPinCode = "";
    global.priceIndex = 1;
    global.custNames = [];
    global.memberPicture = "";
    global.memberEmail = "";
    global.isMember = false;

    Navigator.pushNamedAndRemoveUntil(
      context,
      "/order_animation_one",
      (Route<dynamic> route) => false,
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final status = _memberQrService.status;
    final qrUrl = _memberQrService.qrUrl;

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      global.language("scan_for_member"),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                        shadows: const [
                          Shadow(
                            blurRadius: 2.0,
                            color: Colors.white,
                            offset: Offset(1.0, 1.0),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // QR Code Section
                if (_isLoading) _buildLoadingState() else if (status == MemberQrPollingStatus.expired) _buildExpiredState() else if (qrUrl.isNotEmpty) _buildQrCodeSection(qrUrl) else _buildErrorState(),

                const SizedBox(height: 32),

                // Instructions
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        global.language("scan_qr_instruction"),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
          ),
          const SizedBox(height: 16),
          Text(
            global.language("loading"),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredState() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            global.language("qr_expired"),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _requestNewSession,
            icon: const Icon(Icons.refresh),
            label: Text(global.language("refresh")),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            global.language("error"),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _requestNewSession,
            icon: const Icon(Icons.refresh),
            label: Text(global.language("retry")),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeSection(String qrUrl) {
    return Column(
      children: [
        // QR Code with animation
        ScaleTransition(
          scale: _pulseAnimation ?? const AlwaysStoppedAnimation(1.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: QrImageView(
              data: qrUrl,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.orange.shade800,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black87,
              ),
              errorStateBuilder: (context, error) {
                return Center(
                  child: Text(
                    'Error generating QR',
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Countdown timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _remainingSeconds < 60 ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _remainingSeconds < 60 ? Colors.red.shade200 : Colors.green.shade200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                size: 24,
                color: _remainingSeconds < 60 ? Colors.red.shade700 : Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(_remainingSeconds),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _remainingSeconds < 60 ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),

        // Waiting indicator
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              global.language("waiting_for_scan"),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Row(
        children: [
          // Back button
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back),
                label: Text(
                  global.language("back"),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Skip/Continue without member
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _skipMember,
                icon: const Icon(Icons.arrow_forward),
                label: Text(
                  global.language("skip"),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
