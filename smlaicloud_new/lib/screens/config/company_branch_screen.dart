import 'dart:async';
import 'dart:io';

import 'package:smlaicloud/bloc/company_branch/company_branch_bloc.dart';
import 'package:smlaicloud/bloc/image/image_upload_bloc.dart';
import 'package:smlaicloud/model/business_type_model.dart';
import 'package:smlaicloud/model/company_branch_model.dart';
import 'package:smlaicloud/model/contact_model.dart';
import 'package:smlaicloud/screen_search/business_type_search_screen.dart';
import 'package:smlaicloud/screens/config/map_get_location_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smlaicloud/global.dart' as global;
import 'package:smlaicloud/model/global_model.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:split_view/split_view.dart';
import 'package:translator/translator.dart';
import 'package:smlaicloud/widgets/point_config_widget.dart';

class CompanyBranchScreen extends StatefulWidget {
  const CompanyBranchScreen({super.key});

  @override
  State<CompanyBranchScreen> createState() => CompanyBranchScreenState();
}

class CompanyBranchScreenState extends State<CompanyBranchScreen>
    with SingleTickerProviderStateMixin {
  final translator = GoogleTranslator();
  late TabController tabController;
  ScrollController editScrollController = ScrollController();
  bool refreshFocus = false;
  TextEditingController searchController = TextEditingController();
  TextEditingController groupController = TextEditingController();
  int focusNodeMax = 0;
  FocusNode searchFocusNode = FocusNode(skipTraversal: true);
  List<LanguageModel> languageList = <LanguageModel>[];
  List<global.FieldFocusModel> fieldFocusNodes = [];
  int focusNodeIndex = 0;
  List<CompanyBranchModel> listData = [];
  List<String> guidListChecked = [];
  List<LanguageDataModel> names = [];
  ScrollController listScrollController = ScrollController();
  List<GlobalKey> listKeys = [];
  String searchText = "";
  String selectGuid = "";
  bool isDataChange = false;
  bool isSaveAllow = false;
  late CompanyBranchState blocCurrentState;
  String headerEdit = "";
  late MediaQueryData queryData;
  int currentListIndex = -1;
  GlobalKey headerKey = GlobalKey();
  bool isKeyUp = false;
  bool isKeyDown = false;
  bool showCheckBox = false;
  bool isEditMode = false;
  late CompanyBranchModel screenData;

  late DropzoneViewController dropZoneController;
  Color colorSelected = Colors.white;
  final _debouncer = global.Debouncer(1000);
  late Timer screenTimer;
  bool loadingData = false;

  global.ScreenEventEnum screenEvent = global.ScreenEventEnum.list;
  late SplitViewController splitViewController;
  TextEditingController branchCode = TextEditingController();

  final ImagePicker imagePicker = ImagePicker();
  List<File> imageFile = [File('')];
  List<Uint8List> imageWeb = [Uint8List(0)];

  final ImagePicker logoPicker = ImagePicker();
  List<File> logoFile = [File('')];
  List<Uint8List> logoWeb = [Uint8List(0)];

  List<String> selectlanguageList = [];

  List<LanguageModel> defaultlanguageList = [
    LanguageModel(code: "th", codeTranslator: "th", name: "Thai", isuse: false),
    LanguageModel(
        code: "en", codeTranslator: "en", name: "English", isuse: false),
    LanguageModel(
        code: "zh", codeTranslator: "zh", name: "Chinese", isuse: false),
    LanguageModel(
        code: "ja", codeTranslator: "ja", name: "Japanese", isuse: false),
    LanguageModel(
        code: "ko", codeTranslator: "ko", name: "Korean", isuse: false),
    LanguageModel(code: "lo", codeTranslator: "lo", name: "Lao", isuse: false),
    LanguageModel(
        code: "my", codeTranslator: "my", name: "Burmese", isuse: false),
    LanguageModel(
        code: "ms", codeTranslator: "ms", name: "Malaysian", isuse: false),
    LanguageModel(
        code: "vi", codeTranslator: "vi", name: "Vietnamese", isuse: false),
    LanguageModel(
        code: "km", codeTranslator: "km", name: "Khmer", isuse: false),
  ];

  bool businesstypeNull = false;

  bool isExpanded = false;

  void setSystemLanguageList() async {
    clearEditData();
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
    selectlanguageList.add("th");

    setSystemLanguageList();
    tabController = TabController(vsync: this, length: 2);
    tabController.addListener(() {
      setState(() {});
    });

    // เรียงลำดับ Focus
    for (int i = 0; i < 100; i++) {
      fieldFocusNodes.add(global.FieldFocusModel(focusNode: FocusNode()));
      fieldFocusNodes[i].focusNode.addListener(() {
        if (fieldFocusNodes[i].focusNode.hasFocus) {
          focusNodeIndex = i;
          fieldFocusNodes[focusNodeIndex].focusNode.requestFocus();
        }
      });
    }
    splitViewController =
        SplitViewController(limits: [null, WeightLimit(min: 0.2, max: 0.8)]);
    listScrollController.addListener(onScrollList);

    screenTimer = Timer.periodic(const Duration(microseconds: 500), (timer) {
      if (refreshFocus) {
        fieldFocusNodes[focusNodeIndex].focusNode.requestFocus();
        refreshFocus = false;
      }
    });

    // Initialize payment rounding controllers
    initPaymentRoundingControllers();

    super.initState();
  }

  @override
  void dispose() {
    listScrollController.dispose();
    tabController.dispose();
    editScrollController.dispose();
    searchController.dispose();
    groupController.dispose();
    for (int i = 0; i < fieldFocusNodes.length; i++) {
      fieldFocusNodes[i].focusNode.dispose();
    }
    super.dispose();
  }

  void loadDataList(String search) {
    setState(() {
      loadingData = true;
    });
    searchText = search;
    context.read<CompanyBranchBloc>().add(CompanyBranchLoadList(
        offset: (listData.isEmpty) ? 0 : listData.length,
        limit: global.loadDataPerPage,
        search: search));
  }

  void onScrollList() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      loadDataList(searchText);
    }
  }

  String getLangName(String code) {
    LanguageModel name = languageList.firstWhere(
        (element) => element.code == code,
        orElse: () => LanguageModel(
            code: '', codeTranslator: '', name: '', isuse: false));
    return name.name!;
  }

  void clearEditData() {
    List<LanguageDataModel> names = [];
    for (int k = 0; k < languageList.length; k++) {
      names.add(LanguageDataModel(code: languageList[k].code!, name: ""));
    }
    branchCode.text = "";
    screenData = CompanyBranchModel(
      code: '',
      guidfixed: '',
      names: names,
      contact: ContactModel(
        address: [],
        phonenumber: '',
        latitude: 0,
        longitude: 0,
      ),
      pointconfig: PointConfigModel(
        generalrules: [],
        specialrules: [],
        pointusagetype: 1,
      ),
    );

    isDataChange = false;
    focusNodeIndex = 0;
    refreshFocus = true;

    imageFile = [File('')];
    imageWeb = [Uint8List(0)];
    logoFile = [File('')];
    logoWeb = [Uint8List(0)];

    businesstypeNull = false;

    // Reset payment rounding controllers
    initPaymentRoundingControllers();
  }

  void discardData({required Function callBack}) {
    if (isEditMode && isDataChange) {
      showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                title: Text(global.language('data_editing')),
                content: Text(global.language('leave_this_screen')),
                actions: <Widget>[
                  ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context),
                      child: Text(global.language('no'))),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue),
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
    isEditMode = false;
    context.read<CompanyBranchBloc>().add(CompanyBranchGet(guid: guid));
  }

  Widget listScreen({bool mobileScreen = false}) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: global.theme.appBarColor,
        automaticallyImplyLeading: false,
        title: Text(global.language('companyBranch')),
        leading: IconButton(
          focusNode: FocusNode(skipTraversal: true),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            discardData(callBack: () {
              Navigator.pushReplacementNamed(context, '/menu');
              // Navigator.of(context).popUntil(ModalRoute.withName('/menu'));
              isEditMode = false;
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
                icon: (showCheckBox)
                    ? const Icon(Icons.close)
                    : const Icon(Icons.check_box),
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
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('ไม่')),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue),
                              onPressed: () {
                                Navigator.pop(context);
                                context.read<CompanyBranchBloc>().add(
                                    CompanyBranchDeleteMany(
                                        guid: guidListChecked));
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
                      screenData.companynames = global.shopSelectData.names!;
                      headerEdit = global.language("append");
                      isSaveAllow = true;
                      if (mobileScreen) {
                        WidgetsBinding.instance
                            .addPostFrameCallback((timeStamp) {
                          tabController.animateTo(1);
                        });
                      }
                      fieldFocusNodes[0].focusNode.requestFocus();
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
        onKey: (node, event) {
          if (kIsWeb) {
            if (event is RawKeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                isKeyDown = false;
                int index = listData.indexOf(listData
                    .firstWhere((element) => element.guidfixed == selectGuid));
                if (index > 0) {
                  selectGuid = listData[index - 1].guidfixed;
                  currentListIndex = index + 1;
                  isKeyUp = true;
                  getData(selectGuid);
                }
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                isKeyUp = false;
                int index = listData.indexOf(listData
                    .firstWhere((element) => element.guidfixed == selectGuid));
                selectGuid = listData[index + 1].guidfixed;
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
                        onSubmitted: (value) {
                          searchFocusNode.requestFocus();
                        },
                        onChanged: (value) {
                          _debouncer.run(() {
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
                          contentPadding: const EdgeInsets.only(
                              top: 0, bottom: 0, left: 0, right: 0),
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
              padding:
                  const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
              child: Row(children: [
                Expanded(
                    flex: 5,
                    child: Text(global.language("company_branch_code"),
                        style: TextStyle(
                            color: global.theme.columnHeaderTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize:
                                global.deviceConfig.listDataFontSize + 2))),
                Expanded(
                    flex: 10,
                    child: Text(
                      global.language("company_branch_name"),
                      style: TextStyle(
                          color: global.theme.columnHeaderTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: global.deviceConfig.listDataFontSize + 2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )),
                if (showCheckBox)
                  Expanded(
                      flex: 1,
                      child: Icon(Icons.check,
                          color: global.theme.columnHeaderTextColor, size: 12))
              ])),
          Expanded(
              child: ListView(
                  controller: listScrollController,
                  children: listData
                      .map((value) => listObject(
                          listData.indexOf(value), value, showCheckBox))
                      .toList())),
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

  void switchToEdit(CompanyBranchModel value) {
    setState(() {
      selectGuid = value.guidfixed;
      getData(selectGuid);
      headerEdit = global.language("edit");
      isSaveAllow = true;
      isEditMode = true;
    });
  }

  Widget listObject(int index, CompanyBranchModel value, bool showCheckBox) {
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
        fontWeight: (selected) ? FontWeight.bold : FontWeight.normal,
        fontSize: (selected)
            ? global.deviceConfig.listDataFontSize + 2.0
            : global.deviceConfig.listDataFontSize);
    return GestureDetector(
        onTap: () {
          if (showCheckBox == true) {
            setState(() {
              selectGuid = value.guidfixed;
              if (isCheck == true) {
                guidListChecked.remove(value.guidfixed);
              } else {
                guidListChecked.add(value.guidfixed);
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
                selectGuid = value.guidfixed;
                getData(selectGuid);
                //searchFocusNode.requestFocus();
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
            padding: EdgeInsets.only(
                left: 10,
                right: 10,
                top: global.deviceConfig.listDataLineSpace,
                bottom: global.deviceConfig.listDataLineSpace),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  flex: 5,
                  child: Text(value.code,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle)),
              Expanded(
                  flex: 10,
                  child: Text(global.packName(value.names),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle)),
              if (showCheckBox)
                Expanded(
                    flex: 1,
                    child: (isCheck)
                        ? Icon(Icons.check,
                            size: global.deviceConfig.listDataFontSize)
                        : Container())
            ])));
  }

  void upLoadLogo() {
    if (logoFile.isNotEmpty) {
      if (logoFile[0].path != '') {
        context
            .read<ImageUploadBloc>()
            .add(LogoUploadFileSaved(imageFiles: logoFile, imageWeb: logoWeb));
      }
    }
  }

  void upLoadImage() {
    if (imageFile.isNotEmpty) {
      if (imageFile[0].path != '') {
        context.read<ImageUploadBloc>().add(
            ImageUploadFileSaved(imageFiles: imageFile, imageWeb: imageWeb));
      }
    }
  }

  bool verifyData(CompanyBranchModel value) {
    List<String> errorList = [];
    if (screenData.businesstype!.code!.isEmpty) {
      setState(() {
        businesstypeNull = true;
      });
      errorList.add(global.language("please_select_business_type"));
    }

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

  void saveOrUpdateData() {
    if (verifyData(screenData)) {
      showCheckBox = false;
      // print(screenData.toJson());

      if (selectGuid.trim().isEmpty) {
        context
            .read<CompanyBranchBloc>()
            .add(CompanyBranchSave(companyBranch: screenData));
      } else {
        updateData(selectGuid);
      }
    }
  }

  void updateData(String guid) {
    showCheckBox = false;
    context
        .read<CompanyBranchBloc>()
        .add(CompanyBranchUpdate(guid: guid, companyBranch: screenData));
  }

  void findFocusNext(int index) {
    focusNodeIndex = index;
    do {
      focusNodeIndex++;
      if (focusNodeIndex > focusNodeMax) {
        focusNodeIndex = 0;
      }
    } while (fieldFocusNodes[focusNodeIndex].isReadOnly);
    // print("findFocusNext=$focusNodeIndex");
    refreshFocus = true;
  }

  void getDataToEditScreen(CompanyBranchModel companyBranch) {
    isDataChange = false;
    selectGuid = companyBranch.guidfixed;
    branchCode.text = companyBranch.code;
    screenData.code = companyBranch.code;
    screenData.guidfixed = companyBranch.guidfixed;
    screenData.contact?.address = companyBranch.contact?.address;
    screenData.contact?.phonenumber = companyBranch.contact?.phonenumber;
    screenData.contact?.latitude = companyBranch.contact?.latitude;
    screenData.contact?.longitude = companyBranch.contact?.longitude;
    screenData.imageuri = companyBranch.imageuri;
    screenData.logouri = companyBranch.logouri;
    screenData.names = [];
    screenData.pos!.taxid = companyBranch.pos!.taxid;
    screenData.pos!.vatrate = companyBranch.pos!.vatrate;
    screenData.pos!.vattypesale = companyBranch.pos!.vattypesale;
    screenData.pos!.vattypepurchase = companyBranch.pos!.vattypepurchase;
    screenData.pos!.inquirytypesale = companyBranch.pos!.inquirytypesale;
    screenData.pos!.inquirytypepurchase =
        companyBranch.pos!.inquirytypepurchase;
    screenData.pos!.headerreceiptpos = companyBranch.pos!.headerreceiptpos;
    screenData.pos!.footerreceiptpos = companyBranch.pos!.footerreceiptpos;
    screenData.pos!.isbom = companyBranch.pos!.isbom;
    screenData.companynames = [];
    screenData.businesstype = companyBranch.businesstype;
    screenData.pointconfig = companyBranch.pointconfig ?? PointConfigModel();

    // Ensure pointusagetype has default value of 1 if it's 0 or null
    if (screenData.pointconfig!.pointusagetype == 0) {
      screenData.pointconfig!.pointusagetype = 1;
    }

    //เพิ่มภาษาตาม config
    for (var lang in languageList) {
      screenData.names.add(LanguageDataModel(code: lang.code!, name: ""));
      screenData.companynames
          .add(LanguageDataModel(code: lang.code!, name: ""));
    }

    for (var data in companyBranch.names) {
      for (var ele in screenData.names) {
        if (data.code == ele.code) {
          ele.name = data.name;
        }
      }
    }

    for (var data in companyBranch.companynames) {
      for (var ele in screenData.companynames) {
        if (data.code == ele.code) {
          ele.name = data.name;
        }
      }
    }

    //เก็บค่าที่ไม่ได้เปิดใช้งานภาษาเข้าทาง array
    for (var defualtValueLang in companyBranch.names) {
      LanguageDataModel result = screenData.names.firstWhere(
          (data) => data.code == defualtValueLang.code,
          orElse: () => LanguageDataModel(code: '', name: ''));
      if (result.code == '') {
        screenData.names.add(defualtValueLang);
      }
    }

    for (var defualtValueLang in companyBranch.companynames) {
      LanguageDataModel result = screenData.companynames.firstWhere(
          (data) => data.code == defualtValueLang.code,
          orElse: () => LanguageDataModel(code: '', name: ''));
      if (result.code == '') {
        screenData.companynames.add(defualtValueLang);
      }
    }

    screenData.paymentrounding =
        companyBranch.paymentrounding ?? PaymentRoundingModel();

    // Set up controllers for the existing rounding rules
    updateRoundingControllers();
  }

  void updateRoundingControllers() {
    // Clear existing controllers
    if (screenData.guidfixed.isEmpty) {
      initPaymentRoundingControllers();
    }

    if (screenData.paymentrounding == null) return;

    // Setup controllers for cash
    updateMethodControllers('cash', screenData.paymentrounding!.cash.rules);
    // Setup controllers for creditcard
    updateMethodControllers(
        'creditcard', screenData.paymentrounding!.creditcard.rules);
    // Setup controllers for banktransfer
    updateMethodControllers(
        'banktransfer', screenData.paymentrounding!.banktransfer.rules);
    // Setup controllers for cheque
    updateMethodControllers('cheque', screenData.paymentrounding!.cheque.rules);
    // Setup controllers for coupon
    updateMethodControllers('coupon', screenData.paymentrounding!.coupon.rules);
    // Setup controllers for delivery
    updateMethodControllers(
        'delivery', screenData.paymentrounding!.delivery.rules);
    // Setup controllers for qrcode
    updateMethodControllers('qrcode', screenData.paymentrounding!.qrcode.rules);
  }

  void updateMethodControllers(String method, List<RoundingRuleModel> rules) {
    roundingControllers[method]?.clear();
    for (var rule in rules) {
      List<TextEditingController> ruleControllers = [
        TextEditingController(text: rule.lowerbound.toString()),
        TextEditingController(text: rule.upperbound.toString()),
        TextEditingController(text: rule.roundto.toString()),
      ];
      roundingControllers[method]?.add(ruleControllers);
    }
    // If no rules exist, add an empty one
    if (rules.isEmpty) {
      addNewRoundingRule(method);
    }
  }

  void addNewRoundingRule(String method) {
    List<TextEditingController> controllers = [
      TextEditingController(text: "0.01"),
      TextEditingController(text: "0.99"),
      TextEditingController(text: "0"),
    ];
    roundingControllers[method]?.add(controllers);

    // Update the model
    RoundingRuleModel newRule =
        RoundingRuleModel(lowerbound: 0.01, upperbound: 0.99, roundto: 0);

    // Update the model
    switch (method) {
      case 'cash':
        screenData.paymentrounding?.cash.rules.add(newRule);
        break;
      case 'creditcard':
        screenData.paymentrounding?.creditcard.rules.add(newRule);
        break;
      case 'banktransfer':
        screenData.paymentrounding?.banktransfer.rules.add(newRule);
        break;
      case 'cheque':
        screenData.paymentrounding?.cheque.rules.add(newRule);
        break;
      case 'coupon':
        screenData.paymentrounding?.coupon.rules.add(newRule);
        break;
      case 'delivery':
        screenData.paymentrounding?.delivery.rules.add(newRule);
        break;
      case 'qrcode':
        screenData.paymentrounding?.qrcode.rules.add(newRule);
        break;
    }
    setState(() {});
  }

  void removeRoundingRule(String method, int index) {
    if (roundingControllers[method]!.length > 1) {
      roundingControllers[method]?.removeAt(index);

      // Update the model
      switch (method) {
        case 'cash':
          if (index < screenData.paymentrounding!.cash.rules.length) {
            screenData.paymentrounding!.cash.rules.removeAt(index);
          }
          break;
        case 'creditcard':
          if (index < screenData.paymentrounding!.creditcard.rules.length) {
            screenData.paymentrounding!.creditcard.rules.removeAt(index);
          }
          break;
        case 'banktransfer':
          if (index < screenData.paymentrounding!.banktransfer.rules.length) {
            screenData.paymentrounding!.banktransfer.rules.removeAt(index);
          }
          break;
        case 'cheque':
          if (index < screenData.paymentrounding!.cheque.rules.length) {
            screenData.paymentrounding!.cheque.rules.removeAt(index);
          }
          break;
        case 'coupon':
          if (index < screenData.paymentrounding!.coupon.rules.length) {
            screenData.paymentrounding!.coupon.rules.removeAt(index);
          }
          break;
        case 'delivery':
          if (index < screenData.paymentrounding!.delivery.rules.length) {
            screenData.paymentrounding!.delivery.rules.removeAt(index);
          }
          break;
        case 'qrcode':
          if (index < screenData.paymentrounding!.qrcode.rules.length) {
            screenData.paymentrounding!.qrcode.rules.removeAt(index);
          }
          break;
      }
      setState(() {});
    }
  }

  Widget buildPaymentRoundingSection() {
    List<Widget> paymentRoundingWidgets = [];

    // Title
    paymentRoundingWidgets.add(
      Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          margin: const EdgeInsets.only(top: 10, bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(5),
            color: Colors.white,
          ),
          child: Column(
            children: [
              Text(global.language("payment_rounding") ?? "การปัดเศษ",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Payment Methods Tabs
              DefaultTabController(
                length: 7,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(text: global.language("cash") ?? "เงินสด"),
                        Tab(
                            text:
                                global.language("credit_card") ?? "บัตรเครดิต"),
                        Tab(
                            text:
                                global.language("bank_transfer") ?? "โอนเงิน"),
                        Tab(text: global.language("cheque") ?? "เช็ค"),
                        Tab(text: global.language("coupon") ?? "คูปอง"),
                        Tab(
                            text: global.language("delivery") ??
                                "เก็บเงินปลายทาง"),
                        Tab(text: global.language("qrcode") ?? "QR Code"),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 500,
                      child: TabBarView(
                        children: [
                          buildPaymentMethodRounding('cash'),
                          buildPaymentMethodRounding('creditcard'),
                          buildPaymentMethodRounding('banktransfer'),
                          buildPaymentMethodRounding('cheque'),
                          buildPaymentMethodRounding('coupon'),
                          buildPaymentMethodRounding('delivery'),
                          buildPaymentMethodRounding('qrcode'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Column(children: paymentRoundingWidgets);
  }

  Widget buildPaymentMethodRounding(String method) {
    bool isEnabled = false;

    // Get enabled state from the model
    switch (method) {
      case 'cash':
        isEnabled = screenData.paymentrounding?.cash.enabled ?? false;
        break;
      case 'creditcard':
        isEnabled = screenData.paymentrounding?.creditcard.enabled ?? false;
        break;
      case 'banktransfer':
        isEnabled = screenData.paymentrounding?.banktransfer.enabled ?? false;
        break;
      case 'cheque':
        isEnabled = screenData.paymentrounding?.cheque.enabled ?? false;
        break;
      case 'coupon':
        isEnabled = screenData.paymentrounding?.coupon.enabled ?? false;
        break;
      case 'delivery':
        isEnabled = screenData.paymentrounding?.delivery.enabled ?? false;
        break;
      case 'qrcode':
        isEnabled = screenData.paymentrounding?.qrcode.enabled ?? false;
        break;
    }

    return Column(
      children: [
        // Enable/Disable switch
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Switch(
              value: isEnabled,
              onChanged: (value) {
                setState(() {
                  isDataChange = true;
                  // Update the model
                  switch (method) {
                    case 'cash':
                      screenData.paymentrounding?.cash.enabled = value;
                      break;
                    case 'creditcard':
                      screenData.paymentrounding?.creditcard.enabled = value;
                      break;
                    case 'banktransfer':
                      screenData.paymentrounding?.banktransfer.enabled = value;
                      break;
                    case 'cheque':
                      screenData.paymentrounding?.cheque.enabled = value;
                      break;
                    case 'coupon':
                      screenData.paymentrounding?.coupon.enabled = value;
                      break;
                    case 'delivery':
                      screenData.paymentrounding?.delivery.enabled = value;
                      break;
                    case 'qrcode':
                      screenData.paymentrounding?.qrcode.enabled = value;
                      break;
                  }
                });
              },
            ),
            Text(global.language("enable_rounding") ?? "เปิดใช้งานการปัดเศษ"),
          ],
        ),
        const SizedBox(height: 10),

        // Rules table header
        if (isEnabled)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Row(
              children: [
                // Add sequence number header
                SizedBox(
                  width: 30,
                  child: Text(global.language("#") ?? "ลำดับ",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),

                Expanded(
                    flex: 3,
                    child: Text(global.language("lower_bound") ?? "ค่าต่ำสุด",
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 3,
                    child: Text(global.language("upper_bound") ?? "ค่าสูงสุด",
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 3,
                    child: Text(global.language("round_to") ?? "ปัดเป็น",
                        style: const TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Container()),
              ],
            ),
          ),

        // Rules list
        if (isEnabled)
          Expanded(
            child: ListView.builder(
              itemCount: roundingControllers[method]!.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      // Add sequence number column
                      SizedBox(
                        width: 30,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Lower bound
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: roundingControllers[method]![index][0],
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            hintText:
                                global.language("lower_bound") ?? "ค่าต่ำสุด",
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (value) {
                            isDataChange = true;
                            double val = double.tryParse(value) ?? 0;

                            // Update the model
                            switch (method) {
                              case 'cash':
                                if (index <
                                    screenData
                                        .paymentrounding!.cash.rules.length) {
                                  screenData.paymentrounding!.cash.rules[index]
                                      .lowerbound = val;
                                } else {
                                  screenData.paymentrounding!.cash.rules.add(
                                      RoundingRuleModel(
                                          lowerbound: val,
                                          upperbound: 0,
                                          roundto: 0));
                                }
                                break;
                              case 'creditcard':
                                if (index <
                                    screenData.paymentrounding!.creditcard.rules
                                        .length) {
                                  screenData.paymentrounding!.creditcard
                                      .rules[index].lowerbound = val;
                                } else {
                                  screenData.paymentrounding!.creditcard.rules
                                      .add(RoundingRuleModel(
                                          lowerbound: val,
                                          upperbound: 0,
                                          roundto: 0));
                                }
                                break;
                              case 'banktransfer':
                                if (index <
                                    screenData.paymentrounding!.banktransfer
                                        .rules.length) {
                                  screenData.paymentrounding!.banktransfer
                                      .rules[index].lowerbound = val;
                                } else {
                                  screenData.paymentrounding!.banktransfer.rules
                                      .add(RoundingRuleModel(
                                          lowerbound: val,
                                          upperbound: 0,
                                          roundto: 0));
                                }
                                break;
                              case 'cheque':
                                if (index <
                                    screenData
                                        .paymentrounding!.cheque.rules.length) {
                                  screenData.paymentrounding!.cheque
                                      .rules[index].lowerbound = val;
                                } else {
                                  screenData.paymentrounding!.cheque.rules.add(
                                      RoundingRuleModel(
                                          lowerbound: val,
                                          upperbound: 0,
                                          roundto: 0));
                                }
                                break;
                              case 'coupon':
                                if (index <
                                    screenData
                                        .paymentrounding!.coupon.rules.length) {
                                  screenData.paymentrounding!.coupon
                                      .rules[index].lowerbound = val;
                                } else {
                                  screenData.paymentrounding!.coupon.rules.add(
                                      RoundingRuleModel(
                                          lowerbound: val,
                                          upperbound: 0,
                                          roundto: 0));
                                }
                                break;
                              case 'delivery':
                                if (index <
                                    screenData.paymentrounding!.delivery.rules
                                        .length) {
                                  screenData.paymentrounding!.delivery
                                      .rules[index].lowerbound = val;
                                } else {
                                  screenData.paymentrounding!.delivery.rules
                                      .add(RoundingRuleModel(
                                          lowerbound: val,
                                          upperbound: 0,
                                          roundto: 0));
                                }
                                break;
                              case 'qrcode':
                                if (index <
                                    screenData
                                        .paymentrounding!.qrcode.rules.length) {
                                  screenData.paymentrounding!.qrcode
                                      .rules[index].lowerbound = val;
                                } else {
                                  screenData.paymentrounding!.qrcode.rules.add(
                                      RoundingRuleModel(
                                          lowerbound: val,
                                          upperbound: 0,
                                          roundto: 0));
                                }
                                break;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Upper bound
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: roundingControllers[method]![index][1],
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            hintText:
                                global.language("upper_bound") ?? "ค่าสูงสุด",
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (value) {
                            isDataChange = true;
                            double val = double.tryParse(value) ?? 0;

                            // Update the model
                            switch (method) {
                              case 'cash':
                                if (index <
                                    screenData
                                        .paymentrounding!.cash.rules.length) {
                                  screenData.paymentrounding!.cash.rules[index]
                                      .upperbound = val;
                                }
                                break;
                              case 'creditcard':
                                if (index <
                                    screenData.paymentrounding!.creditcard.rules
                                        .length) {
                                  screenData.paymentrounding!.creditcard
                                      .rules[index].upperbound = val;
                                }
                                break;
                              case 'banktransfer':
                                if (index <
                                    screenData.paymentrounding!.banktransfer
                                        .rules.length) {
                                  screenData.paymentrounding!.banktransfer
                                      .rules[index].upperbound = val;
                                }
                                break;
                              case 'cheque':
                                if (index <
                                    screenData
                                        .paymentrounding!.cheque.rules.length) {
                                  screenData.paymentrounding!.cheque
                                      .rules[index].upperbound = val;
                                }
                                break;
                              case 'coupon':
                                if (index <
                                    screenData
                                        .paymentrounding!.coupon.rules.length) {
                                  screenData.paymentrounding!.coupon
                                      .rules[index].upperbound = val;
                                }
                                break;
                              case 'delivery':
                                if (index <
                                    screenData.paymentrounding!.delivery.rules
                                        .length) {
                                  screenData.paymentrounding!.delivery
                                      .rules[index].upperbound = val;
                                }
                                break;
                              case 'qrcode':
                                if (index <
                                    screenData
                                        .paymentrounding!.qrcode.rules.length) {
                                  screenData.paymentrounding!.qrcode
                                      .rules[index].upperbound = val;
                                }
                                break;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Round to
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: roundingControllers[method]![index][2],
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            hintText: global.language("round_to") ?? "ปัดเป็น",
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (value) {
                            isDataChange = true;
                            double val = double.tryParse(value) ?? 0;

                            // Update the model
                            switch (method) {
                              case 'cash':
                                if (index <
                                    screenData
                                        .paymentrounding!.cash.rules.length) {
                                  screenData.paymentrounding!.cash.rules[index]
                                      .roundto = val;
                                }
                                break;
                              case 'creditcard':
                                if (index <
                                    screenData.paymentrounding!.creditcard.rules
                                        .length) {
                                  screenData.paymentrounding!.creditcard
                                      .rules[index].roundto = val;
                                }
                                break;
                              case 'banktransfer':
                                if (index <
                                    screenData.paymentrounding!.banktransfer
                                        .rules.length) {
                                  screenData.paymentrounding!.banktransfer
                                      .rules[index].roundto = val;
                                }
                                break;
                              case 'cheque':
                                if (index <
                                    screenData
                                        .paymentrounding!.cheque.rules.length) {
                                  screenData.paymentrounding!.cheque
                                      .rules[index].roundto = val;
                                }
                                break;
                              case 'coupon':
                                if (index <
                                    screenData
                                        .paymentrounding!.coupon.rules.length) {
                                  screenData.paymentrounding!.coupon
                                      .rules[index].roundto = val;
                                }
                                break;
                              case 'delivery':
                                if (index <
                                    screenData.paymentrounding!.delivery.rules
                                        .length) {
                                  screenData.paymentrounding!.delivery
                                      .rules[index].roundto = val;
                                }
                                break;
                              case 'qrcode':
                                if (index <
                                    screenData
                                        .paymentrounding!.qrcode.rules.length) {
                                  screenData.paymentrounding!.qrcode
                                      .rules[index].roundto = val;
                                }
                                break;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Delete button
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => removeRoundingRule(method, index),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        // Add new rule button
        if (isEnabled)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: Text(global.language("add_rule") ?? "เพิ่มเงื่อนไข"),
              onPressed: () => addNewRoundingRule(method),
            ),
          ),
      ],
    );
  }

  Widget editScreen({mobileScreen}) {
    List<Widget> formWidgets = [];
    List<Widget> formWidgetsExpansion = [];

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Text(
          global.language("company_name"),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    focusNodeMax = 0;
    for (int languageIndex = 0;
        languageIndex < languageList.length;
        languageIndex++) {
      LanguageDataModel companyName = screenData.companynames.firstWhere(
          (element) => element.code == languageList[languageIndex].code,
          orElse: () => LanguageDataModel(code: '', name: ''));
      if (companyName.code == '') {
        screenData.companynames.add(LanguageDataModel(
            code: languageList[languageIndex].code!, name: ''));
      }
      formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: TextField(
          enabled: disableBranch(),
          readOnly: !isEditMode,
          onChanged: (value) {
            isDataChange = true;
            screenData.companynames[languageIndex].name = value;
          },
          onSubmitted: (value) {
            if (kIsWeb) {
              findFocusNext(focusNodeIndex);
            }
          },
          focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
          textAlign: TextAlign.left,
          controller: TextEditingController(
              text: screenData.companynames[languageIndex].name),
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
            labelText:
                "${global.language("company_name")} (${getLangName(screenData.companynames[languageIndex].code)})",
          ),
        ),
      ));
    }

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Text(
          global.language("company_branch_data"),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: TextField(
          enabled: disableBranch(),
          onSubmitted: (value) {
            if (kIsWeb) {
              findFocusNext(focusNodeIndex);
            }
          },
          focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
          textAlign: TextAlign.left,
          controller: branchCode,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp('[a-z A-Z 0-9 -]'))
          ],
          onChanged: (value) {
            isDataChange = true;
            screenData.code = value.toUpperCase();
            branchCode.value = TextEditingValue(
                text: value.toUpperCase(), selection: branchCode.selection);
          },
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
            labelText: global.language("company_branch_code"),
          ),
        ),
      ),
    );

    for (int languageIndex = 0;
        languageIndex < languageList.length;
        languageIndex++) {
      LanguageDataModel branchName = screenData.names.firstWhere(
          (element) => element.code == languageList[languageIndex].code,
          orElse: () => LanguageDataModel(code: '', name: ''));
      if (branchName.code == '') {
        screenData.names.add(LanguageDataModel(
            code: languageList[languageIndex].code!, name: ''));
      }
      formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: TextField(
          enabled: disableBranch(),
          readOnly: !isEditMode,
          onChanged: (value) {
            isDataChange = true;
            screenData.names[languageIndex].name = value;
          },
          onSubmitted: (value) {
            if (kIsWeb) {
              findFocusNext(focusNodeIndex);
            }
          },
          focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
          textAlign: TextAlign.left,
          controller:
              TextEditingController(text: screenData.names[languageIndex].name),
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
            labelText:
                "${global.language("company_branch_name")} (${getLangName(screenData.names[languageIndex].code)})",
          ),
        ),
      ));
    }

    for (int languageIndex = 0;
        languageIndex < languageList.length;
        languageIndex++) {
      LanguageDataModel address = screenData.contact!.address!.firstWhere(
          (element) => element.code == languageList[languageIndex].code,
          orElse: () => LanguageDataModel(code: '', name: ''));
      if (address.code == '') {
        screenData.contact!.address!.add(LanguageDataModel(
            code: languageList[languageIndex].code!, name: ''));
      }
      formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: TextField(
          enabled: disableBranch(),
          readOnly: !isEditMode,
          onChanged: (value) {
            isDataChange = true;
            screenData.contact!.address![languageIndex].name = value;
          },
          onSubmitted: (value) {
            if (kIsWeb) {
              findFocusNext(focusNodeIndex);
            }
          },
          focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
          textAlign: TextAlign.left,
          controller: TextEditingController(
              text: screenData.contact!.address![languageIndex].name),
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
            labelText:
                "${global.language("company_branch_address")} (${getLangName(screenData.contact!.address![languageIndex].code)})",
          ),
        ),
      ));
    }

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                enabled: disableBranch(),
                readOnly: !isEditMode,
                onChanged: (value) {
                  isDataChange = true;
                  screenData.contact?.latitude = double.parse(value);
                },
                onSubmitted: (value) {
                  if (kIsWeb) {
                    findFocusNext(focusNodeIndex);
                  }
                },
                focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
                textAlign: TextAlign.left,
                controller: TextEditingController(
                    text: screenData.contact?.latitude.toString()),
                decoration: InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: const OutlineInputBorder(),
                  labelText: global.language("company_latitude"),
                ),
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: TextField(
                enabled: disableBranch(),
                readOnly: !isEditMode,
                onChanged: (value) {
                  isDataChange = true;
                  screenData.contact?.longitude = double.parse(value);
                },
                onSubmitted: (value) {
                  if (kIsWeb) {
                    findFocusNext(focusNodeIndex);
                  }
                },
                focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
                textAlign: TextAlign.left,
                controller: TextEditingController(
                    text: screenData.contact?.longitude.toString()),
                decoration: InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: const OutlineInputBorder(),
                  labelText: global.language("company_longitude"),
                ),
              ),
            ),
            SizedBox(
              child: IconButton(
                focusNode: FocusNode(skipTraversal: true),
                icon: const Icon(Icons.location_on),
                onPressed: (screenData.code != '00000')
                    ? () async {
                        final result = Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MapGetLocationScreen(
                                      latitude: screenData.contact!.latitude!,
                                      longitude: screenData.contact!.longitude!,
                                    )));
                        result.then((value) {
                          if (value != null) {
                            screenData.contact!.latitude = value.latitude;
                            screenData.contact!.longitude = value.longitude;
                            setState(() {});
                          }
                        });
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );

    formWidgets.add(Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
      child: TextField(
        enabled: disableBranch(),
        readOnly: !isEditMode,
        onChanged: (value) {
          isDataChange = true;
          screenData.contact?.phonenumber = value;
        },
        onSubmitted: (value) {
          if (kIsWeb) {
            findFocusNext(focusNodeIndex);
          }
        },
        focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
        textAlign: TextAlign.left,
        controller:
            TextEditingController(text: screenData.contact?.phonenumber),
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: const OutlineInputBorder(),
          labelText: global.language("company_branch_phone"),
        ),
      ),
    ));

    formWidgets.add(Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
      child: TextField(
        enabled: disableBranch(),
        readOnly: !isEditMode,
        onChanged: (value) {
          isDataChange = true;
          screenData.pos!.taxid = value;
        },
        onSubmitted: (value) {
          if (kIsWeb) {
            findFocusNext(focusNodeIndex);
          }
        },
        focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
        textAlign: TextAlign.left,
        controller: TextEditingController(text: screenData.pos!.taxid),
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: const OutlineInputBorder(),
          labelText: global.language("company_tax_id"),
        ),
      ),
    ));

    /// ประเภทธุรกิจ
    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      (screenData.businesstype!.guidfixed!.isNotEmpty)
                          ? const Color.fromARGB(255, 168, 171, 136)
                          : const Color.fromARGB(255, 168, 171, 136),
                    ),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.black),
                  ),
                  onPressed: () {
                    Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const BusinessTypeSearchScreen(word: '')))
                        .then((value) {
                      if (value != null) {
                        setState(() {
                          BusinessTypeModel result = value;
                          if (result.guidfixed!.isNotEmpty) {
                            businesstypeNull = false;
                            screenData.businesstype!.guidfixed =
                                result.guidfixed;
                            screenData.businesstype!.code = result.code;
                            screenData.businesstype!.names = result.names;
                          }
                        });
                      }
                    });
                    setState(() {});
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          (screenData.businesstype!.guidfixed!.isEmpty)
                              ? "${global.language("business_code")} ~ ${global.language("business_name")} "
                              : "${global.language("product_type_name")} : ${screenData.businesstype!.code} ~ ${global.packName(screenData.businesstype!.names!)}  ",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      (screenData.businesstype!.guidfixed!.isNotEmpty)
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  // Reset the selected product type
                                  screenData.businesstype!.guidfixed = '';
                                  screenData.businesstype!.code = '';
                                  screenData.businesstype!.names = [];
                                });
                              },
                              icon: const Icon(Icons.delete),
                            )
                          : Container(),
                      const Icon(Icons.search),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    /// buisnesstypeNull Show Error text
    formWidgets.add(
      (businesstypeNull)
          ? Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  "**${global.language("please_select_business_type")}**",
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          : Container(),
    );

    formWidgetsExpansion.add(
      Padding(
        padding: const EdgeInsets.only(
          left: 10,
          right: 10,
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.only(top: 10, bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(5),
              color: Colors.white,
            ),
            child: Column(children: [
              const Text('เลือกภาษาข้อมูล',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              for (var i = 0; i < selectlanguageList.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Expanded(
                        child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text((i + 1).toString()),
                        ),
                        Expanded(
                          child: ElevatedButton(
                              onPressed: () {
                                List<LanguageModel> languagesSelectList = [];
                                languagesSelectList.addAll(defaultlanguageList);
                                for (var selected in selectlanguageList) {
                                  languagesSelectList.removeWhere(
                                      (ele) => ele.code == selected);
                                }
                                if (isSaveAllow) {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text(global
                                              .language('select_language')),
                                          content: SizedBox(
                                            width: 300,
                                            height: 400,
                                            child: ListView.builder(
                                              itemCount:
                                                  languagesSelectList.length,
                                              itemBuilder: (context, index) {
                                                return ListTile(
                                                  title: Row(
                                                    children: [
                                                      Text(languagesSelectList[
                                                              index]
                                                          .name!),
                                                      const Spacer(),
                                                      Image.asset(
                                                        'assets/flags/${languagesSelectList[index].code}.png',
                                                        width: 30,
                                                        height: 30,
                                                      ),
                                                    ],
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      Navigator.of(context).pop(
                                                          languagesSelectList[
                                                                  index]
                                                              .code);
                                                    });
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        );
                                      }).then((value) {
                                    /// check null value
                                    if (value != null) {
                                      setState(() {
                                        selectlanguageList[i] = value;
                                      });
                                    }
                                  });
                                }
                              },
                              child: Row(children: [
                                (selectlanguageList[i].isNotEmpty)
                                    ? Image.asset(
                                        'assets/flags/${selectlanguageList[i]}.png',
                                        width: 30,
                                        height: 30,
                                      )
                                    : Container(),
                                const SizedBox(width: 10),
                                (selectlanguageList[i].isNotEmpty)
                                    ? Text(defaultlanguageList[
                                            defaultlanguageList.indexWhere(
                                                (element) =>
                                                    element.code ==
                                                    selectlanguageList[i])]
                                        .name!)
                                    : Text(global.language('select_language')),
                              ])),
                        ),
                      ],
                    )),
                    (i == 0)
                        ? const SizedBox(
                            width: 50,
                          )
                        : SizedBox(
                            width: 50,
                            child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    selectlanguageList.removeAt(i);
                                  });
                                },
                                color: Colors.red,
                                icon: const Icon(Icons.delete)),
                          ),
                  ]),
                ),
              const SizedBox(height: 10),
              if (isSaveAllow)
                Row(children: [
                  ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectlanguageList.add("");
                        });
                      },
                      child: Text(global.language('add_language'))),
                ]),
            ]),
          ),
        ),
      ),
    );

    formWidgetsExpansion.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Container(
          margin: const EdgeInsets.only(top: 10, bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(5),
            color: Colors.white,
          ),
          child: Column(
            children: [
              /// อัตราภาษี
              Text(global.language("vat_rate"),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: global.language("vat_rate"),
                  border: const OutlineInputBorder(),
                ),
                controller: TextEditingController(
                    text: screenData.pos!.vatrate.toString()),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [global.NumberInputFormatter()],
                onChanged: (value) {
                  isDataChange = true;
                  screenData.pos!.vatrate = double.parse(value);
                },
              ),
              const SizedBox(height: 10),
              const Divider(),

              /// ตัดสต๊อกตามสูตรผลิด (BOM) screenData.pos.isbom  use switch

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                      child: Row(
                    children: [
                      Switch(
                          value: screenData.pos!.isbom!,
                          onChanged: (value) {
                            setState(() {
                              screenData.pos!.isbom = value;
                            });
                          }),
                      Expanded(
                          child: Text(
                        global.language("cut_stock_by_bom"),
                        overflow: TextOverflow.clip,
                      ))
                    ],
                  )),
                ],
              ),

              const Divider(),

              /// ประเภทภาษีซื้อ
              Text(global.language("vattype_purchase"),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                      child: Row(
                    children: [
                      Radio(
                          value: 0,
                          groupValue: screenData.pos!.vattypepurchase,
                          onChanged: (value) {
                            setState(() {
                              screenData.pos!.vattypepurchase = value;
                            });
                          }),
                      Expanded(
                          child: Text(
                        global.language("vat_exclude"),
                        overflow: TextOverflow.clip,
                      ))
                    ],
                  )),
                  Expanded(
                      child: Row(
                    children: [
                      Radio(
                          value: 1,
                          groupValue: screenData.pos!.vattypepurchase,
                          onChanged: (value) {
                            setState(() {
                              screenData.pos!.vattypepurchase = value;
                            });
                          }),
                      Expanded(
                          child: Text(
                        global.language("vat_include"),
                        overflow: TextOverflow.clip,
                      ))
                    ],
                  )),
                  Expanded(
                      child: Row(children: [
                    Radio(
                        value: 2,
                        groupValue: screenData.pos!.vattypepurchase,
                        activeColor: Colors.blue,
                        onChanged: (value) {
                          setState(() {
                            screenData.pos!.vattypepurchase = value;
                          });
                        }),
                    Expanded(
                      child: Text(
                        global.language("vat_zero"),
                        overflow: TextOverflow.clip,
                      ),
                    )
                  ])),
                  Expanded(
                      child: Row(children: [
                    Radio(
                        value: 3,
                        groupValue: screenData.pos!.vattypepurchase,
                        activeColor: Colors.blue,
                        onChanged: (value) {
                          setState(() {
                            screenData.pos!.vattypepurchase = value;
                          });
                        }),
                    Expanded(
                      child: Text(
                        global.language("vat_none"),
                        overflow: TextOverflow.clip,
                      ),
                    )
                  ])),
                ],
              ),
              const Divider(),

              /// ประเภทรายการซื้อ
              Text(global.language("inquirytype_purchase"),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                      child: Row(
                    children: [
                      Radio(
                          value: 0,
                          groupValue: screenData.pos!.inquirytypepurchase,
                          onChanged: (value) {
                            setState(() {
                              screenData.pos!.inquirytypepurchase = value;
                            });
                          }),
                      Expanded(
                          child: Text(
                        global.language("credit"),
                        overflow: TextOverflow.clip,
                      ))
                    ],
                  )),
                  Expanded(
                      child: Row(
                    children: [
                      Radio(
                          value: 1,
                          groupValue: screenData.pos!.inquirytypepurchase,
                          onChanged: (value) {
                            setState(() {
                              screenData.pos!.inquirytypepurchase = value;
                            });
                          }),
                      Expanded(
                          child: Text(
                        global.language("cash"),
                        overflow: TextOverflow.clip,
                      ))
                    ],
                  )),
                ],
              ),
              Column(
                children: [
                  const Divider(),

                  /// ประเภทภาษีขาย
                  Text(global.language("vattype_sale"),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Row(
                        children: [
                          Radio(
                              value: 0,
                              groupValue: screenData.pos!.vattypesale,
                              onChanged: (value) {
                                setState(() {
                                  screenData.pos!.vattypesale = value;
                                });
                              }),
                          Expanded(
                              child: Text(
                            global.language("vat_exclude"),
                            overflow: TextOverflow.clip,
                          ))
                        ],
                      )),
                      Expanded(
                          child: Row(
                        children: [
                          Radio(
                              value: 1,
                              groupValue: screenData.pos!.vattypesale,
                              onChanged: (value) {
                                setState(() {
                                  screenData.pos!.vattypesale = value;
                                });
                              }),
                          Expanded(
                              child: Text(
                            global.language("vat_include"),
                            overflow: TextOverflow.clip,
                          ))
                        ],
                      )),
                      Expanded(
                          child: Row(children: [
                        Radio(
                            value: 2,
                            groupValue: screenData.pos!.vattypesale,
                            activeColor: Colors.blue,
                            onChanged: (value) {
                              setState(() {
                                screenData.pos!.vattypesale = value;
                              });
                            }),
                        Expanded(
                          child: Text(
                            global.language("vat_zero"),
                            overflow: TextOverflow.clip,
                          ),
                        )
                      ])),
                      Expanded(
                          child: Row(children: [
                        Radio(
                            value: 3,
                            groupValue: screenData.pos!.vattypesale,
                            activeColor: Colors.blue,
                            onChanged: (value) {
                              setState(() {
                                screenData.pos!.vattypesale = value;
                              });
                            }),
                        Expanded(
                          child: Text(
                            global.language("vat_none"),
                            overflow: TextOverflow.clip,
                          ),
                        )
                      ])),
                    ],
                  ),
                  const Divider(),

                  /// ประเภทการขาย
                  Text(global.language("inquirytype_sale"),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Row(
                        children: [
                          Radio(
                              value: 0,
                              groupValue: screenData.pos!.inquirytypesale,
                              onChanged: (value) {
                                setState(() {
                                  screenData.pos!.inquirytypesale = value;
                                });
                              }),
                          Expanded(
                              child: Text(
                            global.language("credit"),
                            overflow: TextOverflow.clip,
                          ))
                        ],
                      )),
                      Expanded(
                          child: Row(
                        children: [
                          Radio(
                              value: 1,
                              groupValue: screenData.pos!.inquirytypesale,
                              onChanged: (value) {
                                setState(() {
                                  screenData.pos!.inquirytypesale = value;
                                });
                              }),
                          Expanded(
                              child: Text(
                            global.language("cash"),
                            overflow: TextOverflow.clip,
                          ))
                        ],
                      )),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    /// ปัดเศษการชำระเงิน
    formWidgetsExpansion.add(
      buildPaymentRoundingSection(),
    );

    formWidgetsExpansion.add(
      Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          margin: const EdgeInsets.only(top: 10, bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(5),
            color: Colors.white,
          ),
          child: Column(
            children: [
              /// หัวใบเสร็จ
              Text(global.language("header_receipt_pos"),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  hintText: global.language("header_receipt_pos"),
                  border: const OutlineInputBorder(),
                ),
                controller: TextEditingController(
                    text: screenData.pos!.headerreceiptpos),
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                onChanged: (value) {
                  isDataChange = true;
                  screenData.pos!.headerreceiptpos = value;
                },
              ),

              const SizedBox(height: 10),
              const Divider(),

              /// ท้ายใบเสร็จ
              Text(global.language("footer_receipt_pos"),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  hintText: global.language("footer_receipt_pos"),
                  border: const OutlineInputBorder(),
                ),
                controller: TextEditingController(
                    text: screenData.pos!.footerreceiptpos),
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                onChanged: (value) {
                  isDataChange = true;
                  screenData.pos!.footerreceiptpos = value;
                },
              ),
            ],
          ),
        ),
      ),
    );

    formWidgetsExpansion.add(const SizedBox(
      height: 10,
    ));

    formWidgetsExpansion.add(Center(
      child: Text(global.language("image"),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ));

    formWidgetsExpansion.add(GridView.builder(
        primary: true,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: imageFile.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1, childAspectRatio: 1.5),
        itemBuilder: (BuildContext context, int index) {
          return Column(
            children: [
              // ignore: unrelated_type_equality_checks
              (disableBranch == true)
                  ? Row(
                      children: [
                        Expanded(
                            child: IconButton(
                          focusNode: FocusNode(skipTraversal: true),
                          onPressed: () async {
                            screenData.imageuri = "";
                            imageFile[index] = File('');
                            imageWeb[index] = Uint8List(0);
                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.delete,
                          ),
                        )),
                        const SizedBox(width: 5),
                        Expanded(
                            child: IconButton(
                          focusNode: FocusNode(skipTraversal: true),
                          onPressed: () async {
                            final XFile? image = await imagePicker.pickImage(
                                source: ImageSource.gallery,
                                maxHeight: 400,
                                maxWidth: 400);
                            if (image != null) {
                              var f = await image.readAsBytes();
                              imageWeb[index] = f;
                              imageFile[index] = File(image.path);
                              upLoadImage();
                              setState(() {});
                            }
                          },
                          icon: const Icon(
                            Icons.folder,
                          ),
                        )),
                        const SizedBox(width: 5),
                        if (kIsWeb == false)
                          Expanded(
                              child: IconButton(
                            focusNode: FocusNode(skipTraversal: true),
                            onPressed: () async {
                              final XFile? photo = await imagePicker.pickImage(
                                  source: ImageSource.camera,
                                  maxHeight: 400,
                                  maxWidth: 400,
                                  imageQuality: 60);
                              if (photo != null) {
                                var f = await photo.readAsBytes();
                                imageWeb[index] = f;
                                imageFile[index] = File(photo.path);
                                upLoadImage();
                                setState(() {});
                              }
                            },
                            icon: const Icon(
                              Icons.camera_alt,
                            ),
                          )),
                      ],
                    )
                  : Container(),
              Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(5),
                        image: (imageFile[index].path != '')
                            ? DecorationImage(
                                image: MemoryImage(imageWeb[index]),
                                fit: BoxFit.fill)
                            : (screenData.imageuri != '')
                                ? DecorationImage(
                                    image: NetworkImage(screenData.imageuri!),
                                    fit: BoxFit.fill)
                                : const DecorationImage(
                                    image:
                                        AssetImage('assets/img/noimage.png')),
                      ),
                    )),
              ),
            ],
          );
        }));

    formWidgetsExpansion.add(const SizedBox(
      height: 10,
    ));
    formWidgetsExpansion.add(Center(
      child: Text(global.language("logo"),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ));

    formWidgetsExpansion.add(GridView.builder(
        primary: true,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logoFile.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1, childAspectRatio: 1.5),
        itemBuilder: (BuildContext context, int index) {
          return Column(
            children: [
              // ignore: unrelated_type_equality_checks
              (disableBranch == true)
                  ? Row(
                      children: [
                        Expanded(
                            child: IconButton(
                          focusNode: FocusNode(skipTraversal: true),
                          onPressed: () async {
                            screenData.logouri = "";
                            logoFile[index] = File('');
                            logoWeb[index] = Uint8List(0);
                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.delete,
                          ),
                        )),
                        const SizedBox(width: 5),
                        Expanded(
                            child: IconButton(
                          focusNode: FocusNode(skipTraversal: true),
                          onPressed: () async {
                            final XFile? image = await logoPicker.pickImage(
                                source: ImageSource.gallery,
                                maxHeight: 400,
                                maxWidth: 400);
                            if (image != null) {
                              var f = await image.readAsBytes();
                              logoWeb[index] = f;
                              logoFile[index] = File(image.path);
                              upLoadLogo();
                              setState(() {});
                            }
                          },
                          icon: const Icon(
                            Icons.folder,
                          ),
                        )),
                        const SizedBox(width: 5),
                        if (kIsWeb == false)
                          Expanded(
                              child: IconButton(
                            focusNode: FocusNode(skipTraversal: true),
                            onPressed: () async {
                              final XFile? photo = await logoPicker.pickImage(
                                  source: ImageSource.camera,
                                  maxHeight: 400,
                                  maxWidth: 400,
                                  imageQuality: 60);
                              if (photo != null) {
                                var f = await photo.readAsBytes();
                                logoWeb[index] = f;
                                logoFile[index] = File(photo.path);
                                upLoadLogo();
                                setState(() {});
                              }
                            },
                            icon: const Icon(
                              Icons.camera_alt,
                            ),
                          )),
                      ],
                    )
                  : Container(),
              Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(5),
                        image: (logoFile[index].path != '')
                            ? DecorationImage(
                                image: MemoryImage(logoWeb[index]),
                                fit: BoxFit.fill)
                            : (screenData.logouri != '')
                                ? DecorationImage(
                                    image: NetworkImage(screenData.logouri!),
                                    fit: BoxFit.fill)
                                : const DecorationImage(
                                    image:
                                        AssetImage('assets/img/noimage.png')),
                      ),
                    )),
              ),
            ],
          );
        }));

    formWidgets.add(const SizedBox(
      height: 10,
    ));

    if (isSaveAllow) {
      formWidgets.add(Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          child: ElevatedButton.icon(
              focusNode: FocusNode(skipTraversal: true),
              onPressed: () {
                saveOrUpdateData();
              },
              icon: const Icon(Icons.save),
              label:
                  Text(global.language("save") + ((kIsWeb) ? " (F10)" : "")))));
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
          backgroundColor: (isEditMode)
              ? global.theme.toolBarEditModeColor
              : global.theme.appBarColor,
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
          title: Text(headerEdit + global.language("company_branch")),
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
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(context),
                                child: Text(global.language('no'))),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue),
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.read<CompanyBranchBloc>().add(
                                      CompanyBranchDelete(guid: selectGuid));
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
            if (isEditMode && global.systemLanguage.length > 1)
              Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: () async {
                      for (int indexLanguage = 2;
                          indexLanguage <= languageList.length;
                          indexLanguage++) {
                        try {} catch (_) {}
                      }
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.translate,
                    ),
                  )),
            if (isSaveAllow == false && selectGuid.trim().isNotEmpty)
              Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: () {
                      showCheckBox = false;
                      switchToEdit(listData[listData.indexOf(
                          listData.firstWhere(
                              (element) => element.guidfixed == selectGuid))]);
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
                    onPressed: () => saveOrUpdateData(),
                    icon: const Icon(
                      Icons.save,
                    ),
                  ))
          ]),
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent) {
            // print(event.logicalKey);
            if (event.logicalKey == LogicalKeyboardKey.f10) {
              saveOrUpdateData();
            }
            if (event.logicalKey == LogicalKeyboardKey.tab ||
                event.logicalKey == LogicalKeyboardKey.enter) {
              if (event.isShiftPressed) {
                //findFocusPrev(focusNodeIndex);
              } else {
                findFocusNext(focusNodeIndex);
              }
            }
          }
        },
        child: SingleChildScrollView(
          controller: editScrollController,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: Form(
              child: Column(
                children: [
                  Column(children: formWidgets),
                  const SizedBox(height: 10),
                  ExpansionTile(
                    initiallyExpanded: isExpanded,
                    // ลบ border เดิมและใช้ container decoration แทน
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // เพิ่ม background color และ shadow
                    backgroundColor: Colors.grey[50],
                    collapsedBackgroundColor: Colors.white,
                    // ปรับ padding
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

                    title: Row(
                      children: [
                        // เพิ่ม icon ด้านหน้า
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "กำหนดค่าเพิ่มเติม",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    // ปรับ trailing icon ให้สวยขึ้น
                    trailing: AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ),

                    onExpansionChanged: (bool expanded) {
                      setState(() {
                        isExpanded = expanded;
                      });
                    },

                    children: [
                      // เพิ่ม container wrapper สำหรับ styling
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: formWidgetsExpansion,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
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
              BlocListener<CompanyBranchBloc, CompanyBranchState>(
                listener: (context, state) {
                  blocCurrentState = state;
                  // Load
                  if (state is CompanyBranchLoadSuccess) {
                    setState(() {
                      loadingData = false;
                      if (state.companyBranch.isNotEmpty) {
                        listData.addAll(state.companyBranch);
                      }
                    });
                  }
                  if (state is CompanyBranchLoadFailed) {
                    setState(() {
                      loadingData = false;
                    });
                  }
                  // Save
                  if (state is CompanyBranchSaveSuccess) {
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
                  if (state is CompanyBranchSaveFailed) {
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
                  if (state is CompanyBranchUpdateSuccess) {
                    setState(() {
                      global.showSnackBar(
                          context,
                          const Icon(
                            Icons.edit,
                            color: Colors.white,
                          ),
                          global.language("edit_success"),
                          Colors.blue);
                      isSaveAllow = false;
                      clearEditData();
                      listData.clear();
                      loadDataList(searchText);
                      getData(selectGuid);
                    });
                  }
                  if (state is CompanyBranchUpdateFailed) {
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
                  if (state is CompanyBranchDeleteSuccess) {
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
                  if (state is CompanyBranchDeleteManySuccess) {
                    setState(() {
                      global.showSnackBar(
                          context,
                          const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                          global.language("not_delete_success"),
                          Colors.blue);
                      listData.clear();
                      clearEditData();
                      loadDataList(searchText);
                      showCheckBox = false;
                    });
                  }
                  // Get
                  if (state is CompanyBranchGetSuccess) {
                    setState(() {
                      businesstypeNull = false;
                      getDataToEditScreen(state.companyBranch);
                      if (isEditMode) {
                        WidgetsBinding.instance
                            .addPostFrameCallback((timeStamp) {
                          tabController.animateTo(1);
                        });
                        setState(() {
                          findFocusNext(0);
                        });
                      }
                    });
                    if (currentListIndex >= 0) {
                      RenderBox? boxHeader = headerKey.currentContext
                          ?.findRenderObject() as RenderBox?;
                      Offset? positionheader =
                          boxHeader?.localToGlobal(Offset.zero);
                      RenderBox? box = listKeys[currentListIndex]
                          .currentContext
                          ?.findRenderObject() as RenderBox?;
                      Offset? position = box?.localToGlobal(Offset.zero);
                      if (position != null &&
                          positionheader != null &&
                          boxHeader != null &&
                          box != null) {
                        // Scroll Up
                        if (isKeyUp &&
                            position.dy <=
                                (positionheader.dy +
                                    (boxHeader.size.height +
                                        (box.size.height * 2)))) {
                          setState(() {
                            listScrollController.animateTo(
                                listScrollController.offset -
                                    (boxHeader.size.height + box.size.height),
                                duration: const Duration(milliseconds: 100),
                                curve: Curves.ease);
                            isKeyUp = false;
                          });
                        }
                        // Scroll Down
                        if (isKeyDown &&
                            position.dy > (queryData.size.height - 100)) {
                          setState(() {
                            listScrollController.animateTo(
                                listScrollController.offset +
                                    (position.dy -
                                        (queryData.size.height - 100)),
                                duration: const Duration(milliseconds: 100),
                                curve: Curves.easeOut);
                            isKeyDown = false;
                          });
                        }
                      }
                    }
                  }
                },
              ),
              BlocListener<ImageUploadBloc, ImageUploadState>(
                  listener: (context, state) {
                if (state is ImageUploadSaveSuccess) {
                  screenData.imageuri = state.imageUpload.uri;
                } else if (state is LogoUploadSaveSuccess) {
                  screenData.logouri = state.imageUpload.uri;
                }
              }),
            ],
            child: (constraints.maxWidth > 800)
                ? SplitView(
                    controller: splitViewController,
                    gripSize: 8,
                    gripColor: global.theme.appBarColor,
                    gripColorActive: Colors.blue,
                    viewMode: SplitViewMode.Horizontal,
                    indicator: const SplitIndicator(
                        viewMode: SplitViewMode.Horizontal),
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
                    children: [
                      listScreen(mobileScreen: true),
                      editScreen(mobileScreen: true)
                    ],
                  ),
          );
        },
      ),
    );
  }

  // Add the missing roundingControllers property
  Map<String, List<List<TextEditingController>>> roundingControllers = {};
  void initPaymentRoundingControllers() {
    // Initialize controllers for all payment methods
    List<String> paymentMethods = [
      'cash',
      'creditcard',
      'banktransfer',
      'cheque',
      'coupon',
      'delivery',
      'qrcode'
    ];

    List<Map<String, double>> defaultRules = [
      {'lowerbound': 0.01, 'upperbound': 0.12, 'roundto': 0.0},
      {'lowerbound': 0.13, 'upperbound': 0.37, 'roundto': 0.25},
      {'lowerbound': 0.38, 'upperbound': 0.62, 'roundto': 0.5},
      {'lowerbound': 0.63, 'upperbound': 0.87, 'roundto': 0.75},
      {'lowerbound': 0.88, 'upperbound': 0.99, 'roundto': 1.0},
    ];

    for (String method in paymentMethods) {
      roundingControllers[method] = [];

      // Initialize the model if needed
      if (screenData != null && screenData.paymentrounding != null) {
        // Make sure the rules list is empty before adding default rules
        switch (method) {
          case 'cash':
            screenData.paymentrounding!.cash.rules.clear();
            for (var rule in defaultRules) {
              screenData.paymentrounding!.cash.rules.add(RoundingRuleModel(
                  lowerbound: rule['lowerbound']!,
                  upperbound: rule['upperbound']!,
                  roundto: rule['roundto']!));
            }
            break;
          case 'creditcard':
            screenData.paymentrounding!.creditcard.rules.clear();
            for (var rule in defaultRules) {
              screenData.paymentrounding!.creditcard.rules.add(
                  RoundingRuleModel(
                      lowerbound: rule['lowerbound']!,
                      upperbound: rule['upperbound']!,
                      roundto: rule['roundto']!));
            }
            break;
          case 'banktransfer':
            screenData.paymentrounding!.banktransfer.rules.clear();
            for (var rule in defaultRules) {
              screenData.paymentrounding!.banktransfer.rules.add(
                  RoundingRuleModel(
                      lowerbound: rule['lowerbound']!,
                      upperbound: rule['upperbound']!,
                      roundto: rule['roundto']!));
            }
            break;
          case 'cheque':
            screenData.paymentrounding!.cheque.rules.clear();
            for (var rule in defaultRules) {
              screenData.paymentrounding!.cheque.rules.add(RoundingRuleModel(
                  lowerbound: rule['lowerbound']!,
                  upperbound: rule['upperbound']!,
                  roundto: rule['roundto']!));
            }
            break;
          case 'coupon':
            screenData.paymentrounding!.coupon.rules.clear();
            for (var rule in defaultRules) {
              screenData.paymentrounding!.coupon.rules.add(RoundingRuleModel(
                  lowerbound: rule['lowerbound']!,
                  upperbound: rule['upperbound']!,
                  roundto: rule['roundto']!));
            }
            break;
          case 'delivery':
            screenData.paymentrounding!.delivery.rules.clear();
            for (var rule in defaultRules) {
              screenData.paymentrounding!.delivery.rules.add(RoundingRuleModel(
                  lowerbound: rule['lowerbound']!,
                  upperbound: rule['upperbound']!,
                  roundto: rule['roundto']!));
            }
            break;
          case 'qrcode':
            screenData.paymentrounding!.qrcode.rules.clear();
            for (var rule in defaultRules) {
              screenData.paymentrounding!.qrcode.rules.add(RoundingRuleModel(
                  lowerbound: rule['lowerbound']!,
                  upperbound: rule['upperbound']!,
                  roundto: rule['roundto']!));
            }
            break;
        }
      }

      // For each default rule, create controllers
      for (var rule in defaultRules) {
        List<TextEditingController> controllers = [
          TextEditingController(text: rule['lowerbound']!.toString()),
          TextEditingController(text: rule['upperbound']!.toString()),
          TextEditingController(text: rule['roundto']!.toString()),
        ];
        roundingControllers[method]!.add(controllers);
      }
    }
  }

  // Add the missing disableBranch method
  bool disableBranch() {
    // if (screenData.code == '00000') {
    //   return false;
    // } else {
    //   return true;
    // }
    return true;
  }
}
