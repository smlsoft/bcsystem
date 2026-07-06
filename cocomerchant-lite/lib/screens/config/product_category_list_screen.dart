import 'package:cocomerchant_lite/bloc/product_barcode/product_barcode_bloc.dart';
import 'package:cocomerchant_lite/bloc/product_category/product_category_bloc.dart';
import 'package:cocomerchant_lite/model/product_category_model.dart';
import 'package:cocomerchant_lite/model/product_model.dart';
import 'package:cocomerchant_lite/screen_search/product_category_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:split_view/split_view.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:flutter_draggable_gridview/flutter_draggable_gridview.dart';

class ProductCategoryListScreen extends StatefulWidget {
  const ProductCategoryListScreen({Key? key}) : super(key: key);

  @override
  State<ProductCategoryListScreen> createState() => ProductCategoryListScreenState();
}

class ProductCategoryListScreenState extends State<ProductCategoryListScreen> with SingleTickerProviderStateMixin {
  TextEditingController searchController = TextEditingController();
  List<DraggableGridItem> draggableGridItemList = [];
  List<ProductBarcodeModel> listData = [];
  bool loadingData = false;
  bool isDataChange = false;
  FocusNode searchFocusNode = FocusNode(skipTraversal: true);
  final _debouncer = global.Debouncer(1000);
  ScrollController listScrollController = ScrollController();
  List<SearchCodeAndNameAndUnitModel> productList = [];
  String searchText = "";
  String selectGuid = "";
  String selectProductCategoryGuid = "";
  String selectProductCategoryName = "";
  ProductCategoryModel? selectProductCategory;
  late SplitViewController splitViewController;
  int selectedGroupNumber = 1;
  @override
  void initState() {
    rebuildGrid();
    loadDataList("");
    listScrollController.addListener(onScrollList);
    splitViewController = SplitViewController(limits: [null, WeightLimit(min: 0.2, max: 0.8)]);
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void rebuildGrid() {
    draggableGridItemList = [];
    for (int i = 0; i < productList.length; i++) {
      draggableGridItemList.add(DraggableGridItem(isDraggable: true, child: objectBox(productList[i])));
    }
  }

  Widget objectBox(SearchCodeAndNameAndUnitModel data) {
    return Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
        ),
        child: Column(
          children: [
            Container(
                padding: const EdgeInsets.all(4),
                width: double.infinity,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2))),
                    onPressed: () {
                      isDataChange = true;
                      productList.removeAt(productList.indexOf(data));
                      rebuildGrid();
                      setState(() {});
                    },
                    child: const Icon(Icons.close))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
                child: Column(
                  children: [
                    Text(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      data.barcode,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        global.packName(data.name),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      data.unitcode,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                        child: Text(
                      global.packName(data.unitname),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ));
  }

  void discardData({required Function callBack}) {
    if (isDataChange) {
      showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                title: Text(global.language('data_editing')),
                content: Text(global.language('leave_this_screen')),
                actions: <Widget>[
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context), child: Text(global.language('no'))),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      onPressed: () {
                        Navigator.pop(context);
                        callBack();
                      },
                      child: Text(global.language('yes'))),
                ],
              ));
    } else {
      callBack();
    }
  }

  Widget listObject(int index, ProductBarcodeModel value) {
    return GestureDetector(
        onTap: () {},
        onDoubleTap: () {},
        child: Container(
            color: (index % 2 == 0) ? global.theme.columnAlternateEvenColor : global.theme.columnAlternateOddColor,
            padding: EdgeInsets.only(left: 10, right: 10, top: global.deviceConfig.listDataLineSpace, bottom: global.deviceConfig.listDataLineSpace),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 5, child: Text(value.barcode!, maxLines: 2, overflow: TextOverflow.ellipsis)),
              Expanded(
                  flex: 5,
                  child: Text(
                    global.packName(value.names!),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )),
              Expanded(flex: 5, child: Text(global.packName(value.itemunitnames!), maxLines: 2, overflow: TextOverflow.ellipsis)),
              Expanded(flex: 5, child: Text(value.itemcode!, maxLines: 2, overflow: TextOverflow.ellipsis)),
              Expanded(flex: 5, child: Text(global.packName(value.groupnames!), maxLines: 2, overflow: TextOverflow.ellipsis)),
              IconButton(
                  onPressed: () {
                    bool found = false;
                    for (int i = 0; i < productList.length; i++) {
                      if (productList[i].barcode == value.barcode) {
                        found = true;
                        break;
                      }
                    }
                    if (found == false) {
                      isDataChange = true;
                      productList.add(SearchCodeAndNameAndUnitModel(
                          barcode: value.barcode!, code: value.itemcode!, name: value.names!, unitcode: value.itemunitcode!, unitname: value.itemunitnames!));
                      rebuildGrid();
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.add)),
            ])));
  }

  void loadDataList(String search) {
    setState(() {
      loadingData = true;
    });
    searchText = search;
    context.read<ProductBarcodeBloc>().add(ProductBarcodeLoadList(
          offset: (listData.isEmpty) ? 0 : listData.length,
          limit: global.loadDataPerPage,
          search: search,
          branchcode: global.companyBranchSelectData.code,
          businesstypecode: global.companyBranchSelectData.businesstype!.code!,
        ));
  }

  Widget listScreen() {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(children: [
        Container(
            height: 40,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(children: [
              Expanded(
                  child: TextField(
                      onSubmitted: (value) {
                        searchFocusNode.requestFocus();
                      },
                      onChanged: (value) {
                        _debouncer.run(() {
                          setState(() {
                            listData = [];
                          });
                          loadDataList(value);
                        });
                      },
                      autofocus: false,
                      focusNode: searchFocusNode,
                      controller: searchController,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.only(top: 0, bottom: 0, left: 0, right: 0),
                        border: InputBorder.none,
                        hintText: global.language('search'),
                      ))),
            ])),
        Container(
          color: global.theme.appBarColor,
          height: 6,
        ),
        Container(
            key: const Key('barcode_list'),
            padding: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
            color: global.theme.columnHeaderColor,
            child: Row(children: [
              Expanded(flex: 5, child: Text(global.language("barcode"), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
              Expanded(
                  flex: 5,
                  child: Text(
                    global.language("product_name"),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )),
              Expanded(flex: 5, child: Text(global.language("unit"), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
              Expanded(flex: 5, child: Text(global.language("item_code"), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
              Expanded(flex: 5, child: Text(global.language("product_group"), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
            ])),
        Expanded(child: ListView(controller: listScrollController, children: listData.map((value) => listObject(listData.indexOf(value), value)).toList())),
        if (loadingData)
          Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
            color: Colors.blue,
            size: 50,
          ))
      ]),
    );
  }

  void onScrollList() {
    if (listScrollController.offset >= listScrollController.position.maxScrollExtent && !listScrollController.position.outOfRange) {
      loadDataList(searchText);
    }
  }

  Widget gridView() {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
          padding: const EdgeInsets.all(5),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 50,
                    child: DropdownMenu<int>(
                      initialSelection: global.groupNumber.first,
                      onSelected: (int? value) {
                        // This is called when the user selects an item.
                        setState(() {
                          selectedGroupNumber = value!;
                        });
                      },
                      dropdownMenuEntries: global.groupNumber.map<DropdownMenuEntry<int>>((int value) {
                        return DropdownMenuEntry<int>(value: value, label: "${global.language("group_number")} : $value");
                      }).toList(),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          discardData(callBack: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductCategorySearchScreen(
                                  groupnumber: selectedGroupNumber,
                                ),
                              ),
                            ).then((value) {
                              if (value != null) {
                                if (value[0].isNotEmpty) {
                                  selectProductCategoryGuid = value[0];
                                  selectProductCategoryName = global.packName(value[1]);
                                  context.read<ProductCategoryBloc>().add(ProductCategoryGet(guid: selectProductCategoryGuid));
                                }
                              }
                            });
                          });
                        },
                        child: Text((selectProductCategoryGuid.isEmpty) ? global.language("select_product_category") : selectProductCategoryName),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  SizedBox(
                    width: 100,
                    height: 50,
                    child: ElevatedButton(
                        onPressed: (selectProductCategoryGuid.isNotEmpty)
                            ? () {
                                selectProductCategory?.codelist = [];
                                for (int i = 0; i < productList.length; i++) {
                                  selectProductCategory?.codelist!.add(ProductCategoryCodeListModel(
                                      xorder: i,
                                      barcode: productList[i].barcode,
                                      unitcode: productList[i].unitcode,
                                      unitnames: productList[i].unitname,
                                      code: productList[i].code,
                                      names: productList[i].name));
                                }
                                context.read<ProductCategoryBloc>().add(
                                      ProductCategoryUpdate(guid: selectProductCategoryGuid, category: selectProductCategory!),
                                    );
                              }
                            : null,
                        child: const Icon(
                          Icons.save,
                          color: Colors.white,
                        )),
                  ),
                ],
              ),
              Expanded(
                  child: (productList.isEmpty)
                      ? const Center(child: Text("ยังไม่เลือกสินค้า"))
                      : DraggableGridViewBuilder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: constraints.widthConstraints().maxWidth ~/ 150,
                          ),
                          children: draggableGridItemList,
                          isOnlyLongPress: true,
                          dragCompletion: (List<DraggableGridItem> list, int beforeIndex, int afterIndex) {
                            // // print('onDragAccept: $beforeIndex -> $afterIndex');
                            productList.insert(afterIndex, productList.removeAt(beforeIndex));
                          },
                          dragFeedback: (List<DraggableGridItem> list, int index) {
                            return objectBox(productList[index]);
                          },
                          dragPlaceHolder: (List<DraggableGridItem> list, int index) {
                            return PlaceHolderWidget(
                              child: Container(
                                color: Colors.white,
                              ),
                            );
                          },
                        ))
            ],
          ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return MultiBlocListener(
        listeners: [
          BlocListener<ProductBarcodeBloc, ProductBarcodeState>(listener: (context, state) {
            // Load
            if (state is ProductBarcodeLoadSuccess) {
              setState(() {
                loadingData = false;
                if (state.productBarcodes.isNotEmpty) {
                  listData.addAll(state.productBarcodes);
                }
              });
            }
            if (state is ProductBarcodeLoadFailed) {
              setState(() {
                loadingData = false;
              });
            }
          }),
          BlocListener<ProductCategoryBloc, ProductCategoryState>(listener: (context, state) {
            // Load
            if (state is ProductCategoryGetSuccess) {
              productList = [];
              selectProductCategory = state.category;
              for (int i = 0; i < state.category.codelist!.length; i++) {
                productList.add(SearchCodeAndNameAndUnitModel(
                  barcode: state.category.codelist![i].barcode,
                  code: state.category.codelist![i].code,
                  name: state.category.codelist![i].names!,
                  unitcode: state.category.codelist![i].unitcode,
                  unitname: state.category.codelist![i].unitnames!,
                ));
              }
              rebuildGrid();
              setState(() {});
            }
            if (state is ProductCategoryUpdateSuccess) {
              setState(() {
                global.showSnackBar(
                    context,
                    const Icon(
                      Icons.edit,
                      color: Colors.white,
                    ),
                    "แก้ไขสำเร็จ",
                    Colors.blue);
                productList = [];
                isDataChange = false;
                selectGuid = "";
                selectProductCategoryGuid = "";
                selectProductCategoryName = "";
                setState(() {});
              });
            }
            if (state is ProductCategoryUpdateFailed) {
              setState(() {
                global.showSnackBar(
                    context,
                    const Icon(
                      Icons.edit,
                      color: Colors.white,
                    ),
                    "แก้ไขไม่สำเร็จ : ${state.message}",
                    Colors.red);
              });
            }
          })
        ],
        child: Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              backgroundColor: global.theme.appBarColor,
              automaticallyImplyLeading: false,
              title: Text(global.language('product_category')),
              leading: IconButton(
                focusNode: FocusNode(skipTraversal: true),
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  discardData(callBack: () {
                    // Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/menu');
                  });
                },
              ),
            ),
            body: (constraints.maxWidth < 800.0)
                ? SplitView(
                    controller: splitViewController,
                    gripSize: 8,
                    gripColor: global.theme.appBarColor,
                    gripColorActive: Colors.blue,
                    viewMode: SplitViewMode.Vertical,
                    indicator: const SplitIndicator(viewMode: SplitViewMode.Vertical),
                    activeIndicator: const SplitIndicator(
                      viewMode: SplitViewMode.Vertical,
                      isActive: true,
                    ),
                    children: [
                        listScreen(),
                        gridView(),
                      ])
                : SplitView(
                    controller: splitViewController,
                    gripSize: 8,
                    gripColor: global.theme.appBarColor,
                    gripColorActive: Colors.blue,
                    viewMode: SplitViewMode.Horizontal,
                    indicator: const SplitIndicator(viewMode: SplitViewMode.Horizontal),
                    activeIndicator: const SplitIndicator(
                      viewMode: SplitViewMode.Horizontal,
                      isActive: true,
                    ),
                    children: [
                        listScreen(),
                        gridView(),
                      ])),
      );
    });
  }
}
