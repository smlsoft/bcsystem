import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/global_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kapi/models/qr_transaction_response.dart';
import 'package:kapi/smlkapi.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/core/logger/app_logger.dart';

class SmlQrPage extends StatefulWidget {
  const SmlQrPage({super.key});

  @override
  State<SmlQrPage> createState() => _SmlQrPageState();
}

class _SmlQrPageState extends State<SmlQrPage> {
  TextEditingController searchController = TextEditingController();
  List<ProfileQrPaymentModel> providerList = [];
  ProfileQrPaymentModel? selectedProvider;
  List<QRTransactionResponse> transactionList = [];
  final Color _themeColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);

  // Pagination variables
  int currentPage = 0;
  final int pageSize = 10;
  bool isLoading = false;
  bool hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (global.posConfig.qrcodes!.isNotEmpty) {
      global.posConfig.qrcodes!.forEach((element) {
        if (element.qrtype == 301) {
          providerList.add(element);
        }
      });
    }
    if (providerList.isNotEmpty) {
      selectedProvider = providerList.first;
      getDataList(refresh: true);
    }

    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // Scroll listener for detecting when to load more data
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 && !isLoading && hasMoreData) {
      getDataList();
    }
  }

  void getDataList({bool refresh = false}) async {
    if (isLoading) return;

    if (refresh) {
      setState(() {
        currentPage = 0;
        transactionList = [];
        hasMoreData = true;
      });
    }

    setState(() {
      isLoading = true;
    });

    // Implement your data fetching logic here
    if (selectedProvider != null) {
      try {
        SMLKBankConnector smlKApiConnector = SMLKBankConnector(apiKey: selectedProvider?.apikey ?? "", uatMode: false);

        final value = await smlKApiConnector.ListTransaction(page: currentPage, size: pageSize);

        setState(() {
          if (value.isNotEmpty) {
            transactionList.addAll(value);
            currentPage++;
          } else {
            hasMoreData = false;
          }
          isLoading = false;
        });
      } catch (error) {
        // Handle error
        AppLogger.debug(error);
        setState(() {
          isLoading = false;
        });
        // Optional: Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $error')));
      }
    }
  }

  // Helper function for status color
  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'success':
      case 'PAID':
        return Colors.green;
      case 'REQUESTED':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper function for status icon
  IconData getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'success':
      case 'PAID':
        return Icons.check_circle;
      case 'REQUESTED':
        return Icons.pending;
      case 'failed':
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _themeColor,
          title: const Text("SML QR Payment"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => getDataList(refresh: true))],
        ),
        body: Column(
          children: [
            // Horizontal scrollable card-based provider selection
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  alignment: WrapAlignment.start,
                  children: providerList.map((provider) {
                    final isSelected = selectedProvider == provider;

                    return SizedBox(
                      width: 220,
                      height: 130,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedProvider = provider;
                            getDataList(refresh: true);
                          });
                        },
                        child: Card(
                          elevation: isSelected ? 4.0 : 1.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            side: BorderSide(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2.0),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) : null, borderRadius: BorderRadius.circular(10.0)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.payment, size: 28.0, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey),
                                const SizedBox(height: 8.0),
                                Text(
                                  provider.bankcode + '~' + provider.bookbankcode + '\n' + global.getNameFromLanguage(provider.bookbanknames!, global.userScreenLanguage),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 15.0, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Theme.of(context).colorScheme.primary : null),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Expanded(
              child: transactionList.isEmpty && !isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('ไม่พบรายการธุรกรรม', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(onPressed: () => getDataList(refresh: true), icon: const Icon(Icons.refresh), label: const Text('ลองอีกครั้ง')),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        getDataList(refresh: true);
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8.0),
                        itemCount: transactionList.length + (isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == transactionList.length) {
                            return const Center(
                              child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
                            );
                          }

                          final transaction = transactionList[index];
                          DateTime parsedDate = DateTime.parse(transaction.UpdatedAt);
                          DateTime localDate = parsedDate.add(Duration(hours: 7));
                          // Format currency
                          final formatter = NumberFormat("#,##0.00", "th_TH");
                          final formattedAmount = formatter.format(double.parse(transaction.amount.toString()));

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12.0),
                              onTap: () {
                                // Show detailed transaction info
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('รายละเอียดธุรกรรม'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _detailRow('Transaction ID:', transaction.txnUid ?? '-'),
                                          _detailRow('จำนวนเงิน:', '฿$formattedAmount'),
                                          _detailRow('วันที่-เวลา:', DateFormat('dd/MM/yyyy HH:mm:ss').format(localDate)),
                                          _detailRow('สถานะ:', transaction.paymentStatus ?? '-'),
                                          // Add more details as needed
                                        ],
                                      ),
                                    ),
                                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด'))],
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${transaction.txnUid}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: getStatusColor(transaction.paymentStatus ?? '').withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: getStatusColor(transaction.paymentStatus ?? ''), width: 1),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(getStatusIcon(transaction.paymentStatus ?? ''), size: 16, color: getStatusColor(transaction.paymentStatus ?? '')),
                                              const SizedBox(width: 4),
                                              Text(
                                                transaction.paymentStatus ?? 'ไม่ทราบสถานะ',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: getStatusColor(transaction.paymentStatus ?? '')),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(DateFormat('dd/MM/yyyy HH:mm').format(localDate), style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                                          ],
                                        ),
                                        Text(
                                          '฿$formattedAmount',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for transaction details dialog
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
