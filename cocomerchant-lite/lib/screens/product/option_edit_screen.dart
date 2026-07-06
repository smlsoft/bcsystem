import 'dart:io';

import 'package:cocomerchant_lite/bloc/image/image_upload_bloc.dart';
import 'package:cocomerchant_lite/components/custom_number_filed.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/screen_search/product_search_screen.dart';
import 'package:cocomerchant_lite/screens/product/components/image_picker_widget.dart';
import 'package:cocomerchant_lite/screens/product/components/select_type_bottom_sheet.dart';
import 'package:cocomerchant_lite/screens/product/components/selector_field_widget.dart';
import 'package:cocomerchant_lite/screens/product/components/switch_form_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/model/product_model.dart';
import 'package:cocomerchant_lite/components/language_names_fields.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:translator/translator.dart';

class OptionEditScreen extends StatefulWidget {
  final ProductOptionModel? option;
  final Function(ProductOptionModel) onOptionUpdated;
  final bool isEditMode;

  const OptionEditScreen({
    Key? key,
    this.option,
    required this.onOptionUpdated,
    required this.isEditMode,
  }) : super(key: key);

  @override
  _OptionEditScreenState createState() => _OptionEditScreenState();
}

class _OptionEditScreenState extends State<OptionEditScreen> {
  late ProductOptionModel _option;
  final _formKey = GlobalKey<FormState>();
  List<LanguageModel> languageList = <LanguageModel>[];
  List<TextEditingController> optionNameTextController = [];
  bool isLoading = false;
  bool isLoadTranslation = false;
  final translator = GoogleTranslator();
  late List<List<TextEditingController>> choiceNameTextControllers;

  /// ประเภทตัวเลือก
  final List<Map<String, dynamic>> optionsTypes = [
    {"value": 0, "label": "product_option_choice_type_single"},
    {"value": 1, "label": "product_option_choice_type_multi"},
  ];

  @override
  void initState() {
    super.initState();
    _option = widget.isEditMode
        ? ProductOptionModel.from(widget.option!)
        : ProductOptionModel(
            guid: '',
            names: [],
            choicetype: 0,
            minselect: 0,
            maxselect: 1,
            choices: [],
          );
    setSystemLanguageList();
    initializeControllers();
  }

  @override
  void dispose() {
    for (var controller in optionNameTextController) {
      controller.dispose();
    }
    for (var controllerList in choiceNameTextControllers) {
      for (var controller in controllerList) {
        controller.dispose();
      }
    }
    for (var choice in _option.choices) {
      choice.image?.delete();
    }
    super.dispose();
  }

  void initializeControllers() {
    optionNameTextController = List.generate(
      _option.names.length,
      (index) => TextEditingController(text: _option.names[index].name),
    );

    choiceNameTextControllers = List.generate(
      _option.choices.length,
      (choiceIndex) => List.generate(
        _option.choices[choiceIndex].names.length,
        (nameIndex) => TextEditingController(text: _option.choices[choiceIndex].names[nameIndex].name),
      ),
    );
  }

