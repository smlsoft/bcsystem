import 'dart:io';
import 'package:dedecashier/objectbox.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:path_provider/path_provider.dart';

// Import ObjectBox Structs
import 'package:dedecashier/model/objectbox/bank_struct.dart';
import 'package:dedecashier/model/objectbox/bill_struct.dart';
import 'package:dedecashier/model/objectbox/buffet_mode_struct.dart';
import 'package:dedecashier/model/objectbox/coupon_item_struct.dart';
import 'package:dedecashier/model/objectbox/customer_struct.dart';
import 'package:dedecashier/model/objectbox/employees_struct.dart';
import 'package:dedecashier/model/objectbox/form_design_struct.dart';
import 'package:dedecashier/model/objectbox/kitchen_struct.dart';
import 'package:dedecashier/model/objectbox/order_temp_struct.dart';
import 'package:dedecashier/model/objectbox/pos_log_struct.dart';
import 'package:dedecashier/model/objectbox/pos_ticket_struct.dart';
import 'package:dedecashier/model/objectbox/printer_struct.dart';
import 'package:dedecashier/model/objectbox/product_barcode_status_struct.dart';
import 'package:dedecashier/model/objectbox/product_barcode_struct.dart';
import 'package:dedecashier/model/objectbox/product_category_struct.dart';
import 'package:dedecashier/model/objectbox/promotion_struct.dart';
import 'package:dedecashier/model/objectbox/shift_struct.dart';
import 'package:dedecashier/model/objectbox/staff_client_struct.dart';
import 'package:dedecashier/model/objectbox/table_struct.dart';
import 'package:dedecashier/model/objectbox/wallet_struct.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

// ==================== Cubit States ====================

abstract class DatabaseCheckerState {}

class DatabaseCheckerInitial extends DatabaseCheckerState {}

class DatabaseCheckerLoading extends DatabaseCheckerState {
  final String message;
  DatabaseCheckerLoading(this.message);
}

class DatabaseCheckerLoaded extends DatabaseCheckerState {
  final DatabaseCheckReport report;
  DatabaseCheckerLoaded(this.report);
}

class DatabaseCheckerError extends DatabaseCheckerState {
  final String error;
  final String stackTrace;
  DatabaseCheckerError(this.error, this.stackTrace);
}

class DatabaseDeletingState extends DatabaseCheckerState {}

class DatabaseDeletedState extends DatabaseCheckerState {}

// ==================== Cubit ====================

class DatabaseCheckerCubit extends Cubit<DatabaseCheckerState> {
  DatabaseCheckerCubit() : super(DatabaseCheckerInitial());

  Future<void> checkDatabase() async {
    emit(DatabaseCheckerLoading('กำลังวิเคราะห์โครงสร้าง...'));

    try {
      final report = await _performStructureCheck();
      emit(DatabaseCheckerLoaded(report));
    } catch (e, stackTrace) {
      emit(DatabaseCheckerError(e.toString(), stackTrace.toString()));
    }
  }

  Future<DatabaseCheckReport> _performStructureCheck() async {
    final report = DatabaseCheckReport();

    try {
      final model = getObjectBoxModel();
      final modelInfo = model as dynamic;
      final entities = modelInfo.model.entities as List;

      for (final modelEntity in entities) {
        final entityReport = EntityReport(
          name: modelEntity.name,
          id: modelEntity.id.toString(),
        );

        for (final property in modelEntity.properties) {
          entityReport.properties.add(
            PropertyReport(
              name: property.name,
              id: property.id.toString(),
              type: _getPropertyTypeName(property.type),
              status: FieldStatus.matched,
            ),
          );
        }

        // นับจำนวน Records ถ้า Store เปิดอยู่
        if (global.objectBoxStoreInit) {
          try {
            entityReport.recordCount = _getEntityRecordCount(modelEntity.name);
            AppLogger.debug(
              '✅ ${modelEntity.name}: ${entityReport.recordCount} records',
            );
          } catch (e) {
            AppLogger.error('❌ Error counting ${modelEntity.name}: $e');
            entityReport.recordCount = 0;
          }
        } else {
          AppLogger.debug('⚠️ ObjectBox Store not initialized');
        }

        report.entities.add(entityReport);
      }

      if (global.objectBoxStoreInit) {
        final storePath = global.objectBoxStore.directoryPath;
        final dbDir = Directory(storePath);

        if (await dbDir.exists()) {
          report.databasePath = dbDir.path;
          report.databaseExists = true;

          final dataFile = File('${dbDir.path}/data.mdb');
          if (await dataFile.exists()) {
            final stat = await dataFile.stat();
            report.databaseSize = stat.size;
            report.lastModified = stat.modified;
          }
        }
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final dbDir = Directory(
          '${appDir.path}/objectbox${global.shopId}${global.objectBoxVersion}',
        );

        if (await dbDir.exists()) {
          report.databasePath = dbDir.path;
          report.databaseExists = true;

          final dataFile = File('${dbDir.path}/data.mdb');
          if (await dataFile.exists()) {
            final stat = await dataFile.stat();
            report.databaseSize = stat.size;
            report.lastModified = stat.modified;
          }
        }
      }

      report.checkSuccess = true;
    } catch (e) {
      report.checkSuccess = false;
      report.errorMessage = e.toString();
    }

    return report;
  }

