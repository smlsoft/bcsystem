import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/model/json/member_model.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/core/logger/app_logger.dart';

class FindMemberByTelNameLoadStart extends FindMemberByTelNameEvent {
  final String words;
  final int offset;
  final int limit;

  FindMemberByTelNameLoadStart({
    required this.words,
    required this.offset,
    required this.limit,
  });
}

class FindMemberByTelNameLoadSuccess extends FindMemberByTelNameState {
  List<MemberModel> result;

  FindMemberByTelNameLoadSuccess({required this.result});
}

class FindMemberByTelNameBloc
    extends Bloc<FindMemberByTelNameEvent, FindMemberByTelNameState> {
  final ApiRepository apiFindMemberByTelName;

  final int? offset;
  final int? limit;

  FindMemberByTelNameBloc({
    required this.apiFindMemberByTelName,
    this.offset,
    this.limit,
  }) : super(FindMemberByTelNameInitial()) {
    on<FindMemberByTelNameLoadStart>(_findMemberByTelName);
    on<FindMemberByTelNameLoadFinish>(_findMemberByTelNameLoadFinish);
  }
  void _findMemberByTelName(
    FindMemberByTelNameLoadStart event,
    Emitter<FindMemberByTelNameState> emit,
  ) async {
    emit(FindMemberByTelNameLoading());

    try {
      List<MemberModel> result = [];

      // ลองดึงข้อมูลจาก API ก่อนถ้า online
      if (global.isOnline) {
        AppLogger.debug('Online mode: fetching customer from API...');
        try {
          result = await apiFindMemberByTelName.findMemberByTelName(
            event.words,
            event.offset,
            event.limit,
          );
          AppLogger.debug('Found ${result.length} customers from API');
        } catch (e) {
          AppLogger.error(
            'API call failed: $e, falling back to local database...',
          );
        }
      } else {
        AppLogger.debug('Offline mode: using local database...');
      }

      // ถ้าไม่พบข้อมูลจาก API หรือไม่ online ให้ดึงจาก local database
      if (result.isEmpty) {
        AppLogger.debug(
          'No customers found from API, checking local database...',
        );
        result = await _findMemberFromLocal(
          event.words,
          event.offset,
          event.limit,
        );
        AppLogger.debug('Found ${result.length} customers from local database');
      }

      emit(FindMemberByTelNameLoadSuccess(result: result));
    } catch (e) {
      AppLogger.error('Error finding member: $e');
      emit(FindMemberByTelNameLoadSuccess(result: []));
    }
  }

  /// ค้นหาลูกค้าจาก local database
  Future<List<MemberModel>> _findMemberFromLocal(
    String searchText,
    int offset,
    int limit,
  ) async {
    try {
      // ใช้ CustomerHelper ในการค้นหา
      final customers = global.customerHelper.findByTelName(searchText);

      // แปลงจาก CustomerObjectBoxStruct เป็น MemberModel
      List<MemberModel> result = [];
      for (var customer in customers) {
        result.add(
          MemberModel(
            code: customer.code,
            guidfixed: customer.guidfixed,
            pointbalance: customer.pointbalance,
            pointscode: customer.pointscode,
            email: customer.email,
            names: [LanguageDataModel(code: 'th', name: customer.name)],
            addressforbilling: MemberAddressForBillingModel(
              address: [customer.address],
              phoneprimary: customer.tel,
              phonesecondary: '',
              contactnames: [
                LanguageDataModel(code: 'th', name: customer.name),
              ],
            ),
          ),
        );
      }

      // จำกัดจำนวนผลลัพธ์ตาม offset และ limit
      if (offset < result.length) {
        int endIndex = (offset + limit < result.length)
            ? offset + limit
            : result.length;
        return result.sublist(offset, endIndex);
      }

      return [];
    } catch (e) {
      AppLogger.error('Error finding member from local database: $e');
      return [];
    }
  }

  void _findMemberByTelNameLoadFinish(
    FindMemberByTelNameLoadFinish event,
    Emitter<FindMemberByTelNameState> emit,
  ) async {
    emit(FindMemberByTelNameLoadStop());
  }
}

abstract class FindMemberByTelNameEvent {}

class FindMemberByTelNameLoadFinish extends FindMemberByTelNameEvent {}

abstract class FindMemberByTelNameState {}

class FindMemberByTelNameInitial extends FindMemberByTelNameState {}

class FindMemberByTelNameLoading extends FindMemberByTelNameState {}

class FindMemberByTelNameLoaded extends FindMemberByTelNameState {}

class FindMemberByTelNameFound extends FindMemberByTelNameState {}

class FindMemberByTelNameNotFound extends FindMemberByTelNameState {}

class FindMemberByTelNameLoadStop extends FindMemberByTelNameState {}
