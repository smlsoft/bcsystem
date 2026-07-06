import 'dart:async';

import 'package:smlaicloud/bloc/warehouse/warehose_bloc.dart';
import 'package:smlaicloud/bloc/warehouse_location/warehouse_location_bloc.dart';
import 'package:smlaicloud/model/location_model.dart';
import 'package:smlaicloud/model/shelf_model.dart';
import 'package:smlaicloud/model/warehouse_location_model.dart';
import 'package:smlaicloud/model/warehouse_location_update_model.dart';
import 'package:smlaicloud/model/warehouse_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smlaicloud/global.dart' as global;
import 'package:smlaicloud/model/global_model.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:split_view/split_view.dart';
import 'package:smlaicloud/screen_search/product_warehouse_search_screen.dart';
import 'package:translator/translator.dart';

class ProductLocaltionScreen extends StatefulWidget {
  const ProductLocaltionScreen({Key? key}) : super(key: key);

  @override
  State<ProductLocaltionScreen> createState() => ProductLocaltionScreenState();
}

class ProductLocaltionScreenState extends State<ProductLocaltionScreen> with SingleTickerProviderStateMixin {
  final translator = GoogleTranslator();
  late TabController tabController;
  ScrollController editScrollController = ScrollController();
  bool refreshFocus = false;
  TextEditingController searchController = TextEditingController();
  TextEditingController warehouseCodeController = TextEditingController();
  List<LanguageModel> warehouseNameController = <LanguageModel>[];
  int focusNodeMax = 0;
  FocusNode searchFocusNode = FocusNode(skipTraversal: true);
  List<LanguageModel> languageList = <LanguageModel>[];
  List<global.FieldFocusModel> fieldFocusNodes = [];
  int focusNodeIndex = 0;
  List<WarehouseLocationModel> listData = [];
  List<String> guidListChecked = [];
  List<LanguageDataModel> names = [];
  ScrollController listScrollController = ScrollController();
  List<GlobalKey> listKeys = [];
  String searchText = "";
  String selectGuid = "";
  bool isDataChange = false;
  bool isSaveAllow = false;
  late WarehouseLocationState blocWarehouseLocationState;
  late WarehouseState blocWarehouseState;
  String headerEdit = "";
  late MediaQueryData queryData;
  int currentListIndex = -1;
  GlobalKey headerKey = GlobalKey();
  bool isKeyUp = false;
  bool isKeyDown = false;
  bool showCheckBox = false;
  bool isEditMode = false;
  bool isAddMode = false;
  late WarehouseModel screenData;
  late LocationModel locationData;
  late WarehouseModel warehouseData;

  late DropzoneViewController dropZoneController;
  Color colorSelected = Colors.white;
  final _debouncer = global.Debouncer(1000);
  late Timer screenTimer;
  bool loadingData = false;
  String selectWarehouseCode = "";
  String selectLocationCode = "";
  late SplitViewController splitViewController;
  global.ScreenEventEnum screenEvent = global.ScreenEventEnum.list;

  bool isLoadTranslation = false;

  void setSystemLanguageList() async {
    await global.setSystemLanguage(context);

    for (int i = 0; i < global.config.languages.length; i++) {
      if (global.config.languages[i].isuse!) {
        languageList.add(global.config.languages[i]);
      }
    }
    clearEditData();
    loadDataList("");
  }

  @override
  void initState() {
    clearEditData();
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
    setSystemLanguageList();

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
    warehouseCodeController.dispose();
    for (int i = 0; i < fieldFocusNodes.length; i++) {
      fieldFocusNodes[i].focusNode.dispose();
    }
    super.dispose();
  }

  void changeScreenEvent(global.ScreenEventEnum event) {
    // print(event);
    screenEvent = event;
    for (int index = 0; index < fieldFocusNodes.length; index++) {
      fieldFocusNodes[index].isReadOnly = (screenEvent == global.ScreenEventEnum.list) ? true : false;
    }
    if (screenEvent == global.ScreenEventEnum.edit) {
      fieldFocusNodes[0].isReadOnly = true;
    }
    setState(() {});
  }

