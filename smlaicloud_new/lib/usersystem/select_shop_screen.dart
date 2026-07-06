import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:smlaicloud/bloc/company_branch/company_branch_bloc.dart';
import 'package:smlaicloud/bloc/list_shop/list_shop_bloc.dart';
import 'package:smlaicloud/bloc/shop/shop_bloc.dart';
import 'package:smlaicloud/bloc/shop_select/shop_select_bloc.dart';
import 'package:smlaicloud/bloc/user/user_bloc.dart';
import 'package:smlaicloud/global.dart';
import 'package:smlaicloud/menu_screen.dart';
import 'package:smlaicloud/model/company_branch_model.dart';
import 'package:smlaicloud/model/shop_list_model.dart';
import 'package:smlaicloud/model/shop_model.dart';
import 'package:flutter/material.dart';
import 'package:smlaicloud/global.dart' as global;
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectShopScreen extends StatefulWidget {
  const SelectShopScreen({super.key});

  @override
  SelectShopScreenState createState() => SelectShopScreenState();
}

class SelectShopScreenState extends State<SelectShopScreen> {
  List<ShopListModel> listData = [];
  List<CompanyBranchModel> companyBranchListData = [];
  bool screenBranch = false;

  @override
  void initState() {
    loadDataList();
    super.initState();
  }

  void loadDataList() {
    context.read<ListShopBloc>().add(ListShopLoad());
  }

  Widget menuWidget({required String shopid, required String label, Color color = Colors.white, icon, required Function callback}) {
    Widget textWidget = Center(child: AutoSizeText(label, maxLines: 3, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(4),
          foregroundColor: Colors.black,
          backgroundColor: color,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        onPressed: (shopid != global.getShopId())
            ? () {
                callback();
              }
            : null,
        child: (icon == null)
            ? textWidget
            : Stack(
                children: [
                  textWidget,
                  Positioned(right: 4, top: 8, child: Icon(icon as IconData, size: 25)),
                ],
              ));
  }

  Widget branchWidget({required String guidfiexd, required String label, Color color = Colors.white, icon, required Function callback}) {
    Widget textWidget = Center(child: AutoSizeText(label, maxLines: 3, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(4),
          foregroundColor: Colors.black,
          backgroundColor: color,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
        onPressed: (guidfiexd != global.getBranchGuidFixed())
            ? () {
                callback();
              }
            : null,
        child: (icon == null)
            ? textWidget
            : Stack(
                children: [
                  textWidget,
                  Positioned(right: 4, top: 8, child: Icon(icon as IconData, size: 25)),
                ],
              ));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ListShopBloc, ListShopState>(
          listener: (context, state) {
            if (state is ListShopLoadSuccess) {
              setState(() {
                listData.clear();
                listData = state.shop;
              });
            }
          },
        ),
        BlocListener<ShopSelectBloc, ShopSelectState>(
          listener: (context, state) {
            if (state is ShopSelectLoadSuccess) {
              // Load shop info when shop is selected
              context.read<ShopBloc>().add(GetShopInfo(shopid: state.shop.shopid));

              context.read<CompanyBranchBloc>().add(const CompanyBranchLoadList(offset: 0, limit: 100, search: ""));

              context.read<UserBloc>().add(UserGet(username: appConfig.getString("user")!));
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
                  "GetMainShopCenterTypesSuccess - productCenterType: ${state.productCenterType}, debtorCenterType: ${state.debtorCenterType} , posProductCenterType: ${state.posProductCenterType}");
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
                  companyBranchListData = state.companyBranch;
                  screenBranch = true;
                });
              }
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
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            screenBranch
                ? global.language("select_branch")
                : global.language(
                    "select_shop",
                  ),
          ),
          backgroundColor: global.theme.appBarColor,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: !screenBranch
                ? GridView.builder(
                    padding: const EdgeInsets.all(0),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, crossAxisSpacing: 10, mainAxisSpacing: 10),
                    itemCount: listData.length,
                    itemBuilder: (BuildContext ctx, index) {
                      final shop = listData[index];
                      return menuWidget(
                        shopid: shop.shopid,
                        label: (shop.name.isEmpty) ? global.packName(shop.names!) : shop.name,
                        color: Colors.orange.shade100,
                        icon: (appConfig.getString("user") == shop.createdby) ? Icons.business : null,
                        callback: () {
                          if (shop.shopid != global.getShopId()) {
                            context.read<ShopSelectBloc>().add(ShopSelect(shop: shop));
                          }
                        },
                      );
                    },
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(0),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, crossAxisSpacing: 10, mainAxisSpacing: 10),
                    itemCount: companyBranchListData.length,
                    itemBuilder: (BuildContext ctx, index) {
                      final branch = companyBranchListData[index];
                      return branchWidget(
                        guidfiexd: branch.guidfixed,
                        label: global.packName(branch.names),
                        color: Colors.blue.shade100,
                        icon: Icons.home_work_rounded,
                        callback: () async {
                          if (branch.guidfixed != appConfig.getString("guidfixed")) {
                            appConfig.setString("branch_guidfixed", branch.guidfixed);
                            appConfig.setInt("branch_total", companyBranchListData.length);
                            global.companyBranchSelectData = branch;
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/menu',
                              (Route<dynamic> route) => false,
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
