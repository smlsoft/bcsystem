import 'package:dedekiosk/model/kiosk_list_model.dart';
import 'package:dedekiosk/model/shop_list_model.dart';
import 'package:dedekiosk/service/user_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'list_kiosk_event.dart';
part 'list_kiosk_state.dart';

class ListKioskBloc extends Bloc<ListKioskEvent, ListKioskState> {
  final UserRepository _userRepository;

  ListKioskBloc({required UserRepository userRepository})
      : _userRepository = userRepository,
        super(ListKioskInitial()) {
    on<ListKioskLoad>(_onListKioskLoad);
  }

  void _onListKioskLoad(ListKioskLoad event, Emitter<ListKioskState> emit) async {
    emit(ListKioskInProgress());
    try {
      final result = await _userRepository.getKioskList();
      final resultsetting = await _userRepository.getSettingList();
      // print(_result.data);

      if (result.success && resultsetting.success) {
        List<KioskListModel> kiosk = (result.data as List).map((kiosk) => KioskListModel.fromJson(kiosk)).toList();
        List<KioskListModel> setting = (resultsetting.data as List).map((kiosk) => KioskListModel.fromJson(kiosk)).toList();
        // print(_shop.toString());
        List<KioskListModel> kioskMapList = [];

        for (var i = 0; i < kiosk.length; i++) {
          var matchedSettings = setting.where((s) => s.guidfixed == kiosk[i].settingcode).toList();

          if (matchedSettings.isNotEmpty) {
            List<String> emailList = [];
            matchedSettings.forEach((element) {
              element.emails.forEach((email) {
                emailList.add(email);
              });
            });

            List<String> uniqueEmailList = emailList.toSet().toList();
            if (kiosk[i].activepin.isEmpty) {
              kioskMapList.add(KioskListModel(
                guidfixed: kiosk[i].guidfixed,
                code: kiosk[i].code,
                settingcode: kiosk[i].settingcode,
                emails: uniqueEmailList,
                activepin: kiosk[i].activepin,
                devicenumber: kiosk[i].devicenumber,
                devicetype: kiosk[i].devicetype,
                docformat: kiosk[i].docformat,
                isposactive: kiosk[i].isposactive,
              ));
            }
          }
        }

        emit(ListKioskLoadSuccess(kiosk: kioskMapList));
      } else {
        emit(const ListKioskLoadFailed(message: 'Kiosk Not Found'));
      }
    } catch (e) {
      emit(ListKioskLoadFailed(message: e.toString()));
    }
  }
}
