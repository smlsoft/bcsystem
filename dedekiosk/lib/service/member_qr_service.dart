import 'dart:async';
import 'dart:convert';
import 'package:dedekiosk/model/member_qr_model.dart';
import 'package:dedekiosk/model/trans_model.dart';
import 'package:dedekiosk/objectbox/order_temp_data_model.dart';
import 'package:dedekiosk/util/logger.dart';
import 'package:http/http.dart' as http;
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/util/api.dart' as api;

/// Service สำหรับจัดการ Member QR flow ใหม่
/// Flow: KIOSK request session → แสดง QR → ลูกค้าสแกน → LIFF ส่งข้อมูลไป backend → KIOSK poll ได้ status=active
class MemberQrService {
  static final MemberQrService _instance = MemberQrService._internal();
  factory MemberQrService() => _instance;
  MemberQrService._internal();

  // Backend API base URL
  static const String _baseUrl = String.fromEnvironment(
    'MEMBER_QR_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // Current session data
  MemberQrPinModel? _currentSession;
  MemberDataModel? _linkedMember;
  MemberQrPollingStatus _status = MemberQrPollingStatus.idle;

  // Polling timer
  Timer? _pollingTimer;
  static const int _pollingIntervalMs = 2000; // Poll every 2 seconds
  static const int _maxPollingDurationSeconds = 900; // 15 minutes max (match expiresIn)

  // Callbacks
  Function(MemberDataModel member)? onMemberLinked;
  Function(MemberQrPollingStatus status)? onStatusChanged;
  Function(String error)? onError;

  // Getters
  MemberQrPinModel? get currentSession => _currentSession;
  MemberDataModel? get linkedMember => _linkedMember;
  MemberQrPollingStatus get status => _status;
  bool get hasActiveSession => _currentSession != null && !_currentSession!.isExpired;
  String get qrUrl => _currentSession?.qrUrl ?? '';
  String get pin => _currentSession?.pin ?? '';

  /// Request new session from backend
  /// POST /dedelineoa/kiosk/session
  /// Body: { "shopId": "xxx", "kioskId": "xxx" }
  Future<bool> requestNewSession() async {
    try {
      _updateStatus(MemberQrPollingStatus.requesting);
      _linkedMember = null;

      String shopId = global.deviceConfig.shopId;
      String kioskId = global.deviceConfig.orderStationCode;

      Logger.d('MemberQrService: Requesting new session - shopId: $shopId, kioskId: $kioskId');

      final url = '$_baseUrl/dedelineoa/kiosk/session';
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'shopId': shopId,
              'kioskId': kioskId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      Logger.d('MemberQrService: Session response status: ${response.statusCode}');
      Logger.d('MemberQrService: Session response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          _currentSession = MemberQrPinModel.fromJson(data);

          _updateStatus(MemberQrPollingStatus.waitingForScan);
          _startPolling();

          Logger.d('MemberQrService: New session created - PIN: ${_currentSession!.pin}, QR: ${_currentSession!.qrUrl}');
          return true;
        } else {
          Logger.e('MemberQrService: Invalid response - success: ${data['success']}');
          _updateStatus(MemberQrPollingStatus.error);
          onError?.call(data['message'] ?? 'Failed to create session');
          return false;
        }
      } else {
        Logger.e('MemberQrService: HTTP error - status: ${response.statusCode}');
        _updateStatus(MemberQrPollingStatus.error);
        onError?.call('Server error: ${response.statusCode}');
        return false;
      }
    } catch (e, s) {
      Logger.e('MemberQrService: Error requesting new session', error: e, stackTrace: s);
      _updateStatus(MemberQrPollingStatus.error);
      onError?.call(e.toString());
      return false;
    }
  }

  /// Start polling for member data
  void _startPolling() {
    _stopPolling();

    int elapsedSeconds = 0;

    _pollingTimer = Timer.periodic(
      Duration(milliseconds: _pollingIntervalMs),
      (timer) async {
        elapsedSeconds += _pollingIntervalMs ~/ 1000;

        // Check if session expired
        if (_currentSession?.isExpired ?? true) {
          Logger.d('MemberQrService: Session expired');
          _updateStatus(MemberQrPollingStatus.expired);
          _stopPolling();
          return;
        }

        // Check max polling duration
        if (elapsedSeconds >= _maxPollingDurationSeconds) {
          Logger.d('MemberQrService: Max polling duration reached');
          _updateStatus(MemberQrPollingStatus.expired);
          _stopPolling();
          return;
        }

        // Poll for member data
        await _pollForMemberData();
      },
    );
  }

