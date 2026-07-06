import 'dart:convert';

import 'package:cocomerchant_lite/bloc/login_bloc/login_bloc.dart';
import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/model/business_type_model.dart';
import 'package:cocomerchant_lite/model/create_shop_model.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/screens/login_success/login_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocomerchant_lite/global.dart' as global;

class CreateShopForm extends StatefulWidget {
  const CreateShopForm({super.key});

  @override
  _CreateShopFormState createState() => _CreateShopFormState();
}

class _CreateShopFormState extends State<CreateShopForm> {
  final _formKeyCreateShop = GlobalKey<FormState>();
  late CreateShopModel createShopData;
  int _indexStep = 0;

  List<LanguageModel> defaultlanguageList = [
    LanguageModel(code: "th", codeTranslator: "th", name: "Thai", isuse: false),
    LanguageModel(code: "en", codeTranslator: "en", name: "English", isuse: false),
    LanguageModel(code: "zh", codeTranslator: "zh", name: "Chinese", isuse: false),
    LanguageModel(code: "ja", codeTranslator: "ja", name: "Japanese", isuse: false),
    LanguageModel(code: "ko", codeTranslator: "ko", name: "Korean", isuse: false),
    LanguageModel(code: "lo", codeTranslator: "lo", name: "Lao", isuse: false),
    LanguageModel(code: "my", codeTranslator: "my", name: "Burmese", isuse: false),
    LanguageModel(code: "ms", codeTranslator: "ms", name: "Malaysian", isuse: false),
    LanguageModel(code: "vi", codeTranslator: "vi", name: "Vietnamese", isuse: false),
    LanguageModel(code: "km", codeTranslator: "km", name: "Khmer", isuse: false),
  ];

  List<BusinessTypeModel> businessTypeList = [];

  @override
  void initState() {
    clearDataCreateShop();
    super.initState();
  }

  void clearDataCreateShop() {
    createShopData = CreateShopModel(
      address: [],
      branchcode: '',
      images: [],
      logo: '',
      name1: '',
      names: [],
      profilepicture: '',
      settings: Settings(
        emailowners: [],
        emailstaffs: [],
        isusebranch: false,
        isusedepartment: false,
        languageconfigs: [],
        latitude: 0,
        longitude: 0,
        taxid: '',
        vatrate: 7,
        vattypesale: 0,
        vattypepurchase: 0,
        inquirytypesale: 0,
        inquirytypepurchase: 0,
      ),
      telephone: '',
      businesstype: BusinessTypeModel(),
    );
    createShopData.settings!.languageconfigs!.add(
      LanguageModel(
        code: "th",
        codeTranslator: "th",
        name: "Thai",
        isuse: false,
      ),
    );
    addTextControllerName();
    getTemplateBusinessType();
  }

  void addTextControllerName() {
    createShopData.names = [];
    for (int i = 0; i < createShopData.settings!.languageconfigs!.length; i++) {
      createShopData.names!.add(
        LanguageDataModel(
          code: createShopData.settings!.languageconfigs![i].code!,
          name: "",
        ),
      );
    }
    setState(() {});
  }

