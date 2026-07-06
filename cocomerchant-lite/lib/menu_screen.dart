import 'package:cocomerchant_lite/screens/sign_in/sign_in_screen.dart';
import 'package:cocomerchant_lite/select_branch_screen.dart';
import 'package:cocomerchant_lite/select_language_screen.dart';
import 'package:cocomerchant_lite/select_shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/bloc/login_bloc/login_bloc.dart';
import 'package:cocomerchant_lite/bloc/profile/profile_bloc.dart';
import 'package:cocomerchant_lite/global.dart';
import 'package:cocomerchant_lite/model/profile_model.dart';
import 'package:cocomerchant_lite/model/timezones_model.dart';

import 'package:cocomerchant_lite/global.dart' as global;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dropdown_search/dropdown_search.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => MenuScreenState();
}

class MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late TabController mainTabController = TabController(length: 3, vsync: this, initialIndex: global.activeIndexMenu);
  List<Widget> masterMenuList = [];
  List<Widget> masterProductMenuList = [];
  List<Widget> transactionPurchaseMenuList = [];
  List<Widget> transactionSaleMenuList = [];
  List<Widget> transactionStockMenuList = [];
  List<Widget> transactionPaidMenuList = [];
  List<Widget> reportMenuList = [];
  List<Widget> customerMenuList = [];
  List<Widget> newMenuList = [];
  List<Widget> configMenuList = [];
  List<Widget> restaurantMenuList = [];
  List<Widget> glMenuList = [];
  List<Widget> configCompanyMenuList = [];

  Widget menuWidget({required String label, Color color = Colors.white, icon, required Function callback}) {
    Widget textWidget = Center(
      child: Text(
        label,
        maxLines: 3,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(4),
        foregroundColor: Colors.black,
        backgroundColor: color,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
      onPressed: () {
        callback();
      },
      child: (icon == null)
          ? textWidget
          : Stack(
              children: [
                textWidget,
                Positioned(right: 4, top: 8, child: Icon(icon as IconData, size: 25)),
              ],
            ),
    );
  }

  void buildMenuLite() {
    masterMenuList = [];
    configMenuList = [];
    configCompanyMenuList = [];

    masterMenuList.add(
      menuWidget(
          label: global.language("product"),
          icon: Icons.barcode_reader,
          callback: () {
            Navigator.pushNamed(context, '/product');
          }),
    );
    masterMenuList.add(
      menuWidget(
          label: global.language("product_unit"),
          icon: Icons.format_list_numbered,
          callback: () {
            Navigator.pushNamed(context, '/productunit');
          }),
    );
    masterMenuList.add(
      menuWidget(
          label: global.language("product_category"),
          icon: Icons.category,
          callback: () {
            Navigator.pushNamed(context, '/productcategory');
          }),
    );
    masterMenuList.add(
      menuWidget(
          label: global.language("product_category_list"),
          icon: Icons.category_sharp,
          callback: () {
            Navigator.pushNamed(context, '/productcategorylist');
          }),
    );

    configMenuList.add(
      menuWidget(
          label: global.language("table"),
          color: Colors.cyan.shade100,
          icon: Icons.table_bar,
          callback: () {
            Navigator.pushNamed(context, '/table');
          }),
    );
    configMenuList.add(
      menuWidget(
          label: global.language("sale_channel"),
          color: Colors.cyan.shade100,
          icon: Icons.send,
          callback: () {
            Navigator.pushNamed(context, '/salechannel');
          }),
    );

    configMenuList.add(
      menuWidget(
          label: global.language("pos_media"),
          color: Colors.cyan.shade100,
          icon: Icons.display_settings,
          callback: () {
            Navigator.pushNamed(context, '/posmedia');
          }),
    );

    configMenuList.add(
      menuWidget(
        label: global.language("qr_provider"),
        color: Colors.cyan.shade100,
        icon: Icons.qr_code,
        callback: () {
          Navigator.pushNamed(context, '/qrprovider');
        },
      ),
    );
    configMenuList.add(
      menuWidget(
          label: global.language("order_template_setting"),
          color: Colors.cyan.shade100,
          icon: Icons.monitor_weight_outlined,
          callback: () {
            Navigator.pushNamed(context, '/ordertemplatsetting');
          }),
    );

    configMenuList.add(
      menuWidget(
        label: global.language("order_setting"),
        color: Colors.cyan.shade100,
        icon: Icons.monitor_weight_outlined,
        callback: () {
          Navigator.pushNamed(context, '/ordersetting');
        },
      ),
    );

    configMenuList.add(
      menuWidget(
          label: global.language("qr_code_order"),
          color: Colors.cyan.shade100,
          icon: Icons.add,
          callback: () {
            Navigator.pushNamed(context, '/qrcodeorder');
          }),
    );

    configMenuList.add(
      menuWidget(
          label: global.language("kitchen"),
          color: Colors.cyan.shade100,
          icon: Icons.kitchen,
          callback: () {
            Navigator.pushNamed(context, '/kitchen');
          }),
    );

    configMenuList.add(
      menuWidget(
          label: global.language("add_product_to_kitchen"),
          color: Colors.cyan.shade100,
          icon: Icons.add,
          callback: () {
            Navigator.pushNamed(context, '/addproducttokitchen');
          }),
    );

    configCompanyMenuList.add(
      menuWidget(
        label: global.language("system_config"),
        color: Colors.orange.shade100,
        icon: Icons.business,
        callback: () {
          Navigator.pushNamed(context, '/config_system');
        },
      ),
    );
    configCompanyMenuList.add(menuWidget(
        label: global.language("company"),
        color: Colors.orange.shade100,
        icon: Icons.business,
        callback: () {
          Navigator.pushNamed(context, '/company');
        }));
  }

  void setSystemLanguageList() async {
    await global.setSystemLanguage(context);
    TabController(length: 3, vsync: this, initialIndex: global.activeIndexMenu);

    mainTabController.addListener(() {
      global.activeIndexMenu = mainTabController.index;
    });

    buildMenuLite();

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    setSystemLanguageList();
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;

    return MultiBlocListener(
      listeners: [
        BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            /// Logout
            if (state is LogoutSuccess) {
              Navigator.pushNamed(context, SignInScreen.routeName);
            }
          },
        ),
        BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is UpdateProfileSuccess) {
              setState(() {
                global.showSnackBar(
                    context,
                    const Icon(
                      Icons.edit,
                      color: Colors.white,
                    ),
                    global.language("edit_success"),
                    Colors.blue);
              });
              // Clear the state after a delay
              context.read<ProfileBloc>().add(const GetProfile());
            }

            if (state is GetProfileSuccess) {
              setState(() {
                global.profileData = state.profile;
              });
            }
          },
        ),
      ],
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: PreferredSize(
          preferredSize: Size(screenSize.width, 1000),
          child: Container(
            color: global.theme.appBarColor,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("COCO Merchant Lite", style: TextStyle(color: Colors.white, fontSize: 18)),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          context.read<LoginBloc>().add(const Logout());
                        },
                        child: const Icon(Icons.logout, color: Colors.white),
                      ),
                      SizedBox(
                        width: screenSize.width / 100,
                      ),
                      IconButton(
                        icon: Container(
                            width: 32,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 1),
                            ),
                            child: Image.asset('assets/flags/${global.userLanguage}.png')),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SelectLanguageScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        body: DedeMerchantLiteWidget(
          masterMenuList: masterMenuList,
          configMenuList: configMenuList,
          configCompanyMenuList: configCompanyMenuList,
        ),
        bottomNavigationBar: null,
      ),
    );
  }
}

