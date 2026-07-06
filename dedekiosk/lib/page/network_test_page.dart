import 'dart:async';
import 'package:flutter/material.dart';
import '../global.dart' as global;
import '../util/api.dart' as api;
import '../util/network_helper.dart';
import '../widget/network_loading_indicator.dart';
import '../widget/network_error_dialog.dart';
import '../widget/network_status_widget.dart';

/// Network Test Page - ทดสอบ Phase 1 + Phase 2
///
/// ทดสอบ:
/// - Timeout protection
/// - Retry mechanism
/// - Loading indicators
/// - Error dialogs
/// - Network status widget
class NetworkTestPage extends StatefulWidget {
  const NetworkTestPage({super.key});

  @override
  State<NetworkTestPage> createState() => _NetworkTestPageState();
}

class _NetworkTestPageState extends State<NetworkTestPage> {
  String _testResult = '';
  bool _isTesting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Test Page'),
        backgroundColor: Colors.blue,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(35),
          child: NetworkStatusWidget(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.science, size: 48, color: Colors.blue),
                    const SizedBox(height: 8),
                    const Text(
                      'Network Resilience Test Suite',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ทดสอบ Phase 1 (Timeout) + Phase 2 (UX)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Result Display
            if (_testResult.isNotEmpty) ...[
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Test Result:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_testResult),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Test Section 1: Timeout Protection
            _buildTestSection(
              title: '1. Timeout Protection Tests',
              icon: Icons.access_time,
              color: Colors.orange,
              tests: [
                _buildTestButton(
                  'Test clickHouseSelect with Timeout',
                  'ทดสอบ clickHouseSelect พร้อม timeout 10 วินาที',
                  _testClickHouseSelectTimeout,
                ),
                _buildTestButton(
                  'Test clickHouseExecute with Retry',
                  'ทดสอบ clickHouseExecute พร้อม retry 3 ครั้ง',
                  _testClickHouseExecuteRetry,
                ),
                _buildTestButton(
                  'Test getMemberPin with Timeout',
                  'ทดสอบ getMemberPin พร้อม timeout',
                  _testGetMemberPinTimeout,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Test Section 2: Loading Indicators
            _buildTestSection(
              title: '2. Loading Indicator Tests',
              icon: Icons.refresh,
              color: Colors.blue,
              tests: [
                _buildTestButton(
                  'Test Basic Loading Overlay',
                  'แสดง loading overlay 3 วินาที',
                  _testBasicLoading,
                ),
                _buildTestButton(
                  'Test Loading with withLoadingIndicator',
                  'ทดสอบ withLoadingIndicator helper',
                  _testWithLoadingIndicator,
                ),
                _buildTestButton(
                  'Test Loading with Cancel Button',
                  'แสดง loading พร้อมปุ่มยกเลิก',
                  _testLoadingWithCancel,
                ),
                _buildTestButton(
                  'Test Progress Sheet',
                  'แสดง progress bottom sheet',
                  _testProgressSheet,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Test Section 3: Error Dialogs
            _buildTestSection(
              title: '3. Error Dialog Tests',
              icon: Icons.error_outline,
              color: Colors.red,
              tests: [
                _buildTestButton(
                  'Test Timeout Error Dialog',
                  'แสดง timeout error dialog',
                  _testTimeoutErrorDialog,
                ),
                _buildTestButton(
                  'Test Connection Error Dialog',
                  'แสดง connection error dialog',
                  _testConnectionErrorDialog,
                ),
                _buildTestButton(
                  'Test Server Error Dialog',
                  'แสดง server error dialog',
                  _testServerErrorDialog,
                ),
                _buildTestButton(
                  'Test Error Snackbar',
                  'แสดง error snackbar',
                  _testErrorSnackbar,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Test Section 4: Network Status
            _buildTestSection(
              title: '4. Network Status Tests',
              icon: Icons.wifi,
              color: Colors.green,
              tests: [
                _buildTestButton(
                  'Test Network Availability Check',
                  'ตรวจสอบสถานะ network',
                  _testNetworkAvailability,
                ),
                _buildTestButton(
                  'Test executeWithRetry',
                  'ทดสอบ retry mechanism',
                  _testExecuteWithRetry,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Test Section 5: Real Scenarios
            _buildTestSection(
              title: '5. Real Scenario Tests',
              icon: Icons.play_circle_outline,
              color: Colors.purple,
              tests: [
                _buildTestButton(
                  'Simulate Stock Check Timeout',
                  'จำลองการเช็คสต็อกที่ timeout',
                  _testStockCheckScenario,
                ),
                _buildTestButton(
                  'Simulate Payment Processing',
                  'จำลองการประมวลผลการชำระเงิน',
                  _testPaymentScenario,
                ),
                _buildTestButton(
                  'Simulate Order Save with Retry',
                  'จำลองการบันทึกออร์เดอร์พร้อม retry',
                  _testOrderSaveScenario,
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> tests,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...tests,
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    String title,
    String subtitle,
    Future<void> Function() onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: _isTesting ? null : () => _runTest(onPressed),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runTest(Future<void> Function() test) async {
    setState(() {
      _isTesting = true;
      _testResult = '';
    });

    try {
      await test();
    } catch (e) {
      setState(() {
        _testResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  // ==================== Test Implementations ====================

  // Test 1.1: clickHouseSelect with Timeout
  Future<void> _testClickHouseSelectTimeout() async {
    try {
      final result = await api
          .clickHouseSelect(
              "select 1 as test from system.one") // Simple test query
          .timeout(NetworkTimeouts.standard);

      setState(() {
        _testResult = 'Success! Query completed within timeout.\nResult: $result';
      });
    } on TimeoutException {
      setState(() {
        _testResult = 'Timeout! Query exceeded 10 seconds (as expected for slow network)';
      });
    }
  }

  // Test 1.2: clickHouseExecute with Retry
  Future<void> _testClickHouseExecuteRetry() async {
    try {
      final result = await api.clickHouseExecute("select 1 as test");

      setState(() {
        _testResult = 'Success! Execute completed with retry mechanism.\nResult: $result';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Failed after retries: $e';
      });
    }
  }

  // Test 1.3: getMemberPin with Timeout
  Future<void> _testGetMemberPinTimeout() async {
    try {
      final result = await api.getMemberPin('1234');

      setState(() {
        _testResult = 'Success! getMemberPin completed.\nResult: $result';
      });
    } on TimeoutException {
      setState(() {
        _testResult = 'Timeout! getMemberPin exceeded 10 seconds';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error: $e';
      });
    }
  }

  // Test 2.1: Basic Loading
  Future<void> _testBasicLoading() async {
    NetworkLoadingOverlay.show(
      context,
      message: global.language("checking_stock"),
    );

    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      NetworkLoadingOverlay.hide(context);
      setState(() {
        _testResult = 'Loading overlay displayed for 3 seconds!';
      });
    }
  }

  // Test 2.2: withLoadingIndicator
  Future<void> _testWithLoadingIndicator() async {
    final result = await withLoadingIndicator<String>(
      context: context,
      message: global.language("processing_payment"),
      operation: () async {
        await Future.delayed(const Duration(seconds: 2));
        return 'Operation completed!';
      },
    );

    setState(() {
      _testResult = 'withLoadingIndicator test: $result';
    });
  }

  // Test 2.3: Loading with Cancel
  Future<void> _testLoadingWithCancel() async {
    bool cancelled = false;

    NetworkLoadingOverlay.show(
      context,
      message: 'กำลังประมวลผล... (กด Cancel เพื่อยกเลิก)',
      dismissible: true,
      onCancel: () {
        cancelled = true;
        Navigator.of(context).pop();
      },
    );

    await Future.delayed(const Duration(seconds: 5));

    if (mounted && !cancelled) {
      NetworkLoadingOverlay.hide(context);
      setState(() {
        _testResult = 'Completed without cancellation';
      });
    } else {
      setState(() {
        _testResult = 'User cancelled the operation';
      });
    }
  }

  // Test 2.4: Progress Sheet
  Future<void> _testProgressSheet() async {
    for (int i = 0; i <= 100; i += 10) {
      if (!mounted) break;

      NetworkProgressSheet.show(
        context,
        operation: 'กำลังดาวน์โหลด...',
        progress: i,
      );

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        NetworkProgressSheet.hide(context);
      }
    }

    setState(() {
      _testResult = 'Progress sheet completed 0-100%';
    });
  }

  // Test 3.1: Timeout Error Dialog
  Future<void> _testTimeoutErrorDialog() async {
    await NetworkErrorDialog.showTimeoutError(
      context,
      customMessage: "การตรวจสอบสต็อกใช้เวลานานเกินไป",
      showContinue: true,
      onRetry: () {
        setState(() {
          _testResult = 'User clicked Retry';
        });
      },
      onContinue: () {
        setState(() {
          _testResult = 'User clicked Continue';
        });
      },
      onCancel: () {
        setState(() {
          _testResult = 'User clicked Cancel';
        });
      },
    );
  }

  // Test 3.2: Connection Error Dialog
  Future<void> _testConnectionErrorDialog() async {
    await NetworkErrorDialog.showConnectionError(
      context,
      onRetry: () {
        setState(() {
          _testResult = 'User clicked Retry on connection error';
        });
      },
    );
  }

  // Test 3.3: Server Error Dialog
  Future<void> _testServerErrorDialog() async {
    await NetworkErrorDialog.showServerError(
      context,
      customMessage: 'เซิร์ฟเวอร์ขัดข้อง กรุณาลองใหม่ภายหลัง',
      onRetry: () {
        setState(() {
          _testResult = 'User clicked Retry on server error';
        });
      },
    );
  }

  // Test 3.4: Error Snackbar
  Future<void> _testErrorSnackbar() async {
    NetworkErrorSnackbar.show(
      context,
      message: 'การซิงค์ล้มเหลว',
      errorType: NetworkErrorType.timeout,
      onRetry: () {
        setState(() {
          _testResult = 'User clicked Retry from snackbar';
        });
      },
    );

    setState(() {
      _testResult = 'Snackbar displayed with retry action';
    });
  }

  // Test 4.1: Network Availability
  Future<void> _testNetworkAvailability() async {
    final isAvailable = await NetworkHelper.isNetworkAvailable();

    setState(() {
      _testResult = 'Network available: $isAvailable';
    });
  }

  // Test 4.2: executeWithRetry
  Future<void> _testExecuteWithRetry() async {
    int attempt = 0;

    final result = await NetworkHelper.executeWithRetry<String>(
      maxRetries: 3,
      timeout: NetworkTimeouts.quick,
      operation: () async {
        attempt++;
        await Future.delayed(const Duration(seconds: 1));

        if (attempt < 2) {
          throw Exception('Simulated failure');
        }

        return 'Success on attempt $attempt';
      },
    );

    setState(() {
      if (result.isSuccess) {
        _testResult = 'executeWithRetry: ${result.data}';
      } else {
        _testResult = 'executeWithRetry failed: ${result.error}';
      }
    });
  }

  // Test 5.1: Stock Check Scenario
  Future<void> _testStockCheckScenario() async {
    try {
      final stockQty = await withLoadingIndicator<double>(
        context: context,
        message: global.language("checking_stock"),
        operation: () async {
          // Simulate stock check
          await Future.delayed(const Duration(seconds: 2));
          return 10.0; // Available stock
        },
      );

      setState(() {
        _testResult = 'Stock check completed! Available: $stockQty';
      });
    } on TimeoutException {
      if (mounted) {
        await NetworkErrorDialog.showTimeoutError(
          context,
          customMessage: "การตรวจสอบสต็อกหมดเวลา",
          showContinue: true,
          onRetry: _testStockCheckScenario,
          onContinue: () {
            setState(() {
              _testResult = 'User chose to continue without stock check';
            });
          },
        );
      }
    }
  }

  // Test 5.2: Payment Scenario
  Future<void> _testPaymentScenario() async {
    try {
      final paymentResult = await withLoadingIndicator<bool>(
        context: context,
        message: global.language("processing_payment"),
        operation: () async {
          await Future.delayed(const Duration(seconds: 3));
          return true; // Payment success
        },
      );

      setState(() {
        _testResult = 'Payment processed successfully: $paymentResult';
      });
    } catch (e) {
      if (mounted) {
        await NetworkErrorDialog.showGenericError(
          context,
          title: 'ชำระเงินล้มเหลว',
          message: 'กรุณาลองใหม่อีกครั้ง',
          onRetry: _testPaymentScenario,
        );
      }
    }
  }

  // Test 5.3: Order Save Scenario
  Future<void> _testOrderSaveScenario() async {
    final result = await NetworkHelper.executeWithRetry<bool>(
      maxRetries: 3,
      timeout: NetworkTimeouts.long,
      operation: () async {
        await Future.delayed(const Duration(seconds: 2));
        return true; // Order saved
      },
    );

    if (result.isSuccess) {
      setState(() {
        _testResult = 'Order saved with retry mechanism!';
      });
    } else {
      if (mounted) {
        NetworkErrorSnackbar.show(
          context,
          message: result.error ?? 'Order save failed',
          errorType: result.errorType,
        );
      }
    }
  }
}
