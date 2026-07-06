import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// Performance Monitoring Widget for DeDe Kiosk
/// Add this to your app to monitor performance metrics in real-time
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enabled = kDebugMode, // Only enable in debug mode by default
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  Timer? _monitorTimer;
  final List<PerformanceMetric> _metrics = [];
  bool _showOverlay = false;

  // Metrics
  int _frameCount = 0;
  int _droppedFrames = 0;
  DateTime _lastFrameTime = DateTime.now();
  int _currentFPS = 0;
  int _memoryUsageMB = 0;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _startMonitoring();
    }
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    // Monitor every second
    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;

      // Calculate FPS
      final now = DateTime.now();
      final timeDiff = now.difference(_lastFrameTime).inMilliseconds;
      if (timeDiff > 0) {
        _currentFPS = (_frameCount * 1000 / timeDiff).round();
      }
      _lastFrameTime = now;
      _frameCount = 0;

      // Get memory usage (approximate)
      try {
        // This is a placeholder - actual implementation would parse process info
        _memoryUsageMB = (ProcessInfo.currentRss ~/ (1024 * 1024));
      } catch (e) {
        // Fallback if can't get process info
        _memoryUsageMB = 0;
      }

      setState(() {
        _metrics.add(PerformanceMetric(
          timestamp: DateTime.now(),
          fps: _currentFPS,
          memoryMB: _memoryUsageMB,
          droppedFrames: _droppedFrames,
        ));

        // Keep only last 60 seconds of metrics
        if (_metrics.length > 60) {
          _metrics.removeAt(0);
        }
      });

      // Log performance issues
      if (_currentFPS < 45) {
        debugPrint('⚠️ PERFORMANCE WARNING: FPS dropped to $_currentFPS');
      }
      if (_droppedFrames > 5) {
        debugPrint('⚠️ PERFORMANCE WARNING: $_droppedFrames frames dropped');
        _droppedFrames = 0;
      }
    });

    // Track frame rendering
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
  }

  void _onFrame(Duration timestamp) {
    if (!mounted) return;
    _frameCount++;
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,

        // Toggle button
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.black.withValues(alpha: 0.7),
            child: Icon(
              _showOverlay ? Icons.close : Icons.analytics,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showOverlay = !_showOverlay;
              });
            },
          ),
        ),

        // Performance overlay
        if (_showOverlay)
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Performance Monitor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildMetricRow(
                    'FPS',
                    '$_currentFPS',
                    _currentFPS >= 55 ? Colors.green :
                    _currentFPS >= 45 ? Colors.orange : Colors.red,
                  ),
                  _buildMetricRow(
                    'Memory',
                    '$_memoryUsageMB MB',
                    _memoryUsageMB < 240 ? Colors.green :
                    _memoryUsageMB < 280 ? Colors.orange : Colors.red,
                  ),
                  _buildMetricRow(
                    'Target FPS',
                    '60',
                    Colors.white54,
                  ),
                  _buildMetricRow(
                    'Target Memory',
                    '<240 MB',
                    Colors.white54,
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),

                  // Performance status
                  _buildStatusIndicator(),

                  // Export button
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _exportMetrics,
                      icon: const Icon(Icons.download),
                      label: const Text('Export Metrics'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final isGood = _currentFPS >= 55 && _memoryUsageMB < 240;
    final isOk = _currentFPS >= 45 && _memoryUsageMB < 280;

    final status = isGood ? 'Excellent' : isOk ? 'Good' : 'Needs Improvement';
    final statusColor = isGood ? Colors.green : isOk ? Colors.orange : Colors.red;
    final icon = isGood ? Icons.check_circle : isOk ? Icons.warning : Icons.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _exportMetrics() {
    if (_metrics.isEmpty) {
      debugPrint('No metrics to export');
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('DeDe Kiosk Performance Metrics');
    buffer.writeln('Export Time: ${DateTime.now()}');
    buffer.writeln('');
    buffer.writeln('Timestamp,FPS,Memory(MB),DroppedFrames');

    for (final metric in _metrics) {
      buffer.writeln(
        '${metric.timestamp.toIso8601String()},'
        '${metric.fps},'
        '${metric.memoryMB},'
        '${metric.droppedFrames}'
      );
    }

    // Calculate averages
    final avgFPS = _metrics.map((m) => m.fps).reduce((a, b) => a + b) / _metrics.length;
    final avgMemory = _metrics.map((m) => m.memoryMB).reduce((a, b) => a + b) / _metrics.length;

    buffer.writeln('');
    buffer.writeln('Summary:');
    buffer.writeln('Average FPS: ${avgFPS.toStringAsFixed(1)}');
    buffer.writeln('Average Memory: ${avgMemory.toStringAsFixed(0)} MB');
    buffer.writeln('Total Metrics: ${_metrics.length}');

    debugPrint(buffer.toString());
    debugPrint('✅ Metrics exported to console. Copy and save to file.');
  }
}

class PerformanceMetric {
  final DateTime timestamp;
  final int fps;
  final int memoryMB;
  final int droppedFrames;

  PerformanceMetric({
    required this.timestamp,
    required this.fps,
    required this.memoryMB,
    required this.droppedFrames,
  });
}

// Placeholder for process info (would need platform-specific implementation)
class ProcessInfo {
  static int get currentRss => 220 * 1024 * 1024; // Placeholder: 220MB
}
