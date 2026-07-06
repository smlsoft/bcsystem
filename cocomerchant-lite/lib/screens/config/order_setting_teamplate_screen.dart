import 'package:cocomerchant_lite/bloc/company_branch/company_branch_bloc.dart';
import 'package:cocomerchant_lite/bloc/order_template_setting/order_template_setting_bloc.dart';
import 'package:cocomerchant_lite/bloc/pos_media/pos_media_bloc.dart';
import 'package:cocomerchant_lite/bloc/sale_channel/sale_channel_bloc.dart';
import 'package:cocomerchant_lite/model/book_bank_model.dart';
import 'package:cocomerchant_lite/model/pos_media_model.dart';
import 'package:cocomerchant_lite/model/order_template_setting_model.dart';
import 'package:cocomerchant_lite/model/qr_model.dart';
import 'package:cocomerchant_lite/model/sale_channel_model.dart';
import 'package:cocomerchant_lite/model/table_model.dart';
import 'package:cocomerchant_lite/screen_search/bookbank_select_screen.dart';
import 'package:cocomerchant_lite/screen_search/pos_media_search_screen.dart';
import 'package:cocomerchant_lite/screen_search/qr_search_screen.dart';
import 'package:cocomerchant_lite/screen_search/sale_chanels_search_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:split_view/split_view.dart';

class OrderTemplateSettingScreen extends StatefulWidget {
  const OrderTemplateSettingScreen({Key? key}) : super(key: key);

  @override
  State<OrderTemplateSettingScreen> createState() => OrderTemplateSettingScreenState();
}

class OrderTemplateSettingScreenState extends State<OrderTemplateSettingScreen> with SingleTickerProviderStateMixin {
  late TabController tabController;
  ScrollController editScrollController = ScrollController();
  TextEditingController searchController = TextEditingController();
  List<LanguageModel> languageList = <LanguageModel>[];
  List<OrderTemplateSettingModel> listData = [];
  List<String> guidListChecked = [];
  List<LanguageDataModel> names = [];
  ScrollController listScrollController = ScrollController();
  List<GlobalKey> listKeys = [];
  String searchText = "";
  String selectGuid = "";
  bool isDataChange = false;
  bool isSaveAllow = false;
  late OrderTemplateSettingState blocCurrentState;
  String headerEdit = "";
  late MediaQueryData queryData;
  int currentListIndex = -1;
  GlobalKey headerKey = GlobalKey();
  bool isKeyUp = false;
  bool isKeyDown = false;
  bool showCheckBox = false;
  bool isEditMode = false;
  late OrderTemplateSettingModel screenData;
  late SplitViewController splitViewController;
  final debouncer = global.Debouncer(1000);
  bool loadingData = false;
  late DateTime dateNow = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  TextEditingController codeController = TextEditingController();
  TextEditingController labelController = TextEditingController();

  List<TextEditingController> bookBankQrSerchController = [];
  List<TextEditingController> salechannelserchController = [];

  late PosMediaModel posMediaData;
  late TableModel tableData;

  final List<TimeOfDay> _selectedTime = [];
  List<TextEditingController> mediaFromTimeController = [];
  List<TextEditingController> mediaToTimeController = [];

  List<SaleChannelModel> saleChannelListData = [];

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
    labelController.dispose();

