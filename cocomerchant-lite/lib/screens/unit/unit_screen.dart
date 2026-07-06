import 'dart:convert';
import 'dart:io';
import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/utils/dialog_template.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocomerchant_lite/bloc/unit/unit_bloc.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/model/product_model.dart';
import 'package:split_view/split_view.dart';
import 'package:translator/translator.dart';

class UnitScreen extends StatefulWidget {
  static String routeName = "/unit";
  const UnitScreen({super.key});

  @override
  State<UnitScreen> createState() => UnitScreenState();
}

class UnitScreenState extends State<UnitScreen> with SingleTickerProviderStateMixin {
  final translator = GoogleTranslator();
  late TabController tabController;
  ScrollController editScrollController = ScrollController();
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode(skipTraversal: true);
  List<LanguageModel> languageList = <LanguageModel>[];
  List<TextEditingController> fieldTextController = [];
  List<global.FieldFocusModel> fieldFocusNodes = [];
  int focusNodeIndex = 0;
  List<UnitModel> listData = [];
  List<UnitModel> listTempData = [];
  List<String> unitGuidListChecked = [];
  List<LanguageDataModel> names = [];
  ScrollController listScrollController = ScrollController();
  List<GlobalKey> listKeys = [];
  String searchText = "";
  String selectGuid = "";
  bool isChange = false;
  bool isSaveAllow = false;
  late UnitState blocUnitState;
  String headerEdit = "";
  late MediaQueryData queryData;
  int currentListIndex = -1;
  GlobalKey headerKey = GlobalKey();
  bool isKeyUp = false;
  bool isKeyDown = false;
  bool showCheckBox = false;
  global.ScreenEventEnum screenEvent = global.ScreenEventEnum.list;
  late SplitViewController splitViewController;
  final debouncer = global.Debouncer(1000);
  bool showAllLanguages = false;

  UnitModel dataTemp = UnitModel(guidfixed: '', unitcode: '');

