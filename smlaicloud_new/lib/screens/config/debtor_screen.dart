import 'dart:async';
import 'dart:io';

import 'package:smlaicloud/bloc/debtor/debtor_bloc.dart';
import 'package:smlaicloud/bloc/debtor_group/debtor_group_bloc.dart';
import 'package:smlaicloud/model/customer_address_model.dart';
import 'package:smlaicloud/model/debtor_group_model.dart';
import 'package:smlaicloud/model/debtor_model.dart';
import 'package:smlaicloud/model/price_model.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:email_validator/email_validator.dart';
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
import 'package:smlaicloud/screens/config/point_transaction_screen.dart';
import 'package:smlaicloud/bloc/point_transaction/point_transaction_bloc.dart';
import 'package:smlaicloud/repositories/point_transaction_repository.dart';

class DebtorScreen extends StatefulWidget {
  const DebtorScreen({Key? key}) : super(key: key);

  @override
  State<DebtorScreen> createState() => DebtorScreenState();
}

class DebtorScreenState extends State<DebtorScreen> with SingleTickerProviderStateMixin {
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
  List<DebtorModel> listData = [];
  List<DebtorGroupModel> listDataGroup = [];
  List<String> guidListChecked = [];
  List<LanguageDataModel> names = [];
  ScrollController listScrollController = ScrollController();
  List<GlobalKey> listKeys = [];
  String searchText = "";
  String selectGuid = "";
  bool isDataChange = false;
  bool isSaveAllow = false;
  late DebtorState blocCurrentState;
  String headerEdit = "";
  late MediaQueryData queryData;
  int currentListIndex = -1;
  GlobalKey headerKey = GlobalKey();
  bool isKeyUp = false;
  bool isKeyDown = false;
  bool showCheckBox = false;
  bool isEditMode = false;
  late DebtorModel screenData;
  List<Uint8List> imageWeb = [];
  final ImagePicker imagePicker = ImagePicker();
  late DropzoneViewController dropZoneController;
  Color colorSelected = Colors.white;
  final _debouncer = global.Debouncer(1000);
  late Timer screenTimer;
  bool loadingData = false;
  List<DebtorGroupModel> groupSelected = [];
  List<File> imageFile = [];
  global.ScreenEventEnum screenEvent = global.ScreenEventEnum.list;
  late SplitViewController splitViewController;
  final _popupBuilderKey = GlobalKey<DropdownSearchState<String>>();
  final _popupBuilderKey2 = GlobalKey<DropdownSearchState<String>>();
  TextEditingController debtorCode = TextEditingController();

  List<DebtorGroupModel> selectedFilters = [];
  List<String> selectedFilterCodes = [];

  bool isLoadTranslation = false;

  final _formKey = GlobalKey<FormState>();
  void setSystemLanguageList() async {
    clearEditData();
    await global.setSystemLanguage(context);

    for (int i = 0; i < global.config.languages.length; i++) {
      if (global.config.languages[i].isuse!) {
        languageList.add(global.config.languages[i]);
      }
    }
    loadDataList("", []);
    loadDataGroupList();
  }