  Future<void> deleteDatabase() async {
    emit(DatabaseDeletingState());

    try {
      String? dbPath;

      if (global.objectBoxStoreInit) {
        dbPath = global.objectBoxStore.directoryPath;
        global.objectBoxStore.close();
        global.objectBoxStoreInit = false;
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        dbPath =
            '${appDir.path}/objectbox${global.shopId}${global.objectBoxVersion}';
      }

      final dbDir = Directory(dbPath);
      if (await dbDir.exists()) {
        await dbDir.delete(recursive: true);
        emit(DatabaseDeletedState());
      } else {
        emit(DatabaseCheckerError('ไม่พบฐานข้อมูล', ''));
      }
    } catch (e) {
      emit(DatabaseCheckerError('เกิดข้อผิดพลาด: $e', ''));
    }
  }

  String _getPropertyTypeName(int type) {
    switch (type) {
      case 0:
        return 'Unknown';
      case 1:
        return 'Bool';
      case 2:
        return 'Byte';
      case 3:
        return 'Short';
      case 4:
        return 'Char';
      case 5:
        return 'Int';
      case 6:
        return 'Long';
      case 7:
        return 'Float';
      case 8:
        return 'Double';
      case 9:
        return 'String';
      case 10:
        return 'Date';
      case 11:
        return 'Relation';
      case 12:
        return 'DateNano';
      case 13:
        return 'Flex';
      case 22:
        return 'BoolVector';
      case 23:
        return 'ByteVector';
      case 24:
        return 'ShortVector';
      case 25:
        return 'CharVector';
      case 26:
        return 'IntVector';
      case 27:
        return 'LongVector';
      case 28:
        return 'FloatVector';
      case 29:
        return 'DoubleVector';
      case 30:
        return 'StringVector';
      case 31:
        return 'DateVector';
      case 32:
        return 'DateNanoVector';
      default:
        return 'Type($type)';
    }
  }

