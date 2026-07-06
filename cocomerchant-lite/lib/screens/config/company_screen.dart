import 'dart:io';

import 'package:cocomerchant_lite/bloc/company_branch/company_branch_bloc.dart';
import 'package:cocomerchant_lite/bloc/image/image_upload_bloc.dart';
import 'package:cocomerchant_lite/bloc/shop/shop_bloc.dart';
import 'package:cocomerchant_lite/model/company_branch_model.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/model/shop_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter/material.dart';

import 'package:cocomerchant_lite/global.dart' as global;
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => CompanyScreenState();
}

class CompanyScreenState extends State<CompanyScreen> with SingleTickerProviderStateMixin {
  GetStorage appConfig = GetStorage('AppConfig');
  late ShopModel screenData;
  late CompanyBranchModel branchData;
  List<LanguageModel> languageList = <LanguageModel>[];

  final ImagePicker imagePicker = ImagePicker();
  List<File> imageFile = [File('')];
  List<Uint8List> imageWeb = [Uint8List(0)];

  final ImagePicker logoPicker = ImagePicker();
  List<File> logoFile = [File('')];
  List<Uint8List> logoWeb = [Uint8List(0)];

  /// textinput controller api key
  final TextEditingController apiKeyController = TextEditingController();

  @override
  void initState() {
    screenData = ShopModel();
    branchData = CompanyBranchModel(
      guidfixed: '',
      code: '',
    );

    apiKeyController.text = appConfig.read("apikey") ?? '';

    setSystemLanguageList();
    loadDataBranch("00000");
    super.initState();
  }

  void loadDataBranch(String code) {
    context.read<CompanyBranchBloc>().add(CompanyBranchGetBycode(code: code));
  }

  void setSystemLanguageList() async {
    await global.setSystemLanguage(context);

    for (int i = 0; i < global.config.languages.length; i++) {
      if (global.config.languages[i].isuse!) {
        languageList.add(global.config.languages[i]);
      }
    }

    setState(() {
      screenData = global.shopSelectData;
    });
  }

  void upLoadImage() {
    if (imageFile.isNotEmpty) {
      if (imageFile[0].path != '') {
        context.read<ImageUploadBloc>().add(ImageUploadFileSaved(imageFiles: imageFile, imageWeb: imageWeb));
      }
    }
  }