  void setSystemLanguageList() async {
    setState(() {
      isLoading = true;
    });
    try {
      await global.setSystemLanguage(context);
      for (var lang in global.config.languages) {
        if (lang.isuse!) {
          languageList.add(lang);
        }
      }
      if (_option.names.isEmpty) {
        _option.names = languageList.map((language) => LanguageDataModel(code: language.code!, name: '')).toList();
      }
      optionNameTextController = List.generate(languageList.length, (index) => TextEditingController(text: _option.names[index].name));
    } catch (ex) {
      if (kDebugMode) {
        print(ex);
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  void _saveOption() {
    if (_formKey.currentState!.validate()) {
      widget.onOptionUpdated(_option);
      Navigator.pop(context);
    }
  }

  void _addChoice() {
    setState(() {
      ProductChoiceModel newChoice = ProductChoiceModel(
        guid: '',
        names: _option.names.map((e) => LanguageDataModel(code: e.code, name: '')).toList(),
        isdefault: false,
        isstock: false,
        price: '0',
        qty: 0,
        refbarcode: '',
        refproductcode: '',
        refunitcode: '',
        imageuri: null,
        image: null,
        imageWeb: null,
      );
      _option.choices.add(newChoice);

      // Create new TextEditingControllers for the new choice
      List<TextEditingController> newControllers = List.generate(
        newChoice.names.length,
        (index) => TextEditingController(text: newChoice.names[index].name),
      );
      choiceNameTextControllers.add(newControllers);
    });
  }

  void _removeChoice(int index) {
    setState(() {
      _option.choices.removeAt(index);
      // Also remove the corresponding controllers
      for (var controller in choiceNameTextControllers[index]) {
        controller.dispose();
      }
      choiceNameTextControllers.removeAt(index);
    });
  }

  Future<void> _translateNames() async {
    setState(() {
      isLoadTranslation = true;
    });
    try {
      // Translate option names
      await _translateOptionNames();

      // Translate choice names
      for (int i = 0; i < _option.choices.length; i++) {
        await _translateChoiceNames(_option.choices[i], i);
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    setState(() {
      isLoadTranslation = false;
    });
  }

  Future<void> _translateOptionNames() async {
    for (int i = 1; i < _option.names.length; i++) {
      var translation = await translator.translate(_option.names[0].name, to: languageList[i].codeTranslator!);
      setState(() {
        _option.names[i].name = translation.text;
        optionNameTextController[i].text = translation.text;
      });
    }
  }

  Future<void> _translateChoiceNames(ProductChoiceModel choice, int choiceIndex) async {
    if (choice.names[0].name.isEmpty) return; // Skip translation if the first name is empty

    for (int i = 1; i < choice.names.length; i++) {
      var translation = await translator.translate(choice.names[0].name, to: languageList[i].codeTranslator!);
      setState(() {
        choice.names[i].name = translation.text;
        choiceNameTextControllers[choiceIndex][i].text = translation.text;
      });
    }
  }

  Future<void> _selectProduct(ProductChoiceModel choice) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProductSearchScreen(word: ''),
      ),
    );

    if (result != null) {
      setState(() {
        choice.refbarcode = result.barcode;
        choice.refbarcodenames = result.names;
        choice.refproductcode = result.itemcode;
        choice.refunitcode = result.itemunitcode;
        choice.refunitnames = result.itemunitnames;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: Text(
          widget.isEditMode ? global.language('edit_option') : global.language('add_option'),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.translate, color: Colors.white),
            onPressed: _translateNames,
          ),
          IconButton(
            icon: Icon(Icons.save, color: Colors.white),
            onPressed: _saveOption,
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(16),
                    children: [
                      if (_option.names.isNotEmpty)
                        LanguageNamesFields(
                          names: _option.names,
                          languageList: languageList,
                          fieldName: 'option_name',
                          isEditMode: true,
                          isLoadTranslation: isLoadTranslation,
                          controllers: optionNameTextController,
                          onChanged: (code, value) {
                            setState(() {
                              _option.names.firstWhere((element) => element.code == code).name = value;
                            });
                          },
                        ),
                      SizedBox(height: 16),
                      ListTile(
                        title: Text(global.language('option_type')),
                        subtitle: Text(global.language(optionsTypes[_option.choicetype]['label'])),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => context.showSelectTypeBottomSheet(
                          title: global.language('select_product_type'),
                          types: optionsTypes,
                          selectedType: _option.choicetype,
                          onSelect: (value) => setState(() => _option.choicetype = value),
                        ),
                        tileColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: CustomNumberField(
                              readOnly: false,
                              controller: TextEditingController(text: _option.minselect.toString()),
                              labelText: global.language('option_min_select_choice'),
                              prefixIcon: null,
                              index: 0,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  _option.minselect = int.tryParse(value) ?? 0;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomNumberField(
                              readOnly: false,
                              controller: TextEditingController(text: _option.maxselect.toString()),
                              labelText: global.language('option_max_select_choice'),
                              prefixIcon: null,
                              index: 0,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  _option.maxselect = int.tryParse(value) ?? 1;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      Text(
                        global.language('choices'),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      if (_option.choices.isNotEmpty)
                        ..._option.choices.asMap().entries.map((entry) {
                          return _buildChoiceItem(entry.value, entry.key);
                        }).toList()
                      else
                        Center(child: Text(global.language('no_choice'))),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _addChoice,
                          icon: Icon(Icons.add),
                          label: Text(global.language('add_choice')),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: kPrimaryColor,
                            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildChoiceItem(ProductChoiceModel choice, int choiceIndex) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    choice.names.first.name.isNotEmpty ? choice.names.first.name : global.language('new_choice'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeChoice(choiceIndex),
                ),
              ],
            ),
            SizedBox(height: 16),
            BlocConsumer<ImageUploadBloc, ImageUploadState>(
              listener: (context, state) {
                if (state is ImageUploadSaveInProgress) {
                  setState(() {
                    choice.isImageUploading = true;
                  });
                } else if (state is ImageUploadSaveSuccess) {
                  setState(() {
                    choice.isImageUploading = false;
                    choice.imageuri = state.imageUpload.uri;
                  });
                } else if (state is ImageUploadSaveFailure) {
                  setState(() {
                    choice.isImageUploading = false;
                  });
                  global.showSnackBar(
                    context,
                    const Icon(Icons.error, color: Colors.white),
                    global.language("image_upload_failed ${state.message}"),
                    Colors.red,
                  );
                }
              },
              builder: (context, state) {
                return ImagePickerWidget(
                  image: choice.image,
                  imageUrl: choice.imageuri,
                  imageWeb: choice.imageWeb,
                  onImagePicked: (ImageSource source) async {
                    final pickedFile = await ImagePicker().pickImage(source: source);
                    if (pickedFile != null) {
                      choice.imageWeb = await pickedFile.readAsBytes();
                      setState(() {
                        choice.image = File(pickedFile.path);
                        choice.imageuri = null;
                        choice.isImageUploading = true;
                      });
                      context.read<ImageUploadBloc>().add(ImageUploadFileSaved(
                            imageFiles: [choice.image!],
                            imageWeb: [choice.imageWeb!],
                          ));
                    }
                  },
                  onImageRemoved: choice.imageuri != null && choice.imageuri!.isNotEmpty
                      ? () {
                          setState(() {
                            choice.image = null;
                            choice.imageWeb = null;
                            choice.imageuri = null;
                          });
                        }
                      : null,
                  isLoading: choice.isImageUploading,
                );
              },
            ),
            SizedBox(height: 16),
            LanguageNamesFields(
              names: choice.names,
              languageList: languageList,
              fieldName: 'choice_name',
              isEditMode: true,
              isLoadTranslation: isLoadTranslation,
              controllers: choiceNameTextControllers[choiceIndex],
              onChanged: (code, value) {
                setState(() {
                  choice.names.firstWhere((element) => element.code == code).name = value;
                });
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomNumberField(
                    readOnly: false,
                    controller: TextEditingController(text: choice.price),
                    labelText: global.language('price'),
                    prefixIcon: Icons.attach_money,
                    index: 0, // index can be any relevant index, adjust as needed
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        choice.price = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomNumberField(
                    readOnly: false,
                    controller: TextEditingController(text: choice.qty.toString()),
                    labelText: global.language('qty'),
                    prefixIcon: Icons.inventory,
                    index: 1, // index can be any relevant index, adjust as needed
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        choice.qty = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SwitchFormField(
                    value: choice.isdefault ?? false,
                    onChanged: (value) {
                      setState(() {
                        choice.isdefault = value;
                      });
                    },
                    label: global.language('choice_is_select'),
                  ),
                ),
                Expanded(
                  child: SwitchFormField(
                    value: choice.isstock,
                    onChanged: (value) {
                      setState(() {
                        choice.isstock = value;
                      });
                    },
                    label: global.language('choice_is_stock'),
                  ),
                ),
              ],
            ),
            if (choice.isstock)
              Column(
                children: [
                  SelectorFieldWidget(
                    selectedCode: choice.refbarcode,
                    selectedNames: choice.refbarcodenames ?? [],
                    onTap: () => _selectProduct(choice),
                    icon: Icons.qr_code,
                    label: global.language('product'),
                  ),
                  SizedBox(height: 16),
                  CustomNumberField(
                    readOnly: false,
                    controller: TextEditingController(text: choice.qty.toString()),
                    labelText: global.language('stock_deduction_quantity'),
                    prefixIcon: Icons.inventory_2,
                    index: choiceIndex,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        choice.qty = double.tryParse(value) ?? 0.0;
                      });
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