  int _getEntityRecordCount(String entityName) {
    try {
      if (!global.objectBoxStoreInit) {
        AppLogger.debug('⚠️ Store not init for: $entityName');
        return 0;
      }

      int count = 0;

      // นับจำนวน records แต่ละ Entity
      switch (entityName) {
        case 'BankObjectBoxStruct':
          count = global.objectBoxStore.box<BankObjectBoxStruct>().count();
          break;
        case 'BillDetailObjectBoxStruct':
          count = global.objectBoxStore
              .box<BillDetailObjectBoxStruct>()
              .count();
          break;
        case 'BillObjectBoxStruct':
          count = global.objectBoxStore.box<BillObjectBoxStruct>().count();
          break;
        case 'BuffetModeObjectBoxStruct':
          count = global.objectBoxStore
              .box<BuffetModeObjectBoxStruct>()
              .count();
          break;
        case 'CouponItemObjectBoxStruct':
          count = global.objectBoxStore
              .box<CouponItemObjectBoxStruct>()
              .count();
          break;
        case 'CustomerObjectBoxStruct':
          count = global.objectBoxStore.box<CustomerObjectBoxStruct>().count();
          break;
        case 'EmployeeObjectBoxStruct':
          count = global.objectBoxStore.box<EmployeeObjectBoxStruct>().count();
          break;
        case 'FormDesignObjectBoxStruct':
          count = global.objectBoxStore
              .box<FormDesignObjectBoxStruct>()
              .count();
          break;
        case 'KitchenObjectBoxStruct':
          count = global.objectBoxStore.box<KitchenObjectBoxStruct>().count();
          break;
        case 'OrderTempObjectBoxStruct':
          count = global.objectBoxStore.box<OrderTempObjectBoxStruct>().count();
          break;
        case 'PosLogObjectBoxStruct':
          count = global.objectBoxStore.box<PosLogObjectBoxStruct>().count();
          break;
        case 'PosTicketObjectBoxStruct':
          count = global.objectBoxStore.box<PosTicketObjectBoxStruct>().count();
          break;
        case 'PrinterObjectBoxStruct':
          count = global.objectBoxStore.box<PrinterObjectBoxStruct>().count();
          break;
        case 'ProductBarcodeStatusObjectBoxStruct':
          count = global.objectBoxStore
              .box<ProductBarcodeStatusObjectBoxStruct>()
              .count();
          break;
        case 'ProductBarcodeObjectBoxStruct':
          count = global.objectBoxStore
              .box<ProductBarcodeObjectBoxStruct>()
              .count();
          break;
        case 'ProductCategoryObjectBoxStruct':
          count = global.objectBoxStore
              .box<ProductCategoryObjectBoxStruct>()
              .count();
          break;
        case 'PromotionObjectBoxStruct':
          count = global.objectBoxStore.box<PromotionObjectBoxStruct>().count();
          break;
        case 'ShiftObjectBoxStruct':
          count = global.objectBoxStore.box<ShiftObjectBoxStruct>().count();
          break;
        case 'StaffClientObjectBoxStruct':
          count = global.objectBoxStore
              .box<StaffClientObjectBoxStruct>()
              .count();
          break;
        case 'TableObjectBoxStruct':
          count = global.objectBoxStore.box<TableObjectBoxStruct>().count();
          break;
        case 'TableProcessObjectBoxStruct':
          count = global.objectBoxStore
              .box<TableProcessObjectBoxStruct>()
              .count();
          break;
        case 'WalletObjectBoxStruct':
          count = global.objectBoxStore.box<WalletObjectBoxStruct>().count();
          break;
        default:
          AppLogger.debug('⚠️ Unknown entity: $entityName');
          count = 0;
      }

      AppLogger.debug('📊 $entityName: $count records');

      return count;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        AppLogger.error('❌ Error counting records for $entityName: $e');
        AppLogger.debug('Stack trace: $stackTrace');
      }
      return 0;
    }
  }
}

// ==================== UI Widget ====================

class DatabaseCheckerDialog {
  static const String _secretCode = '19682511';

  static void show(BuildContext context, {VoidCallback? onDatabaseDeleted}) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider(
        create: (context) => DatabaseCheckerCubit(),
        child: _DatabaseCheckerDialogContent(
          onDatabaseDeleted: onDatabaseDeleted,
        ),
      ),
    );
  }
}

class _DatabaseCheckerDialogContent extends StatelessWidget {
  final VoidCallback? onDatabaseDeleted;

  const _DatabaseCheckerDialogContent({this.onDatabaseDeleted});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DatabaseCheckerCubit>();

