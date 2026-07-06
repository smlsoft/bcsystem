import 'dart:io';

import 'package:cocomerchant_lite/bloc/pos_media/pos_media_bloc.dart';
import 'package:cocomerchant_lite/model/pos_media_model.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:split_view/split_view.dart';
import 'package:intl/intl.dart';

class PosMediaScreen extends StatefulWidget {
  const PosMediaScreen({Key? key}) : super(key: key);

  @override
  State<PosMediaScreen> createState() => PosMediaScreenState();
}

class PosMediaScreenState extends State<PosMediaScreen> with SingleTickerProviderStateMixin {
  late TabController tabController;
  ScrollController editScrollController = ScrollController();
  TextEditingController searchController = TextEditingController();
  List<LanguageModel> languageList = <LanguageModel>[];
  List<PosMediaModel> listData = [];
  List<String> guidListChecked = [];
  List<LanguageDataModel> names = [];
  ScrollController listScrollController = ScrollController();
  List<GlobalKey> listKeys = [];
  String searchText = "";
  String selectGuid = "";
  bool isDataChange = false;
  bool isSaveAllow = false;
  late PosMediaState blocCurrentState;
  String headerEdit = "";
  late MediaQueryData queryData;
  int currentListIndex = -1;
  GlobalKey headerKey = GlobalKey();
  bool isKeyUp = false;
  bool isKeyDown = false;
  bool showCheckBox = false;
  bool isEditMode = false;
  late PosMediaModel screenData;
  late SplitViewController splitViewController;
  final debouncer = global.Debouncer(1000);
  bool loadingData = false;
  late DateTime dateNow = DateTime.now();
  final _formKey = GlobalKey<FormState>();
  TextEditingController codeController = TextEditingController();
  List<Uint8List> imageWeb = [];
  List<File> imageFile = [];
  final ImagePicker imagePicker = ImagePicker();
  List<TextEditingController> mediaFromDateController = [];
  List<TextEditingController> mediaToDateController = [];
  List<TextEditingController> mediaFromTimeController = [];
  List<TextEditingController> mediaToTimeController = [];
  List<DayOfWeekModel> dayOfWeekList = [];
  List<List<DayOfWeekModel>> dayOfWeekSeleted = [];
  final List<TimeOfDay> _selectedTime = [];

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
    dayOfWeekList.add(DayOfWeekModel(code: '1', name: global.language('monday')));
    dayOfWeekList.add(DayOfWeekModel(code: '2', name: global.language('tuesday')));
    dayOfWeekList.add(DayOfWeekModel(code: '3', name: global.language('wendesday')));
    dayOfWeekList.add(DayOfWeekModel(code: '4', name: global.language('thursday')));
    dayOfWeekList.add(DayOfWeekModel(code: '5', name: global.language('friday')));
    dayOfWeekList.add(DayOfWeekModel(code: '6', name: global.language('saturday')));
    dayOfWeekList.add(DayOfWeekModel(code: '7', name: global.language('sunday')));

