import 'package:dedecashier/bloc/bill_bloc.dart';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/model/objectbox/bill_struct.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_cancel_bill_detail.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/global.dart' as global;

// ⭐ Theme Colors: MARINEPOS = น้ำเงินเข้ม, อื่นๆ = อิฐบ้านเชียง (Terracotta)
final Color _themeColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);

class PosCancelBillScreen extends StatefulWidget {
  final global.PosScreenModeEnum posScreenMode;

  @override
  const PosCancelBillScreen({super.key, required this.posScreenMode});

  @override
  State<PosCancelBillScreen> createState() => _PosCancelBillScreenState();
}

class _PosCancelBillScreenState extends State<PosCancelBillScreen> {
  List<BillObjectBoxStruct> dataList = [];
  List<BillObjectBoxStruct> filteredDataList = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    context.read<BillBloc>().add(BillLoad(posScreenMode: widget.posScreenMode));
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
          return bill.doc_number.toLowerCase().contains(query.toLowerCase()) || bill.customer_name.toLowerCase().contains(query.toLowerCase());
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
          if (filteredDataList.isEmpty && searchController.text.isEmpty) {
            filteredDataList = dataList;
          }
          isLoading = false;
        }
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              global.language("cancel_bill"),
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            backgroundColor: _themeColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: _filterBills,
                  decoration: InputDecoration(
                    hintText: 'ค้นหาเลขที่บิล หรือชื่อลูกค้า...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey.shade400),
                            onPressed: () {
                              global.playSound(sound: global.SoundEnum.buttonTing);
                              searchController.clear();
                              _filterBills('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(color: _themeColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredDataList.isEmpty
                    ? _buildEmptyState()
                    : _buildBillGrid(),
              ),
            ],
          ),
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
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(searchController.text.isNotEmpty ? Icons.search_off : Icons.receipt_long, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            searchController.text.isNotEmpty ? 'ไม่พบบิลที่ค้นหา' : 'ไม่มีบิลที่สามารถยกเลิกได้',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(searchController.text.isNotEmpty ? 'ลองค้นหาด้วยคำอื่น' : 'บิลทั้งหมดจะแสดงที่นี่', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          if (searchController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                searchController.clear();
                _filterBills('');
              },
              icon: const Icon(Icons.clear),
              label: const Text('ล้างการค้นหา'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.grey.shade700, elevation: 0),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillGrid() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 2;
          if (constraints.maxWidth > 600) {
            crossAxisCount = 3;
          }
          if (constraints.maxWidth > 900) {
            crossAxisCount = 4;
          }
          if (constraints.maxWidth > 1200) {
            crossAxisCount = 5;
          }

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, childAspectRatio: 1.1, crossAxisSpacing: 6, mainAxisSpacing: 6),
            itemCount: filteredDataList.length,
            itemBuilder: (context, index) {
              final bill = filteredDataList[index];
              return _buildBillCard(bill);
            },
          );
        },
      ),
    );
  }

  Widget _buildBillCard(BillObjectBoxStruct bill) {
    final bool isCancelled = bill.is_cancel;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            global.playSound(sound: global.SoundEnum.buttonTing);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PosCancelBillDetailScreen(docNumber: bill.doc_number, posScreenMode: widget.posScreenMode),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isCancelled ? [Colors.red.shade50, Colors.red.shade100] : [Colors.blue.shade50, Colors.blue.shade100],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: isCancelled ? Colors.red : Colors.green, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    isCancelled ? 'ยกเลิกแล้ว' : 'ปกติ',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 8),

                // Bill Content using existing posBill widget
                Expanded(child: posBill(bill)),

                // const SizedBox(height: 8),

                // Action Button
                // Container(
                //   width: double.infinity,
                //   height: 32,
                //   decoration: BoxDecoration(
                //     color: isCancelled
                //         ? Colors.red.withOpacity(0.1)
                //         : (F.appFlavor != Flavor.MARINEPOS)
                //             ? Colors.blue.withOpacity(0.1)
                //             : const Color(0xFF005598).withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(8),
                //     border: Border.all(
                //       color: isCancelled
                //           ? Colors.red.withOpacity(0.3)
                //           : (F.appFlavor != Flavor.MARINEPOS)
                //               ? Colors.blue.withOpacity(0.3)
                //               : const Color(0xFF005598).withOpacity(0.3),
                //     ),
                //   ),
                //   child: Center(
                //     child: Text(
                //       isCancelled ? 'ดูรายละเอียด' : 'ยกเลิกบิล',
                //       style: TextStyle(
                //         color: isCancelled
                //             ? Colors.red.shade700
                //             : (F.appFlavor != Flavor.MARINEPOS)
                //                 ? Colors.blue.shade700
                //                 : const Color(0xFF005598),
                //         fontSize: 12,
                //         fontWeight: FontWeight.w600,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
