/// Model สำหรับข้อมูล PIN และ QR URL ที่ได้จาก backend
class MemberQrPinModel {
  final String pin;
  final String qrUrl;
  final String sessionId;
  final DateTime expireAt;

  MemberQrPinModel({
    required this.pin,
    required this.qrUrl,
    required this.sessionId,
    required this.expireAt,
  });

  factory MemberQrPinModel.fromJson(Map<String, dynamic> json) {
    // Support new API response format
    final data = json['data'] ?? json;
    final expiresIn = data['expiresIn'] ?? 900; // default 15 minutes

    return MemberQrPinModel(
      pin: data['pin']?.toString() ?? '',
      qrUrl: data['liffUrl'] ?? data['qrUrl'] ?? '',
      sessionId: data['sessionId'] ?? 'SESSION-${DateTime.now().millisecondsSinceEpoch}',
      expireAt: data['expireAt'] != null ? DateTime.parse(data['expireAt']) : DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pin': pin,
      'qrUrl': qrUrl,
      'sessionId': sessionId,
      'expireAt': expireAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expireAt);
}

/// Model สำหรับข้อมูลสมาชิกที่ได้จาก polling
/// รองรับ response format:
/// {
///   "success": true,
///   "data": {
///     "pin": "8062",
///     "shopId": "xxx",
///     "source": "kiosk",
///     "status": "active",  // pending | active
///     "displayName": "ชื่อลูกค้า",
///     "pictureUrl": "https://...",
///     "lineUserId": "Uxxxx",
///     ...
///   }
/// }
class MemberDataModel {
  final String memberId;
  final String lineUserId;
  final String displayName;
  final String pictureUrl;
  final String email;
  final String phone;
  final String memberCode;
  final double points;
  final String tier;
  final bool isLinked;
  final String status;

  MemberDataModel({
    required this.memberId,
    required this.lineUserId,
    required this.displayName,
    required this.pictureUrl,
    required this.email,
    required this.phone,
    required this.memberCode,
    required this.points,
    required this.tier,
    required this.isLinked,
    this.status = 'pending',
  });

  factory MemberDataModel.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? 'pending';
    return MemberDataModel(
      memberId: json['memberId'] ?? json['lineUserId'] ?? json['userId'] ?? '',
      lineUserId: json['lineUserId'] ?? json['userId'] ?? '',
      displayName: json['displayName'] ?? json['name'] ?? '',
      pictureUrl: json['pictureUrl'] ?? json['picture'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      memberCode: json['memberCode'] ?? json['code'] ?? '',
      points: (json['points'] ?? 0).toDouble(),
      tier: json['tier'] ?? 'standard',
      isLinked: status == 'active' || (json['isLinked'] ?? false),
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'lineUserId': lineUserId,
      'displayName': displayName,
      'pictureUrl': pictureUrl,
      'email': email,
      'phone': phone,
      'memberCode': memberCode,
      'points': points,
      'tier': tier,
      'isLinked': isLinked,
      'status': status,
    };
  }

  /// สร้าง mock data สำหรับทดสอบ
  static MemberDataModel mockMember() {
    return MemberDataModel(
      memberId: 'MOCK001',
      lineUserId: 'U1234567890abcdef',
      displayName: 'ทดสอบ สมาชิก',
      pictureUrl: 'https://profile.line-scdn.net/0m0000000000000000000000000000',
      email: 'test@example.com',
      phone: '0891234567',
      memberCode: 'MEM-MOCK-001',
      points: 150.0,
      tier: 'gold',
      isLinked: true,
    );
  }
}

/// สถานะของการ polling
enum MemberQrPollingStatus {
  idle,
  requesting,
  waitingForScan,
  memberLinked,
  expired,
  error,
}