    return BlocConsumer<DatabaseCheckerCubit, DatabaseCheckerState>(
      listener: (context, state) {
        if (state is DatabaseDeletedState) {
          Navigator.of(context).pop();

          // ⭐ เรียก callback ถ้ามี
          if (onDatabaseDeleted != null) {
            onDatabaseDeleted!();
            return; // ออกทันที ไม่แสดง dialog ที่ 2
          }

          // ถ้าไม่มี callback ให้แสดง dialog แบบเดิม
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(global.language('สำเร็จ')),
                ],
              ),
              content: Text(
                global.language('ลบฐานข้อมูลเรียบร้อย\nโปรแกรมจะปิดทันที'),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => exit(0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(global.language('OK')),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is DatabaseCheckerInitial) {
          return _SecretCodeDialog(onConfirm: () => cubit.checkDatabase());
        }

        if (state is DatabaseCheckerLoading) {
          return _LoadingDialog(message: state.message);
        }

        if (state is DatabaseDeletingState) {
          return _LoadingDialog(message: 'กำลังลบฐานข้อมูล...');
        }

        if (state is DatabaseCheckerLoaded) {
          return _DatabaseReportDialog(
            report: state.report,
            onDelete: () => _showDeleteConfirmation(context, cubit),
          );
        }

        if (state is DatabaseCheckerError) {
          return _ErrorDialog(error: state.error, stackTrace: state.stackTrace);
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    DatabaseCheckerCubit cubit,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade700,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                global.language('ลบฐานข้อมูล'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200, width: 2),
              ),
              child: Text(
                global.language(
                  'การดำเนินการนี้จะลบ ObjectBox Database ทั้งหมด และโปรแกรมจะปิดทันที\n\nคุณต้องการดำเนินการต่อหรือไม่?',
                ),
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(global.language('ยกเลิก')),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.deleteDatabase();
            },
            icon: const Icon(Icons.delete_forever, size: 20),
            label: Text(global.language('ยืนยันลบ')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Sub Widgets ====================

class _SecretCodeDialog extends StatefulWidget {
  final VoidCallback onConfirm;

  const _SecretCodeDialog({required this.onConfirm});

  @override
  State<_SecretCodeDialog> createState() => _SecretCodeDialogState();
}

class _SecretCodeDialogState extends State<_SecretCodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storage, color: Colors.blue, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  global.language('Database Checker'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Field Comparison Tool',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      global.language('กรุณาใส่รหัสพิเศษเพื่อดำเนินการ'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              obscureText: true,
              decoration: InputDecoration(
                labelText: global.language('รหัสพิเศษ'),
                hintText: 'Enter secret code',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onSubmitted: (_) => _checkCode(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(global.language('Cancel')),
        ),
        ElevatedButton.icon(
          onPressed: _checkCode,
          icon: const Icon(Icons.search, size: 20),
          label: Text(global.language('Check Now')),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _checkCode() {
    if (_controller.text == DatabaseCheckerDialog._secretCode) {
      widget.onConfirm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text(global.language('รหัสพิเศษไม่ถูกต้อง')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }
}

class _LoadingDialog extends StatelessWidget {
  final String message;

  const _LoadingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _DatabaseReportDialog extends StatelessWidget {
  final DatabaseCheckReport report;
  final VoidCallback onDelete;

  const _DatabaseReportDialog({required this.report, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.95,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          children: [
            _buildHeader(context),
            _buildInfoBar(),
            Expanded(child: _buildComparisonTable(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.storage, color: Colors.blue.shade700, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Database Structure Comparison',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Shop: ${global.shopId} • Ver: ${global.objectBoxVersion} • Total: ${report.entities.length} Entities',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            tooltip: 'Delete Database',
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    // คำนวณจำนวน Records รวม
    int totalRecords = 0;
    for (final entity in report.entities) {
      totalRecords += entity.recordCount;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoChip(
            Icons.folder,
            'Path',
            report.databaseExists ? 'Exists' : 'Not Found',
            report.databaseExists ? Colors.green : Colors.red,
          ),
          _buildInfoChip(
            Icons.storage,
            'Size',
            '${(report.databaseSize / (1024 * 1024)).toStringAsFixed(1)} MB',
            Colors.blue,
          ),
          _buildInfoChip(
            Icons.description,
            'Records',
            totalRecords > 0 ? '$totalRecords rows' : 'N/A',
            Colors.purple,
          ),
          _buildInfoChip(
            Icons.access_time,
            'Modified',
            report.lastModified != null
                ? '${report.lastModified!.day}/${report.lastModified!.month}/${report.lastModified!.year}'
                : 'N/A',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: report.entities.length,
      itemBuilder: (context, index) {
        final entity = report.entities[index];
        return _EntityCard(entity: entity, key: ValueKey(entity.name));
      },
    );
  }
}

class _EntityCard extends StatelessWidget {
  final EntityReport entity;

  const _EntityCard({required this.entity, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: [_buildEntityHeader(), _buildEntityTable()]),
    );
  }

  Widget _buildEntityHeader() {
    // Debug: แสดงค่า recordCount
    AppLogger.debug(
      '🎨 UI Building: ${entity.name} with ${entity.recordCount} records',
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.table_chart, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              entity.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: entity.recordCount > 0
                  ? Colors.orange.shade600
                  : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storage, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${entity.recordCount} records',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${entity.properties.length} fields',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntityTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(20),
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
        headingRowHeight: 56,
        dataRowHeight: 56,
        columnSpacing: 24,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        columns: const [
          DataColumn(
            label: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'Field Name',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text('ใน DB', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'ใน Program',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: List.generate(entity.properties.length, (idx) {
          final prop = entity.properties[idx];
          return DataRow(
            cells: [
              DataCell(Text('${idx + 1}')),
              DataCell(
                Text(
                  prop.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(Text(prop.id)),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(prop.type),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    prop.type,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              DataCell(
                Icon(
                  prop.status == FieldStatus.newInProgram
                      ? Icons.close
                      : Icons.check_circle,
                  color: prop.status == FieldStatus.newInProgram
                      ? Colors.red
                      : Colors.green,
                  size: 24,
                ),
              ),
              DataCell(
                Icon(
                  prop.status == FieldStatus.removedFromProgram
                      ? Icons.close
                      : Icons.check_circle,
                  color: prop.status == FieldStatus.removedFromProgram
                      ? Colors.red
                      : Colors.green,
                  size: 24,
                ),
              ),
              DataCell(_buildStatusBadge(prop.status)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStatusBadge(FieldStatus status) {
    IconData icon;
    Color color;
    String label;

    switch (status) {
      case FieldStatus.matched:
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'OK';
        break;
      case FieldStatus.newInProgram:
        icon = Icons.add_circle;
        color = Colors.blue;
        label = 'NEW';
        break;
      case FieldStatus.removedFromProgram:
        icon = Icons.remove_circle;
        color = Colors.red;
        label = 'REMOVED';
        break;
      case FieldStatus.typeMismatch:
        icon = Icons.warning;
        color = Colors.orange;
        label = 'MISMATCH';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    if (type.contains('Long') || type.contains('Int')) {
      return Colors.blue.shade600;
    } else if (type.contains('String')) {
      return Colors.green.shade600;
    } else if (type.contains('Double') || type.contains('Float')) {
      return Colors.orange.shade600;
    } else if (type.contains('Bool')) {
      return Colors.purple.shade600;
    } else if (type.contains('Date')) {
      return Colors.red.shade600;
    } else if (type.contains('Vector')) {
      return Colors.teal.shade600;
    } else {
      return Colors.grey.shade600;
    }
  }
}

class _ErrorDialog extends StatelessWidget {
  final String error;
  final String stackTrace;

  const _ErrorDialog({required this.error, required this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 32),
          const SizedBox(width: 12),
          const Text(
            'Error Occurred',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(child: Text(error)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// ==================== Data Classes ====================

class DatabaseCheckReport {
  bool checkSuccess = false;
  String errorMessage = '';
  List<EntityReport> entities = [];
  List<FieldDifference> differences = [];
  String databasePath = '';
  bool databaseExists = false;
  int databaseSize = 0;
  DateTime? lastModified;
}

class EntityReport {
  final String name;
  final String id;
  List<PropertyReport> properties = [];
  int recordCount = 0;
  EntityReport({required this.name, required this.id});
}

class PropertyReport {
  final String name;
  final String id;
  final String type;
  final FieldStatus status;
  PropertyReport({
    required this.name,
    required this.id,
    required this.type,
    required this.status,
  });
}

class FieldDifference {
  final String entityName;
  final String fieldName;
  final FieldStatus status;
  final String dbType;
  final String programType;
  FieldDifference({
    required this.entityName,
    required this.fieldName,
    required this.status,
    required this.dbType,
    required this.programType,
  });
}

enum FieldStatus { matched, newInProgram, removedFromProgram, typeMismatch }