class DedeMerchantWidget extends StatelessWidget {
  const DedeMerchantWidget({
    super.key,
    required this.mainTabController,
    required this.transactionPurchaseMenuList,
    required this.transactionSaleMenuList,
    required this.transactionStockMenuList,
    required this.transactionPaidMenuList,
    required this.reportMenuList,
    required this.glMenuList,
    required this.masterMenuList,
    required this.masterProductMenuList,
    required this.customerMenuList,
    required this.newMenuList,
    required this.restaurantMenuList,
    required this.configMenuList,
  });

  final TabController mainTabController;
  final List<Widget> transactionPurchaseMenuList;
  final List<Widget> transactionSaleMenuList;
  final List<Widget> transactionStockMenuList;
  final List<Widget> transactionPaidMenuList;
  final List<Widget> reportMenuList;
  final List<Widget> glMenuList;
  final List<Widget> masterMenuList;
  final List<Widget> masterProductMenuList;
  final List<Widget> customerMenuList;
  final List<Widget> newMenuList;
  final List<Widget> restaurantMenuList;
  final List<Widget> configMenuList;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.blue, gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Colors.blue.shade200, Colors.blue])),
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                controller: mainTabController,
                children: [
                  SingleChildScrollView(
                      child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(children: [
                            GridView.builder(
                                padding: const EdgeInsets.all(0),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, crossAxisSpacing: 10, mainAxisSpacing: 10),
                                itemCount: transactionPurchaseMenuList.length,
                                itemBuilder: (BuildContext ctx, index) {
                                  return transactionPurchaseMenuList[index];
                                }),
                            const SizedBox(
                              height: 25,
                            ),
                            GridView.builder(
                                padding: const EdgeInsets.all(0),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, crossAxisSpacing: 10, mainAxisSpacing: 10),
                                itemCount: transactionSaleMenuList.length,
                                itemBuilder: (BuildContext ctx, index) {
                                  return transactionSaleMenuList[index];
                                }),
                            const SizedBox(
                              height: 25,
                            ),
                            GridView.builder(
                                padding: const EdgeInsets.all(0),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, crossAxisSpacing: 10, mainAxisSpacing: 10),
                                itemCount: transactionStockMenuList.length,
                                itemBuilder: (BuildContext ctx, index) {
                                  return transactionStockMenuList[index];
                                }),
                            const SizedBox(
                              height: 25,
                            ),
                            GridView.builder(
                                padding: const EdgeInsets.all(0),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, crossAxisSpacing: 10, mainAxisSpacing: 10),
                                itemCount: transactionPaidMenuList.length,
                                itemBuilder: (BuildContext ctx, index) {
                                  return transactionPaidMenuList[index];
                                }),
                            const SizedBox(
                              height: 25,
                            ),
                            GridView.builder(
                                padding: const EdgeInsets.all(0),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, crossAxisSpacing: 10, mainAxisSpacing: 10),
                                itemCount: reportMenuList.length,
                                itemBuilder: (BuildContext ctx, index) {
                                  return reportMenuList[index];
                                }),
                            const SizedBox(
                              height: 25,
                            ),
                            GridView.builder(
                                padding: const EdgeInsets.all(0),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, crossAxisSpacing: 10, mainAxisSpacing: 10),
                                itemCount: glMenuList.length,
                                itemBuilder: (BuildContext ctx, index) {
                                  return glMenuList[index];
                                }),
                          ]))),
                  SingleChildScrollView(
                      child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(children: [
                            GridView.builder(
                                padding: const EdgeInsets.all(0),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, crossAxisSpacing: 10, mainAxisSpacing: 10),
                                itemCount: masterMenuList.length,
                                itemBuilder: (BuildContext ctx, index) {
                                  return masterMenuList[index];
                                }),
                            const SizedBox(
                              height: 25,
                            ),
                            GridView.builder(
                                padding: const EdgeInsets.all(0),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, crossAxisSpacing: 10, mainAxisSpacing: 10),
                                itemCount: masterProductMenuList.length,
                                itemBuilder: (BuildContext ctx, index) {
                                  return masterProductMenuList[index];
                                }),
                            const SizedBox(
                              height: 25,
                            ),
                            GridView.builder(
                                padding: const EdgeInsets.all(0),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, crossAxisSpacing: 10, mainAxisSpacing: 10),
                                itemCount: customerMenuList.length,
                                itemBuilder: (BuildContext ctx, index) {
                                  return customerMenuList[index];
                                }),
                            const SizedBox(
                              height: 25,
                            ),
                            GridView.builder(
                                padding: const EdgeInsets.all(0),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, crossAxisSpacing: 10, mainAxisSpacing: 10),
                                itemCount: newMenuList.length,
                                itemBuilder: (BuildContext ctx, index) {
                                  return newMenuList[index];
                                }),
                            const SizedBox(
                              height: 25,
                            ),
                            GridView.builder(
                                padding: const EdgeInsets.all(0),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, crossAxisSpacing: 10, mainAxisSpacing: 10),
                                itemCount: restaurantMenuList.length,
                                itemBuilder: (BuildContext ctx, index) {
                                  return restaurantMenuList[index];
                                }),
                          ]))),
                  SingleChildScrollView(
                      child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: GridView.builder(
                        padding: const EdgeInsets.all(0),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, crossAxisSpacing: 10, mainAxisSpacing: 10),
                        itemCount: configMenuList.length,
                        itemBuilder: (BuildContext ctx, index) {
                          return configMenuList[index];
                        }),
                  )),
                ],
              ),
            )
          ],
        ));
  }
}

