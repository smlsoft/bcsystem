import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cocomerchant_lite/bloc/business_type/business_type_bloc.dart';
import 'package:cocomerchant_lite/bloc/company_branch/company_branch_bloc.dart';
import 'package:cocomerchant_lite/bloc/creditor/creditor_bloc.dart';
import 'package:cocomerchant_lite/bloc/image/image_upload_bloc.dart';
import 'package:cocomerchant_lite/bloc/product_dimension/product_dimension_bloc.dart';
import 'package:cocomerchant_lite/bloc/unit/unit_bloc.dart';
import 'package:cocomerchant_lite/model/business_type_model.dart';
import 'package:cocomerchant_lite/model/company_branch_model.dart';
import 'package:cocomerchant_lite/model/dimension_model.dart';
import 'package:cocomerchant_lite/model/order_type_model.dart';
import 'package:cocomerchant_lite/model/product_bom_model.dart';
import 'package:cocomerchant_lite/model/product_group_model.dart';
import 'package:cocomerchant_lite/model/product_type_model.dart';
import 'package:cocomerchant_lite/repositories/product_group_repository.dart';
import 'package:cocomerchant_lite/repositories/unit_repository.dart';
import 'package:cocomerchant_lite/screen_search/barcode_search_screen.dart';
import 'package:cocomerchant_lite/screen_search/dimension_search_screen.dart';
import 'package:cocomerchant_lite/screen_search/order_type_search_screen.dart';
import 'package:cocomerchant_lite/screen_search/product_group_search_screen.dart';
import 'package:cocomerchant_lite/screen_search/product_search_screen.dart';
import 'package:cocomerchant_lite/screens/config/product_bom_widget.dart';
import 'package:cocomerchant_lite/utils/image_tooltip.dart';
import 'package:cocomerchant_lite/utils/util.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cocomerchant_lite/bloc/product_barcode/product_barcode_bloc.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/model/price_model.dart';
import 'package:cocomerchant_lite/model/product_model.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:split_view/split_view.dart';
import 'package:cocomerchant_lite/screen_search/unit_search_screen.dart';
import 'package:translator/translator.dart';
import 'package:uuid/uuid.dart';

class ProductBarcodeScreen extends StatefulWidget {
  const ProductBarcodeScreen({super.key});

  @override
  State<ProductBarcodeScreen> createState() => ProductBarcodeScreenState();
}

class ProductBarcodeScreenState extends State<ProductBarcodeScreen> with SingleTickerProviderStateMixin {
  final translator = GoogleTranslator();
  List<GlobalKey<ImageTooltipState>> tooltipKeys = [];
  late TabController tabController;
  ScrollController editScrollController = ScrollController();
  bool refreshFocus = false;
  TextEditingController searchController = TextEditingController();
  TextEditingController groupController = TextEditingController();
  int focusNodeMax = 0;
  FocusNode searchFocusNode = FocusNode(skipTraversal: true);
  List<LanguageModel> languageList = <LanguageModel>[];
  List<PriceModel> priceList = <PriceModel>[];
  List<global.FieldFocusModel> fieldFocusNodes = [];
  int focusNodeIndex = 0;
  List<ProductBarcodeModel> listData = [];
  List<String> guidListChecked = [];
  int currentBarcodeNode = -1;
  int bomCurrentBarcodeNode = -1;
  String textDescription = "";
  List<LanguageDataModel> names = [];
  ScrollController listScrollController = ScrollController();
  List<GlobalKey> listKeys = [];
  String searchText = "";
  String selectGuid = "";
  bool isDataChange = false;
  bool isSaveAllow = false;
  late ProductBarcodeState blocCurrentState;
  String headerEdit = "";
  late MediaQueryData queryData;
  int currentListIndex = -1;
  GlobalKey headerKey = GlobalKey();
  bool isKeyUp = false;
  bool isKeyDown = false;
  bool showCheckBox = false;
  bool isEditMode = false;

  TextEditingController alertDescriptionTextEditController = TextEditingController();
  TextEditingController descriptionTextEditController = TextEditingController();
  late ProductBarcodeModel screenData;
  File imageFile = File('');
  Uint8List? imageWeb;
  final ImagePicker imagePicker = ImagePicker();
  late DropzoneViewController dropZoneController;
  Color colorSelected = Colors.white;
  final _debouncer = global.Debouncer(500);
  List<UnitModel> unitListData = [];
  // late Timer screenTimer;
  bool loadingData = false;
  bool showImage = false;
  bool useReferenceBarcode = false;
  bool isPreview = true;
  bool isPreviewBom = false;

  TextEditingController barcodeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  List<File> imageFileChoice = [File('')];
  List<Uint8List> imageWebChoice = [Uint8List(0)];
  int uploadImageOptionIndex = -1;
  int uploadImageChoiceIndex = -1;

  List<DimensionModel> dimensionSeleted = [];

  LanguageModel languangeExport = global.config.languages[0];
  bool isLoadTranslation = false;
  final _popupBuilderBranchKey = GlobalKey<DropdownSearchState<String>>();
  final _popupBuilderBusinessKey = GlobalKey<DropdownSearchState<String>>();
  List<BusinessTypeModel> listDataBusinessType = [];
  List<BranchModel> listDataBranchBusinessType = [];
  FiltterBarcodeModel filterBarcode = FiltterBarcodeModel(branch: false);
  List<CompanyBranchModel> listDataBranchAll = [];
  List<BranchModel>? ignorebranches = [];

  ProductBomModel productBom = ProductBomModel(
    guidfixed: '',
    names: [],
    itemunitcode: '',
    itemunitnames: [],
    barcode: '',
    condition: false,
    dividevalue: 0,
    standvalue: 0,
    qty: 0,
    imageuri: '',
    bom: [],
  );

  void setSystemLanguageList() async {
    await global.setSystemLanguage(context);

    for (int i = 0; i < global.config.languages.length; i++) {
      if (global.config.languages[i].isuse!) {
        languageList.add(global.config.languages[i]);
      }
    }

    for (int i = 0; i < global.config.prices.length; i++) {
      if (global.config.prices[i].isUse) {
        priceList.add(global.config.prices[i]);
      }
    }

    clearEditData();
    listData = [];
    loadDataList("", filterBarcode);
    loadUnit();
    loadBranchAll();
  }

  @override
  void initState() {
    loadDataBusinessTypesList();
    clearEditData();
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
    listScrollController.addListener(onScrollList);

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
    // screenTimer.cancel();
    removeTooltip();
    for (int i = 0; i < tooltipKeys.length; i++) {
      tooltipKeys[i].currentState?.dispose();
    }
    super.dispose();
  }

  void removeTooltip() {
    for (int i = 0; i < tooltipKeys.length; i++) {
      tooltipKeys[i].currentState?.removeTooltip();
    }
  }

  void loadDataList(String search, FiltterBarcodeModel filterBarcode) {
    setState(() {
      loadingData = true;
    });
    searchText = search;
    context.read<ProductBarcodeBloc>().add(ProductBarcodeLoadList(
          offset: (listData.isEmpty) ? 0 : listData.length,
          limit: global.loadDataPerPage,
          search: search,
          branchcode: (filterBarcode.branch == true) ? global.companyBranchSelectData.code : "",
          businesstypecode: (filterBarcode.branch == true) ? global.companyBranchSelectData.businesstype!.code! : "",
        ));
  }

  void loadUnit() {
    context.read<UnitBloc>().add(const UnitLoadList(offset: 0, limit: 2000, search: ""));
  }

  void loadBranchAll() {
    listDataBranchAll = [];
    context.read<CompanyBranchBloc>().add(const CompanyBranchLoadList(offset: 0, limit: 100, search: ""));
  }

  void onScrollList() {
    if (listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange) {
      /// set delay 500 ms
      _debouncer.run(() {
        loadDataList(searchText, filterBarcode);
      });
    }
  }

  String getLangName(String code) {
    LanguageModel name = languageList.firstWhere((element) => element.code == code, orElse: () => LanguageModel(code: '', codeTranslator: '', name: '', isuse: false));
    return name.name!;
  }

  List<LanguageDataModel> getUnitName(String data) {
    if (unitListData.isNotEmpty && data != '') {
      List<LanguageDataModel> res = [];
      for (var ele in unitListData) {
        if (ele.unitcode == data) {
          res = ele.names!;
        }
      }
      return res;
    } else {
      return [];
    }
  }

  void clearEditData() {
    List<LanguageDataModel> names = [];
    List<LanguageDataModel> itemunitnames = [];
    for (int k = 0; k < languageList.length; k++) {
      names.add(LanguageDataModel(code: languageList[k].code!, name: ""));
      itemunitnames.add(LanguageDataModel(code: languageList[k].code!, name: ""));
    }
    List<PriceDataModel> prices = [];
    for (int i = 0; i < priceList.length; i++) {
      prices.add(PriceDataModel(
        keynumber: priceList[i].keyNumber,
        price: 0,
      ));
    }

    barcodeController.text = "";
    alertDescriptionTextEditController.text = "";
    descriptionTextEditController.text = "";
    screenData = ProductBarcodeModel(
      barcode: "",
      guidfixed: "",
      groupcode: "",
      groupnames: [],
      names: names,
      itemcode: "",
      itemunitcode: "",
      itemunitnames: itemunitnames,
      prices: prices,
      imageuri: "",
      useimageorcolor: true,
      colorselect: "",
      colorselecthex: "",
      options: [],
      dividevalue: 1,
      standvalue: 1,
      refbarcode: null,
      isalacarte: true,
      isdiscountpointofpurchase: true,
      restaurant: ProductBarcodeRestaurantModel(),
      issplitunitprint: true,
      isonlystaff: false,
      ordertypes: [],
      producttype: ProductTypeModel(
        guidfixed: "",
        code: "",
        names: [],
      ),
      businesstypes: [
        BusinessTypeModel(
          guidfixed: global.companyBranchSelectData.businesstype!.guidfixed,
          code: global.companyBranchSelectData.businesstype!.code!,
          names: global.companyBranchSelectData.businesstype!.names!,
        )
      ],
      ignorebranches: [
        // BranchModel(
        //   guidfixed: global.companyBranchSelectData.guidfixed,
        //   code: global.companyBranchSelectData.code,
        //   names: global.companyBranchSelectData.names,
        // )
      ],
      foodtype: 0,
      isstockforrestaurant: false,
      discount: "",
      manufacturerguid: "",
      manufacturer: SearchGuidCodeNameModel(
        code: "",
        names: [],
        guid: '',
      ),
      isalert: false,
      alertdescription: "",
      description: "",
    );

    isDataChange = false;
    focusNodeIndex = 0;
    refreshFocus = true;

    uploadImageOptionIndex = -1;
    uploadImageChoiceIndex = -1;
    imageFileChoice = [File('')];
    imageWebChoice = [Uint8List(0)];

    setState(() {
      imageFile = File('');
      imageWeb = null;
    });

    loadDataBranchList(screenData.businesstypes!);
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
    imageWeb = null;
    imageFile = File('');
    context.read<ProductBarcodeBloc>().add(ProductBarcodeGet(guid: guid));
  }

  void upLoadImageChoice() {
    if (imageFileChoice.isNotEmpty) {
      if (imageFileChoice[0].path != '') {
        context.read<ImageUploadBloc>().add(ImageUploadFileSaved(imageFiles: imageFileChoice, imageWeb: imageWebChoice));
      }
    }
  }

