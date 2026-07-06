import 'dart:typed_data';

import 'package:cocomerchant_lite/bloc/image/image_upload_bloc.dart';
import 'package:cocomerchant_lite/bloc/product_barcode/product_barcode_bloc.dart';
import 'package:cocomerchant_lite/components/custom_delete_button.dart';
import 'package:cocomerchant_lite/components/custom_text_filed.dart';
import 'package:cocomerchant_lite/components/loadding_widget.dart';
import 'package:cocomerchant_lite/components/custom_save_button.dart';
import 'package:cocomerchant_lite/model/price_model.dart';
import 'package:cocomerchant_lite/components/language_names_fields.dart';
import 'package:cocomerchant_lite/screen_search/unit_search_screen.dart';
import 'package:cocomerchant_lite/screens/product/components/image_picker_widget.dart';
import 'package:cocomerchant_lite/screens/product/components/price_fields.dart';
import 'package:cocomerchant_lite/screens/product/components/select_type_bottom_sheet.dart';
import 'package:cocomerchant_lite/screens/product/components/switch_form_field.dart';
import 'package:cocomerchant_lite/screens/product/components/selector_field_widget.dart';
import 'package:cocomerchant_lite/screens/product/list_product_barcode_screen.dart';
import 'package:cocomerchant_lite/screens/product/product_options_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/model/product_model.dart';
import 'package:translator/translator.dart';

class AddProductBarcodeScreen extends StatefulWidget {
  static const routeName = '/add_product_barcode';
  final ProductBarcodeModel? productToEdit;

  const AddProductBarcodeScreen({Key? key, this.productToEdit}) : super(key: key);

  @override
  AddProductBarcodeScreenState createState() => AddProductBarcodeScreenState();
}