  void loadDataList(String search) {
    setState(() {
      loadingData = true;
    });
    searchText = search;
    context.read<WarehouseLocationBloc>().add(WarehouseLoadLocationList(offset: (listData.isEmpty) ? 0 : listData.length, limit: global.loadDataPerPage, search: search));
  }

  void onScrollList() {
    if (listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange) {
      loadDataList(searchText);
    }
  }

  String getLangName(String code) {
    LanguageModel name = languageList.firstWhere((element) => element.code == code, orElse: () => LanguageModel(code: '', codeTranslator: '', name: '', isuse: false));
    return name.name!;
  }

  void clearEditData() {
    List<LanguageDataModel> names = [];
    for (int k = 0; k < languageList.length; k++) {
      names.add(LanguageDataModel(code: languageList[k].code!, name: ""));
    }

    List<LanguageDataModel> locationnames = [];
    for (int k = 0; k < languageList.length; k++) {
      locationnames.add(LanguageDataModel(code: languageList[k].code!, name: ""));
    }

    warehouseCodeController.text = "";
    screenData = WarehouseModel(
      guidfixed: "",
      code: "",
      names: names,
      location: [],
    );

    locationData = LocationModel(
      code: "",
      names: names,
      shelf: [],
    );

    warehouseData = WarehouseModel(
      guidfixed: "",
      code: "",
      names: names,
      location: [],
    );

    isDataChange = false;
    focusNodeIndex = 0;
    refreshFocus = true;
    isDataChange = false;
  }

