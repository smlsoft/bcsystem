import 'dart:async';
import 'dart:io';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/api/sync/master/sync_master.dart';
import 'package:dedecashier/api/sync/sync_bill.dart';
import 'package:dedecashier/bill_list_page.dart';
import 'package:dedecashier/db/buffet_mode_helper.dart';
import 'package:dedecashier/db/shift_helper.dart';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_screen.dart';
import 'package:dedecashier/features/pos/presentation/screens/sale_summary_page.dart';
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/shift_struct.dart';
import 'package:dedecashier/services/printer_config.dart';
import 'package:dedecashier/services/customer_sync_service.dart';
import 'package:dedecashier/sml_qr_page.dart';
import 'package:dedecashier/util/barcode_checker.dart';
import 'package:dedecashier/util/connect_staff_client.dart';
import 'package:dedecashier/util/employee_change_password_page.dart';
import 'package:dedecashier/util/printer.dart';
import 'package:dedecashier/util/select_language_screen.dart';
import 'package:dedecashier/core/performance/app_performance_manager.dart';
import 'package:dedecashier/widgets/button.dart';
import 'package:dedecashier/widgets/numpad.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:flutter/services.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_shadow/simple_shadow.dart';
import 'package:uuid/uuid.dart';
import 'package:dedecashier/core/logger/app_logger.dart';
import 'package:dedecashier/features/pos/presentation/screens/print_queue_viewer.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // ⭐ Theme Colors: MARINEPOS = น้ำเงินเข้ม, อื่นๆ = อิฐบ้านเชียง (Terracotta)
  static final Color _themeColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);
  static final Color _themeColorDark = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF003D6E) : const Color(0xFF7F4513);
  static final MaterialColor _themeSwatch = (F.appFlavor == Flavor.MARINEPOS)
      ? const MaterialColor(0xFF005598, <int, Color>{
          50: Color(0xFFE6EFF5),
          100: Color(0xFFB3D1E6),
          200: Color(0xFF80B3D7),
          300: Color(0xFF4D95C8),
          400: Color(0xFF2677B9),
          500: Color(0xFF005598),
          600: Color(0xFF004A85),
          700: Color(0xFF003D6E),
          800: Color(0xFF003057),
          900: Color(0xFF002340),
        })
      : const MaterialColor(0xFFB5651D, <int, Color>{
          50: Color(0xFFFBF5F0),
          100: Color(0xFFF5E6D8),
          200: Color(0xFFEAC9AC),
          300: Color(0xFFDEAB7F),
          400: Color(0xFFD18D52),
          500: Color(0xFFB5651D),
          600: Color(0xFF9A5518),
          700: Color(0xFF7F4513),
          800: Color(0xFF64350E),
          900: Color(0xFF4A2509),
        });

  ApiRepository apiRepository = ApiRepository();
  List<Widget> menuPosList = [];
  List<Widget> menuShiftList = [];
  List<Widget> menuVisitList = [];
  List<Widget> menuUtilList = [];
  TextEditingController receiveAmount = TextEditingController();
  TextEditingController empCode = TextEditingController();
  TextEditingController userCode = TextEditingController();
  TextEditingController password = TextEditingController();
  bool loadConfigSuccess = false;
  var appBarHeight = AppBar().preferredSize.height;
  String appVersion = "";
  final FlutterThermalPrinter _flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;

  // ⭐ Performance Fix #1: Cached language strings
  late String _posScreenText;
  late String _posReturnText;
  late String _billListText;
  late String _smlQrListText;
  late String _openShiftText;
  late String _closeShiftText;
  late String _addChangeText;
  late String _withdrawText;
  late String _saleSummaryText;
  late String _barcodeCheckerText;
  late String _printerConfigText;
  late String _printTestText;
  late String _syncMasterText;
  late String _syncBillText;
  late String _printerIsNotReadyText;
  late String _syncingDataText;
  late String _pleaseWaitText;
  late String _syncFailedText;
  late String _syncDataErrorText;
  late String _noInternetText;
  late String _pleaseCheckInternetText;
  late String _changePasswordText;
  late String _logoutText;
  late String _printQueueText;

  // ⭐ Performance Fix #1.1: Additional cached strings
  late String _connectStaffClientText;
  late String _setGpsLocationText;
  late String _takeShopPhotoText;
  late String _takeProductPhotoText;

  // ⭐ Performance Fix #2: Cached computed values
  String? _cachedCompanyName;
  String? _cachedBranchName;
  bool _isLoadingCustomers = false;

  // ⭐ Performance Fix #1: Initialize language strings once
  void _initializeLanguageStrings() {
    AppLogger.debug('[Performance] Initializing language strings...');

    _posScreenText = global.language("pos_screen");
    _posReturnText = global.language("pos_return_screen");
    _billListText = global.language("pos_list_bill");
    _smlQrListText = global.language("pos_sml_qr_list");
    _openShiftText = global.language("open_shift");
    _closeShiftText = global.language("close_shift");
    _addChangeText = global.language("add_change_money");
    _withdrawText = global.language("withdraw_money");
    _saleSummaryText = global.language("sale_summary");
    _barcodeCheckerText = global.language("barcodechecker");
    _printerConfigText = global.language("printer_config");
    _printTestText = global.language("print_test");
    _syncMasterText = global.language("sync_master");
    _syncBillText = global.language("sync_bill");
    _printerIsNotReadyText = global.language("printer_is_not_ready");
    _syncingDataText = global.language("syncing_data");
    _pleaseWaitText = global.language("please_wait");
    _syncFailedText = global.language("sync_failed");
    _syncDataErrorText = global.language("sync_data_error");
    _noInternetText = global.language("no_internet_connection");
    _pleaseCheckInternetText = global.language("please_check_your_internet_connection");
    _changePasswordText = global.language('change_password');
    _logoutText = global.language('logout');
    _printQueueText = "สถานะงานพิมพ์";

    // ⭐ Performance Fix #1.1: Additional strings
    _connectStaffClientText = global.language("connect_staff_client");
    _setGpsLocationText = global.language("set_gps_location");
    _takeShopPhotoText = global.language("take_shop_photo");
    _takeProductPhotoText = global.language("take_product_photo");
  }

  // ⭐ Performance Fix #7: Update cached names
  void _updateCachedNames() {
    if (loadConfigSuccess && global.profileSetting.branch.isNotEmpty) {
      var branchList = global.profileSetting.branch.where((element) => element.guidfixed == global.posConfig.branch.guidfixed);
      if (branchList.isNotEmpty) {
        ProfileSettingBranchModel branchModel = branchList.first;
        if (branchModel.names.isNotEmpty) {
          _cachedBranchName = global.getNameFromLanguage(branchModel.names, global.userScreenLanguage);
        }
      }
      _cachedCompanyName = global.getNameFromLanguage(global.profileSetting.company.names, global.userScreenLanguage);
    }
  }

  List<Widget> menuForVisit() {
    // ⭐ Performance Fix #1.1: Use cached strings for SMLMOBILESALES flavor
    return [
      menuItem(
        icon: Icons.list_alt_outlined,
        title: _setGpsLocationText, // ⭐ Fix: Use cached string
        callBack: () {},
      ),
      menuItem(
        icon: Icons.list_alt_outlined,
        title: _takeShopPhotoText, // ⭐ Fix: Use cached string
        callBack: () {},
      ),
      menuItem(
        icon: Icons.list_alt_outlined,
        title: _takeProductPhotoText, // ⭐ Fix: Use cached string
        callBack: () {},
      ),
    ];
  }

  List<Widget> menuPos() {
    if (F.appFlavor != Flavor.MARINEPOS) {
      return [
        menuItem(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/point-of-sale.png'),
          title: _posScreenText, // ⭐ Fix: Use cached string
          callBack: () async {
            global.playSound(sound: global.SoundEnum.buttonTing);
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen(posScreenMode: global.PosScreenModeEnum.posSale)));
            sendCommandToSecondScreen();
          },
        ),
        menuItem(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/return-box.png'),
          title: _posReturnText, // ⭐ Fix: Use cached string
          callBack: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen(posScreenMode: global.PosScreenModeEnum.posReturn)));
            sendCommandToSecondScreen();
          },
        ),
        menuItem(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/images/albums.png'),
          title: _billListText, // ⭐ Fix: Use cached string
          callBack: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const BillListPage()));
          },
        ),
        menuItem(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/images/generate_qrcode.png'),
          title: _smlQrListText, // ⭐ Fix: Use cached string
          callBack: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const SmlQrPage()));
          },
        ),
      ];
    } else {
      return [
        menuItemMarine(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/marine-icon-pos.png'),
          callBack: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen(posScreenMode: global.PosScreenModeEnum.posSale)));
            sendCommandToSecondScreen();
          },
        ),
        menuItemMarine(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/marine-icon-return.png'),
          callBack: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const PosScreen(posScreenMode: global.PosScreenModeEnum.posReturn)));
            sendCommandToSecondScreen();
          },
        ),
        menuItemMarine(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/marine-icon-history.png'),
          callBack: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const BillListPage()));
          },
        ),
      ];
    }
  }

  // Future<void> showDialogShiftAndMoney(int mode) async {
  //   /// Mode (1=เปิดกะ+เงินทอน, 2=ปิดกะ+ส่งเงิน, 3=เติมเงินทอน, 4=นำเงินออก)
  //   ///
  //   SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  //   global.shiftAndMoneyMode = sharedPreferences.getInt('shift_and_money_mode') ?? 0;

  //   if (global.shiftAndMoneyMode == 1) {
  //     if (mode == 1) {
  //       if (mounted) {
  //         global.showAlertDialog(context: context, title: global.language("open_the_cash_register_and_change"), message: global.language("please_close_shift"));
  //         return;
  //       }
  //     }
  //   } else if (global.shiftAndMoneyMode == 2) {
  //     if (mode == 2) {
  //       if (mounted) {
  //         global.showAlertDialog(context: context, title: global.language("close_the_shift"), message: global.language("please_open_shift"));
  //         return;
  //       }
  //     } else if (mode == 3) {
  //       if (mounted) {
  //         global.showAlertDialog(context: context, title: global.language("replenish_change"), message: global.language("please_open_shift"));
  //       }
  //       return;
  //     } else if (mode == 4) {
  //       if (mounted) {
  //         global.showAlertDialog(context: context, title: global.language("take_out_money"), message: global.language("please_open_shift"));
  //         return;
  //       }
  //     }
  //   }
  //   if (mounted) {
  //     await showDialog(
  //         barrierDismissible: false,
  //         context: context,
  //         builder: (BuildContext context) {
  //           return AlertDialog(
  //               insetPadding: const EdgeInsets.all(0),
  //               contentPadding: const EdgeInsets.all(0),
  //               backgroundColor: Colors.transparent,
  //               content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
  //                 return shiftAndMoneyScreen(mode: mode);
  //               }));
  //         });

  //     // รีเฟรชหน้าจอหลังจากปิด dialog เพื่ออัปเดตสถานะกะ
  //     if (mounted) {
  //       setState(() {});
  //     }
  //   }
  // }

  Future<void> showDialogShiftAndMoney(int mode) async {
    /// Mode (1=เปิดกะ+เงินทอน, 2=ปิดกะ+ส่งเงิน, 3=เติมเงินทอน, 4=นำเงินออก)

    try {
      final lastOpenShift = global.shiftHelper.getLastOpenShift(global.posConfig.code);
      final bool hasOpenShift = lastOpenShift != null;

      if (hasOpenShift) {
        global.shiftAndMoneyMode = 1; // มีกะเปิดอยู่
      } else {
        global.shiftAndMoneyMode = 2; // ไม่มีกะเปิด
      }

      if (hasOpenShift) {
        if (mode == 1) {
          if (mounted) {
            global.showAlertDialog(
              context: context,
              title: global.language("open_the_cash_register_and_change"),
              message: "มีกะของ ${lastOpenShift.username} เปิดอยู่แล้ว กรุณาปิดกะก่อน",
            );
            return;
          }
        }
      } else {
        if (mode == 2) {
          if (mounted) {
            global.showAlertDialog(context: context, title: global.language("close_the_shift"), message: global.language("please_open_shift"));
            return;
          }
        } else if (mode == 3) {
          if (mounted) {
            global.showAlertDialog(context: context, title: global.language("replenish_change"), message: global.language("please_open_shift"));
            return;
          }
        } else if (mode == 4) {
          if (mounted) {
            global.showAlertDialog(context: context, title: global.language("take_out_money"), message: global.language("please_open_shift"));
            return;
          }
        }
      }

      if (mounted) {
        await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              insetPadding: const EdgeInsets.all(0),
              contentPadding: const EdgeInsets.all(0),
              backgroundColor: Colors.transparent,
              content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return shiftAndMoneyScreen(mode: mode, context: context);
                },
              ),
            );
          },
        );

        if (mounted) {
          setState(() {
            final updatedOpenShift = global.shiftHelper.getLastOpenShift(global.posConfig.code);
            if (updatedOpenShift != null) {
              global.shiftAndMoneyMode = 1; // มีกะเปิดอยู่
            } else {
              global.shiftAndMoneyMode = 2; // ไม่มีกะเปิด
            }
          });
        }
      }
    } catch (e) {
      AppLogger.error("Error checking shift status: $e");

      if (mounted) {
        global.showAlertDialog(context: context, title: "ข้อผิดพลาด", message: "ไม่สามารถตรวจสอบสถานะกะได้ กรุณาลองใหม่อีกครั้ง");
      }
    }
  }

  Widget shiftAndMoneyScreen({required int mode, required BuildContext context}) {
    TextEditingController remarkTextEditingController = TextEditingController();
    TextStyle textStyle = const TextStyle(fontSize: 12);
    String header = "";
    switch (mode) {
      case 1:
        header = global.language("open_the_cash_register_and_change"); // "เปิดกะ+เงินทอน";
        break;
      case 2:
        header = global.language("close_the_shift"); // "ปิดกะ+ส่งเงิน";
        break;
      case 3:
        header = global.language("replenish_change"); // "เติมเงินทอน";
        break;
      case 4:
        header = global.language("take_out_money"); // "นำเงินออก";
        break;
    }
    return Container(
      width: 350,
      height: 600,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.5), spreadRadius: 5, blurRadius: 7)],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _themeSwatch[100]!,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.5), spreadRadius: 2, blurRadius: 2)],
            ),
            child: Center(
              child: Text(
                header,
                style: textStyle.copyWith(
                  shadows: <Shadow>[const Shadow(offset: Offset(1.0, 1.0), blurRadius: 3.0, color: Colors.grey)],
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Table(
                    columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
                    children: [
                      TableRow(
                        children: [
                          Text(global.language("employee_code"), style: textStyle),
                          Text(global.userLogin!.code, style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      TableRow(
                        children: [
                          Text(global.language("employee_name"), style: textStyle),
                          Text(global.userLogin!.name, style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      TableRow(
                        children: [
                          Text(global.language("date"), style: textStyle),
                          Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()), style: textStyle.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (mode == 2 || mode == 4)
                    TextField(
                      controller: remarkTextEditingController,
                      style: textStyle,
                      decoration: InputDecoration(border: const OutlineInputBorder(), hintText: global.language("remark")),
                    ),
                  if (mode == 2 || mode == 4) const SizedBox(height: 5),
                  if (mode == 3 || mode == 4)
                    Expanded(
                      child: NumberPad(
                        header: global.language("amount_of_money"),
                        onChange: (value) async {
                          double amount = double.tryParse(value) ?? 0; // กด ตกลง
                          if (amount != 0) {
                            String guid = const Uuid().v4();
                            String docno;

                            if (mode == 1) {
                              docno = const Uuid().v4();
                            } else {
                              final lastOpenShift = ShiftHelper().getLastOpenShift(global.posConfig.code);
                              if (lastOpenShift != null) {
                                docno = lastOpenShift.docno;
                              } else {
                                docno = const Uuid().v4();
                              }
                            }

                            ShiftObjectBoxStruct data = ShiftObjectBoxStruct(
                              isSync: false,
                              guidfixed: guid,
                              doctype: mode,
                              docdate: DateTime.now(),
                              remark: remarkTextEditingController.text,
                              usercode: global.userLogin!.code,
                              username: global.userLogin!.name,
                              amount: amount,
                              creditcard: 0,
                              promptpay: 0,
                              transfer: 0,
                              cheque: 0,
                              coupon: 0,
                              posid: global.posConfig.code,
                              docno: docno,
                            );
                            ShiftHelper().insert(data);
                            await shiftAndMoneyPrint(guid);

                            SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
                            sharedPreferences.setInt('shift_and_money_mode', mode);
                          }
                        },
                      ),
                    ),
                  if (mode == 1 || mode == 2) const Spacer(),
                  if (mode == 1 || mode == 2)
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: NumPadButton(
                            text: global.language('cancel'),
                            callBack: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const Spacer(),
                        Expanded(
                          flex: 1,
                          child: NumPadButton(
                            text: global.language('ok'),
                            callBack: () async {
                              String guid = const Uuid().v4();
                              String docno;

                              if (mode == 1) {
                                docno = const Uuid().v4();
                              } else {
                                final lastOpenShift = ShiftHelper().getLastOpenShift(global.posConfig.code);
                                if (lastOpenShift != null) {
                                  docno = lastOpenShift.docno;
                                } else {
                                  docno = const Uuid().v4();
                                }
                              }

                              ShiftObjectBoxStruct data = ShiftObjectBoxStruct(
                                isSync: false,
                                guidfixed: guid,
                                doctype: mode,
                                docdate: DateTime.now(),
                                remark: remarkTextEditingController.text,
                                usercode: global.userLogin!.code,
                                username: global.userLogin!.name,
                                amount: 0,
                                creditcard: 0,
                                promptpay: 0,
                                transfer: 0,
                                cheque: 0,
                                coupon: 0,
                                posid: global.posConfig.code,
                                docno: docno,
                              );
                              ShiftHelper().insert(data);
                              await shiftAndMoneyPrint(guid);

                              SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
                              sharedPreferences.setInt('shift_and_money_mode', mode);

                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> menuShift() {
    if (F.appFlavor != Flavor.MARINEPOS) {
      return [
        menuItem(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/cashier.png'),
          title: _openShiftText, // ⭐ Fix: Use cached string
          callBack: () {
            showDialogShiftAndMoney(1);
          },
        ),
        menuItem(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/deposit.png'),
          title: _addChangeText, // ⭐ Fix: Use cached string
          callBack: () {
            showDialogShiftAndMoney(3);
          },
        ),
        menuItem(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/cash-withdrawal.png'),
          title: _withdrawText, // ⭐ Fix: Use cached string
          callBack: () {
            showDialogShiftAndMoney(4);
          },
        ),
        menuItem(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/safe.png'),
          title: _closeShiftText, // ⭐ Fix: Use cached string
          callBack: () {
            showDialogShiftAndMoney(2);
          },
        ),
        menuItem(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/cashier.png'),
          title: _saleSummaryText, // ⭐ Fix: Use cached string
          callBack: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const SaleSummaryPage()));
          },
        ),
      ];
    } else {
      return [
        menuItemMarine(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/marine-icon-open.png'),
          callBack: () {
            showDialogShiftAndMoney(1);
          },
        ),
        menuItemMarine(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/marine-icon-addcharge.png'),
          callBack: () {
            showDialogShiftAndMoney(3);
          },
        ),
        menuItemMarine(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/marine-item-withdraw.png'),
          callBack: () {
            showDialogShiftAndMoney(4);
          },
        ),
        menuItemMarine(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/marine-icon-close.png'),
          callBack: () {
            showDialogShiftAndMoney(2);
          },
        ),
        menuItem(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/cashier.png'),
          title: global.language("sale_summary"), // 'ปิดกะ/ส่งเงิน',
          callBack: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const SaleSummaryPage()));
          },
        ),
      ];
    }
  }

  List<Widget> menuUtil() {
    return [
      if (F.appFlavor != Flavor.MARINEPOS)
        menuItem(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/barcode-icon.png'),
          title: _barcodeCheckerText, // ⭐ Fix: Use cached string
          callBack: () async {
            var res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const BarcodeChecker()));
            if (res) {
              _autoLoadProductData();
            }
          },
        ),
      menuItem(
        iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/print-icon.png'),
        title: _printerConfigText, // ⭐ Fix: Use cached string
        callBack: () async {
          await global.loadPrinter();
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PrinterConfigScreen())).then((value) async => {await global.loadPrinter()});
          }
        },
      ),
      menuItem(
        iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/print-icon.png'),
        title: _printQueueText,
        callBack: () async {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PrintQueueViewerScreen()));
        },
      ),
      if (F.appFlavor != Flavor.MARINEPOS)
        menuItem(
          iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/mobile-icon.png'),
          title: _connectStaffClientText, // ⭐ Fix: Use cached string
          callBack: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const ConnectStaffClientPage()));
          },
        ),
      menuItem(
        iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/printtest-icon.png'),
        title: _printTestText, // ⭐ Fix: Use cached string
        callBack: () async {
          await performPrintTest();
          if (mounted) {
            setState(() {});
          }
        },
      ),
      menuItem(
        iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/syncdata-icon.png'),
        title: _syncMasterText, // ⭐ Fix: Use cached string
        callBack: () async {
          global.isOnline = await global.hasNetwork();
          if (global.isOnline) {
            setState(() {
              global.syncDataSuccess = false;
            });

            // แสดง loading dialog
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    content: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(_themeSwatch)),
                          const SizedBox(height: 20),
                          Text(
                            _syncingDataText, // ⭐ Fix: Use cached string
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _pleaseWaitText, // ⭐ Fix: Use cached string
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            // รอให้ sync process เสร็จสิ้น
            await syncMasterProcess();

            // ตรวจสอบสถานะและปิด dialog
            if (mounted) {
              Navigator.of(context).pop(); // ปิด loading dialog

              if (global.syncDataSuccess) {
                // แสดง success dialog
                Future.delayed(const Duration(seconds: 1), () async {
                  await _syncCustomerData();
                });
                // เรียก sync ลูกค้าอีกครั้งหลังจาก sync master เสร็จ
              } else {
                // แสดง error dialog
                global.showAlertDialog(
                  context: context,
                  title: _syncFailedText, // ⭐ Fix: Use cached string
                  message: _syncDataErrorText, // ⭐ Fix: Use cached string
                );
              }
            }
          } else {
            // แสดง error dialog ถ้าไม่มีเน็ต
            global.showAlertDialog(
              context: context,
              title: _noInternetText, // ⭐ Fix: Use cached string
              message: _pleaseCheckInternetText, // ⭐ Fix: Use cached string
            );
          }
        },
      ),
      menuItem(
        iconImage: AppImageCacheManager.cachedAssetImage('assets/icons/syncbill-icon.png'),
        title: _syncBillText, // ⭐ Fix: Use cached string
        callBack: () async {
          SyncBill().startSync();
        },
      ),
    ];
  }

  Widget menuItemMarine({required Widget iconImage, Color backgroundColor = Colors.white, required VoidCallback callBack}) {
    return SizedBox.expand(
      child: ElevatedButton(
        onPressed: callBack,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
        child: iconImage,
      ),
    );
  }

  Widget menuItem({IconData? icon, Widget? iconImage, required String title, Color color = Colors.white, required Function callBack}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () {
        callBack();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: (icon != null)
                ? Icon(icon, size: 30, color: const Color(0xFFF56045))
                : Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: SimpleShadow(opacity: 0.5, color: Colors.black, offset: const Offset(2, 2), sigma: 2, child: iconImage!),
                  ),
          ),
          AutoSizeText(
            title,
            textAlign: TextAlign.center,
            // overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, color: Colors.black87),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  void rebuildScreen() {
    menuPosList = menuPos();
    menuShiftList = menuShift();
    menuUtilList = menuUtil();
    if (F.appFlavor == Flavor.SMLMOBILESALES) {
      menuVisitList = menuForVisit();
    }
  }

  @override
  void initState() {
    super.initState();

    // ⭐ Performance Fix #8: Add performance logging
    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
      AppLogger.debug('MenuScreen initState started');
    }

    // ⭐ Performance Fix #1: Initialize language strings FIRST
    _initializeLanguageStrings();

    // ⭐ Performance Fix #4: Rebuild screen (now uses cached strings)
    rebuildScreen();

    // ⭐ Performance Fix #1: Move database query to background
    Future.microtask(() {
      global.buffetModeLists = BuffetModeHelper().getAll();
    });

    // ⭐ Performance Manager
    AppPerformanceManager.instance.start();

    // ⭐ Performance Fix #1: Parallel loading with Future.wait
    Future.wait([global.getProfile(), global.getAppVersion()]).then((results) {
      if (mounted) {
        loadConfigSuccess = true;
        appVersion = results[1] as String;
        _updateCachedNames(); // ⭐ Fix #7: Update cached names
        setState(() {}); // ⭐ Single setState instead of 2
      }
    });

    // ⭐ Performance Fix #3: Delay customer data load (ไม่ block UI)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _autoLoadCustomerData();
    });

    global.sendProcessToCustomerDisplay(mode: global.secondScreenCommandInformation);

    if (global.printerLocalStrongData.where((e) => e.printerConnectType == global.PrinterConnectEnum.usb).isNotEmpty) {
      Future.microtask(() => getPrinter());
    }

    Future.microtask(() {
      AppPerformanceManager.instance.forceUpdatePrinterStatus();
    });

    // ⭐ Performance Fix #8: Log init time
    if (kDebugMode) {
      stopwatch?.stop();
      AppLogger.success('[Performance] MenuScreen initState took ${stopwatch?.elapsedMilliseconds}ms');
    }
  }

  Future<void> testPrinterConnect() async {
    AppLogger.debug("Testing printer connections...");

    for (int i = 0; i < global.printerLocalStrongData.length; i++) {
      PrinterLocalStrongDataModel printer = global.printerLocalStrongData[i];

      AppLogger.debug("Testing printer ${i + 1}: ${printer.name} (${printer.deviceName})");

      try {
        switch (printer.printerConnectType) {
          case global.PrinterConnectEnum.ip:
            await testIpPrinter(printer, i);
            break;

          case global.PrinterConnectEnum.bluetooth:
            await testBluetoothPrinter(printer, i);
            break;

          case global.PrinterConnectEnum.usb:
            await testUsbPrinter(printer, i);
            break;

          case global.PrinterConnectEnum.windows:
            await testWindowsPrinter(printer, i);
            break;

          case global.PrinterConnectEnum.sunmi1:
            // TODO: Implement Sunmi printer test
            global.printerLocalStrongData[i].isReady = false;
            global.printerLocalStrongData[i].isConfigConnectSuccess = false;
            break;
        }
      } catch (e) {
        AppLogger.error("Error testing printer ${printer.name}: $e");
        global.printerLocalStrongData[i].isReady = false;
        global.printerLocalStrongData[i].isConfigConnectSuccess = false;
      }
    }

    AppLogger.debug("Printer connection test completed");
  }

  Future<void> testIpPrinter(PrinterLocalStrongDataModel printer, int index) async {
    Socket? socket;
    try {
      if (printer.ipAddress.isEmpty || printer.ipPort <= 0) {
        global.printerLocalStrongData[index].isReady = false;
        global.printerLocalStrongData[index].isConfigConnectSuccess = false;
        return;
      }

      // ⭐ ตรวจสอบว่า IP address valid หรือไม่
      final ipPattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
      if (!ipPattern.hasMatch(printer.ipAddress)) {
        global.printerLocalStrongData[index].isReady = false;
        global.printerLocalStrongData[index].isConfigConnectSuccess = false;
        return;
      }

      // ⭐ แค่เช็ค TCP connection - ไม่ส่งคำสั่งใดๆ (DLE EOT ทำให้ printer บางรุ่นค้าง)
      socket = await Socket.connect(printer.ipAddress, printer.ipPort, timeout: const Duration(seconds: 2));

      // ⭐ รอสักครู่ก่อนปิด เพื่อไม่ให้ printer ค้าง
      await Future.delayed(const Duration(milliseconds: 100));

      // ถ้าเชื่อมต่อได้ ถือว่าเครื่องพิมพ์พร้อมใช้งาน
      global.printerLocalStrongData[index].isReady = true;
      global.printerLocalStrongData[index].isConfigConnectSuccess = true;
    } catch (e) {
      global.printerLocalStrongData[index].isReady = false;
      global.printerLocalStrongData[index].isConfigConnectSuccess = false;
      if (kDebugMode) {
        AppLogger.debug("IP printer test failed (${printer.ipAddress}:${printer.ipPort}): $e");
      }
    } finally {
      // ⭐ ปิด socket เสมอ (gracefully)
      try {
        await socket?.close();
      } catch (_) {}
    }
  }

  Future<void> testBluetoothPrinter(PrinterLocalStrongDataModel printer, int index) async {
    try {
      // ⭐ ไม่ connect จริง - แค่เช็คว่า config ถูกต้อง
      // การ connect/disconnect บ่อยเกินไปทำให้ printer บางรุ่นค้าง
      if (printer.deviceName.isNotEmpty && printer.ipAddress.isNotEmpty) {
        global.printerLocalStrongData[index].isReady = true;
        global.printerLocalStrongData[index].isConfigConnectSuccess = true;
      } else {
        global.printerLocalStrongData[index].isReady = false;
        global.printerLocalStrongData[index].isConfigConnectSuccess = false;
      }
    } catch (e) {
      global.printerLocalStrongData[index].isReady = false;
      global.printerLocalStrongData[index].isConfigConnectSuccess = false;
      AppLogger.debug("Bluetooth printer test failed: $e");
    }
  }

  Future<void> testUsbPrinter(PrinterLocalStrongDataModel printer, int index) async {
    try {
      // ⭐ ไม่ connect จริง - แค่เช็คว่า config ถูกต้อง
      // การ connect/disconnect บ่อยเกินไปทำให้ printer บางรุ่นค้าง
      if (printer.deviceName.isNotEmpty && (printer.vendorId.isNotEmpty || printer.productId.isNotEmpty)) {
        global.printerLocalStrongData[index].isReady = true;
        global.printerLocalStrongData[index].isConfigConnectSuccess = true;
      } else {
        global.printerLocalStrongData[index].isReady = false;
        global.printerLocalStrongData[index].isConfigConnectSuccess = false;
      }
    } catch (e) {
      global.printerLocalStrongData[index].isReady = false;
      global.printerLocalStrongData[index].isConfigConnectSuccess = false;
      AppLogger.debug("USB printer test failed: $e");
    }
  }

  Future<void> testWindowsPrinter(PrinterLocalStrongDataModel printer, int index) async {
    try {
      String printerName = printer.deviceName;

      // เช็คว่าเครื่องพิมพ์มีอยู่ในระบบ Windows หรือไม่
      List<PrinterDeviceModel> windowsPrinters = global.windowsListPrinters();
      bool printerExists = windowsPrinters.any((p) => p.deviceName == printerName);

      if (printerExists) {
        global.printerLocalStrongData[index].isReady = true;
        global.printerLocalStrongData[index].isConfigConnectSuccess = true;

        AppLogger.debug("Windows printer '$printerName' is available");
      } else {
        global.printerLocalStrongData[index].isReady = false;
        global.printerLocalStrongData[index].isConfigConnectSuccess = false;

        AppLogger.debug("Windows printer '$printerName' not found");
      }
    } catch (e) {
      global.printerLocalStrongData[index].isReady = false;
      global.printerLocalStrongData[index].isConfigConnectSuccess = false;
      AppLogger.debug("Windows printer test failed: $e");
    }
  }

  /// ทดสอบการพิมพ์จริงด้วยเครื่องพิมพ์ตัวแรกที่มีในระบบ
  Future<void> performPrintTest() async {
    if (global.printerLocalStrongData.isEmpty) {
      if (mounted) {
        global.showAlertDialog(context: context, title: "ไม่พบเครื่องพิมพ์", message: "กรุณาตั้งค่าเครื่องพิมพ์ก่อนทำการทดสอบ");
      }
      return;
    }

    PrinterLocalStrongDataModel testPrinter = global.printerLocalStrongData[0];

    AppLogger.debug("Testing print with: ${testPrinter.name} (${testPrinter.deviceName})");

    try {
      // ทำการตรวจสอบเครื่องพิมพ์ใน background เพื่อไม่ block UI
      await Future.microtask(() async {
        await testPrinterConnect();
      });

      if (!testPrinter.isReady || !testPrinter.isConfigConnectSuccess) {
        if (mounted) {
          global.showAlertDialog(context: context, title: "เครื่องพิมพ์ไม่พร้อม", message: "เครื่องพิมพ์ ${testPrinter.name} ไม่พร้อมใช้งาน กรุณาตรวจสอบการเชื่อมต่อ");
        }
        return;
      }

      // ทำการพิมพ์ใน background
      await Future.microtask(() async {
        await printTestReceipt(testPrinter);
      });

      if (mounted) {
        global.showAlertDialog(context: context, title: "ทดสอบการพิมพ์", message: "ส่งข้อมูลไปยังเครื่องพิมพ์ ${testPrinter.name} เรียบร้อยแล้ว");
      }
    } catch (e) {
      AppLogger.error("Print test failed: $e");
      if (mounted) {
        global.showAlertDialog(context: context, title: "ข้อผิดพลาด", message: "ไม่สามารถทดสอบการพิมพ์ได้: $e");
      }
    }
  }

  /// โหลดข้อมูลสินค้าอัตโนมัติเมื่อเข้าหน้า menu
  Future<void> _autoLoadProductData() async {
    try {
      global.isOnline = await global.hasNetwork();
      if (global.isOnline) {
        setState(() {
          global.syncDataSuccess = false;
        });

        await syncMasterProcess();
      }
    } catch (e) {
      AppLogger.error('Auto product load error: $e');
    }
  }

  /// โหลดข้อมูลลูกค้าอัตโนมัติเมื่อเข้าหน้า menu
  Future<void> _autoLoadCustomerData() async {
    // ⭐ Performance Fix #3: Optimized customer data loading
    Stopwatch? stopwatch;
    if (kDebugMode) {
      stopwatch = Stopwatch()..start();
      AppLogger.debug('_autoLoadCustomerData started');
    }

    try {
      // เช็คว่า online หรือไม่
      if (!global.isOnline) {
        AppLogger.debug('[Performance] Auto customer load skipped - offline mode');
        return;
      }

      // ⭐ Fix: ย้าย database query ไป background
      final existingCustomerCount = await Future.microtask(() => CustomerSyncService.instance.getLocalCustomerCount());

      // เช็คว่าควร sync ใหม่หรือไม่
      final shouldSync = await _shouldSyncCustomerData(existingCustomerCount);

      if (!shouldSync) {
        AppLogger.debug('[Performance] Customer data is up to date ($existingCustomerCount customers). Skipping sync.');
        return;
      }

      AppLogger.debug('[Performance] Auto loading customer data...');

      // ⭐ Show loading indicator
      if (mounted) {
        setState(() => _isLoadingCustomers = true);
      }

      // ทำการ sync ข้อมูลลูกค้า
      final success = await CustomerSyncService.instance.manualSync();

      if (mounted) {
        setState(() => _isLoadingCustomers = false);
      }

      if (success) {
        final customerCount = CustomerSyncService.instance.getLocalCustomerCount();

        AppLogger.debug('[Performance] Auto customer load completed. Total: $customerCount');

        // ⭐ Save sync time
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_customer_sync', DateTime.now().millisecondsSinceEpoch);

        // แสดง notification เล็กๆ
        if (mounted && customerCount > existingCustomerCount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('โหลดข้อมูลลูกค้า $customerCount คน'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.fixed, // ⭐ เปลี่ยนเป็น fixed เพื่อป้องกัน off-screen error
            ),
          );
        }
      } else {
        AppLogger.debug('[Performance] Auto customer load failed');
      }
    } catch (e) {
      AppLogger.error('[Performance] Auto customer load error: $e');
      if (mounted) {
        setState(() => _isLoadingCustomers = false);
      }
    } finally {
      if (kDebugMode) {
        stopwatch?.stop();
        AppLogger.success('[Performance] _autoLoadCustomerData took ${stopwatch?.elapsedMilliseconds}ms');
      }
    }
  }

  /// เช็คว่าควร sync ข้อมูลลูกค้าใหม่หรือไม่
  Future<bool> _shouldSyncCustomerData(int existingCount) async {
    // ⭐ Performance Fix #3: Smart sync logic

    // กรณีที่ 1: ถ้าไม่มีข้อมูลลูกค้าเลย ให้ sync
    if (existingCount == 0) {
      return true;
    }

    // ⭐ กรณีที่ 2: เช็คเวลาที่ sync ล่าสุด
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt('last_customer_sync') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final hoursSinceSync = (now - lastSync) / (1000 * 60 * 60);

      // ⭐ Sync เฉพาะถ้าผ่านมา > 24 ชั่วโมง
      if (hoursSinceSync > 24) {
        AppLogger.debug('[Performance] Customer data is ${hoursSinceSync.toStringAsFixed(1)} hours old. Syncing...');
        return true;
      }

      AppLogger.debug('[Performance] Customer data synced ${hoursSinceSync.toStringAsFixed(1)} hours ago. Skipping.');
      return false;
    } catch (e) {
      AppLogger.error('[Performance] Error checking sync time: $e. Syncing anyway.');
      return true;
    }
  }

  /// ซิงค์ข้อมูลลูกค้าจาก Server
  Future<void> _syncCustomerData() async {
    // แสดง loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text("กำลังซิงค์ข้อมูลลูกค้า...")]));
        },
      );
    }

    try {
      // เรียกใช้ CustomerSyncService
      final success = await CustomerSyncService.instance.manualSync();

      // ปิด loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // แสดงผลลัพธ์
      if (mounted) {
        final customerCount = CustomerSyncService.instance.getLocalCustomerCount();

        global.showAlertDialog(context: context, title: "ซิงค์สำเร็จ", message: "ซิงค์ข้อมูลสำเร็จ");
      }
    } catch (e) {
      // ปิด loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      AppLogger.debug("Customer sync failed: $e");

      if (mounted) {
        global.showAlertDialog(context: context, title: "เกิดข้อผิดพลาด", message: "ไม่สามารถซิงค์ข้อมูลลูกค้าได้: $e");
      }
    }
  }

  Future<void> printTestReceipt(PrinterLocalStrongDataModel printer) async {
    switch (printer.printerConnectType) {
      case global.PrinterConnectEnum.ip:
        await printTestViaIP(printer);
        break;

      case global.PrinterConnectEnum.bluetooth:
      case global.PrinterConnectEnum.usb:
        await printTestViaThermal(printer);
        break;

      case global.PrinterConnectEnum.windows:
        await printTestViaWindows(printer);
        break;

      default:
        throw Exception("ประเภทเครื่องพิมพ์ไม่รองรับ");
    }
  }

  Future<void> printTestViaIP(PrinterLocalStrongDataModel printer) async {
    final Socket socket = await Socket.connect(printer.ipAddress, printer.ipPort, timeout: const Duration(seconds: 1));

    try {
      List<int> commands = [];

      commands.addAll([0x1B, 0x40]); // ESC @

      commands.addAll([0x1B, 0x61, 0x01]); // ESC a 1

      commands.addAll("=== ทดสอบการพิมพ์ ===\n".codeUnits);
      commands.addAll("PRINT TEST\n".codeUnits);
      commands.addAll("=================\n\n".codeUnits);

      commands.addAll([0x1B, 0x61, 0x00]); // ESC a 0

      commands.addAll("เครื่องพิมพ์: ${printer.name}\n".codeUnits);
      commands.addAll("อุปกรณ์: ${printer.deviceName}\n".codeUnits);
      commands.addAll("IP: ${printer.ipAddress}:${printer.ipPort}\n".codeUnits);
      commands.addAll("วันที่: ${DateTime.now().toString()}\n\n".codeUnits);

      commands.addAll("1234567890123456789012345678901234567890\n".codeUnits);
      commands.addAll("ABCDEFGHIJKLMNOPQRSTUVWXYZ\n".codeUnits);
      commands.addAll("abcdefghijklmnopqrstuvwxyz\n".codeUnits);
      commands.addAll("!@#\$%^&*()_+-=[]{}|;:,.<>?\n\n".codeUnits);

      commands.addAll([0x1D, 0x56, 0x42, 0x00]); // GS V B 0

      socket.add(commands);
      // ลดเวลารอจาก 500ms เป็น 200ms
      await Future.delayed(const Duration(milliseconds: 200));
    } finally {
      socket.close();
    }
  }

  Future<void> printTestViaThermal(PrinterLocalStrongDataModel printer) async {
    Printer testPrinter = Printer(
      address: printer.ipAddress,
      name: printer.deviceName,
      vendorId: printer.vendorId,
      productId: printer.productId,
      connectionType: printer.printerConnectType == global.PrinterConnectEnum.bluetooth ? ConnectionType.BLE : ConnectionType.USB,
      isConnected: false,
    );

    try {
      await _flutterThermalPrinterPlugin.connect(testPrinter);

      List<int> commands = [];

      commands.addAll([0x1B, 0x40]); // ESC @

      commands.addAll([0x1B, 0x61, 0x01]);
      commands.addAll("PRINT TEST\n".codeUnits);
      commands.addAll("=================\n\n".codeUnits);

      commands.addAll("1234567890123456789012345678901234567890\n".codeUnits);
      commands.addAll("ABCDEFGHIJKLMNOPQRSTUVWXYZ\n".codeUnits);
      commands.addAll("abcdefghijklmnopqrstuvwxyz\n\n".codeUnits);

      commands.addAll([0x1D, 0x56, 0x42, 0x00]);

      await _flutterThermalPrinterPlugin.printData(testPrinter, commands);
    } finally {
      await _flutterThermalPrinterPlugin.disconnect(testPrinter);
    }
  }

  Future<void> printTestViaWindows(PrinterLocalStrongDataModel printer) async {
    if (!Platform.isWindows) {
      throw Exception("Windows printer รองรับเฉพาะบน Windows เท่านั้น");
    }

    String testContent =
        """
=== ทดสอบการพิมพ์ ===
PRINT TEST
=================

เครื่องพิมพ์: ${printer.name}
อุปกรณ์: ${printer.deviceName}
ประเภท: Windows Printer
วันที่: ${DateTime.now()}

1234567890123456789012345678901234567890
ABCDEFGHIJKLMNOPQRSTUVWXYZ
abcdefghijklmnopqrstuvwxyz

การทดสอบเสร็จสิ้น
""";

    try {
      Process.run('powershell', ['-Command', 'Out-Printer -Name "${printer.deviceName}" -InputObject "$testContent"']);
    } catch (e) {
      AppLogger.error("Windows print command failed, trying alternative method: $e");

      final Directory tempDir = Directory.systemTemp;
      final File tempFile = File('${tempDir.path}/print_test.txt');
      await tempFile.writeAsString(testContent);

      Process.run('notepad', ['/p', tempFile.path]);

      Timer(const Duration(seconds: 5), () {
        if (tempFile.existsSync()) {
          tempFile.delete();
        }
      });
    }
  }

  void getPrinter() async {
    try {
      await _flutterThermalPrinterPlugin.getPrinters(connectionTypes: [ConnectionType.USB]);
      if (mounted) {
        setState(() {
          // Force update printer status
          AppPerformanceManager.instance.forceUpdatePrinterStatus();
        });
      }
    } on PlatformException {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    // หยุด Performance Manager เพื่อป้องกัน memory leak
    AppPerformanceManager.instance.stop();
    super.dispose();
  }

  void sendCommandToSecondScreen() {
    // Send to จอสอง (เฉพาะเมื่อมี secondary display ต่ออยู่)
    if (Platform.isAndroid && global.isInternalCustomerDisplayConnected) {
      global.displayManager.transferDataToPresentation(<String, dynamic>{'mode': global.secondScreenCommandInformation});
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⭐ Performance Fix #7: Use cached values
    // ตรวจสอบขนาดหน้าจอ
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // ⭐ Performance Fix #7: Use cached company/branch names
    String companyName = _cachedCompanyName ?? "";
    String branchName = _cachedBranchName ?? "";

    Widget infoWidget = Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.5),
                spreadRadius: 1,
                blurRadius: 7,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          margin: EdgeInsets.only(left: isMobile ? 5 : 10, right: isMobile ? 5 : 10, top: isMobile ? 5 : 10),
          padding: EdgeInsets.all(isMobile ? 6.0 : 8.0),
          child: isMobile ? _buildMobileInfoWidget() : _buildDesktopInfoWidget(),
        ),
      ],
    );

    // ⭐ Performance Fix #7: Removed duplicate computation - use cached values above

    // ปรับขนาด AppBar สำหรับอุปกรณ์ต่างๆ
    final isMobileDevice = screenWidth < 600;
    final responsiveAppBarHeight = isMobileDevice ? appBarHeight : appBarHeight + 20;

    return SafeArea(
      child: Scaffold(
        backgroundColor: _themeSwatch[100],
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(responsiveAppBarHeight),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_themeSwatch[600]!, _themeSwatch[800]!]),
            ),
            child: AppBar(
              backgroundColor: Colors.transparent, // ใช้สีโปร่งใสเพื่อให้เห็น gradient
              automaticallyImplyLeading: false,
              centerTitle: false,
              foregroundColor: Colors.white,
              elevation: 0, // ลบเงาเพื่อให้ gradient ดูสวยขึ้น
              flexibleSpace: Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobileDevice ? 12.0 : 16.0, vertical: isMobileDevice ? 16.0 : 20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // โลโก้ + ชื่อแบรนด์ด้านซ้าย
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: (global.appMode == global.AppModeEnum.posTerminal) ? companyName : "${global.language("pos_remote")} : $companyName",
                              style: TextStyle(fontSize: isMobileDevice ? 20 : 28, fontWeight: FontWeight.bold, fontStyle: FontStyle.normal, color: Colors.white),
                            ),
                            if (branchName.isNotEmpty)
                              TextSpan(
                                text: isMobileDevice ? "\n$branchName" : "   $branchName",
                                style: TextStyle(fontSize: isMobileDevice ? 14 : 16, color: Colors.white.withValues(alpha: 0.9), letterSpacing: isMobileDevice ? 0.8 : 1.2),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // leading: Container(
              //   margin: const EdgeInsets.all(5),
              //   child: ((global.getShopLogoPathName().isNotEmpty) && (File(global.getShopLogoPathName()).existsSync()))
              //       ? Image.file(
              //           File(global.getShopLogoPathName()),
              //         )
              //       : Container(),
              // ),
              actions: [
                // ⭐ Demo Mode Badge
                if (global.isDemoMode)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.science, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'DEMO MODE',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                if (Platform.isWindows)
                  IconButton(
                    icon: Icon((global.isFullScreen == false) ? Icons.fullscreen_exit : Icons.fullscreen),
                    onPressed: () async {
                      await global.switchFullScreen();
                    },
                  ),
                // ⭐ ปุ่มเปิด/ปิดเสียง Beep
                IconButton(
                  icon: Icon(global.isSoundEnabled ? Icons.volume_up : Icons.volume_off, color: global.isSoundEnabled ? Colors.white : Colors.white54),
                  tooltip: global.isSoundEnabled ? 'ปิดเสียง' : 'เปิดเสียง',
                  onPressed: () async {
                    setState(() {
                      global.isSoundEnabled = !global.isSoundEnabled;
                    });
                    // ⭐ บันทึกค่าลง SharedPreferences
                    await global.saveSoundSetting();
                    // แสดง feedback
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(global.isSoundEnabled ? '🔊 เปิดเสียงแล้ว' : '🔇 ปิดเสียงแล้ว'), duration: const Duration(seconds: 1)));
                    }
                  },
                ),
                IconButton(
                  icon: Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 2)),
                    child: Image.asset('assets/flags/${global.userScreenLanguage}.png'),
                  ),
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectLanguageScreen()));
                    // ⭐ Performance Fix: Refresh cached strings after language change
                    _initializeLanguageStrings();
                    _updateCachedNames();
                    rebuildScreen();
                    setState(() {});
                  },
                ),
                PopupMenuButton(
                  elevation: 2,
                  icon: const Icon(Icons.more_vert),
                  offset: Offset(0.0, appBarHeight),
                  onSelected: (value) async {
                    switch (value) {
                      case 1:
                        // ตั้งค่าเครื่องพิมพ์
                        await global.loadPrinter();
                        if (mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const PrinterConfigScreen())).then((value) async => {await global.loadPrinter()});
                        }
                        break;
                      case 3:
                        if (mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployeeChangePasswordPage())).then((value) async => {await global.loadPrinter()});
                        }
                        break;
                      case 9:
                        if (Platform.isAndroid) {
                          SystemNavigator.pop();
                        } else if (Platform.isIOS) {
                          exit(0);
                        } else {
                          exit(0);
                        }
                        break;
                    }
                  },
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0),
                      topLeft: Radius.circular(8.0),
                      topRight: Radius.circular(8.0),
                    ),
                  ),
                  itemBuilder: (ctx) => [
                    buildPopupMenuItem(
                      title: _printerConfigText, // ⭐ Fix: Use cached string
                      valueCode: 1,
                      iconData: Icons.print_rounded,
                    ),
                    buildPopupMenuItem(
                      title: _changePasswordText, // ⭐ Fix: Use cached string
                      valueCode: 3,
                      iconData: Icons.lock,
                    ),
                    buildPopupMenuItem(
                      title: _logoutText, // ⭐ Fix: Use cached string
                      valueCode: 9,
                      iconData: Icons.logout,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        resizeToAvoidBottomInset: false,
        floatingActionButton: Builder(
          builder: (context) {
            double screenWidth = MediaQuery.of(context).size.width;
            double iconSize = screenWidth * 0.12; // ปรับ % ตามขนาดที่ต้องการ
            if (F.appFlavor == Flavor.MARINEPOS) {
              return SizedBox(
                width: iconSize,
                height: iconSize,
                child: Image.asset('assets/icons/marine-logo-app.png', fit: BoxFit.contain),
              );
            } else {
              return Container();
            }
          },
        ),
        body: Column(
          children: [
            // สถานะเครื่องพิมพ์แบบ Reactive
            ValueListenableBuilder<bool>(
              valueListenable: AppPerformanceManager.printerStatusNotifier,
              builder: (context, isPrinterReady, child) {
                if (global.printerLocalStrongData.isEmpty || isPrinterReady) {
                  return Container(); // ไม่แสดงอะไรถ้าเครื่องพิมพ์พร้อม
                }

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.red.shade400, Colors.red.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), spreadRadius: 1, blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.print_disabled, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _printerIsNotReadyText, // ⭐ Fix: Use cached string
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            infoWidget,
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: menuPosList.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _getCrossAxisCount(context),
                            crossAxisSpacing: _getGridSpacing(context),
                            mainAxisSpacing: _getGridSpacing(context),
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            return menuPosList[index];
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: menuShiftList.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _getCrossAxisCount(context),
                            crossAxisSpacing: _getGridSpacing(context),
                            mainAxisSpacing: _getGridSpacing(context),
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            return menuShiftList[index];
                          },
                        ),
                      ),
                    ),
                    if (menuVisitList.isNotEmpty)
                      Padding(
                        padding: _getGridPadding(context),
                        child: SizedBox(
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: menuVisitList.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _getCrossAxisCount(context),
                              crossAxisSpacing: _getGridSpacing(context),
                              mainAxisSpacing: _getGridSpacing(context),
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              return menuVisitList[index];
                            },
                          ),
                        ),
                      ),
                    Padding(
                      padding: _getGridPadding(context),
                      child: SizedBox(
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: menuUtilList.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _getCrossAxisCount(context),
                            crossAxisSpacing: _getGridSpacing(context),
                            mainAxisSpacing: _getGridSpacing(context),
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            return menuUtilList[index];
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method สำหรับคำนวณ crossAxisCount แบบ responsive
  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 400) {
      // Mobile จอเล็ก
      return 2;
    } else if (screenWidth < 600) {
      // Mobile จอใหญ่
      return 3;
    } else if (screenWidth < 1024) {
      // Tablet
      return 4;
    } else {
      // Desktop
      return screenWidth ~/ 120;
    }
  }

  // Helper method สำหรับ spacing แบบ responsive
  double _getGridSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      // Mobile
      return 8.0;
    } else {
      // Tablet/Desktop
      return 10.0;
    }
  }

  // Helper method สำหรับ padding แบบ responsive
  EdgeInsets _getGridPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      // Mobile
      return const EdgeInsets.all(4.0);
    } else {
      // Tablet/Desktop
      return const EdgeInsets.all(8.0);
    }
  }

  Widget _buildShiftStatusWidget() {
    try {
      // ตรวจสอบสถานะกะปัจจุบัน
      final lastOpenShift = global.shiftHelper.getLastOpenShift(global.posConfig.code);

      if (lastOpenShift != null) {
        // มีกะที่เปิดอยู่
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade300, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: Colors.green.shade700),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "กะ: ${lastOpenShift.username}",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text("เปิด: ${DateFormat('HH:mm').format(lastOpenShift.docdate)}", style: TextStyle(fontSize: 10, color: Colors.green.shade600)),
                ],
              ),
            ],
          ),
        );
      } else {
        // ไม่มีกะที่เปิดอยู่
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade300, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time_outlined, size: 16, color: Colors.orange.shade700),
              const SizedBox(width: 4),
              Text(
                "ยังไม่เปิดกะ",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade700),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // ถ้าเกิดข้อผิดพลาด แสดงสถานะไม่ทราบ
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline_rounded, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              "ไม่ทราบสถานะ",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
  }

  // Helper method สำหรับ mobile layout
  Widget _buildMobileInfoWidget() {
    return Column(
      children: [
        // Row แรก: User info และ logout button
        Row(
          children: [
            Expanded(
              child: (global.userLogin!.code.isEmpty)
                  ? const Row(
                      children: [
                        Icon(Icons.key, size: 20),
                        SizedBox(width: 6),
                        Text("Login", style: TextStyle(fontSize: 14)),
                      ],
                    )
                  : Row(
                      children: [
                        if (global.userLogin!.profile_picture.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(global.userLogin!.profile_picture, height: 24, width: 24, fit: BoxFit.cover),
                            ),
                          ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_user, size: 18, color: Colors.green),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            global.userLogin!.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(40, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  global.playSound(sound: global.SoundEnum.buttonTing);
                  global.loginSuccess = false;
                  global.userLogin = null;
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, global.loginByEmployeePageName, (route) => false);
                  }
                },
                child: const Icon(Icons.logout, size: 18),
              ),
            ),
          ],
        ),
        // Row สอง: รายละเอียดเพิ่มเติม
        if (global.userLogin!.code.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                child: Text("(${global.userLogin!.code})", style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  global.deviceId,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildShiftStatusWidget(),
            ],
          ),
        ],
      ],
    );
  }

  // Helper method สำหรับ desktop layout (เดิม)
  Widget _buildDesktopInfoWidget() {
    return Row(
      children: [
        (global.userLogin!.code.isEmpty)
            ? const Row(
                children: [
                  Icon(Icons.key),
                  SizedBox(width: 8),
                  Text("Login", overflow: TextOverflow.clip),
                ],
              )
            : Row(
                children: [
                  if (global.userLogin!.profile_picture.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 2)),
                      child: Image.network(global.userLogin!.profile_picture, height: 30),
                    ),
                  const SizedBox(width: 4),
                  const Icon(Icons.verified_user),
                  const SizedBox(width: 4),
                  Text("ผู้ใช้งาน : ${global.userLogin!.name} (${global.userLogin!.code}) ", overflow: TextOverflow.clip),
                  const SizedBox(width: 4),
                  Text(global.deviceId, overflow: TextOverflow.clip),
                  const SizedBox(width: 8),
                  _buildShiftStatusWidget(),
                ],
              ),
        const Spacer(),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _themeColor),
          onPressed: () {
            global.loginSuccess = false;
            global.userLogin = null;
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, global.loginByEmployeePageName, (route) => false);
            }
          },
          child: const Icon(Icons.logout),
        ),
      ],
    );
  }

  PopupMenuItem buildPopupMenuItem({required String title, required IconData iconData, required int valueCode}) {
    return PopupMenuItem(
      value: valueCode,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(iconData, color: Colors.black),
          Text(title),
        ],
      ),
    );
  }
}
