import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:split_view/split_view.dart';
import 'package:translator/translator.dart';
import '../../bloc/coupon_bloc.dart';
import '../../bloc/coupon_event.dart';
import '../../bloc/coupon_state.dart';
import '../../model/coupon_model.dart';
import '../../model/global_model.dart';
import '../../screen_search/customer_search_screen.dart';
import '../../widgets/date_picker_widget.dart';
import '../../global.dart' as global;

class CouponScreen extends StatefulWidget {
  const CouponScreen({Key? key}) : super(key: key);

  @override
  State<CouponScreen> createState() => CouponScreenState();
}

class CouponScreenState extends State<CouponScreen> with SingleTickerProviderStateMixin {
  final translator = GoogleTranslator();
  late TabController tabController;
  ScrollController editScrollController = ScrollController();
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode(skipTraversal: true);
  List<LanguageModel> languageList = <LanguageModel>[];
  List<TextEditingController> fieldTextController = [];
  List<global.FieldFocusModel> fieldFocusNodes = [];
  int focusNodeIndex = 0;
  List<CouponModel> listData = [];
  List<String> couponGuidListChecked = [];
  List<LanguageDataModel> names = [];
  List<LanguageDataModel> conditionNames = [];
  ScrollController listScrollController = ScrollController();
  List<GlobalKey> listKeys = [];
  String searchText = "";
  String selectGuid = "";
  bool isChange = false;
  bool isSaveAllow = false;
  late CouponState blocCouponState;
  String headerEdit = "";
  late MediaQueryData queryData;
  int currentListIndex = -1;
  GlobalKey headerKey = GlobalKey();
  bool isKeyUp = false;
  bool isKeyDown = false;
  global.ScreenEventEnum screenEvent = global.ScreenEventEnum.list;
  late SplitViewController splitViewController;
  final debouncer = global.Debouncer(1000);
  bool isLoadTranslation = false;

  // Coupon specific fields - additional to multi-language fields
  late TextEditingController couponCodeController;
  late TextEditingController couponValueController;
  late TextEditingController remarkController;
  late TextEditingController maxUsageCountController;
  late TextEditingController maxUsageCountPerCustomerController;
  late TextEditingController customerCodesController;

  late FocusNode couponCodeFocusNode;
  late FocusNode couponValueFocusNode;
  late FocusNode remarkFocusNode;
  late FocusNode maxUsageCountFocusNode;
  late FocusNode maxUsageCountPerCustomerFocusNode;
  late FocusNode customerCodesFocusNode;

  DateTime? issuedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? expiryDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
  int couponType = 0;
  int status = 0;
  bool isOneTimeUse = false;
  List<String> customerCodes = [];

  // Error states for validation
  Map<String, String> fieldErrors = {};

  void changeScreenEvent(global.ScreenEventEnum event) {
    screenEvent = event;
    for (int index = 0; index < fieldFocusNodes.length; index++) {
      fieldFocusNodes[index].isReadOnly = (screenEvent == global.ScreenEventEnum.list) ? true : false;
    }
    if (screenEvent == global.ScreenEventEnum.edit) {
      fieldFocusNodes[0].isReadOnly = true;
    }
    setState(() {});
  }

  void setSystemLanguageList() async {
    await global.setSystemLanguage(context);

    for (int i = 0; i < global.config.languages.length; i++) {
      if (global.config.languages[i].isuse!) {
        languageList.add(global.config.languages[i]);
      }
    }

    // Add fieldTextController and focusNodes for each language
    for (int i = 0; i < languageList.length; i++) {
      fieldTextController.add(TextEditingController());
      FocusNode focusNode = FocusNode();
      int actualIndex = i + 1; // +1 because coupon code is at index 0
      focusNode.addListener(() {
        focusNodeIndex = actualIndex;
      });
      fieldFocusNodes.add(global.FieldFocusModel(focusNode: focusNode));
    }

    loadDataList("");
  }

  @override
  void initState() {
    tabController = TabController(vsync: this, length: 2);
    tabController.addListener(() {
      setState(() {});
    });

    splitViewController = SplitViewController(limits: [null, WeightLimit(min: 0.2, max: 0.8)]);

    // Initialize coupon specific controllers and focus nodes
    couponCodeController = TextEditingController();
    couponValueController = TextEditingController();
    remarkController = TextEditingController();
    maxUsageCountController = TextEditingController();
    maxUsageCountPerCustomerController = TextEditingController();
    customerCodesController = TextEditingController();

    couponCodeFocusNode = FocusNode();
    couponValueFocusNode = FocusNode();
    remarkFocusNode = FocusNode();
    maxUsageCountFocusNode = FocusNode();
    maxUsageCountPerCustomerFocusNode = FocusNode();
    customerCodesFocusNode = FocusNode();

    // Add coupon code field as first field (similar to brand code)
    FocusNode focusNode = FocusNode();
    focusNode.addListener(() {
      focusNodeIndex = 0;
    });
    fieldFocusNodes.add(global.FieldFocusModel(focusNode: focusNode));
    fieldTextController.add(TextEditingController());

    setSystemLanguageList();
    listScrollController.addListener(onScrollList);

    super.initState();
  }

