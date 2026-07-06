import 'dart:async';
import 'package:dedecashier/api/network/websocket_client.dart' as ws_client;
import 'package:dedecashier/model/objectbox/pos_log_struct.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/objectbox.g.dart';

class PosLogHelper {
  /// ✅ WebSocket: Insert POS log
  /// แทนที่ HTTP POST ด้วย WebSocket real-time
  Future<int> insert(PosLogObjectBoxStruct value) async {
    if (global.appMode == global.AppModeEnum.posRemote) {
      // ✅ ใหม่: ส่งผ่าน WebSocket
      ws_client.WebSocketClient().send({
        'type': 'pos_log',
        'action': 'insert',
        'data': value.toJson(),
      });

      // ⚠️ WebSocket ไม่ต้องรอ response แบบ blocking
      // Server จะส่ง acknowledgment กลับมาทาง message handler
      return 0;
    } else {
      return global.objectBoxStore.box<PosLogObjectBoxStruct>().put(
        value,
        mode: PutMode.insert,
      );
    }
  }

  /// ✅ WebSocket: Get hold count
  Future<int> holdCount(String holdCode) async {
    if (global.appMode == global.AppModeEnum.posRemote) {
      // ✅ ใหม่: Request ผ่าน WebSocket
      ws_client.WebSocketClient().sendCommand('PosLogHelper.holdCount', {
        'holdCode': holdCode,
      });

      // TODO: Implement response handler to get actual count
      // สำหรับตอนนี้ return 0 หรือใช้ cached value
      return 0;
    } else {
      final allRecords = global.objectBoxStore
          .box<PosLogObjectBoxStruct>()
          .query(
            PosLogObjectBoxStruct_.hold_code
                .equals(holdCode)
                .and(PosLogObjectBoxStruct_.is_void.equals(0)),
          )
          .build()
          .find();

      final deletedGuids = allRecords
          .where((record) => record.command_code == 9)
          .map((record) => record.guid_ref)
          .toSet();

      return allRecords
          .where(
            (record) =>
                record.command_code == 1 &&
                !deletedGuids.contains(record.guid_auto_fixed),
          )
          .length;
    }
  }

  /// ✅ WebSocket: Select by GUID
  Future<List<PosLogObjectBoxStruct>> selectByGuidFixed(
    String guidAutoFixed,
  ) async {
    if (global.appMode == global.AppModeEnum.posRemote) {
      // ✅ ใหม่: Request ผ่าน WebSocket
      ws_client.WebSocketClient().sendCommand(
        'PosLogHelper.selectByGuidFixed',
        {'guid': guidAutoFixed},
      );

      // TODO: Implement response handler to get actual data
      return [];
    } else {
      return (global.objectBoxStore.box<PosLogObjectBoxStruct>().query(
        PosLogObjectBoxStruct_.guid_auto_fixed.equals(guidAutoFixed),
      )..order(PosLogObjectBoxStruct_.log_date_time)).build().find();
    }
  }

  /// ✅ WebSocket: Select by hold code
  Future<List<PosLogObjectBoxStruct>> selectByHoldCode(String holdCode) async {
    if (global.appMode == global.AppModeEnum.posRemote) {
      // ✅ ใหม่: Request ผ่าน WebSocket
      ws_client.WebSocketClient().sendCommand('PosLogHelper.selectByHoldCode', {
        'holdCode': holdCode,
      });

      // TODO: Implement response handler to get actual data
      return [];
    } else {
      return global.objectBoxStore
          .box<PosLogObjectBoxStruct>()
          .query(PosLogObjectBoxStruct_.hold_code.equals(holdCode))
          .build()
          .find();
    }
  }

  List<PosLogObjectBoxStruct> selectByGuidRefHoldCodeCommandCode({
    required String guidRef,
    required int commandCode,
    required String holdCode,
  }) {
    return global.objectBoxStore
        .box<PosLogObjectBoxStruct>()
        .query(
          PosLogObjectBoxStruct_.guid_ref.equals(guidRef) &
              PosLogObjectBoxStruct_.hold_code.equals(holdCode) &
              PosLogObjectBoxStruct_.command_code.equals(commandCode),
        )
        .build()
        .find();
  }

  bool deleteByGuidRefHoldCodeCommandCode({
    required String guidRef,
    required int commandCode,
    required String holdCode,
  }) {
    bool result = false;
    final find = global.objectBoxStore
        .box<PosLogObjectBoxStruct>()
        .query(
          PosLogObjectBoxStruct_.guid_ref.equals(guidRef) &
              PosLogObjectBoxStruct_.hold_code.equals(holdCode) &
              PosLogObjectBoxStruct_.command_code.equals(commandCode),
        )
        .build()
        .findFirst();
    if (find != null) {
      result = global.objectBoxStore.box<PosLogObjectBoxStruct>().remove(
        find.id,
      );
    }
    return result;
  }

  bool deleteByGuidCodeRefHoldCodeCommandCode({
    required String guidCode,
    required int commandCode,
    required String holdCode,
  }) {
    bool result = false;
    final find = global.objectBoxStore
        .box<PosLogObjectBoxStruct>()
        .query(
          PosLogObjectBoxStruct_.guid_code_ref.equals(guidCode) &
              PosLogObjectBoxStruct_.hold_code.equals(holdCode) &
              PosLogObjectBoxStruct_.command_code.equals(commandCode),
        )
        .build()
        .findFirst();
    if (find != null) {
      result = global.objectBoxStore.box<PosLogObjectBoxStruct>().remove(
        find.id,
      );
    }
    return result;
  }

  /// ✅ WebSocket: Delete by hold code
  Future<int> deleteByHoldCode({required String holdCode}) async {
    if (global.appMode == global.AppModeEnum.posRemote) {
      // ✅ ใหม่: ส่งผ่าน WebSocket
      ws_client.WebSocketClient().send({
        'type': 'pos_log',
        'action': 'deleteByHoldCode',
        'data': {'holdCode': holdCode},
      });
      return 0;
    } else {
      // เป็นเครื่อง POS Terminal
      final ids = global.objectBoxStore
          .box<PosLogObjectBoxStruct>()
          .query(PosLogObjectBoxStruct_.hold_code.equals(holdCode))
          .build()
          .findIds();
      return global.objectBoxStore.box<PosLogObjectBoxStruct>().removeMany(ids);
    }
  }
}