  Widget listScreen({bool mobileScreen = false}) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: global.theme.appBarColor,
        automaticallyImplyLeading: false,
        title: Text(global.language('barcode')),
        leading: IconButton(
          focusNode: FocusNode(skipTraversal: true),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            discardData(callBack: () {
              Navigator.pushReplacementNamed(context, '/menu');
              isEditMode = false;
            });
          },
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: IconButton(
              onPressed: () {
                discardData(callBack: () {
                  Navigator.pushReplacementNamed(context, '/importproduct');
                });
              },
              icon: const Icon(
                Icons.upload,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: IconButton(
              onPressed: () {
                /// dialog select language code
                showDialog<String>(
                  context: context,
                  builder: (BuildContext context) {
                    // Initialize the selected language outside of StatefulBuilder
                    LanguageModel? selectedLanguage = global.config.languages[0];

                    return AlertDialog(
                      title: Text(global.language('select_language')),
                      content: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return InputDecorator(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<LanguageModel>(
                                value: selectedLanguage,
                                icon: const Icon(Icons.arrow_drop_down),
                                style: const TextStyle(color: Colors.deepPurple),
                                underline: Container(
                                  color: Colors.deepPurpleAccent,
                                ),
                                onChanged: (LanguageModel? value) {
                                  setState(() {
                                    selectedLanguage = value!;
                                  });
                                },
                                isDense: true,
                                isExpanded: true,
                                items: global.config.languages.map<DropdownMenuItem<LanguageModel>>((LanguageModel value) {
                                  return DropdownMenuItem<LanguageModel>(
                                    value: value,
                                    child: Row(
                                      children: <Widget>[
                                        Image.asset(
                                          'assets/flags/${value.code}.png', // Ensure the image path is correct
                                          width: 30,
                                          height: 30,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(Icons.error); // Error icon if the image fails to load
                                          },
                                        ),
                                        const SizedBox(width: 10), // Spacing between the image and text
                                        Text(value.name!),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                      actions: <Widget>[
                        // Text button cancel
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(global.language('cancel')),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(
                Icons.download,
              ),
            ),
          ),
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
            ),
          ),
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
                                context.read<ProductBarcodeBloc>().add(ProductBarcodeDeleteMany(guid: guidListChecked));
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
                      isPreview = false;
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

          /// เพิ่มมูลใหม่จากข้อมูลเดิม (Copy)
          // if (selectGuid.isNotEmpty)
          //   Padding(
          //       padding: const EdgeInsets.only(right: 20.0),
          //       child: IconButton(
          //         focusNode: FocusNode(skipTraversal: true),
          //         onPressed: () {
          //           discardData(callBack: () {
          //             setState(() {
          //               isEditMode = true;
          //               showCheckBox = false;
          //               isChange = false;
          //               isChange = false;
          //               headerEdit = global.language("append");
          //               isSaveAllow = true;
          //               if (mobileScreen) {
          //                 WidgetsBinding.instance
          //                     .addPostFrameCallback((timeStamp) {
          //                   tabController.animateTo(1);
          //                 });
          //               }
          //               fieldFocusNodes[0].requestFocus();
          //             });
          //           });
          //         },
          //         icon: const Icon(
          //           Icons.copy_all,
          //         ),
          //       )),
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
                    onSubmitted: (value) {
                      searchFocusNode.requestFocus();
                    },
                    onChanged: (value) {
                      _debouncer.run(() {
                        setState(() {
                          listData = [];
                        });
                        loadDataList(value, filterBarcode);
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
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    filterBarcode = await filterBox(filterBarcode);

                    setState(() {
                      listData = [];
                      loadDataList(searchText, filterBarcode);
                    });
                  },
                  icon: Icon(
                    (filterBarcode.branch == false) ? Icons.filter_alt_off : Icons.filter_alt,
                    color: (filterBarcode.branch == false) ? Colors.black : Colors.blue,
                  ),
                ),
                IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    icon: Icon((showImage) ? Icons.image_not_supported : Icons.image),
                    onPressed: () async {
                      setState(() {
                        showImage = !showImage;
                      });
                    }),
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
                Expanded(flex: 6, child: Text(global.language("barcode"), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 10,
                    child: Text(
                      global.language("product_name"),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )),
                Expanded(flex: 2, child: Text(global.language("unit"), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text(global.language("item_code"), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                Expanded(flex: 4, child: Text(global.language("product_group"), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                if (showImage) const Expanded(flex: 1, child: Icon(Icons.image, color: Colors.black, size: 12)),
                if (showCheckBox) const Expanded(flex: 1, child: Icon(Icons.check, color: Colors.black, size: 12))
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

  Future<FiltterBarcodeModel> filterBox(FiltterBarcodeModel filterBarcode) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(global.language("filter_product")),
              content: SizedBox(
                width: 600.0,
                height: 600.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    RadioListTile(
                      title: Text(global.language("branch_selected")),
                      value: true,
                      groupValue: filterBarcode.branch,
                      onChanged: (value) {
                        setState(() {
                          filterBarcode.branch = value!;
                        });
                      },
                    ),
                    RadioListTile(
                      title: Text(global.language("all")),
                      value: false,
                      groupValue: filterBarcode.branch,
                      onChanged: (value) {
                        setState(() {
                          filterBarcode.branch = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(global.language("confirm")),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(global.language("clear")),
                ),
              ],
            );
          },
        );
      },
    );

    return filterBarcode;
  }

  void switchToEdit(ProductBarcodeModel value) {
    setState(() {
      selectGuid = value.guidfixed;
      getData(selectGuid);
      headerEdit = global.language("edit");
      isSaveAllow = true;
      isEditMode = true;
      isPreview = false;
    });
  }

  void optionSearch() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const BarcodeSearchScreen(word: "", screen: ""))).then((value) {
      if (value != null) {
        setState(() {
          ProductBarcodeModel result = value;
          if (result.guidfixed.isNotEmpty) {
            screenData.options!.clear();
            if (result.options!.isNotEmpty) {
              screenData.options = result.options!;
            } else {
              screenData.options!.add(ProductOptionModel(guid: const Uuid().v4(), choicetype: 0, minselect: 1, maxselect: 1, names: names, choices: []));
            }
          }
        });
      }
    });
  }

  void barcodeSearch(String word, int optionIndex, int choiceIndex) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => BarcodeSearchScreen(
                  word: word,
                  screen: "",
                ))).then((value) {
      if (value != null) {
        setState(() {
          ProductBarcodeModel result = value;
          if (result.guidfixed.isNotEmpty) {
            screenData.options![optionIndex].choices[choiceIndex].refproductcode = result.itemcode!;
            screenData.options![optionIndex].choices[choiceIndex].refbarcode = result.barcode!;
            screenData.options![optionIndex].choices[choiceIndex].refbarcodenames = result.names!;
            screenData.options![optionIndex].choices[choiceIndex].refunitcode = result.itemunitcode!;
            screenData.options![optionIndex].choices[choiceIndex].refunitnames = result.itemunitnames!;
            screenData.options![optionIndex].choices[choiceIndex].vatcal = result.vatcal;
          }
        });
      }
    });
  }

  void orderTypeSearch(int orderTypeIndex) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderTypeSearchScreen(word: ''))).then((value) {
      if (value != null) {
        setState(() {
          OrderTypeModel result = value;
          if (result.code.isNotEmpty) {
            screenData.ordertypes![orderTypeIndex].guidfixed = result.guidfixed!;
            screenData.ordertypes![orderTypeIndex].code = result.code;
            screenData.ordertypes![orderTypeIndex].names = result.names;
          }
        });
      }
    });
  }

  void dimensionSearch(int dimensionIndex) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const DimensionSearchScreen(word: ''))).then((value) {
      if (value != null) {
        setState(() {
          /// print log json result
          if (kDebugMode) {
            print(jsonEncode(value.toJson()));
          }

          DimensionModel result = value;
          if (result.guidfixed!.isNotEmpty) {
            screenData.dimensions![dimensionIndex].guidfixed = result.guidfixed!;
            screenData.dimensions![dimensionIndex].names = result.names;
            screenData.dimensions![dimensionIndex].isdisabled = result.isdisabled;

            dimensionSeleted[dimensionIndex] = result;
          }
        });
      }
    });
  }

  Future<ProductBarcodeModel> subbarcodeSearch() async {
    ProductBarcodeModel res = ProductBarcodeModel(guidfixed: '', itemcode: '');
    res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const BarcodeSearchScreen(word: '', screen: '')));
    return res;
  }

  void productSearch(String word, int optionIndex, int choiceIndex) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProductSearchScreen(word: word))).then((value) {
      if (value != null) {
        setState(() {
          ProductModel result = value;
          if (result.guidfixed.isNotEmpty) {
            screenData.options![optionIndex].choices[choiceIndex].refproductcode = result.itemcode;
          }
        });
      }
    });
  }

  void loadDataBusinessTypesList() {
    context.read<BusinessTypeBloc>().add(const BusinessTypeLoadList(offset: 0, limit: 1000, search: ""));
  }

  Future<List<BusinessTypeModel>> getDataBusiness(filter) async {
    return listDataBusinessType;
  }

  void loadDataBranchList(List<BusinessTypeModel> businessType) {
    listDataBranchBusinessType = [];

    // Extract the 'code' value from each element and concatenate them
    String businesstypecode = businessType.map((item) => item.code).join(',');

    if (businesstypecode.isNotEmpty) {
      context.read<CompanyBranchBloc>().add(CompanyBranchByBusinessTypeLoadList(offset: 0, limit: 1000, search: "", businesstypecode: businesstypecode));
    }
  }

  Future<List<BranchModel>> getDataBranch(filter) async {
    return listDataBranchBusinessType;
  }

  Widget listObject(int index, ProductBarcodeModel value, bool showCheckBox) {
    bool isCheck = false;
    TextStyle textStyle = (selectGuid == value.guidfixed)
        ? TextStyle(fontSize: global.deviceConfig.listDataFontSize, fontWeight: FontWeight.bold)
        : TextStyle(fontSize: global.deviceConfig.listDataFontSize);
    if (showCheckBox) {
      for (int i = 0; i < guidListChecked.length; i++) {
        if (guidListChecked[i] == value.guidfixed) {
          isCheck = true;
          break;
        }
      }
    }
    listKeys.add(GlobalKey());
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
          isPreview = false;
          switchToEdit(value);
        }
      },
      child: Container(
        key: listKeys.last,
        color: _getContainerColor(selectGuid, value.guidfixed, index),
        padding: EdgeInsets.only(
          left: 10,
          right: 10,
          top: global.deviceConfig.listDataLineSpace,
          bottom: global.deviceConfig.listDataLineSpace,
        ),
        child: Column(
          children: [
            _buildRow(value, textStyle, showImage, tooltipKeys[index], showCheckBox, isCheck),
            (filterBarcode.branch == false)
                ? SizedBox(
                    width: double.infinity,
                    child: _buildChipWrap(value.branches!),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  Color? _getContainerColor(String selectGuid, String guidfixed, int index) {
    return (selectGuid == guidfixed)
        ? Colors.cyan[100]
        : (index % 2 == 0)
            ? global.theme.columnAlternateEvenColor
            : global.theme.columnAlternateOddColor;
  }

  Row _buildRow(ProductBarcodeModel value, TextStyle textStyle, bool showImage, GlobalKey<ImageTooltipState> key, bool showCheckBox, bool isCheck) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: Text(value.barcode!, style: textStyle, maxLines: 2, overflow: TextOverflow.ellipsis)),
        Expanded(
          flex: 10,
          child: Text(
            global.packName(value.names!),
            style: textStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(flex: 2, child: Text(global.packName(value.itemunitnames!), style: textStyle, maxLines: 2, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 4, child: Text(value.itemcode!, style: textStyle, maxLines: 2, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 4, child: Text(global.packName(value.groupnames!), style: textStyle, maxLines: 2, overflow: TextOverflow.ellipsis)),
        if (showImage) _buildImageWidget(value, key),
        if (showCheckBox) Expanded(flex: 1, child: (isCheck) ? const Icon(Icons.check, size: 12) : Container())
      ],
    );
  }

  Widget _buildImageWidget(ProductBarcodeModel value, GlobalKey<ImageTooltipState> key) {
    return Expanded(
      flex: 1,
      child: (value.imageuri!.isNotEmpty || 1 == 1) // Consider revising this condition
          ? ImageTooltip(
              key: key,
              image: Image.network(value.imageuri!),
              child: _buildImageContainer(value.imageuri!),
            )
          : Container(),
    );
  }

  Container _buildImageContainer(String imageUri) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: Colors.grey,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 1,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Image.network(
          imageUri,
          fit: BoxFit.fitHeight,
          height: 20,
          errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
            return const Icon(Icons.image_not_supported);
          },
        ),
      ),
    );
  }

  Wrap _buildChipWrap(List<CompanyBranchModel> branches) {
    return Wrap(
      spacing: 2.0,
      runSpacing: 2.0,
      children: branches.asMap().entries.map((entry) => _buildChip(entry.value)).toList(),
    );
  }

  Chip _buildChip(CompanyBranchModel branch) {
    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.all(0),
      label: Text(
        '${branch.code} - ${global.activeLangName(branch.names)}',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  void saveOrUpdateData() {
    if (screenData.itemtype != 2) {
      for (var element in screenData.refbarcodes!) {
        if (!element.condition) {
          element.standvalue = element.qty;
          element.dividevalue = 1;
          element.qty = 1;
        } else {
          element.standvalue = 1;
          element.dividevalue = element.qty;
          element.qty = 1;
        }
      }
    }

    /// fillter data company branch in listDataBranchBusinessType where screenData.ignorebranches ! = listDataBranchBusinessType
    /// ค้นหา สาขา ที่ไม่ตรงกับ ui ที่เลือกเพื่อส่งค่าไป ignore
    List<BranchModel> listDataBranchBusinessTypeFilter = [];
    for (var element in listDataBranchBusinessType) {
      bool isFound = false;
      for (var ignoreBranch in ignorebranches!) {
        if (element.guidfixed == ignoreBranch.guidfixed) {
          isFound = true;
          break;
        }
      }
      if (!isFound) {
        listDataBranchBusinessTypeFilter.add(element);
      }
    }

    screenData.ignorebranches = listDataBranchBusinessTypeFilter;

    if (kDebugMode) {
      print(jsonEncode(screenData.toJson()));
    }

    if (descriptionTextEditController.text.isNotEmpty) {
      screenData.description = descriptionTextEditController.text;
    }

    if (alertDescriptionTextEditController.text.isNotEmpty) {
      screenData.alertdescription = alertDescriptionTextEditController.text;
    }

    showCheckBox = false;
    if (selectGuid.trim().isEmpty) {
      if (imageFile.path.isNotEmpty) {
        context.read<ProductBarcodeBloc>().add(ProductBarcodeWithImageSave(
              productBarcode: screenData,
              imageFile: imageFile,
              imageWeb: imageWeb,
            ));
      } else {
        context.read<ProductBarcodeBloc>().add(ProductBarcodeSave(productBarcode: screenData));
      }
    } else {
      updateData(selectGuid);
    }
  }

  void updateData(String guid) {
    showCheckBox = false;
    if (imageWeb != null) {
      context.read<ProductBarcodeBloc>().add(ProductBarcodeWithImageUpdate(
            guid: guid,
            productBarcode: screenData,
            imageFile: imageFile,
            imageWeb: imageWeb!,
          ));
    } else {
      context.read<ProductBarcodeBloc>().add(ProductBarcodeUpdate(guid: guid, productBarcode: screenData));
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

  void searchUnit({required String word, required Function callBack}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => UnitSearchScreen(
                  word: word,
                ))).then((value) {
      global.SearchCodeNameModel result = value;

      if (result.code.trim().isNotEmpty) {
        callBack(true, result.code, result.names);
      }
      if (result.isCancel == false) findFocusNext(focusNodeIndex);
    });
  }

  void setFocusNode(FocusNode focus) {
    focus.unfocus();
    Future.delayed(const Duration(milliseconds: 500), () {
      focus.requestFocus();
    });
  }

  Future<void> translateNames() async {
    for (var name in screenData.names!) {
      if (name.name.isNotEmpty) {
        var translatedNames = await global.translateNames(namesData: screenData.names!);
        setState(() => screenData.names = translatedNames);
        break;
      }
    }
  }

  Future<void> translateOptions() async {
    for (var option in screenData.options!) {
      await translateOptionNames(option);
      await translateChoices(option);
    }
  }

  Future<void> translateOptionNames(ProductOptionModel option) async {
    for (var name in option.names) {
      if (name.name.isEmpty) {
        var translatedNames = await global.translateNames(namesData: option.names);
        setState(() => option.names = translatedNames);
        break;
      }
    }
  }

  Future<void> translateChoices(ProductOptionModel option) async {
    for (var choice in option.choices) {
      for (var name in choice.names) {
        if (name.name.isEmpty) {
          var translatedNames = await global.translateNames(namesData: choice.names);
          setState(() => choice.names = translatedNames);
          break;
        }
      }
    }
  }

  Widget unitTextEditWidget(
      {required String label,
      required String unitCode,
      required List<LanguageDataModel> unitNames,
      required bool isReadOnly,
      required bool enableIcon,
      required TextEditingController unitCodeController,
      required TextEditingController unitNameController,
      required Function callBack}) {
    return Row(children: [
      Expanded(
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.f2) {
                searchUnit(word: unitCodeController.text, callBack: callBack);
              }
            }
          },
          child: TextFormField(
            onEditingComplete: () {
              if (kIsWeb) {
                findFocusNext(focusNodeIndex);
              }
            },
            readOnly: isReadOnly,
            onChanged: (code) {
              isDataChange = true;
              if (code.trim().isNotEmpty) {
                UnitRepository().getUnitManyByCode([code.trim()]).then((value) {
                  for (var data in value.data) {
                    if (data != null) {
                      UnitModel unit = UnitModel.fromJson(data);
                      unitNameController.text = global.packName(unit.names!);
                      callBack(false, code, unit.names);
                    } else {
                      unitNameController.text = "";
                      callBack(false, code, null);
                    }
                  }
                });
              } else {
                unitNameController.text = "";
                callBack(false, null, null);
              }
            },
            focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
            textAlign: TextAlign.left,
            controller: unitCodeController,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(10.0),
              hintText: global.language("must") + label,
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 0.0),
              ),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              labelText: label,
              suffixIcon: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (enableIcon)
                    IconButton(
                      focusNode: FocusNode(skipTraversal: true),
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        searchUnit(word: unitCodeController.text, callBack: callBack);
                      },
                    ),
                ],
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }

              return null;
            },
          ),
        ),
      ),
      const SizedBox(width: 5),
      Expanded(
          child: TextFormField(
        readOnly: true,
        focusNode: null,
        textAlign: TextAlign.left,
        controller: unitNameController,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(10.0),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey, width: 0.0),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: const OutlineInputBorder(),
          labelText: global.language("name"),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }

          return null;
        },
      ))
    ]);
  }

  void productGroupSearch() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ProductGroupSearchScreen(word: screenData.groupcode!))).then((value) {
      if (value != null) {
        setState(() {
          global.SearchCodeNameModel result = value;
          if (result.isCancel == false) {
            groupController.text = result.code;
            screenData.groupcode = result.code;
            screenData.groupnames = result.names;
          }
        });
      }
    });
  }

  void findProductGroup() {
    ProductGroupRepository().getProductGroupManyByCode([screenData.groupcode!.trim()]).then((value) {
      screenData.groupnames = [];
      for (var data in value.data) {
        if (data != null) {
          ProductGroupModel productGroupModel = ProductGroupModel.fromJson(data);
          screenData.groupnames = productGroupModel.names;
        }
        setState(() {});
      }
    });
  }

  Future<List<ItemDimension>> getDataItemDimension(filter, dimensionIndex) async {
    return dimensionSeleted[dimensionIndex].items!;
  }

  Widget _buildRadioOption(int value, String labelKey, Color activeColor) {
    return SizedBox(
      width: 200, // ปรับขนาดตามความเหมาะสม
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<int>(
            value: value,
            groupValue: screenData.itemtype,
            activeColor: activeColor,
            onChanged: isEditMode
                ? (newValue) {
                    setState(() {
                      screenData.itemtype = newValue;
                      if (newValue != 0 && newValue != 2) {
                        screenData.refbarcodes!.clear();
                        screenData.isusesubbarcodes = false;
                      }
                      if (newValue == 0 && screenData.refbarcodes!.length > 1) {
                        screenData.refbarcodes!.removeRange(1, screenData.refbarcodes!.length);
                        currentBarcodeNode = 0;
                      }
                    });
                  }
                : null,
          ),
          Flexible(
            child: Text(
              global.language(labelKey),
              style: TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget editScreen({mobileScreen}) {
    List<Widget> formWidgets = [];
    List<Widget> groupMenuWidgets = [];
    Widget productTypeRadio = Wrap(
      spacing: 8.0, // ระยะห่างแนวนอนระหว่าง items
      runSpacing: 0.0, // ระยะห่างแนวตั้งระหว่างแถว
      children: [
        _buildRadioOption(0, "product_is_stock", Colors.blue),
        _buildRadioOption(1, "product_is_service", Colors.red),
        _buildRadioOption(2, "product_is_set", Colors.yellow),
        _buildRadioOption(3, "product_is_material", Colors.red),
        _buildRadioOption(4, "product_semi_finished", Colors.red),
        _buildRadioOption(5, "product_is_not_stock", Colors.red),
      ],
    );

    Widget foodTypeRadio = InputDecorator(
      decoration: InputDecoration(
        labelText: global.language("food_type"),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: const BorderSide(color: Colors.grey, width: 0.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                Radio(
                    value: 0,
                    groupValue: screenData.foodtype,
                    onChanged: (value) {
                      if (isEditMode) {
                        setState(() {
                          screenData.foodtype = value;
                        });
                      }
                    }),
                Expanded(
                    child: Text(
                  global.language("food"),
                  overflow: TextOverflow.clip,
                ))
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Radio(
                    value: 1,
                    groupValue: screenData.foodtype,
                    activeColor: Colors.red,
                    onChanged: (value) {
                      if (isEditMode) {
                        setState(() {
                          screenData.foodtype = value;
                        });
                      }
                    }),
                Expanded(
                  child: Text(
                    global.language("drink"),
                    overflow: TextOverflow.clip,
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Radio(
                    value: 2,
                    groupValue: screenData.foodtype,
                    activeColor: Colors.yellow,
                    onChanged: (value) {
                      if (isEditMode) {
                        setState(() {
                          screenData.foodtype = value;
                        });
                      }
                    }),
                Expanded(
                  child: Text(
                    global.language("alcohol"),
                    overflow: TextOverflow.clip,
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Radio(
                    value: 3,
                    groupValue: screenData.foodtype,
                    activeColor: Colors.red,
                    onChanged: (value) {
                      if (isEditMode) {
                        setState(() {
                          screenData.foodtype = value;
                        });
                      }
                    }),
                Expanded(
                  child: Text(
                    global.language("other"),
                    overflow: TextOverflow.clip,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );

    Widget vatTypeRadio = InputDecorator(
      decoration: InputDecoration(
        labelText: global.language("vat_type"),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: const BorderSide(color: Colors.grey, width: 0.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
              child: Row(
            children: [
              Radio(
                  value: 0,
                  groupValue: screenData.vatcal,
                  onChanged: (value) {
                    if (isEditMode) {
                      setState(() {
                        screenData.vatcal = value;
                      });
                    }
                  }),
              Expanded(
                  child: Text(
                global.language("product_vat_type_1"),
                overflow: TextOverflow.clip,
              ))
            ],
          )),
          Expanded(
              child: Row(children: [
            Radio(
                value: 1,
                groupValue: screenData.vatcal,
                activeColor: Colors.red,
                onChanged: (value) {
                  if (isEditMode) {
                    setState(() {
                      screenData.vatcal = value;
                    });
                  }
                }),
            Expanded(
              child: Text(
                global.language("product_vat_type_2"),
                overflow: TextOverflow.clip,
              ),
            )
          ])),
        ],
      ),
    );

    Widget issumPointRadio = InputDecorator(
      decoration: InputDecoration(
        labelText: global.language("issumpoint"),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide: const BorderSide(color: Colors.grey, width: 0.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
              child: Row(
            children: [
              Radio(
                  value: false,
                  groupValue: screenData.issumpoint,
                  onChanged: (value) {
                    if (isEditMode) {
                      setState(() {
                        screenData.issumpoint = value;
                      });
                    }
                  }),
              Expanded(
                  child: Text(
                global.language("product_use_point_1"),
                overflow: TextOverflow.clip,
              ))
            ],
          )),
          Expanded(
              child: Row(children: [
            Radio(
                value: true,
                groupValue: screenData.issumpoint,
                activeColor: Colors.red,
                onChanged: (value) {
                  if (isEditMode) {
                    setState(() {
                      screenData.issumpoint = value;
                    });
                  }
                }),
            Expanded(
              child: Text(
                global.language("product_use_point_2"),
                overflow: TextOverflow.clip,
              ),
            )
          ])),
        ],
      ),
    );

    global.deviceConfigLoad();
    groupMenuWidgets.add(Expanded(
        child: ElevatedButton(
            child: Text(
              global.language("item_display_all"),
              overflow: TextOverflow.clip,
            ),
            onPressed: () {
              setState(() {
                global.deviceConfig.itemDisplaySku = true;
                global.deviceConfig.itemDisplayPrice = true;
                global.deviceConfigSaveJson();
              });
            })));
    groupMenuWidgets.add(const SizedBox(width: 5));
    groupMenuWidgets.add(Expanded(
        child: ElevatedButton(
            child: Row(children: [
              (global.deviceConfig.itemDisplaySku) ? const Icon(Icons.check) : const Icon(Icons.error),
              const SizedBox(width: 5),
              Expanded(child: Text(global.language("item_display_sku"), overflow: TextOverflow.clip))
            ]),
            onPressed: () {
              setState(() {
                global.deviceConfig.itemDisplaySku = !global.deviceConfig.itemDisplaySku;
                global.deviceConfigSaveJson();
              });
            })));
    groupMenuWidgets.add(const SizedBox(width: 5));
    groupMenuWidgets.add(Expanded(
        child: ElevatedButton(
            child: Row(children: [
              (global.deviceConfig.itemDisplayPrice) ? const Icon(Icons.check) : const Icon(Icons.error),
              const SizedBox(width: 5),
              Expanded(child: Text(global.language("item_display_price"), overflow: TextOverflow.clip))
            ]),
            onPressed: () {
              setState(() {
                global.deviceConfig.itemDisplayPrice = !global.deviceConfig.itemDisplayPrice;
                global.deviceConfigSaveJson();
              });
            })));
    // formWidgets.add(Container(
    //     padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
    //     child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: groupMenuWidgets))));
    focusNodeMax = 0;
    // Barcode
    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: TextFormField(
          enabled: (screenData.guidfixed.isEmpty && isEditMode),
          onEditingComplete: () {
            if (kIsWeb) {
              findFocusNext(focusNodeIndex);
            }
          },
          focusNode: fieldFocusNodes[focusNodeMax].focusNode,
          textAlign: TextAlign.left,
          controller: barcodeController,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9-]')),
            FilteringTextInputFormatter.deny(' '), // Exclude space character
          ],
          onChanged: (value) {
            isDataChange = true;
            screenData.barcode = value.toUpperCase();
            barcodeController.value = TextEditingValue(text: value.toUpperCase(), selection: barcodeController.selection);
          },
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
            labelText: global.language("barcode"),
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
    formWidgets.addAll(listNamesFields(screenData.names!, "product_name"));
    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: unitTextEditWidget(
          unitCode: screenData.itemunitcode ?? "",
          unitNames: screenData.itemunitnames ?? [],
          unitCodeController: TextEditingController(text: screenData.itemunitcode ?? ""),
          unitNameController: TextEditingController(text: global.packName(screenData.itemunitnames!)),
          label: global.language("unit"),
          isReadOnly: !isEditMode,
          enableIcon: isEditMode,
          callBack: (isChange, code, name) {
            if (isChange) {
              setState(() {
                screenData.itemunitcode = code;
                screenData.itemunitnames = name;
              });
            }
          },
        ),
      ),
    );
    for (int priceIndex = 0; priceIndex < priceList.length; priceIndex++) {
      formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
        child: TextField(
          readOnly: !isEditMode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [global.NumberInputFormatter()],
          onChanged: (value) {
            isDataChange = true;
            if (value != '') {
              screenData.prices![priceIndex].price = double.parse(value.replaceAll(',', ''));
            } else {
              screenData.prices![priceIndex].price = 0;
            }
          },
          onSubmitted: (value) {
            findFocusNext(focusNodeIndex);
          },
          focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
          textAlign: TextAlign.right,
          controller: TextEditingController(
              text: (screenData.prices![priceIndex].price == 0.0)
                  ? ""
                  : global.formatNumber(screenData.prices!.firstWhere((element) => element.keynumber == priceList[priceIndex].keyNumber).price)),
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
            labelText: "${global.language("price")} (${priceList[priceIndex].names[0].name})",
          ),
        ),
      ));
    }

    String subLenght = (screenData.refbarcodes!.isNotEmpty) ? "(${screenData.refbarcodes!.length})" : "";
    List<Widget> barcodes = [];
    if (screenData.isusesubbarcodes!) {
      List<TextEditingController> textStandController = [];
      List<TextEditingController> textDivideController = [];
      List<FocusNode> barcodesFocusNode = [];
      List<FocusNode> qtySetFocusNode = [];
      List<TextEditingController> qtyController = [];

      for (int i = 0; i < screenData.refbarcodes!.length; i++) {
        var data = screenData.refbarcodes![i];

        barcodesFocusNode.add(FocusNode());
        qtySetFocusNode.add(FocusNode());
        textStandController.add(TextEditingController(text: data.standvalue.toString()));
        textDivideController.add(TextEditingController(text: data.dividevalue.toString()));
        qtyController.add(TextEditingController(text: data.qty.toString()));
      }

      for (int i = 0; i < screenData.refbarcodes!.length; i++) {
        var data = screenData.refbarcodes![i];
        if (isEditMode && currentBarcodeNode > -1) {
          barcodesFocusNode[currentBarcodeNode].requestFocus();
          qtySetFocusNode[currentBarcodeNode].requestFocus();
        }

        /// ไม่ใช่สินค้าชุด
        if (screenData.itemtype != 2) {
          barcodes.add(Container(
            margin: const EdgeInsets.only(bottom: 10),
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                  const Color.fromARGB(255, 123, 235, 157),
                ),
                foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
              ),
              onPressed: () {
                subbarcodeSearch().then((result) {
                  if (!result.isusesubbarcodes!) {
                    if (result.guidfixed.isNotEmpty) {
                      data.guidfixed = result.guidfixed;
                      data.barcode = result.barcode!;
                      data.names = result.names!;
                      data.itemunitcode = result.itemunitcode!;
                      data.itemunitnames = result.itemunitnames!;
                      currentBarcodeNode = i;
                      data.qty = 0;
                      data.condition = false;
                    }
                  } else {
                    data.barcode = "";
                    global.showSnackBar(
                      context,
                      const Icon(
                        Icons.warning_amber,
                        color: Colors.white,
                      ),
                      global.language("ref_barcode_is_sub_barcode"),
                      Colors.orange,
                    );
                  }
                  setState(() {});
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (data.barcode.isEmpty)
                        ? "${global.language("barcode")} / ${global.language("item_name")} / ${global.language("unit_name")}"
                        : "${data.barcode} / ${global.packName(data.names)} / ${global.packName(data.itemunitnames)}",
                  ),
                  const Icon(Icons.search),
                ],
              ),
            ),
          ));
          if (data.barcode.isNotEmpty) {
            barcodes.add(
              Container(
                margin: const EdgeInsets.only(bottom: 10, top: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                              readOnly: !isEditMode,
                              keyboardType: TextInputType.number,
                              focusNode: qtySetFocusNode[i],
                              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                              onEditingComplete: () {},
                              onChanged: (code) {
                                if (code.isNotEmpty) {
                                  data.qty = int.parse(code);
                                  currentBarcodeNode = i;
                                  _debouncer.run(() {
                                    setState(() {});
                                  });
                                }
                              },
                              textAlign: TextAlign.center,
                              controller: qtyController[i],
                              decoration: InputDecoration(
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                border: const OutlineInputBorder(),
                                labelText: global.language("qty"),
                              )),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Radio(
                                        value: false,
                                        groupValue: data.condition,
                                        onChanged: (value) {
                                          if (isEditMode) {
                                            setState(() {
                                              data.condition = false;
                                              data.dividevalue = 1;
                                            });
                                          }
                                        }),
                                    Expanded(
                                        child: Text(
                                      global.packName(data.itemunitnames),
                                      overflow: TextOverflow.clip,
                                    ))
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Radio(
                                      value: true,
                                      groupValue: data.condition,
                                      onChanged: (value) {
                                        if (isEditMode) {
                                          setState(() {
                                            data.standvalue = 1;
                                            data.condition = true;
                                          });
                                        }
                                      },
                                    ),
                                    Expanded(
                                      child: Text(
                                        global.packName(screenData.itemunitnames!),
                                        overflow: TextOverflow.clip,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          child: Text(
                            (!data.condition)
                                ? "${global.formatNumber(double.parse(qtyController[i].text))} ${global.packName(data.itemunitnames)} = 1 ${global.packName(screenData.itemunitnames!)}"
                                : "1 ${global.packName(data.itemunitnames)} = ${global.formatNumber(double.parse(qtyController[i].text))} ${global.packName(screenData.itemunitnames!)}",
                            style: const TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          /// สินค้าชุด
        } else {
          barcodes.add(
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              width: double.infinity,
              height: 40,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                            const Color.fromARGB(255, 123, 235, 157),
                          ),
                          foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
                        ),
                        onPressed: () {
                          subbarcodeSearch().then((result) {
                            if (result.guidfixed.isNotEmpty) {
                              if (result.refbarcodes!.length == 1) {
                                data.dividevalue = result.refbarcodes![0].dividevalue;
                                data.standvalue = result.refbarcodes![0].standvalue;
                              } else {
                                data.dividevalue = 1;
                                data.standvalue = 1;
                              }
                              data.guidfixed = result.guidfixed;
                              data.barcode = result.barcode!;
                              data.names = result.names!;
                              data.itemunitcode = result.itemunitcode!;
                              data.itemunitnames = result.itemunitnames!;
                              currentBarcodeNode = i;
                              data.qty = 0;
                              data.condition = false;
                            }
                            setState(() {});
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                (data.barcode.isEmpty)
                                    ? "${global.language("barcode")} / ${global.language("item_name")} / ${global.language("unit_name")}"
                                    : "${data.barcode} / ${global.packName(data.names)} / ${global.packName(data.itemunitnames)}",
                                style: const TextStyle(
                                  overflow: TextOverflow.ellipsis,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(Icons.search),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    iconSize: 30.0,
                    onPressed: () {
                      setState(() {
                        currentBarcodeNode = 0;
                        if (screenData.refbarcodes!.length > 1) {
                          screenData.refbarcodes!.removeAt(i);
                        } else {
                          data.barcode = "";
                        }
                      });
                    },
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                  )
                ],
              ),
            ),
          );

          if (data.barcode.isNotEmpty) {
            barcodes.add(
              Container(
                margin: const EdgeInsets.only(bottom: 10, top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                          readOnly: !isEditMode,
                          keyboardType: TextInputType.number,
                          focusNode: qtySetFocusNode[i],
                          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                          onEditingComplete: () {},
                          onChanged: (code) {
                            if (code.isNotEmpty) {
                              data.qty = int.parse(code);
                              currentBarcodeNode = i;
                              _debouncer.run(() {
                                setState(() {});
                              });
                            }
                          },
                          textAlign: TextAlign.center,
                          controller: qtyController[i],
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: const OutlineInputBorder(),
                            labelText: global.language("qty"),
                          )),
                    ),
                    Expanded(
                      child: Container(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${qtyController[i].text} ${global.activeLangName(data.itemunitnames)} ",
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          }
        }
      }
    }

    ///  ประเภทสินค้า
    formWidgets.add(
      Container(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: global.language("product_type"),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4.0),
              borderSide: const BorderSide(color: Colors.grey, width: 0.0),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: productTypeRadio),
                ],
              ),
              const SizedBox(
                height: 10,
              ),

              ///  ใช้บาร์โค้ดอ้างอิง
              Row(
                children: [
                  Text(
                    "${global.language("use_reference_barcode")} $subLenght",
                    style: TextStyle(
                      fontSize: 16,
                      color: (screenData.itemtype == 1 || screenData.itemtype == 3 || screenData.itemtype == 4 || screenData.itemtype == 5) ? Colors.grey : Colors.black,
                    ),
                  ),
                  Switch(
                    value: screenData.isusesubbarcodes!,
                    onChanged: (screenData.itemtype == 1 || screenData.itemtype == 3 || screenData.itemtype == 4 || screenData.itemtype == 5)
                        ? null
                        : (bool value) {
                            setState(() {
                              if (value && screenData.refbarcodes!.isEmpty) {
                                screenData.refbarcodes!.add(BarCodeSubModel(
                                  guidfixed: '',
                                  barcode: '',
                                  names: [],
                                  itemunitcode: '',
                                  itemunitnames: [],
                                  condition: false,
                                  standvalue: 1,
                                  dividevalue: 1,
                                  qty: 0,
                                ));
                              } else {
                                screenData.refbarcodes!.clear();
                              }
                              screenData.isusesubbarcodes = value;
                            });
                          },
                  ),
                  Expanded(
                    child: (screenData.itemtype == 2 && screenData.isusesubbarcodes!)
                        ? SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                focusNode: FocusNode(skipTraversal: true),
                                onPressed: () {
                                  setState(() {
                                    screenData.refbarcodes!.add(BarCodeSubModel(
                                      guidfixed: '',
                                      barcode: '',
                                      names: [],
                                      itemunitcode: '',
                                      itemunitnames: [],
                                      condition: false,
                                      standvalue: 1,
                                      dividevalue: 1,
                                      qty: 0,
                                    ));
                                  });
                                },
                                label: Text(global.language("add_barcode"))),
                          )
                        : Container(),
                  )
                ],
              ),
              (screenData.isusesubbarcodes!)
                  ? Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Center(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: BorderSide(color: Colors.blue.shade100, width: 2), // Set the border color and width
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: barcodes,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );

    /// bom สูตรผลิต
    String bomLenght = (screenData.bom!.isNotEmpty) ? "(${screenData.bom!.length})" : "";
    List<Widget> bomBarcodes = [];
    if (screenData.bom!.isNotEmpty) {
      List<FocusNode> bomBarcodesFocusNode = [];
      List<FocusNode> bomQtySetFocusNode = [];
      List<TextEditingController> bomQtyController = [];

      for (int i = 0; i < screenData.bom!.length; i++) {
        var data = screenData.bom![i];

        bomBarcodesFocusNode.add(FocusNode());
        bomQtySetFocusNode.add(FocusNode());
        bomQtyController.add(TextEditingController(text: data.qty.toString()));
      }

      for (int i = 0; i < screenData.bom!.length; i++) {
        var data = screenData.bom![i];
        if (isEditMode && bomCurrentBarcodeNode > -1) {
          bomBarcodesFocusNode[bomCurrentBarcodeNode].requestFocus();
          bomQtySetFocusNode[bomCurrentBarcodeNode].requestFocus();
        }

        bomBarcodes.add(
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            width: double.infinity,
            height: 40,
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all<Color>(
                          const Color.fromARGB(255, 235, 147, 123),
                        ),
                        foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
                      ),
                      onPressed: () {
                        subbarcodeSearch().then((result) {
                          if (result.guidfixed.isNotEmpty) {
                            if (result.refbarcodes!.length == 1) {
                              data.dividevalue = result.refbarcodes![0].dividevalue;
                              data.standvalue = result.refbarcodes![0].standvalue;
                            } else {
                              data.dividevalue = 1;
                              data.standvalue = 1;
                            }
                            data.guidfixed = result.guidfixed;
                            data.barcode = result.barcode!;
                            data.names = result.names!;
                            data.itemunitcode = result.itemunitcode!;
                            data.itemunitnames = result.itemunitnames!;
                            bomCurrentBarcodeNode = i;
                            data.qty = 0;
                            data.condition = false;
                          }
                          setState(() {});
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              (data.barcode.isEmpty)
                                  ? "${global.language("barcode")} / ${global.language("item_name")} / ${global.language("unit_name")}"
                                  : "${data.barcode} / ${global.packName(data.names)} / ${global.packName(data.itemunitnames)}",
                              style: const TextStyle(
                                overflow: TextOverflow.ellipsis,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(Icons.search),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  iconSize: 30.0,
                  onPressed: () {
                    setState(() {
                      bomCurrentBarcodeNode = 0;
                      if (screenData.bom!.length > 1) {
                        screenData.bom!.removeAt(i);
                      } else {
                        data.barcode = "";
                      }
                    });
                  },
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                )
              ],
            ),
          ),
        );

        if (data.barcode.isNotEmpty) {
          bomBarcodes.add(
            Container(
              margin: const EdgeInsets.only(bottom: 10, top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      readOnly: !isEditMode,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true), // Allow decimal input
                      focusNode: bomQtySetFocusNode[i],
                      inputFormatters: <TextInputFormatter>[
                        // Allow digits and dot, limit to 6 decimal places
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}')),
                      ],
                      onEditingComplete: () {
                        setState(() {});
                      },
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          data.qty = double.parse(value);
                          bomCurrentBarcodeNode = i;
                          _debouncer.run(() {
                            setState(() {});
                          });
                        }
                      },
                      textAlign: TextAlign.center,
                      controller: bomQtyController[i],
                      decoration: InputDecoration(
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: const OutlineInputBorder(),
                        labelText: global.language("qty"),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "${bomQtyController[i].text} ${global.activeLangName(data.itemunitnames)} ",
                        style: const TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        }
      }
    }

    ///  bom สูตรผลิต
    formWidgets.add(
      Container(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: Row(
          children: [
            Text(
              "${global.language("use_product_boom")} $bomLenght",
              style: TextStyle(
                fontSize: 16,
                color: (screenData.itemtype == 1) ? Colors.grey : Colors.black,
              ),
            ),
            Switch(
              value: (screenData.bom!.isNotEmpty) ? true : false,
              onChanged: (bool value) {
                if (value) {
                  setState(() {
                    if (value && screenData.bom!.isEmpty) {
                      screenData.bom!.add(BomModel(
                        guidfixed: '',
                        barcode: '',
                        names: [],
                        itemunitcode: '',
                        itemunitnames: [],
                        condition: false,
                        standvalue: 1,
                        dividevalue: 1,
                        qty: 0,
                      ));
                    }
                  });
                } else {
                  setState(() {
                    screenData.bom!.clear();
                  });
                }
              },
            ),
            Expanded(
              child: (screenData.bom!.isNotEmpty)
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color?>(Colors.blue.shade100),
                            foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
                          ),
                          icon: const Icon(Icons.add),
                          focusNode: FocusNode(skipTraversal: true),
                          onPressed: () {
                            setState(() {
                              screenData.bom!.add(BomModel(
                                guidfixed: '',
                                barcode: '',
                                names: [],
                                itemunitcode: '',
                                itemunitnames: [],
                                condition: false,
                                standvalue: 1,
                                dividevalue: 1,
                                qty: 0,
                              ));
                            });
                          },
                          label: Text(global.language("add_barcode"))),
                    )
                  : Container(),
            )
          ],
        ),
      ),
    );

    ///  bom สูตรผลิต
    if (screenData.bom!.isNotEmpty) {
      formWidgets.add(
        Container(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: global.language("product_bom"),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4.0),
                borderSide: const BorderSide(color: Colors.grey, width: 0.0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: Colors.blue.shade100, width: 2), // Set the border color and width
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: bomBarcodes,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    ///  ประเภทอาหาร
    formWidgets.add(
      Container(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: foodTypeRadio),
          ],
        ),
      ),
    );

    if (queryData.size.width > 1264) {
      formWidgets.add(Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Expanded(child: vatTypeRadio)],
          )));

      formWidgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: issumPointRadio,
        ),
      );
    } else {
      formWidgets.add(Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.only(left: 10, right: 10), child: vatTypeRadio));
      formWidgets.add(Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.only(left: 10, right: 10), child: issumPointRadio));
    }
    // รหัสสินค้า
    focusNodeMax++;
    formWidgets.add(Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: TextField(
            readOnly: !isEditMode,
            onSubmitted: (value) {
              if (kIsWeb) {
                findFocusNext(focusNodeIndex);
              }
            },
            focusNode: fieldFocusNodes[focusNodeMax].focusNode,
            textAlign: TextAlign.left,
            controller: TextEditingController(text: screenData.itemcode),
            textCapitalization: TextCapitalization.characters,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp('[a-z A-Z 0-9 -]')),
            ],
            onChanged: (value) {
              isDataChange = true;
              screenData.itemcode = value.toUpperCase();
              TextEditingController(text: screenData.itemcode).selection = TextSelection.fromPosition(TextPosition(offset: value.length));
            },
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              labelText: global.language("item_code"),
            ))));

    formWidgets.add(Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: Row(
        children: [
          Expanded(
              child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (KeyEvent event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.f2) {
                        productGroupSearch();
                      }
                    }
                  },
                  child: TextField(
                      readOnly: false,
                      textInputAction: TextInputAction.next,
                      focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
                      controller: TextEditingController(text: screenData.groupcode ?? ""),
                      textAlign: TextAlign.left,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (code) {
                        isDataChange = true;
                        screenData.groupcode = code;
                        findProductGroup();
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
                            (isEditMode)
                                ? IconButton(
                                    focusNode: FocusNode(skipTraversal: true),
                                    icon: const Icon(Icons.search),
                                    onPressed: () {
                                      productGroupSearch();
                                    },
                                  )
                                : Container(),
                          ],
                        ),
                        border: const OutlineInputBorder(),
                        labelText: global.language("product_group_code"),
                      )))),
          const SizedBox(width: 5),
          Expanded(
              child: TextField(
                  readOnly: true,
                  controller: TextEditingController(text: global.packName(screenData.groupnames!)),
                  textAlign: TextAlign.left,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(10.0),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 0.0),
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    border: const OutlineInputBorder(),
                    labelText: global.language("product_group_name"),
                  )))
        ],
      ),
    ));

    focusNodeMax++;
    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: TextField(
          readOnly: !isEditMode,
          onSubmitted: (value) {
            if (kIsWeb) {
              findFocusNext(++focusNodeIndex);
            }
          },
          focusNode: fieldFocusNodes[focusNodeMax].focusNode,
          textAlign: TextAlign.left,
          controller: TextEditingController(text: screenData.discount),
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) {
            isDataChange = true;
            screenData.discount = value;
            TextEditingController(text: screenData.discount).selection = TextSelection.fromPosition(TextPosition(offset: value.length));
          },
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.always,
            border: const OutlineInputBorder(),
            labelText: global.language("discount"),
          ),
        ),
      ),
    );

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Row(
          children: [
            Switch(
              value: screenData.isalacarte!,
              onChanged: (bool? value) {
                setState(() {
                  screenData.isalacarte = value ?? false;
                });
              },
            ),
            Text(global.language("alacarte")),
          ],
        ),
      ),
    );
    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Row(
          children: [
            Switch(
              value: screenData.isstockforrestaurant!,
              onChanged: (bool? value) {
                setState(() {
                  screenData.isstockforrestaurant = value ?? false;
                });
              },
            ),
            Text(global.language("is_stock_for_restaurant")),
          ],
        ),
      ),
    );
    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Row(
          children: [
            Switch(
              value: screenData.issplitunitprint!,
              onChanged: (bool? value) {
                setState(() {
                  screenData.issplitunitprint = value ?? false;
                });
              },
            ),
            Text(global.language("is_split_unit_print")),
          ],
        ),
      ),
    );
    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Row(
          children: [
            Switch(
              value: screenData.isonlystaff!,
              onChanged: (bool? value) {
                setState(() {
                  screenData.isonlystaff = value ?? false;
                });
              },
            ),
            Text(global.language("is_only_employee")),
          ],
        ),
      ),
    );

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Row(
          children: [
            Switch(
              value: screenData.isdiscountpointofpurchase!,
              onChanged: (bool? value) {
                setState(() {
                  screenData.isdiscountpointofpurchase = value ?? false;
                });
              },
            ),
            Text(global.language("is_discount_point_of_purchase")),
          ],
        ),
      ),
    );

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Row(
          children: [
            Switch(
              value: screenData.restaurant!.isforrestaurant!,
              onChanged: (bool? value) {
                setState(() {
                  screenData.restaurant!.isforrestaurant = value ?? false;
                });
              },
            ),
            Text(global.language("is_for_restaurant")),
          ],
        ),
      ),
    );

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Row(
          children: [
            Switch(
              value: screenData.restaurant!.isfortakeaway!,
              onChanged: (bool? value) {
                setState(() {
                  screenData.restaurant!.isfortakeaway = value ?? false;
                });
              },
            ),
            Text(global.language("is_for_takeaway")),
          ],
        ),
      ),
    );

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Row(
          children: [
            Switch(
              value: screenData.restaurant!.isfordelivery!,
              onChanged: (bool? value) {
                setState(() {
                  screenData.restaurant!.isfordelivery = value ?? false;
                });
              },
            ),
            Text(global.language("is_for_delivery")),
          ],
        ),
      ),
    );

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Row(
          children: [
            Switch(
              value: screenData.restaurant!.isforcustomer!,
              onChanged: (bool? value) {
                setState(() {
                  screenData.restaurant!.isforcustomer = value ?? false;
                });
              },
            ),
            Text(global.language("is_for_customer")),
          ],
        ),
      ),
    );

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Row(
          children: [
            Switch(
              value: screenData.restaurant!.isforcustomerpreorder!,
              onChanged: (bool? value) {
                setState(() {
                  screenData.restaurant!.isforcustomerpreorder = value ?? false;
                });
              },
            ),
            Text(global.language("is_for_customer_preorder")),
          ],
        ),
      ),
    );

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Column(
          children: [
            Row(
              children: [
                Switch(
                  value: screenData.isalert!,
                  onChanged: (bool value) {
                    setState(() {
                      screenData.isalert = value;
                    });
                  },
                ),
                Text(global.language("is_use_alert")),
              ],
            ),
            (screenData.isalert!)
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                            child: TextField(
                          maxLines: 4,
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: const OutlineInputBorder(),
                            labelText: global.language('disciption'),
                          ),
                          controller: alertDescriptionTextEditController,
                        )),
                      ],
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );

    /// ประเภทธูรกิจ
    formWidgets.add(Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
      child: DropdownSearch<BusinessTypeModel>.multiSelection(
        enabled: isEditMode,
        key: _popupBuilderBusinessKey,
        asyncItems: (String filter) => getDataBusiness(filter),
        compareFn: (item, selectedItem) => item.guidfixed == selectedItem.guidfixed,
        itemAsString: (BusinessTypeModel? businessTypeModel) {
          if (businessTypeModel == null) return '';
          return '${businessTypeModel.code} - ${global.packName(businessTypeModel.names!)}';
        },
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            labelText: global.language("business_type"),
          ),
        ),
        onChanged: (List<BusinessTypeModel> value) {
          setState(() {
            screenData.businesstypes = value;
            loadDataBranchList(screenData.businesstypes!);
          });
        },
        popupProps: PopupPropsMultiSelection.dialog(
          showSearchBox: false,
          showSelectedItems: true,
          title: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(global.language("select_business_type")),
          ),
        ),
        selectedItems: screenData.businesstypes!,
      ),
    ));

    /// สาขา
    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: DropdownSearch<BranchModel>.multiSelection(
          enabled: isEditMode,
          key: _popupBuilderBranchKey,
          asyncItems: (String filter) => getDataBranch(filter),
          compareFn: (item, selectedItem) => item.guidfixed == selectedItem.guidfixed,
          itemAsString: (BranchModel? branchModel) {
            if (branchModel == null) return '';
            return '${branchModel.code} - ${global.packName(branchModel.names!)}';
          },
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              labelText: global.language("branch"),
            ),
          ),
          onChanged: (List<BranchModel> value) {
            setState(() {
              ignorebranches = value;
            });
          },
          popupProps: PopupPropsMultiSelection.dialog(
            showSearchBox: false,
            showSelectedItems: true,
            emptyBuilder: (context, searchEntry) => Center(
              child: (screenData.businesstypes!.isEmpty) ? Text(global.language("please_select_business_type")) : Text(global.language("business_type_not_match_branch")),
            ),
            title: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(global.language("select_branch")),
            ),
          ),
          selectedItems: ignorebranches!,
        ),
      ),
    );

    /// ประเภทสินค้า
    // formWidgets.add(
    //   Padding(
    //     padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
    //     child: Row(
    //       children: [
    //         Expanded(
    //           child: SizedBox(
    //             height: 50,
    //             child: ElevatedButton(
    //               style: ButtonStyle(
    //                 backgroundColor: WidgetStateProperty.all<Color>(
    //                   (screenData.producttype!.guidfixed!.isNotEmpty) ? const Color.fromARGB(255, 168, 171, 136) : const Color.fromARGB(255, 168, 171, 136),
    //                 ),
    //                 foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
    //               ),
    //               onPressed: () {
    //                 Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductTypeSearchScreen(word: ''))).then((value) {
    //                   if (value != null) {
    //                     setState(() {
    //                       ProductTypeModel result = value;
    //                       if (result.guidfixed!.isNotEmpty) {
    //                         screenData.producttype!.guidfixed = result.guidfixed;
    //                         screenData.producttype!.code = result.code;
    //                         screenData.producttype!.names = result.names;
    //                       }
    //                     });
    //                   }
    //                 });
    //                 setState(() {});
    //               },
    //               child: Row(
    //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                 children: [
    //                   // Add your new icon here
    //                   const Icon(Icons.category),
    //                   Expanded(
    //                     child: Text(
    //                       (screenData.producttype!.guidfixed!.isEmpty)
    //                           ? "${global.language("product_type_code")} ~ ${global.language("product_type_name")} "
    //                           : "${global.language("product_type_name")} : ${screenData.producttype!.code} ~ ${global.packName(screenData.producttype!.names!)}  ",
    //                       overflow: TextOverflow.ellipsis,
    //                       maxLines: 2,
    //                     ),
    //                   ),
    //                   (screenData.producttype!.guidfixed!.isNotEmpty)
    //                       ? IconButton(
    //                           onPressed: () {
    //                             setState(() {
    //                               // Reset the selected product type
    //                               screenData.producttype!.guidfixed = '';
    //                               screenData.producttype!.code = '';
    //                               screenData.producttype!.names = [];
    //                             });
    //                           },
    //                           icon: const Icon(Icons.delete),
    //                         )
    //                       : Container(),
    //                   const Icon(Icons.search),
    //                 ],
    //               ),
    //             ),
    //           ),
    //         ),
    //       ],
    //     ),
    //   ),
    // );

    /// ผู้ผลิต
    // formWidgets.add(
    //   Padding(
    //     padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
    //     child: Row(
    //       children: [
    //         Expanded(
    //           child: SizedBox(
    //             height: 50,
    //             child: ElevatedButton(
    //               style: ButtonStyle(
    //                 backgroundColor: WidgetStateProperty.all<Color>(
    //                   (screenData.manufacturer!.guid.isNotEmpty) ? const Color.fromARGB(255, 158, 236, 255) : const Color.fromARGB(255, 158, 236, 255),
    //                 ),
    //                 foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
    //               ),
    //               onPressed: () {
    //                 Navigator.push(context, MaterialPageRoute(builder: (context) => const SupplierSearchScreen(word: ''))).then((value) {
    //                   if (value != null) {
    //                     setState(() {
    //                       SearchGuidCodeNameModel result = value;
    //                       if (result.guid.isNotEmpty) {
    //                         screenData.manufacturerguid = result.guid;
    //                         screenData.manufacturer!.guid = result.guid;
    //                         screenData.manufacturer!.code = result.code;
    //                         screenData.manufacturer!.names = result.names;
    //                       }
    //                     });
    //                   }
    //                 });
    //                 setState(() {});
    //               },
    //               child: Row(
    //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                 children: [
    //                   // Add your new icon here
    //                   const Icon(Icons.person_search_rounded),
    //                   Expanded(
    //                     child: Text(
    //                       (screenData.manufacturer!.guid.isEmpty)
    //                           ? "${global.language("manufacturer_code")} ~ ${global.language("manufacturer_name")} "
    //                           : "${global.language("manufacturer_name")} : ${screenData.manufacturer!.code} ~ ${global.packName(screenData.manufacturer!.names)}  ",
    //                       overflow: TextOverflow.ellipsis,
    //                       maxLines: 2,
    //                     ),
    //                   ),
    //                   (screenData.manufacturer!.guid.isNotEmpty)
    //                       ? IconButton(
    //                           onPressed: () {
    //                             setState(() {
    //                               // Reset the selected product type
    //                               screenData.manufacturerguid = '';
    //                               screenData.manufacturer!.guid = '';
    //                               screenData.manufacturer!.code = '';
    //                               screenData.manufacturer!.names = [];
    //                             });
    //                           },
    //                           icon: const Icon(Icons.delete),
    //                         )
    //                       : Container(),
    //                   const Icon(Icons.search),
    //                 ],
    //               ),
    //             ),
    //           ),
    //         ),
    //       ],
    //     ),
    //   ),
    // );

    // if (screenData.ordertypes!.isNotEmpty) {
    //   for (int optionTypeIndex = 0; optionTypeIndex < screenData.ordertypes!.length; optionTypeIndex++) {
    //     formWidgets.add(
    //       Padding(
    //         padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
    //         child: Row(
    //           children: [
    //             Expanded(
    //               child: SizedBox(
    //                 height: 50,
    //                 child: ElevatedButton(
    //                   style: ButtonStyle(
    //                     backgroundColor: WidgetStateProperty.all<Color>(
    //                       (screenData.ordertypes![optionTypeIndex].code.isNotEmpty) ? const Color.fromARGB(255, 171, 192, 233) : const Color.fromARGB(255, 199, 194, 194),
    //                     ),
    //                     foregroundColor: WidgetStateProperty.all<Color>(Colors.black),
    //                   ),
    //                   onPressed: () {
    //                     orderTypeSearch(optionTypeIndex);
    //                   },
    //                   child: Row(
    //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                     children: [
    //                       Expanded(
    //                         child: Text(
    //                           (screenData.ordertypes![optionTypeIndex].code.isEmpty)
    //                               ? "${global.language("order_type_code")} ~ ${global.language("order_type_name")} "
    //                               : "${screenData.ordertypes![optionTypeIndex].code} ~ ${global.packName(screenData.ordertypes![optionTypeIndex].names)}  ",
    //                           overflow: TextOverflow.ellipsis,
    //                           maxLines: 2,
    //                         ),
    //                       ),
    //                       const Icon(Icons.search),
    //                     ],
    //                   ),
    //                 ),
    //               ),
    //             ),
    //             const SizedBox(
    //               width: 10,
    //             ),
    //             Expanded(
    //               child: TextField(
    //                 enabled: (screenData.ordertypes![optionTypeIndex].code.isNotEmpty),
    //                 controller: TextEditingController(text: screenData.ordertypes![optionTypeIndex].price.toString()),
    //                 keyboardType: TextInputType.number,
    //                 inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
    //                 textAlign: TextAlign.center,
    //                 decoration: InputDecoration(
    //                   floatingLabelBehavior: FloatingLabelBehavior.always,
    //                   border: const OutlineInputBorder(),
    //                   labelText: global.language("charge_price"),
    //                 ),
    //                 onChanged: (value) {
    //                   if (value.isNotEmpty) {
    //                     screenData.ordertypes![optionTypeIndex].price = double.parse(value.replaceAll(',', ''));
    //                   } else {
    //                     screenData.ordertypes![optionTypeIndex].price = 0;
    //                   }
    //                 },
    //               ),
    //             ),
    //             const SizedBox(
    //               width: 10,
    //             ),
    //             IconButton(
    //                 onPressed: () {
    //                   setState(() {
    //                     screenData.ordertypes!.removeAt(optionTypeIndex);
    //                   });
    //                 },
    //                 icon: const Icon(Icons.delete),
    //                 focusNode: FocusNode(skipTraversal: true),
    //                 color: Colors.red,
    //                 iconSize: 20),
    //           ],
    //         ),
    //       ),
    //     );
    //   }
    // }

    // formWidgets.add(
    //   Container(
    //     height: 50,
    //     padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
    //     width: double.infinity,
    //     child: ElevatedButton.icon(
    //       onPressed: () {
    //         setState(() {
    //           List<LanguageDataModel> names = [];
    //           for (int k = 0; k < languageList.length; k++) {
    //             names.add(LanguageDataModel(code: languageList[k].code!, name: ""));
    //           }
    //           screenData.ordertypes!.add(OrderTypeProductBarcode(
    //             guidfixed: '',
    //             code: '',
    //             names: names,
    //             price: 0,
    //           ));
    //         });
    //       },
    //       style: ButtonStyle(
    //         backgroundColor: WidgetStateProperty.all<Color>(const Color.fromARGB(255, 65, 66, 74)), // Set the background color here
    //       ),
    //       icon: const Icon(Icons.add), // Set the icon here
    //       label: Text(global.language("add_order_type")),
    //     ),
    //   ),
    // );

    /// dimension

    // if (screenData.dimensions!.isNotEmpty) {
    //   for (int dimensionsIndex = 0; dimensionsIndex < screenData.dimensions!.length; dimensionsIndex++) {
    //     formWidgets.add(
    //       Padding(
    //         padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
    //         child: Row(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             Expanded(
    //               child: SizedBox(
    //                 height: 50,
    //                 child: ElevatedButton(
    //                   style: ButtonStyle(
    //                     backgroundColor: WidgetStateProperty.all<Color>(
    //                       const Color.fromARGB(182, 59, 63, 21),
    //                     ),
    //                     foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
    //                   ),
    //                   onPressed: () {
    //                     dimensionSearch(dimensionsIndex);
    //                     setState(() {});
    //                   },
    //                   child: Row(
    //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                     children: [
    //                       Expanded(
    //                         child: Text(
    //                           (screenData.dimensions![dimensionsIndex].guidfixed!.isEmpty)
    //                               ? "${global.language("level_dimension")} : ${dimensionsIndex + 1} "
    //                               : "${global.language("level_dimension")} : ${dimensionsIndex + 1} ~ ${global.packName(screenData.dimensions![dimensionsIndex].names!)}  ",
    //                           overflow: TextOverflow.ellipsis,
    //                           maxLines: 2,
    //                         ),
    //                       ),
    //                       const Icon(Icons.search),
    //                     ],
    //                   ),
    //                 ),
    //               ),
    //             ),
    //             const SizedBox(
    //               width: 10,
    //             ),
    //             Expanded(
    //               child: DropdownSearch<ItemDimension>(
    //                 enabled: isEditMode,
    //                 asyncItems: (String filter) => getDataItemDimension(filter, dimensionsIndex),
    //                 compareFn: (item, selectedItem) => item.guidfixed == selectedItem.guidfixed,
    //                 itemAsString: (ItemDimension? item) {
    //                   if (item == null || item.guidfixed!.isEmpty) return '';
    //                   return global.packName(item.names!);
    //                 },
    //                 dropdownDecoratorProps: const DropDownDecoratorProps(
    //                   dropdownSearchDecoration: InputDecoration(
    //                     border: OutlineInputBorder(),
    //                     contentPadding: EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
    //                     floatingLabelBehavior: FloatingLabelBehavior.always,
    //                     filled: true,
    //                   ),
    //                 ),
    //                 onChanged: (ItemDimension? value) {
    //                   if (value != null && value.isdisabled!) {
    //                     setState(() {
    //                       screenData.dimensions![dimensionsIndex].item = value;
    //                     });
    //                   } else {
    //                     setState(() {
    //                       screenData.dimensions![dimensionsIndex].item = ItemDimension(
    //                         guidfixed: '',
    //                         names: [],
    //                         isdisabled: false,
    //                       );
    //                       global.showSnackBar(
    //                         context,
    //                         const Icon(
    //                           Icons.warning_amber,
    //                           color: Colors.white,
    //                         ),
    //                         global.language("ref_dimension_is_disabled"),
    //                         Colors.orange,
    //                       );
    //                     });
    //                   }
    //                 },
    //                 validator: (ItemDimension? u) => u!.guidfixed!.isEmpty ? "required field" : null,
    //                 popupProps: PopupPropsMultiSelection.dialog(
    //                   showSearchBox: true,
    //                   showSelectedItems: true,
    //                   itemBuilder: (ctx, item, isSelected) {
    //                     return ListTile(
    //                       enabled: item.isdisabled!,
    //                       title: Text(global.packName(item.names!)),
    //                       selected: isSelected,
    //                     );
    //                   },
    //                 ),
    //                 selectedItem: screenData.dimensions![dimensionsIndex].item,
    //               ),
    //             ),
    //             const SizedBox(
    //               width: 10,
    //             ),
    //             IconButton(
    //                 onPressed: () {
    //                   setState(() {
    //                     dimensionSeleted.removeAt(dimensionsIndex);
    //                     screenData.dimensions!.removeAt(dimensionsIndex);
    //                   });
    //                 },
    //                 icon: const Icon(Icons.delete),
    //                 focusNode: FocusNode(skipTraversal: true),
    //                 color: Colors.red,
    //                 iconSize: 20),
    //           ],
    //         ),
    //       ),
    //     );
    //   }
    // }

    /// dimension
    // formWidgets.add(
    //   Container(
    //     height: 50,
    //     padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
    //     width: double.infinity,
    //     child: ElevatedButton.icon(
    //       onPressed: () {
    //         setState(() {
    //           screenData.dimensions!.add(
    //             DimensionProductModel(
    //               guidfixed: '',
    //               names: names,
    //               item: ItemDimension(
    //                 guidfixed: '',
    //                 names: [],
    //                 isdisabled: false,
    //               ),
    //             ),
    //           );
    //           dimensionSeleted.add(DimensionModel());
    //         });
    //       },
    //       style: ButtonStyle(
    //         backgroundColor: WidgetStateProperty.all<Color>(const Color.fromARGB(182, 59, 63, 21)), // Set the background color here
    //       ),
    //       icon: const Icon(Icons.add), // Set the icon here
    //       label: Text(global.language("add_dimension")),
    //     ),
    //   ),
    // );

    if (screenData.options!.isNotEmpty) {
      formWidgets.add(
        Container(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
              focusNode: FocusNode(skipTraversal: true),
              onPressed: () {
                optionSearch();
              },
              child: Text(global.language("clone_option"))),
        ),
      );
      for (int optionIndex = 0; optionIndex < screenData.options!.length; optionIndex++) {
        List<Widget> optionList = [];
        optionList.add(Container(
          padding: const EdgeInsets.only(top: 5, bottom: 10),
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text("${global.language("option")} ${optionIndex + 1}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
              IconButton(
                  onPressed: () {
                    setState(() {
                      screenData.options!.removeAt(optionIndex);
                    });
                  },
                  icon: const Icon(Icons.delete),
                  focusNode: FocusNode(skipTraversal: true),
                  color: Colors.red,
                  iconSize: 20),
              if (optionIndex > 0)
                IconButton(
                    onPressed: () {
                      setState(() {
                        screenData.options!.insert(optionIndex - 1, screenData.options!.removeAt(optionIndex));
                      });
                    },
                    icon: const Icon(Icons.move_up),
                    focusNode: FocusNode(skipTraversal: true),
                    color: Colors.blue,
                    iconSize: 20),
              if (optionIndex < screenData.options!.length - 1)
                IconButton(
                    onPressed: () {
                      setState(() {
                        screenData.options!.insert(optionIndex + 1, screenData.options!.removeAt(optionIndex));
                      });
                    },
                    icon: const Icon(Icons.move_down),
                    color: Colors.red,
                    focusNode: FocusNode(skipTraversal: true),
                    iconSize: 20),
            ],
          ),
        ));
        // for (int languageIndex = 0; languageIndex < languageList.length; languageIndex++) {
        //   LanguageDataModel optionName =
        //       screenData.options![optionIndex].names.firstWhere((element) => element.code == languageList[languageIndex].code, orElse: () => LanguageDataModel(code: '', name: ''));
        //   if (optionName.code == '') {
        //     screenData.options![optionIndex].names.add(LanguageDataModel(code: languageList[languageIndex].code!, name: ''));
        //   }

        //   optionList.add(Padding(
        //     padding: const EdgeInsets.only(left: 5, right: 5, bottom: 10),
        //     child: TextField(
        //       readOnly: !isEditMode,
        //       onChanged: (value) {
        //         isDataChange = true;
        //         screenData.options![optionIndex].names[languageIndex].name = value;
        //       },
        //       onSubmitted: (value) {
        //         findFocusNext(focusNodeIndex);
        //       },
        //       focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
        //       textAlign: TextAlign.left,
        //       controller: TextEditingController(text: screenData.options![optionIndex].names[languageIndex].name),
        //       decoration: InputDecoration(
        //         floatingLabelBehavior: FloatingLabelBehavior.always,
        //         border: const OutlineInputBorder(),
        //         labelText: "${global.language("option_name")} (${getLangName(screenData.options![optionIndex].names[languageIndex].code)})",
        //       ),
        //     ),
        //   ));
        // }
        optionList.addAll(listNamesFields(screenData.options![optionIndex].names, "option_name"));
        optionList.add(Row(children: [
          Expanded(
              child: ListTile(
            title: Text(global.language("product_option_choice_type_multi")),
            leading: Radio(
                value: 0,
                groupValue: screenData.options![optionIndex].choicetype,
                onChanged: (value) {
                  setState(() {
                    screenData.options![optionIndex].choicetype = value!;
                  });
                }),
          )),
          Expanded(
            child: ListTile(
                title: Text(global.language("product_option_choice_type_single")),
                leading: Radio(
                    value: 1,
                    groupValue: screenData.options![optionIndex].choicetype,
                    onChanged: (value) {
                      setState(() {
                        screenData.options![optionIndex].choicetype = value!;
                      });
                    })),
          ),
        ]));
        List<Widget> choiceList = [];
        for (int choiceIndex = 0; choiceIndex < screenData.options![optionIndex].choices.length; choiceIndex++) {
          List<Widget> choiceRow = [];
          if (choiceList.isNotEmpty) {
            choiceRow.add(const Divider(
              color: Colors.black,
            ));
          }
          choiceRow.add(Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text("${global.language("choice")} ${choiceIndex + 1}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
              IconButton(
                  onPressed: () {
                    setState(() {
                      screenData.options![optionIndex].choices.removeAt(choiceIndex);
                    });
                  },
                  icon: const Icon(Icons.delete),
                  focusNode: FocusNode(skipTraversal: true),
                  color: Colors.red,
                  iconSize: 20),
              if (choiceIndex > 0)
                IconButton(
                    onPressed: () {
                      setState(() {
                        screenData.options![optionIndex].choices.insert(choiceIndex - 1, screenData.options![optionIndex].choices.removeAt(choiceIndex));
                      });
                    },
                    icon: const Icon(Icons.move_up),
                    focusNode: FocusNode(skipTraversal: true),
                    color: Colors.blue,
                    iconSize: 20),
              if (choiceIndex < screenData.options![optionIndex].choices.length - 1)
                IconButton(
                    onPressed: () {
                      setState(() {
                        screenData.options![optionIndex].choices.insert(choiceIndex + 1, screenData.options![optionIndex].choices.removeAt(choiceIndex));
                      });
                    },
                    icon: const Icon(Icons.move_down),
                    color: Colors.green,
                    focusNode: FocusNode(skipTraversal: true),
                    iconSize: 20),
            ],
          ));

          choiceRow.add(Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    global.language("image"),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: ElevatedButton.icon(
                      focusNode: FocusNode(skipTraversal: true),
                      onPressed: () async {
                        setState(() {
                          screenData.options![optionIndex].choices[choiceIndex].imageuri = "";
                        });
                      },
                      icon: const Icon(
                        Icons.delete,
                      ),
                      label: Text(global.language('delete_picture')),
                    )),
                    const SizedBox(width: 5),
                    Expanded(
                        child: ElevatedButton.icon(
                      focusNode: FocusNode(skipTraversal: true),
                      onPressed: () async {
                        XFile? image = await imagePicker.pickImage(source: ImageSource.gallery, maxHeight: 480, maxWidth: 640, imageQuality: 60);
                        if (image != null) {
                          var f = await image.readAsBytes();
                          setState(() {
                            imageWebChoice[0] = f;
                            imageFileChoice[0] = File(image.path);
                            uploadImageOptionIndex = optionIndex;
                            uploadImageChoiceIndex = choiceIndex;
                            upLoadImageChoice();
                          });
                        }
                      },
                      icon: const Icon(
                        Icons.folder,
                      ),
                      label: Text(global.language("select_picture")),
                    )),
                    const SizedBox(width: 5),
                  ],
                ),
                SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    children: [
                      Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(5),
                            image: (screenData.options![optionIndex].choices[choiceIndex].imageuri != '')
                                ? DecorationImage(image: NetworkImage(screenData.options![optionIndex].choices[choiceIndex].imageuri!), fit: BoxFit.fill)
                                : const DecorationImage(
                                    image: AssetImage('assets/img/noimage.png'),
                                  ),
                          ),
                          child: const SizedBox(
                            width: double.infinity,
                            height: 200,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ));

          choiceRow.addAll(listNamesFields(screenData.options![optionIndex].choices[choiceIndex].names, "choice_name"));
          choiceRow.add(Padding(
            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
            child: TextField(
              readOnly: !isEditMode,
              onChanged: (value) {
                isDataChange = true;
                screenData.options![optionIndex].choices[choiceIndex].price = value;
              },
              onSubmitted: (value) {
                findFocusNext(focusNodeIndex);
              },
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [global.NumberInputFormatter()],
              focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
              controller: TextEditingController(text: screenData.options![optionIndex].choices[choiceIndex].price.toString()),
              decoration: InputDecoration(
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: const OutlineInputBorder(),
                labelText: global.language("choice_add_price_percent"),
              ),
            ),
          ));
          choiceRow.add(
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                focusNode: FocusNode(skipTraversal: true),
                title: Text(global.language("choice_is_stock")),
                value: screenData.options![optionIndex].choices[choiceIndex].isstock,
                onChanged: ((value) {
                  setState(() {
                    screenData.options![optionIndex].choices[choiceIndex].isstock = !screenData.options![optionIndex].choices[choiceIndex].isstock;
                  });
                }),
              ),
            ),
          );
          choiceRow.add(
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                focusNode: FocusNode(skipTraversal: true),
                title: Text(global.language("choice_is_select")),
                value: screenData.options![optionIndex].choices[choiceIndex].isdefault!,
                onChanged: ((value) {
                  setState(() {
                    screenData.options![optionIndex].choices[choiceIndex].isdefault = !screenData.options![optionIndex].choices[choiceIndex].isdefault!;
                  });
                }),
              ),
            ),
          );
          if (screenData.options![optionIndex].choices[choiceIndex].isstock) {
            choiceRow.add(Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: TextField(
                    readOnly: true,
                    onSubmitted: (value) {
                      findFocusNext(focusNodeIndex);
                    },
                    focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
                    textAlign: TextAlign.left,
                    controller: TextEditingController(
                        text:
                            "${screenData.options![optionIndex].choices[choiceIndex].refbarcode} ~ ${global.activeLangName(screenData.options![optionIndex].choices[choiceIndex].refbarcodenames!)}"),
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('[a-z A-Z 0-9 -]'))],
                    onChanged: (value) {
                      isDataChange = true;
                      screenData.options![optionIndex].choices[choiceIndex].refbarcode = value.toUpperCase();
                    },
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      suffixIcon: IconButton(
                        focusNode: FocusNode(skipTraversal: true),
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          String word = screenData.options![optionIndex].choices[choiceIndex].refbarcode;
                          barcodeSearch(word, optionIndex, choiceIndex);
                        },
                      ),
                      border: const OutlineInputBorder(),
                      labelText: global.language("barcode"),
                    ))));

            choiceRow.add(Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
              child: TextField(
                readOnly: !isEditMode,
                onChanged: (value) {
                  isDataChange = true;
                  screenData.options![optionIndex].choices[choiceIndex].qty = double.tryParse(value)!;
                },
                onSubmitted: (value) {
                  findFocusNext(focusNodeIndex);
                },
                textAlign: TextAlign.right,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [global.NumberInputFormatter()],
                focusNode: fieldFocusNodes[++focusNodeMax].focusNode,
                controller: TextEditingController(
                    text: (screenData.options![optionIndex].choices[choiceIndex].qty == 0) ? "" : screenData.options![optionIndex].choices[choiceIndex].qty.toString()),
                decoration: InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: const OutlineInputBorder(),
                  labelText: global.language("choice_stock_qty"),
                ),
              ),
            ));
          }
          choiceList.add(Column(children: choiceRow));
        }
        if (choiceList.isNotEmpty) {
          optionList.add(Container(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
              width: double.infinity,
              child: Container(
                  decoration: BoxDecoration(color: Colors.grey.shade200, border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(5)),
                  width: double.infinity,
                  child: Column(children: choiceList))));
        }
        if (isEditMode) {
          optionList.add(Container(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
              width: double.infinity,
              child: ElevatedButton(
                  focusNode: FocusNode(skipTraversal: true),
                  onPressed: () {
                    setState(() {
                      List<LanguageDataModel> names = [];
                      for (int k = 0; k < languageList.length; k++) {
                        names.add(LanguageDataModel(code: languageList[k].code!, name: ""));
                      }
                      screenData.options![optionIndex].choices.add(ProductChoiceModel(
                        guid: const Uuid().v4(),
                        refbarcode: "",
                        isstock: false,
                        isdefault: false,
                        refproductcode: "",
                        refunitcode: "",
                        names: names,
                        qty: 0,
                        price: "",
                      ));
                    });
                  },
                  child: Text(global.language("add_choice")))));
        }
        formWidgets.add(Container(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          width: double.infinity,
          child: Container(
              decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(5)),
              width: double.infinity,
              child: Column(
                children: optionList,
              )),
        ));
        if (screenData.options![optionIndex].choicetype == 0) {
          optionList.add(Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
              child: Row(children: [
                Expanded(
                    child: TextField(
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                        readOnly: true,
                        focusNode: FocusNode(skipTraversal: true),
                        textAlign: TextAlign.center,
                        controller: TextEditingController(text: screenData.options![optionIndex].minselect.toString()),
                        decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: const OutlineInputBorder(),
                            labelText: global.language("option_min_select_choice"),
                            prefixIcon: IconButton(
                                focusNode: FocusNode(skipTraversal: true),
                                icon: const Icon(Icons.arrow_downward),
                                onPressed: () {
                                  setState(() {
                                    if (screenData.options![optionIndex].minselect > 0) {
                                      screenData.options![optionIndex].minselect--;
                                    }
                                  });
                                }),
                            suffixIcon: IconButton(
                                focusNode: FocusNode(skipTraversal: true),
                                icon: const Icon(Icons.arrow_upward),
                                onPressed: () {
                                  setState(() {
                                    if (screenData.options![optionIndex].minselect <= screenData.options![optionIndex].choices.length) {
                                      screenData.options![optionIndex].minselect++;
                                    }
                                  });
                                })))),
                const SizedBox(width: 5),
                Expanded(
                    child: TextField(
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                        readOnly: true,
                        focusNode: FocusNode(skipTraversal: true),
                        textAlign: TextAlign.center,
                        controller: TextEditingController(text: screenData.options![optionIndex].maxselect.toString()),
                        decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            border: const OutlineInputBorder(),
                            labelText: global.language("option_max_select_choice"),
                            prefixIcon: IconButton(
                                focusNode: FocusNode(skipTraversal: true),
                                icon: const Icon(Icons.arrow_downward),
                                onPressed: () {
                                  setState(() {
                                    if (screenData.options![optionIndex].maxselect > 1) {
                                      screenData.options![optionIndex].maxselect--;
                                    }
                                  });
                                }),
                            suffixIcon: IconButton(
                                focusNode: FocusNode(skipTraversal: true),
                                icon: const Icon(Icons.arrow_upward),
                                onPressed: () {
                                  setState(() {
                                    if (screenData.options![optionIndex].maxselect <= screenData.options![optionIndex].choices.length) {
                                      screenData.options![optionIndex].maxselect++;
                                    }
                                  });
                                })))),
              ])));
        }
      }
    }

    formWidgets.add(
      Container(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
            focusNode: FocusNode(skipTraversal: true),
            onPressed: () {
              setState(() {
                List<LanguageDataModel> names = [];
                for (int k = 0; k < languageList.length; k++) {
                  names.add(LanguageDataModel(code: languageList[k].code!, name: ""));
                }
                screenData.options!.add(ProductOptionModel(guid: const Uuid().v4(), choicetype: 0, minselect: 1, maxselect: 1, names: names, choices: []));
              });
            },
            child: Text(global.language("add_option"))),
      ),
    );

    formWidgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Radio(
              focusNode: FocusNode(skipTraversal: true),
              value: true,
              groupValue: screenData.useimageorcolor,
              onChanged: (value) {
                if (isEditMode) {
                  setState(() {
                    screenData.useimageorcolor = true;
                  });
                }
              },
            ),
            const Text("ใช้รูปภาพ"),
            const SizedBox(width: 10),
            Radio(
              focusNode: FocusNode(skipTraversal: true),
              value: false,
              groupValue: screenData.useimageorcolor,
              onChanged: (value) {
                if (isEditMode) {
                  setState(() {
                    screenData.useimageorcolor = false;
                  });
                }
              },
            ),
            const Text("ใช้สี"),
          ],
        )));

    if (isEditMode) {
      if (screenData.useimageorcolor!) {
        formWidgets.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                  child: ElevatedButton.icon(
                focusNode: FocusNode(skipTraversal: true),
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    imageWeb = null;
                    imageFile = File('');
                    screenData.imageuri = "";
                  });
                },
                icon: const Icon(
                  Icons.delete,
                ),
                label: Text(global.language('delete_picture')),
              )),
              const SizedBox(width: 5),
              Expanded(
                  child: ElevatedButton.icon(
                focusNode: FocusNode(skipTraversal: true),
                onPressed: (kIsWeb)
                    ? () async {
                        FocusScope.of(context).unfocus();
                        XFile? image = await imagePicker.pickImage(source: ImageSource.gallery, maxHeight: 480, maxWidth: 640, imageQuality: 60);
                        if (image != null) {
                          var f = await image.readAsBytes();
                          setState(() {
                            imageWeb = f;
                            imageFile = File(image.path);
                          });
                        }
                      }
                    : () {
                        FocusScope.of(context).unfocus();
                        setState(() async {
                          final XFile? photo = await imagePicker.pickImage(source: ImageSource.gallery, maxHeight: 480, maxWidth: 640, imageQuality: 60);
                          if (photo != null) {
                            var f = await photo.readAsBytes();
                            setState(() {
                              imageWeb = f;
                              imageFile = File(photo.path);
                            });
                          }
                        });
                      },
                icon: const Icon(
                  Icons.folder,
                ),
                label: Text(global.language("select_picture")),
              )),
              const SizedBox(width: 5),
              if (kIsWeb == false)
                Expanded(
                    child: ElevatedButton.icon(
                  focusNode: FocusNode(skipTraversal: true),
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    final XFile? photo = await imagePicker.pickImage(source: ImageSource.camera, maxHeight: 480, maxWidth: 640, imageQuality: 60);
                    if (photo != null) {
                      var f = await photo.readAsBytes();
                      setState(() {
                        imageWeb = f;
                        imageFile = File(photo.path);
                      });
                    }
                  },
                  icon: const Icon(
                    Icons.camera_alt,
                  ),
                  label: Text(global.language('take_photo')),
                )),
            ],
          ),
        ));
      }
    }
    if (screenData.useimageorcolor!) {
      formWidgets.add(Container(
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          width: double.infinity,
          height: 300,
          child: Stack(children: [
            if (kIsWeb)
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
                    imageWeb = bytes;
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
                image: (imageWeb != null)
                    ? DecorationImage(image: MemoryImage(imageWeb!), fit: BoxFit.fill)
                    : (screenData.imageuri != '')
                        ? DecorationImage(
                            image: NetworkImage(screenData.imageuri!),
                          )
                        : const DecorationImage(
                            image: AssetImage('assets/img/noimage.png'),
                          ),
              ),
              child: const SizedBox(
                width: double.infinity,
                height: 400,
              ),
            )),
          ])));
    } else {
      formWidgets.add(
        Container(
            margin: const EdgeInsets.all(8),
            width: double.infinity,
            decoration: BoxDecoration(color: colorSelected, border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(5)),
            child: Container(
                padding: const EdgeInsets.all(10),
                child: ColorPicker(
                  color: colorSelected,
                  padding: const EdgeInsets.all(0),
                  heading: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(5)),
                      child: Row(children: [
                        Container(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              'เลือกสี (เพื่อแสดงตัวอย่างสีในระบบ)',
                              style: Theme.of(context).textTheme.titleMedium,
                            )),
                        const Spacer(),
                        IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                colorSelected = Colors.white;
                              });
                            })
                      ])),
                  showColorName: true,
                  showColorCode: true,
                  onColorChanged: (Color colorValue) {
                    setState(() {
                      colorSelected = colorValue;
                      screenData.colorselect = colorValue.value.toString();
                      screenData.colorselecthex = colorValue.value.toRadixString(16).toString();
                    });
                  },
                  pickersEnabled: const <ColorPickerType, bool>{
                    ColorPickerType.both: true,
                    ColorPickerType.primary: true,
                    ColorPickerType.accent: true,
                    ColorPickerType.bw: false,
                    ColorPickerType.custom: true,
                    ColorPickerType.wheel: true,
                  },
                ))),
      );
    }

    formWidgets.add(
      Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                  child: TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: const OutlineInputBorder(),
                  labelText: global.language('disciption'),
                ),
                controller: descriptionTextEditController,
              )),
            ],
          ),
        ),
      ),
    );
    if (isSaveAllow) {
      formWidgets.add(Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
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
          title: Text(headerEdit + global.language("barcode")),
          actions: <Widget>[
            if (selectGuid.isNotEmpty)
              Tooltip(
                message: global.language("show_product_bom"),
                child: Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: IconButton(
                    focusNode: FocusNode(skipTraversal: true),
                    onPressed: () {
                      isPreviewBom = !isPreviewBom;
                      setState(() {});
                    },
                    icon: Icon(
                      (!isPreviewBom) ? Icons.account_tree_outlined : Icons.account_tree_rounded,
                    ),
                  ),
                ),
              ),
            (isPreview)
                ? Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: IconButton(
                      focusNode: FocusNode(skipTraversal: true),
                      onPressed: () {
                        isPreview = false;
                        isPreviewBom = false;
                        setState(() {});
                      },
                      icon: const Icon(
                        Icons.text_fields,
                      ),
                    ))
                : Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: IconButton(
                      focusNode: FocusNode(skipTraversal: true),
                      onPressed: () {
                        isPreview = true;
                        isPreviewBom = false;
                        setState(() {});
                      },
                      icon: const Icon(
                        Icons.preview,
                      ),
                    )),
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
                          title: Text(global.language('coppy_confirm')),
                          actions: <Widget>[
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context), child: Text(global.language('no'))),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                onPressed: () {
                                  Navigator.pop(context);

                                  discardData(callBack: () {
                                    setState(() {
                                      isEditMode = true;
                                      isPreview = false;
                                      selectGuid = "";
                                      showCheckBox = false;
                                      isDataChange = false;
                                      // clearEditData();
                                      screenData.guidfixed = "";
                                      screenData.barcode = "";
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
                                child: Text(global.language('confirm'))),
                          ],
                        ),
                      );
                      setState(() {});
                    },
                    icon: const Icon(
                      Icons.copy,
                    ),
                  )),
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
                                  context.read<ProductBarcodeBloc>().add(ProductBarcodeDelete(guid: selectGuid));
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
                      setState(() {
                        context.loaderOverlay.show(widgetBuilder: (progress) {
                          return const ReconnectingOverlay();
                        });
                        isLoadTranslation = true;
                      });
                      try {
                        await translateNames();
                        await translateOptions();
                        setState(() {
                          isLoadTranslation = false;
                          context.loaderOverlay.hide();
                        });
                      } catch (e) {
                        if (kDebugMode) {
                          print(e);
                        }
                      }
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
      body: LoaderOverlay(
        overlayColor: Colors.black.withOpacity(0.8),
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.f10) {
                if (_formKey.currentState!.validate()) {
                  saveOrUpdateData();
                }
              }
              // if (event.logicalKey == LogicalKeyboardKey.tab) {
              //   if (event.isShiftPressed) {
              //     //findFocusPrev(focusNodeIndex);
              //   } else {
              //     findFocusNext(focusNodeIndex);
              //   }
              // }
            }
          },
          child: SingleChildScrollView(
            controller: editScrollController,
            scrollDirection: Axis.vertical,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: (!isPreviewBom)
                  ? Form(
                      key: _formKey,
                      child: Column(
                        children: (isPreview) ? previewScreenWidget() : formWidgets,
                      ),
                    )
                  : ProductBomWidget(productBom: productBom),
            ),
          ),
        ),
      ),
    );
  }

  String productTypeName(int type) {
    String productTypeName = "";
    if (type == 0) {
      productTypeName = global.language("product_is_stock");
    } else if (type == 1) {
      productTypeName = global.language("product_is_service");
    } else if (type == 2) {
      productTypeName = global.language("product_is_set");
    } else if (type == 3) {
      productTypeName = global.language("product_is_material");
    }
    return productTypeName;
  }

  List<Widget> previewScreenWidget() {
    List<Widget> previewWidgets = [];

    previewWidgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: Center(
          child: Text(
            global.packName(screenData.names!),
            style: const TextStyle(fontSize: 17),
          ),
        )));
    previewWidgets.add(const Divider(
      height: 5,
      color: Colors.black,
    ));
    previewWidgets.add(Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("${global.language("barcode")} : ${screenData.barcode!}"),
            const SizedBox(width: 20),
            Text("${global.language("item_code")} : ${screenData.itemcode}"),
            const SizedBox(width: 20),
            Text("${global.language("unit")} : ${screenData.itemunitcode}|${global.packName(screenData.itemunitnames!)}"),
          ],
        ),
      ),
    ));

    previewWidgets.add(Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("${global.language("product_type")} : ${productTypeName(screenData.itemtype!)}"),
            const SizedBox(width: 20),
            Text("${global.language("vat_type")} : ${(screenData.vatcal == 0) ? global.language("product_vat_type_1") : global.language("product_vat_type_2")}"),
            const SizedBox(width: 20),
            Text("${global.language("issumpoint")} : ${(!screenData.issumpoint!) ? global.language("product_use_point_1") : global.language("product_use_point_2")}"),
          ],
        ),
      ),
    ));

    previewWidgets.add(Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("${global.language("isdividend")} : ${(!screenData.isdividend!) ? global.language("product_use_dividend_1") : global.language("product_use_dividend_2")} "),
            const SizedBox(width: 20),
            Text("${global.language("product_group_code")} : ${screenData.groupcode}~${global.packName(screenData.groupnames!)}"),
          ],
        ),
      ),
    ));

    previewWidgets.add(const Divider(
      height: 5,
      color: Colors.black,
    ));
    List<Widget> priceListWidget = [];
    for (int priceIndex = 0; priceIndex < priceList.length; priceIndex++) {
      priceListWidget
          .add(Text("${priceList[priceIndex].names[0].name} : ${(screenData.prices![priceIndex].price == 0.0) ? "0" : screenData.prices![priceIndex].price.toString()}"));
      if (priceIndex != priceList.length - 1) {
        priceListWidget.add(const SizedBox(width: 20));
      }
    }

    previewWidgets.add(Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: priceListWidget,
        ),
      ),
    ));
    previewWidgets.add(const Divider(
      height: 5,
      color: Colors.black,
    ));

    previewWidgets.add(Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text("${global.language("discount")} : ${screenData.discount!}"),
      ),
    ));
    previewWidgets.add(const Divider(
      height: 5,
      color: Colors.black,
    ));

    if (screenData.isusesubbarcodes!) {
      previewWidgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
        child: Text("${global.language("reference_barcode")} :"),
      ));
      for (int i = 0; i < screenData.refbarcodes!.length; i++) {
        var data = screenData.refbarcodes![i];
        previewWidgets.add(Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (data.barcode.isEmpty)
                      ? "${global.language("barcode")} / ${global.language("item_name")} / ${global.language("unit_name")}"
                      : "${data.barcode} / ${global.packName(data.names)} / ${global.packName(data.itemunitnames)}",
                ),
                Text(
                  (!data.condition)
                      ? "${data.qty}${global.activeLangName(data.itemunitnames)} = 1 ${global.activeLangName(screenData.itemunitnames!)}"
                      : "1 ${global.activeLangName(data.itemunitnames)} = ${data.qty} ${global.activeLangName(screenData.itemunitnames!)}",
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),
        ));
        previewWidgets.add(const Divider(
          height: 5,
          color: Colors.black,
        ));
      }
    }
    if (screenData.isalacarte == true) {
      previewWidgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
        child: Row(
          children: [
            Text(global.language("product_is_alacarte")),
          ],
        ),
      ));
    }
    if (screenData.isdiscountpointofpurchase == true) {
      previewWidgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
        child: Row(
          children: [
            Text(global.language("is_discount_point_of_purchase")),
          ],
        ),
      ));
    }

    if (screenData.restaurant!.isforrestaurant == true) {
      previewWidgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
        child: Row(
          children: [
            Text(global.language("is_for_restaurant")),
          ],
        ),
      ));
    }

    if (screenData.restaurant!.isfortakeaway == true) {
      previewWidgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
        child: Row(
          children: [
            Text(global.language("is_for_takeaway")),
          ],
        ),
      ));
    }

    if (screenData.restaurant!.isfordelivery == true) {
      previewWidgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
        child: Row(
          children: [
            Text(global.language("is_for_delivery")),
          ],
        ),
      ));
    }

    if (screenData.restaurant!.isforcustomer == true) {
      previewWidgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
        child: Row(
          children: [
            Text(global.language("is_for_customer")),
          ],
        ),
      ));
    }

    if (screenData.restaurant!.isforcustomerpreorder == true) {
      previewWidgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
        child: Row(
          children: [
            Text(global.language("is_for_customer_preorder")),
          ],
        ),
      ));
    }

    if (screenData.isstockforrestaurant == true) {
      previewWidgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
        child: Row(
          children: [
            Text(global.language("is_stock_for_restaurant")),
          ],
        ),
      ));
    }

    if (screenData.issplitunitprint == true) {
      previewWidgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
        child: Row(
          children: [
            Text(global.language("is_split_unit_print")),
          ],
        ),
      ));
    }

    if (screenData.isonlystaff == true) {
      previewWidgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
        child: Row(
          children: [
            Text(global.language("is_only_employee")),
          ],
        ),
      ));
    }

    if (screenData.isalert == true) {
      previewWidgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
        child: Row(
          children: [
            Text('${global.language("is_use_alert")} : ${screenData.alertdescription}'),
          ],
        ),
      ));
    }

    if (screenData.ordertypes!.isNotEmpty) {
      for (int i = 0; i < screenData.ordertypes!.length; i++) {
        var data = screenData.ordertypes![i];
        previewWidgets.add(Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${global.language("order_type")} : "),
                Text(
                  (data.code.isEmpty)
                      ? "${global.language("barcode")} / ${global.language("item_name")} }"
                      : "${data.code} / ${global.packName(data.names)} ${global.language("charge_price")} /",
                ),
                Text(
                  "  ${data.price}",
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),
        ));
        previewWidgets.add(const Divider(
          height: 5,
          color: Colors.black,
        ));
      }
    }
    if (screenData.options!.isNotEmpty) {
      for (int optionIndex = 0; optionIndex < screenData.options!.length; optionIndex++) {
        previewWidgets.add(
          Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text("${global.language("option")} ${optionIndex + 1}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(
                      width: 15,
                    ),
                    Text(global.packName(screenData.options![optionIndex].names)),
                    const SizedBox(
                      width: 15,
                    ),
                    Text((screenData.options![optionIndex].choicetype == 0)
                        ? global.language("product_option_choice_type_multi")
                        : global.language("product_option_choice_type_single")),
                    const SizedBox(
                      width: 15,
                    ),
                    if (screenData.options![optionIndex].choicetype == 0) Text("${global.language("option_min_select_choice")}:${screenData.options![optionIndex].minselect}"),
                    const SizedBox(
                      width: 10,
                    ),
                    if (screenData.options![optionIndex].choicetype == 0) Text("${global.language("option_max_select_choice")}:${screenData.options![optionIndex].maxselect}"),
                  ],
                ),
              )),
        );

        for (int choiceIndex = 0; choiceIndex < screenData.options![optionIndex].choices.length; choiceIndex++) {
          previewWidgets.add(
            Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 20, right: 10, bottom: 10),
                child: Row(
                  children: [
                    Text("${global.language("choice")} ${choiceIndex + 1}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(
                      width: 15,
                    ),
                    Text(global.packName(screenData.options![optionIndex].choices[choiceIndex].names)),
                    const SizedBox(
                      width: 15,
                    ),
                    Text((screenData.options![optionIndex].choices[choiceIndex].isstock) ? global.language("choice_is_stock") : global.language("choice_no_stock")),
                    const SizedBox(
                      width: 15,
                    ),
                    Text((screenData.options![optionIndex].choices[choiceIndex].isstock) ? global.language("choice_is_select") : ""),
                    Expanded(
                        child: Text(
                      "${global.language("price")}: ${screenData.options![optionIndex].choices[choiceIndex].price}",
                      textAlign: TextAlign.right,
                    )),
                  ],
                )),
          );
          if (screenData.options![optionIndex].choices[choiceIndex].isstock) {
            previewWidgets.add(
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 30, right: 10, bottom: 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                          "${global.language("barcode")}:${screenData.options![optionIndex].choices[choiceIndex].refbarcode} ~ ${global.activeLangName(screenData.options![optionIndex].choices[choiceIndex].refbarcodenames!)}"),
                      const SizedBox(
                        width: 15,
                      ),
                      if (screenData.options![optionIndex].choices[choiceIndex].refproductcode.isNotEmpty)
                        Text("${global.language("product_code")}:${screenData.options![optionIndex].choices[choiceIndex].refproductcode}"),
                      const SizedBox(
                        width: 15,
                      ),
                      Text(
                          "${global.language("unit")}:${screenData.options![optionIndex].choices[choiceIndex].refunitcode} ~ ${global.activeLangName(screenData.options![optionIndex].choices[choiceIndex].refunitnames!)}"),
                      const SizedBox(
                        width: 15,
                      ),
                      Text(
                        "${global.language("qty")}:${screenData.options![optionIndex].choices[choiceIndex].qty}",
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        }

        previewWidgets.add(const Divider(
          height: 5,
          color: Colors.black,
        ));
      }
    }

    previewWidgets.add(
      Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10, top: 10),
        child: Center(
            child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(5),
            image: (imageWeb != null)
                ? DecorationImage(image: MemoryImage(imageWeb!), fit: BoxFit.fill)
                : (screenData.imageuri != '')
                    ? DecorationImage(
                        image: NetworkImage(screenData.imageuri!),
                      )
                    : const DecorationImage(image: AssetImage('assets/img/noimage.png')),
          ),
          child: const SizedBox(
            width: double.infinity,
            height: 360,
          ),
        )),
      ),
    );

    return previewWidgets;
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
                BlocListener<ProductBarcodeBloc, ProductBarcodeState>(
                  listener: (context, state) {
                    blocCurrentState = state;
                    // Load
                    if (state is ProductBarcodeLoadSuccess) {
                      removeTooltip();
                      setState(() {
                        loadingData = false;
                      });
                      if (state.productBarcodes.isNotEmpty) {
                        for (int i = 0; i < state.productBarcodes.length; i++) {
                          List<CompanyBranchModel> listDataBranchInBusinessType = [];

                          /// find branch in listDataBranchAll where state.productBarcodes[i].businesstypes = listDataBranchAll[j].businesstype
                          for (int j = 0; j < state.productBarcodes[i].businesstypes!.length; j++) {
                            listDataBranchInBusinessType
                                .addAll(listDataBranchAll.where((element) => element.businesstype!.guidfixed == state.productBarcodes[i].businesstypes![j].guidfixed));
                          }

                          state.productBarcodes[i].branches = listDataBranchInBusinessType
                              .where(
                                (element) => !state.productBarcodes[i].ignorebranches!.any(
                                  (ignoreBranch) => element.guidfixed == ignoreBranch.guidfixed,
                                ),
                              )
                              .toList();
                        }
                        setState(() {
                          listData.addAll(state.productBarcodes);
                        });
                      }
                      tooltipKeys.clear();
                      for (int i = 0; i < listData.length; i++) {
                        tooltipKeys.add(GlobalKey<ImageTooltipState>());
                      }
                    }
                    if (state is ProductBarcodeLoadFailed) {
                      setState(() {
                        loadingData = false;
                        global.showSnackBar(
                            context,
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                            ),
                            state.message,
                            Colors.red);
                      });
                    }
                    // Save
                    if (state is ProductBarcodeSaveSuccess) {
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
                        listData = [];
                      });
                      loadDataList(searchText, filterBarcode);
                    }
                    if (state is ProductBarcodeSaveFailed) {
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
                    if (state is ProductBarcodeUpdateSuccess) {
                      global.showSnackBar(
                          context,
                          const Icon(
                            Icons.edit,
                            color: Colors.white,
                          ),
                          global.language("edit_success"),
                          Colors.blue);
                      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                        tabController.animateTo(0);
                      });
                      isSaveAllow = false;

                      /// set data in listData update listData filtter guidfixed = screenData.guidfixed
                      listData[listData.indexWhere((element) => element.guidfixed == screenData.guidfixed)] = screenData;
                      listData = [];
                      loadDataList(searchText, filterBarcode);

                      getData(screenData.guidfixed);
                    }
                    if (state is ProductBarcodeUpdateFailed) {
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
                    if (state is ProductBarcodeDeleteSuccess) {
                      setState(() {
                        global.showSnackBar(
                            context,
                            const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                            global.language("delete_success"),
                            Colors.blue);
                        listData = [];
                        clearEditData();
                        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                          tabController.animateTo(0);
                        });
                        loadDataList(searchText, filterBarcode);
                      });
                    } else if (state is ProductBarcodeDeleteFailed) {
                      setState(() {
                        global.showSnackBar(
                            context,
                            const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                            "${global.language("not_delete_success")} : ${state.message}",
                            Colors.red);
                      });
                    }
                    // Delete Many
                    if (state is ProductBarcodeDeleteManySuccess) {
                      setState(() {
                        global.showSnackBar(
                            context,
                            const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                            "${global.language("not_delete_success")} : ${state.message}",
                            Colors.blue);
                        listData = [];
                        clearEditData();
                        loadDataList(searchText, filterBarcode);
                        showCheckBox = false;
                      });
                    } else if (state is ProductBarcodeDeleteManyFailed) {
                      setState(() {
                        global.showSnackBar(
                            context,
                            const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                            "${global.language("not_delete_success")} : ${state.message}",
                            Colors.red);
                      });
                    }
                    // Get
                    if (state is ProductBarcodeGetSuccess) {
                      removeTooltip();

                      setState(() {
                        isDataChange = false;

                        screenData = state.productBarcode;
                        barcodeController.text = screenData.barcode!;

                        if (screenData.dimensions!.isNotEmpty) {
                          for (int i = 0; i < screenData.dimensions!.length; i++) {
                            context.read<ProductDimensionBloc>().add(ProductDimensionGet(guid: screenData.dimensions![i].guidfixed!));
                          }
                        }

                        if (screenData.manufacturerguid!.isNotEmpty) {
                          context.read<CreditorBloc>().add(CreditorGet(guid: screenData.manufacturerguid!));
                        }

                        ///ไม่ใช่ชุด
                        if (screenData.itemtype != 2) {
                          if (screenData.refbarcodes!.isNotEmpty) {
                            if (!screenData.refbarcodes![0].condition) {
                              screenData.refbarcodes![0].qty = screenData.refbarcodes![0].standvalue;
                            } else {
                              screenData.refbarcodes![0].qty = screenData.refbarcodes![0].dividevalue;
                            }
                          }
                        }

                        if (screenData.description!.isNotEmpty) {
                          descriptionTextEditController.text = screenData.description!;
                        }

                        if (screenData.alertdescription!.isNotEmpty) {
                          alertDescriptionTextEditController.text = screenData.alertdescription!;
                        }

                        /// remove screenData.prices where keynumber not in priceList
                        screenData.prices!.removeWhere((element) => !priceList.any((price) => price.keyNumber == element.keynumber));

                        for (int priceIndex = 0; priceIndex < priceList.length; priceIndex++) {
                          PriceDataModel priceData = screenData.prices!
                              .firstWhere((element) => element.keynumber == priceList[priceIndex].keyNumber, orElse: () => PriceDataModel(keynumber: -1, price: 0));
                          if (priceData.keynumber < 0) {
                            screenData.prices!.add(PriceDataModel(keynumber: priceList[priceIndex].keyNumber, price: 0));
                          }
                        }
                        colorSelected = global.colorFromHex(screenData.colorselecthex!.replaceAll("#", ""));

                        /// load สาขาตามประเภทธุรกิจ
                        loadDataBranchList(screenData.businesstypes!);

                        if (screenData.bom!.isNotEmpty) {
                          context.read<ProductBarcodeBloc>().add(ProductBarcodeGetBom(barcode: screenData.barcode!));
                        } else {
                          productBom = ProductBomModel(
                            guidfixed: '',
                            names: [],
                            itemunitcode: '',
                            itemunitnames: [],
                            barcode: '',
                            condition: false,
                            dividevalue: 0,
                            standvalue: 0,
                            qty: 0,
                            imageuri: '',
                            bom: [],
                          );
                        }

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

                    // Get Bom
                    if (state is ProductBarcodeGetBomInProgress) {
                      context.loaderOverlay.show(widgetBuilder: (progress) {
                        return const ReconnectingOverlay();
                      });
                    } else if (state is ProductBarcodeGetBomSuccess) {
                      context.loaderOverlay.hide();
                      setState(() {
                        productBom = state.productBom;
                        productBom.qty = 1;
                      });
                    } else if (state is ProductBarcodeGetBomFailed) {
                      context.loaderOverlay.hide();
                      global.showSnackBar(
                          context,
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                          ),
                          state.message,
                          Colors.red);
                    }
                  },
                ),
                BlocListener<CompanyBranchBloc, CompanyBranchState>(listener: (context, state) {
                  if (state is CompanyBranchLoadSuccess) {
                    setState(() {
                      listDataBranchAll = state.companyBranch;
                    });
                  }
                  if (state is CompanyBranchByBusinessTypeLoadSuccess) {
                    // Add elements to listDataBranchBusinessType only if guidfixed is not empty
                    listDataBranchBusinessType.addAll(
                      state.companyBranch.where((element) => element.guidfixed.isNotEmpty).map((element) => BranchModel(
                            guidfixed: element.guidfixed,
                            code: element.code,
                            names: element.names,
                            isignore: false,
                          )),
                    );

                    setState(() {
                      ignorebranches = [];
                      if (screenData.ignorebranches!.isNotEmpty) {
                        for (var element in listDataBranchBusinessType) {
                          if (screenData.ignorebranches!.any((ignoreBranch) => ignoreBranch.code != element.code)) {
                            ignorebranches!.add(element);
                          }
                        }
                      } else {
                        ignorebranches!.addAll(listDataBranchBusinessType);
                      }
                    });
                  }
                }),

                BlocListener<UnitBloc, UnitState>(listener: (context, state) {
                  if (state is UnitLoadSuccess) {
                    setState(() {
                      if (state.units.isNotEmpty) {
                        unitListData.addAll(state.units);
                      }
                    });
                  }
                }),
                BlocListener<ImageUploadBloc, ImageUploadState>(listener: (context, state) {
                  if (state is ImageUploadSaveSuccess) {
                    setState(() {
                      screenData.options![uploadImageOptionIndex].choices[uploadImageChoiceIndex].imageuri = state.imageUpload.uri;
                    });
                  }
                }),
                BlocListener<CreditorBloc, CreditorState>(listener: (context, state) {
                  if (state is CreditorGetSuccess) {
                    setState(() {
                      screenData.manufacturer!.guid = state.creditors.guidfixed;
                      screenData.manufacturer!.code = state.creditors.code;
                      screenData.manufacturer!.names = state.creditors.names;
                    });
                  }
                }),
                BlocListener<ProductDimensionBloc, ProductDimensionState>(listener: (context, state) {
                  if (state is ProductDimensionGetSuccess) {
                    setState(() {
                      for (int i = 0; i < screenData.dimensions!.length; i++) {
                        dimensionSeleted.add(
                          DimensionModel(
                            guidfixed: screenData.dimensions![i].guidfixed,
                            names: screenData.dimensions![i].names,
                            isdisabled: screenData.dimensions![i].isdisabled,
                            items: state.productDimension.items,
                          ),
                        );
                      }
                    });
                  }
                }),

                /// BusinessTypeBloc
                BlocListener<BusinessTypeBloc, BusinessTypeState>(listener: (context, state) {
                  if (state is BusinessTypeLoadSuccess) {
                    setState(() {
                      if (state.businessType.isNotEmpty) {
                        listDataBusinessType.addAll(state.businessType);
                      }
                    });
                  }
                }),
              ],
              child: (constraints.maxWidth > 800)
                  ? SplitView(
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

  List<Widget> listNamesFields(List<LanguageDataModel> names, String fieldname) {
    List<Widget> forms = [];
    for (int languageIndex = 0; languageIndex < languageList.length; languageIndex++) {
      LanguageDataModel nameObj = names.firstWhere((element) => element.code == languageList[languageIndex].code, orElse: () => LanguageDataModel(code: '', name: ''));
      if (nameObj.code == '') {
        names.add(LanguageDataModel(code: languageList[languageIndex].code!, name: ''));
      }
    }
    for (int languageIndex = 0; languageIndex < languageList.length; languageIndex++) {
      LanguageDataModel nameObj = names.firstWhere((element) => element.code == languageList[languageIndex].code, orElse: () => LanguageDataModel(code: '', name: ''));
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
    }

    return forms;
  }
}