  void loadDataList(String search) {
    context.read<CouponBloc>().add(GetCoupons());
  }

  void onScrollList() {
    if (listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange) {
      loadDataList(searchText);
    }
  }

  @override
  void dispose() {
    listScrollController.dispose();
    tabController.dispose();
    editScrollController.dispose();
    searchController.dispose();

    // Dispose coupon specific controllers
    couponCodeController.dispose();
    couponValueController.dispose();
    remarkController.dispose();
    maxUsageCountController.dispose();
    maxUsageCountPerCustomerController.dispose();
    customerCodesController.dispose();

    // Dispose coupon specific focus nodes
    couponCodeFocusNode.dispose();
    couponValueFocusNode.dispose();
    remarkFocusNode.dispose();
    maxUsageCountFocusNode.dispose();
    maxUsageCountPerCustomerFocusNode.dispose();
    customerCodesFocusNode.dispose();

    for (int i = 0; i < fieldTextController.length; i++) {
      fieldTextController[i].dispose();
    }
    for (int i = 0; i < fieldFocusNodes.length; i++) {
      fieldFocusNodes[i].focusNode.dispose();
    }

    super.dispose();
  }

  void clearEditData() {
    for (int i = 0; i < fieldTextController.length; i++) {
      fieldTextController[i].clear();
    }
    couponCodeController.clear();
    couponValueController.clear();
    remarkController.clear();
    maxUsageCountController.clear();
    maxUsageCountPerCustomerController.clear();
    // ไม่ต้อง clear customerCodesController เพราะเราใช้ customerCodes list โดยตรง

    issuedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
    expiryDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0, 23, 59, 59);
    couponType = 0;
    status = 0; // Default to active (0 = เปิด)
    isOneTimeUse = false;
    customerCodes.clear();
    names.clear();
    conditionNames.clear();
    fieldErrors.clear(); // Clear validation errors

