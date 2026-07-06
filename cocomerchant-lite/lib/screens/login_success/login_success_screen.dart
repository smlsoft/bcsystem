import 'package:cocomerchant_lite/auth_service.dart';
import 'package:cocomerchant_lite/bloc/company_branch/company_branch_bloc.dart';
import 'package:cocomerchant_lite/bloc/list_shop/list_shop_bloc.dart';
import 'package:cocomerchant_lite/bloc/login_bloc/login_bloc.dart';
import 'package:cocomerchant_lite/bloc/profile/profile_bloc.dart';
import 'package:cocomerchant_lite/bloc/shop_select/shop_select_bloc.dart';
import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/create_shop/create_shop_screen.dart';
import 'package:cocomerchant_lite/model/company_branch_model.dart';
import 'package:cocomerchant_lite/model/shop_list_model.dart';
import 'package:cocomerchant_lite/model/shop_model.dart';
import 'package:cocomerchant_lite/screens/home/home_screen.dart';
import 'package:cocomerchant_lite/screens/menu/menu_screen.dart';
import 'package:cocomerchant_lite/screens/sign_in/sign_in_screen.dart';
import 'package:cocomerchant_lite/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocomerchant_lite/global.dart' as global;

class LoginSuccessScreen extends StatefulWidget {
  static String routeName = "/login_success";
  final bool isBranchSelect;

  const LoginSuccessScreen({super.key, this.isBranchSelect = false});

  @override
  LoginSuccessScreenState createState() => LoginSuccessScreenState();
}

class LoginSuccessScreenState extends State<LoginSuccessScreen> {
  final AuthService auth = AuthService();
  bool isBranchSelect = false;
  List<ShopListModel> shopList = [];
  List<CompanyBranchModel> companyBranchListData = [];

  @override
  void initState() {
    super.initState();
    setState(() {
      isBranchSelect = widget.isBranchSelect;
    });
    context.read<ProfileBloc>().add(const GetProfile());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as bool?;
    if (args != null) {
      setState(() {
        isBranchSelect = args;
      });
      context.read<CompanyBranchBloc>().add(const CompanyBranchLoadList(offset: 0, limit: 100, search: ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        /// Logout
        if (state is LogoutSuccess) {
          Navigator.pushNamed(context, SignInScreen.routeName);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: global.shopid != "" && global.companyBranchSelectData.guidfixed == ""
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      global.shopSelectData = ShopModel();
                      global.shopid = "";
                      isBranchSelect = false;
                    });
                  },
                )
              : global.shopid != "" && global.companyBranchSelectData.guidfixed != ""
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )
                  : const SizedBox(),
          title: Semantics(label: !isBranchSelect ? "เลือกร้านค้า" : "เลือกสาขา", child: Text(!isBranchSelect ? "เลือกร้านค้า" : "เลือกสาขา")),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                if (global.shopid != "") {
                  context.read<LoginBloc>().add(const Logout());
                } else {
                  auth.signOut();
                  Navigator.pushNamed(context, SignInScreen.routeName);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.pushNamed(context, CreateShopScreen.routeName);
              },
            ),
          ],
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<ProfileBloc, ProfileState>(
              listener: (context, state) {
                if (state is GetProfileSuccess) {
                  global.profileData = state.profile;
                  context.read<ListShopBloc>().add(const ListShopLoad());
                }
              },
            ),
            BlocListener<ListShopBloc, ListShopState>(
              listener: (context, state) {
                if (state is ListShopLoadSuccess) {
                  setState(() {
                    shopList = state.shop;
                  });
                }
              },
            ),
            BlocListener<ShopSelectBloc, ShopSelectState>(
              listener: (context, state) {
                if (state is ShopSelectLoadSuccess) {
                  global.setSystemLanguage(context);
                  context.read<CompanyBranchBloc>().add(const CompanyBranchLoadList(offset: 0, limit: 100, search: ""));
                }
              },
            ),
            BlocListener<CompanyBranchBloc, CompanyBranchState>(
              listener: (context, state) {
                if (state is CompanyBranchLoadSuccess) {
                  if (state.companyBranch.length == 1) {
                    global.appConfig.write("branch_guidfixed", state.companyBranch[0].guidfixed);
                    global.appConfig.write("branch_total", 1);
                    global.companyBranchSelectData = state.companyBranch[0];

                    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MenuScreen()), (route) => false);
                  } else {
                    setState(() {
                      companyBranchListData.clear();
                      companyBranchListData.addAll(state.companyBranch);
                      isBranchSelect = true;
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
          ],
          child: Stack(
            children: [
              // Align(
              //   alignment: Alignment.bottomCenter,
              //   child: Image.asset(
              //     "assets/images/success.png",
              //     height: SizeConfig.screenHeight * 0.4, // 40%
              //   ),
              // ),
              Column(
                children: [
                  if (!isBranchSelect)
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemCount: shopList.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Card(
                              color: global.shopSelectData.guidfixed == shopList[index].shopid ? Colors.grey : kPrimaryLightColor,
                              child: ListTile(
                                onTap: global.shopSelectData.guidfixed == shopList[index].shopid
                                    ? null
                                    : () {
                                        context.read<ShopSelectBloc>().add(ShopSelect(shop: shopList[index]));
                                      },
                                leading: (global.appConfig.read("user") == shopList[index].createdby) ? const Icon(Icons.business) : null,
                                title: Semantics(
                                  label: (shopList[index].name.isEmpty) ? global.packName(shopList[index].names!) : shopList[index].name,
                                  child: Text(
                                    (shopList[index].name.isEmpty) ? global.packName(shopList[index].names!) : shopList[index].name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemCount: companyBranchListData.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Card(
                            color: global.companyBranchSelectData.guidfixed == companyBranchListData[index].guidfixed ? Colors.grey : Colors.blue.shade100,
                            child: ListTile(
                              onTap: global.companyBranchSelectData.guidfixed != companyBranchListData[index].guidfixed
                                  ? () {
                                      global.companyBranchSelectData = companyBranchListData[index];
                                      global.appConfig.write("branch_guidfixed", companyBranchListData[index].guidfixed);
                                      global.appConfig.write("branch_total", companyBranchListData.length);
                                      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MenuScreen()), (route) => false);
                                    }
                                  : null,
                              leading: const Icon(Icons.home_work_rounded),
                              title: Semantics(
                                label: global.packName(companyBranchListData[index].names),
                                child: Text(
                                  global.packName(companyBranchListData[index].names),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: SizeConfig.screenHeight * 0.08),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