  bool isLoadTranslation = false;
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
    try {
      await global.setSystemLanguage(context);
    } catch (ex) {
      // print(ex);
    }
    for (int i = 0; i < global.config.languages.length; i++) {
      if (global.config.languages[i].isuse!) {
        languageList.add(global.config.languages[i]);
      }
    }
    for (int i = 0; i < languageList.length; i++) {
      fieldTextController.add(TextEditingController());
      FocusNode focusNode = FocusNode();
      focusNode.addListener(() {
        focusNodeIndex = i;
      });
      fieldFocusNodes.add(global.FieldFocusModel(focusNode: focusNode));
    }
    setState(() {});
  }

  @override
  void initState() {
    getTemplate();
    tabController = TabController(vsync: this, length: 2);
    tabController.addListener(() {
      setState(() {});
    });

    splitViewController = SplitViewController(limits: [null, WeightLimit(min: 0.2, max: 0.8)]);
    // เรียงลำดับ Focus
    // Focus รหัส
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
    context.read<UnitBloc>().add(UnitLoadList(offset: (listData.isEmpty) ? 0 : listData.length, limit: global.loadDataPerPage, search: search));
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
    isChange = false;
    focusNodeIndex = 0;
    fieldFocusNodes[focusNodeIndex].focusNode.requestFocus();
  }

  Future<void> getTemplate() async {
    const githubRawUrl = 'https://raw.githubusercontent.com/smlsoft/dedepos_template/main/unit.json';
    try {
      final fileContent = await global.readFileFromGithub(githubRawUrl);
      final unit = (json.decode(fileContent) as List).map((unit) => UnitModel.fromJson(unit)).toList();
      listTempData = [];

      for (int i = 0; i < unit.length; i++) {
        listTempData.add(unit[i]);
      }

      if (listData.isNotEmpty) {
        /// bankTempListDatas remove where bankListDatas
        for (int i = 0; i < listData.length; i++) {
          listTempData.removeWhere((element) => element.unitcode == listData[i].unitcode);
        }
      }

      loadDataList("");
    } catch (error) {
      // Handle error
      // ignore: avoid_print
      print('Error reading file: $error');
    }
  }

  void discardData({required Function callBack}) {
    // กรณีมีการแก้ไขข้อมูล ให้เตือน
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
    context.read<UnitBloc>().add(UnitGet(guid: guid));
  }

  Widget listScreen({bool mobileScreen = false}) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        automaticallyImplyLeading: false,
        title: Text(global.language('product_unit'), style: Theme.of(context).textTheme.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            discardData(callBack: () {
              Navigator.pushReplacementNamed(context, '/menu');
              changeScreenEvent(global.ScreenEventEnum.list);
            });
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.cloud_download),
            onPressed: () async {
              await getTemplate();
              List<dynamic> selectedData = await DialogTemplate.showDataListTemplateDialog(context, listTempData, "unit");
              if (selectedData.isNotEmpty) {
                List<UnitModel> unitTempSelected = [];
                for (int i = 0; i < selectedData.length; i++) {
                  if (selectedData[i] == true) {
                    unitTempSelected.add(listTempData[i]);
                  }
                }
                context.read<UnitBloc>().add(UnitSaveBulk(units: unitTempSelected));
              }
            },
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.font),
            onPressed: () {
              setState(() {
                global.listDataFontSizeChange();
              });
            },
          ),
          IconButton(
            icon: Icon(showCheckBox ? Icons.close : Icons.check_box),
            onPressed: () {
              discardData(callBack: () {
                setState(() {
                  showCheckBox = !showCheckBox;
                  if (!showCheckBox)
                    unitGuidListChecked.clear();
                  else {
                    global.showSnackBar(context, const Icon(Icons.delete, color: Colors.white), global.language("choose_item_delete"), Colors.blue);
                  }
                });
              });
            },
          ),
          if (unitGuidListChecked.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: Text(global.language('confirm_delete')),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(global.language('no')),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.read<UnitBloc>().add(UnitDeleteMany(guid: unitGuidListChecked));
                        },
                        child: Text(global.language('confirm')),
                      ),
                    ],
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              discardData(callBack: () {
                setState(() {
                  changeScreenEvent(global.ScreenEventEnum.add);
                  selectGuid = "";
                  showCheckBox = false;
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
          ),
        ],
      ),
      body: Column(
        children: [
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
            child: RawKeyboardListener(
              autofocus: true,
              focusNode: FocusNode(skipTraversal: true, canRequestFocus: true),
              onKey: (RawKeyEvent event) {
                if (screenEvent == global.ScreenEventEnum.list) {
                  if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
                    if (event is RawKeyUpEvent) {
                      try {
                        if (event.logicalKey == LogicalKeyboardKey.f2) {
                          isKeyDown = false;
                          searchFocusNode.requestFocus();
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                          isKeyDown = false;
                          int index = listData.indexOf(listData.firstWhere((element) => element.guidfixed! == selectGuid));
                          if (index > 0) {
                            selectGuid = listData[index - 1].guidfixed!;
                            currentListIndex = index - 1;
                            isKeyUp = true;
                            getData(selectGuid);
                          }
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                          isKeyUp = false;
                          int index = listData.indexOf(listData.firstWhere((element) => element.guidfixed! == selectGuid));
                          selectGuid = listData[index + 1].guidfixed!;
                          currentListIndex = index + 1;
                          isKeyDown = true;
                          getData(selectGuid);
                        }
                      } catch (_) {}
                    }
                  }
                }
              },
              child: ListView.builder(
                controller: listScrollController,
                itemCount: listData.length,
                itemBuilder: (context, index) => listObject(index, listData[index], showCheckBox),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void switchToEdit(UnitModel value) {
    setState(() {
      selectGuid = value.guidfixed!;
      getData(selectGuid);
      headerEdit = global.language("edit");
      isSaveAllow = true;
      changeScreenEvent(global.ScreenEventEnum.edit);
    });
  }

  Widget listObject(int index, UnitModel value, bool showCheckBox) {
    // ตรวจสอบและปรับขนาดของ listKeys ถ้าจำเป็น
    while (listKeys.length <= index) {
      listKeys.add(GlobalKey());
    }

    bool isCheck = unitGuidListChecked.contains(value.guidfixed);
    bool selected = selectGuid == value.guidfixed;

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
          backgroundColor: kPrimaryColor,
          child: Text(
            value.unitcode?.substring(0, 1).toUpperCase() ?? '',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          value.unitcode!,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: selected ? global.deviceConfig.listDataFontSize + 2.0 : global.deviceConfig.listDataFontSize,
          ),
        ),
        subtitle: Text(
          global.packName(value.names!),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: global.deviceConfig.listDataFontSize - 2),
        ),
        trailing: showCheckBox
            ? Checkbox(
                value: isCheck,
                onChanged: (bool? newValue) {
                  setState(() {
                    if (newValue == true) {
                      unitGuidListChecked.add(value.guidfixed!);
                    } else {
                      unitGuidListChecked.remove(value.guidfixed);
                    }
                    isCheck = newValue ?? false;
                  });
                  global.showSnackBar(
                      context, const Icon(Icons.check, color: Colors.white), "${global.language("chosen")} ${unitGuidListChecked.length} ${global.language("list")}", Colors.blue);
                },
              )
            : null,
        onTap: () {
          if (showCheckBox) {
            setState(() {
              if (isCheck) {
                unitGuidListChecked.remove(value.guidfixed);
              } else {
                unitGuidListChecked.add(value.guidfixed!);
              }
              isCheck = !isCheck;
            });
          } else {
            discardData(callBack: () {
              setState(() {
                isSaveAllow = false;
                changeScreenEvent(global.ScreenEventEnum.list);
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

  List<LanguageDataModel> packLanguage() {
    List<LanguageDataModel> names = [];
    for (int i = 0; i < languageList.length; i++) {
      if (languageList[i].code!.trim().isNotEmpty) {
        names.add(LanguageDataModel(code: languageList[i].code!, name: fieldTextController[i + 1].text));
      }
    }

    for (var defualtValueLang in dataTemp.names!) {
      LanguageDataModel result = names.firstWhere((data) => data.code == defualtValueLang.code, orElse: () => LanguageDataModel(code: '', name: ''));
      if (result.code == '') {
        names.add(defualtValueLang);
      }
    }

    return names;
  }

  bool verifyData(UnitModel value) {
    List<String> errorList = [];
    if (value.unitcode!.isEmpty) {
      errorList.add(global.language("unit_code"));
    }
    if (value.names!.isEmpty || value.names![0].name.isEmpty) {
      errorList.add(global.language("name"));
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
    if (screenEvent == global.ScreenEventEnum.edit || screenEvent == global.ScreenEventEnum.add) {
      UnitModel unit = UnitModel(
        guidfixed: "",
        unitcode: fieldTextController[0].text,
        names: packLanguage(),
      );
      if (verifyData(unit)) {
        showCheckBox = false;
        if (selectGuid.trim().isEmpty) {
          context.read<UnitBloc>().add(UnitSave(unitModel: unit));
        } else {
          showCheckBox = false;
          context.read<UnitBloc>().add(UnitUpdate(guid: selectGuid, unitModel: unit));
        }
      }
    }
  }

  void getDataToEditScreen(UnitModel unit) {
    isChange = false;
    selectGuid = unit.guidfixed!;
    fieldTextController[0].text = unit.unitcode!;
    for (int i = 0; i < languageList.length; i++) {
      fieldTextController[i + 1].text = "";
    }
    for (int i = 0; i < languageList.length; i++) {
      for (int j = 0; j < unit.names!.length; j++) {
        if (languageList[i].code! == unit.names![j].code) {
          fieldTextController[i + 1].text = unit.names![j].name;
        }
      }
    }
  }

  void findFocusNext(int index) {
    // print("findFocusNext($index)");
    focusNodeIndex = index + 1;
    if (focusNodeIndex > fieldFocusNodes.length - 1) {
      focusNodeIndex = 0;
    }
    while (true) {
      if (fieldFocusNodes[focusNodeIndex].isReadOnly == true) {
        focusNodeIndex++;
        if (focusNodeIndex > fieldFocusNodes.length - 1) {
          break;
        }
      } else {
        fieldFocusNodes[focusNodeIndex].focusNode.requestFocus();
        fieldTextController[focusNodeIndex].selection = TextSelection.fromPosition(TextPosition(offset: fieldTextController[focusNodeIndex].text.length));
        break;
      }
    }
  }

  Widget editScreen({mobileScreen}) {
    return Scaffold(
      backgroundColor: global.theme.backgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
          backgroundColor: kPrimaryColor,
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
          title: Text(headerEdit + global.language("product_unit")),
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
                                style: ElevatedButton.styleFrom(backgroundColor: global.theme.buttonNoColor),
                                onPressed: () => Navigator.pop(context),
                                child: Text(global.language('no'))),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: global.theme.buttonYesColor),
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.read<UnitBloc>().add(UnitDelete(guid: selectGuid));
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
            if ((screenEvent == global.ScreenEventEnum.add || screenEvent == global.ScreenEventEnum.edit) && global.systemLanguage.length > 1)
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
                          if (fieldTextController[i].text.isEmpty) {
                            var translation = await translator.translate(fieldTextController[1].text, to: languageList[i - 1].codeTranslator!);
                            fieldTextController[i].text = translation.text;
                          }
                        } catch (e) {
                          if (kDebugMode) {
                            print(e);
                          }
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
            if (isSaveAllow == false && selectGuid.trim().isNotEmpty)
              Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: () {
                      showCheckBox = false;
                      switchToEdit(listData[listData.indexOf(listData.firstWhere((element) => element.guidfixed! == selectGuid))]);
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
        focusNode: FocusNode(skipTraversal: true),
        onKey: (event) {
          if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
            if (event is RawKeyUpEvent) {
              if (event.logicalKey == LogicalKeyboardKey.tab) {
                // print("Tab");
              }
              if (event.logicalKey == LogicalKeyboardKey.f10) {
                saveOrUpdateData();
              }
            }
          }
        },
        child: SingleChildScrollView(
          controller: editScrollController,
          child: Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const SizedBox(height: 10),

                /// unit_code
                TextFormField(
                  readOnly: fieldFocusNodes[0].isReadOnly,
                  onFieldSubmitted: (value) {
                    findFocusNext(0);
                  },
                  textInputAction: TextInputAction.next,
                  focusNode: fieldFocusNodes[0].focusNode,
                  textAlign: TextAlign.left,
                  controller: fieldTextController[0],
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('[a-z A-Z 0-9 -]'))],
                  onChanged: (value) {
                    isChange = true;
                    fieldTextController[0].value = TextEditingValue(text: value.toUpperCase(), selection: fieldTextController[0].selection);
                  },
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 0.0),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: global.language("unit_code"),
                    labelStyle: TextStyle(color: global.theme.inputTextBoxForceColor),
                  ),
                ),
                const SizedBox(height: 15),
                if (languageList.isNotEmpty && fieldTextController.length > 1)
                  // UnitNameField(
                  //   index: 0,
                  //   isReadOnly: fieldFocusNodes[1].isReadOnly,
                  //   onChanged: () {
                  //     isChange = true;
                  //   },
                  //   onSubmitted: (value) => findFocusNext(1),
                  //   focusNode: fieldFocusNodes[1].focusNode,
                  //   controller: fieldTextController[1],
                  //   language: languageList[0],
                  //   isLoadTranslation: isLoadTranslation,
                  //   withIcon: true,
                  //   showAllLanguages: showAllLanguages,
                  //   onIconPressed: () {
                  //     setState(() {
                  //       showAllLanguages = !showAllLanguages;
                  //     });
                  //   },
                  // ),
                  const SizedBox(height: 20),
                if (showAllLanguages)
                  Column(
                    children: List.generate(
                      languageList.length - 1,
                      (index) {
                        // final fieldIndex = index + 2;
                        // if (fieldIndex < fieldTextController.length && (index + 1) < languageList.length) {
                        //   return Padding(
                        //     padding: const EdgeInsets.only(bottom: 20),
                        //     child: UnitNameField(
                        //       index: index + 1,
                        //       isReadOnly: fieldFocusNodes[fieldIndex].isReadOnly,
                        //       onChanged: () {
                        //         isChange = true;
                        //       },
                        //       onSubmitted: (value) => findFocusNext(fieldIndex),
                        //       focusNode: fieldFocusNodes[fieldIndex].focusNode,
                        //       controller: fieldTextController[fieldIndex],
                        //       language: languageList[index + 1],
                        //       isLoadTranslation: isLoadTranslation,
                        //       onIconPressed: () {},
                        //     ),
                        //   );
                        // }
                        return const SizedBox(); // Return an empty widget if index is out of range
                      },
                    ),
                  ),
                if (isSaveAllow)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                      focusNode: FocusNode(skipTraversal: true),
                      onPressed: () {
                        saveOrUpdateData();
                      },
                      icon: const Icon(Icons.save),
                      label: Text(
                        global.language("save") + ((kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) ? " (F10)" : ""),
                      ),
                    ),
                  )
              ],
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
      unitGuidListChecked.clear();
    }
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return BlocListener<UnitBloc, UnitState>(
            listener: (context, state) {
              blocUnitState = state;
              // Load
              if (state is UnitLoadSuccess) {
                setState(() {
                  if (state.units.isNotEmpty) {
                    listData.addAll(state.units);
                  }
                });
              }
              // Save
              if (state is UnitSaveSuccess) {
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
              if (state is UnitSaveFailed) {
                setState(() {
                  global.showSnackBar(
                      context,
                      const Icon(
                        Icons.save,
                        color: Colors.white,
                      ),
                      "${global.language("not_success_save")} : ${state.message}",
                      Colors.red);
                });
              }
              // Update
              if (state is UnitUpdateSuccess) {
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
              if (state is UnitUpdateFailed) {
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
              if (state is UnitDeleteSuccess) {
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
              if (state is UnitDeleteManySuccess) {
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
              if (state is UnitGetSuccess) {
                setState(() {
                  dataTemp = state.unit;

                  getDataToEditScreen(state.unit);

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
                  Offset? positionHeader = boxHeader?.localToGlobal(Offset.zero);
                  RenderBox? box = listKeys[currentListIndex].currentContext?.findRenderObject() as RenderBox?;
                  Offset? position = box?.localToGlobal(Offset.zero);
                  if (position != null && positionHeader != null && boxHeader != null && box != null) {
                    // Scroll Up
                    if (isKeyUp && position.dy <= (positionHeader.dy + (boxHeader.size.height + (box.size.height * 2)))) {
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
                  ),
          );
        },
      ),
    );
  }
}
