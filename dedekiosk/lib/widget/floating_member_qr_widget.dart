import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dedekiosk/model/member_qr_model.dart';
import 'package:dedekiosk/service/member_qr_service.dart';
import 'package:dedekiosk/global.dart' as global;

/// Floating QR Widget สำหรับแสดง QR code ให้ลูกค้าสแกนเพื่อเชื่อมสมาชิก
/// จะแสดงเป็น floating button ที่มุมล่างขวา เมื่อกดจะขยายแสดง QR code
/// Session จะเริ่มอัตโนมัติเมื่อสร้าง widget (autoStartSession = true)
class FloatingMemberQrWidget extends StatefulWidget {
  final VoidCallback? onMemberLinked;
  final bool showOnlyWhenActive;
  final bool autoStartSession;

  const FloatingMemberQrWidget({
    super.key,
    this.onMemberLinked,
    this.showOnlyWhenActive = false,
    this.autoStartSession = true,
  });

  @override
  State<FloatingMemberQrWidget> createState() => _FloatingMemberQrWidgetState();
}

class _FloatingMemberQrWidgetState extends State<FloatingMemberQrWidget> with SingleTickerProviderStateMixin {
  final MemberQrService _memberQrService = MemberQrService();
  bool _isExpanded = false;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // ❌ Don't initialize anything if memberPinMode is true
    if (global.memberPinMode) {
      _animationController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
      );
      return; // Exit early - don't setup callbacks or timers
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
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

    // Auto start session when widget is created
    if (widget.autoStartSession) {
      _autoStartSession();
    }
  }

  /// Auto start session when widget is created
  Future<void> _autoStartSession() async {
    // Don't start session if memberPinMode is true
    if (global.memberPinMode) {
      return;
    }

    // Wait a bit for widget to be fully mounted
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted && !_memberQrService.hasActiveSession) {
      await _requestNewSession();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _handleMemberLinked(MemberDataModel member) {
    if (mounted) {
      setState(() {
        _isExpanded = false;
      });
      _animationController.reverse();

      // Show welcome dialog
      _showWelcomeDialog(member);

      // Callback to parent
      widget.onMemberLinked?.call();
    }
  }

  void _handleStatusChanged(MemberQrPollingStatus status) {
    if (mounted) {
      setState(() {});

      if (status == MemberQrPollingStatus.expired) {
        _showExpiredMessage();
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
      builder: (BuildContext context) {
        // Auto close after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
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
                    child: member.pictureUrl.isEmpty ? const Icon(Icons.person, size: 50) : null,
                  )
                else
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.orange.shade100,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.orange.shade800,
                    ),
                  ),
                const SizedBox(height: 16),

                // Welcome text
                Text(
                  '${global.language("welcome")}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),

                // Member name
                Text(
                  member.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Points info
                if (member.points > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
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
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${member.points.toStringAsFixed(0)} ${global.language("points")}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Check icon
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
              ],
            ),
          ),
        );
      },
    );
  }

  void _showExpiredMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(global.language("qr_expired")),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: global.language("refresh"),
          textColor: Colors.white,
          onPressed: _requestNewSession,
        ),
      ),
    );
  }

  Future<void> _requestNewSession() async {
    // Don't request if memberPinMode is true
    if (global.memberPinMode) return;

    await _memberQrService.requestNewSession();
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleExpanded() async {
    // Don't toggle if memberPinMode is true
    if (global.memberPinMode) return;

    if (_isExpanded) {
      _animationController.reverse();
      setState(() {
        _isExpanded = false;
      });
    } else {
      // Request new session if needed
      if (!_memberQrService.hasActiveSession) {
        await _requestNewSession();
      }

      setState(() {
        _isExpanded = true;
      });
      _animationController.forward();
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if member is already linked
    if (global.isMember) {
      return const SizedBox.shrink();
    }

    // Don't show if useMember is disabled
    if (!global.deviceConfig.useMember) {
      return const SizedBox.shrink();
    }

    // Don't show if memberPinMode is true (use PIN widget instead)
    if (global.memberPinMode) {
      return const SizedBox.shrink();
    }

    // Only show floating button when status is waitingForScan or requesting
    final status = _memberQrService.status;
    if (status != MemberQrPollingStatus.waitingForScan && status != MemberQrPollingStatus.requesting) {
      return const SizedBox.shrink();
    }

    // Show only when active session exists
    if (widget.showOnlyWhenActive && !_memberQrService.hasActiveSession) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Expanded QR card
        if (_isExpanded)
          Positioned(
            right: 16,
            bottom: 80,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.bottomRight,
              child: _buildExpandedCard(),
            ),
          ),

        // Floating button
        Positioned(
          right: 16,
          bottom: 16,
          child: _buildFloatingButton(),
        ),
      ],
    );
  }

  Widget _buildFloatingButton() {
    final hasSession = _memberQrService.hasActiveSession;
    final status = _memberQrService.status;

    Color buttonColor;
    IconData icon;
    String? badge;

    switch (status) {
      case MemberQrPollingStatus.waitingForScan:
        buttonColor = Colors.green;
        icon = Icons.qr_code_2;
        badge = _formatTime(_remainingSeconds);
        break;
      case MemberQrPollingStatus.requesting:
        buttonColor = Colors.orange;
        icon = Icons.hourglass_top;
        break;
      case MemberQrPollingStatus.memberLinked:
        buttonColor = Colors.blue;
        icon = Icons.check_circle;
        break;
      case MemberQrPollingStatus.expired:
        buttonColor = Colors.grey;
        icon = Icons.refresh;
        break;
      default:
        buttonColor = Colors.orange.shade700;
        icon = Icons.card_membership;
    }

    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: buttonColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: buttonColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),

            // Badge with countdown
            if (badge != null && hasSession)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedCard() {
    final status = _memberQrService.status;
    final qrUrl = _memberQrService.qrUrl;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  global.language("scan_for_member"),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: _toggleExpanded,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // QR Code or loading/error state
            if (status == MemberQrPollingStatus.requesting)
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (status == MemberQrPollingStatus.expired)
              SizedBox(
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      global.language("qr_expired"),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _requestNewSession,
                      icon: const Icon(Icons.refresh),
                      label: Text(global.language("refresh")),
                    ),
                  ],
                ),
              )
            else if (qrUrl.isNotEmpty)
              Column(
                children: [
                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: QrImageView(
                      data: qrUrl,
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
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
                  const SizedBox(height: 12),

                  // Countdown timer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _remainingSeconds < 60 ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: _remainingSeconds < 60 ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(_remainingSeconds),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _remainingSeconds < 60 ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_2,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _requestNewSession,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(global.language("start")),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Instructions
            Text(
              global.language("scan_qr_instruction"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),

            // Test button for simulating member link
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await _memberQrService.mockMemberLink();
              },
              icon: const Icon(Icons.bug_report, size: 16),
              label: const Text('ทดสอบ: จำลองสมาชิก'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple,
                side: const BorderSide(color: Colors.purple),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact version of the QR widget for smaller screens or inline use
class CompactMemberQrWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const CompactMemberQrWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Don't show if member is already linked or useMember is disabled
    if (global.isMember || !global.deviceConfig.useMember) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.card_membership,
              color: Colors.orange.shade800,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              global.language("become_member"),
              style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
