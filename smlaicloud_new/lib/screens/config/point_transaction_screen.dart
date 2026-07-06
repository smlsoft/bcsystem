import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smlaicloud/bloc/point_transaction/point_transaction_bloc.dart';
import 'package:smlaicloud/model/point_transaction_model.dart';
import 'package:smlaicloud/global.dart' as global;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:intl/intl.dart';

class PointTransactionScreen extends StatefulWidget {
  final String debtorCode;
  final String debtorName;
  final String pointsCode;

  const PointTransactionScreen({
    Key? key,
    required this.debtorCode,
    required this.debtorName,
    required this.pointsCode,
  }) : super(key: key);

  @override
  State<PointTransactionScreen> createState() => _PointTransactionScreenState();
}

class _PointTransactionScreenState extends State<PointTransactionScreen> {
  List<PointTransactionModel> transactions = [];
  bool loadingData = false;

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  void loadTransactions() {
    context.read<PointTransactionBloc>().add(
      PointTransactionLoadByDebtorCode(debtorCode: widget.pointsCode),
    );
  }

  String getTransactionTypeText(int type) {
    switch (type) {
      case 1:
        return 'ได้รับแต้ม';
      case 2:
        return 'ใช้แต้ม';
      default:
        return 'ไม่ทราบ';
    }
  }

  Color getTransactionTypeColor(int type) {
    switch (type) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget transactionListItem(PointTransactionModel transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    transaction.transactiondocno,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getTransactionTypeColor(transaction.transactiontype),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    getTransactionTypeText(transaction.transactiontype),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd/MM/yyyy HH:mm:ss').format(transaction.transactiondate),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('รหัสแต้ม: ${transaction.pointscode}'),
                Text(
                  '${transaction.pointamount > 0 ? '+' : ''}${transaction.pointamount}',
                  style: TextStyle(
                    color: getTransactionTypeColor(transaction.transactiontype),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ยอดก่อน: ${transaction.balancebefore}'),
                Text('ยอดหลัง: ${transaction.balanceafter}'),
              ],
            ),
            if (transaction.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                transaction.description,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: global.theme.appBarColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ประวัติการใช้แต้ม'),
            Text(
              '${widget.debtorCode} - ${widget.debtorName}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadTransactions,
          ),
        ],
      ),
      body: BlocListener<PointTransactionBloc, PointTransactionState>(
        listener: (context, state) {
          if (state is PointTransactionLoadSuccess) {
            setState(() {
              loadingData = false;
              transactions = state.transactions;
            });
          }
          if (state is PointTransactionLoadFailed) {
            setState(() {
              loadingData = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('เกิดข้อผิดพลาด: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is PointTransactionInProgress) {
            setState(() {
              loadingData = true;
            });
          }
        },
        child: Column(
          children: [
            if (loadingData)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.blue,
                    size: 50,
                  ),
                ),
              ),
            if (!loadingData && transactions.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'ไม่พบประวัติการใช้แต้ม',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            if (!loadingData && transactions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    return transactionListItem(transactions[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
