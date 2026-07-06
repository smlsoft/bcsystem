import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:smlaicloud/bloc/company_branch/company_branch_bloc.dart';
import 'package:smlaicloud/bloc/profile/profile_bloc.dart';
import 'package:smlaicloud/bloc/shop/shop_bloc.dart';
import 'package:smlaicloud/bloc/user/user_bloc.dart';
import 'package:smlaicloud/components/singin_button.dart';
import 'package:smlaicloud/flavors.dart';
import 'package:smlaicloud/global.dart';
import 'package:smlaicloud/menu_screen.dart';
import 'package:smlaicloud/model/business_type_model.dart';
import 'package:smlaicloud/model/company_branch_model.dart';
import 'package:smlaicloud/model/create_shop_model.dart';
import 'package:smlaicloud/model/global_model.dart';
import 'package:smlaicloud/model/shop_list_model.dart';
import 'package:smlaicloud/model/shop_model.dart';
import 'package:smlaicloud/usersystem/otp/telephone_screen.dart';
import 'package:smlaicloud/usersystem/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:smlaicloud/bloc/list_shop/list_shop_bloc.dart';
import 'package:smlaicloud/bloc/login_bloc/login_bloc.dart';
import 'package:smlaicloud/bloc/shop_select/shop_select_bloc.dart';
import 'package:smlaicloud/utils/util.dart';
import 'package:smlaicloud/global.dart' as global;
import 'package:url_launcher/url_launcher.dart';

class LoginShopScreen extends StatefulWidget {
  const LoginShopScreen({super.key});

  @override
  State<LoginShopScreen> createState() => LoginShopScreenState();
}

