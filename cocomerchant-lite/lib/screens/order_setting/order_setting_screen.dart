import 'package:cocomerchant_lite/bloc/order_setting/order_setting_bloc.dart';
import 'package:cocomerchant_lite/bloc/order_template_setting/order_template_setting_bloc.dart';
import 'package:cocomerchant_lite/bloc/pos_setting/pos_setting_bloc.dart';
import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/model/order_setting_model.dart';
import 'package:cocomerchant_lite/repositories/client.dart';
import 'package:cocomerchant_lite/repositories/report_repository.dart';
import 'package:cocomerchant_lite/screen_search/order_template_setting_search_screen.dart';
import 'package:cocomerchant_lite/screens/otp/otp_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:split_view/split_view.dart';

class OrderSettingScreen extends StatefulWidget {
  static String routeName = "/order_setting_screen";
  const OrderSettingScreen({super.key});

  @override
  State<OrderSettingScreen> createState() => OrderSettingScreenState();
}

class OrderSettingScreenState extends State<OrderSettingScreen> with SingleTickerProviderStateMixin {
  late TabController tabController;
  ScrollController editScrollController = ScrollController();
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode(skipTraversal: true);
  List<LanguageModel> languageList = <LanguageModel>[];
  List<OrderSettingModel> listData = [];
  List<String> guidListChecked = [];
  List<LanguageDataModel> names = [];
  ScrollController listScrollController = ScrollController();
  List<GlobalKey> listKeys = [];
  String searchText = "";
  String selectGuid = "";
  bool isDataChange = false;
  bool isSaveAllow = false;
  late OrderSettingState blocCurrentState;
  String headerEdit = "";
  late MediaQueryData queryData;
  int currentListIndex = -1;
  GlobalKey headerKey = GlobalKey();
  bool isKeyUp = false;
  bool isKeyDown = false;
  bool showCheckBox = false;
  bool isEditMode = false;
  late OrderSettingModel screenData;
  late SplitViewController splitViewController;
  final debouncer = global.Debouncer(1000);
  bool loadingData = false;
  late DateTime dateNow = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  TextEditingController codeController = TextEditingController();
  TextEditingController docformat = TextEditingController();

  String pinActive = "";
  TextEditingController field1 = TextEditingController();
  TextEditingController field2 = TextEditingController();
  TextEditingController field3 = TextEditingController();
  TextEditingController field4 = TextEditingController();
  TextEditingController field5 = TextEditingController();
  TextEditingController field6 = TextEditingController();
  TextEditingController field7 = TextEditingController();
  TextEditingController field8 = TextEditingController();

  bool isActivePin = false;
  String activeAPIKEY = "";
  bool isLoadingActive = false;

  void setSystemLanguageList() async {
    await global.setSystemLanguage(context);

    for (int i = 0; i < global.config.languages.length; i++) {
      if (global.config.languages[i].isuse!) {
        languageList.add(global.config.languages[i]);
      }
    }
    loadDataList("");
  }

  @override
  void initState() {
    splitViewController = SplitViewController(limits: [null, WeightLimit(min: 0.2, max: 0.8)]);

    tabController = TabController(vsync: this, length: 2);
    tabController.addListener(() {
      setState(() {});
    });

    clearEditData();
    setSystemLanguageList();

    super.initState();
  }

  @override
  void dispose() {
    listScrollController.dispose();
    tabController.dispose();
    editScrollController.dispose();
    searchController.dispose();

    codeController.dispose();
    docformat.dispose();

    super.dispose();
  }

  void loadDataList(String search) {
    setState(() {
      loadingData = true;
    });
    searchText = search;
    context.read<OrderSettingBloc>().add(OrderSettingLoadList(offset: (listData.isEmpty) ? 0 : listData.length, limit: global.loadDataPerPage, search: search));
  }

  void onScrollList() {
    if (listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange) {
      loadDataList(searchText);
    }
  }

  void clearEditData() {
    listScrollController.addListener(onScrollList);

    screenData = OrderSettingModel(
      code: '',
      devicenumber: '',
      guidfixed: '',
      activepin: '',
      devicetype: 0,
      docformat: 'YYMMDD####',
      isposactive: false,
      settingcode: '',
      settingname: '',
    );

    isActivePin = false;
    isDataChange = false;
    setState(() {
      loadDataToScreen();
    });
  }