  Future<void> getTemplateBusinessType() async {
    const githubRawUrl = 'https://raw.githubusercontent.com/smlsoft/dedepos_template/main/business_type.json';

    try {
      final fileContent = await global.readFileFromGithub(githubRawUrl);
      final businessType = (json.decode(fileContent) as List).map((bank) => BusinessTypeModel.fromJson(bank)).toList();
      businessTypeList = [];

      for (int i = 0; i < businessType.length; i++) {
        businessTypeList.add(businessType[i]);
      }

      setState(() {
        if (createShopData.businesstype!.code!.isEmpty) {
          createShopData.businesstype = BusinessTypeModel(
            code: businessType[0].code,
            names: businessType[0].names,
          );
        }
      });
    } catch (error) {
      // Handle error
      // ignore: avoid_print
      print('Error reading file: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is CreateShopSuccess) {
          clearDataCreateShop();
          Navigator.pushNamed(context, LoginSuccessScreen.routeName);
        }
      },
      child: Form(
        key: _formKeyCreateShop,
        child: Column(
          children: [
            Stepper(
              currentStep: _indexStep,
              onStepCancel: () {
                if (_indexStep > 0) {
                  setState(() {
                    _indexStep -= 1;
                  });
                }
              },
              onStepContinue: () {
                if (_indexStep < 1) {
                  setState(() {
                    addTextControllerName();
                    _indexStep += 1;
                  });
                } else if (_indexStep == 1) {
                  if (_formKeyCreateShop.currentState!.validate()) {
                    createShopData.settings!.languageconfigs![0].isdefault = true;
                    context.read<LoginBloc>().add(CreateShop(createShop: createShopData));
                  }
                }
              },
              onStepTapped: (int index) {
                setState(() {
                  addTextControllerName();
                  if (index >= 0 && index < 2) {
                    // Ensure index is valid
                    _indexStep = index;
                  }
                });
              },
              controlsBuilder: (BuildContext context, ControlsDetails details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: <Widget>[
                      if (_indexStep == 0)
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: Text(global.language('next')),
                        ),
                      if (_indexStep == 1)
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            // Your custom styles here
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(global.language('save')),
                        ),
                      if (_indexStep == 1 && details.stepIndex > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: Text(global.language('back')),
                        ),
                    ],
                  ),
                );
              },
              steps: <Step>[
                Step(
                  title: Text(global.language('step_1_select_language')),
                  content: Container(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      children: [
                        for (var i = 0; i < createShopData.settings!.languageconfigs!.length; i++)
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

                                          for (var selected in createShopData.settings!.languageconfigs!) {
                                            languagesSelectList.removeWhere((element) => element.code == selected.code);
                                          }

                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text(global.language('select_language')),
                                                  content: SizedBox(
                                                    width: 300,
                                                    height: 400,
                                                    child: ListView.builder(
                                                      itemCount: languagesSelectList.length,
                                                      itemBuilder: (context, index) {
                                                        return ListTile(
                                                          title: Row(
                                                            children: [
                                                              Text(languagesSelectList[index].name!),
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
                                                              Navigator.of(context).pop(languagesSelectList[index]);
                                                            });
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                );
                                              }).then((value) {
                                            setState(() {
                                              if (value != null) {
                                                createShopData.settings!.languageconfigs![i] = value!;
                                                createShopData.settings!.languageconfigs![i].isuse = true;
                                                addTextControllerName();
                                              }
                                            });
                                          });
                                        },
                                        child: Row(children: [
                                          (createShopData.settings!.languageconfigs![i].code!.isNotEmpty)
                                              ? Image.asset(
                                                  'assets/flags/${createShopData.settings!.languageconfigs![i].code!}.png',
                                                  width: 30,
                                                  height: 30,
                                                )
                                              : Container(),
                                          const SizedBox(width: 10),
                                          (createShopData.settings!.languageconfigs![i].code!.isNotEmpty)
                                              ? Text(defaultlanguageList.firstWhere((element) => element.code == createShopData.settings!.languageconfigs![i].code!).name!)
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
                                              createShopData.settings!.languageconfigs!.removeAt(i);
                                            });
                                          },
                                          color: Colors.red,
                                          icon: const Icon(Icons.delete)),
                                    ),
                            ]),
                          ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                createShopData.settings!.languageconfigs!.add(
                                  LanguageModel(
                                    code: "",
                                    codeTranslator: "",
                                    name: "",
                                    isuse: false,
                                  ),
                                );
                                addTextControllerName();
                              });
                            },
                            child: Text(
                              global.language('add_language'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Step(
                  title: Text(global.language('step_2_enter_shop_name')),
                  content: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            /// set color button
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black, backgroundColor: Colors.green[200], // foreground
                            ),
                            onPressed: () async {
                              await getTemplateBusinessType();

                              if (mounted) {
                                showDialog(
                                    // ignore: use_build_context_synchronously
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(global.language('select_business_type')),
                                        content: SizedBox(
                                          width: 300,
                                          height: 400,
                                          child: ListView.builder(
                                            itemCount: businessTypeList.length,
                                            itemBuilder: (context, index) {
                                              return ListTile(
                                                title: Text(
                                                  global.activeLangName(businessTypeList[index].names!),
                                                  maxLines: 2, // Set the maxLines here
                                                  overflow: TextOverflow.ellipsis, // Optional: Use this to show ellipsis at the end if text overflows
                                                ),
                                                tileColor: createShopData.businesstype!.code == businessTypeList[index].code! ? Colors.blue[100] : null, // Highlight if selected
                                                onTap: createShopData.businesstype!.code != businessTypeList[index].code!
                                                    ? () {
                                                        setState(() {
                                                          Navigator.of(context).pop(businessTypeList[index]);
                                                        });
                                                      }
                                                    : null,
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    }).then((value) {
                                  if (value != null) {
                                    setState(() {
                                      createShopData.businesstype!.code = value.code;
                                      createShopData.businesstype!.names = value.names;
                                    });
                                  }
                                });
                              }
                            },
                            child: Text(
                              "${global.language("company_type")} ~ ${global.activeLangName(createShopData.businesstype!.names!)}",
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (int i = 0; i < createShopData.settings!.languageconfigs!.length; i++)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            controller: TextEditingController(text: createShopData.names![i].name),
                            autofocus: true,
                            onChanged: (value) {
                              createShopData.names![i].name = value;
                            },
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              border: const OutlineInputBorder(),
                              labelText: "${global.language("company_name")} (${createShopData.names![i].code.toUpperCase()})",
                              labelStyle: const TextStyle(fontSize: 16.0),
                            ),
                            onEditingComplete: () {
                              setState(() {
                                createShopData.names![i].name = createShopData.names![i].name;
                              });
                            },
                            validator: (value) {
                              if (i == 0) {
                                if (value == null || value.isEmpty) {
                                  return global.language('please_enter_value');
                                }
                                return null;
                              } else {
                                return null;
                              }
                            },
                          ),
                        )
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