    super.initState();
  }

  @override
  void dispose() {
    listScrollController.dispose();
    tabController.dispose();
    editScrollController.dispose();
    searchController.dispose();

    codeController.dispose();

    super.dispose();
  }

  void loadDataList(String search) {
    setState(() {
      loadingData = true;
    });
    searchText = search;
    context.read<PosMediaBloc>().add(PosMediaLoadList(offset: (listData.isEmpty) ? 0 : listData.length, limit: global.loadDataPerPage, search: search));
  }

  void onScrollList() {
    if (listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange) {
      loadDataList(searchText);
    }
  }

  void clearEditData() {
    listScrollController.addListener(onScrollList);

    screenData = PosMediaModel(
      guidfixed: '',
      code: '',
      description: [],
      resources: [],
    );
    imageFile = [];
    imageWeb = [];
    isDataChange = false;

    dayOfWeekSeleted = [];
    mediaFromDateController = [];
    mediaToDateController = [];
    mediaFromTimeController = [];
    mediaToTimeController = [];

    setState(() {
      loadDataToScreen();
    });
  }

  void loadDataToScreen() {
    codeController.text = screenData.code;

    imageWeb = [];
    imageFile = [];

    for (int i = 0; i < screenData.resources.length; i++) {
      _selectedTime.add(TimeOfDay.now());
      imageWeb.add(Uint8List(0));
      imageFile.add(File(''));
      mediaFromDateController.add(TextEditingController());
      mediaToDateController.add(TextEditingController());
      mediaFromTimeController.add(TextEditingController());
      mediaToTimeController.add(TextEditingController());

      mediaFromDateController[i].text = (screenData.resources[i].fromDate.isNotEmpty) ? DateFormat('dd/MM/yyyy').format(DateTime.parse(screenData.resources[i].fromDate)) : '';
      mediaToDateController[i].text = (screenData.resources[i].toDate.isNotEmpty) ? DateFormat('dd/MM/yyyy').format(DateTime.parse(screenData.resources[i].toDate)) : '';
      mediaFromTimeController[i].text = screenData.resources[i].fromTime;
      mediaToTimeController[i].text = screenData.resources[i].toTime;
      dayOfWeekSeleted.add(screenData.resources[i].daysofweek.map((e) => dayOfWeekList.firstWhere((element) => element.code == e.toString())).toList());
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
    context.read<PosMediaBloc>().add(PosMediaGet(guid: guid));
  }

  void switchToEdit(PosMediaModel value) {
    setState(() {
      selectGuid = value.guidfixed;
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
        title: Text(global.language("pos_media")),
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
                                context.read<PosMediaBloc>().add(PosMediaDeleteMany(guid: guidListChecked));
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
                    child: Text(global.language("pos_media_code"),
                        style: TextStyle(color: global.theme.columnHeaderTextColor, fontWeight: FontWeight.bold, fontSize: global.deviceConfig.listDataFontSize + 2))),
                Expanded(
                    flex: 5,
                    child: Text(
                      global.language("description"),
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

  Widget listObject(int index, PosMediaModel value, bool showCheckBox) {
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
            Expanded(flex: 5, child: Text(value.code, maxLines: 2, overflow: TextOverflow.ellipsis, style: textStyle)),
            Expanded(flex: 5, child: Text(global.packName(value.description), maxLines: 2, overflow: TextOverflow.ellipsis, style: textStyle)),
            if (showCheckBox) Expanded(flex: 1, child: (isCheck) ? Icon(Icons.check, size: global.deviceConfig.listDataFontSize) : Container())
          ],
        ),
      ),
    );
  }

  void saveOrUpdateData() {
    showCheckBox = false;

    for (int i = 0; i < screenData.resources.length; i++) {
      if (mediaFromDateController[i].text.isNotEmpty) {
        DateTime fromDateUtc = DateTime.parse(screenData.resources[i].fromDate);
        screenData.resources[i].fromDate = fromDateUtc.toUtc().toIso8601String();
      }

      if (mediaToDateController[i].text.isNotEmpty) {
        DateTime toDateUtc = DateTime.parse(screenData.resources[i].toDate);
        screenData.resources[i].toDate = toDateUtc.toUtc().toIso8601String();
      }

      screenData.resources[i].daysofweek = [];
      for (var element in dayOfWeekSeleted[i]) {
        screenData.resources[i].daysofweek.add(int.parse(element.code));
      }
    }
    // print(screenData.toJson());

    if (selectGuid.trim().isEmpty) {
      if (imageFile.isNotEmpty) {
        context.read<PosMediaBloc>().add(PosMediaWithImageSave(
              posMedia: screenData,
              imageFile: imageFile,
              imageWeb: imageWeb,
            ));
      } else {
        context.read<PosMediaBloc>().add(PosMediaSave(posMedia: screenData));
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
      if (imageWeb[i].isNotEmpty || screenData.resources[i].uri != '') {
        imageFileUpdate.add(imageFile[i]);
        imageWebUpdate.add(imageWeb[i]);
        imageUris.add(ImagesModel(uri: screenData.resources[i].uri, xorder: i));
      }
    }
    if (imageWebUpdate.isNotEmpty) {
      context.read<PosMediaBloc>().add(PosMediaWithImageUpdate(
            guid: guid,
            posMedia: screenData,
            imageFiles: imageFile,
            imagesUris: imageUris,
            imageWeb: imageWeb,
          ));
    } else {
      screenData.resources = [];
      context.read<PosMediaBloc>().add(PosMediaUpdate(guid: guid, posMedia: screenData));
    }
  }

  void _selectMediaFromDate(BuildContext context, int mediaIndex) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.parse((screenData.resources[mediaIndex].fromDate.isNotEmpty) ? screenData.resources[mediaIndex].fromDate.toString() : dateNow.toIso8601String()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        screenData.resources[mediaIndex].fromDate = pickedDate.toLocal().toIso8601String();

        mediaFromDateController[mediaIndex].text = DateFormat('dd/MM/yyyy').format(DateTime.parse(screenData.resources[mediaIndex].fromDate));
      });
    }
  }

  void _selectMediaToDate(BuildContext context, int mediaIndex) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.parse((screenData.resources[mediaIndex].toDate.isNotEmpty) ? screenData.resources[mediaIndex].toDate.toString() : dateNow.toIso8601String()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        screenData.resources[mediaIndex].toDate = pickedDate.toLocal().toIso8601String();

        mediaToDateController[mediaIndex].text = DateFormat('dd/MM/yyyy').format(DateTime.parse(screenData.resources[mediaIndex].toDate));
      });
    }
  }

  void _selectMediaFromTime(BuildContext context, int mediaIndex) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime[mediaIndex],
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

        screenData.resources[mediaIndex].fromTime = formattedTime;
        mediaFromTimeController[mediaIndex].text = formattedTime;
      });
    }
  }

  void _selectMediaToTime(BuildContext context, int mediaIndex) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime[mediaIndex],
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
        TimeOfDay fromTime = global.getTimeOfDayFromString(screenData.resources[mediaIndex].fromTime);
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
          screenData.resources[mediaIndex].toTime = '';
          mediaToTimeController[mediaIndex].text = '';
          return;
        } else {
          // Update the toTime and the text in the text field
          screenData.resources[mediaIndex].toTime = formattedTime;
          mediaToTimeController[mediaIndex].text = formattedTime;
        }
      });
    }
  }

  String getLangName(String code) {
    LanguageModel name = languageList.firstWhere((element) => element.code == code, orElse: () => LanguageModel(code: '', codeTranslator: '', name: '', isuse: false));
    return name.name!;
  }

  Future<List<DayOfWeekModel>> getDataDayOfWeek(filter) async {
    return dayOfWeekList;
  }

  Widget editScreen({mobileScreen}) {
    List<Widget> formWidgets = [];

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: TextFormField(
          readOnly: !isEditMode,
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
            labelText: global.language("pos_media_code"),
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

    formWidgets.addAll(
      listNamesFields(
        screenData.description,
        "description",
      ),
    );

    formWidgets.add((screenData.resources.isNotEmpty)
        ? Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
            child: Text(global.language("pos_media")),
          )
        : Container());

    List<Widget> mediaList = [];
    for (int mediaIndex = 0; mediaIndex < screenData.resources.length; mediaIndex++) {
      mediaList.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Row(
                  children: [
                    (isEditMode)
                        ? Expanded(
                            child: IconButton(
                            focusNode: FocusNode(skipTraversal: true),
                            onPressed: () async {
                              screenData.resources.removeAt(mediaIndex);
                              imageWeb.removeAt(mediaIndex);
                              imageFile.removeAt(mediaIndex);

                              mediaFromDateController.removeAt(mediaIndex);
                              mediaToDateController.removeAt(mediaIndex);
                              mediaFromTimeController.removeAt(mediaIndex);
                              mediaToTimeController.removeAt(mediaIndex);
                              dayOfWeekSeleted.removeAt(mediaIndex);

                              setState(() {});
                            },
                            icon: const Icon(
                              Icons.delete,
                            ),
                          ))
                        : Container(),
                    const SizedBox(height: 5),
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
                                        imageWeb[mediaIndex] = f;
                                        imageFile[mediaIndex] = File(image.path);
                                        FocusScope.of(context).unfocus();
                                      });
                                    }
                                  }
                                : () async {
                                    final XFile? photo = await imagePicker.pickImage(source: ImageSource.camera, maxHeight: 480, maxWidth: 640, imageQuality: 60);
                                    if (photo != null) {
                                      var f = await photo.readAsBytes();
                                      imageWeb[mediaIndex] = f;
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
                            imageWeb[mediaIndex] = f;
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
                    height: 350,
                    child: Stack(children: [
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
                          image: (imageWeb[mediaIndex].isNotEmpty)
                              ? DecorationImage(image: MemoryImage(imageWeb[mediaIndex]), fit: BoxFit.fill)
                              : (screenData.resources[mediaIndex].uri != '')
                                  ? DecorationImage(image: NetworkImage(screenData.resources[mediaIndex].uri), fit: BoxFit.fill)
                                  : const DecorationImage(image: AssetImage('assets/img/noimg.png'), fit: BoxFit.fill),
                        ),
                        child: const SizedBox(
                          width: 500,
                          height: 500,
                        ),
                      )),
                    ])),
              ],
            ),
            const SizedBox(height: 20),

            /// widget form
            Column(
              children: [
                /// description
                Column(
                  children: listNamesFields(
                    screenData.resources[mediaIndex].description,
                    "description",
                  ),
                ),

                /// fromdate todate
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          decoration: InputDecoration(
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              border: const OutlineInputBorder(),
                              labelText: global.language("from_date"),
                              suffixIcon: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    focusNode: FocusNode(skipTraversal: true),
                                    icon: const Icon(Icons.calendar_today),
                                    onPressed: () {
                                      _selectMediaFromDate(context, mediaIndex);
                                    },
                                  ),
                                ],
                              )),
                          controller: mediaFromDateController[mediaIndex],
                          onChanged: (value) {
                            setState(() {
                              try {
                                List<String> valueSplit = value.replaceAll(".", "/").split("/");
                                if (valueSplit.length == 3) {
                                  if (valueSplit[2].length == 2) {
                                    valueSplit[2] = '25${valueSplit[2]}';
                                  }
                                  int year = int.tryParse(valueSplit[2]) ?? 0;
                                  year = year - 543;
                                  int month = int.tryParse(valueSplit[1]) ?? 0;
                                  int day = int.tryParse(valueSplit[0]) ?? 0;
                                  value = "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
                                }

                                if (global.isValidDate(value)) {
                                  screenData.resources[mediaIndex].fromDate = DateTime.parse(value).toLocal().toIso8601String();
                                }
                              } catch (e) {
                                // print(e);
                              }
                            });
                          },
                          onSubmitted: (value) => {
                            mediaFromDateController[mediaIndex].text = DateFormat('dd/MM/yyyy').format(
                              DateTime.parse(
                                screenData.resources[mediaIndex].fromDate.toString(),
                              ),
                            ),
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: TextField(
                          readOnly: true,
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: const OutlineInputBorder(),
                            labelText: global.language("to_date"),
                            suffixIcon: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  focusNode: FocusNode(skipTraversal: true),
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: () {
                                    _selectMediaToDate(context, mediaIndex);
                                  },
                                ),
                              ],
                            ),
                          ),
                          controller: mediaToDateController[mediaIndex],
                          onChanged: (value) {
                            setState(() {
                              try {
                                List<String> valueSplit = value.replaceAll(".", "/").split("/");
                                if (valueSplit.length == 3) {
                                  if (valueSplit[2].length == 2) {
                                    valueSplit[2] = '25${valueSplit[2]}';
                                  }
                                  int year = int.tryParse(valueSplit[2]) ?? 0;
                                  year = year - 543;
                                  int month = int.tryParse(valueSplit[1]) ?? 0;
                                  int day = int.tryParse(valueSplit[0]) ?? 0;
                                  value = "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
                                }

                                if (global.isValidDate(value)) {
                                  screenData.resources[mediaIndex].toDate = DateTime.parse(value).toLocal().toIso8601String();
                                }
                              } catch (e) {
                                // print(e);
                              }
                            });
                          },
                          onSubmitted: (value) => {
                            mediaToDateController[mediaIndex].text = DateFormat('dd/MM/yyyy').format(
                              DateTime.parse(
                                screenData.resources[mediaIndex].toDate.toString(),
                              ),
                            ),
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                /// fromtime totime
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: mediaFromTimeController[mediaIndex],
                          onTap: () async {
                            _selectMediaFromTime(context, mediaIndex);
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
                                    _selectMediaFromTime(context, mediaIndex);
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
                          controller: mediaToTimeController[mediaIndex],
                          onTap: () async {
                            _selectMediaToTime(context, mediaIndex);
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
                                    _selectMediaToTime(context, mediaIndex);
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
                    ],
                  ),
                ),

                /// displaytime
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                    controller: TextEditingController(text: screenData.resources[mediaIndex].displaytime.toString()),
                    onChanged: (value) {
                      isDataChange = true;
                      screenData.resources[mediaIndex].displaytime = int.parse(value);
                    },
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      border: const OutlineInputBorder(),
                      labelText: global.language("display_time"),
                    ),
                  ),
                ),

                /// dayofweek checkbox
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
                  child: DropdownSearch<DayOfWeekModel>.multiSelection(
                    enabled: isEditMode,
                    asyncItems: (String filter) => getDataDayOfWeek(filter),
                    compareFn: (item, selectedItem) => item.code == selectedItem.code,
                    itemAsString: (DayOfWeekModel? group) {
                      if (group == null) return '';
                      return '${group.code} - ${group.name}';
                    },
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.only(left: 10, top: 15, bottom: 10, right: 10),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: global.language("day_of_week"),
                      ),
                    ),
                    onChanged: (List<DayOfWeekModel> value) {
                      setState(() {
                        dayOfWeekSeleted[mediaIndex] = value;
                      });
                    },
                    popupProps: const PopupPropsMultiSelection.dialog(
                      showSearchBox: false,
                      showSelectedItems: true,
                    ),
                    selectedItems: dayOfWeekSeleted[mediaIndex],
                  ),
                ),
              ],
            ),
          ],
        ),
      ));
    }

    formWidgets.add(Column(
      children: mediaList,
    ));

    if (isSaveAllow) {
      formWidgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: ElevatedButton.icon(
            focusNode: FocusNode(skipTraversal: true),
            onPressed: () {
              screenData.resources.add(ResourceModel(
                daysofweek: [],
                description: [],
                displaytime: 5,
                fromDate: '',
                fromTime: '',
                mediaType: 0,
                toDate: '',
                toTime: '',
                uri: '',
              ));

              mediaFromDateController.add(TextEditingController());
              mediaToDateController.add(TextEditingController());
              mediaFromTimeController.add(TextEditingController());
              mediaToTimeController.add(TextEditingController());
              _selectedTime.add(TimeOfDay.now());

              dayOfWeekSeleted.add([
                dayOfWeekList[0],
                dayOfWeekList[1],
                dayOfWeekList[2],
                dayOfWeekList[3],
                dayOfWeekList[4],
                dayOfWeekList[5],
                dayOfWeekList[6],
              ]);

              setState(() {
                imageWeb.add(Uint8List(0));
                imageFile.add(File(''));
                FocusScope.of(context).unfocus();
              });
            },
            icon: const Icon(Icons.add),
            label: Text(global.language("add_media"))),
      ));

      formWidgets.add(Container(
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
            title: Text(headerEdit + global.language("pos_media")),
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
                                    context.read<PosMediaBloc>().add(PosMediaDelete(guid: selectGuid));
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
              BlocListener<PosMediaBloc, PosMediaState>(
                listener: (context, state) {
                  blocCurrentState = state;
                  // Load
                  if (state is PosMediaLoadSuccess) {
                    setState(() {
                      loadingData = false;
                      if (state.posMedias.isNotEmpty) {
                        listData.addAll(state.posMedias);
                      }
                    });
                  }
                  if (state is PosMediaLoadFailed) {
                    setState(() {
                      loadingData = false;
                    });
                  }
                  // Save
                  if (state is PosMediaSaveSuccess) {
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
                  if (state is PosMediaSaveFailed) {
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
                  if (state is PosMediaUpdateSuccess) {
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
                  if (state is PosMediaUpdateFailed) {
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
                  if (state is PosMediaDeleteSuccess) {
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
                  if (state is PosMediaDeleteManySuccess) {
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
                  if (state is PosMediaGetSuccess) {
                    setState(() {
                      isDataChange = false;
                      screenData = state.posMedia;

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
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          child: TextFormField(
            readOnly: !isEditMode,
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
    }

    return forms;
  }
}

// Create an input widget that takes only one digit
class OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final bool autoFocus;
  const OtpInput(this.controller, this.autoFocus, {Key? key}) : super(key: key);

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