  @override
  void initState() {
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
    splitViewController = SplitViewController(limits: [null, WeightLimit(min: 0.2, max: 0.8)]);
    listScrollController.addListener(onScrollList);

    screenTimer = Timer.periodic(const Duration(microseconds: 500), (timer) {
      if (refreshFocus) {
        fieldFocusNodes[focusNodeIndex].focusNode.requestFocus();
        refreshFocus = false;
      }
    });
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

  void loadDataGroupList() {
    context.read<DebtorGroupBloc>().add(const DebtorGroupLoadList(offset: 0, limit: 1000, search: ""));
  }

  void loadDataList(String search, List<String>? filter) {
    setState(() {
      loadingData = true;
    });
    searchText = search;
    context.read<DebtorBloc>().add(DebtorLoadList(offset: (listData.isEmpty) ? 0 : listData.length, limit: global.loadDataPerPage, search: search, groups: filter));
  }

  void onScrollList() {
    if (listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange) {
      loadDataList(searchText, selectedFilterCodes);
    }
  }

  String getLangName(String code) {
    LanguageModel name = languageList.firstWhere((element) => element.code == code, orElse: () => LanguageModel(code: '', codeTranslator: '', name: '', isuse: false));
    return name.name!;
  }

  void clearEditData() {
    List<LanguageDataModel> names = [];
    List<LanguageDataModel> addressNames = [];
    for (int k = 0; k < languageList.length; k++) {
      names.add(LanguageDataModel(code: languageList[k].code!, name: ""));
      addressNames.add(LanguageDataModel(code: languageList[k].code!, name: ""));
    }
    List<LanguageDataModel> nameBill = [];
    for (int k = 0; k < languageList.length; k++) {
      nameBill.add(LanguageDataModel(code: languageList[k].code!, name: ""));
    }
    debtorCode.text = "";
    screenData = DebtorModel(
      guidfixed: "",
      code: "",
      names: names,
      customertype: 1,
      branchnumber: '00000',
      personaltype: 1,
      addressforbilling: CustomerAddressModel(
        guid: "",
        address: [""],
        countrycode: "",
        provincecode: "",
        districtcode: "",
        subdistrictcode: "",
        zipcode: "",
        latitude: 0,
        longitude: 0,
        contactnames: nameBill,
        phoneprimary: "",
        phonesecondary: "",
      ),
      addressforshipping: [],
      images: [],
      groups: [],
      taxid: "",
      email: "",
      pointbalance: 0,
      pointscode: "",
      pricelevel: "1",
    );
    imageFile = [];
    imageWeb = [];
    groupSelected = [];
    isDataChange = false;
    focusNodeIndex = 0;
    refreshFocus = true;
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
              ));
    } else {
      callBack();
    }
  }

  void getData(String guid) {
    headerEdit = global.language("show");
    isEditMode = false;
    context.read<DebtorBloc>().add(DebtorGet(guid: guid));
  }

  Widget listScreen({bool mobileScreen = false}) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: global.theme.appBarColor,
        automaticallyImplyLeading: false,
        title: Text(global.language('debtor')),
        leading: IconButton(
          focusNode: FocusNode(skipTraversal: true),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            discardData(callBack: () {
              Navigator.pop(context);
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
                                context.read<DebtorBloc>().add(DebtorDeleteMany(guid: guidListChecked));
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
                int index = listData.indexOf(listData.firstWhere((element) => element.guidfixed == selectGuid));
                if (index > 0) {
                  selectGuid = listData[index - 1].guidfixed;
                  currentListIndex = index + 1;
                  isKeyUp = true;
                  getData(selectGuid);
                }
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                isKeyUp = false;
                int index = listData.indexOf(listData.firstWhere((element) => element.guidfixed == selectGuid));
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
                            loadDataList(value, selectedFilterCodes);
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
                  onPressed: () async {
                    selectedFilters = await filterDebtorGroup(selectedFilters);
                    if (selectedFilters.isNotEmpty) {
                      selectedFilterCodes.clear();
                      for (var element in selectedFilters) {
                        selectedFilterCodes.add(element.guidfixed);
                      }
                    } else {
                      selectedFilterCodes.clear();
                    }
                    listData = [];
                    loadDataList(searchText, selectedFilterCodes);
                    setState(() {});
                  },
                  icon: Icon(
                    (selectedFilters.isEmpty) ? Icons.filter_alt_off : Icons.filter_alt,
                    color: (selectedFilters.isEmpty) ? Colors.black : Colors.blue,
                  ),
                ),
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
                    flex: 3,
                    child: Text(global.language("debtor_code"),
                        style: TextStyle(color: global.theme.columnHeaderTextColor, fontWeight: FontWeight.bold, fontSize: global.deviceConfig.listDataFontSize + 2))),
                Expanded(
                    flex: 5,
                    child: Text(
                      global.language("debtor_name"),
                      style: TextStyle(color: global.theme.columnHeaderTextColor, fontWeight: FontWeight.bold, fontSize: global.deviceConfig.listDataFontSize + 2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )),
                Expanded(
                    flex: 5,
                    child: Text(global.language("address"),
                        style: TextStyle(color: global.theme.columnHeaderTextColor, fontWeight: FontWeight.bold, fontSize: global.deviceConfig.listDataFontSize + 2))),
                Expanded(
                    flex: 3,
                    child: Text(global.language("telephone"),
                        style: TextStyle(color: global.theme.columnHeaderTextColor, fontWeight: FontWeight.bold, fontSize: global.deviceConfig.listDataFontSize + 2))),
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

  void switchToEdit(DebtorModel value) {
    setState(() {
      selectGuid = value.guidfixed;
      getData(selectGuid);
      headerEdit = global.language("edit");
      isSaveAllow = true;
      isEditMode = true;
    });
  }

  Widget listObject(int index, DebtorModel value, bool showCheckBox) {
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
            padding: EdgeInsets.only(left: 10, right: 10, top: global.deviceConfig.listDataLineSpace, bottom: global.deviceConfig.listDataLineSpace),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: Text(value.code, maxLines: 2, overflow: TextOverflow.ellipsis, style: textStyle)),
              Expanded(flex: 5, child: Text(global.packName(value.names), maxLines: 2, overflow: TextOverflow.ellipsis, style: textStyle)),
              Expanded(
                  flex: 5,
                  child: Text((value.addressforbilling.address!.isNotEmpty) ? value.addressforbilling.address![0] : '',
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: textStyle)),
              Expanded(
                  flex: 3,
                  child: Text((value.addressforbilling.phoneprimary!.isNotEmpty) ? value.addressforbilling.phoneprimary! : '',
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: textStyle)),
              if (showCheckBox) Expanded(flex: 1, child: (isCheck) ? Icon(Icons.check, size: global.deviceConfig.listDataFontSize) : Container())
            ])));
  }

  void saveOrUpdateData() {
    showCheckBox = false;

    screenData.groups = groupSelected;

    if (selectGuid.trim().isEmpty) {
      if (imageFile.isNotEmpty) {
        context.read<DebtorBloc>().add(DebtorWithImageSave(
              debtor: screenData,
              imageFile: imageFile,
              imageWeb: imageWeb,
            ));
      } else {
        context.read<DebtorBloc>().add(DebtorSave(debtor: screenData));
      }
    } else {
      updateData(selectGuid);
    }
  }

  void updateData(String guid) {
    showCheckBox = false;
    List<File> imageFileUpdate = [];
    List<Uint8List> imageWebUpdate = [];
    List<ImagesModel> imageUris = [];
    for (int i = 0; i < imageWeb.length; i++) {
      // print(imageWeb.length);
      // print(imageFile.length);
      // print(screenData.images.length);
      if (imageWeb[i].isNotEmpty || screenData.images[i].uri != '') {
        imageFileUpdate.add(imageFile[i]);
        imageWebUpdate.add(imageWeb[i]);
        imageUris.add(ImagesModel(uri: screenData.images[i].uri, xorder: i));
      }
    }
    // print("imageWebUpdate.isNotEmpty " + imageWebUpdate.isNotEmpty.toString());
    if (imageWebUpdate.isNotEmpty) {
      context.read<DebtorBloc>().add(DebtorWithImageUpdate(
            guid: guid,
            debtor: screenData,
            imageFiles: imageFile,
            imagesUris: imageUris,
            imageWeb: imageWeb,
          ));
    } else {
      screenData.images = [];
      context.read<DebtorBloc>().add(DebtorUpdate(guid: guid, debtorModel: screenData));
    }
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

  void getDataToEditScreen(DebtorModel debtor) {
    isDataChange = false;
    selectGuid = debtor.guidfixed;
    debtorCode.text = debtor.code;
    screenData.code = debtor.code;
    screenData.email = debtor.email;
    screenData.fundcode = debtor.fundcode;
    screenData.creditday = debtor.creditday;
    screenData.guidfixed = debtor.guidfixed;
    screenData.images = debtor.images;
    screenData.ismember = debtor.ismember;
    screenData.personaltype = debtor.personaltype;
    screenData.customertype = debtor.customertype;
    screenData.branchnumber = debtor.branchnumber;
    screenData.taxid = debtor.taxid;
    screenData.groups = debtor.groups;
    groupSelected = debtor.groups;
    screenData.pointbalance = debtor.pointbalance;
    screenData.pointscode = debtor.pointscode;
    screenData.pricelevel = debtor.pricelevel ?? "1";
    screenData.addressforbilling.address = debtor.addressforbilling.address;
    screenData.addressforbilling.phoneprimary = debtor.addressforbilling.phoneprimary;
    screenData.addressforbilling.phonesecondary = debtor.addressforbilling.phonesecondary;
    screenData.pricelevel = debtor.pricelevel;

    screenData.names = [];
    screenData.addressforbilling.contactnames = [];
    screenData.addressforshipping = [];
    //เพิ่มภาษาตาม config
    for (var lang in languageList) {
      screenData.names.add(LanguageDataModel(code: lang.code!, name: ""));
      screenData.addressforbilling.contactnames!.add(LanguageDataModel(code: lang.code!, name: ""));
    }

    for (var addressforshipping in debtor.addressforshipping) {
      CustomerAddressModel newData = CustomerAddressModel(
          guid: addressforshipping.guid,
          address: addressforshipping.address,
          countrycode: addressforshipping.countrycode,
          provincecode: addressforshipping.provincecode,
          districtcode: addressforshipping.districtcode,
          subdistrictcode: addressforshipping.subdistrictcode,
          zipcode: addressforshipping.zipcode,
          latitude: addressforshipping.latitude,
          longitude: addressforshipping.longitude,
          contactnames: [],
          phoneprimary: addressforshipping.phoneprimary,
          phonesecondary: addressforshipping.phonesecondary);

      for (var lang in languageList) {
        newData.contactnames!.add(LanguageDataModel(code: lang.code!, name: ""));
      }
      screenData.addressforshipping.add(newData);
    }

    //ใส่ value ตามภาษา
    for (var data in debtor.addressforbilling.contactnames!) {
      for (var ele in screenData.addressforbilling.contactnames!) {
        if (data.code == ele.code) {
          ele.name = data.name;
        }
      }
    }

    for (var data in debtor.names) {
      for (var ele in screenData.names) {
        if (data.code == ele.code) {
          ele.name = data.name;
        }
      }
    }

    // for (var addressforshipping in customer.addressforshipping) {
    //   for (var data in addressforshipping.contactnames) {
    //     for (var arr in screenData.addressforshipping) {
    //       for (var ele in arr.contactnames) {
    //         if (data.code == ele.code) {
    //           ele.name = data.name;
    //         }
    //       }
    //     }
    //   }
    // }

    for (int i = 0; i < debtor.addressforshipping.length; i++) {
      for (var data in debtor.addressforshipping[i].contactnames!) {
        for (var ele in screenData.addressforshipping[i].contactnames!) {
          if (data.code == ele.code) {
            ele.name = data.name;
          }
        }
      }
    }

    //เก็บค่าที่ไม่ได้เปิดใช้งานภาษาเข้าทาง array
    for (var defualtValueLang in debtor.names) {
      LanguageDataModel result = screenData.names.firstWhere((data) => data.code == defualtValueLang.code, orElse: () => LanguageDataModel(code: '', name: ''));
      if (result.code == '') {
        screenData.names.add(defualtValueLang);
      }
    }

    for (var defualtValueLang in debtor.addressforbilling.contactnames!) {
      LanguageDataModel result =
          screenData.addressforbilling.contactnames!.firstWhere((data) => data.code == defualtValueLang.code, orElse: () => LanguageDataModel(code: '', name: ''));
      if (result.code == '') {
        screenData.addressforbilling.contactnames!.add(defualtValueLang);
      }
    }

    for (var addressforshipping in debtor.addressforshipping) {
      for (var defualtValueLang in addressforshipping.contactnames!) {
        for (var arr in screenData.addressforshipping) {
          LanguageDataModel result = arr.contactnames!.firstWhere((data) => data.code == defualtValueLang.code, orElse: () => LanguageDataModel(code: '', name: ''));
          if (result.code == '') {
            arr.contactnames!.add(defualtValueLang);
          }
        }
      }
    }

    imageWeb = [];
    imageFile = [];

    for (int i = 0; i < debtor.images.length; i++) {
      imageWeb.add(Uint8List(0));
      imageFile.add(File(''));
    }
  }

  Future<List<DebtorGroupModel>> getDataGroup(filter) async {
    return listDataGroup;
  }

  DebtorGroupModel getGroup(String guid) {
    DebtorGroupModel data = DebtorGroupModel(guidfixed: "", groupcode: "");
    for (var ele in listDataGroup) {
      if (ele.guidfixed == guid) {
        data = ele;
      }
    }
    return data;
  }

  Widget editScreen({mobileScreen}) {
    List<Widget> formWidgets = [];

    focusNodeMax = 0;
    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: TextFormField(
          readOnly: !isEditMode,
          onEditingComplete: () {
            if (kIsWeb) {
              findFocusNext(focusNodeIndex);
            }
          },
          focusNode: fieldFocusNodes[focusNodeMax].focusNode,
          textAlign: TextAlign.left,
          controller: debtorCode,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('[a-z A-Z 0-9 -]'))],
          onChanged: (value) {
            isDataChange = true;
            screenData.code = value.toUpperCase();
            debtorCode.value = TextEditingValue(text: value.toUpperCase(), selection: debtorCode.selection);
          },
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
            labelText: global.language("debtor_code"),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          },
        ),
      ),
    );
    for (int languageIndex = 0; languageIndex < languageList.length; languageIndex++) {
      LanguageDataModel debtorName =
          screenData.names.firstWhere((element) => element.code == languageList[languageIndex].code, orElse: () => LanguageDataModel(code: '', name: ''));
      if (debtorName.code == '') {
        screenData.names.add(LanguageDataModel(code: languageList[languageIndex].code!, name: ''));
      }
      formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: TextFormField(
          readOnly: !isEditMode,
          onChanged: (value) {
            isDataChange = true;
            screenData.names[languageIndex].name = value;
          },
          onEditingComplete: () {
            if (kIsWeb) {
              findFocusNext(focusNodeIndex);
            }
          },
          focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
          textAlign: TextAlign.left,
          controller: TextEditingController(text: screenData.names[languageIndex].name),
          decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              labelText: "${global.language("debtor_name")} (${getLangName(screenData.names[languageIndex].code)})",
              suffixIcon: isLoadTranslation
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : null),
          validator: (value) {
            if (languageIndex == 0) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
            }

            return null;
          },
        ),
      ));
    }

    formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Row(
          children: [
            Radio(
              focusNode: FocusNode(skipTraversal: true),
              value: 1,
              groupValue: screenData.personaltype,
              onChanged: (value) {
                setState(() {
                  screenData.personaltype = value!;
                  focusNodeIndex = 3;
                  refreshFocus = true;
                });
              },
            ),
            Text(global.language("customer_individual")),
            const SizedBox(width: 10),
            Radio(
              focusNode: FocusNode(skipTraversal: true),
              value: 2,
              groupValue: screenData.personaltype,
              onChanged: (value) {
                setState(() {
                  screenData.personaltype = value!;
                  focusNodeIndex = 3;
                  refreshFocus = true;
                });
              },
            ),
            Text(global.language("customer_company")),
          ],
        )));
    formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: TextFormField(
            readOnly: !isEditMode,
            onFieldSubmitted: (value) {
              findFocusNext(focusNodeIndex);
            },
            textInputAction: TextInputAction.next,
            focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
            textAlign: TextAlign.left,
            controller: TextEditingController(text: screenData.taxid),
            textCapitalization: TextCapitalization.characters,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('[a-z A-Z 0-9 -]'))],
            onChanged: (value) {
              isDataChange = true;
              screenData.taxid = value;
            },
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              labelText: global.language((screenData.personaltype == 1) ? "customer_tax_id_card_number" : "customer_tax_id_bussiness"),
            ))));
    formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Row(
          children: [
            Radio(
              focusNode: FocusNode(skipTraversal: true),
              value: 1,
              groupValue: screenData.customertype,
              onChanged: (screenData.personaltype == 2)
                  ? (value) {
                      setState(() {
                        screenData.customertype = 1;
                        screenData.branchnumber = '00000';
                        focusNodeIndex = 5;
                        refreshFocus = true;
                      });
                    }
                  : null,
            ),
            Text(global.language("head_office")),
            const SizedBox(width: 10),
            Radio(
              focusNode: FocusNode(skipTraversal: true),
              value: 2,
              groupValue: screenData.customertype,
              onChanged: (screenData.personaltype == 2)
                  ? (value) {
                      setState(() {
                        screenData.customertype = 2;
                        screenData.branchnumber = '';
                        focusNodeIndex = 4;
                        refreshFocus = true;
                      });
                    }
                  : null,
            ),
            Text(global.language("branch")),
          ],
        )));

    formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: TextFormField(
            enabled: screenData.personaltype == 2,
            readOnly: !isEditMode || screenData.customertype == 1,
            onFieldSubmitted: (value) {
              findFocusNext(focusNodeIndex);
            },
            key: _popupBuilderKey2,
            textInputAction: TextInputAction.next,
            focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
            textAlign: TextAlign.left,
            controller: TextEditingController(text: screenData.branchnumber),
            textCapitalization: TextCapitalization.characters,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('[a-z A-Z 0-9 -]'))],
            onChanged: (value) {
              isDataChange = true;
              screenData.branchnumber = value;
            },
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              labelText: global.language("branch_number"),
            ))));

    formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: TextFormField(
            readOnly: !isEditMode,
            onFieldSubmitted: (value) {
              bool isValid = (screenData.email!.isEmpty) ? true : EmailValidator.validate(screenData.email!);
              if (!isValid) {
                global.showSnackBar(
                    context,
                    const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                    global.language("email_error"),
                    Colors.red);
              }
              findFocusNext(focusNodeIndex);
            },
            textInputAction: TextInputAction.next,
            focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
            textAlign: TextAlign.left,
            controller: TextEditingController(text: screenData.email),
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) {
              isDataChange = true;
              screenData.email = value;
            },
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              labelText: global.language("email"),
            ))));

    // formWidgets.add(Padding(
    //     padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
    //     child: TextFormField(
    //         readOnly: !isEditMode,
    //         onFieldSubmitted: (value) {
    //           findFocusNext(focusNodeIndex);
    //         },
    //         focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
    //         controller: TextEditingController(text: screenData.fundcode),
    //         onChanged: (value) {
    //           isDataChange = true;
    //           screenData.fundcode = value;
    //         },
    //         decoration: InputDecoration(
    //           floatingLabelBehavior: FloatingLabelBehavior.always,
    //           border: const OutlineInputBorder(),
    //           labelText: global.language("fund_code"),
    //         ))));

    formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: TextFormField(
            readOnly: !isEditMode,
            onFieldSubmitted: (value) {
              findFocusNext(focusNodeIndex);
            },
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
            focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
            controller: TextEditingController(text: screenData.creditday.toString()),
            onChanged: (value) {
              isDataChange = true;
              screenData.creditday = int.parse(value);
            },
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              labelText: global.language("credit_day"),
            ))));

    formWidgets.add(
      (!kIsWeb)
          ? Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
              child: DropdownSearch<DebtorGroupModel>.multiSelection(
                enabled: isEditMode,
                key: _popupBuilderKey,
                asyncItems: (String filter) => getDataGroup(filter),
                compareFn: (item, selectedItem) => item.guidfixed == selectedItem.guidfixed,
                itemAsString: (DebtorGroupModel? group) {
                  if (group == null) return '';
                  return '${group.groupcode} - ${global.activeLangName(group.names)}';
                },
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: global.language("group"),
                  ),
                ),
                onChanged: (List<DebtorGroupModel> value) {
                  setState(() {
                    groupSelected = value;
                  });
                },
                popupProps: const PopupPropsMultiSelection.modalBottomSheet(
                  showSearchBox: true,
                  showSelectedItems: true,
                ),
                selectedItems: groupSelected,
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
              child: DropdownSearch<DebtorGroupModel>.multiSelection(
                enabled: isEditMode,
                compareFn: (item, selectedItem) => item.guidfixed == selectedItem.guidfixed,
                asyncItems: (String filter) => getDataGroup(filter),
                itemAsString: (DebtorGroupModel? group) {
                  if (group == null) return '';
                  return '${group.groupcode} - ${global.activeLangName(group.names)}';
                },
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: global.language("group"),
                  ),
                ),
                onChanged: (List<DebtorGroupModel> value) {
                  setState(() {
                    groupSelected = value;
                  });
                },
                popupProps: const PopupPropsMultiSelection.dialog(
                  showSearchBox: true,
                  showSelectedItems: true,
                ),
                selectedItems: groupSelected,
              ),
            ),
    );

    formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Row(
          children: [
            Radio(
              focusNode: FocusNode(skipTraversal: true),
              value: false,
              groupValue: screenData.ismember,
              onChanged: (value) {
                setState(() {
                  screenData.ismember = value!;
                });
              },
            ),
            Text(global.language("not_member")),
            const SizedBox(width: 10),
            Radio(
              focusNode: FocusNode(skipTraversal: true),
              value: true,
              groupValue: screenData.ismember,
              onChanged: (value) {
                setState(() {
                  screenData.ismember = value!;
                });
              },
            ),
            Text(global.language("is_member")),
          ],
        )));

    formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: TextFormField(
            readOnly: !isEditMode,
            onFieldSubmitted: (value) {
              findFocusNext(focusNodeIndex);
            },
            focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
            controller: TextEditingController(text: screenData.pointscode),
            onChanged: (value) {
              isDataChange = true;
              screenData.pointscode = value;
            },
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              labelText: 'รหัสสะสมแต้ม',
            ))));

    // เพิ่มฟิลด์ pricelevel
    List<PriceModel> availablePrices = global.config.prices.where((price) => price.keyNumber == 1 || (price.keyNumber >= 9 && price.keyNumber <= 17)).toList();

    formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: DropdownButtonFormField<String>(
          value: availablePrices.any((p) => p.keyNumber.toString() == screenData.pricelevel) ? screenData.pricelevel : "1",
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
            labelText: 'ระดับราคา',
          ),
          items: availablePrices.map<DropdownMenuItem<String>>((PriceModel price) {
            String priceName = "";
            if (price.names.isNotEmpty) {
              // ใช้ภาษาแรกที่มีอยู่
              priceName = price.names.first.name ?? "";
            }
            return DropdownMenuItem<String>(
              value: price.keyNumber.toString(),
              child: Text(priceName),
            );
          }).toList(),
          onChanged: isEditMode
              ? (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      isDataChange = true;
                      screenData.pricelevel = newValue;
                    });
                  }
                }
              : null,
        )));

    formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                  readOnly: true,
                  onFieldSubmitted: (value) {
                    findFocusNext(focusNodeIndex);
                  },
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                  focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
                  controller: TextEditingController(text: screenData.pointbalance.toString()),
                  onChanged: (value) {
                    isDataChange = true;
                    screenData.pointbalance = int.parse(value.isEmpty ? "0" : value);
                  },
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: const OutlineInputBorder(),
                    labelText: 'แต้มคงเหลือ',
                  )),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  focusNode: FocusNode(skipTraversal: true),
                  onPressed: screenData.code.isNotEmpty
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocProvider(
                                create: (context) => PointTransactionBloc(
                                  pointTransactionRepository: PointTransactionRepository(),
                                ),
                                child: PointTransactionScreen(
                                  debtorCode: screenData.code,
                                  debtorName: global.packName(screenData.names),
                                  pointsCode: screenData.pointscode!,
                                ),
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('ประวัติ', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        )));

    formWidgets.add(Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
      child: Text(global.language("address_for_billing")),
    ));

    for (int languageIndex = 0; languageIndex < languageList.length; languageIndex++) {
      LanguageDataModel contactnames =
          screenData.addressforbilling.contactnames!.firstWhere((element) => element.code == languageList[languageIndex].code, orElse: () => LanguageDataModel(code: '', name: ''));
      if (contactnames.code == '') {
        screenData.addressforbilling.contactnames!.add(LanguageDataModel(code: languageList[languageIndex].code!, name: ''));
      }
      formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: TextField(
          readOnly: !isEditMode,
          onChanged: (value) {
            isDataChange = true;
            screenData.addressforbilling.contactnames![languageIndex].name = value;
          },
          onSubmitted: (value) {
            if (kIsWeb) {
              findFocusNext(focusNodeIndex);
            }
          },
          focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
          textAlign: TextAlign.left,
          controller: TextEditingController(text: screenData.addressforbilling.contactnames![languageIndex].name),
          decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              labelText: "${global.language("debtor_name")} (${getLangName(screenData.addressforbilling.contactnames![languageIndex].code)})",
              suffixIcon: isLoadTranslation
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : null),
        ),
      ));
    }

    for (int addressIndex = 0; addressIndex < 1; addressIndex++) {
      formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: TextFormField(
          readOnly: !isEditMode,
          onChanged: (value) {
            isDataChange = true;
            screenData.addressforbilling.address![addressIndex] = value;
          },
          onFieldSubmitted: (value) {
            findFocusNext(focusNodeIndex);
          },
          textInputAction: TextInputAction.next,
          focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
          textAlign: TextAlign.left,
          controller: TextEditingController(text: screenData.addressforbilling.address![addressIndex]),
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
            labelText: global.language("address"),
            // labelText: global.language("tax_address_${addressIndex + 1}"),
          ),
        ),
      ));
    }

    formWidgets.add(Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
      child: TextFormField(
        maxLength: 10,
        readOnly: !isEditMode,
        onChanged: (value) {
          isDataChange = true;
          screenData.addressforbilling.phoneprimary = value;
        },
        onFieldSubmitted: (value) {
          findFocusNext(focusNodeIndex);
        },
        textInputAction: TextInputAction.next,
        focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
        textAlign: TextAlign.left,
        controller: TextEditingController(text: screenData.addressforbilling.phoneprimary),
        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('[0-9]'))],
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: const OutlineInputBorder(),
          labelText: global.language("telephone_primary"),
        ),
      ),
    ));
    formWidgets.add(Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
      child: TextFormField(
        maxLength: 10,
        readOnly: !isEditMode,
        onChanged: (value) {
          isDataChange = true;
          screenData.addressforbilling.phonesecondary = value;
        },
        onFieldSubmitted: (value) {
          findFocusNext(focusNodeIndex);
        },
        textInputAction: TextInputAction.next,
        focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
        textAlign: TextAlign.left,
        controller: TextEditingController(text: screenData.addressforbilling.phonesecondary),
        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('[0-9]'))],
        decoration: InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: const OutlineInputBorder(),
          labelText: global.language("telephone_secondary"),
        ),
      ),
    ));

    for (int addressShipIndex = 0; addressShipIndex < screenData.addressforshipping.length; addressShipIndex++) {
      formWidgets.add((screenData.addressforshipping.isNotEmpty)
          ? Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
              child: Text(global.language("address_for_shipping ${addressShipIndex + 1}")),
            )
          : Container());
      for (int languageIndex = 0; languageIndex < languageList.length; languageIndex++) {
        LanguageDataModel contactnames = screenData.addressforshipping[addressShipIndex].contactnames!
            .firstWhere((element) => element.code == languageList[languageIndex].code, orElse: () => LanguageDataModel(code: '', name: ''));
        if (contactnames.code == '') {
          screenData.addressforshipping[addressShipIndex].contactnames!.add(LanguageDataModel(code: languageList[languageIndex].code!, name: ''));
        }
        formWidgets.add(Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
          child: TextField(
            readOnly: !isEditMode,
            onChanged: (value) {
              isDataChange = true;
              screenData.addressforshipping[addressShipIndex].contactnames![languageIndex].name = value;
            },
            onSubmitted: (value) {
              if (kIsWeb) {
                findFocusNext(focusNodeIndex);
              }
            },
            focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
            textAlign: TextAlign.left,
            controller: TextEditingController(text: screenData.addressforshipping[addressShipIndex].contactnames![languageIndex].name),
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              labelText: "${global.language("debtor_name")} (${getLangName(screenData.addressforshipping[addressShipIndex].contactnames![languageIndex].code)})",
            ),
          ),
        ));
      }
      for (int addressIndex = 0; addressIndex < screenData.addressforshipping[addressShipIndex].address!.length; addressIndex++) {
        formWidgets.add(Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
          child: TextFormField(
            readOnly: !isEditMode,
            onChanged: (value) {
              isDataChange = true;
              screenData.addressforshipping[addressShipIndex].address![addressIndex] = value;
            },
            onFieldSubmitted: (value) {
              findFocusNext(focusNodeIndex);
            },
            textInputAction: TextInputAction.next,
            focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
            textAlign: TextAlign.left,
            controller: TextEditingController(text: screenData.addressforshipping[addressShipIndex].address![addressIndex]),
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              labelText: global.language("shipping_address_${addressIndex + 1}"),
            ),
          ),
        ));
      }
      formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: TextFormField(
          maxLength: 10,
          readOnly: !isEditMode,
          onChanged: (value) {
            isDataChange = true;
            screenData.addressforshipping[addressShipIndex].phoneprimary = value;
          },
          onFieldSubmitted: (value) {
            findFocusNext(focusNodeIndex);
          },
          textInputAction: TextInputAction.next,
          focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
          textAlign: TextAlign.left,
          controller: TextEditingController(text: screenData.addressforshipping[addressShipIndex].phoneprimary),
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('[0-9]'))],
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
            labelText: global.language("telephone_primary"),
          ),
        ),
      ));
      formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: TextFormField(
          maxLength: 10,
          readOnly: !isEditMode,
          onChanged: (value) {
            isDataChange = true;
            screenData.addressforshipping[addressShipIndex].phonesecondary = value;
          },
          onFieldSubmitted: (value) {
            findFocusNext(focusNodeIndex);
          },
          textInputAction: TextInputAction.next,
          focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
          textAlign: TextAlign.left,
          controller: TextEditingController(text: screenData.addressforshipping[addressShipIndex].phonesecondary),
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('[0-9]'))],
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
            labelText: global.language("telephone_secondary"),
          ),
        ),
      ));
    }

    formWidgets.add((screenData.images.isNotEmpty)
        ? Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
            child: Text(global.language("debtor_image")),
          )
        : Container());

    List<Widget> imageList = [];
    for (int imageIndex = 0; imageIndex < screenData.images.length; imageIndex++) {
      imageList.add(Container(
          width: 300,
          padding: const EdgeInsets.only(left: 5, right: 5, bottom: 5, top: 5),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: const BorderRadius.all(Radius.circular(5.0))),
          child: Column(
            children: [
              Row(
                children: [
                  (isEditMode)
                      ? Expanded(
                          child: IconButton(
                          focusNode: FocusNode(skipTraversal: true),
                          onPressed: () async {
                            screenData.images.removeAt(imageIndex);
                            imageWeb.removeAt(imageIndex);
                            imageFile.removeAt(imageIndex);
                            setState(() {});
                          },
                          icon: const Icon(
                            Icons.delete,
                          ),
                        ))
                      : Container(),
                  const SizedBox(width: 5),
                  (isEditMode)
                      ? Expanded(
                          child: IconButton(
                          focusNode: FocusNode(skipTraversal: true),
                          onPressed: (kIsWeb)
                              ? () async {
                                  XFile? image = await imagePicker.pickImage(source: ImageSource.gallery, maxHeight: 480, maxWidth: 640, imageQuality: 60);
                                  if (image != null) {
                                    var f = await image.readAsBytes();
                                    setState(() {
                                      imageWeb[imageIndex] = f;
                                      imageFile[imageIndex] = File(image.path);
                                      FocusScope.of(context).unfocus();
                                    });
                                  }
                                }
                              : () async {
                                  final XFile? photo = await imagePicker.pickImage(source: ImageSource.camera, maxHeight: 480, maxWidth: 640, imageQuality: 60);
                                  if (photo != null) {
                                    var f = await photo.readAsBytes();
                                    imageWeb[imageIndex] = f;
                                    imageFile.add(File(photo.path));
                                    setState(() {
                                      FocusScope.of(context).unfocus();
                                    });
                                  }
                                },
                          icon: const Icon(
                            Icons.folder,
                          ),
                        ))
                      : Container(),
                  const SizedBox(width: 5),
                  if (kIsWeb == false)
                    Expanded(
                        child: IconButton(
                      focusNode: FocusNode(skipTraversal: true),
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        final XFile? photo = await imagePicker.pickImage(source: ImageSource.camera, maxHeight: 480, maxWidth: 640, imageQuality: 60);
                        if (photo != null) {
                          var f = await photo.readAsBytes();
                          imageWeb[imageIndex] = f;
                          imageFile.add(File(photo.path));
                          setState(() {});
                        }
                      },
                      icon: const Icon(
                        Icons.camera_alt,
                      ),
                    )),
                ],
              ),
              SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(children: [
                    DropzoneView(
                      operation: DragOperation.copy,
                      cursor: CursorType.grab,
                      onCreated: (ctrl) => dropZoneController = ctrl,
                      onLoaded: () {},
                      onError: (ev) {},
                      onHover: () {},
                      onLeave: () {},
                      onDrop: (ev) async {
                        final bytes = await dropZoneController.getFileData(ev);
                        setState(() {
                          imageWeb[imageIndex] = bytes;
                        });
                      },
                      onDropMultiple: (ev) async {},
                    ),
                    Center(
                        child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: const [
                          BoxShadow(
                              offset: Offset(0, 4),
                              color: Colors.cyan, //edited
                              spreadRadius: 4,
                              blurRadius: 10 //edited
                              )
                        ],
                        image: (imageWeb[imageIndex].isNotEmpty)
                            ? DecorationImage(image: MemoryImage(imageWeb[imageIndex]), fit: BoxFit.fill)
                            : (screenData.images[imageIndex].uri != '')
                                ? DecorationImage(image: NetworkImage(screenData.images[imageIndex].uri), fit: BoxFit.fill)
                                : const DecorationImage(image: AssetImage('assets/img/noimage.png')),
                      ),
                      child: const SizedBox(
                        width: 500,
                        height: 500,
                      ),
                    )),
                  ])),
            ],
          )));
    }

    formWidgets.add(Wrap(
      children: imageList,
    ));
    formWidgets.add(const SizedBox(
      height: 5,
    ));
    if (isEditMode) {
      formWidgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: ElevatedButton.icon(
            focusNode: FocusNode(skipTraversal: true),
            onPressed: () {
              setState(() {
                screenData.images.add(ImagesModel(uri: '', xorder: 0));
                imageWeb.add(Uint8List(0));
                imageFile.add(File(''));
                FocusScope.of(context).unfocus();
              });
            },
            icon: const Icon(Icons.add),
            label: Text(global.language("add_picture"))),
      ));
    }
    formWidgets.add(const SizedBox(
      height: 5,
    ));
    if (isEditMode) {
      formWidgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: ElevatedButton.icon(
            focusNode: FocusNode(skipTraversal: true),
            onPressed: () {
              setState(() {
                List<LanguageDataModel> names = [];
                for (int k = 0; k < languageList.length; k++) {
                  names.add(LanguageDataModel(code: languageList[k].code!, name: ""));
                }
                screenData.addressforshipping.add(CustomerAddressModel(
                    guid: "",
                    address: ["", "", ""],
                    countrycode: "",
                    provincecode: "",
                    districtcode: "",
                    subdistrictcode: "",
                    zipcode: "",
                    latitude: 0,
                    longitude: 0,
                    phoneprimary: "",
                    phonesecondary: "",
                    contactnames: names));
              });
            },
            icon: const Icon(Icons.add),
            label: Text(global.language("add_address_shipping"))),
      ));
    }

    formWidgets.add(const SizedBox(
      height: 5,
    ));

    if (isSaveAllow) {
      formWidgets.add(Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
          child: ElevatedButton.icon(
              focusNode: FocusNode(skipTraversal: true),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  saveOrUpdateData();
                }
              },
              icon: const Icon(Icons.save),
              label: Text(global.language("save") + ((kIsWeb) ? " (F10)" : "")))));
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
          title: Text(headerEdit + global.language("debtor")),
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
                                  context.read<DebtorBloc>().add(DebtorDelete(guid: selectGuid));
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
            if (isEditMode && global.systemLanguage.length > 1)
              Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: () async {
                      setState(() {
                        isLoadTranslation = true;
                      });

                      /// Translate names in global
                      for (int i = 0; i < screenData.names.length; i++) {
                        if (screenData.names[i].name.trim().isEmpty) {
                          var data = await global.translateNames(namesData: screenData.names);
                          setState(() {
                            screenData.names[i].name = data[i].name;
                          });
                        }
                      }

                      for (int i = 0; i < screenData.addressforbilling.contactnames!.length; i++) {
                        if (screenData.addressforbilling.contactnames![i].name.trim().isEmpty) {
                          var data = await global.translateNames(namesData: screenData.addressforbilling.contactnames!);
                          setState(() {
                            screenData.addressforbilling.contactnames![i].name = data[i].name;
                          });
                        }
                      }

                      setState(() {
                        isLoadTranslation = false;
                      });
                    },
                    icon: const Icon(
                      Icons.translate,
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
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent) {
            // print(event.logicalKey);
            if (event.logicalKey == LogicalKeyboardKey.f10) {
              if (_formKey.currentState!.validate()) {
                saveOrUpdateData();
              }
            }
            if (event.logicalKey == LogicalKeyboardKey.tab || event.logicalKey == LogicalKeyboardKey.enter) {
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
            padding: const EdgeInsets.only(top: 10, bottom: 15),
            child: Form(
              key: _formKey,
              child: Column(
                children: formWidgets,
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
        body: LayoutBuilder(builder: (context, constraints) {
          return MultiBlocListener(
              listeners: [
                BlocListener<DebtorBloc, DebtorState>(
                  listener: (context, state) {
                    blocCurrentState = state;
                    // Load
                    if (state is DebtorLoadSuccess) {
                      setState(() {
                        loadingData = false;
                        if (state.debtors.isNotEmpty) {
                          listData.addAll(state.debtors);
                        }
                      });
                    }
                    if (state is DebtorLoadFailed) {
                      setState(() {
                        loadingData = false;
                      });
                    }
                    // Save
                    if (state is DebtorSaveSuccess) {
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
                        loadDataList(searchText, selectedFilterCodes);
                      });
                    }
                    if (state is DebtorSaveFailed) {
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
                    if (state is DebtorUpdateSuccess) {
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
                        loadDataList(searchText, selectedFilterCodes);
                        isSaveAllow = false;
                        getData(selectGuid);
                      });
                    }
                    if (state is DebtorUpdateFailed) {
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
                    if (state is DebtorDeleteSuccess) {
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
                        loadDataList(searchText, selectedFilterCodes);
                      });
                    }
                    // Delete Many
                    if (state is DebtorDeleteManySuccess) {
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
                        loadDataList(searchText, selectedFilterCodes);
                        showCheckBox = false;
                      });
                    }
                    // Get
                    if (state is DebtorGetSuccess) {
                      setState(() {
                        getDataToEditScreen(state.debtors);
                        if (isEditMode) {
                          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                            tabController.animateTo(1);
                          });
                          setState(() {
                            findFocusNext(0);
                          });
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
                BlocListener<DebtorGroupBloc, DebtorGroupState>(listener: (context, state) {
                  // Load
                  if (state is DebtorGroupLoadSuccess) {
                    setState(() {
                      if (state.debtorGroups.isNotEmpty) {
                        listDataGroup = state.debtorGroups;
                      }
                    });
                  }
                })
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
                    ));
        }));
  }

  Future<List<DebtorGroupModel>> filterDebtorGroup(List<DebtorGroupModel> selectedFilters) async {
    List<DebtorGroupModel> selectedValues = selectedFilters;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Column(
                children: [
                  Text(global.language('filter_debtor_group')),
                  const Divider(),
                  Wrap(
                    spacing: 8.0,
                    children: selectedValues.map((filter) {
                      return InputChip(
                        label: Text(filter.groupcode),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () {
                          setState(() {
                            selectedValues.remove(filter);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const Divider(),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: listDataGroup.length,
                  itemBuilder: (BuildContext context, int index) {
                    final filter = listDataGroup[index];
                    final isSelected = selectedValues.contains(filter);
                    return CheckboxListTile(
                      title: Text("${filter.groupcode} ~ ${(global.packName(filter.names))} "),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedValues.add(filter);
                          } else {
                            selectedValues.remove(filter);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(global.language("filter")),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      Navigator.pop(context);
                      selectedValues.clear();
                    });
                  },
                  child: Text(global.language("cancel")),
                ),
              ],
            );
          },
        );
      },
    );

    return selectedValues;
  }
}