  void upLoadLogo() {
    if (logoFile.isNotEmpty) {
      if (logoFile[0].path != '') {
        context.read<ImageUploadBloc>().add(LogoUploadFileSaved(imageFiles: logoFile, imageWeb: logoWeb));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: MultiBlocListener(
        listeners: [
          BlocListener<ShopBloc, ShopState>(
            listener: (context, state) {
              if (state is ShopUpdateSuccess) {
                context.read<CompanyBranchBloc>().add(CompanyBranchUpdate(guid: branchData.guidfixed, companyBranch: branchData));
              } else if (state is ShopUpdateFailed) {
                setState(() {
                  global.showSnackBar(
                    context,
                    const Icon(
                      Icons.save,
                      color: Colors.white,
                    ),
                    "//${global.language("save_failed")} ${state.message}",
                    Colors.red,
                  );
                });
              }

              if (state is ShopUpdateFailed) {
                setState(() {
                  global.showSnackBar(
                    context,
                    const Icon(
                      Icons.save,
                      color: Colors.white,
                    ),
                    "//${global.language("save_failed")} ${state.message}",
                    Colors.red,
                  );
                });
              }
            },
          ),
          BlocListener<CompanyBranchBloc, CompanyBranchState>(listener: (context, state) {
            if (state is CompanyBranchUpdateSuccess) {
              global.showSnackBar(
                  context,
                  const Icon(
                    Icons.save,
                    color: Colors.white,
                  ),
                  global.language("update_success"),
                  Colors.blue);
              Navigator.pushReplacementNamed(context, '/menu');
            } else if (state is CompanyBranchUpdateFailed) {
              setState(() {
                global.showSnackBar(
                    context,
                    const Icon(
                      Icons.save,
                      color: Colors.white,
                    ),
                    "//${global.language("save_failed")} ${state.message}",
                    Colors.red);
              });
            }
          }),
          BlocListener<CompanyBranchBloc, CompanyBranchState>(listener: (context, state) {
            if (state is CompanyBranchGetBycodeSuccess) {
              setState(() {
                if (state.companyBranch.guidfixed.isNotEmpty) {
                  branchData = state.companyBranch;
                }
              });
            }
          }),
          BlocListener<ImageUploadBloc, ImageUploadState>(listener: (context, state) {
            if (state is ImageUploadSaveSuccess) {
              screenData.profilepicture = state.imageUpload.uri;
            } else if (state is LogoUploadSaveSuccess) {
              screenData.logo = state.imageUpload.uri;
            }
          }),
        ],
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: global.theme.appBarColor,
                automaticallyImplyLeading: false,
                title: Text(global.language('company')),
                leading: IconButton(
                  focusNode: FocusNode(skipTraversal: true),
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/menu');
                  },
                ),
                actions: <Widget>[
                  Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: IconButton(
                        focusNode: FocusNode(skipTraversal: true),
                        onPressed: () {
                          saveOrUpdateData();
                        },
                        icon: const Icon(
                          Icons.save,
                          size: 26.0,
                        ),
                      )),
                ],
              ),
              body: SingleChildScrollView(
                child: Center(
                    child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 10),
                      padding: const EdgeInsets.all(10),
                      width: 600,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(global.language("company_data"), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(
                            height: 15,
                          ),
                          Column(
                            children: listNamesFields(screenData.names!, "company_name"),
                          ),

                          /// branchcode field
                          Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                            child: TextFormField(
                              onChanged: (value) {
                                screenData.branchcode = value;
                              },
                              enabled: false,
                              textAlign: TextAlign.left,
                              controller: TextEditingController(text: branchData.code),
                              decoration: InputDecoration(
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                border: const OutlineInputBorder(),
                                labelText: global.language("branch_code"),
                              ),
                            ),
                          ),

                          Column(
                            children: listNamesFields(branchData.names, "company_branch_name"),
                          ),

                          /// address
                          Column(
                            children: listAddressFields(screenData.address!, "address"),
                          ),

                          /// phone field
                          Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                            child: TextFormField(
                              onChanged: (value) {
                                screenData.telephone = value;
                              },
                              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp('[0-9]'))],
                              textAlign: TextAlign.left,
                              controller: TextEditingController(text: screenData.telephone!),
                              decoration: InputDecoration(
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                border: const OutlineInputBorder(),
                                labelText: global.language("telephone"),
                              ),
                            ),
                          ),

                          /// taxid field
                          Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                            child: TextFormField(
                              onChanged: (value) {
                                screenData.settings!.taxid = value;
                              },
                              textAlign: TextAlign.left,
                              controller: TextEditingController(text: screenData.settings!.taxid),
                              decoration: InputDecoration(
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                border: const OutlineInputBorder(),
                                labelText: global.language("customer_tax_id_bussiness"),
                              ),
                            ),
                          ),

                          const Divider(),

                          Text(global.language("image"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                          GridView.builder(
                            primary: true,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: imageFile.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, childAspectRatio: 1.5),
                            itemBuilder: (BuildContext context, int index) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                          child: IconButton(
                                        focusNode: FocusNode(skipTraversal: true),
                                        onPressed: () async {
                                          screenData.profilepicture = "";
                                          imageFile[index] = File('');
                                          imageWeb[index] = Uint8List(0);
                                          setState(() {});
                                        },
                                        icon: const Icon(
                                          Icons.delete,
                                        ),
                                      )),
                                      const SizedBox(width: 5),
                                      Expanded(
                                          child: IconButton(
                                        focusNode: FocusNode(skipTraversal: true),
                                        onPressed: () async {
                                          final XFile? image = await imagePicker.pickImage(source: ImageSource.gallery, maxHeight: 400, maxWidth: 400);
                                          if (image != null) {
                                            var f = await image.readAsBytes();
                                            imageWeb[index] = f;
                                            imageFile[index] = File(image.path);
                                            upLoadImage();
                                            setState(() {});
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.folder,
                                        ),
                                      )),
                                      const SizedBox(width: 5),
                                      if (kIsWeb == false)
                                        Expanded(
                                            child: IconButton(
                                          focusNode: FocusNode(skipTraversal: true),
                                          onPressed: () async {
                                            final XFile? photo = await imagePicker.pickImage(source: ImageSource.camera, maxHeight: 400, maxWidth: 400, imageQuality: 60);
                                            if (photo != null) {
                                              var f = await photo.readAsBytes();
                                              imageWeb[index] = f;
                                              imageFile[index] = File(photo.path);
                                              upLoadImage();
                                              setState(() {});
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.camera_alt,
                                          ),
                                        )),
                                    ],
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Colors.black),
                                          borderRadius: BorderRadius.circular(5),
                                          image: (imageFile[index].path != '')
                                              ? DecorationImage(image: MemoryImage(imageWeb[index]), fit: BoxFit.fill)
                                              : (screenData.profilepicture != '')
                                                  ? DecorationImage(image: NetworkImage(screenData.profilepicture!), fit: BoxFit.fill)
                                                  : const DecorationImage(image: AssetImage('assets/img/noimage.png')),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const Divider(),
                          Text(global.language("Logo"), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                          /// logo
                          GridView.builder(
                              primary: true,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: logoFile.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 1, childAspectRatio: 1.5),
                              itemBuilder: (BuildContext context, int index) {
                                return Container(
                                    width: 500,
                                    padding: const EdgeInsets.only(left: 5, right: 5, bottom: 5, top: 5),
                                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: const BorderRadius.all(Radius.circular(5.0))),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                                child: IconButton(
                                              focusNode: FocusNode(skipTraversal: true),
                                              onPressed: () async {
                                                screenData.logo = "";
                                                logoFile[index] = File('');
                                                logoWeb[index] = Uint8List(0);
                                                setState(() {});
                                              },
                                              icon: const Icon(
                                                Icons.delete,
                                              ),
                                            )),
                                            const SizedBox(width: 5),
                                            Expanded(
                                                child: IconButton(
                                              focusNode: FocusNode(skipTraversal: true),
                                              onPressed: () async {
                                                final XFile? image = await logoPicker.pickImage(source: ImageSource.gallery, maxHeight: 400, maxWidth: 400);
                                                if (image != null) {
                                                  var f = await image.readAsBytes();
                                                  logoWeb[index] = f;
                                                  logoFile[index] = File(image.path);
                                                  upLoadLogo();
                                                  setState(() {});
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.folder,
                                              ),
                                            )),
                                            const SizedBox(width: 5),
                                            if (kIsWeb == false)
                                              Expanded(
                                                  child: IconButton(
                                                focusNode: FocusNode(skipTraversal: true),
                                                onPressed: () async {
                                                  final XFile? photo = await logoPicker.pickImage(source: ImageSource.camera, maxHeight: 400, maxWidth: 400, imageQuality: 60);
                                                  if (photo != null) {
                                                    var f = await photo.readAsBytes();
                                                    logoWeb[index] = f;
                                                    logoFile[index] = File(photo.path);
                                                    upLoadLogo();
                                                    setState(() {});
                                                  }
                                                },
                                                icon: const Icon(
                                                  Icons.camera_alt,
                                                ),
                                              )),
                                          ],
                                        ),
                                        Expanded(
                                            child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: Colors.black),
                                            borderRadius: BorderRadius.circular(5),
                                            image: (logoFile[index].path != '')
                                                ? DecorationImage(image: MemoryImage(logoWeb[index]), fit: BoxFit.fill)
                                                : (screenData.logo != '')
                                                    ? DecorationImage(image: NetworkImage(screenData.logo!), fit: BoxFit.fill)
                                                    : const DecorationImage(image: AssetImage('assets/img/noimage.png')),
                                          ),
                                        )),
                                      ],
                                    ));
                              }),
                        ],
                      ),
                    ),
                  ],
                )),
              ),
            );
          },
        ),
      ),
    );
  }

  void saveOrUpdateData() {
    branchData.companynames = screenData.names!;
    branchData.contact!.address = screenData.address!;
    branchData.contact!.latitude = screenData.settings!.latitude!;
    branchData.contact!.longitude = screenData.settings!.longitude!;
    branchData.contact!.phonenumber = screenData.telephone!;
    branchData.pos!.taxid = screenData.settings!.taxid!;
    branchData.imageuri = screenData.profilepicture;
    branchData.logouri = screenData.logo;

    context.read<ShopBloc>().add(ShopUpdate(shopid: screenData.guidfixed!, shopdata: screenData));
  }

  String getLangName(String code) {
    LanguageModel name = languageList.firstWhere((element) => element.code == code, orElse: () => LanguageModel(code: '', codeTranslator: '', name: '', isuse: false));
    return name.name!;
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
            onChanged: (value) {
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

  List<Widget> listAddressFields(List<LanguageDataModel> names, String fieldname) {
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
            onChanged: (value) {
              nameObj.name = value;
            },
            keyboardType: TextInputType.multiline,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
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
