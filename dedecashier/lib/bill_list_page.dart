import 'dart:io';
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BillListPage extends StatefulWidget {
  const BillListPage({super.key});

  @override
  BillListPageState createState() => BillListPageState();
}

class BillListPageState extends State<BillListPage> {
  final Color _themeColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      AppLogger.debug('[BillList] 📱 Page initialized');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      AppLogger.debug('[BillList] 🔨 Building BillListPage');
    }
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: _themeColor,
          title: Text(global.language("bill_list"), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: FutureBuilder<List<File>>(
          future: global.getSavedBillImages(),
          builder: (BuildContext context, AsyncSnapshot<List<File>> snapshot) {
            if (kDebugMode) {
              AppLogger.debug('[BillList] 📡 FutureBuilder state: ${snapshot.connectionState}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              if (kDebugMode) {
                AppLogger.debug('[BillList] ⏳ Loading images...');
              }
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              if (kDebugMode) {
                AppLogger.error('[BillList] ❌ Error: ${snapshot.error}');
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              if (kDebugMode) {
                AppLogger.debug('[BillList] 📭 No images found');
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No bills found',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text('Bills will appear here after printing', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                  ],
                ),
              );
            } else {
              final imageFiles = snapshot.data!;

              if (kDebugMode) {
                AppLogger.success('[BillList] ✅ Loaded ${imageFiles.length} images');
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    spacing: 16.0,
                    runSpacing: 16.0,
                    children: imageFiles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final imageFile = entry.value;
                      return SizedBox(width: (MediaQuery.of(context).size.width - 80) / 4, child: _buildBillCard(context, imageFile, index));
                    }).toList(),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildBillCard(BuildContext context, File imageFile, int index) {
    final dateTime = imageFile.lastModifiedSync();
    final formattedDate = DateFormat('dd MMM yyyy').format(dateTime);
    final formattedTime = DateFormat('HH:mm').format(dateTime);

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _showImageDialog(context, imageFile);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image thumbnail - full size
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(color: Colors.grey[200]),
              child: Image.file(imageFile, fit: BoxFit.contain),
            ),
            // Date & Time info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(formattedTime, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, File imageFile) {
    final dateTime = imageFile.lastModifiedSync();
    final formattedDate = DateFormat('dd MMMM yyyy').format(dateTime);
    final formattedTime = DateFormat('HH:mm').format(dateTime);
    final fileName = imageFile.path.split(Platform.pathSeparator).last;

    if (kDebugMode) {
      AppLogger.debug('[BillList] 🖼️ Opening image: $fileName');
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              // Full-screen interactive image viewer with padding
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 80.0),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: InteractiveViewer(
                          panEnabled: true,
                          boundaryMargin: const EdgeInsets.all(20),
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Image.file(imageFile, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Top bar with close button and info
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.7), Colors.transparent]),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        fileName,
                                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                                    const SizedBox(width: 6),
                                    Text(formattedDate, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.access_time, color: Colors.white70, size: 14),
                                    const SizedBox(width: 6),
                                    Text(formattedTime, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom hint text
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Pinch to zoom',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.touch_app, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Tap to close',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
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
}