  /// Poll backend for member status
  /// GET /dedelineoa/getpin?pin=xxx&shopId=xxx
  Future<void> _pollForMemberData() async {
    if (_currentSession == null) return;

    try {
      final shopId = global.deviceConfig.shopId;
      final pin = _currentSession!.pin;

      final url = '$_baseUrl/dedelineoa/getpin?pin=$pin&shopId=$shopId';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final status = data['data']['status']?.toString() ?? 'pending';

          Logger.d('MemberQrService: Poll status: $status');

          if (status == 'active') {
            // Member linked successfully!
            _linkedMember = MemberDataModel.fromJson(data['data']);
            await _handleMemberLinked(_linkedMember!);
          }
          // If status is 'pending', continue polling
        }
      }
    } catch (e, s) {
      Logger.e('MemberQrService: Error polling for member data', error: e, stackTrace: s);
      // Don't stop polling on error, just log it
    }
  }

  /// Handle when member is linked (status = active)
  Future<void> _handleMemberLinked(MemberDataModel member) async {
    Logger.d('MemberQrService: Member linked - ${member.displayName}');

    _stopPolling();
    _updateStatus(MemberQrPollingStatus.memberLinked);

    // Update global member data
    global.isMember = true;
    global.memberCode = member.memberCode;
    global.memberName = member.displayName;
    global.memberPicture = member.pictureUrl;
    global.memberEmail = member.email;
    global.memberPinCode = _currentSession?.pin ?? '';
    global.priceIndex = 1; // ราคาสมาชิก
    global.lineDestination = member.lineUserId;

    // Set customer names
    global.custNames = [
      TransNameInfoModel(
        name: member.displayName,
        code: "th",
        isauto: false,
        isdelete: false,
      ),
      TransNameInfoModel(
        name: member.displayName,
        code: "en",
        isauto: false,
        isdelete: false,
      ),
    ];

    // Try to get debtor data from backend
    try {
      var memberData = await api.getDebtorByLine(code: member.lineUserId);
      if (memberData.success && memberData.data != null) {
        global.memberCode = memberData.data["code"] ?? member.memberCode;
        List<TransNameInfoModel> names = (memberData.data["names"] as List?)?.map((data) => TransNameInfoModel.fromJson(data)).toList() ?? global.custNames;
        global.custNames = names;
      } else {
        // Create new debtor if not exists
        await api.createDebtor(
          code: member.lineUserId,
          name: member.displayName,
          email: member.email,
          img: member.pictureUrl,
        );
      }
    } catch (e) {
      Logger.e('MemberQrService: Error getting/creating debtor', error: e);
    }

    // Update cart prices to member prices
    _updateCartToMemberPrices();

    // Notify callback
    onMemberLinked?.call(member);
  }

  /// Update all items in cart to use member prices (priceIndex = 1)
  void _updateCartToMemberPrices() {
    try {
      final cartItems = global.objectBoxStore.box<OrderTempObjectBoxModel>().getAll();

      for (var item in cartItems) {
        // Find product to get member price
        final productIndex = global.findProductByBarcode(item.barcode);
        if (productIndex != -1) {
          final product = global.productList[productIndex];
          // Get member price (keynumber = 2)
          double memberPrice = 0;
          for (var price in product.prices) {
            if (price.keynumber == 2) {
              memberPrice = price.price;
              break;
            }
          }
          // Fallback to first price if member price not found
          if (memberPrice == 0 && product.prices.isNotEmpty) {
            memberPrice = product.prices[0].price;
          }

          if (memberPrice > 0) {
            // Update item with member price
            item.price = memberPrice;
            item.amount = memberPrice * item.qty + item.optionamount;
            global.objectBoxStore.box<OrderTempObjectBoxModel>().put(item);
          }
        }
      }

      Logger.d('MemberQrService: Updated ${cartItems.length} cart items to member prices');
    } catch (e) {
      Logger.e('MemberQrService: Error updating cart prices', error: e);
    }
  }

  /// Mock member linking for testing (simulate status = active)
  Future<void> mockMemberLink() async {
    Logger.d('MemberQrService: Mock member link triggered');

    // Create mock member data
    _linkedMember = MemberDataModel(
      memberId: 'MOCK-${DateTime.now().millisecondsSinceEpoch}',
      lineUserId: 'U_mock_${DateTime.now().millisecondsSinceEpoch}',
      displayName: 'ลูกค้าทดสอบ',
      pictureUrl: '',
      email: 'test@example.com',
      phone: '0891234567',
      memberCode: 'MEM-MOCK-001',
      points: 100,
      tier: 'gold',
      isLinked: true,
      status: 'active',
    );

    await _handleMemberLinked(_linkedMember!);
  }

  /// Stop polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Update status and notify callback
  void _updateStatus(MemberQrPollingStatus newStatus) {
    _status = newStatus;
    onStatusChanged?.call(newStatus);
  }

  /// Clear current session and reset
  void clearSession() {
    _stopPolling();
    _currentSession = null;
    _linkedMember = null;
    _updateStatus(MemberQrPollingStatus.idle);
  }

  /// Dispose service
  void dispose() {
    clearSession();
    onMemberLinked = null;
    onStatusChanged = null;
    onError = null;
  }

  /// Check if member is already linked in this session
  bool get isMemberLinked => _linkedMember != null;

  /// Get remaining time for QR session (in seconds)
  int get remainingSeconds {
    if (_currentSession == null || _currentSession!.isExpired) return 0;
    return _currentSession!.expireAt.difference(DateTime.now()).inSeconds;
  }
}