class LoginShopScreenState extends State<LoginShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formKeyCreateShop = GlobalKey<FormState>();

  /// 0 = login , 1 = list shop , 2 = create shop , 3 = select branch
  int stateScreen = 1;
  final bool _isListShopNotFound = false;

  late FirebaseAuth _auth;

  global.LoginEnum loginType = global.LoginEnum.none;
  late CreateShopModel createShopData;

  int _indexStep = 0;

  List<CompanyBranchModel> companyBranchListData = [];

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

  Timer? _timer;
  bool stateLoginScreen = false;

  Future<UserCredential?> googleSignIn() async {
    try {
      // Trigger the authentication flow
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'], // scopes พื้นฐานพอ
      );
      // Obtain the auth details from the request
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // print(googleUser);

      // Sign in to Firebase with the Google [UserCredential]

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      // print(e);
      return null;
    }
  }

  Future<String?> getCurrentUserIdToken() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      String? idToken = await currentUser.getIdToken();
      return idToken;
    } else {
      // No user is signed in.
      // print("No user is signed in");
      return null;
    }
  }

  @override
  void initState() {
    if (kIsWeb) {
      _auth = FirebaseAuth.instance;
    } else if (Platform.isWindows) {
      _auth = FirebaseAuth.instance;
    } else if (Platform.isMacOS) {
      _auth = FirebaseAuth.instance;
    }

    clearDataCreateShop();

    context.read<ProfileBloc>().add(const GetProfile());
    context.read<ListShopBloc>().add(ListShopLoad());
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

  void logoutWithGoogle() async {
    // await _auth.signOut();
    await getCurrentUserIdToken();
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

  Widget createShop() {
    return SizedBox(
      width: 600,
      child: Align(
        child: Card(
          color: Colors.grey.shade200,
          elevation: 5,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(15),
            ),
          ),
          child: SizedBox(
              child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    (MediaQuery.of(context).size.width > 799)
                        ? ElevatedButton.icon(
                            onPressed: () {
                              context.read<LoginBloc>().add(const Logout());
                            },
                            icon: const Icon(Icons.logout),
                            label: Text(global.language('logout')),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              setState(() {
                                stateScreen = 0;
                              });
                            },
                            child: const Icon(
                              Icons.logout,
                              color: Colors.white, // Set the icon color
                            ),
                          ),

                    const Spacer(), //
                    const Text(
                      "สร้างร้านค้า",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(), //
                    (MediaQuery.of(context).size.width > 799)
                        ? ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                stateScreen = 1;
                              });
                            },
                            icon: const Icon(Icons.swap_vert),
                            label: Text(global.language('select_shop')),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              setState(() {
                                stateScreen = 1;
                              });
                            },
                            child: const Icon(
                              Icons.list,
                              color: Colors.white,
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Expanded(
                child: Stepper(
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
                      _indexStep = index;
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
                                backgroundColor: Colors.green,
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
                      content: Form(
                        key: _formKeyCreateShop,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  /// set color button
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    backgroundColor: Colors.green[200], // foreground
                                  ),
                                  onPressed: () async {
                                    await getTemplateBusinessType();

                                    if (mounted) {
                                      showDialog(
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
                                                      tileColor:
                                                          createShopData.businesstype!.code == businessTypeList[index].code! ? Colors.blue[100] : null, // Highlight if selected
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
                    ),
                  ],
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget listShopSelect() {
    return BlocBuilder<ListShopBloc, ListShopState>(builder: (context, state) {
      if (state is ListShopLoadSuccess) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            const spacing = 4.0;
            double maxWidth = constraints.maxWidth;
            int crossAxisCount = (maxWidth / 200).floor();
            return GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(spacing),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: 1.5,
              ),
              itemCount: state.shop.length,
              itemBuilder: (context, index) => cardItem(state.shop[index]),
            );
          },
        );
      }
      return Container();
    });
  }

  Widget cardItem(ShopListModel data) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      onPressed: () {
        context.read<ShopSelectBloc>().add(ShopSelect(shop: data));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(child: (appConfig.getString("user") == data.createdby) ? const Icon(Icons.business) : const Icon(Icons.business_center)),
          Expanded(
              child: Text(
            (data.name.isEmpty) ? global.packName(data.names!) : data.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 5,
          )),
        ],
      ),
    );
  }

  Widget cardItemBranch(CompanyBranchModel data) {
    return Card(
      elevation: 3,
      child: ListTile(
        /// backgroup color
        tileColor: Colors.blue.shade100,

        onTap: (() {
          global.companyBranchSelectData = data;

          appConfig.setString("branch_guidfixed", data.guidfixed);
          appConfig.setInt("branch_total", companyBranchListData.length);
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MenuScreen()), (route) => false);
        }),
        leading: const Icon(Icons.home_work_rounded),
        title: Text(
          global.packName(data.names),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget loginWithGoogle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20),
        child: SingInButton(
          labelText: 'Sign in with google',
          press: () {
            loginType = global.LoginEnum.google;
            if (kIsWeb) {
              googleSignIn().then((value) async {
                if (value != null) {
                  String? userIdToken = await getCurrentUserIdToken();
                  if (userIdToken != null) {
                    // print(userIdToken);
                    appConfig.setString("user", value.user!.email ?? "");
                    if (mounted) {
                      context.read<LoginBloc>().add(TokenLogin(token: userIdToken));
                    }
                  }
                }
              });
            } else if (Platform.isWindows) {
              GoogleAuthHelper googleAuthHelper = GoogleAuthHelper();
              googleAuthHelper.signIn().then((value) async {
                // if (value != null) {
                //   String userIdToken = value.credentials.idToken ?? "";
                //   if (userIdToken.isNotEmpty) {
                //     print(userIdToken);
                //     appConfig.write("user", value.email);
                //     if (mounted) {
                //       context
                //           .read<LoginBloc>()
                //           .add(TokenLogin(token: userIdToken));
                //     }
                //   }
                // }
                if (value != null) {
                  String? userIdToken = await getCurrentUserIdToken();
                  if (userIdToken != null) {
                    // print(userIdToken);
                    appConfig.setString("user", value.user!.email ?? "");
                    if (mounted) {
                      context.read<LoginBloc>().add(TokenLogin(token: userIdToken));
                    }
                  }
                }
              });
            } else if (Platform.isMacOS) {
              GoogleAuthHelper googleAuthHelper = GoogleAuthHelper();
              googleAuthHelper.signIn().then((value) async {
                if (value != null) {
                  String? userIdToken = await getCurrentUserIdToken();
                  if (userIdToken != null) {
                    // print(userIdToken);
                    appConfig.setString("user", value.user!.email ?? "");
                    if (mounted) {
                      context.read<LoginBloc>().add(TokenLogin(token: userIdToken));
                    }
                  }
                }
              });
            }
          },
          img: const AssetImage("assets/img/google_logo.png"),
        ),
      ),
    );
  }

  Widget registerPhone() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20),
        child: SingInButton(
          labelText: 'Register With Phone Number',
          press: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TelephoneScreen(),
              ),
            );
          },
          img: const AssetImage("assets/img/logo_phone.png"),
        ),
      ),
    );
  }

  Widget imageLogo() {
    return Image.asset(
      "assets/img/sml-merchant-icon.png",
      height: 240,
    );
  }

  void showSncakBar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget listBranchSelect() {
    return SizedBox(
      width: 600,
      child: Align(
        child: Card(
          color: Colors.grey.shade200,
          elevation: 5,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(15),
            ),
          ),
          child: SizedBox(
              child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Spacer(), //
                    Text(
                      global.language('select_branch'),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(), //
                    (MediaQuery.of(context).size.width > 799)
                        ? ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                stateScreen = 1;
                              });
                            },
                            icon: const Icon(Icons.swap_vert),
                            label: Text(global.language('select_shop')),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              setState(() {
                                stateScreen = 1;
                              });
                            },
                            child: const Icon(
                              Icons.list,
                              color: Colors.white,
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              Expanded(
                child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: companyBranchListData.length,
                    itemBuilder: (BuildContext context, int index) {
                      return cardItemBranch(companyBranchListData[index]);
                    }),
              )
            ],
          )),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
        listeners: [
          BlocListener<LoginBloc, LoginState>(
            listener: (context, state) {
              /// Logout
              if (state is LogoutSuccess) {
                Navigator.pushNamedAndRemoveUntil(context, '/login_screen', (route) => false);
              }

              if (state is CreateShopSuccess) {
                context.read<ListShopBloc>().add(ListShopLoad());
              }
            },
          ),
          BlocListener<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state is GetProfileSuccess) {
                global.profileData = state.profile;
              }
            },
          ),
          BlocListener<ListShopBloc, ListShopState>(
            listener: (context, state) {
              if (state is ListShopLoadSuccess) {
                setState(() {
                  stateScreen = 1;
                });
              }
            },
          ),
          BlocListener<ShopSelectBloc, ShopSelectState>(
            listener: (context, state) {
              if (state is ShopSelectLoadSuccess) {
                /// load ข้อมูล ร้านค้า

                context.read<ShopBloc>().add(GetShopInfo(shopid: global.getShopId()));

                /// load ข้อมูลสาขา
                context.read<CompanyBranchBloc>().add(
                      const CompanyBranchLoadList(
                        offset: 0,
                        limit: 100,
                        search: "",
                      ),
                    );

                String userJsonString = appConfig.getString("user")!;
                Map<String, dynamic> userJson = jsonDecode(userJsonString);
                String userEmail = userJson['email'];
                context.read<UserBloc>().add(UserGet(username: userEmail));

                /// ข้ามการเลือกสาขา

                // Navigator.of(context).pushAndRemoveUntil(
                //     MaterialPageRoute(builder: (_) => const MenuScreen()),
                //     (route) => false);
              }
            },
          ),
          BlocListener<ShopBloc, ShopState>(
            listener: (context, state) {
              print("ShopBloc State: ${state.runtimeType}"); // เพิ่มบรรทัดนี้

              if (state is GetShopInfoSuccess) {
                print("Shop data: ismainshop=${state.shop.ismainshop}, mainshopid='${state.shop.mainshopid}'");

                appConfig.setString("shop_info", jsonEncode(state.shop.toJson()));

                // ตรวจสอบเงื่อนไขแต่ละขั้นตอน
                print("ismainshop == false: ${state.shop.ismainshop == false}");
                print("mainshopid != null: ${state.shop.mainshopid != null}");
                print("mainshopid!.isNotEmpty: ${state.shop.mainshopid?.isNotEmpty}");

                if (state.shop.ismainshop == false && state.shop.mainshopid != null && state.shop.mainshopid!.isNotEmpty) {
                  print("All conditions met, calling GetMainShopCenterTypes");
                  context.read<ShopBloc>().add(GetMainShopCenterTypes(mainShopId: state.shop.mainshopid!));
                } else {
                  print("Conditions not met for GetMainShopCenterTypes");
                }
              }

              if (state is GetMainShopCenterTypesInProgress) {
                print("GetMainShopCenterTypesInProgress");
              }

              if (state is GetMainShopCenterTypesSuccess) {
                print(
                    "GetMainShopCenterTypesSuccess - productCenterType: ${state.productCenterType}, debtorCenterType: ${state.debtorCenterType}, posProductCenterType: ${state.posProductCenterType}");
                // Update shop_info with center types from main shop using ShopModel
                String? shopInfoJson = appConfig.getString("shop_info");
                if (shopInfoJson != null && shopInfoJson.isNotEmpty) {
                  try {
                    ShopModel shopModel = ShopModel.fromJson(jsonDecode(shopInfoJson));
                    shopModel = ShopModel(
                      guidfixed: shopModel.guidfixed,
                      address: shopModel.address,
                      branchcode: shopModel.branchcode,
                      images: shopModel.images,
                      logo: shopModel.logo,
                      name1: shopModel.name1,
                      names: shopModel.names,
                      profilepicture: shopModel.profilepicture,
                      settings: shopModel.settings,
                      telephone: shopModel.telephone,
                      ismainshop: shopModel.ismainshop,
                      productcentertype: state.productCenterType,
                      debtorcentertype: state.debtorCenterType,
                      posproductcentertype: state.posProductCenterType,
                      mainshopid: shopModel.mainshopid,
                    );

                    appConfig.remove("shop_info");
                    appConfig.setString("shop_info", jsonEncode(shopModel.toJson()));
                    print("Updated shop_info with center types");
                  } catch (e) {
                    print("Error updating shop_info with center types: $e");
                  }
                }
              }

              if (state is GetMainShopCenterTypesFailed) {
                print("GetMainShopCenterTypesFailed: ${state.message}");
              }
            },
          ),
          BlocListener<CompanyBranchBloc, CompanyBranchState>(
            listener: (context, state) {
              if (state is CompanyBranchLoadSuccess) {
                if (state.companyBranch.length == 1) {
                  appConfig.setString("branch_guidfixed", state.companyBranch[0].guidfixed);
                  appConfig.setInt("branch_total", 1);
                  global.companyBranchSelectData = state.companyBranch[0];

                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MenuScreen()), (route) => false);
                } else {
                  setState(() {
                    companyBranchListData.clear();
                    companyBranchListData.addAll(state.companyBranch);
                    stateScreen = 3;
                  });
                }
              }

              if (state is CompanyBranchLoadFailed) {
                global.showSnackBar(
                  context,
                  const Icon(
                    Icons.error,
                    color: Colors.white,
                  ),
                  state.message,
                  Colors.red,
                );
              }
            },
          ),
          BlocListener<UserBloc, UserState>(
            listener: (context, state) {
              if (state is UserGetSuccess) {
                // save to local
                appConfig.setString("role", state.user.role.toString());
              } else if (state is UserGetFailed) {
                // show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error: ${state.message}"),
                  ),
                );
              }
            },
          ),
        ],
        child: SafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Text(global.language('select_shop'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(global.userLoginData.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              actions: [
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<LoginBloc>().add(const Logout());
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(
                    global.language('logout'),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      stateScreen = 2;
                      clearDataCreateShop();
                    });
                  },
                  icon: const Icon(Icons.add_business),
                  label: Text(global.language('create_shop'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            body: Scaffold(
              backgroundColor: Colors.cyan.shade100,
              body: Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                child: (stateScreen == 1)
                    ? listShopSelect()
                    : (stateScreen == 2)
                        ? createShop()
                        : listBranchSelect(),
              ),
            ),
          ),
        ));
  }
}
