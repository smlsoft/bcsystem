import 'package:dedecashier/bloc/bill_bloc.dart';
import 'package:dedecashier/db/bill_helper.dart';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/model/objectbox/bill_struct.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/global.dart' as global;

// ⭐ Theme Colors: MARINEPOS = น้ำเงินเข้ม, อื่นๆ = อิฐบ้านเชียง (Terracotta)
final Color _themeColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);

class PosCancelBillDetailScreen extends StatefulWidget {
  final global.PosScreenModeEnum posScreenMode;
  final String docNumber;

  @override
  const PosCancelBillDetailScreen({super.key, required this.docNumber, required this.posScreenMode});

  @override
  State<PosCancelBillDetailScreen> createState() => _PosCancelBillDetailScreenState();
}

class _PosCancelBillDetailScreenState extends State<PosCancelBillDetailScreen> {
  BillObjectBoxStruct bill = BillObjectBoxStruct(
    date_time: DateTime.now(),
    doc_number: "",
    trancsaction_id: "",
    paypointamount: 0,
    shift_doc_no: "",
    is_cancel: false,
    table_open_date_time: DateTime.now(),
    table_close_date_time: DateTime.now(),
    is_sync: false,
    is_vat_register: false,
    vat_type: 0,
    vat_rate: 0,
    total_qty: 0,
    total_item_vat_amount: 0,
    total_item_except_vat_amount: 0,
    discount_formula: "",
    total_discount: 0,
    total_discount_from_promotion: 0,
    total_discount_vat_amount: 0,
    total_discount_except_vat_amount: 0,
    amount_before_calc_vat: 0,
    amount_after_calc_vat: 0,
    amount_except_vat: 0,
    total_amount: 0,
    total_vat_amount: 0,
    sale_code: "",
    sale_name: "",
    cashier_code: "",
    cashier_name: "",
    pay_cash_amount: 0,
    pay_cash_change: 0,
    sum_qr_code: 0,
    sum_credit_card: 0,
    sum_money_transfer: 0,
    pointdiscountamount: 0,
    point_balance_after: 0,
    sum_cheque: 0,
    sum_coupon: 0,
    sum_credit: 0,
    full_vat_print: false,
    full_vat_doc_number: "",
    full_vat_name: "",
    full_vat_address: "",
    full_vat_tax_id: "",
    full_vat_branch_number: "",
    print_copy_bill_date_time: [],
    doc_mode: 0,
    bill_tax_type: 0,
    customer_code: "",
    customer_name: "",
    customer_telephone: "",
    is_delivery: false,
    delivery_code: "",
    delivery_number: "",
    guidpos: "",
    promotion_json: "",
    promotion_bottom_json: "",
    promotion_bonus_json: "",
    promotion_coupon_json: "",
    detail_discount_formula: "",
    detail_total_amount: 0,
    detail_total_discount: 0,
    round_amount: 0,
    total_amount_after_discount: 0,
    detail_total_amount_before_discount: 0,
    food_amount: 0,
    beverage_amount: 0,
    cancel_date_time: "",
    cancel_description: "",
    cancel_user_code: "",
    cancel_user_name: "",
    cancel_reason: "",
    table_number: "",
    man_count: 0,
    woman_count: 0,
    child_count: 0,
    table_al_la_crate_mode: false,
    buffet_code: "",
    pay_json: "",
    getpoint: 0,
    usepoint: 0,
    couponcashamount: 0,
    coupondiscountamount: 0,
    coupons_json: "",
  );

  TextEditingController cancelDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<BillBloc>().add(BillLoadByDocNumber(docNumber: widget.docNumber, posScreenMode: widget.posScreenMode));
  }

  @override
  void dispose() {
    cancelDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillBloc, BillState>(
      builder: (context, state) {
        if (state is BillLoadByDocNumberSuccess) {
          if (state.bill != null) {
            bill = state.bill!;
          }
          context.read<BillBloc>().add(BillLoadByDocNumberFinish());
        }
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: _themeColor,
            title: Text(
              global.language("cancel_bill_detail"),
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: bill.is_cancel ? [Colors.red.shade50, Colors.red.shade100] : [Colors.orange.shade50, Colors.orange.shade100],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: bill.is_cancel ? Colors.red : Colors.orange, borderRadius: BorderRadius.circular(10)),
                            child: Icon(bill.is_cancel ? Icons.cancel : Icons.warning, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bill.is_cancel ? 'บิลถูกยกเลิกแล้ว' : 'บิลยังไม่ได้ยกเลิก',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: bill.is_cancel ? Colors.red.shade800 : Colors.orange.shade800),
                                ),
                                const SizedBox(height: 4),
                                Text('เลขที่: ${bill.doc_number}', style: TextStyle(fontSize: 14, color: bill.is_cancel ? Colors.red.shade600 : Colors.orange.shade600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Cancel Form (only show if not cancelled)
                  if (!bill.is_cancel) ...[
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.edit_note, color: _themeColor, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'เหตุผลการยกเลิก',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _themeColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: cancelDescriptionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'กรุณาระบุเหตุผลในการยกเลิกบิล...',
                                hintStyle: TextStyle(color: Colors.grey.shade500),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: _themeColor, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.cancel, size: 20),
                                label: Text(global.language("cancel_bill"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                onPressed: () {
                                  global.playSound(sound: global.SoundEnum.buttonTing);
                                  _showCancelConfirmDialog();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Bill Details
                  posBillDetail(docNumber: widget.docNumber),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCancelConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.warning, color: Colors.red.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(global.language("cancel_bill"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('คุณต้องการยกเลิกบิลนี้หรือไม่?', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.receipt, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'เลขที่บิล: ${bill.doc_number}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              if (cancelDescriptionController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_note, color: Colors.orange.shade700, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'เหตุผล:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(cancelDescriptionController.text, style: TextStyle(fontSize: 14, color: Colors.orange.shade800)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                global.playSound(sound: global.SoundEnum.buttonTing);
                Navigator.of(context).pop();
              },
              child: Text(
                global.language("cancel"),
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                global.playSound(sound: global.SoundEnum.buttonTing);
                bill.is_cancel = true;
                BillHelper().updatesIsCancel(docNumber: bill.doc_number, description: cancelDescriptionController.text, value: true);
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Back to cancel bill list
                Navigator.of(context).pop(); // Back to main menu
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, size: 16),
                  const SizedBox(width: 6),
                  Text(global.language("confirm"), style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