    isChange = false;
    focusNodeIndex = 0;
    if (fieldFocusNodes.isNotEmpty) {
      fieldFocusNodes[focusNodeIndex].focusNode.requestFocus();
    }
  }

  void discardData({required Function callBack}) {
    if ((screenEvent == global.ScreenEventEnum.add || screenEvent == global.ScreenEventEnum.edit) && isChange) {
      showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                title: Text(global.language('data_editing')),
                content: Text(global.language('leave_this_screen')),
                actions: <Widget>[
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: global.theme.buttonNoColor), onPressed: () => Navigator.pop(context), child: Text(global.language('no'))),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: global.theme.buttonYesColor),
                      onPressed: () {
                        Navigator.pop(context);
                        callBack();
                      },
                      child: Text(global.language('yes'))),
                ],
              ));
    } else {
      callBack();
    }
  }

  void getData(String guid) {
    headerEdit = global.language("show");
    changeScreenEvent(global.ScreenEventEnum.list);
    context.read<CouponBloc>().add(GetCouponById(id: guid));
  }

  Widget listScreen({bool mobileScreen = false}) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: global.theme.appBarColor,
        automaticallyImplyLeading: false,
        title: Text(global.language('coupon')),
        leading: IconButton(
          focusNode: FocusNode(skipTraversal: true),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            discardData(callBack: () {
              Navigator.pop(context);
              changeScreenEvent(global.ScreenEventEnum.list);
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
                      changeScreenEvent(global.ScreenEventEnum.add);
                      selectGuid = "";
                      isChange = false;
                      clearEditData();
                      headerEdit = global.language("append");
                      isSaveAllow = true;
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        tabController.animateTo(1);
                        fieldFocusNodes[0].focusNode.requestFocus();
                      });
                    });
                  });
                },
                icon: const Icon(
                  Icons.add,
                ),
              )),
        ],
      ),
      body: Column(
        children: [
          Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(children: [
                Expanded(
                    child: TextFormField(
                        onFieldSubmitted: (value) {
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
                        autofocus: false,
                        focusNode: searchFocusNode,
                        controller: searchController,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.only(top: 0, bottom: 0, left: 0, right: 0),
                          border: InputBorder.none,
                          hintText: global.language('search'),
                        ))),
                IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    icon: const FaIcon(FontAwesomeIcons.font),
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
              color: global.theme.columnHeaderColor,
              key: headerKey,
              padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
              child: Row(children: [
                Expanded(
                    flex: 4,
                    child: Text(global.language("coupon_code"),
                        style: TextStyle(color: global.theme.columnHeaderTextColor, fontWeight: FontWeight.bold, fontSize: global.deviceConfig.listDataFontSize + 2))),
                Expanded(
                    flex: 6,
                    child: Text(
                      global.language("coupon_name"),
                      style: TextStyle(color: global.theme.columnHeaderTextColor, fontWeight: FontWeight.bold, fontSize: global.deviceConfig.listDataFontSize + 2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )),
                Expanded(
                    flex: 3,
                    child: Text(
                      global.language("coupon_type"),
                      style: TextStyle(color: global.theme.columnHeaderTextColor, fontWeight: FontWeight.bold, fontSize: global.deviceConfig.listDataFontSize + 2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )),
                Expanded(
                    flex: 2,
                    child: Text(
                      global.language("status"),
                      style: TextStyle(color: global.theme.columnHeaderTextColor, fontWeight: FontWeight.bold, fontSize: global.deviceConfig.listDataFontSize + 2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )),
              ])),
          Expanded(child: ListView(controller: listScrollController, children: listData.map((value) => listObject(listData.indexOf(value), value)).toList())),
        ],
      ),
    );
  }

  void switchToEdit(CouponModel value) {
    setState(() {
      selectGuid = value.guidfixed ?? "";
      getData(selectGuid);
      headerEdit = global.language("edit");
      isSaveAllow = true;
      changeScreenEvent(global.ScreenEventEnum.edit);
    });
  }

  Widget listObject(int index, CouponModel value) {
    listKeys.add(GlobalKey());
    bool selected = selectGuid == (value.guidfixed ?? "");
    TextStyle textStyle = TextStyle(
        fontWeight: (selected) ? FontWeight.bold : FontWeight.normal, fontSize: (selected) ? global.deviceConfig.listDataFontSize + 2.0 : global.deviceConfig.listDataFontSize);

    String couponTypeName = "";
    switch (value.coupontype) {
      case 0:
        couponTypeName = global.language("fixed_amount");
        break;
      case 1:
        couponTypeName = global.language("percentage");
        break;
      case 2:
        couponTypeName = global.language("cash_discount");
        break;
      default:
        couponTypeName = global.language("fixed_amount");
    }

    String statusName = (value.status == 0) ? global.language("active") : global.language("inactive");

    return GestureDetector(
        onTap: () {
          setState(() {
            discardData(callBack: () {
              isSaveAllow = false;
              changeScreenEvent(global.ScreenEventEnum.list);
              selectGuid = value.guidfixed ?? "";
              getData(selectGuid);
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                tabController.animateTo(1);
              });
            });
          });
        },
        onDoubleTap: () {
          switchToEdit(value);
        },
        child: Container(
            key: listKeys.last,
            decoration: BoxDecoration(
              color: (selectGuid == (value.guidfixed ?? ""))
                  ? Colors.cyan[100]
                  : (index % 2 == 0)
                      ? global.theme.columnAlternateEvenColor
                      : global.theme.columnAlternateOddColor,
            ),
            padding: EdgeInsets.only(left: 10, right: 10, top: global.deviceConfig.listDataLineSpace, bottom: global.deviceConfig.listDataLineSpace),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 4, child: Text(value.couponcode ?? "", maxLines: 2, overflow: TextOverflow.ellipsis, style: textStyle)),
              Expanded(flex: 6, child: Text(global.packName(value.names ?? []), maxLines: 2, overflow: TextOverflow.ellipsis, style: textStyle)),
              Expanded(flex: 3, child: Text(couponTypeName, maxLines: 2, overflow: TextOverflow.ellipsis, style: textStyle)),
              Expanded(flex: 2, child: Text(statusName, maxLines: 2, overflow: TextOverflow.ellipsis, style: textStyle)),
            ])));
  }

  List<LanguageDataModel> packLanguage(List<TextEditingController> controllers) {
    List<LanguageDataModel> names = [];
    for (int i = 0; i < languageList.length; i++) {
      if (languageList[i].code!.trim().isNotEmpty && controllers[i + 1].text.trim().isNotEmpty) {
        names.add(LanguageDataModel(code: languageList[i].code!, name: controllers[i + 1].text));
      }
    }
    return names;
  }

  void saveOrUpdateData() {
    // Clear previous errors
    fieldErrors.clear();

    // ตรวจสอบฟิลด์ที่จำเป็น
    if (fieldTextController[0].text.trim().isEmpty) {
      fieldErrors['coupon_code'] = "กรุณาระบุรหัสคูปอง";
    }

    if (couponValueController.text.trim().isEmpty) {
      fieldErrors['coupon_value'] = "กรุณาระบุค่าส่วนลด";
    }

    if (maxUsageCountController.text.trim().isEmpty) {
      fieldErrors['max_usage_count'] = "กรุณาระบุจำนวนใช้ทั้งหมด";
    }

    // ตรวจสอบวันที่ออกคูปอง (จำเป็น)
    if (issuedDate == null) {
      fieldErrors['issued_date'] = "กรุณาระบุวันที่ออกคูปอง";
    }

    // ตรวจสอบวันหมดอายุ (จำเป็น)
    if (expiryDate == null) {
      fieldErrors['expiry_date'] = "กรุณาระบุวันหมดอายุ";
    }

    // ตรวจสอบว่ามีชื่อคูปองอย่างน้อย 1 ภาษา
    bool hasAtLeastOneName = false;
    for (int i = 1; i < fieldTextController.length; i++) {
      if (fieldTextController[i].text.trim().isNotEmpty) {
        hasAtLeastOneName = true;
        break;
      }
    }
    if (!hasAtLeastOneName) {
      fieldErrors['coupon_name'] = "กรุณาระบุชื่อคูปองอย่างน้อย 1 ภาษา";
    }

    // ตรวจสอบว่า coupon value เป็นตัวเลขและมากกว่า 0
    double? couponValue = double.tryParse(couponValueController.text);
    if (couponValueController.text.trim().isNotEmpty && (couponValue == null || couponValue <= 0)) {
      fieldErrors['coupon_value'] = "ค่าส่วนลดต้องเป็นตัวเลขและมากกว่า 0";
    }

    // ตรวจสอบว่า max usage count เป็นตัวเลขและมากกว่า 0
    int? maxUsageCount = int.tryParse(maxUsageCountController.text);
    if (maxUsageCountController.text.trim().isNotEmpty && (maxUsageCount == null || maxUsageCount <= 0)) {
      fieldErrors['max_usage_count'] = "จำนวนใช้ทั้งหมดต้องเป็นตัวเลขและมากกว่า 0";
    }

    // ตรวจสอบว่าถ้าเป็น percentage ต้องไม่เกิน 100
    if (couponType == 1 && couponValue != null && couponValue > 100) {
      fieldErrors['coupon_value'] = "เปอร์เซ็นต์ส่วนลดต้องไม่เกิน 100";
    }

    // ตรวจสอบวันที่ (เฉพาะกรณีที่มีทั้งสองวัน)
    if (issuedDate != null && expiryDate != null && expiryDate!.isBefore(issuedDate!)) {
      fieldErrors['expiry_date'] = "วันหมดอายุต้องมาหลังวันที่ออกคูปอง";
    }

    // If there are errors, trigger setState to show them
    if (fieldErrors.isNotEmpty) {
      setState(() {});
      return;
    }

    // Pack language data for names
    names = packLanguage(fieldTextController);

    final couponData = {
      'couponcode': fieldTextController[0].text.trim().toUpperCase(),
      'names': names.map((name) => name.toJson()).toList(),
      'couponvalue': couponValue,
      'coupontype': couponType,
      'remark': remarkController.text.trim(),
      'issueddate': issuedDate != null ? _formatToUtc(issuedDate!) : null,
      'expirydate': expiryDate != null ? _formatToUtc(expiryDate!) : null,
      'maxusagecount': maxUsageCount,
      'maxusagecountpercustomer': maxUsageCountPerCustomerController.text.trim().isNotEmpty ? int.tryParse(maxUsageCountPerCustomerController.text) : null,
      'isonetimeuse': isOneTimeUse,
      'customercodes': customerCodes,
      'status': status,
    };

    if (screenEvent == global.ScreenEventEnum.add) {
      context.read<CouponBloc>().add(CreateCoupon(couponData: couponData));
    } else if (screenEvent == global.ScreenEventEnum.edit) {
      context.read<CouponBloc>().add(UpdateCoupon(id: selectGuid, couponData: couponData));
    }
  }

  void getDataToEditScreen(CouponModel coupon) {
    fieldTextController[0].text = coupon.couponcode ?? "";

    // Set multi-language names
    for (int i = 0; i < languageList.length; i++) {
      int controllerIndex = i + 1; // coupon code is at index 0, language names start at index 1

      if (controllerIndex < fieldTextController.length) {
        fieldTextController[controllerIndex].text = "";
        if (coupon.names != null) {
          for (LanguageDataModel name in coupon.names!) {
            // Case-insensitive comparison
            if (name.code.toLowerCase() == languageList[i].code!.toLowerCase()) {
              fieldTextController[controllerIndex].text = name.name;
              break;
            }
          }
        }
      }
    }

    couponValueController.text = coupon.couponvalue?.toString() ?? "";
    remarkController.text = coupon.remark ?? "";
    maxUsageCountController.text = coupon.maxusagecount?.toString() ?? "";
    maxUsageCountPerCustomerController.text = coupon.maxusagecountpercustomer?.toString() ?? "";

    // Convert UTC dates to local time for display
    issuedDate = coupon.issueddate != null ? _parseLocalDate(coupon.issueddate!) : null;
    expiryDate = coupon.expirydate != null ? _parseLocalDate(coupon.expirydate!) : null;
    couponType = coupon.coupontype ?? 0;
    status = coupon.status ?? 0;
    isOneTimeUse = coupon.isonetimeuse ?? false;
    customerCodes = coupon.customercodes ?? [];
  }

  void findFocusNext(int currentIndex) {
    if (currentIndex < fieldFocusNodes.length - 1) {
      fieldFocusNodes[currentIndex + 1].focusNode.requestFocus();
    } else {
      // Move to coupon specific fields
      couponValueFocusNode.requestFocus();
    }
  }

  Widget editScreen({mobileScreen = false}) {
    return Scaffold(
        backgroundColor: global.theme.backgroundColor,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
            backgroundColor:
                (screenEvent == global.ScreenEventEnum.edit || screenEvent == global.ScreenEventEnum.add) ? global.theme.toolBarEditModeColor : global.theme.appBarColor,
            automaticallyImplyLeading: false,
            leading: mobileScreen
                ? IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () async {
                      discardData(callBack: () {
                        changeScreenEvent(global.ScreenEventEnum.list);
                        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                          tabController.animateTo(0);
                        });
                      });
                    })
                : null,
            title: Text(headerEdit + global.language("coupon")),
            actions: <Widget>[
              if (selectGuid.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: IconButton(
                      focusNode: FocusNode(skipTraversal: true),
                      onPressed: () {
                        showDialog<String>(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: Text(global.language('delete_confirm')),
                            actions: <Widget>[
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: global.theme.buttonNoColor),
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(global.language('no'))),
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: global.theme.buttonYesColor),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.read<CouponBloc>().add(DeleteCoupon(id: selectGuid));
                                  },
                                  child: Text(global.language('confirm'))),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete),
                    )),
              if (isSaveAllow == false && selectGuid.trim().isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: IconButton(
                      focusNode: FocusNode(skipTraversal: true),
                      onPressed: () {
                        switchToEdit(listData[listData.indexOf(listData.firstWhere((element) => (element.guidfixed ?? "") == selectGuid))]);
                      },
                      icon: const Icon(Icons.edit),
                    )),
              if ((screenEvent == global.ScreenEventEnum.edit || screenEvent == global.ScreenEventEnum.add) && global.systemLanguage.length > 1)
                Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: IconButton(
                      focusNode: FocusNode(skipTraversal: true),
                      onPressed: () async {
                        setState(() {
                          isLoadTranslation = true;
                        });
                        for (int i = 1; i <= languageList.length; i++) {
                          try {
                            var translation = await translator.translate(fieldTextController[1].text, to: languageList[i - 1].codeTranslator!);
                            if (fieldTextController[i].text.isEmpty) {
                              fieldTextController[i].text = translation.text;
                            }
                          } catch (_) {}
                        }
                        setState(() {
                          isLoadTranslation = false;
                        });
                      },
                      icon: const Icon(Icons.translate),
                    )),
              if (isSaveAllow == true)
                Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: IconButton(
                      focusNode: FocusNode(skipTraversal: true),
                      onPressed: () => saveOrUpdateData(),
                      icon: const Icon(Icons.save),
                    ))
            ]),
        body: SingleChildScrollView(
            controller: editScrollController,
            child: Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ส่วนข้อมูลพื้นฐาน
                    _buildSectionHeader("ข้อมูลพื้นฐาน", Icons.receipt),
                    const SizedBox(height: 16),

                    // รหัสคูปอง (จำเป็น)
                    _buildRequiredField(
                      controller: fieldTextController[0],
                      focusNode: fieldFocusNodes[0].focusNode,
                      label: global.language("coupon_code"),
                      hint: "เช่น SAVE20, NEWYEAR2025",
                      isRequired: true,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9-]')),
                        FilteringTextInputFormatter.deny(' '),
                      ],
                      onChanged: (value) {
                        isChange = true;
                        fieldTextController[0].value = TextEditingValue(text: value.toUpperCase(), selection: fieldTextController[0].selection);
                      },
                      errorKey: 'coupon_code',
                    ),

                    // ชื่อคูปองแต่ละภาษา (จำเป็นอย่างน้อย 1 ภาษา)
                    for (int i = 0; i < languageList.length; i++)
                      _buildRequiredField(
                        controller: fieldTextController[i + 1],
                        focusNode: fieldFocusNodes[i + 1].focusNode,
                        label: "${global.language("coupon_name")} (${languageList[i].name})",
                        hint: "ชื่อคูปองที่จะแสดงให้ลูกค้า",
                        isRequired: i == 0, // ภาษาแรกเป็น required
                        onChanged: (value) => isChange = true,
                        suffixIcon: isLoadTranslation ? _buildLoadingIcon() : null,
                        errorKey: i == 0 ? 'coupon_name' : null,
                      ),

                    const SizedBox(height: 24),

                    // ส่วนประเภทและค่าส่วนลด
                    _buildSectionHeader("ประเภทและค่าส่วนลด", Icons.local_offer),
                    const SizedBox(height: 16),

                    // เลือกประเภทคูปองด้วย Card
                    _buildCouponTypeSelector(),

                    // ค่าส่วนลด (จำเป็น)
                    _buildRequiredField(
                      controller: couponValueController,
                      focusNode: couponValueFocusNode,
                      label: _getCouponValueLabel(),
                      hint: _getCouponValueHint(),
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      onChanged: (value) => isChange = true,
                      errorKey: 'coupon_value',
                    ),

                    const SizedBox(height: 24),

                    // ส่วนกำหนดเงื่อนไข
                    _buildSectionHeader("กำหนดเงื่อนไข", Icons.rule),
                    const SizedBox(height: 16),

                    // วันที่ออกและหมดอายุ
                    Row(
                      children: [
                        Expanded(child: _buildDateField("วันที่ออกคูปอง", issuedDate, (date) => setState(() => issuedDate = date), isRequired: true, errorKey: 'issued_date')),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildDateField("วันหมดอายุ", expiryDate, (date) {
                          setState(() {
                            if (date != null) {
                              // Set to end of day for expiry date
                              expiryDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
                            } else {
                              expiryDate = date;
                            }
                          });
                        }, isRequired: true, errorKey: 'expiry_date')),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // จำนวนการใช้งาน
                    Row(
                      children: [
                        Expanded(
                          child: _buildRequiredField(
                            controller: maxUsageCountController,
                            focusNode: maxUsageCountFocusNode,
                            label: "จำนวนใช้ทั้งหมด",
                            hint: "เช่น 100, 500",
                            isRequired: true,
                            keyboardType: TextInputType.number,
                            onChanged: (value) => isChange = true,
                            errorKey: 'max_usage_count',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOptionalField(
                            controller: maxUsageCountPerCustomerController,
                            focusNode: maxUsageCountPerCustomerFocusNode,
                            label: "จำนวนใช้ต่อลูกค้า",
                            hint: "ไม่จำกัด",
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    // สถานะและตัวเลือก
                    _buildToggleOptions(),

                    const SizedBox(height: 24),

                    // ส่วนลูกค้า
                    _buildSectionHeader("กำหนดลูกค้า", Icons.people),
                    const SizedBox(height: 16),
                    _buildCustomerSelection(),

                    const SizedBox(height: 24),

                    // หมายเหตุ
                    _buildSectionHeader("หมายเหตุ", Icons.note),
                    const SizedBox(height: 16),
                    _buildOptionalField(
                      controller: remarkController,
                      focusNode: remarkFocusNode,
                      label: "หมายเหตุเพิ่มเติม",
                      hint: "ข้อมูลเพิ่มเติมเกี่ยวกับคูปอง",
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),

                    // ปุ่มบันทึก
                    if (isSaveAllow)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: global.theme.buttonColor,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: saveOrUpdateData,
                          icon: const Icon(Icons.save, size: 20),
                          label: Text(
                            global.language("save") + ((kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) ? " (F10)" : ""),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),
                  ],
                ))));
  }

  void openCustomerSearch() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CustomerSearchScreen(word: ""),
        ),
      );

      if (result != null && result is global.SearchDebtorModel) {
        if (result.guid.isNotEmpty) {
          // เพิ่มรหัสลูกค้าใหม่เข้าไปใน list
          if (!customerCodes.contains(result.code)) {
            customerCodes.add(result.code);
            // ไม่ต้องอัปเดต controller เพราะเราใช้ customerCodes list โดยตรง
            isChange = true;
            setState(() {});

            global.showSnackBar(
                context, const Icon(Icons.person_add, color: Colors.white), "เพิ่มลูกค้า: ${result.code} - ${global.packName(result.names)} เรียบร้อยแล้ว", Colors.green);
          } else {
            global.showSnackBar(context, const Icon(Icons.warning, color: Colors.white), "ลูกค้า ${result.code} ถูกเลือกไปแล้ว", Colors.orange);
          }
        }
      }
    } catch (e) {
      global.showSnackBar(context, const Icon(Icons.error, color: Colors.white), "${global.language("error")}: $e", Colors.red);
    }
  }

  void removeCustomerCode(String customerCode) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบลูกค้า "$customerCode" หรือไม่?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(global.language('no')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              customerCodes.remove(customerCode);
              // ไม่ต้องอัปเดต controller เพราะเราใช้ customerCodes list โดยตรง
              isChange = true;
              setState(() {});

              // แสดงข้อความยืนยัน
              global.showSnackBar(context, const Icon(Icons.person_remove, color: Colors.white), "ลบลูกค้า $customerCode เรียบร้อยแล้ว", Colors.orange);
            },
            child: Text(global.language('confirm')),
          ),
        ],
      ),
    );
  }

  // Helper widgets for the new UI
  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: global.theme.appBarColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: global.theme.appBarColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: global.theme.appBarColor),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: global.theme.appBarColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    bool isRequired = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffixIcon,
    Function(String)? onChanged,
    String? errorKey,
  }) {
    final hasError = errorKey != null && fieldErrors.containsKey(errorKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: hasError ? Colors.red[700] : Colors.grey[700],
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: hasError ? Colors.red[400]! : Colors.grey[300]!,
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            onChanged: (value) {
              if (errorKey != null && fieldErrors.containsKey(errorKey)) {
                setState(() {
                  fieldErrors.remove(errorKey);
                });
              }
              onChanged?.call(value);
            },
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              suffixIcon: suffixIcon,
              isDense: true,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            fieldErrors[errorKey]!,
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        SizedBox(height: hasError ? 12 : 16),
      ],
    );
  }

  Widget _buildOptionalField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
    String? errorKey,
  }) {
    return _buildRequiredField(
      controller: controller,
      focusNode: focusNode,
      label: label,
      hint: hint,
      isRequired: false,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      errorKey: errorKey,
    );
  }

  Widget _buildCouponTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ประเภทคูปอง *",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    couponType = 0;
                    isChange = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: couponType == 0 ? global.theme.buttonColor.withOpacity(0.1) : Colors.white,
                    border: Border.all(
                      color: couponType == 0 ? global.theme.buttonColor : Colors.grey[300]!,
                      width: couponType == 0 ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.money_off,
                        size: 28,
                        color: couponType == 0 ? global.theme.buttonColor : Colors.grey[600],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "จำนวนเงิน",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: couponType == 0 ? global.theme.buttonColor : Colors.grey[600],
                        ),
                      ),
                      Text(
                        "ลดเป็นบาท",
                        style: TextStyle(
                          fontSize: 11,
                          color: couponType == 0 ? global.theme.buttonColor : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    couponType = 1;
                    isChange = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: couponType == 1 ? global.theme.buttonColor.withOpacity(0.1) : Colors.white,
                    border: Border.all(
                      color: couponType == 1 ? global.theme.buttonColor : Colors.grey[300]!,
                      width: couponType == 1 ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.percent,
                        size: 28,
                        color: couponType == 1 ? global.theme.buttonColor : Colors.grey[600],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "เปอร์เซ็นต์",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: couponType == 1 ? global.theme.buttonColor : Colors.grey[600],
                        ),
                      ),
                      Text(
                        "ลดเป็น %",
                        style: TextStyle(
                          fontSize: 11,
                          color: couponType == 1 ? global.theme.buttonColor : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    couponType = 2;
                    isChange = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: couponType == 2 ? global.theme.buttonColor.withOpacity(0.1) : Colors.white,
                    border: Border.all(
                      color: couponType == 2 ? global.theme.buttonColor : Colors.grey[300]!,
                      width: couponType == 2 ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_atm,
                        size: 28,
                        color: couponType == 2 ? global.theme.buttonColor : Colors.grey[600],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "เงินสด",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: couponType == 2 ? global.theme.buttonColor : Colors.grey[600],
                        ),
                      ),
                      Text(
                        "คืนเงินสด",
                        style: TextStyle(
                          fontSize: 11,
                          color: couponType == 2 ? global.theme.buttonColor : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime? selectedDate, Function(DateTime?) onDateSelected, {bool isRequired = false, String? errorKey}) {
    final hasError = errorKey != null && fieldErrors.containsKey(errorKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DatePickerWidget(
          label: label,
          selectedDate: selectedDate,
          onDateSelected: (date) {
            if (errorKey != null && fieldErrors.containsKey(errorKey)) {
              setState(() {
                fieldErrors.remove(errorKey);
              });
            }
            onDateSelected(date);
            if (date != null) {
              setState(() {
                isChange = true;
              });
            }
          },
          isEnabled: screenEvent != global.ScreenEventEnum.list,
          isRequired: isRequired,
          hasError: hasError,
        ),
        if (hasError) ...[
          Text(
            fieldErrors[errorKey]!,
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
        ],
      ],
    );
  }

  Widget _buildToggleOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // สถานะการใช้งาน
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "สถานะและตัวเลือก",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Switch(
                          value: status == 0,
                          onChanged: (value) {
                            setState(() {
                              status = value ? 0 : 1;
                              isChange = true;
                            });
                          },
                          activeColor: global.theme.buttonColor,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "เปิดใช้งาน",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Switch(
                          value: isOneTimeUse,
                          onChanged: (value) {
                            setState(() {
                              isOneTimeUse = value;
                              isChange = true;
                            });
                          },
                          activeColor: global.theme.buttonColor,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "ใช้ได้ครั้งเดียว",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "รหัสลูกค้าที่ใช้ได้",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "(ว่างเปล่า = ทุกคน)",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // แสดงรายการลูกค้าที่เลือก
        if (customerCodes.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "ลูกค้าที่เลือก (${customerCodes.length} คน)",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (customerCodes.length > 1) {
                            showDialog<String>(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: Text(global.language('delete_confirm')),
                                content: Text('คุณต้องการลบลูกค้าทั้งหมด ${customerCodes.length} คน หรือไม่?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(global.language('no')),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      setState(() {
                                        customerCodes.clear();
                                        isChange = true;
                                      });
                                    },
                                    child: Text(global.language('confirm')),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            setState(() {
                              customerCodes.clear();
                              isChange = true;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.clear_all,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Customer List
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      children: customerCodes.asMap().entries.map((entry) {
                        int index = entry.key;
                        String customerCode = entry.value;
                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: index == customerCodes.length - 1 ? Colors.transparent : Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              radius: 16,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                            title: Text(
                              customerCode,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.remove_circle,
                                color: Colors.red[400],
                                size: 20,
                              ),
                              onPressed: () => removeCustomerCode(customerCode),
                              tooltip: 'ลบลูกค้า',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 10),

        // ปุ่มเพิ่มลูกค้า
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: global.theme.buttonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            onPressed: openCustomerSearch,
            icon: const Icon(Icons.person_add, size: 18),
            label: Text(
              customerCodes.isEmpty ? "เลือกลูกค้า" : "เพิ่มลูกค้า",
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // แสดงข้อความช่วยเหลือ
        if (customerCodes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "หากไม่เลือกลูกค้า คูปองนี้จะใช้ได้กับลูกค้าทุกคน",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _getCouponValueLabel() {
    switch (couponType) {
      case 0:
        return "จำนวนเงินส่วนลด";
      case 1:
        return "เปอร์เซ็นต์ส่วนลด";
      case 2:
        return "จำนวนเงินสดคืน";
      default:
        return "ค่าส่วนลด";
    }
  }

  String _getCouponValueHint() {
    switch (couponType) {
      case 0:
        return "เช่น 100 (หมายถึง 100 บาท)";
      case 1:
        return "เช่น 10 (หมายถึง 10%)";
      case 2:
        return "เช่น 50 (หมายถึง 50 บาทคืน)";
      default:
        return "ระบุค่าส่วนลด";
    }
  }

  Widget _buildLoadingIcon() {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.all(12),
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(global.theme.buttonColor),
      ),
    );
  }

  // Helper functions for date/time conversion (similar to PointConfigWidget)
  DateTime _parseLocalDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) {
      return DateTime.now();
    }
    try {
      final utcDate = DateTime.parse(isoString);
      return utcDate.toLocal();
    } catch (e) {
      return DateTime.now();
    }
  }

  String _formatToUtc(DateTime localDateTime) {
    return localDateTime.toUtc().toIso8601String();
  }

  @override
  Widget build(BuildContext context) {
    queryData = MediaQuery.of(context);
    listKeys.clear();
    couponGuidListChecked.clear();
    return Scaffold(
        resizeToAvoidBottomInset: true,
        body: LayoutBuilder(builder: (context, constraints) {
          return BlocListener<CouponBloc, CouponState>(
              listener: (context, state) {
                blocCouponState = state;
                if (state is CouponsLoaded) {
                  setState(() {
                    if (state.coupons.isNotEmpty) {
                      listData.addAll(state.coupons);
                    }
                  });
                }
                if (state is CouponOperationSuccess) {
                  setState(() {
                    global.showSnackBar(
                        context,
                        const Icon(
                          Icons.save,
                          color: Colors.white,
                        ),
                        state.message,
                        Colors.blue);
                    clearEditData();
                    listData.clear();
                    loadDataList(searchText);
                  });
                }
                if (state is CouponError) {
                  setState(() {
                    global.showSnackBar(
                        context,
                        const Icon(
                          Icons.error,
                          color: Colors.white,
                        ),
                        state.message,
                        Colors.red);
                  });
                }
                if (state is CouponLoaded) {
                  setState(() {
                    getDataToEditScreen(state.coupon);
                    if (screenEvent == global.ScreenEventEnum.edit) {
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        tabController.animateTo(1);
                      });
                      setState(() {
                        findFocusNext(0);
                      });
                    }
                  });
                }
              },
              child: (constraints.maxWidth > 800)
                  ? SplitView(
                      controller: splitViewController,
                      gripSize: 14,
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
                    ));
        }));
  }
}