    super.dispose();
  }

  void loadDataList(String search) {
    setState(() {
      loadingData = true;
    });
    searchText = search;
    context.read<OrderTemplateSettingBloc>().add(OrderTemplateSettingLoadList(offset: (listData.isEmpty) ? 0 : listData.length, limit: global.loadDataPerPage, search: search));
    context.read<SaleChannelBloc>().add(const SaleChannelLoadList(offset: 0, limit: 100, search: ""));
  }

  void onScrollList() {
    if (listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange) {
      loadDataList(searchText);
    }
  }

  void clearEditData() {
    listScrollController.addListener(onScrollList);

    screenData = OrderTemplateSettingModel(
      branch: BranchModel(
        code: "",
        guidfixed: '',
        names: [],
      ),
      code: '',
      devicenumber: '',
      guidfixed: '',
      activepin: '',
      mediaguid: '',
      qrcodes: [],
      timeforsales: [],
      devicetype: 0,
      tablenumber: '',
      docformat: 'YYMMDD####',
      orderdevices: [],
      label: "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20",
      salechannels: [],
    );
    bookBankQrSerchController = [];
    salechannelserchController = [];

    posMediaData = PosMediaModel(
      guidfixed: '',
      code: '',
      description: [],
      resources: [],
    );

    tableData = TableModel(
      guidfixed: '',
      number: '',
      names: [],
      zone: '',
      xorder: 0,
    );

    mediaFromTimeController = [];
    mediaToTimeController = [];

    isDataChange = false;
    setState(() {
      loadDataToScreen();
    });
  }

  void loadDataToScreen() {
    codeController.text = screenData.code!;
    labelController.text = screenData.label!;

    if (screenData.qrcodes!.isNotEmpty) {
      for (int i = 0; i < screenData.qrcodes!.length; i++) {
        bookBankQrSerchController.add(TextEditingController());
        bookBankQrSerchController[i].text = "${screenData.qrcodes![i].bankcode} ~ ${screenData.qrcodes![i].bookbankcode!}";
      }
    }

    if (screenData.salechannels!.isNotEmpty) {
      for (int i = 0; i < screenData.salechannels!.length; i++) {
        salechannelserchController.add(TextEditingController());

        SaleChannelModel saleChannel = saleChannelListData.firstWhere((element) => element.guidfixed == screenData.salechannels![i]);

        salechannelserchController[i].text = "${saleChannel.code} ~ ${saleChannel.name}";
      }
    }

    if (screenData.timeforsales!.isNotEmpty) {
      for (int i = 0; i < screenData.timeforsales!.length; i++) {
        _selectedTime.add(TimeOfDay.now());
        mediaFromTimeController.add(TextEditingController());
        mediaToTimeController.add(TextEditingController());

        mediaFromTimeController[i].text = screenData.timeforsales![i].from!;
        mediaToTimeController[i].text = screenData.timeforsales![i].to!;
      }
    }
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
    context.read<OrderTemplateSettingBloc>().add(OrderTemplateSettingGet(guid: guid));
  }

  void switchToEdit(OrderTemplateSettingModel value) {
    setState(() {
      selectGuid = value.guidfixed!;
      getData(selectGuid);
      headerEdit = global.language("edit");
      isSaveAllow = true;
      isEditMode = true;
    });
  }

  Widget listScreen({bool mobileScreen = false}) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: global.theme.appBarColor,
        automaticallyImplyLeading: false,
        title: Text(global.language("order_template_setting")),
        leading: IconButton(
          focusNode: FocusNode(skipTraversal: true),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            discardData(callBack: () {
              Navigator.pop(context);
            });
          },
        ),
        actions: <Widget>[
          Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: IconButton(
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
              )),
          if (guidListChecked.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: IconButton(
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
                                context.read<OrderTemplateSettingBloc>().add(OrderTemplateSettingDeleteMany(guid: guidListChecked));
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
                )),

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
      body: Focus(
        focusNode: FocusNode(skipTraversal: true, canRequestFocus: true),
        onKeyEvent: (node, event) {
          if (kIsWeb) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                isKeyDown = false;
                int index = listData.indexOf(listData.firstWhere((element) => element.guidfixed == selectGuid));
                if (index > 0) {
                  selectGuid = listData[index - 1].guidfixed!;
                  currentListIndex = index + 1;
                  isKeyUp = true;
                  getData(selectGuid);
                }
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                isKeyUp = false;
                int index = listData.indexOf(listData.firstWhere((element) => element.guidfixed == selectGuid));
                selectGuid = listData[index + 1].guidfixed!;
                currentListIndex = index + 1;
                isKeyDown = true;
                getData(selectGuid);
              }
            }
          }
          return KeyEventResult.ignored;
        },
        child: Column(children: [
          Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(children: [
                Expanded(
                    child: TextField(
                        onSubmitted: (value) {},
                        onChanged: (value) {
                          debouncer.run(() {
                            setState(() {
                              listData = [];
                            });
                            loadDataList(value);
                          });
                        },
                        autofocus: false,
                        controller: searchController,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.only(top: 0, bottom: 0, left: 0, right: 0),
                          border: InputBorder.none,
                          hintText: global.language('search'),
                        ))),
                IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    icon: const Icon(Icons.font_download_rounded),
                    onPressed: () async {
                      setState(() {
                        global.listDataFontSizeChange();
                      });
                    }),
                IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    icon: const Icon(Icons.line_weight),
                    onPressed: () async {
                      setState(() {
                        global.listDataLineSpaceChange();
                      });
                    })
              ])),
          Container(
            color: global.theme.appBarColor,
            height: 6,
          ),
          Container(
              key: headerKey,
              padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
              color: global.theme.columnHeaderColor,
              child: Row(children: [
                Expanded(
                    flex: 5,
                    child: Text(global.language("order_template_setting_code"),
                        style: TextStyle(color: global.theme.columnHeaderTextColor, fontWeight: FontWeight.bold, fontSize: global.deviceConfig.listDataFontSize + 2))),
                Expanded(
                    flex: 5,
                    child: Text(
                      global.language("order_template_setting_code"),
                      style: TextStyle(color: global.theme.columnHeaderTextColor, fontWeight: FontWeight.bold, fontSize: global.deviceConfig.listDataFontSize + 2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )),
                if (showCheckBox) Expanded(flex: 1, child: Icon(Icons.check, color: global.theme.columnHeaderTextColor, size: 12))
              ])),
          Expanded(child: ListView(controller: listScrollController, children: listData.map((value) => listObject(listData.indexOf(value), value, showCheckBox)).toList())),
          if (loadingData)
            Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
              color: Colors.blue,
              size: 50,
            ))
        ]),
      ),
    );
  }

  Widget listObject(int index, OrderTemplateSettingModel value, bool showCheckBox) {
    bool isCheck = false;
    for (int i = 0; i < guidListChecked.length; i++) {
      if (guidListChecked[i] == value.guidfixed) {
        isCheck = true;
        break;
      }
    }
    listKeys.add(GlobalKey());
    bool selected = selectGuid == value.guidfixed;
    TextStyle textStyle = TextStyle(
        fontWeight: (selected) ? FontWeight.bold : FontWeight.normal, fontSize: (selected) ? global.deviceConfig.listDataFontSize + 2.0 : global.deviceConfig.listDataFontSize);
    return GestureDetector(
      onTap: () {
        if (showCheckBox == true) {
          setState(() {
            selectGuid = value.guidfixed!;
            if (isCheck == true) {
              guidListChecked.remove(value.guidfixed);
            } else {
              guidListChecked.add(value.guidfixed!);
            }
            global.showSnackBar(
                context,
                const Icon(
                  Icons.check,
                  color: Colors.white,
                ),
                "${global.language("chosen")} ${guidListChecked.length} ${global.language("list")}",
                Colors.blue);
          });
        } else {
          setState(() {
            discardData(callBack: () {
              isSaveAllow = false;
              isEditMode = false;
              selectGuid = value.guidfixed!;
              getData(selectGuid);
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                tabController.animateTo(1);
              });
            });
          });
        }
      },
      onDoubleTap: () {
        if (showCheckBox == false) {
          switchToEdit(value);
        }
      },
      child: Container(
        key: listKeys.last,
        decoration: BoxDecoration(
          color: (selectGuid == value.guidfixed)
              ? Colors.cyan[100]
              : (index % 2 == 0)
                  ? global.theme.columnAlternateEvenColor
                  : global.theme.columnAlternateOddColor,
        ),
        padding: EdgeInsets.only(left: 10, right: 10, top: global.deviceConfig.listDataLineSpace, bottom: global.deviceConfig.listDataLineSpace),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: Text(value.code!, maxLines: 2, overflow: TextOverflow.ellipsis, style: textStyle)),
            Expanded(flex: 5, child: Text(value.code!, maxLines: 2, overflow: TextOverflow.ellipsis, style: textStyle)),
            if (showCheckBox) Expanded(flex: 1, child: (isCheck) ? Icon(Icons.check, size: global.deviceConfig.listDataFontSize) : Container())
          ],
        ),
      ),
    );
  }

  void saveOrUpdateData() {
    if (verifyData(screenData)) {
      showCheckBox = false;
      // print(screenData.toJson());
      if (selectGuid.trim().isEmpty) {
        context.read<OrderTemplateSettingBloc>().add(OrderTemplateSettingSave(orderTemplateSetting: screenData));
      } else {
        updateData(selectGuid);
      }
    }
  }

  bool verifyData(OrderTemplateSettingModel value) {
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

    context.read<OrderTemplateSettingBloc>().add(OrderTemplateSettingUpdate(guid: guid, orderTemplateSetting: screenData));
  }

  String getLangName(String code) {
    LanguageModel name = languageList.firstWhere((element) => element.code == code, orElse: () => LanguageModel(code: '', codeTranslator: '', name: '', isuse: false));
    return name.name!;
  }

  void _selecttimeforsalesFrom(BuildContext context, int index) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime[index],
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    // ignore: unrelated_type_equality_checks
    if (pickedTime != null) {
      setState(() {
        // Format the hour and minute to ensure they have two digits (e.g., 09, 12, 23, etc.)
        String formattedHour = pickedTime.hour.toString().padLeft(2, '0');
        String formattedMinute = pickedTime.minute.toString().padLeft(2, '0');

        // Combine the formatted hour and minute with a ":" separator
        String formattedTime = '$formattedHour:$formattedMinute';

        screenData.timeforsales![index].from = formattedTime;
        mediaFromTimeController[index].text = formattedTime;
      });
    }
  }

  void _selectMediaToTime(BuildContext context, int index) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime[index],
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    // ignore: unrelated_type_equality_checks
    if (pickedTime != null) {
      setState(() {
        // Format the hour and minute to ensure they have two digits (e.g., 09, 12, 23, etc.)
        String formattedHour = pickedTime.hour.toString().padLeft(2, '0');
        String formattedMinute = pickedTime.minute.toString().padLeft(2, '0');

        // Combine the formatted hour and minute with a ":" separator
        String formattedTime = '$formattedHour:$formattedMinute';

        // Convert the time string to a TimeOfDay object
        TimeOfDay fromTime = global.getTimeOfDayFromString(screenData.timeforsales![index].from!);
        TimeOfDay toTime = global.getTimeOfDayFromString(formattedTime);

        // Check if toTime is not earlier than fromTime
        if (toTime.hour < fromTime.hour || (toTime.hour == fromTime.hour && toTime.minute <= fromTime.minute)) {
          global.showSnackBar(
            context,
            const Icon(
              Icons.edit,
              color: Colors.white,
            ),
            global.language("to_time_must_be_later_than_from_time"),
            Colors.red,
          );
          screenData.timeforsales![index].to = '';
          mediaToTimeController[index].text = '';
          return;
        } else {
          // Update the toTime and the text in the text field
          screenData.timeforsales![index].to = formattedTime;
          mediaToTimeController[index].text = formattedTime;
        }
      });
    }
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
            labelText: global.language("order_template_setting_code"),
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
          controller: labelController,
          textCapitalization: TextCapitalization.characters,
          // inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('[a-z A-Z 0-9 -]'))],
          onChanged: (value) {
            isDataChange = true;
            screenData.label = value;
            labelController.value = TextEditingValue(text: value, selection: labelController.selection);
          },
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
            labelText: global.language("order_code"),
          ),
          onEditingComplete: () {},
        ),
      ),
    );

    if (screenData.qrcodes!.isNotEmpty) {
      formWidgets.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const Divider(),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  global.language("qrcode_list"),
                ),
              ),
            ],
          ),
        ),
      );
    }

    for (int i = 0; i < screenData.qrcodes!.length; i++) {
      formWidgets.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(const Color.fromARGB(255, 238, 86, 144)),
                            ),
                            onPressed: (isEditMode)
                                ? () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const QrSearchScreen(
                                                  word: "",
                                                ))).then((value) {
                                      setState(() {
                                        if (value.guidfixed.isNotEmpty) {
                                          screenData.qrcodes![i] = value;
                                          bookBankQrSerchController[i].text = "${value.bankcode} ~ ${global.packName(value.bookbanknames!)}";
                                        }
                                      });
                                    });
                                  }
                                : null,
                            child: Row(
                              children: [
                                Icon((screenData.qrcodes![i].guidfixed!.isEmpty) ? Icons.search : Icons.qr_code),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  (screenData.qrcodes![i].guidfixed!.isEmpty)
                                      ? global.language("serch_qrcode")
                                      : "${screenData.qrcodes![i].code} ~ ${global.packName(screenData.qrcodes![i].qrnames!)}",
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      IconButton(
                        onPressed: (isEditMode)
                            ? () {
                                setState(() {
                                  screenData.qrcodes!.removeAt(i);
                                });
                              }
                            : null,
                        icon: const Icon(Icons.delete),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  (screenData.qrcodes![i].code!.isNotEmpty)
                      ? Column(
                          children: [
                            TextFormField(
                              readOnly: true,
                              textInputAction: TextInputAction.next,
                              textAlign: TextAlign.left,
                              controller: bookBankQrSerchController[i],
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('[a-z A-Z 0-9 -]'))],
                              onChanged: (value) {},
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                labelText: global.language("bookBank_code"),
                                labelStyle: TextStyle(color: global.theme.inputTextBoxForceColor),
                                suffixIcon: IconButton(
                                  focusNode: FocusNode(skipTraversal: true),
                                  icon: const Icon(Icons.search),
                                  onPressed: () {
                                    (isEditMode)
                                        ? Navigator.push(context, MaterialPageRoute(builder: (context) => const BookBankSelectScreen())).then((value) {
                                            if (value != null) {
                                              setState(() {
                                                BookBankModel returnValue = value as BookBankModel;
                                                bookBankQrSerchController[i].text = "${returnValue.bankcode} ~ ${returnValue.passbook}";
                                                screenData.qrcodes![i].bankcode = returnValue.bankcode;
                                                screenData.qrcodes![i].banknames = returnValue.banknames;
                                                screenData.qrcodes![i].bookbankcode = returnValue.passbook;
                                                screenData.qrcodes![i].bookbanknames = returnValue.names;
                                                screenData.qrcodes![i].bookbankimages = returnValue.images;
                                              });
                                            }
                                          })
                                        : null;
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 15,
                            ),
                            (screenData.qrcodes![i].qrtype == 100) ? fromPromptPay(i) : fromLugent(i),
                          ],
                        )
                      : Container(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all<Color>(const Color.fromARGB(255, 148, 160, 194)),
              foregroundColor: WidgetStateProperty.all<Color>(const Color.fromARGB(255, 0, 0, 0)),
            ),
            focusNode: FocusNode(skipTraversal: true),
            onPressed: (isEditMode)
                ? () {
                    setState(() {
                      bookBankQrSerchController.add(TextEditingController());
                      screenData.qrcodes?.add(QrModel(
                        guidfixed: "",
                        code: "",
                        qrnames: [],
                        qrtype: 100,
                        isactive: true,
                        logo: "",
                        bankcode: "",
                        banknames: [],
                        bookbankcode: "",
                        bookbanknames: [],
                        bookbankimages: [],
                        qrcode: "",
                        apikey: "",
                        billerCode: "",
                        billerID: "",
                        storeID: "",
                        terminalID: "",
                        merchantName: "",
                        accessCode: "",
                        bankcharge: "",
                        customercharge: "",
                      ));
                    });
                  }
                : null,
            icon: const Icon(Icons.qr_code),
            label: Text(
              global.language("add_qrcode"),
            ),
          ),
        ),
      ),
    );

    /// สื่อโฆษณา
    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Container(
          padding: const EdgeInsets.only(bottom: 5),
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all<Color>(const Color.fromARGB(255, 208, 42, 158)),
            ),
            onPressed: (isEditMode)
                ? () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PosMediaSearchScreen(
                                  word: '',
                                ))).then((value) {
                      setState(() {
                        global.SearchGuidCodeNameModel result = value;
                        if (result.isCancel == false) {
                          screenData.mediaguid = result.guid;

                          posMediaData.code = result.code;
                          posMediaData.description = result.names;
                        }
                      });
                    });
                  }
                : null,
            icon: const Icon(Icons.live_tv_rounded),
            label: Text(
              (screenData.mediaguid!.isEmpty) ? global.language("select_media") : '${posMediaData.code} ~ ${global.packName(posMediaData.description)}',
            ),
          ),
        ),
      ),
    );

    if (screenData.timeforsales!.isNotEmpty) {
      formWidgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
          child: Column(
            children: [
              const Divider(),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  global.language("time_for_sale"),
                ),
              ),
            ],
          ),
        ),
      );
    }

    for (int i = 0; i < screenData.timeforsales!.length; i++) {
      formWidgets.add(
        Container(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
          width: double.infinity,
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              Column(
                children: listNamesFields(
                  screenData.timeforsales![i].names!,
                  "name",
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      enabled: isEditMode,
                      controller: mediaFromTimeController[i],
                      onTap: () async {
                        _selecttimeforsalesFrom(context, i);
                      },
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: global.language("from_time"),
                        border: const OutlineInputBorder(),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        suffixIcon: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              focusNode: FocusNode(skipTraversal: true),
                              icon: const Icon(Icons.timer_sharp),
                              onPressed: () {
                                _selecttimeforsalesFrom(context, i);
                              },
                            ),
                          ],
                        ),
                      ),
                      inputFormatters: [
                        global.TimeInputFormatter(),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: TextFormField(
                      enabled: isEditMode,
                      controller: mediaToTimeController[i],
                      onTap: () async {
                        _selectMediaToTime(context, i);
                      },
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: global.language("from_to"),
                        border: const OutlineInputBorder(),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        suffixIcon: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              focusNode: FocusNode(skipTraversal: true),
                              icon: const Icon(Icons.timer_sharp),
                              onPressed: () {
                                _selectMediaToTime(context, i);
                              },
                            ),
                          ],
                        ),
                      ),
                      inputFormatters: [
                        global.TimeInputFormatter(),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  IconButton(
                    onPressed: (isEditMode)
                        ? () {
                            setState(() {
                              mediaFromTimeController.removeAt(i);
                              mediaToTimeController.removeAt(i);
                              screenData.timeforsales!.removeAt(i);
                            });
                          }
                        : null,
                    icon: const Icon(Icons.delete),
                  )
                ],
              ),
            ],
          ),
        ),
      );
    }

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: SizedBox(
          height: 50,
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all<Color>(const Color.fromARGB(255, 148, 194, 168)),
              foregroundColor: WidgetStateProperty.all<Color>(const Color.fromARGB(255, 0, 0, 0)),
            ),
            focusNode: FocusNode(skipTraversal: true),
            onPressed: (isEditMode)
                ? () {
                    setState(() {
                      _selectedTime.add(TimeOfDay.now());
                      mediaFromTimeController.add(TextEditingController());
                      mediaToTimeController.add(TextEditingController());
                      screenData.timeforsales!.add(TimeForsaleModel(
                        from: '',
                        names: [],
                        to: '',
                      ));
                    });
                  }
                : null,
            icon: const Icon(Icons.access_time_sharp),
            label: Text(
              global.language("add_time_for_sale"),
            ),
          ),
        ),
      ),
    );

    /// ช่องทางการขาย
    if (screenData.salechannels!.isNotEmpty) {
      formWidgets.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const Divider(),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  global.language("sale_channel_list"),
                ),
              ),
            ],
          ),
        ),
      );
    }

    for (int i = 0; i < screenData.salechannels!.length; i++) {
      formWidgets.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(const Color.fromARGB(255, 231, 206, 209)),
                              foregroundColor: WidgetStateProperty.all<Color>(const Color.fromARGB(255, 0, 0, 0)),
                            ),
                            onPressed: (isEditMode)
                                ? () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => const SalechannelsSearchScreen(
                                                  word: "",
                                                ))).then((value) {
                                      setState(() {
                                        if (value.guidfixed.isNotEmpty) {
                                          screenData.salechannels![i] = value.guidfixed.toString();
                                          salechannelserchController[i].text = "${value.code} ~ ${value.name!}";
                                        }
                                      });
                                    });
                                  }
                                : null,
                            child: Row(
                              children: [
                                Icon((screenData.salechannels![i].isEmpty) ? Icons.search : Icons.send),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  (screenData.salechannels![i].isEmpty) ? global.language("serch_sale_channel") : salechannelserchController[i].text,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      IconButton(
                        onPressed: (isEditMode)
                            ? () {
                                setState(() {
                                  screenData.salechannels!.removeAt(i);
                                });
                              }
                            : null,
                        icon: const Icon(Icons.delete),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all<Color>(const Color.fromARGB(255, 231, 206, 209)),
              foregroundColor: WidgetStateProperty.all<Color>(const Color.fromARGB(255, 0, 0, 0)),
            ),
            focusNode: FocusNode(skipTraversal: true),
            onPressed: (isEditMode)
                ? () {
                    setState(() {
                      salechannelserchController.add(TextEditingController());
                      screenData.salechannels!.add("");
                    });
                  }
                : null,
            icon: const Icon(Icons.send),
            label: Text(
              global.language("add_sale_channel"),
            ),
          ),
        ),
      ),
    );

    if (isSaveAllow) {
      formWidgets.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15, top: 10),
          child: ElevatedButton.icon(
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
            title: Text(headerEdit + global.language("order_template_setting")),
            actions: <Widget>[
              if (selectGuid.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: IconButton(
                      focusNode: FocusNode(skipTraversal: true),
                      onPressed: () {
                        showCheckBox = false;
                        showDialog<String>(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: Text(global.language('delete_confirm')),
                            actions: <Widget>[
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context), child: Text(global.language('no'))),
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.read<OrderTemplateSettingBloc>().add(OrderTemplateSettingDelete(guid: selectGuid));
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
                    )),
              if (isSaveAllow == false && selectGuid.trim().isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: IconButton(
                      focusNode: FocusNode(skipTraversal: true),
                      onPressed: () {
                        showCheckBox = false;
                        switchToEdit(listData[listData.indexOf(listData.firstWhere((element) => element.guidfixed == selectGuid))]);
                      },
                      icon: const Icon(
                        Icons.edit,
                      ),
                    )),
              if (isSaveAllow == true)
                Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: IconButton(
                      focusNode: FocusNode(skipTraversal: true),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          saveOrUpdateData();
                        }
                      },
                      icon: const Icon(
                        Icons.save,
                      ),
                    ))
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

  Column fromPromptPay(int i) {
    return Column(
      children: [
        TextFormField(
          readOnly: !isEditMode,
          onFieldSubmitted: (value) {},
          maxLength: 14,
          textInputAction: TextInputAction.next,
          textAlign: TextAlign.left,
          controller: TextEditingController(text: screenData.qrcodes![i].qrcode),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9]'))],
          onChanged: (value) {
            isDataChange = true;
            screenData.qrcodes![i].qrcode = value;
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: global.language("telephone_or_citizen_id"),
            labelStyle: TextStyle(color: global.theme.inputTextBoxForceColor),
          ),
        ),
      ],
    );
  }

  Column fromLugent(int i) {
    return Column(
      children: [
        TextFormField(
          readOnly: !isEditMode,
          onFieldSubmitted: (value) {},
          textInputAction: TextInputAction.next,
          textAlign: TextAlign.left,
          controller: TextEditingController(text: screenData.qrcodes![i].apikey),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            isDataChange = true;
            screenData.qrcodes![i].apikey = value;
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: global.language("api_key"),
            labelStyle: TextStyle(color: global.theme.inputTextBoxForceColor),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        TextFormField(
          readOnly: !isEditMode,
          onFieldSubmitted: (value) {},
          textInputAction: TextInputAction.next,
          textAlign: TextAlign.left,
          controller: TextEditingController(text: screenData.qrcodes![i].billerCode),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            isDataChange = true;
            screenData.qrcodes![i].billerCode = value;
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: global.language("biller_code"),
            labelStyle: TextStyle(color: global.theme.inputTextBoxForceColor),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        TextFormField(
          readOnly: !isEditMode,
          onFieldSubmitted: (value) {},
          textInputAction: TextInputAction.next,
          textAlign: TextAlign.left,
          controller: TextEditingController(text: screenData.qrcodes![i].billerID),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            isDataChange = true;
            screenData.qrcodes![i].billerID = value;
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: global.language("biller_id"),
            labelStyle: TextStyle(color: global.theme.inputTextBoxForceColor),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        TextFormField(
          readOnly: !isEditMode,
          onFieldSubmitted: (value) {},
          textInputAction: TextInputAction.next,
          textAlign: TextAlign.left,
          controller: TextEditingController(text: screenData.qrcodes![i].storeID),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            isDataChange = true;
            screenData.qrcodes![i].storeID = value;
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: global.language("store_id"),
            labelStyle: TextStyle(color: global.theme.inputTextBoxForceColor),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        TextFormField(
          readOnly: !isEditMode,
          onFieldSubmitted: (value) {},
          textInputAction: TextInputAction.next,
          textAlign: TextAlign.left,
          controller: TextEditingController(text: screenData.qrcodes![i].terminalID),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            isDataChange = true;
            screenData.qrcodes![i].terminalID = value;
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: global.language("terminal_id"),
            labelStyle: TextStyle(color: global.theme.inputTextBoxForceColor),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        TextFormField(
          readOnly: !isEditMode,
          onFieldSubmitted: (value) {},
          textInputAction: TextInputAction.next,
          textAlign: TextAlign.left,
          controller: TextEditingController(text: screenData.qrcodes![i].merchantName),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            isDataChange = true;
            screenData.qrcodes![i].merchantName = value;
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: global.language("merchant_name"),
            labelStyle: TextStyle(color: global.theme.inputTextBoxForceColor),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        TextFormField(
          readOnly: !isEditMode,
          onFieldSubmitted: (value) {},
          textInputAction: TextInputAction.next,
          textAlign: TextAlign.left,
          controller: TextEditingController(text: screenData.qrcodes![i].accessCode),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            isDataChange = true;
            screenData.qrcodes![i].accessCode = value;
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: global.language("access_code"),
            labelStyle: TextStyle(color: global.theme.inputTextBoxForceColor),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        TextFormField(
          readOnly: !isEditMode,
          onFieldSubmitted: (value) {},
          textInputAction: TextInputAction.next,
          textAlign: TextAlign.left,
          controller: TextEditingController(text: screenData.qrcodes![i].bankcharge),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            isDataChange = true;
            screenData.qrcodes![i].bankcharge = value;
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: global.language("bank_charge"),
            labelStyle: TextStyle(color: global.theme.inputTextBoxForceColor),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        TextFormField(
          readOnly: !isEditMode,
          onFieldSubmitted: (value) {},
          textInputAction: TextInputAction.next,
          textAlign: TextAlign.left,
          controller: TextEditingController(text: screenData.qrcodes![i].customercharge),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            isDataChange = true;
            screenData.qrcodes![i].customercharge = value;
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: global.language("customer_charge"),
            labelStyle: TextStyle(color: global.theme.inputTextBoxForceColor),
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 0),
          child: Row(
            children: [
              Radio(
                focusNode: FocusNode(skipTraversal: true),
                value: 0,
                groupValue: screenData.qrcodes![i].closeqr,
                onChanged: (value) {
                  setState(() {
                    screenData.qrcodes![i].closeqr = value!;
                  });
                },
              ),
              Text(global.language('money_now')),
              const SizedBox(width: 10),
              Radio(
                focusNode: FocusNode(skipTraversal: true),
                value: 1,
                groupValue: screenData.qrcodes![i].closeqr,
                onChanged: (value) {
                  setState(() {
                    screenData.qrcodes![i].closeqr = value!;
                  });
                },
              ),
              Text(global.language('money_end_day')),
              const SizedBox(width: 10),
              Radio(
                focusNode: FocusNode(skipTraversal: true),
                value: 2,
                groupValue: screenData.qrcodes![i].closeqr,
                onChanged: (value) {
                  setState(() {
                    screenData.qrcodes![i].closeqr = value!;
                  });
                },
              ),
              Text(global.language('money_next_day'))
            ],
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 0),
          child: Row(
            children: [
              Radio(
                focusNode: FocusNode(skipTraversal: true),
                value: true,
                groupValue: screenData.qrcodes![i].isactive,
                onChanged: (value) {
                  setState(() {
                    screenData.qrcodes![i].isactive = value!;
                  });
                },
              ),
              Text(global.language('Active')),
              const SizedBox(width: 10),
              Radio(
                focusNode: FocusNode(skipTraversal: true),
                value: false,
                groupValue: screenData.qrcodes![i].isactive,
                onChanged: (value) {
                  setState(() {
                    screenData.qrcodes![i].isactive = value!;
                  });
                },
              ),
              Text(global.language('inactive'))
            ],
          ),
        ),
      ],
    );
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
              BlocListener<CompanyBranchBloc, CompanyBranchState>(listener: (context, state) {
                if (state is CompanyBranchGetBycodeSuccess) {
                  setState(() {
                    if (state.companyBranch.guidfixed.isNotEmpty) {
                      screenData.branch!.guidfixed = state.companyBranch.guidfixed;
                      screenData.branch!.code = state.companyBranch.code;
                      screenData.branch!.names = state.companyBranch.names;
                    }
                  });
                }
              }),
              BlocListener<OrderTemplateSettingBloc, OrderTemplateSettingState>(
                listener: (context, state) {
                  blocCurrentState = state;
                  // Load
                  if (state is OrderTemplateSettingLoadSuccess) {
                    setState(() {
                      loadingData = false;
                      if (state.orderTemplateSettings.isNotEmpty) {
                        listData.addAll(state.orderTemplateSettings);
                      }
                    });
                  }
                  if (state is OrderTemplateSettingLoadFailed) {
                    setState(() {
                      loadingData = false;
                    });
                  }
                  // Save
                  if (state is OrderTemplateSettingSaveSuccess) {
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
                  if (state is OrderTemplateSettingSaveFailed) {
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
                  if (state is OrderTemplateSettingUpdateSuccess) {
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
                  if (state is OrderTemplateSettingUpdateFailed) {
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
                  if (state is OrderTemplateSettingDeleteSuccess) {
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
                  if (state is OrderTemplateSettingDeleteManySuccess) {
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
                  if (state is OrderTemplateSettingGetSuccess) {
                    setState(() {
                      isDataChange = false;
                      screenData = state.orderTemplateSettings;

                      if (screenData.mediaguid!.isNotEmpty) {
                        context.read<PosMediaBloc>().add(PosMediaGet(guid: screenData.mediaguid!));
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
              BlocListener<PosMediaBloc, PosMediaState>(
                listener: (context, state) {
                  if (state is PosMediaGetSuccess) {
                    setState(() {
                      posMediaData = state.posMedia;
                    });
                  }
                },
              ),
              BlocListener<SaleChannelBloc, SaleChannelState>(
                listener: (context, state) {
                  // Load
                  if (state is SaleChannelLoadSuccess) {
                    saleChannelListData = state.salechannel;
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
