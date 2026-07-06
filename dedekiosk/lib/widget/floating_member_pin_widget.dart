import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dedekiosk/model/trans_model.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/util/api.dart' as api;
import 'package:dedekiosk/util/logger.dart';

/// Floating PIN Widget สำหรับระบบสมาชิกแบบกรอก PIN
/// จะแสดงเป็น floating button ที่มุมล่างขวา เมื่อกดจะขยายแสดง QR code LINE OA และช่องกรอก PIN
class FloatingMemberPinWidget extends StatefulWidget {
  final VoidCallback? onMemberLinked;

  const FloatingMemberPinWidget({
    super.key,
    this.onMemberLinked,
  });

  @override
  State<FloatingMemberPinWidget> createState() => _FloatingMemberPinWidgetState();
}

class _FloatingMemberPinWidgetState extends State<FloatingMemberPinWidget> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // PIN controllers
  final TextEditingController _pinController1 = TextEditingController();
  final TextEditingController _pinController2 = TextEditingController();
  final TextEditingController _pinController3 = TextEditingController();
  final TextEditingController _pinController4 = TextEditingController();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pinController1.dispose();
    _pinController2.dispose();
    _pinController3.dispose();
    _pinController4.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    if (_isExpanded) {
      _animationController.reverse();
      setState(() {
        _isExpanded = false;
        _clearPinFields();
      });
    } else {
      setState(() {
        _isExpanded = true;
      });
      _animationController.forward();
    }
  }

  void _clearPinFields() {
    _pinController1.clear();
    _pinController2.clear();
    _pinController3.clear();
    _pinController4.clear();
  }

  String get _pinCode => _pinController1.text + _pinController2.text + _pinController3.text + _pinController4.text;

  void _addDigit(String digit) {
    if (_pinController1.text.isEmpty) {
      _pinController1.text = digit;
    } else if (_pinController2.text.isEmpty) {
      _pinController2.text = digit;
    } else if (_pinController3.text.isEmpty) {
      _pinController3.text = digit;
    } else if (_pinController4.text.isEmpty) {
      _pinController4.text = digit;
    }
    setState(() {});
  }

  void _removeDigit() {
    if (_pinController4.text.isNotEmpty) {
      _pinController4.clear();
    } else if (_pinController3.text.isNotEmpty) {
      _pinController3.clear();
    } else if (_pinController2.text.isNotEmpty) {
      _pinController2.clear();
    } else if (_pinController1.text.isNotEmpty) {
      _pinController1.clear();
    }
    setState(() {});
  }

  Future<void> _checkPin() async {
    if (_pinCode.length != 4) {
      _showErrorSnackBar(global.language("please_enter_4_digits"));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var pinData = await api.getMemberPin(_pinCode);

      if (pinData["success"] == true) {
        if (pinData["data"]["status"] == "active") {
          await api.useMemberPin(_pinCode);

          // Set member data
          global.isMember = true;
          global.memberCode = "";
          global.lineDestination = pinData["data"]["destination"] ?? "";
          global.memberName = pinData["data"]["displayName"] ?? "";
          global.memberEmail = pinData["data"]["email"] ?? "";
          global.memberPicture = pinData["data"]["pictureUrl"] ?? "";
          global.memberPinCode = _pinCode;
          global.priceIndex = 1;

          // Get or create debtor
          var memberData = await api.getDebtorByLine(code: pinData["data"]["userId"] ?? "");
          Logger.d('FloatingMemberPinWidget: getDebtorByLine response: success=${memberData.success}, error=${memberData.error}, message=${memberData.message}');

          // ตรวจสอบว่าเป็น "document not found" (ไม่มี debtor) หรือ error จริง
          String messageStr = (memberData.message ?? "").toString().toLowerCase();
          bool isDocumentNotFound = messageStr.contains("document not found") || messageStr.contains("not found");
          bool isRealError = memberData.error == true && !isDocumentNotFound && messageStr.isNotEmpty;

          if (isRealError) {
            Logger.w('FloatingMemberPinWidget: API error (not "document not found"): ${memberData.message}');
          }

          if (!memberData.success) {
            Logger.d('FloatingMemberPinWidget: Creating new debtor (isDocumentNotFound=$isDocumentNotFound)');
            global.custNames = [
              TransNameInfoModel(name: global.memberName, code: "th", isauto: false, isdelete: false),
              TransNameInfoModel(name: global.memberName, code: "en", isauto: false, isdelete: false),
            ];
            try {
              await api.createDebtor(
                code: pinData["data"]["userId"] ?? "",
                name: global.memberName,
                email: global.memberEmail,
                img: global.memberPicture,
              );
              Logger.d('FloatingMemberPinWidget: Debtor created successfully');
            } catch (e) {
              Logger.e('FloatingMemberPinWidget: Failed to create debtor', error: e);
            }
            // สมาชิกใหม่ใช้ราคา member (priceIndex = 1)
            global.memberPriceLevel = 1;
            global.priceIndex = 1;
          } else {
            Logger.d('FloatingMemberPinWidget: Using existing debtor data');
            // ไม่ override isMember - เราผ่าน PIN แล้ว ถือว่าเป็นสมาชิก
            global.memberCode = memberData.data["code"] ?? "";
            // เก็บค่าตัวแปรใหม่จาก API
            String pointsCode = (memberData.data["pointscode"] ?? "").toString();
            global.memberPointsCode = pointsCode.isNotEmpty ? pointsCode : (memberData.data["code"] ?? "").toString();
            // แปลง pricelevel เป็น int
            var priceLevelRaw = memberData.data["pricelevel"];
            global.memberPriceLevel = (priceLevelRaw is int) ? priceLevelRaw : int.tryParse(priceLevelRaw?.toString() ?? "2") ?? 2;
            // ถ้า pricelevel เป็น 1 ให้เปลี่ยนเป็น 2 เพราะผ่าน PIN แล้ว
            if (global.memberPriceLevel == 1) {
              global.memberPriceLevel = 1;
            }
            global.memberGuidFixed = (memberData.data["guidfixed"] ?? "").toString();
            // แปลง pointbalance เป็น double
            var pointBalanceRaw = memberData.data["pointbalance"];
            if (pointBalanceRaw is double) {
              global.memberPointBalance = pointBalanceRaw;
            } else if (pointBalanceRaw is int) {
              global.memberPointBalance = pointBalanceRaw.toDouble();
            } else {
              global.memberPointBalance = double.tryParse(pointBalanceRaw?.toString() ?? "0") ?? 0;
            }
            global.priceIndex = global.memberPriceLevel;
            List<TransNameInfoModel> names = (memberData.data["names"] as List?)?.map((data) => TransNameInfoModel.fromJson(data)).toList() ?? global.custNames;
            global.custNames = names;
            Logger.d('FloatingMemberPinWidget: Member data set - code=${global.memberCode}, priceLevel=${global.memberPriceLevel}, pointBalance=${global.memberPointBalance}');
          }

          // Close expanded panel
          _animationController.reverse();
          setState(() {
            _isExpanded = false;
            _clearPinFields();
          });

          // Show welcome dialog
          _showWelcomeDialog();

          // Callback to parent
          widget.onMemberLinked?.call();

          Logger.d('FloatingMemberPinWidget: Member linked - ${global.memberName}');
        } else {
          _showErrorSnackBar(global.language("pin_already_used"));
          _clearPinFields();
        }
      } else {
        _showErrorSnackBar(global.language("pin_not_found"));
        _clearPinFields();
      }
    } catch (e, s) {
      Logger.e('FloatingMemberPinWidget: Error checking PIN', error: e, stackTrace: s);
      _showErrorSnackBar(global.language("error"));
      _clearPinFields();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Auto close after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
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
                if (global.memberPicture.isNotEmpty)
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(global.memberPicture),
                    onBackgroundImageError: (_, __) {},
                  )
                else
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.orange.shade100,
                    child: Icon(
                      Icons.person,
                      size: 40,
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
                  global.memberName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    // Don't show if member is already linked
    if (global.isMember) {
      return const SizedBox.shrink();
    } // Don't show if useMember is disabled
    if (!global.deviceConfig.useMember) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Expanded PIN card
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
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.orange.shade700,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.person,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildExpandedCard() {
    final lineOaImg = global.shopProfile?.orderstation.lineoaimg ?? "";

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
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
                  global.language("member_pin"),
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

            // LINE OA QR Image
            if (lineOaImg.isNotEmpty) ...[
              Text(
                global.language("add_friend"),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  lineOaImg,
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 150,
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.qr_code, size: 48, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // PIN input fields
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPinField(_pinController1),
                const SizedBox(width: 8),
                _buildPinField(_pinController2),
                const SizedBox(width: 8),
                _buildPinField(_pinController3),
                const SizedBox(width: 8),
                _buildPinField(_pinController4),
              ],
            ),
            const SizedBox(height: 12),

            // Number pad
            _buildNumberPad(),
            const SizedBox(height: 12),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        global.language("confirm"),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinField(TextEditingController controller) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          controller.text.isEmpty ? "" : "●",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumButton("1"),
            _buildNumButton("2"),
            _buildNumButton("3"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumButton("4"),
            _buildNumButton("5"),
            _buildNumButton("6"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNumButton("7"),
            _buildNumButton("8"),
            _buildNumButton("9"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton(
              icon: Icons.clear,
              color: Colors.grey.shade400,
              onTap: _clearPinFields,
            ),
            _buildNumButton("0"),
            _buildActionButton(
              icon: Icons.backspace,
              color: Colors.red.shade200,
              onTap: _removeDigit,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumButton(String digit) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _addDigit(digit),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 55,
            height: 45,
            alignment: Alignment.center,
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 55,
            height: 45,
            alignment: Alignment.center,
            child: Icon(icon, size: 20),
          ),
        ),
      ),
    );
  }
}
