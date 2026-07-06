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
import 'package:cocomerchant_lite/screens/product/components/price_fields.dart';
import 'package:cocomerchant_lite/screens/product/components/product_type_dropdown.dart';
import 'package:cocomerchant_lite/screens/product/components/switch_form_field.dart';
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
  static String routeName = "/productbarcode";
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
  Set<String> expandedItems = <String>{}; // เพิ่มตัวแปรเพื่อเก็บสถานะการขยาย
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
  bool showImage = true;
  bool useReferenceBarcode = false;
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
              icon: const FaIcon(FontAwesomeIcons.font),
              onPressed: () async {
                setState(() {
                  global.listDataFontSizeChange();
                });
              }),
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
            ),

          /// เพิ่มข้อมูลใหม่
          IconButton(
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
          ),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
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
                itemCount: listData.length,
                itemBuilder: (context, index) => listObject(index, listData[index], showCheckBox),
              ),
            ),
            if (loadingData)
              Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.blue,
                  size: 50,
                ),
              )
          ],
        ),
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
    bool isCheck = guidListChecked.contains(value.guidfixed);
    bool isSelected = selectGuid == value.guidfixed;
    bool isExpanded = expandedItems.contains(value.guidfixed);

    return Card(
      key: listKeys[index],
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      child: Column(
        children: [
          InkWell(
            onTap: () => _handleCardTap(value, isCheck),
            onLongPress: () => _handleCardLongPress(value),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showImage && value.imageuri != null && value.imageuri!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        value.imageuri!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value.barcode ?? '',
                          style: TextStyle(
                            fontSize: global.deviceConfig.listDataFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${global.packName(value.names!)} / ${global.language("unit")}: ${global.packName(value.itemunitnames!)}',
                          style: TextStyle(fontSize: global.deviceConfig.listDataFontSize - 2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${global.language("price")}: ${global.formatNumber(value.prices![0].price)}',
                          style: TextStyle(fontSize: global.deviceConfig.listDataFontSize - 2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (showCheckBox)
                    Checkbox(
                      value: isCheck,
                      onChanged: (bool? newValue) => _handleCheckboxChange(value, newValue),
                    ),
                  IconButton(
                    icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          expandedItems.remove(value.guidfixed);
                        } else {
                          expandedItems.add(value.guidfixed);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded && filterBarcode.branch == false)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: _buildChipWrap(value.branches!),
            ),
        ],
      ),
    );
  }

  Widget _buildChipWrap(List<CompanyBranchModel> branches) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: branches
          .map((branch) => Chip(
                label: Text(
                  '${branch.code} - ${global.activeLangName(branch.names)}',
                  style: TextStyle(fontSize: global.deviceConfig.listDataFontSize - 4),
                ),
                backgroundColor: Colors.grey[200],
                padding: const EdgeInsets.all(4),
              ))
          .toList(),
    );
  }

  void _handleCardTap(ProductBarcodeModel value, bool isCheck) {
    if (showCheckBox) {
      setState(() {
        if (isCheck) {
          guidListChecked.remove(value.guidfixed);
        } else {
          guidListChecked.add(value.guidfixed);
        }
        global.showSnackBar(
          context,
          const Icon(Icons.check, color: Colors.white),
          "${global.language("chosen")} ${guidListChecked.length} ${global.language("list")}",
          Colors.blue,
        );
      });
    } else {
      discardData(callBack: () {
        setState(() {
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
  }

  void _handleCardLongPress(ProductBarcodeModel value) {
    if (!showCheckBox) {
      setState(() {
        switchToEdit(value);
      });
    }
  }

  void _handleCheckboxChange(ProductBarcodeModel value, bool? newValue) {
    setState(() {
      if (newValue == true) {
        guidListChecked.add(value.guidfixed);
      } else {
        guidListChecked.remove(value.guidfixed);
      }
    });
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
            builder: (context) => const UnitSearchScreen(
                  word: "",
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

  Widget unitTextEditWidget({
    required String label,
    required String unitCode,
    required List<LanguageDataModel> unitNames,
    required bool isReadOnly,
    required bool enableIcon,
    required TextEditingController unitCodeController,
    required TextEditingController unitNameController,
    required Function callBack,
  }) {
    return Row(
      children: [
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
        // const SizedBox(width: 5),
        // Expanded(
        //   child: TextFormField(
        //     readOnly: true,
        //     focusNode: null,
        //     textAlign: TextAlign.left,
        //     controller: unitNameController,
        //     decoration: InputDecoration(
        //       contentPadding: const EdgeInsets.all(10.0),
        //       enabledBorder: const OutlineInputBorder(
        //         borderSide: BorderSide(color: Colors.grey, width: 0.0),
        //       ),
        //       floatingLabelBehavior: FloatingLabelBehavior.always,
        //       border: const OutlineInputBorder(),
        //       labelText: global.language("name"),
        //     ),
        //     validator: (value) {
        //       if (value == null || value.isEmpty) {
        //         return 'This field is required';
        //       }
        //       return null;
        //     },
        //   ),
        // )
      ],
    );
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

  Widget editScreen({mobileScreen}) {
    List<Widget> formWidgets = [];
    List<Widget> groupMenuWidgets = [];

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
        child: SizedBox(
          height: 50,
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
      ),
    );
    // formWidgets.add(
    //   Padding(
    //     padding: const EdgeInsets.only(bottom: 5.0),
    //     child: LanguageNamesFields(
    //       names: screenData.names!,
    //       languageList: languageList,
    //       fieldName: "product_name",
    //       isEditMode: isEditMode,
    //       isLoadTranslation: isLoadTranslation,
    //       onChanged: (code, value) {
    //         setState(() {
    //           isDataChange = true;
    //           int index = screenData.names!.indexWhere((element) => element.code == code);
    //           if (index != -1) {
    //             screenData.names![index].name = value;
    //           }
    //         });
    //       },
    //     ),
    //   ),
    // );

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

    formWidgets.add(
      PriceFields(
        prices: screenData.prices!,
        priceList: priceList,
        isEditMode: isEditMode,
        onChanged: (index, value) {
          setState(() {
            isDataChange = true;
            screenData.prices![index].price = value;
          });
        },
        onSubmitted: (index) {
          findFocusNext(focusNodeIndex);
        },
      ),
    );

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
              ProductTypeDropdown(
                value: screenData.itemtype ?? 0,
                isEditMode: isEditMode,
                onChanged: (newValue) {
                  if (newValue != null) {
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
                },
              ),

              ///  ใช้บาร์โค้ดอ้างอิง
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    ],
                  ),
                  (screenData.itemtype == 2 && screenData.isusesubbarcodes!)
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
                      : Container()
                ],
              ),
              (screenData.isusesubbarcodes!)
                  ? Center(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        );

        if (data.barcode.isNotEmpty) {
          bomBarcodes.add(
            Container(
              margin: const EdgeInsets.only(bottom: 10, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: global.language("product_boom"),
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
                ],
              ),
              (screenData.bom!.isNotEmpty)
                  ? Column(
                      children: [
                        SizedBox(
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
                        ),
                        Center(
                          child: Column(
                            children: bomBarcodes,
                          ),
                        ),
                      ],
                    )
                  : Container()
            ],
          ),
        ),
      ),
    );

    Widget buildFoodTypeDropdown() {
      return DropdownButtonFormField<int>(
        decoration: InputDecoration(
          labelText: global.language("food_type"),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
        value: screenData.foodtype,
        items: [
          DropdownMenuItem(
            value: 0,
            child: Text(global.language("food")),
          ),
          DropdownMenuItem(
            value: 1,
            child: Text(global.language("drink")),
          ),
          DropdownMenuItem(
            value: 2,
            child: Text(global.language("alcohol")),
          ),
          DropdownMenuItem(
            value: 3,
            child: Text(global.language("other")),
          ),
        ],
        onChanged: isEditMode
            ? (value) {
                setState(() {
                  screenData.foodtype = value;
                });
              }
            : null,
      );
    }

    ///  ประเภทอาหาร
    formWidgets.add(
      Container(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: buildFoodTypeDropdown(),
            ),
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
        child: Column(
          children: [
            SwitchFormField(
              value: screenData.isalacarte!,
              onChanged: (value) => setState(() => screenData.isalacarte = value),
              label: global.language("alacarte"),
            ),
            SwitchFormField(
              value: screenData.isstockforrestaurant!,
              onChanged: (value) => setState(() => screenData.isstockforrestaurant = value),
              label: global.language("is_stock_for_restaurant"),
            ),
            SwitchFormField(
              value: screenData.issplitunitprint!,
              onChanged: (value) => setState(() => screenData.issplitunitprint = value),
              label: global.language("is_split_unit_print"),
            ),
            SwitchFormField(
              value: screenData.isonlystaff!,
              onChanged: (value) => setState(() => screenData.isonlystaff = value),
              label: global.language("is_only_employee"),
            ),
            SwitchFormField(
              value: screenData.isdiscountpointofpurchase!,
              onChanged: (value) => setState(() => screenData.isdiscountpointofpurchase = value),
              label: global.language("is_discount_point_of_purchase"),
            ),
            SwitchFormField(
              value: screenData.restaurant!.isforrestaurant!,
              onChanged: (value) => setState(() => screenData.restaurant!.isforrestaurant = value),
              label: global.language("is_for_restaurant"),
            ),
            SwitchFormField(
              value: screenData.restaurant!.isfortakeaway!,
              onChanged: (value) => setState(() => screenData.restaurant!.isfortakeaway = value),
              label: global.language("is_for_takeaway"),
            ),
            SwitchFormField(
              value: screenData.restaurant!.isfordelivery!,
              onChanged: (value) => setState(() => screenData.restaurant!.isfordelivery = value),
              label: global.language("is_for_delivery"),
            ),
            SwitchFormField(
              value: screenData.restaurant!.isforcustomer!,
              onChanged: (value) => setState(() => screenData.restaurant!.isforcustomer = value),
              label: global.language("is_for_customer"),
            ),
            SwitchFormField(
              value: screenData.restaurant!.isforcustomerpreorder!,
              onChanged: (value) => setState(() => screenData.restaurant!.isforcustomerpreorder = value),
              label: global.language("is_for_customer_preorder"),
            ),
            SwitchWithTextField(
              value: screenData.isalert!,
              onChanged: (value) => setState(() => screenData.isalert = value),
              label: global.language("is_use_alert"),
              textController: alertDescriptionTextEditController,
            ),
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
          return '${businessTypeModel.code} - ${global.activeLangName(businessTypeModel.names!)}';
        },
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.only(left: 10, top: 10, bottom: 10, right: 10),
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
            return '${branchModel.code} - ${global.activeLangName(branchModel.names!)}';
          },
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.only(left: 10, top: 10, bottom: 10, right: 10),
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

        // optionList.add(
        //   LanguageNamesFields(
        //     names: screenData.options![optionIndex].names,
        //     languageList: languageList,
        //     fieldName: "option_name",
        //     isEditMode: isEditMode,
        //     isLoadTranslation: isLoadTranslation,
        //     onChanged: (code, value) {
        //       setState(() {
        //         isDataChange = true;
        //         int index = screenData.options![optionIndex].names.indexWhere((element) => element.code == code);
        //         if (index != -1) {
        //           screenData.options![optionIndex].names[index].name = value;
        //         }
        //       });
        //     },
        //   ),
        // );
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

          // choiceRow.add(
          //   LanguageNamesFields(
          //     names: screenData.options![optionIndex].choices[choiceIndex].names,
          //     languageList: languageList,
          //     fieldName: "choice_name",
          //     isEditMode: isEditMode,
          //     isLoadTranslation: isLoadTranslation,
          //     onChanged: (code, value) {
          //       setState(() {
          //         isDataChange = true;
          //         int index = screenData.options![optionIndex].choices[choiceIndex].names.indexWhere((element) => element.code == code);
          //         if (index != -1) {
          //           screenData.options![optionIndex].choices[choiceIndex].names[index].name = value;
          //         }
          //       });
          //     },
          //   ),
          // );
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
            if (selectGuid.isNotEmpty)
              IconButton(
                focusNode: FocusNode(skipTraversal: true),
                onPressed: () {
                  showCheckBox = false;
                  showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: Text(global.language('coppy_confirm')),
                      actions: <Widget>[
                        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context), child: Text(global.language('no'))),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            onPressed: () {
                              Navigator.pop(context);

                              discardData(callBack: () {
                                setState(() {
                                  isEditMode = true;
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
              ),
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
              ),
            if (isEditMode && global.systemLanguage.length > 1)
              IconButton(
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
                        children: formWidgets,
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

  @override
  Widget build(BuildContext context) {
    queryData = MediaQuery.of(context);
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
                          for (int i = listKeys.length; i < listData.length; i++) {
                            listKeys.add(GlobalKey());
                          }
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
