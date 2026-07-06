import 'dart:async';
import 'package:dedekiosk/bloc/copy_print_queue_bloc.dart';
import 'package:dedekiosk/model/global_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CopyPrintQueuePage extends StatefulWidget {
  const CopyPrintQueuePage({super.key});

  @override
  CopyPrintQueuePageState createState() => CopyPrintQueuePageState();
}

class CopyPrintQueuePageState extends State<CopyPrintQueuePage> {
  late Timer refreshTimer;
  List<OrderTempModel> copyPrintQueue = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    reload();
    // Auto refresh every 10 seconds
    refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (mounted) {
        reload();
      }
    });
  }

  @override
  void dispose() {
    refreshTimer.cancel();
    super.dispose();
  }

  void reload() {
    if (!mounted) return;
    context.read<CopyPrintQueueBloc>().add(CopyPrintQueueLoadStart());
  }

  void _showMarkAllConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'ยืนยันการอัพเดท',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ต้องการอัพเดทสถานะสำเนาทั้งหมดเป็น "พิมพ์แล้ว" หรือไม่?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF64748B), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'จำนวน ${copyPrintQueue.length} รายการ',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<CopyPrintQueueBloc>().add(CopyPrintQueueMarkAllPrinted());
              },
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
  }

  void _markOnePrinted(OrderTempModel order) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'ทำเครื่องหมายพิมพ์แล้ว',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Text(
            'ต้องการทำเครื่องหมายใบเสร็จเลขที่ ${order.ordernumber} ว่าพิมพ์สำเนาแล้วหรือไม่?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'ยกเลิก',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<CopyPrintQueueBloc>().add(
                      CopyPrintQueueMarkOnePrinted(
                        orderId: order.orderid,
                        orderNumber: order.ordernumber,
                      ),
                    );
              },
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQueueItem(OrderTempModel order, int index) {
    String orderDateTime = DateFormat('dd/MM/yyyy HH:mm').format(order.orderdatetime.add(const Duration(hours: 7)));
    String orderType = order.istakeaway == 0 ? "กินที่ร้าน" : "สั่งกลับบ้าน";
    if (order.salechannelcode.isNotEmpty) {
      orderType = order.salechannelcode;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _markOnePrinted(order),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Queue Number
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Order Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'เลขที่: ${order.ordernumber}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          if (order.queuenumber > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'คิว ${order.queuenumber}',
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            orderDateTime,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: order.istakeaway == 0 ? const Color(0xFFDCFCE7) : const Color(0xFFE0E7FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              orderType,
                              style: TextStyle(
                                color: order.istakeaway == 0 ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (order.ordertagnumber.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'โต๊ะ ${order.ordertagnumber}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '฿${NumberFormat('#,##0.00').format(order.payresult.totalAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.print_disabled, size: 14, color: Color(0xFFEF4444)),
                          SizedBox(width: 4),
                          Text(
                            'รอพิมพ์',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CopyPrintQueueBloc, CopyPrintQueueState>(
      listener: (context, state) {
        if (state is CopyPrintQueueLoadSuccess) {
          setState(() {
            copyPrintQueue = state.copyPrintQueue;
            _isLoading = false;
          });
        } else if (state is CopyPrintQueueLoading) {
          setState(() {
            _isLoading = true;
          });
        } else if (state is CopyPrintQueueMarkAllSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('อัพเดทสถานะสำเนาทั้งหมดสำเร็จ'),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else if (state is CopyPrintQueueMarkAllError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('เกิดข้อผิดพลาด: ${state.message}'),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else if (state is CopyPrintQueueLoadError) {
          setState(() {
            _isLoading = false;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1E293B),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.content_copy, color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'คิวพิมพ์สำเนา',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            // Refresh button
            IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isLoading ? null : reload,
            ),
            // Queue count badge
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: copyPrintQueue.isEmpty ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    copyPrintQueue.isEmpty ? Icons.check_circle : Icons.pending,
                    size: 16,
                    color: copyPrintQueue.isEmpty ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${copyPrintQueue.length}',
                    style: TextStyle(
                      color: copyPrintQueue.isEmpty ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: copyPrintQueue.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ไม่มีรายการรอพิมพ์สำเนา',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'รายการทั้งหมดพิมพ์สำเนาเรียบร้อยแล้ว',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  reload();
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                color: const Color(0xFF6366F1),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 8, bottom: 100),
                  itemCount: copyPrintQueue.length,
                  itemBuilder: (context, index) {
                    return _buildQueueItem(copyPrintQueue[index], index);
                  },
                ),
              ),
        // Floating action button to mark all as printed
        floatingActionButton: copyPrintQueue.isEmpty
            ? null
            : Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: FloatingActionButton.extended(
                  onPressed: _isLoading ? null : _showMarkAllConfirmDialog,
                  backgroundColor: const Color(0xFF10B981),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.done_all, color: Colors.white),
                  label: Text(
                    _isLoading ? 'กำลังอัพเดท...' : 'พิมพ์สำเนาทั้งหมดแล้ว (${copyPrintQueue.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
