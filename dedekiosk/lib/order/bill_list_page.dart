import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dedekiosk/bloc/server_trans_bloc.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/print/print.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class BillListPage extends StatefulWidget {
  const BillListPage({Key? key}) : super(key: key);

  @override
  BillListPageState createState() => BillListPageState();
}

class BillListPageState extends State<BillListPage> {
  static const Duration _bangkokOffset = Duration(hours: 7);
  late DateTime _fromBangkokDate;
  late DateTime _toBangkokDate;

  @override
  void initState() {
    super.initState();
    final now = _getBangkokNow();
    _fromBangkokDate = DateTime(now.year, now.month, now.day);
    _toBangkokDate = DateTime(now.year, now.month, now.day);
    _loadBillsByDateRange();
  }

  DateTime _getBangkokNow() {
    return DateTime.now().toUtc().add(_bangkokOffset);
  }

  DateTime _bangkokDateToUtcStart(DateTime bangkokDate) {
    return DateTime.utc(bangkokDate.year, bangkokDate.month, bangkokDate.day).subtract(_bangkokOffset);
  }

  DateTime _bangkokDateToUtcEnd(DateTime bangkokDate) {
    return DateTime.utc(
      bangkokDate.year,
      bangkokDate.month,
      bangkokDate.day,
      23,
      59,
      59,
      999,
    ).subtract(_bangkokOffset);
  }

  void _loadBillsByDateRange() {
    context.read<ServerTransBloc>().add(
          ServerTransLoadStart(
            fromDate: _bangkokDateToUtcStart(_fromBangkokDate),
            toDate: _bangkokDateToUtcEnd(_toBangkokDate),
          ),
        );
  }

  Future<void> _selectFromDate() async {
    final DateTime bangkokNow = _getBangkokNow();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromBangkokDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(bangkokNow.year + 1, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _fromBangkokDate = DateTime(picked.year, picked.month, picked.day);
        // ถ้า fromDate หลัง toDate ให้ reset toDate ตาม
        if (_fromBangkokDate.isAfter(_toBangkokDate)) {
          _toBangkokDate = _fromBangkokDate;
        }
      });
      _loadBillsByDateRange();
    }
  }

  Future<void> _selectToDate() async {
    final DateTime bangkokNow = _getBangkokNow();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toBangkokDate,
      firstDate: _fromBangkokDate,
      lastDate: DateTime(bangkokNow.year + 1, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _toBangkokDate = DateTime(picked.year, picked.month, picked.day);
      });
      _loadBillsByDateRange();
    }
  }

  Widget _buildServerBillCard(dynamic billData) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBillDialog(serverBillData: billData),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: billData.slipurl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFFF1F5F9),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long, size: 32, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 4),
                        Text(
                          billData.docno ?? '',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      billData.docno ?? '',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.touch_app, size: 12, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBillDialog({File? localFile, dynamic serverBillData}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    Text(
                      global.language("bill_list"),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Image
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: localFile != null
                      ? Image.file(localFile, fit: BoxFit.contain)
                      : CachedNetworkImage(
                          imageUrl: serverBillData.slipurl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                          ),
                          errorWidget: (context, url, error) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
                              const SizedBox(height: 8),
                              Text(
                                global.language("network_error"),
                                style: const TextStyle(color: Color(0xFFEF4444)),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              // Actions
              if (serverBillData != null && global.deviceConfig.machineCondition == 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        try {
                          PrinterClass printer = PrinterClass(
                            printerIndex: 1,
                            qrCode: "",
                            openCashDrawer: false,
                          );
                          await printer.sendToPrinterByImageUrl(
                            printerData: global.deviceConfig.printerForOrderStation,
                            imageUrl: serverBillData.slipurl,
                          );
                        } catch (e, s) {
                          if (kDebugMode) {
                            print(e);
                            print(s);
                          }
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: Text(
                        global.language("reprint"),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // If can't pop, go back to main page
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            }
          },
        ),
        title: Text(
          global.language("bill_list"),
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6366F1)),
            onPressed: () {
              _loadBillsByDateRange();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Server mode only - use BlocConsumer
    return BlocConsumer<ServerTransBloc, ServerTransState>(
      listener: (context, state) {
        if (state is ServerTransLoadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ServerTransLoading) {
          return Column(
            children: [
              _buildDateSelector(),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                ),
              ),
            ],
          );
        }

        if (state is ServerTransLoadSuccess) {
          final bills = state.data;
          if (bills.isEmpty) {
            return Column(
              children: [
                _buildDateSelector(),
                Expanded(child: _buildEmptyState()),
              ],
            );
          }
          return Column(
            children: [
              _buildDateSelector(),
              Expanded(
                child: _buildBillGrid(
                  itemCount: bills.length,
                  itemBuilder: (context, index) => _buildServerBillCard(bills[index]),
                ),
              ),
            ],
          );
        }

        if (state is ServerTransLoadError) {
          return Column(
            children: [
              _buildDateSelector(),
              Expanded(child: _buildErrorState(state.message)),
            ],
          );
        }
        return Column(
          children: [
            _buildDateSelector(),
            Expanded(child: _buildEmptyState()),
          ],
        );
      },
    );
  }

  Widget _buildDateSelector() {
    final fmt = DateFormat('dd/MM/yyyy');
    final fromText = fmt.format(_fromBangkokDate);
    final toText = fmt.format(_toBangkokDate);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Color(0xFF6366F1), size: 20),
          const SizedBox(width: 8),
          // From date
          GestureDetector(
            onTap: _selectFromDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF6366F1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("จาก ", style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  Text(fromText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_calendar, size: 14, color: Color(0xFF6366F1)),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text("–", style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
          ),
          // To date
          GestureDetector(
            onTap: _selectToDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF6366F1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("ถึง ", style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  Text(toText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_calendar, size: 14, color: Color(0xFF6366F1)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillGrid({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth < 400) {
          crossAxisCount = 2;
        } else if (constraints.maxWidth < 600) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth < 1200) {
          crossAxisCount = 5;
        } else {
          crossAxisCount = 6;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.75,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long,
              size: 48,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            global.language("no_data"),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 48,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            global.language("error"),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () {
              _loadBillsByDateRange();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(global.language("retry")),
          ),
        ],
      ),
    );
  }
}