  void loadDataToScreen() {
    codeController.text = screenData.code!;
    docformat.text = screenData.docformat!;
  }

  void discardData({required Function callBack}) {
    if (isEditMode && isDataChange) {
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(global.language('data_editing')),
          content: Text(global.language('leave_this_screen')),
          actions: <Widget>[
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context), child: Text(global.language('no'))),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () {
                  Navigator.pop(context);
                  callBack();
                },
                child: Text(global.language('yes'))),
          ],
        ),
      );
    } else {
      callBack();
    }
  }

  void getData(String guid) {
    headerEdit = global.language("show");
    isEditMode = false;
    context.read<OrderSettingBloc>().add(OrderSettingGet(guid: guid));
  }

  void switchToEdit(OrderSettingModel value) {
    setState(() {
      selectGuid = value.guidfixed!;
      getData(selectGuid);
      headerEdit = global.language("edit");
      isSaveAllow = true;
      isEditMode = true;
    });
  }

  Future<void> activatePin() async {
    /// 0 = dev , 1 = prod , 2 = uat
    int isDeveloper = global.isdevPin;

    ReportRepository reportRepository = ReportRepository();
    try {
      ApiResponse result = await reportRepository.activePos(pinActive, screenData.code!, isDeveloper, activeAPIKEY);
      if (result.success) {
        isActivePin = true;
        if (isActivePin) {
          screenData.activepin = pinActive;
          updateData(selectGuid);
          setState(() {
            isLoadingActive = false;
            activeAPIKEY = "";
            global.showSnackBar(
              context,
              const Icon(
                Icons.check,
                color: Colors.white,
              ),
              global.language("active_pin_success"),
              Colors.blue,
            );
          });
        }
      }
    } catch (e) {
      setState(() {
        isActivePin = false;
        isLoadingActive = false;
      });

      if (mounted) {
        global.showSnackBar(context, const Icon(Icons.error, color: Colors.white), e.toString(), Colors.red);
      }
    }
  }

  Widget listScreen({bool mobileScreen = false}) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: global.theme.appBarColor,
        automaticallyImplyLeading: false,
        title: Text(global.language("order_setting")),
        leading: IconButton(
          focusNode: FocusNode(skipTraversal: true),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            discardData(callBack: () {
              // Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/menu');
              isEditMode = false;
            });
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.font),
            onPressed: () {
              setState(() {
                global.listDataFontSizeChange();
              });
            },
          ),
          IconButton(
            focusNode: FocusNode(skipTraversal: true),
            onPressed: () {
              discardData(callBack: () {
                setState(() {
                  if (showCheckBox) {
                    showCheckBox = false;
                    guidListChecked.clear();
                  } else {
                    showCheckBox = true;
                    global.showSnackBar(
                        context,
                        const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                        global.language("choose_item_delete"),
                        Colors.blue);
                  }
                });
              });
            },
            icon: (showCheckBox) ? const Icon(Icons.close) : const Icon(Icons.check_box),
          ),
          if (guidListChecked.isNotEmpty)
            IconButton(
              focusNode: FocusNode(skipTraversal: true),
              onPressed: () {
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: Text(global.language('confirm_delete')),
                    actions: <Widget>[
                      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context), child: const Text('ไม่')),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          onPressed: () {
                            Navigator.pop(context);
                            context.read<OrderSettingBloc>().add(OrderSettingDeleteMany(guid: guidListChecked));
                          },
                          child: Text(global.language('delete'))),
                    ],
                  ),
                );
                setState(() {});
              },
              icon: const Icon(
                Icons.delete,
              ),
            ),

          /// เพิ่มข้อมูลใหม่
          Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: IconButton(
                focusNode: FocusNode(skipTraversal: true),
                onPressed: () {
                  discardData(callBack: () {
                    setState(() {
                      isEditMode = true;
                      selectGuid = "";
                      showCheckBox = false;
                      isDataChange = false;
                      clearEditData();
                      headerEdit = global.language("append");
                      isSaveAllow = true;
                      if (mobileScreen) {
                        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                          tabController.animateTo(1);
                        });
                      }
                    });
                  });
                },
                icon: const Icon(
                  Icons.add,
                ),
              )),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            onSubmitted: (value) {
              searchFocusNode.requestFocus();
            },
            onChanged: (value) {
              debouncer.run(() {
                setState(() {
                  listData = [];
                });
                loadDataList(value);
              });
            },
            focusNode: searchFocusNode,
            controller: searchController,
            decoration: InputDecoration(
              hintText: global.language('search'),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: listScrollController,
            itemCount: listData.length,
            itemBuilder: (context, index) => listObject(index, listData[index], showCheckBox),
          ),
        ),
        if (loadingData)
          Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
            color: Colors.blue,
            size: 50,
          ))
      ]),
    );
  }

  Widget listObject(int index, OrderSettingModel value, bool showCheckBox) {
    // ตรวจสอบและปรับขนาดของ listKeys ถ้าจำเป็น
    while (listKeys.length <= index) {
      listKeys.add(GlobalKey());
    }

    bool isCheck = guidListChecked.contains(value.guidfixed);
    bool selected = selectGuid == value.guidfixed;
    bool isActive = value.activepin!.isNotEmpty;

    return Card(
      key: listKeys[index],
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: selected
          ? Colors.cyan[100]
          : (index % 2 == 0)
              ? global.theme.columnAlternateEvenColor
              : global.theme.columnAlternateOddColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? Colors.green : Colors.red,
          child: isActive
              ? const Icon(
                  Icons.check,
                  color: Colors.white,
                )
              : const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
        ),
        title: Text(
          value.code!,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: selected ? global.deviceConfig.listDataFontSize + 2.0 : global.deviceConfig.listDataFontSize,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.docformat!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: global.deviceConfig.listDataFontSize - 2),
            ),
            Text(
              isActive ? global.language("active_pin_success") : global.language("not_active_pin"),
              style: TextStyle(
                color: isActive ? Colors.green : Colors.red,
                fontSize: global.deviceConfig.listDataFontSize - 2,
              ),
            ),
          ],
        ),
        trailing: showCheckBox
            ? Checkbox(
                value: isCheck,
                onChanged: (bool? newValue) {
                  setState(() {
                    if (newValue == true) {
                      guidListChecked.add(value.guidfixed!);
                    } else {
                      guidListChecked.remove(value.guidfixed);
                    }
                    isCheck = newValue ?? false;
                  });
                  global.showSnackBar(
                      context, const Icon(Icons.check, color: Colors.white), "${global.language("chosen")} ${guidListChecked.length} ${global.language("list")}", Colors.blue);
                },
              )
            : null,
        onTap: () {
          if (showCheckBox) {
            setState(() {
              if (isCheck) {
                guidListChecked.remove(value.guidfixed);
              } else {
                guidListChecked.add(value.guidfixed!);
              }
              isCheck = !isCheck;
            });
          } else {
            discardData(callBack: () {
              setState(() {
                isSaveAllow = false;
                selectGuid = value.guidfixed!;
                getData(selectGuid);
                WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                  tabController.animateTo(1);
                });
              });
            });
          }
        },
        onLongPress: () {
          if (!showCheckBox) {
            switchToEdit(value);
          }
        },
      ),
    );
  }

  void saveOrUpdateData() {
    if (verifyData(screenData)) {
      showCheckBox = false;
      // print(screenData.toJson());
      if (selectGuid.trim().isEmpty) {
        context.read<OrderSettingBloc>().add(OrderSettingSave(orderSetting: screenData));
      } else {
        updateData(selectGuid);
      }
    }
  }

  bool verifyData(OrderSettingModel value) {
    List<String> errorList = [];

    if (errorList.isNotEmpty) {
      global.showSnackBar(
          context,
          const Icon(
            Icons.error,
            color: Colors.white,
          ),
          "${global.language("not_success_save")} ${errorList.join(", ")}",
          Colors.red);
      return false;
    }
    return true;
  }

  void updateData(String guid) {
    showCheckBox = false;

    context.read<OrderSettingBloc>().add(OrderSettingUpdate(guid: guid, orderSetting: screenData));
  }

  String getLangName(String code) {
    LanguageModel name = languageList.firstWhere((element) => element.code == code, orElse: () => LanguageModel(code: '', codeTranslator: '', name: '', isuse: false));
    return name.name!;
  }

  Widget editScreen({mobileScreen}) {
    List<Widget> formWidgets = [];

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: TextFormField(
          readOnly: !isEditMode,
          enabled: isEditMode,
          textAlign: TextAlign.left,
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('[a-z A-Z 0-9 -]'))],
          onChanged: (value) {
            isDataChange = true;
            screenData.code = value.toUpperCase();
            codeController.value = TextEditingValue(text: value.toUpperCase(), selection: codeController.selection);
          },
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
            labelText: global.language("order_setting_code"),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          },
          onEditingComplete: () {},
        ),
      ),
    );

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: TextFormField(
          readOnly: !isEditMode,
          enabled: isEditMode,
          textAlign: TextAlign.left,
          controller: docformat,
          textCapitalization: TextCapitalization.characters,
          // inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('[a-z A-Z 0-9 -]'))],
          onChanged: (value) {
            isDataChange = true;
            screenData.docformat = value;
            docformat.value = TextEditingValue(text: value, selection: docformat.selection);
          },
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
            labelText: global.language("order_setting_doc_format"),
          ),
          onEditingComplete: () {},
        ),
      ),
    );

    // formWidgets.add(
    //   Padding(
    //     padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
    //     child: Row(
    //       children: [
    //         Radio(
    //           focusNode: FocusNode(skipTraversal: true),
    //           value: 0,
    //           groupValue: screenData.devicetype,
    //           onChanged: (isEditMode)
    //               ? (value) {
    //                   setState(() {
    //                     screenData.devicetype = value as int?;
    //                   });
    //                 }
    //               : null,
    //         ),
    //         Text(global.language("machine_employee")),
    //         const SizedBox(width: 10),
    //         Radio(
    //           focusNode: FocusNode(skipTraversal: true),
    //           value: 1,
    //           groupValue: screenData.devicetype,
    //           onChanged: (isEditMode)
    //               ? (value) {
    //                   setState(() {
    //                     screenData.devicetype = value as int?;
    //                   });
    //                 }
    //               : null,
    //         ),
    //         Text(global.language("machine_customer")),
    //       ],
    //     ),
    //   ),
    // );

    /// setting order
    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Container(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all<Color>(const Color.fromARGB(255, 65, 132, 111)),
            ),
            onPressed: (isEditMode)
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderTemplateSettingSearchScreen(
                          word: '',
                        ),
                      ),
                    ).then((value) {
                      setState(() {
                        global.SearchGuidCodeNameModel result = value;
                        if (result.isCancel == false) {
                          screenData.settingcode = result.guid;
                          screenData.settingname = result.code;
                        }
                      });
                    });
                  }
                : null,
            child: Text(
              (screenData.settingcode!.isEmpty) ? global.language("select_template_order_setting") : '${global.language("type_order_setting")} : ${screenData.settingname}',
            ),
          ),
        ),
      ),
    );

    ///  active pin
    if (screenData.activepin!.isNotEmpty) {
      formWidgets.add(
        Container(
          width: double.infinity,
          height: 50,
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: ElevatedButton.icon(
            focusNode: FocusNode(skipTraversal: true),
            onPressed: () {
              /// show dialog confirm cancel pin
              showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: Text(global.language('confirm_cancel_pin')),
                  content: Text(global.language('how_to_cancel_pin')),
                  actions: <Widget>[
                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context), child: Text(global.language('no'))),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        onPressed: () async {
                          // screenData.activepin = "";
                          // updateData(value.guidfixed);
                          ReportRepository reportRepository = ReportRepository();
                          try {
                            /// get apikey in clickhouse
                            ApiResponse result = await reportRepository.getApiKey(screenData.activepin!);
                            if (result.success) {
                              List<dynamic> data = result.data;

                              /// เก็บ apikey ไว้ใช้ในการลบ ใน apikeyservice
                              activeAPIKEY = data[0]["apikey"];

                              try {
                                /// delete pin in clickhouse pinlist
                                ApiResponse result = await reportRepository.deletePos(screenData.activepin!);
                                if (result.success) {
                                  /// call bloc DeleteApikey
                                  if (mounted) {
                                    context.read<PosSettingBloc>().add(DeleteApikey(apikey: activeAPIKEY));
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  global.showSnackBar(context, const Icon(Icons.error, color: Colors.white), e.toString(), Colors.red);
                                }
                              }
                            }
                          } catch (e) {
                            context.read<PosSettingBloc>().add(DeleteApikey(apikey: activeAPIKEY));
                            // if (mounted) {
                            //   global.showSnackBar(
                            //     context,
                            //     const Icon(Icons.error, color: Colors.white),
                            //     e.toString(),
                            //     Colors.red,
                            //   );
                            // }
                          }
                        },
                        child: Text(global.language('yes'))),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.cancel),
            label: Text(global.language("cancel_active_pin")),
          ),
        ),
      );
    } else {
      formWidgets.add(
        Container(
          width: double.infinity,
          height: 50,
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: ElevatedButton.icon(
            focusNode: FocusNode(skipTraversal: true),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OtpScreen(),
                ),
              ).then((value) async {
                // This will be called when OtpScreen pops and returns the value
                if (value.isNotEmpty) {
                  setState(() {
                    isLoadingActive = true;
                  });

                  pinActive = value;

                  /// delay 1 second next get APIKEY
                  await Future.delayed(const Duration(seconds: 1));

                  /// get APIKEY
                  if (mounted) {
                    context.read<PosSettingBloc>().add(const GetApiKey());
                  } else {
                    setState(() {
                      isLoadingActive = false;
                      pinActive = "";
                    });
                  }
                }
              });
            },
            icon: isLoadingActive ? const CircularProgressIndicator() : const Icon(Icons.lock),
            label: Text(global.language("active_pin")),
          ),
        ),
      );
    }

    if (isSaveAllow) {
      formWidgets.add(const SizedBox(height: 20));
      formWidgets.add(
        Container(
          width: double.infinity,
          height: 50,
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            focusNode: FocusNode(skipTraversal: true),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                saveOrUpdateData();
              }
            },
            icon: const Icon(Icons.save),
            label: Text(
              global.language("save") + ((kIsWeb) ? " (F10)" : ""),
            ),
          ),
        ),
      );
    }

    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
            backgroundColor: (isEditMode) ? global.theme.toolBarEditModeColor : global.theme.appBarColor,
            automaticallyImplyLeading: false,
            leading: mobileScreen
                ? IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () async {
                      showCheckBox = false;
                      discardData(callBack: () {
                        isEditMode = false;
                        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                          tabController.animateTo(0);
                        });
                      });
                    })
                : null,
            title: Text(headerEdit + global.language("order_setting")),
            actions: <Widget>[
              if (selectGuid.isNotEmpty)
                IconButton(
                  focusNode: FocusNode(skipTraversal: true),
                  onPressed: () {
                    showCheckBox = false;
                    showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: Text(global.language('delete_confirm')),
                        actions: <Widget>[
                          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context), child: Text(global.language('no'))),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              onPressed: () {
                                Navigator.pop(context);
                                context.read<OrderSettingBloc>().add(OrderSettingDelete(guid: selectGuid));
                              },
                              child: Text(global.language('confirm'))),
                        ],
                      ),
                    );
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.delete,
                  ),
                ),
              if (isSaveAllow == false && selectGuid.trim().isNotEmpty)
                IconButton(
                  focusNode: FocusNode(skipTraversal: true),
                  onPressed: () {
                    showCheckBox = false;
                    switchToEdit(listData[listData.indexOf(listData.firstWhere((element) => element.guidfixed == selectGuid))]);
                  },
                  icon: const Icon(
                    Icons.edit,
                  ),
                ),
              if (isSaveAllow == true)
                IconButton(
                  focusNode: FocusNode(skipTraversal: true),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      saveOrUpdateData();
                    }
                  },
                  icon: const Icon(
                    Icons.save,
                  ),
                )
            ]),
        body: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (KeyEvent event) {
              if (event is KeyDownEvent) {
                // print(event.logicalKey);
                if (event.logicalKey == LogicalKeyboardKey.f10) {
                  if (_formKey.currentState!.validate()) {
                    saveOrUpdateData();
                  }
                }
              }
            },
            child: SingleChildScrollView(
                controller: editScrollController,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 10, bottom: 15),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: formWidgets,
                    ),
                  ),
                ))));
  }

  @override
  Widget build(BuildContext context) {
    queryData = MediaQuery.of(context);
    listKeys.clear();
    if (showCheckBox == false) {
      guidListChecked.clear();
    }
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return MultiBlocListener(
            listeners: [
              BlocListener<PosSettingBloc, PosSettingState>(
                listener: (context, state) {
                  if (state is GetApiKeySuccess) {
                    setState(() {
                      activeAPIKEY = state.token;
                      if (activeAPIKEY.isNotEmpty) {
                        activatePin();
                      } else {
                        setState(() {
                          global.showSnackBar(
                            context,
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                            ),
                            global.language("not_success_get_apikey"),
                            Colors.red,
                          );
                        });
                      }
                    });
                  } else if (state is GetApiKeyFailed) {
                    setState(() {
                      global.showSnackBar(
                        context,
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                        ),
                        state.message,
                        Colors.red,
                      );
                    });
                  }

                  if (state is DeleteApikeySuccess) {
                    setState(() {
                      activeAPIKEY = '';
                      screenData.activepin = "";
                      updateData(screenData.guidfixed!);

                      /// close dialog
                      Navigator.pop(context);
                    });
                  } else if (state is DeleteApikeyFailed) {
                    setState(() {
                      global.showSnackBar(
                        context,
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                        ),
                        state.message,
                        Colors.red,
                      );
                    });
                  }
                },
              ),
              BlocListener<OrderSettingBloc, OrderSettingState>(
                listener: (context, state) {
                  blocCurrentState = state;
                  // Load
                  if (state is OrderSettingLoadSuccess) {
                    setState(() {
                      loadingData = false;
                      if (state.orderSettings.isNotEmpty) {
                        listData.addAll(state.orderSettings);
                      }
                    });
                  }
                  if (state is OrderSettingLoadFailed) {
                    setState(() {
                      loadingData = false;
                    });
                  }
                  // Save
                  if (state is OrderSettingSaveSuccess) {
                    setState(() {
                      global.showSnackBar(
                          context,
                          const Icon(
                            Icons.save,
                            color: Colors.white,
                          ),
                          global.language("save_success"),
                          Colors.blue);
                      clearEditData();
                      listData.clear();
                      loadDataList(searchText);
                    });
                  }
                  if (state is OrderSettingSaveFailed) {
                    setState(() {
                      global.showSnackBar(
                          context,
                          const Icon(
                            Icons.save,
                            color: Colors.white,
                          ),
                          "//${global.language("not_success_save")} : ${state.message}",
                          Colors.red);
                    });
                  }
                  // Update
                  if (state is OrderSettingUpdateSuccess) {
                    setState(() {
                      global.showSnackBar(
                          context,
                          const Icon(
                            Icons.edit,
                            color: Colors.white,
                          ),
                          global.language("edit_success"),
                          Colors.blue);
                      clearEditData();
                      listData.clear();
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        tabController.animateTo(0);
                      });
                      loadDataList(searchText);
                      isSaveAllow = false;
                      getData(selectGuid);
                    });
                  }
                  if (state is OrderSettingUpdateFailed) {
                    setState(() {
                      global.showSnackBar(
                          context,
                          const Icon(
                            Icons.edit,
                            color: Colors.white,
                          ),
                          "${global.language("not_edit_success")} : ${state.message}",
                          Colors.red);
                    });
                  }
                  // Delete
                  if (state is OrderSettingDeleteSuccess) {
                    setState(() {
                      global.showSnackBar(
                          context,
                          const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                          global.language("delete_success"),
                          Colors.blue);
                      listData.clear();
                      clearEditData();
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        tabController.animateTo(0);
                      });
                      loadDataList(searchText);
                    });
                  }
                  // Delete Many
                  if (state is OrderSettingDeleteManySuccess) {
                    setState(() {
                      global.showSnackBar(
                          context,
                          const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                          global.language("delete_success"),
                          Colors.blue);
                      listData.clear();
                      clearEditData();
                      loadDataList(searchText);
                      showCheckBox = false;
                    });
                  }
                  // Get
                  if (state is OrderSettingGetSuccess) {
                    setState(() {
                      isDataChange = false;
                      screenData = state.orderSettings;

                      if (screenData.settingcode!.isNotEmpty) {
                        context.read<OrderTemplateSettingBloc>().add(OrderTemplateSettingGet(guid: screenData.settingcode!));
                      }

                      loadDataToScreen();

                      if (isEditMode) {
                        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                          tabController.animateTo(1);
                        });
                        setState(() {});
                      }
                    });
                    if (currentListIndex >= 0) {
                      RenderBox? boxHeader = headerKey.currentContext?.findRenderObject() as RenderBox?;
                      Offset? positionheader = boxHeader?.localToGlobal(Offset.zero);
                      RenderBox? box = listKeys[currentListIndex].currentContext?.findRenderObject() as RenderBox?;
                      Offset? position = box?.localToGlobal(Offset.zero);
                      if (position != null && positionheader != null && boxHeader != null && box != null) {
                        // Scroll Up
                        if (isKeyUp && position.dy <= (positionheader.dy + (boxHeader.size.height + (box.size.height * 2)))) {
                          setState(() {
                            listScrollController.animateTo(listScrollController.offset - (boxHeader.size.height + box.size.height),
                                duration: const Duration(milliseconds: 100), curve: Curves.ease);
                            isKeyUp = false;
                          });
                        }
                        // Scroll Down
                        if (isKeyDown && position.dy > (queryData.size.height - 100)) {
                          setState(() {
                            listScrollController.animateTo(listScrollController.offset + (position.dy - (queryData.size.height - 100)),
                                duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
                            isKeyDown = false;
                          });
                        }
                      }
                    }
                  }
                },
              ),
              BlocListener<OrderTemplateSettingBloc, OrderTemplateSettingState>(
                listener: (context, state) {
                  if (state is OrderTemplateSettingGetSuccess) {
                    setState(() {
                      screenData.settingname = state.orderTemplateSettings.code;
                    });
                  }
                },
              ),
            ],
            child: (constraints.maxWidth > 800)
                ? SplitView(
                    controller: splitViewController,
                    gripSize: 8,
                    gripColor: global.theme.appBarColor,
                    gripColorActive: Colors.blue,
                    viewMode: SplitViewMode.Horizontal,
                    indicator: const SplitIndicator(viewMode: SplitViewMode.Horizontal),
                    activeIndicator: const SplitIndicator(
                      viewMode: SplitViewMode.Horizontal,
                      isActive: true,
                    ),
                    children: [
                      listScreen(mobileScreen: false),
                      editScreen(mobileScreen: false),
                    ],
                  )
                : TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: tabController,
                    children: [listScreen(mobileScreen: true), editScreen(mobileScreen: true)],
                  ),
          );
        },
      ),
    );
  }

  List<Widget> listNamesFields(List<LanguageDataModel> names, String fieldname) {
    List<Widget> forms = [];
    for (int languageIndex = 0; languageIndex < languageList.length; languageIndex++) {
      LanguageDataModel nameObj = names.firstWhere((element) => element.code == languageList[languageIndex].code!, orElse: () => LanguageDataModel(code: '', name: ''));
      if (nameObj.code == '') {
        names.add(LanguageDataModel(code: languageList[languageIndex].code!, name: ''));
      }
    }
    for (int languageIndex = 0; languageIndex < languageList.length; languageIndex++) {
      LanguageDataModel nameObj = names.firstWhere((element) => element.code == languageList[languageIndex].code!, orElse: () => LanguageDataModel(code: '', name: ''));
      if (nameObj.code != '') {
        forms.add(Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextFormField(
            readOnly: !isEditMode,
            enabled: isEditMode,
            onChanged: (value) {
              isDataChange = true;
              nameObj.name = value;
            },
            textAlign: TextAlign.left,
            controller: TextEditingController(text: nameObj.name),
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              labelText: "${global.language(fieldname)} (${getLangName(nameObj.code)})",
            ),
            validator: (value) {
              // if (languageIndex == 0) {
              //   if (value == null || value.isEmpty) {
              //     return 'This field is required';
              //   }
              // }

              return null;
            },
          ),
        ));
      }
    }

    return forms;
  }
}

// Create an input widget that takes only one digit
class OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final bool autoFocus;
  const OtpInput(this.controller, this.autoFocus, {super.key});

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: FocusNode(skipTraversal: true),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.backspace) {
            if (controller.text.isEmpty) {
              FocusScope.of(context).previousFocus();
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: 60,
          width: 50,
          child: TextField(
            autofocus: autoFocus,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            controller: controller,
            maxLength: 1,
            cursorColor: Theme.of(context).primaryColor,
            decoration: const InputDecoration(border: OutlineInputBorder(), counterText: '', hintStyle: TextStyle(color: Colors.black, fontSize: 20.0)),
            onChanged: (value) {
              if (value.length == 1) {
                FocusScope.of(context).nextFocus();
              }
            },
          ),
        ),
      ),
    );
  }
}
