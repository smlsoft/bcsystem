import 'package:cocomerchant_lite/components/custom_text_filed.dart';
import 'package:cocomerchant_lite/components/language_names_fields.dart';
import 'package:cocomerchant_lite/components/loadding_widget.dart';
import 'package:cocomerchant_lite/components/custom_save_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:translator/translator.dart';
import 'package:cocomerchant_lite/bloc/unit/unit_bloc.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/model/product_model.dart';
import 'package:cocomerchant_lite/constants.dart';

class AddUnitScreen extends StatefulWidget {
  static String routeName = "/add_unit_screen";
  const AddUnitScreen({super.key});

  @override
  State<AddUnitScreen> createState() => AddUnitScreenState();
}

class AddUnitScreenState extends State<AddUnitScreen> {
  final translator = GoogleTranslator();
  List<LanguageModel> languageList = <LanguageModel>[];
  List<LanguageDataModel> _names = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _unitCodeController = TextEditingController();
  List<TextEditingController> unitNameTextController = [];
  bool showAllLanguages = false;
  bool isLoadTranslation = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    setSystemLanguageList();
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
      _names = languageList.map((language) => LanguageDataModel(code: language.code!, name: '')).toList();
      unitNameTextController = List.generate(languageList.length, (_) => TextEditingController());
    } catch (ex) {
      // Handle error
      if (kDebugMode) {
        print(ex);
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _unitCodeController.dispose();
    for (var controller in unitNameTextController) {
      controller.dispose();
    }
    super.dispose();
  }

  void clearEditData() {
    for (var controller in unitNameTextController) {
      controller.clear();
    }
    for (var name in _names) {
      name.name = '';
    }
  }

  void discardData({required Function callBack}) {
    if (_unitCodeController.text.isEmpty && _names.every((element) => element.name.isEmpty)) {
      callBack();
      return;
    }

    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(global.language('data_editing')),
        content: Text(global.language('leave_this_screen')),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            onPressed: () => Navigator.pop(context),
            child: Text(global.language('no')),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kPrimaryColor),
            onPressed: () {
              Navigator.pop(context);
              callBack();
            },
            child: Text(global.language('yes')),
          ),
        ],
      ),
    );
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
        const Icon(Icons.error, color: Colors.white),
        "${global.language("not_success_save")} ${errorList.join(", ")}",
        Colors.red,
      );
      return false;
    }
    return true;
  }

  void saveOrUpdateData() {
    UnitModel unit = UnitModel(
      guidfixed: "",
      unitcode: _unitCodeController.text,
      names: _names,
    );
    if (verifyData(unit)) {
      setState(() {
        isLoading = true;
      });
      context.read<UnitBloc>().add(UnitSave(unitModel: unit));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            discardData(callBack: () {
              Navigator.pop(context);
            });
          },
        ),
        title: Text(
          global.language("add_product_unit"),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              setState(() {
                isLoadTranslation = true;
              });
              for (int i = 1; i < _names.length; i++) {
                try {
                  var translation = await translator.translate(_names[0].name, to: languageList[i].codeTranslator!);
                  setState(() {
                    _names[i].name = translation.text;
                    unitNameTextController[i].text = translation.text; // Update controller
                  });
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
            icon: const Icon(Icons.translate, color: Colors.white),
          ),
          IconButton(
            onPressed: () => saveOrUpdateData(),
            icon: const Icon(Icons.save, color: Colors.white),
          ),
        ],
        elevation: 0,
      ),
      body: BlocListener<UnitBloc, UnitState>(
        listener: (context, state) {
          if (state is UnitInProgress) {
            setState(() {
              isLoading = true;
            });
          }
          if (state is UnitSaveSuccess) {
            setState(() {
              isLoading = false;
            });
            global.showSnackBar(
              context,
              const Icon(Icons.check_circle, color: Colors.white),
              global.language("save_success"),
              Colors.green,
            );
            Navigator.pop(context);
          }
          if (state is UnitSaveFailed) {
            setState(() {
              isLoading = false;
            });
            global.showSnackBar(
              context,
              const Icon(Icons.error, color: Colors.white),
              "${global.language("not_success_save")} : ${state.message}",
              Colors.red,
            );
          }
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        controller: _unitCodeController,
                        label: global.language('unit_code'),
                        icon: Icons.code,
                      ),
                      const SizedBox(height: 16),
                      if (_names.isNotEmpty)
                        LanguageNamesFields(
                          names: _names,
                          languageList: languageList,
                          fieldName: 'unit_name',
                          isEditMode: true,
                          isLoadTranslation: isLoadTranslation,
                          controllers: unitNameTextController,
                          onChanged: (code, value) {
                            setState(() {
                              _names.firstWhere((element) => element.code == code).name = value;
                            });
                          },
                        ),
                      const SizedBox(height: 32),
                      buildSaveButton(
                        formKey: _formKey,
                        onPressed: saveOrUpdateData,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            LoadingWidget(isLoading: isLoading),
          ],
        ),
      ),
    );
  }
}
