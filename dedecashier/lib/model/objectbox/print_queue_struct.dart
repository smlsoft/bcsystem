// ignore_for_file: non_constant_identifier_names

import 'package:objectbox/objectbox.dart';

/// สถานะของงานพิมพ์
enum PrintQueueStatus {
  pending(0, 'รอพิมพ์'),
  printing(1, 'กำลังพิมพ์'),
  completed(2, 'พิมพ์แล้ว'),
  failed(3, 'ล้มเหลว');

  final int value;
  final String label;
  const PrintQueueStatus(this.value, this.label);

  static PrintQueueStatus fromValue(int value) {
    return PrintQueueStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PrintQueueStatus.pending,
    );
  }
}

/// ประเภทงานพิมพ์
enum PrintJobType {
  receipt('receipt', 'ใบเสร็จ'),
  kitchen('kitchen', 'ครัว'),
  bill('bill', 'บิล'),
  report('report', 'รายงาน'),
  labelPrint('label', 'ฉลาก');

  final String value;
  final String description;
  const PrintJobType(this.value, this.description);

  static PrintJobType fromValue(String value) {
    return PrintJobType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PrintJobType.receipt,
    );
  }
}

@Entity()
class PrintQueueObjectBoxStruct {
  /// ID อัตโนมัติ
  int id = 0;

  /// ชื่อไฟล์ (unique) - ใช้เป็น key หลักในการอ้างอิง
  @Unique()
  String fileName;

  /// ชื่อเครื่องพิมพ์ - ต้องตรงกับ printerName ใน config
  @Index()
  String printerName;

  /// ประเภทการเชื่อมต่อ: ip, usb, windows, bluetooth, sunmi1
  String printerType;

  /// Path เต็มของไฟล์ PNG
  String filePath;

  /// เลขที่เอกสาร - สำหรับอ้างอิง
  String docNumber;

  /// สถานะ: 0=รอพิมพ์, 1=กำลังพิมพ์, 2=พิมพ์แล้ว, 3=ล้มเหลว
  @Index()
  int status;

  /// วันที่สร้างงานพิมพ์
  @Property(type: PropertyType.date)
  DateTime createdAt;

  /// วันที่พิมพ์เสร็จ (nullable)
  @Property(type: PropertyType.date)
  DateTime? printedAt;

  /// วันที่ลอง retry ล่าสุด (สำหรับ rate limiting)
  @Property(type: PropertyType.date)
  DateTime? lastAttemptAt;

  /// จำนวนครั้งที่ retry
  int retryCount;

  /// ข้อความ error (ถ้ามี)
  String errorMessage;

  /// ประเภทงานพิมพ์: receipt, kitchen, bill, report, label
  String jobType;

  /// Priority สำหรับการเรียงลำดับ (ยิ่งสูงยิ่งพิมพ์ก่อน)
  int priority;

  /// Metadata เพิ่มเติม (JSON string)
  String metadata;

  PrintQueueObjectBoxStruct({
    this.fileName = "",
    this.printerName = "",
    this.printerType = "",
    this.filePath = "",
    this.docNumber = "",
    this.status = 0, // default: รอพิมพ์
    DateTime? createdAt,
    this.printedAt,
    this.lastAttemptAt,
    this.retryCount = 0,
    this.errorMessage = "",
    this.jobType = "receipt",
    this.priority = 0,
    this.metadata = "",
  }) : createdAt = createdAt ?? DateTime.now();

  /// สถานะเป็น enum
  PrintQueueStatus get statusEnum => PrintQueueStatus.fromValue(status);

  /// ประเภทงานเป็น enum
  PrintJobType get jobTypeEnum => PrintJobType.fromValue(jobType);

  /// เช็คว่าเป็นงานที่ล้มเหลวหรือไม่
  bool get isFailed => status == PrintQueueStatus.failed.value;

  /// เช็คว่าพร้อมพิมพ์หรือไม่
  bool get isReadyToPrint => status == PrintQueueStatus.pending.value;

  /// เช็คว่าพิมพ์เสร็จแล้วหรือไม่
  bool get isCompleted => status == PrintQueueStatus.completed.value;

  /// คำนวณเวลาที่ใช้ในการพิมพ์ (milliseconds)
  int? get printDuration {
    if (printedAt != null) {
      return printedAt!.difference(createdAt).inMilliseconds;
    }
    return null;
  }

  /// แปลงเป็น Map สำหรับส่งผ่าน SendPort
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'printerName': printerName,
      'printerType': printerType,
      'filePath': filePath,
      'docNumber': docNumber,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'printedAt': printedAt?.toIso8601String(),
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'retryCount': retryCount,
      'errorMessage': errorMessage,
      'jobType': jobType,
      'priority': priority,
      'metadata': metadata,
    };
  }

  /// สร้างจาก Map
  factory PrintQueueObjectBoxStruct.fromMap(Map<String, dynamic> map) {
    return PrintQueueObjectBoxStruct(
      fileName: map['fileName'] ?? '',
      printerName: map['printerName'] ?? '',
      printerType: map['printerType'] ?? '',
      filePath: map['filePath'] ?? '',
      docNumber: map['docNumber'] ?? '',
      status: map['status'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      printedAt: map['printedAt'] != null
          ? DateTime.parse(map['printedAt'])
          : null,
      lastAttemptAt: map['lastAttemptAt'] != null
          ? DateTime.parse(map['lastAttemptAt'])
          : null,
      retryCount: map['retryCount'] ?? 0,
      errorMessage: map['errorMessage'] ?? '',
      jobType: map['jobType'] ?? 'receipt',
      priority: map['priority'] ?? 0,
      metadata: map['metadata'] ?? '',
    )..id = map['id'] ?? 0;
  }

  @override
  String toString() {
    return 'PrintQueue(id: $id, file: $fileName, printer: $printerName, status: ${statusEnum.label}, doc: $docNumber)';
  }
}