class DedeMerchantLiteWidget extends StatelessWidget {
  const DedeMerchantLiteWidget({
    super.key,
    required this.masterMenuList,
    required this.configMenuList,
    required this.configCompanyMenuList,
  });

  final List<Widget> masterMenuList;
  final List<Widget> configMenuList;
  final List<Widget> configCompanyMenuList;

  @override
  Widget build(BuildContext context) {
    Future<dynamic> dialogProfile(BuildContext contexte) {
      TimezonesModel timezonesModel = TimezonesModel(
        abbr: '',
        isDst: false,
        offset: '',
        text: '',
        utc: [],
        value: '',
      );

      String yeartype = "";

      if (global.profileData.timezonelabel!.isNotEmpty) {
        timezonesModel = global.timezonesListData.firstWhere((element) => element.text == global.profileData.timezonelabel);
      }

      if (global.profileData.yeartype!.isNotEmpty) {
        yeartype = global.profileData.yeartype!;
      }

      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text((appConfig.read("name") != "") ? appConfig.read("name") : global.activeLangName(global.shopSelectData.names!)),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return SizedBox(
                  width: 500,
                  height: 200,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person),
                          Text(global.profileData.name!),
                        ],
                      ),
                      const SizedBox(
                        height: 15.0,
                      ),
                      DropdownSearch<TimezonesModel>(
                        asyncItems: (String filter) => global.getTimezonesList(filter),
                        compareFn: (item, selectedItem) => item.text == selectedItem.text,
                        itemAsString: (TimezonesModel? timezone) {
                          if (timezone!.text.isEmpty) return '';
                          return timezone.text;
                        },
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            labelText: global.language("timezone"),
                          ),
                        ),
                        onChanged: (TimezonesModel? value) {
                          setState(() {
                            timezonesModel = value!;
                          });
                        },
                        popupProps: const PopupPropsMultiSelection.dialog(
                          showSearchBox: true,
                          showSelectedItems: true,
                        ),
                        selectedItem: timezonesModel,
                      ),
                      const SizedBox(
                        height: 15.0,
                      ),

                      /// radio button year type buddhist or christian
                      Row(children: [
                        Radio(
                          value: "christian",
                          groupValue: yeartype, // Update groupValue
                          onChanged: (value) {
                            setState(() {
                              yeartype = value.toString(); // Update yeartype
                            });
                          },
                        ),
                        Text(global.language("christian")),
                        Radio(
                          value: "buddhist",
                          groupValue: yeartype, // Update groupValue
                          onChanged: (value) {
                            setState(() {
                              yeartype = value.toString(); // Update yeartype
                            });
                          },
                        ),
                        Text(global.language("buddhist")),
                      ]),
                    ],
                  ),
                );
              },
            ),
            actions: [
              /// update profile
              TextButton(
                onPressed: () {
                  ProfileModel profileModel = ProfileModel(
                    username: global.profileData.username,
                    name: global.profileData.name,
                    avatar: global.profileData.avatar,
                    timezonelabel: timezonesModel.text,
                    timezoneoffset: timezonesModel.offset,
                    yeartype: yeartype,
                  );
                  Navigator.pop(context);
                  context.read<ProfileBloc>().add(UpdateProfile(profile: profileModel));
                },
                child: Text(global.language("update")),
              ),

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(global.language("close")),
              ),
            ],
          );
        },
      );
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF88975),
            Color(0xFFF56045),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text(
                        (appConfig.read("name") != "" || appConfig.read("name") != null)
                            ? appConfig.read("name") ?? 'Unknown Shop'
                            : global.activeLangName(
                                global.shopSelectData.names!,
                              ),
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      InkWell(
                        onTap: (appConfig.read("branch_total") != 1)
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SelectBranchScreen()),
                                );
                              }
                            : null,
                        child: Text(
                          " (${global.activeLangName(global.companyBranchSelectData.names)})",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  dialogProfile(context);
                },
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white),
                    Text(appConfig.read("user") ?? 'Unknown User', style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SelectShopScreen()),
                  );
                },
                child: const Icon(Icons.swap_vert, color: Colors.white),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    GridView.builder(
                      padding: const EdgeInsets.all(0),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, crossAxisSpacing: 10, mainAxisSpacing: 10),
                      itemCount: masterMenuList.length,
                      itemBuilder: (BuildContext ctx, index) {
                        return masterMenuList[index];
                      },
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    GridView.builder(
                      padding: const EdgeInsets.all(0),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, crossAxisSpacing: 10, mainAxisSpacing: 10),
                      itemCount: configMenuList.length,
                      itemBuilder: (BuildContext ctx, index) {
                        return configMenuList[index];
                      },
                    ),
                    const SizedBox(
                      height: 25,
                    ),
                    GridView.builder(
                      padding: const EdgeInsets.all(0),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, crossAxisSpacing: 10, mainAxisSpacing: 10),
                      itemCount: configCompanyMenuList.length,
                      itemBuilder: (BuildContext ctx, index) {
                        return configCompanyMenuList[index];
                      },
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
