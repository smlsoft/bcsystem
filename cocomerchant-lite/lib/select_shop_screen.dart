import 'package:auto_size_text/auto_size_text.dart';
import 'package:cocomerchant_lite/bloc/company_branch/company_branch_bloc.dart';
import 'package:cocomerchant_lite/bloc/list_shop/list_shop_bloc.dart';
import 'package:cocomerchant_lite/bloc/shop_select/shop_select_bloc.dart';
import 'package:cocomerchant_lite/global.dart';
import 'package:cocomerchant_lite/menu_screen.dart';
import 'package:cocomerchant_lite/model/company_branch_model.dart';
import 'package:cocomerchant_lite/model/shop_list_model.dart';
import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectShopScreen extends StatefulWidget {
  const SelectShopScreen({Key? key}) : super(key: key);

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
    context.read<ListShopBloc>().add(const ListShopLoad());
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
        onPressed: (shopid != appConfig.read("shopid"))
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
        onPressed: (guidfiexd != appConfig.read("branch_guidfixed"))
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
              global.setSystemLanguage(context);
              context.read<CompanyBranchBloc>().add(const CompanyBranchLoadList(offset: 0, limit: 100, search: ""));
            }
          },
        ),
        BlocListener<CompanyBranchBloc, CompanyBranchState>(
          listener: (context, state) {
            if (state is CompanyBranchLoadSuccess) {
              if (state.companyBranch.length == 1) {
                appConfig.write("branch_guidfixed", state.companyBranch[0].guidfixed);
                appConfig.write("branch_total", 1);

                global.companyBranchSelectData = state.companyBranch[0];

                global.setSystemLanguage(context);
                Future.delayed(const Duration(seconds: 1), () {
                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MenuScreen()), (route) => false);
                });
              } else {
                setState(() {
                  companyBranchListData = state.companyBranch;

                  screenBranch = true;
                });
              }
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
                        icon: (appConfig.read("user") == shop.createdby) ? Icons.business : null,
                        callback: () {
                          if (shop.shopid != appConfig.read("shopid")) {
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
                          if (branch.guidfixed != appConfig.read("guidfixed")) {
                            appConfig.write("branch_guidfixed", branch.guidfixed);
                            appConfig.write("branch_total", companyBranchListData.length);
                            global.companyBranchSelectData = branch;
                            await global.setSystemLanguage(context);
                            Future.delayed(const Duration(seconds: 1), () {
                              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MenuScreen()), (route) => false);
                            });
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
