import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/model/objectbox/print_queue_struct.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/objectbox.g.dart';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

class PrintQueueViewerScreen extends StatefulWidget {
  const PrintQueueViewerScreen({super.key});

  @override
  State<PrintQueueViewerScreen> createState() => _PrintQueueViewerScreenState();
}

class _PrintQueueViewerScreenState extends State<PrintQueueViewerScreen> {
  List<PrintQueueObjectBoxStruct> _allJobs = [];
  String _filterStatus = 'all'; // all, pending, printing, completed, failed
  Timer? _refreshTimer;
  bool _isLoading = true;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadJobs();
    // Auto refresh ทุก 2 วินาที
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _loadJobs();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    try {
      final box = global.objectBoxStore.box<PrintQueueObjectBoxStruct>();
      final query = box
          .query()
          .order(
            PrintQueueObjectBoxStruct_.createdAt,
            flags: 1, // Descending
          )
          .build();

      final jobs = query.find();
      query.close();

      if (mounted) {
        setState(() {
          _allJobs = jobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('[PrintQueue] Error loading jobs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<PrintQueueObjectBoxStruct> get _filteredJobs {
    if (_filterStatus == 'all') {
      return _allJobs;
    }

    final statusValue = _getStatusValue(_filterStatus);
    return _allJobs.where((job) => job.status == statusValue).toList();
  }

  int _getStatusValue(String status) {
    switch (status) {
      case 'pending':
        return 0;
      case 'printing':
        return 1;
      case 'completed':
        return 2;
      case 'failed':
        return 3;
      default:
        return 0;
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0: // pending
        return Colors.orange;
      case 1: // printing
        return Colors.blue;
      case 2: // completed
        return Colors.green;
      case 3: // failed
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return 'รอพิมพ์';
      case 1:
        return 'กำลังพิมพ์';
      case 2:
        return 'สำเร็จ';
      case 3:
        return 'ล้มเหลว';
      default:
        return 'ไม่ทราบ';
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
  }

  String _getJobTypeText(String jobType) {
    switch (jobType) {
      case 'receipt':
        return 'ใบเสร็จ';
      case 'kitchen':
        return 'ครัว';
      case 'bill':
        return 'บิล';
      case 'report':
        return 'รายงาน';
      case 'label':
        return 'ฉลาก';
      default:
        return jobType;
    }
  }

  Color _getJobTypeColor(String jobType) {
    switch (jobType) {
      case 'receipt':
        return Colors.green;
      case 'kitchen':
        return Colors.orange;
      case 'bill':
        return Colors.blue;
      case 'report':
        return Colors.purple;
      case 'label':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  /// ⭐ ดึงรายละเอียดสินค้า/เอกสารจาก metadata
  /// - ถ้าเป็น kitchen: แสดงชื่อสินค้า
  /// - ถ้าเป็น receipt: แสดง doc_no
  String _getItemDescription(PrintQueueObjectBoxStruct job) {
    // ถ้าเป็นใบเสร็จ แสดง doc_no
    if (job.jobType == 'receipt') {
      return job.docNumber.isNotEmpty ? job.docNumber : '-';
    }

    // ถ้าเป็น kitchen ดึงชื่อสินค้าจาก metadata
    if (job.metadata.isNotEmpty) {
      try {
        final Map<String, dynamic> meta = jsonDecode(job.metadata);
        if (meta.containsKey('productNames')) {
          final List<dynamic> names = meta['productNames'];
          if (names.isNotEmpty) {
            // แสดงชื่อสินค้า (ถ้ามีหลายรายการใช้ , คั่น)
            return names.take(3).join(', ') + (names.length > 3 ? '...' : '');
          }
        }
      } catch (e) {
        // JSON parse error
      }
    }

    return '-';
  }

  Future<void> _retryJob(PrintQueueObjectBoxStruct job) async {
    try {
      await global.updatePrintJobStatus(fileName: job.fileName, status: PrintQueueStatus.pending, errorMessage: null);
      _loadJobs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เพิ่มงานเข้าคิวพิมพ์ใหม่แล้ว'), backgroundColor: Colors.green, duration: Duration(seconds: 2)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 3)));
      }
    }
  }

  Future<void> _deleteJob(PrintQueueObjectBoxStruct job) async {
    try {
      final box = global.objectBoxStore.box<PrintQueueObjectBoxStruct>();
      box.remove(job.id);
      _loadJobs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบงานเรียบร้อย'), backgroundColor: Colors.green, duration: Duration(seconds: 2)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 3)));
      }
    }
  }

  Future<void> _cleanupOldJobs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ล้างข้อมูลเก่า'),
        content: const Text('ต้องการลบงานที่สำเร็จและล้มเหลวที่เก่ากว่า 7 วันใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Manual cleanup - delete jobs older than 7 days
        final box = global.objectBoxStore.box<PrintQueueObjectBoxStruct>();
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

        final query = box.query(PrintQueueObjectBoxStruct_.createdAt.lessThan(sevenDaysAgo.millisecondsSinceEpoch)).build();

        final oldJobs = query.find();
        query.close();

        final completedOrFailed = oldJobs.where((job) => job.status == 2 || job.status == 3).toList();

        for (var job in completedOrFailed) {
          box.remove(job.id);
        }

        _loadJobs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ล้างข้อมูลเก่าเรียบร้อย (${completedOrFailed.length} รายการ)'), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 3)));
        }
      }
    }
  }

  /// ⭐ ล้างประวัติการพิมพ์ที่สำเร็จทั้งหมด (status=completed)
  Future<void> _clearCompletedJobs() async {
    final completedCount = _allJobs.where((j) => j.status == 2).length;

    if (completedCount == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่มีประวัติที่สำเร็จให้ลบ'), backgroundColor: Colors.orange, duration: Duration(seconds: 2)));
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ล้างประวัติการพิมพ์'),
        content: Text('ต้องการลบประวัติที่พิมพ์สำเร็จทั้งหมด ($completedCount รายการ) ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final box = global.objectBoxStore.box<PrintQueueObjectBoxStruct>();

        // Query jobs ที่ status = completed (2)
        final query = box.query(PrintQueueObjectBoxStruct_.status.equals(2)).build();
        final completedJobs = query.find();
        query.close();

        // ลบทีละรายการ
        int deletedCount = 0;
        for (var job in completedJobs) {
          box.remove(job.id);
          deletedCount++;
        }

        if (kDebugMode) {
          AppLogger.success('[PrintQueue] 🗑️ Cleared $deletedCount completed print jobs');
        }

        _loadJobs();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('ล้างประวัติเรียบร้อย ($deletedCount รายการ)'), backgroundColor: Colors.green, duration: const Duration(seconds: 2)));
        }
      } catch (e) {
        AppLogger.error('[PrintQueue] ❌ Error clearing completed jobs: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 3)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _allJobs.where((j) => j.status == 0).length;
    final printingCount = _allJobs.where((j) => j.status == 1).length;
    final completedCount = _allJobs.where((j) => j.status == 2).length;
    final failedCount = _allJobs.where((j) => j.status == 3).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'คิวพิมพ์เสร็จ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'รีเฟรช',
            onPressed: _loadJobs,
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services, color: Colors.white),
            tooltip: 'ล้างประวัติที่สำเร็จ',
            onPressed: _clearCompletedJobs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            tooltip: 'ล้างข้อมูลเก่า (7 วัน)',
            onPressed: _cleanupOldJobs,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('สถานะ: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChip('ทั้งหมด', 'all', _allJobs.length),
                          _buildFilterChip('รอพิมพ์', 'pending', pendingCount),
                          _buildFilterChip('กำลังพิมพ์', 'printing', printingCount),
                          _buildFilterChip('สำเร็จ', 'completed', completedCount),
                          _buildFilterChip('ล้มเหลว', 'failed', failedCount),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('ทั้งหมด ${_filteredJobs.length} รายการ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),

          // Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredJobs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('ไม่มีข้อมูลในคิว', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : Scrollbar(
                    controller: _verticalScrollController,
                    thumbVisibility: true,
                    child: Scrollbar(
                      controller: _horizontalScrollController,
                      thumbVisibility: true,
                      notificationPredicate: (notification) => notification.depth == 1,
                      child: SingleChildScrollView(
                        controller: _verticalScrollController,
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 16,
                            headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                            headingRowHeight: 48,
                            dataRowMinHeight: 56,
                            dataRowMaxHeight: 80,
                            columns: const [
                              DataColumn(
                                label: Text('สถานะ', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              DataColumn(
                                label: Text('เลขที่เอกสาร', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              DataColumn(
                                label: Text('ชื่อไฟล์', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              DataColumn(
                                label: Text('เครื่องพิมพ์', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              DataColumn(
                                label: Text('ประเภทงาน', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              DataColumn(
                                label: Text('รายการ', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              DataColumn(
                                label: Text('สร้างเมื่อ', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              DataColumn(
                                label: Text('เริ่มพิมพ์', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              DataColumn(
                                label: Text('เสร็จสิ้น', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              DataColumn(
                                label: Text('ลองใหม่', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              DataColumn(
                                label: Text('ข้อผิดพลาด', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              DataColumn(
                                label: Text('จัดการ', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                            rows: _filteredJobs.map((job) {
                              return DataRow(
                                cells: [
                                  // Status
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(job.status).withOpacity(0.2),
                                        border: Border.all(color: _getStatusColor(job.status), width: 1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStatusText(job.status),
                                        style: TextStyle(color: _getStatusColor(job.status), fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  // Doc Number
                                  DataCell(Text(job.docNumber.isEmpty ? '-' : job.docNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  // File Name
                                  DataCell(SizedBox(width: 200, child: Text(job.fileName, overflow: TextOverflow.ellipsis, maxLines: 2))),
                                  // Printer Name
                                  DataCell(Text(job.printerName)),
                                  // Job Type (ประเภทงาน)
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: _getJobTypeColor(job.jobType).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                      child: Text(
                                        _getJobTypeText(job.jobType),
                                        style: TextStyle(color: _getJobTypeColor(job.jobType), fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                  // รายการ (สินค้า/เอกสาร)
                                  DataCell(
                                    SizedBox(
                                      width: 180,
                                      child: Text(
                                        _getItemDescription(job),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        style: TextStyle(fontSize: 12, color: job.jobType == 'kitchen' ? Colors.orange.shade700 : Colors.blue.shade700),
                                      ),
                                    ),
                                  ),
                                  // Created At
                                  DataCell(Text(_formatDateTime(job.createdAt), style: const TextStyle(fontSize: 12))),
                                  // Started At (ไม่มี field นี้ - ใช้ createdAt แทน)
                                  DataCell(Text(job.status >= 1 ? _formatDateTime(job.createdAt) : '-', style: const TextStyle(fontSize: 12))),
                                  // Completed At (ใช้ printedAt)
                                  DataCell(Text(_formatDateTime(job.printedAt), style: const TextStyle(fontSize: 12))),
                                  // Retry Count
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: job.retryCount > 0 ? Colors.orange.shade100 : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                      child: Text(
                                        '${job.retryCount}',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: job.retryCount > 0 ? Colors.orange.shade700 : Colors.grey.shade600),
                                      ),
                                    ),
                                  ),
                                  // Error Message
                                  DataCell(
                                    SizedBox(
                                      width: 250,
                                      child: job.errorMessage.isNotEmpty
                                          ? Text(
                                              job.errorMessage,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              style: const TextStyle(color: Colors.red, fontSize: 12),
                                            )
                                          : const Text('-', style: TextStyle(color: Colors.grey)),
                                    ),
                                  ),
                                  // Actions
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (job.status == 3) // Failed
                                          IconButton(icon: const Icon(Icons.refresh, size: 20), color: Colors.orange, tooltip: 'ลองใหม่', onPressed: () => _retryJob(job)),
                                        if (job.status == 2 || job.status == 3)
                                          IconButton(icon: const Icon(Icons.delete_outline, size: 20), color: Colors.red, tooltip: 'ลบ', onPressed: () => _deleteJob(job)),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    Color chipColor;

    switch (value) {
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'printing':
        chipColor = Colors.blue;
        break;
      case 'completed':
        chipColor = Colors.green;
        break;
      case 'failed':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return FilterChip(
      label: Text(
        '$label ($count)',
        style: TextStyle(color: isSelected ? Colors.white : chipColor, fontWeight: FontWeight.bold, fontSize: 13),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      selectedColor: chipColor,
      backgroundColor: chipColor.withOpacity(0.1),
      checkmarkColor: Colors.white,
      side: BorderSide(color: chipColor, width: isSelected ? 2 : 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
