import 'package:dedecashier/bloc/bill_bloc.dart';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/model/objectbox/bill_struct.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_reprint_bill_detail.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/global.dart' as global;

class PosReprintBillScreen extends StatefulWidget {
  final global.PosScreenModeEnum posScreenMode;

  @override
  const PosReprintBillScreen({super.key, required this.posScreenMode});

  @override
  State<PosReprintBillScreen> createState() => _PosReprintBillScreenState();
}

class _PosReprintBillScreenState extends State<PosReprintBillScreen> {
  List<BillObjectBoxStruct> dataList = [];
  List<BillObjectBoxStruct> filteredDataList = [];
  final TextEditingController searchController = TextEditingController();

  final Color _themeColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);
  @override
  void initState() {
    super.initState();
    context.read<BillBloc>().add(BillLoad(posScreenMode: widget.posScreenMode));

    // Add listener to search controller for real-time UI updates
    searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterBills(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredDataList = dataList;
      } else {
        filteredDataList = dataList.where((bill) {
          return bill.doc_number.toLowerCase().contains(query.toLowerCase()) || bill.date_time.toString().toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillBloc, BillState>(
      builder: (context, state) {
        if (state is BillLoadSuccess) {
          context.read<BillBloc>().add(BillLoadFinish());
          dataList = state.result;
          filteredDataList = state.result; // Initialize filtered list
        }

        // Loading state
        if (state is BillLoading) {
          return Scaffold(
            appBar: AppBar(
              title: Text(global.language("reprint_bill"), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
              backgroundColor: _themeColor,
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_themeColor, _themeColor]),
                ),
              ),
            ),
            backgroundColor: Colors.grey[50],
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(global.language("reprint_bill"), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
            backgroundColor: _themeColor,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_themeColor, _themeColor]),
              ),
            ),
          ),
          backgroundColor: Colors.grey[50],
          body: dataList.isEmpty && filteredDataList.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(child: _buildBillList()),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final isSearching = searchController.text.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSearching ? Icons.search_off : Icons.receipt_long, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'ไม่พบบิลที่ค้นหา' : 'ไม่มีบิลที่สามารถพิมพ์ซ้ำได้',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(isSearching ? 'ลองค้นหาด้วยคำอื่น' : 'บิลที่พิมพ์ซ้ำได้จะแสดงที่นี่', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildBillList() {
    return Padding(
      padding: const EdgeInsets.all(12), // ลดจาก 16 เป็น 12
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive grid - เพิ่มจำนวน columns เพื่อให้กล่องเล็กลง
          int crossAxisCount = constraints.maxWidth > 1200
              ? 5 // เพิ่มจาก 6 เป็น 8
              : constraints.maxWidth > 800
              ? 4 // เพิ่มจาก 4 เป็น 6
              : constraints.maxWidth > 600
              ? 3 // เพิ่มจาก 3 เป็น 4
              : 2; // เพิ่มจาก 2 เป็น 3

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.2, // เปลี่ยนจาก 0.75 เป็น 1.2 เพื่อให้กล่องเตี้ยลง
              crossAxisSpacing: 6, // ลดจาก 12 เป็น 8
              mainAxisSpacing: 6, // ลดจาก 12 เป็น 8
            ),
            itemCount: filteredDataList.length,
            itemBuilder: (context, index) => _buildBillCard(index),
          );
        },
      ),
    );
  }

  Widget _buildBillCard(int index) {
    final bill = filteredDataList[index];
    final isCancel = bill.is_cancel;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 1, blurRadius: 8, offset: const Offset(0, 2))],
        border: isCancel ? Border.all(color: Colors.red.shade300, width: 2) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            global.playSound(sound: global.SoundEnum.buttonTing);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PosReprintBillDetailScreen(posScreenMode: widget.posScreenMode, docNumber: bill.doc_number),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8), // ลดจาก 12 เป็น 8
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status indicator
                Row(
                  children: [
                    Icon(
                      isCancel ? Icons.cancel : Icons.receipt,
                      color: isCancel ? Colors.red : Colors.blue,
                      size: 16, // ลดจาก 20 เป็น 16
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        isCancel ? 'ยกเลิก' : 'ปกติ',
                        style: TextStyle(
                          color: isCancel ? Colors.red : Colors.blue,
                          fontSize: 10, // ลดจาก 12 เป็น 10
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4), // ลดจาก 8 เป็น 4
                // Bill content
                Expanded(child: posBill(bill)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: TextField(
          controller: searchController,
          onChanged: _filterBills,
          decoration: InputDecoration(
            hintText: "ค้นหาบิล (เลขที่บิล หรือ วันที่)",
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      global.playSound(sound: global.SoundEnum.buttonTing);
                      searchController.clear();
                      _filterBills('');
                    },
                    icon: Icon(Icons.clear, color: Colors.grey[500]),
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