class AddProductBarcodeScreenState extends State<AddProductBarcodeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  Uint8List? _imageWeb;
  File? _image;
  String? _imageUrl;
  bool isImageUploading = false;

  bool isLoading = false;
  bool isLoadTranslation = false;
  final translator = GoogleTranslator();
  bool isEditMode = false;

  /// barcode
  final _barcodeController = TextEditingController();

  /// ชื่อสินค้า

  late List<TextEditingController> _nameControllers;
  List<LanguageDataModel> _names = [];
  List<LanguageModel> _languageList = [];

  /// ประเภทสินค้า
  int _selectedItemType = 0;

  /// หน่วยนับ

  String _selectedUnit = '';
  List<LanguageDataModel> _selectedUnitNames = [];

  /// ราคา
  List<PriceDataModel> _prices = [];
  List<PriceModel> _priceList = [];

  /// ประเภทสินค้า
  final List<Map<String, dynamic>> itemsTypes = [
    {"value": 0, "label": "product_is_stock"},
    {"value": 1, "label": "product_is_service"},
    {"value": 2, "label": "product_is_set"},
    {"value": 3, "label": "product_is_material"},
    {"value": 4, "label": "product_semi_finished"},
    {"value": 5, "label": "product_is_not_stock"},
  ];

  /// ประเภทอาหาร
  int _selectedFoodType = 0;

  /// ประเภทอาหาร
  final List<Map<String, dynamic>> foodsTypes = [
    {"value": 0, "label": "food"},
    {"value": 1, "label": "drink"},
    {"value": 2, "label": "alcohol"},
    {"value": 3, "label": "other"},
  ];

  /// ประเภทภาษี
  int _selectedVatType = 0;

  /// ประเภทภาษี
  final List<Map<String, dynamic>> vatTypes = [
    {"value": 0, "label": "product_vat_type_1"},
    {"value": 1, "label": "product_vat_type_2"},
  ];

  /// อลาคลาส
  bool _isalacarte = true;

  /// สต็อคสำหรับร้านอาหาร
  bool _isstockforrestaurant = false;

  /// พิมพ์ใบจัััดอาหารแบบแยก
  bool _issplitunitprint = true;

  /// แสดงเฉพาะพนักงาน
  bool _isonlystaff = false;

  /// ลดราคา ณ จุดขาย
  bool _isdiscountpointofpurchase = true;

  /// ทานที่ร้าน
  bool _isforrestaurant = true;

  /// กลับบ้าน
  bool _isfortakeaway = true;

  /// เดลิเวอรี่
  bool _isfordelivery = true;

  /// ลูกค้าสามารถสั่งได้
  bool _isforcustomer = true;

  /// ระบบสั่งอาหารล่วงหน้า
  bool _isforcustomerpreorder = true;

  /// รหัสสินค้า
  final _itemcode = TextEditingController();

  /// ส่วนลด
  final _discount = TextEditingController();

  /// หมายเหตุ
  final _description = TextEditingController();

  /// opstion สินค้า
  List<ProductOptionModel> _options = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    isEditMode = widget.productToEdit != null;
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
    });

    await global.setSystemLanguage(context);
    setState(() {
      _languageList = global.config.languages
          .where((language) => language.isuse == true)
          .map((language) => LanguageModel(
                code: language.code,
                codeTranslator: language.codeTranslator,
                name: language.name,
                isuse: language.isuse,
              ))
          .toList();
      _names = _languageList.map((language) => LanguageDataModel(code: language.code!, name: '')).toList();
      _priceList = global.config.prices;
      _prices = _priceList.map((price) => PriceDataModel(keynumber: price.keyNumber, price: 0.0)).toList();

      _nameControllers = List.generate(_languageList.length, (_) => TextEditingController());

      if (isEditMode) {
        _populateEditData();
      }

      isLoading = false;
    });
  }

  void _populateEditData() {
    final product = widget.productToEdit!;
    _barcodeController.text = product.barcode ?? '';
    _itemcode.text = product.itemcode ?? '';

    _names.clear();
    for (var controller in _nameControllers) {
      controller.clear();
    }

    for (var langModel in _languageList) {
      var productName = product.names?.firstWhere(
        (name) => name.code == langModel.code,
        orElse: () => LanguageDataModel(code: langModel.code!, name: ''),
      );
      _names.add(LanguageDataModel(code: langModel.code!, name: productName?.name ?? ''));
    }

    for (int i = 0; i < _names.length && i < _nameControllers.length; i++) {
      _nameControllers[i].text = _names[i].name;
    }

    _selectedUnit = product.itemunitcode ?? '';
    _selectedUnitNames = product.itemunitnames ?? [];

    // Update prices
    _prices.clear();
    for (var priceModel in _priceList) {
      var productPrice = product.prices?.firstWhere(
        (price) => price.keynumber == priceModel.keyNumber,
        orElse: () => PriceDataModel(keynumber: priceModel.keyNumber, price: 0.0),
      );
      _prices.add(PriceDataModel(keynumber: priceModel.keyNumber, price: productPrice?.price ?? 0.0));
    }
    _imageUrl = product.imageuri;

    _selectedItemType = product.itemtype ?? 0;
    _selectedFoodType = product.foodtype ?? 0;
    _selectedVatType = product.vattype ?? 0;

    _isalacarte = product.isalacarte ?? true;
    _isstockforrestaurant = product.isstockforrestaurant ?? false;
    _issplitunitprint = product.issplitunitprint ?? true;
    _isonlystaff = product.isonlystaff ?? false;
    _isdiscountpointofpurchase = product.isdiscountpointofpurchase ?? true;
    _isforrestaurant = product.restaurant!.isforrestaurant ?? true;
    _isfortakeaway = product.restaurant!.isfortakeaway ?? true;
    _isfordelivery = product.restaurant!.isfordelivery ?? true;
    _isforcustomer = product.restaurant!.isforcustomer ?? true;
    _isforcustomerpreorder = product.restaurant!.isforcustomerpreorder ?? true;

    _discount.text = product.discount ?? '';
    _description.text = product.description ?? '';

    /// options
    _options = product.options ?? [];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _barcodeController.dispose();
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _translateNames() async {
    setState(() {
      isLoadTranslation = true;
    });

    String sourceText = _nameControllers[0].text;
    if (sourceText.isNotEmpty) {
      for (int i = 1; i < _names.length; i++) {
        try {
          var translation = await translator.translate(sourceText, to: _languageList[i].codeTranslator!);
          setState(() {
            _names[i].name = translation.text;
            _nameControllers[i].text = translation.text;
          });
        } catch (e) {
          print('Translation error: $e');
          // Handle error (e.g., show a message to the user)
        }
      }
    }

    setState(() {
      isLoadTranslation = false;
    });
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      _imageWeb = await pickedFile.readAsBytes();

      setState(() {
        _image = File(pickedFile.path);
        _imageUrl = null;
        isImageUploading = true;
      });

      // ส่ง event เพื่ออัปโหลดรูปไปยัง ImageUploadBloc
      // ignore: use_build_context_synchronously
      context.read<ImageUploadBloc>().add(ImageUploadFileSaved(imageFiles: [_image!], imageWeb: [_imageWeb!]));
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
      _imageWeb = null;
      _imageUrl = null;
    });
  }

  Future<void> _selectUnit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UnitSearchScreen(word: ''),
      ),
    );

    if (result != null && !result.isCancel) {
      setState(() {
        _selectedUnit = result.code;
        _selectedUnitNames = result.names;
      });
    }
  }

  void _addOption() {
    setState(() {
      _options.add(ProductOptionModel(
        guid: '',
        names: _languageList.map((lang) => LanguageDataModel(code: lang.code!, name: '')).toList(),
        choicetype: 0,
        minselect: 0,
        maxselect: 1,
        choices: [],
      ));
    });
  }

  void _addChoice(int optionIndex) {
    setState(() {
      _options[optionIndex].choices.add(ProductChoiceModel(
            guid: '',
            imageuri: '',
            isdefault: false,
            isstock: true,
            names: _languageList.map((lang) => LanguageDataModel(code: lang.code!, name: '')).toList(),
            price: '0',
            qty: 0,
            refbarcode: '',
            refbarcodenames: [],
            refproductcode: '',
            refunitcode: '',
            refunitnames: [],
            vatcal: 0,
          ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductBarcodeBloc, ProductBarcodeState>(
      listener: (context, state) {
        if (state is ProductBarcodeDeleteInProgress) {
          setState(() {
            isLoading = true;
          });
        } else if (state is ProductBarcodeDeleteSuccess) {
          setState(() {
            isLoading = false;
            global.showSnackBar(
              context,
              const Icon(
                Icons.delete,
                color: Colors.white,
              ),
              global.language("delete_success"),
              Colors.green,
            );
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ListProductBarcodeScreen()), (route) => false);
          });
        } else if (state is ProductBarcodeDeleteFailed) {
          setState(() {
            isLoading = false;
            global.showSnackBar(
              context,
              const Icon(
                Icons.error,
                color: Colors.white,
              ),
              global.language("delete_failed ${state.message}"),
              Colors.red,
            );
          });
        } else if (state is ProductBarcodeUpdateInProgress) {
          setState(() {
            isLoading = true;
          });
        } else if (state is ProductBarcodeUpdateSuccess) {
          setState(() {
            isLoading = false;
          });
          global.showSnackBar(
            context,
            const Icon(
              Icons.check_circle,
              color: Colors.white,
            ),
            global.language("update_success"),
            Colors.green,
          );
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ListProductBarcodeScreen()), (route) => false);
        } else if (state is ProductBarcodeUpdateFailed) {
          setState(() {
            isLoading = false;
          });
          global.showSnackBar(
            context,
            const Icon(
              Icons.error,
              color: Colors.white,
            ),
            global.language("update_failed ${state.message}"),
            Colors.red,
          );
        } else if (state is ProductBarcodeSaveInProgress) {
          setState(() {
            isLoading = true;
          });
        } else if (state is ProductBarcodeSaveSuccess) {
          setState(() {
            isLoading = false;
          });
          global.showSnackBar(
            context,
            const Icon(
              Icons.save,
              color: Colors.white,
            ),
            global.language("save_success"),
            Colors.green,
          );
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const ListProductBarcodeScreen()), (route) => false);
        } else if (state is ProductBarcodeSaveFailed) {
          setState(() {
            isLoading = false;
          });
          global.showSnackBar(
            context,
            const Icon(
              Icons.error,
              color: Colors.white,
            ),
            global.language("save_failed ${state.message}"),
            Colors.red,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: kPrimaryColor,
            title: Text(isEditMode ? global.language('edit_product') : global.language('add_product'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.translate),
                onPressed: _translateNames,
              ),

              /// save สินค้า
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveProduct,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: global.language('main_info')),
                Tab(text: global.language('options')),
              ],
            ),
          ),
          body: Stack(
            children: [
              _languageList.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMainInfoTab(),
                        _buildOptionsTab(),
                      ],
                    ),
              LoadingWidget(isLoading: isLoading),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocConsumer<ImageUploadBloc, ImageUploadState>(
              listener: (context, state) {
                if (state is ImageUploadSaveInProgress) {
                  setState(() {
                    isImageUploading = true;
                  });
                } else if (state is ImageUploadSaveSuccess) {
                  setState(() {
                    isImageUploading = false;
                    _imageUrl = state.imageUpload.uri;
                  });
                } else if (state is ImageUploadSaveFailure) {
                  setState(() {
                    isImageUploading = false;
                  });
                  global.showSnackBar(
                    context,
                    const Icon(
                      Icons.error,
                      color: Colors.white,
                    ),
                    global.language("image_upload_failed ${state.message}"),
                    Colors.red,
                  );
                }
              },
              builder: (context, state) {
                return ImagePickerWidget(
                  image: _image,
                  imageUrl: _imageUrl,
                  imageWeb: _imageWeb, // ส่ง imageWeb ไปยัง ImagePickerWidget
                  onImagePicked: _getImage,
                  onImageRemoved: _removeImage,
                  isLoading: isImageUploading,
                );
              },
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _barcodeController,
              label: global.language('barcode'),
              icon: Icons.qr_code,
            ),
            const SizedBox(height: 16),
            LanguageNamesFields(
              names: _names,
              languageList: _languageList,
              fieldName: 'product_name',
              isEditMode: true,
              isLoadTranslation: isLoadTranslation,
              controllers: _nameControllers,
              onChanged: (code, value) {
                setState(() {
                  _names.firstWhere((element) => element.code == code).name = value;
                });
              },
            ),
            const SizedBox(height: 16),
            SelectorFieldWidget(
              selectedCode: _selectedUnit,
              selectedNames: _selectedUnitNames,
              onTap: _selectUnit,
              icon: Icons.straighten,
              label: global.language('unit'),
            ),
            const SizedBox(height: 16),
            PriceFields(
              prices: _prices,
              priceList: _priceList,
              isEditMode: true,
              onChanged: (index, value) {
                setState(() {
                  _prices[index].price = value;
                });
              },
              onSubmitted: (index) {
                // Handle on submitted
              },
            ),
            const SizedBox(height: 32),
            if (isEditMode)
              CustomDeleteButton(
                onDelete: () {
                  // Implement delete functionality
                  print('Item deleted with guid: ${widget.productToEdit!.guidfixed}');
                  context.read<ProductBarcodeBloc>().add(ProductBarcodeDelete(guid: widget.productToEdit!.guidfixed));
                },
              ),
            const SizedBox(height: 32),
            buildSaveButton(
              formKey: _formKey,
              onPressed: _saveProduct,
            ),
          ],
        ),
      ),
    );
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final product = ProductBarcodeModel(
        guidfixed: isEditMode ? widget.productToEdit!.guidfixed : '',
        barcode: _barcodeController.text,
        names: _names,
        itemunitcode: _selectedUnit,
        itemunitnames: _selectedUnitNames,
        prices: _prices,
        imageuri: _imageUrl,
        itemtype: _selectedItemType,
        foodtype: _selectedFoodType,
        vattype: _selectedVatType,
        isalacarte: _isalacarte,
        isstockforrestaurant: _isstockforrestaurant,
        issplitunitprint: _issplitunitprint,
        isonlystaff: _isonlystaff,
        isdiscountpointofpurchase: _isdiscountpointofpurchase,
        itemcode: _itemcode.text,
        discount: _discount.text,
        description: _description.text,
        options: _options,
      );

      product.restaurant!.isforrestaurant = _isforrestaurant;
      product.restaurant!.isfortakeaway = _isfortakeaway;
      product.restaurant!.isfordelivery = _isfordelivery;
      product.restaurant!.isforcustomer = _isforcustomer;
      product.restaurant!.isforcustomerpreorder = _isforcustomerpreorder;

      if (isEditMode) {
        print('Updating product: ${product.guidfixed}');

        context.read<ProductBarcodeBloc>().add(ProductBarcodeUpdate(guid: product.guidfixed, productBarcode: product));
      } else {
        print('Saving new product');

        context.read<ProductBarcodeBloc>().add(ProductBarcodeSave(productBarcode: product));
      }
    }
  }

  Widget _buildOptionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              global.language('product_options'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(global.language('product_type')),
              subtitle: Text(global.language(itemsTypes[_selectedItemType]['label'])),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.showSelectTypeBottomSheet(
                title: global.language('select_product_type'),
                types: itemsTypes,
                selectedType: _selectedItemType,
                onSelect: (value) => setState(() => _selectedItemType = value),
              ),
              tileColor: Colors.grey[200],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(global.language('food_type')),
              subtitle: Text(global.language(foodsTypes[_selectedFoodType]['label'])),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.showSelectTypeBottomSheet(
                title: global.language('select_food_type'),
                types: foodsTypes,
                selectedType: _selectedFoodType,
                onSelect: (value) => setState(() => _selectedFoodType = value),
              ),
              tileColor: Colors.grey[200],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(global.language('vat_type')),
              subtitle: Text(global.language(vatTypes[_selectedVatType]['label'])),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.showSelectTypeBottomSheet(
                title: global.language('select_vat_type'),
                types: vatTypes,
                selectedType: _selectedVatType,
                onSelect: (value) => setState(() => _selectedVatType = value),
              ),
              tileColor: Colors.grey[200],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  global.language('product_options'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _navigateToOptionsScreen,
                  child: Text(global.language('manage_options')),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // แสดงรายการตัวเลือกเสริม
            ..._options.map((option) => _buildOptionSummary(option)),

            const SizedBox(height: 16),
            SwitchFormField(
              value: _isalacarte,
              onChanged: (value) {
                setState(() {
                  _isalacarte = value;
                });
              },
              label: global.language('alacarte'),
            ),
            SwitchFormField(
              value: _isstockforrestaurant,
              onChanged: (value) {
                setState(() {
                  _isstockforrestaurant = value;
                });
              },
              label: global.language('is_stock_for_restaurant'),
            ),
            SwitchFormField(
              value: _issplitunitprint,
              onChanged: (value) {
                setState(() {
                  _issplitunitprint = value;
                });
              },
              label: global.language('is_split_unit_print'),
            ),
            SwitchFormField(
              value: _isonlystaff,
              onChanged: (value) {
                setState(() {
                  _isonlystaff = value;
                });
              },
              label: global.language('is_only_employee'),
            ),
            SwitchFormField(
              value: _isdiscountpointofpurchase,
              onChanged: (value) {
                setState(() {
                  _isdiscountpointofpurchase = value;
                });
              },
              label: global.language('is_discount_point_of_purchase'),
            ),
            SwitchFormField(
              value: _isforrestaurant,
              onChanged: (value) {
                setState(() {
                  _isforrestaurant = value;
                });
              },
              label: global.language('is_for_restaurant'),
            ),
            SwitchFormField(
              value: _isfortakeaway,
              onChanged: (value) {
                setState(() {
                  _isfortakeaway = value;
                });
              },
              label: global.language('is_for_takeaway'),
            ),
            SwitchFormField(
              value: _isfordelivery,
              onChanged: (value) {
                setState(() {
                  _isfordelivery = value;
                });
              },
              label: global.language('is_for_delivery'),
            ),
            SwitchFormField(
              value: _isforcustomer,
              onChanged: (value) {
                setState(() {
                  _isforcustomer = value;
                });
              },
              label: global.language('is_for_customer'),
            ),
            SwitchFormField(
              value: _isforcustomerpreorder,
              onChanged: (value) {
                setState(() {
                  _isforcustomerpreorder = value;
                });
              },
              label: global.language('is_for_customer_preorder'),
            ),

            /// item code
            const SizedBox(height: 16),
            CustomTextField(
              controller: _itemcode,
              label: global.language('item_code'),
              icon: Icons.code,
            ),

            /// discount
            const SizedBox(height: 16),
            CustomTextField(
              controller: _discount,
              label: global.language('discount'),
              icon: Icons.money,
            ),

            /// description
            const SizedBox(height: 16),
            CustomTextField(
              controller: _description,
              label: global.language('description'),
              icon: Icons.description,
            ),

            const SizedBox(height: 32),
            if (isEditMode)
              CustomDeleteButton(
                onDelete: () {
                  // Implement delete functionality
                  print('Item deleted with guid: ${widget.productToEdit!.guidfixed}');
                  context.read<ProductBarcodeBloc>().add(ProductBarcodeDelete(guid: widget.productToEdit!.guidfixed));
                },
              ),
            const SizedBox(height: 32),
            buildSaveButton(
              formKey: _formKey,
              onPressed: _saveProduct,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionSummary(ProductOptionModel option) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(option.names.first.name),
        subtitle: Text('${option.choices.length} ${global.language('choices')} ${option.choicetype == 0 ? global.language('single_choice') : global.language('multiple_choice')}'),
      ),
    );
  }

  void _navigateToOptionsScreen() async {
    final updatedOptions = await Navigator.push<List<ProductOptionModel>>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductOptionsScreen(
          options: _options,
          onOptionsUpdated: (options) => setState(() => _options = options),
        ),
      ),
    );

    if (updatedOptions != null) {
      setState(() {
        _options = updatedOptions;
      });
    }
  }
}
