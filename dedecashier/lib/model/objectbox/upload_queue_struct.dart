// ignore_for_file: non_constant_identifier_names

import 'package:objectbox/objectbox.dart';

/// สถานะของงาน upload รูปบิล
enum UploadQueueStatus {
  pending(0, 'รอ upload'),
  uploading(1, 'กำลัง upload'),
  completed(2, 'upload แล้ว'),
  failed(3, 'ล้มเหลว');

  final int value;
  final String label;
  const UploadQueueStatus(this.value, this.label);

  static UploadQueueStatus fromValue(int value) {
    return UploadQueueStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => UploadQueueStatus.pending,
    );
  }
}

/// ObjectBox Entity สำหรับ track ไฟล์รูปบิลที่รอ upload
/// ไฟล์จะถูกเก็บไว้ 7 วัน หลังจาก upload สำเร็จ
@Entity()
class UploadQueueObjectBoxStruct {
  /// ID อัตโนมัติ
  int id = 0;

  /// ชื่อไฟล์ (unique) - ชื่อไฟล์ .jpg
  @Unique()
  String fileName;

  /// Path เต็มของไฟล์ .jpg
  String filePath;

  /// เลขที่เอกสาร - สำหรับอ้างอิง
  @Index()
  String docNumber;

  /// สถานะ: 0=รอ upload, 1=กำลัง upload, 2=upload แล้ว, 3=ล้มเหลว
  @Index()
  int status;

  /// วันที่สร้างงาน upload
  @Property(type: PropertyType.date)
  DateTime createdAt;

  /// วันที่ upload เสร็จ (nullable)
  @Property(type: PropertyType.date)
  DateTime? uploadedAt;

  /// จำนวนครั้งที่ retry
  int retryCount;

  /// ข้อความ error (ถ้ามี)
  String errorMessage;

  /// ขนาดไฟล์ (bytes) - สำหรับ monitoring
  int fileSize;

  /// Metadata เพิ่มเติม (JSON string)
  String metadata;

  UploadQueueObjectBoxStruct({
    this.fileName = "",
    this.filePath = "",
    this.docNumber = "",
    this.status = 0, // default: รอ upload
    DateTime? createdAt,
    this.uploadedAt,
    this.retryCount = 0,
    this.errorMessage = "",
    this.fileSize = 0,
    this.metadata = "",
  }) : createdAt = createdAt ?? DateTime.now();

  /// สถานะเป็น enum
  UploadQueueStatus get statusEnum => UploadQueueStatus.fromValue(status);

  /// เช็คว่าเป็นงานที่ล้มเหลวหรือไม่
  bool get isFailed => status == UploadQueueStatus.failed.value;

  /// เช็คว่าพร้อม upload หรือไม่
  bool get isReadyToUpload => status == UploadQueueStatus.pending.value;

  /// เช็คว่า upload เสร็จแล้วหรือไม่
  bool get isCompleted => status == UploadQueueStatus.completed.value;

  /// เช็คว่าไฟล์เก่ากว่า 7 วัน (สำหรับ cleanup)
  bool get isOlderThan7Days {
    if (uploadedAt == null) return false;
    return DateTime.now().difference(uploadedAt!).inDays >= 7;
  }

  /// คำนวณเวลาที่ใช้ในการ upload (milliseconds)
  int? get uploadDuration {
    if (uploadedAt != null) {
      return uploadedAt!.difference(createdAt).inMilliseconds;
    }
    return null;
  }

  /// แปลงเป็น Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'docNumber': docNumber,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'uploadedAt': uploadedAt?.toIso8601String(),
      'retryCount': retryCount,
      'errorMessage': errorMessage,
      'fileSize': fileSize,
      'metadata': metadata,
    };
  }

  /// สร้างจาก Map
  factory UploadQueueObjectBoxStruct.fromMap(Map<String, dynamic> map) {
    return UploadQueueObjectBoxStruct(
      fileName: map['fileName'] ?? '',
      filePath: map['filePath'] ?? '',
      docNumber: map['docNumber'] ?? '',
      status: map['status'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      uploadedAt: map['uploadedAt'] != null
          ? DateTime.parse(map['uploadedAt'])
          : null,
      retryCount: map['retryCount'] ?? 0,
      errorMessage: map['errorMessage'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      metadata: map['metadata'] ?? '',
    )..id = map['id'] ?? 0;
  }

  @override
  String toString() {
    return 'UploadQueue(id: $id, file: $fileName, docNumber: $docNumber, status: ${statusEnum.label}, size: ${_formatBytes(fileSize)})';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