  void discardData({required Function callBack}) {
    // กรณีมีการแก้ไขข้อมูล ให้เตือน
    if ((screenEvent == global.ScreenEventEnum.add || screenEvent == global.ScreenEventEnum.edit) && isDataChange) {
      showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                title: Text(global.language('data_editing')),
                content: Text(global.language('leave_this_screen')),
                actions: <Widget>[
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: global.theme.buttonNoColor), onPressed: () => Navigator.pop(context), child: Text(global.language('no'))),
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

  void getData(String warehousecode, String locationcode) {
    headerEdit = global.language("show");
    if (isAddMode) {
      changeScreenEvent(global.ScreenEventEnum.add);
    } else {
      changeScreenEvent(global.ScreenEventEnum.list);
    }
    context.read<WarehouseLocationBloc>().add(WarehouseLocationGetByCode(warehousecode: warehousecode, locationcode: locationcode));
  }

  void getWarehouseData(String guid) {
    context.read<WarehouseBloc>().add(WarehouseGet(guid: guid));
  }

  Widget listScreen({bool mobileScreen = false}) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: global.theme.appBarColor,
        automaticallyImplyLeading: false,
        title: Text(global.language('product_location')),
        leading: IconButton(
          focusNode: FocusNode(skipTraversal: true),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            discardData(callBack: () {
              Navigator.pushReplacementNamed(context, '/menu');
              isEditMode = false;
              isAddMode = false;
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
                                context.read<WarehouseLocationBloc>().add(WarehouseLocationDeleteMany(
                                      warehousecode: selectWarehouseCode,
                                      locationcode: guidListChecked,
                                    ));
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
                      selectWarehouseCode = "";
                      selectLocationCode = "";
                      showCheckBox = false;
                      isDataChange = false;
                      isAddMode = true;
                      clearEditData();
                      changeScreenEvent(global.ScreenEventEnum.add);
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
                int index = listData.indexOf(listData.firstWhere((element) => element.locationcode == selectGuid));
                if (index > 0) {
                  selectGuid = listData[index - 1].locationcode;
                  currentListIndex = index + 1;
                  isKeyUp = true;
                  getData(selectWarehouseCode, selectLocationCode);
                }
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                isKeyUp = false;
                int index = listData.indexOf(listData.firstWhere((element) => element.locationcode == selectGuid));
                selectGuid = listData[index + 1].locationcode;
                currentListIndex = index + 1;
                isKeyDown = true;
                getData(selectWarehouseCode, selectLocationCode);
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
              key: headerKey,
              padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
              color: global.theme.columnHeaderColor,
              child: Row(children: [
                Expanded(
                    flex: 5,
                    child: Text(global.language("warehouse_code"),
                        style: TextStyle(color: global.theme.columnHeaderTextColor, fontWeight: FontWeight.bold, fontSize: global.deviceConfig.listDataFontSize + 2))),
                Expanded(
                    flex: 10,
                    child: Text(
                      global.language("warehouse_name"),
                      style: TextStyle(color: global.theme.columnHeaderTextColor, fontWeight: FontWeight.bold, fontSize: global.deviceConfig.listDataFontSize + 2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )),
                Expanded(
                    flex: 5,
                    child: Text(global.language("location_code"),
                        style: TextStyle(color: global.theme.columnHeaderTextColor, fontWeight: FontWeight.bold, fontSize: global.deviceConfig.listDataFontSize + 2))),
                Expanded(
                    flex: 10,
                    child: Text(
                      global.language("location_name"),
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

  void switchToEdit(WarehouseLocationModel value) {
    setState(() {
      selectGuid = value.guidfixed;
      selectWarehouseCode = value.warehousecode;
      selectLocationCode = value.locationcode;
      getData(selectWarehouseCode, selectLocationCode);
      headerEdit = global.language("edit");
      changeScreenEvent(global.ScreenEventEnum.edit);
      isSaveAllow = true;
      isEditMode = true;
      isAddMode = false;
    });
  }

  Widget listObject(int index, WarehouseLocationModel value, bool showCheckBox) {
    bool isCheck = false;

    for (int i = 0; i < guidListChecked.length; i++) {
      if (guidListChecked[i] == value.locationcode) {
        isCheck = true;
        break;
      }
    }
    listKeys.add(GlobalKey());
    bool selected = selectLocationCode == value.locationcode && selectWarehouseCode == value.warehousecode;
    TextStyle textStyle =
        TextStyle(fontWeight: (selected) ? FontWeight.bold : FontWeight.normal, fontSize: (selected) ? global.deviceConfig.listDataFontSize + 2.0 : global.deviceConfig.listDataFontSize);
    return GestureDetector(
        onTap: () {
          selectGuid = value.guidfixed;
          if (showCheckBox == true) {
            setState(() {
              selectWarehouseCode = value.warehousecode;
              selectLocationCode = value.locationcode;
              if (isCheck == true) {
                guidListChecked.remove(value.locationcode);
              } else {
                guidListChecked.add(value.locationcode);
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
                isAddMode = false;
                selectGuid = value.guidfixed;

                selectWarehouseCode = value.warehousecode;
                selectLocationCode = value.locationcode;
                changeScreenEvent(global.ScreenEventEnum.list);
                getData(selectWarehouseCode, selectLocationCode);
                searchFocusNode.requestFocus();
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
            color: (selectWarehouseCode == value.warehousecode && selectLocationCode == value.locationcode)
                ? Colors.cyan[100]
                : (index % 2 == 0)
                    ? global.theme.columnAlternateEvenColor
                    : global.theme.columnAlternateOddColor,
            padding: EdgeInsets.only(left: 10, right: 10, top: global.deviceConfig.listDataLineSpace, bottom: global.deviceConfig.listDataLineSpace),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 5, child: Text(value.warehousecode, maxLines: 2, overflow: TextOverflow.ellipsis, style: textStyle)),
              Expanded(flex: 10, child: Text(global.packName(value.warehousenames), maxLines: 2, overflow: TextOverflow.ellipsis, style: textStyle)),
              Expanded(flex: 5, child: Text(value.locationcode, maxLines: 2, overflow: TextOverflow.ellipsis, style: textStyle)),
              Expanded(flex: 10, child: Text(global.packName(value.locationnames), maxLines: 2, overflow: TextOverflow.ellipsis, style: textStyle)),
              if (showCheckBox) Expanded(flex: 1, child: (isCheck) ? const Icon(Icons.check, size: 12) : Container())
            ])));
  }

  void saveOrUpdateData() {
    showCheckBox = false;

    if (isAddMode) {
      saveData();
    } else {
      updateData(selectWarehouseCode, selectLocationCode);
    }
  }

  void saveData() {
    // // print(jsonEncode(warehouseData.toJson()));
    // // print(jsonEncode(locationData.toJson()));

    warehouseData.location.add(LocationModel(
      code: locationData.code,
      names: locationData.names,
      shelf: locationData.shelf,
    ));

    WarehouseModel dataSave = WarehouseModel(
      guidfixed: screenData.guidfixed,
      code: screenData.code,
      names: screenData.names,
      location: warehouseData.location,
    );

    // // print(jsonEncode(dataSave.toJson()));

    context.read<WarehouseBloc>().add(WarehouseUpdate(guid: screenData.guidfixed, warehouseModel: dataSave));
  }

  void updateData(String selectWarehouseCode, String selectLocationCode) {
    WarehouseLocationUpdateModel dataSave = WarehouseLocationUpdateModel(
      warehousecode: screenData.code,
      locationcode: locationData.code,
      locationnames: locationData.names,
      shelf: locationData.shelf,
    );

    // print(jsonEncode(dataSave.toJson()));

    context.read<WarehouseLocationBloc>().add(WarehouseLocationUpdate(warehousecode: selectWarehouseCode, locationcode: selectLocationCode, warehouseLocationUpdateModel: dataSave));
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

  void warehouseSearch() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductWarehouseSearchScreen(word: ""))).then((value) {
      if (value != null) {
        setState(() {
          SearchGuidCodeNameModel result = value;
          if (result.isCancel == false) {
            screenData.guidfixed = result.guid;
            screenData.code = result.code;
            screenData.names = result.names;

            getWarehouseData(screenData.guidfixed);
          }
        });
      }
    });
  }

  Widget multiShrlf() {
    List<Widget> widgets = [];
    List<Widget> multiShelfWidgets = [];

    for (int shelfIndex = 0; shelfIndex < locationData.shelf.length; shelfIndex++) {
      multiShelfWidgets.add(const SizedBox(
        height: 10,
      ));

      multiShelfWidgets.add(TextField(
          readOnly: !isEditMode,
          onSubmitted: (value) {
            if (kIsWeb) {
              findFocusNext(focusNodeIndex);
            }
          },
          focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
          textAlign: TextAlign.left,
          controller: TextEditingController(text: locationData.shelf[shelfIndex].code),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('[a-z A-Z 0-9 -]'))],
          onChanged: (value) {
            isDataChange = true;
            locationData.shelf[shelfIndex].code = value.toUpperCase();
          },
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
            labelText: "${global.language("shelf_code")} (${shelfIndex + 1})",
          )));

      multiShelfWidgets.add(Padding(
        padding: const EdgeInsets.only(top: 10),
        child: TextField(
            readOnly: !isEditMode,
            onSubmitted: (value) {
              if (kIsWeb) {
                findFocusNext(focusNodeIndex);
              }
            },
            focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
            textAlign: TextAlign.left,
            controller: TextEditingController(text: locationData.shelf[shelfIndex].name),
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) {
              isDataChange = true;
              locationData.shelf[shelfIndex].name = value;
            },
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              labelText: "${global.language("shelf_name")} (${shelfIndex + 1})",
            )),
      ));

      multiShelfWidgets.add(Row(children: [
        Expanded(
            child: Row(
          children: [Container()],
        )),
        IconButton(
          icon: const Icon(Icons.delete),
          padding: EdgeInsets.zero,
          onPressed: locationData.shelf.length > 1
              ? () {
                  locationData.shelf.removeAt(shelfIndex);
                  setState(() {});
                }
              : null,
        ),
      ]));

      if (shelfIndex < locationData.shelf.length - 1) {
        multiShelfWidgets.add(const Divider(
          height: 1,
          color: Colors.grey,
        ));
      }
    }

    widgets.add(Container(
        margin: const EdgeInsets.only(left: 10, right: 10),
        width: double.infinity,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          children: [
            Container(width: double.infinity, padding: const EdgeInsets.only(left: 2, right: 2, bottom: 10), child: Column(children: multiShelfWidgets)),
            Container(
                padding: const EdgeInsets.only(bottom: 5),
                width: double.infinity,
                child: ElevatedButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: () {
                      locationData.shelf.add(ShelfModel(
                        code: "",
                        name: "",
                      ));
                      setState(() {});
                    },
                    child: Text(global.language("shelf_add"))))
          ],
        )));
    return SizedBox(
      width: double.infinity,
      child: Column(children: widgets),
    );
  }

  Widget editScreen({mobileScreen}) {
    List<Widget> formWidgets = [];

    focusNodeMax = 0;
    formWidgets.add(Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Row(children: [
          Expanded(
              child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (RawKeyEvent event) {
                    if (event is RawKeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.f2) {
                        warehouseSearch();
                      }
                    }
                  },
                  child: TextField(
                      readOnly: true,
                      textInputAction: TextInputAction.next,
                      focusNode: fieldFocusNodes[focusNodeMax].focusNode,
                      controller: TextEditingController(text: screenData.code),
                      textAlign: TextAlign.left,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (code) {
                        screenData.code = code;
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.all(10.0),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey, width: 0.0),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        suffixIcon: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              focusNode: FocusNode(skipTraversal: true),
                              icon: const Icon(Icons.search),
                              onPressed: () {
                                if (isEditMode) {
                                  warehouseSearch();
                                }
                              },
                            ),
                          ],
                        ),
                        border: const OutlineInputBorder(),
                        labelText: global.language("warehouse_code"),
                      )))),
          const SizedBox(width: 5),
          Expanded(
              child: TextField(
                  readOnly: true,
                  controller: TextEditingController(text: global.packName(screenData.names)),
                  textAlign: TextAlign.left,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(10.0),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 0.0),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: const OutlineInputBorder(),
                    labelText: global.language("warehouse_name"),
                  )))
        ])));

    formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: TextField(
            readOnly: !isEditMode,
            onSubmitted: (value) {
              if (kIsWeb) {
                findFocusNext(focusNodeIndex);
              }
            },
            focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
            textAlign: TextAlign.left,
            controller: TextEditingController(text: locationData.code),
            textCapitalization: TextCapitalization.characters,
            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('[a-z A-Z 0-9 -]'))],
            onChanged: (value) {
              isDataChange = true;
              locationData.code = value.toUpperCase();
            },
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              labelText: global.language("location_code"),
            ))));
    for (int languageIndex = 0; languageIndex < languageList.length; languageIndex++) {
      LanguageDataModel locationName = locationData.names.firstWhere((element) => element.code == languageList[languageIndex].code, orElse: () => LanguageDataModel(code: '', name: ''));
      if (locationName.code == '') {
        locationData.names.add(LanguageDataModel(code: languageList[languageIndex].code!, name: ''));
      }
      formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: TextField(
          readOnly: !isEditMode,
          onChanged: (value) {
            isDataChange = true;
            locationData.names[languageIndex].name = value;
          },
          onSubmitted: (value) {
            if (kIsWeb) {
              findFocusNext(focusNodeIndex);
            }
          },
          focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
          textAlign: TextAlign.left,
          controller: TextEditingController(text: locationData.names[languageIndex].name),
          decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              labelText: "${global.language("location_name")} (${getLangName(locationData.names[languageIndex].code)})",
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

    formWidgets.add(const SizedBox(
      height: 5,
    ));
    formWidgets.add(multiShrlf());

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
              label: Text(global.language("save") + ((kIsWeb) ? " (F10)" : "")))));
    }
    return Scaffold(
        backgroundColor: global.theme.backgroundColor,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
            backgroundColor: (screenEvent == global.ScreenEventEnum.edit || screenEvent == global.ScreenEventEnum.add) ? global.theme.toolBarEditModeColor : global.theme.appBarColor,
            automaticallyImplyLeading: false,
            leading: mobileScreen
                ? IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () async {
                      showCheckBox = false;
                      discardData(callBack: () {
                        changeScreenEvent(global.ScreenEventEnum.list);
                        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                          tabController.animateTo(0);
                        });
                      });
                    })
                : null,
            title: Text(headerEdit + global.language("product_location")),
            actions: <Widget>[
              if (selectWarehouseCode.isNotEmpty && selectLocationCode.isNotEmpty)
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
                              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context), child: Text(global.language('no'))),
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  onPressed: () {
                                    guidListChecked.add(selectLocationCode);
                                    Navigator.pop(context);
                                    context.read<WarehouseLocationBloc>().add(WarehouseLocationDeleteMany(
                                          warehousecode: selectWarehouseCode,
                                          locationcode: guidListChecked,
                                        ));
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
              if (isSaveAllow == false && selectWarehouseCode.trim().isNotEmpty && selectLocationCode.trim().isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: IconButton(
                      focusNode: FocusNode(skipTraversal: true),
                      onPressed: () {
                        showCheckBox = false;
                        switchToEdit(listData[listData.indexOf(listData.firstWhere((element) => element.warehousecode == selectWarehouseCode && element.locationcode == selectLocationCode))]);
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

                        try {
                          for (var name in locationData.names) {
                            if (name.name.trim().isEmpty) {
                              var data = await global.translateNames(namesData: locationData.names);
                              setState(() {
                                locationData.names = data;
                              });
                              break;
                            }
                          }
                        } catch (e) {
                          if (kDebugMode) {
                            print(e);
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
                  color: Colors.white,
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Form(child: Column(children: formWidgets)),
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
        body: LayoutBuilder(builder: (context, constraints) {
          return MultiBlocListener(
              listeners: [
                BlocListener<WarehouseLocationBloc, WarehouseLocationState>(
                  listener: (context, state) {
                    blocWarehouseLocationState = state;

                    // Load
                    if (state is WarehouseLocationLoadSuccess) {
                      setState(() {
                        loadingData = false;
                        if (state.warehouses.isNotEmpty) {
                          listData.addAll(state.warehouses);
                        }
                      });
                    }
                    if (state is WarehouseLocationLoadFailed) {
                      setState(() {
                        loadingData = false;
                      });
                    }

                    // Update
                    if (state is WarehouseLocationUpdateSuccess) {
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
                        getData(selectWarehouseCode, selectLocationCode);
                      });
                    }
                    if (state is WarehouseLocationUpdateFailed) {
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

                    // Get
                    if (state is WarehouseLocationGetSuccess) {
                      setState(() {
                        isDataChange = false;

                        screenData.code = state.warehouselocation.warehousecode;
                        screenData.names = state.warehouselocation.warehousenames;

                        warehouseCodeController.text = screenData.code;

                        locationData.code = state.warehouselocation.locationcode;
                        locationData.names = state.warehouselocation.locationnames;

                        locationData.shelf = state.warehouselocation.shelf;

                        if (screenEvent == global.ScreenEventEnum.edit) {
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
                              listScrollController.animateTo(listScrollController.offset - (boxHeader.size.height + box.size.height), duration: const Duration(milliseconds: 100), curve: Curves.ease);
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
                    // Delete Many
                    if (state is WarehouseLocationDeleteManySuccess) {
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
                  },
                ),
                BlocListener<WarehouseBloc, WarehouseState>(
                  listener: (context, state) {
                    blocWarehouseState = state;
                    // Update
                    if (state is WarehouseUpdateSuccess) {
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
                        getData(selectWarehouseCode, selectLocationCode);
                      });
                    }
                    if (state is WarehouseUpdateFailed) {
                      clearEditData();
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

                    /// Get Warehouse by guid
                    if (state is WarehouseGetSuccess) {
                      setState(() {
                        warehouseData = state.warehouse;
                        findFocusNext(0);
                      });
                    }
                  },
                ),
              ],
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
