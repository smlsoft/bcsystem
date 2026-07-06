import 'package:cocomerchant_lite/components/loadding_widget.dart';
import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/model/company_branch_model.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/screens/product/add_product_barcode_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocomerchant_lite/bloc/product_barcode/product_barcode_bloc.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/model/product_model.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ListProductBarcodeScreen extends StatefulWidget {
  static String routeName = "/listproductbarcode";
  const ListProductBarcodeScreen({super.key});

  @override
  State<ListProductBarcodeScreen> createState() => ListProductBarcodeScreenState();
}

class ListProductBarcodeScreenState extends State<ListProductBarcodeScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final List<ProductBarcodeModel> listData = [];
  final List<String> guidListChecked = [];
  final Set<String> expandedItems = <String>{};
  String searchText = "";
  String selectGuid = "";
  bool showCheckBox = false;
  bool isLoading = false;
  bool hasReachedMax = false;
  FiltterBarcodeModel filterBarcode = FiltterBarcodeModel(branch: false);
  final _debouncer = global.Debouncer(500);

  @override
  void initState() {
    super.initState();
    loadDataList("", filterBarcode);
    listScrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    searchController.dispose();
    listScrollController.dispose();
    super.dispose();
  }

  void loadDataList(String search, FiltterBarcodeModel filterBarcode) {
    if (isLoading || hasReachedMax) return;
    setState(() {
      isLoading = true;
    });
    context.read<ProductBarcodeBloc>().add(ProductBarcodeLoadListSearch(
          offset: listData.length,
          limit: global.loadDataPerPage,
          search: search,
          branchcode: (filterBarcode.branch == true) ? global.companyBranchSelectData.code : "",
          businesstypecode: (filterBarcode.branch == true) ? global.companyBranchSelectData.businesstype!.code! : "",
        ));
  }

  void _onScroll() {
    if (_isBottom && !isLoading) {
      loadDataList(searchController.text, filterBarcode);
    }
  }

  bool get _isBottom {
    if (!listScrollController.hasClients) return false;
    final maxScroll = listScrollController.position.maxScrollExtent;
    final currentScroll = listScrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AddProductBarcodeScreen.routeName);
        },
        backgroundColor: kPrimaryColor,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: kPrimaryColor,
      title: Text(
        global.language('barcode'),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pushReplacementNamed(context, '/menu'),
      ),
      actions: _buildAppBarActions(),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: const FaIcon(FontAwesomeIcons.font, color: Colors.white),
        onPressed: () async {
          setState(() {
            global.listDataFontSizeChange();
          });
        },
      ),
      IconButton(
        icon: Icon(showCheckBox ? Icons.close : Icons.check_box, color: Colors.white),
        onPressed: _toggleCheckBoxes,
      ),
      if (guidListChecked.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.white),
          onPressed: _showDeleteConfirmation,
        ),
    ];
  }

  Widget _buildBody() {
    return BlocConsumer<ProductBarcodeBloc, ProductBarcodeState>(
      listener: (context, state) {
        if (state is ProductBarcodeLoadSearchSuccess) {
          setState(() {
            isLoading = false;
            if (state.productBarcodes.isEmpty) {
              hasReachedMax = true;
            } else {
              listData.addAll(state.productBarcodes);
            }
          });
        } else if (state is ProductBarcodeLoadSearchFailed) {
          setState(() {
            isLoading = false;
            hasReachedMax = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is ProductBarcodeDeleteManySuccess) {
          setState(() {
            guidListChecked.clear();
            showCheckBox = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(global.language('delete_success'))),
          );
          _refreshList();
        } else if (state is ProductBarcodeDeleteManyFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: listScrollController,
                    itemCount: listData.length,
                    itemBuilder: (context, index) {
                      return _buildListItem(listData[index]);
                    },
                  ),
                  LoadingWidget(isLoading: isLoading || state is ProductBarcodeSearchInProgress || state is ProductBarcodeDeleteManyInProgress),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: kPrimaryColor,
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: global.language('search'),
          prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) {
          _debouncer.run(() {
            setState(() {
              searchText = value;
              listData.clear();
              hasReachedMax = false;
            });
            loadDataList(value, filterBarcode);
          });
        },
      ),
    );
  }

  Widget _buildListItem(ProductBarcodeModel item) {
    bool isCheck = guidListChecked.contains(item.guidfixed);
    bool isSelected = selectGuid == item.guidfixed;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      child: InkWell(
        onTap: () => _handleCardTap(item, isCheck),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductImage(item.imageuri),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.barcode ?? '',
                          style: TextStyle(
                            fontSize: global.deviceConfig.listDataFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          global.activeLangName(item.names!),
                          style: TextStyle(
                            fontSize: global.deviceConfig.listDataFontSize - 2,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${global.language("unit")}: ${global.activeLangName(item.itemunitnames!)}',
                                style: TextStyle(
                                  fontSize: global.deviceConfig.listDataFontSize - 2,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Text(
                              '${global.language("price")}: ${global.formatNumber(item.prices![0].price)}',
                              style: TextStyle(
                                fontSize: global.deviceConfig.listDataFontSize - 2,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (showCheckBox)
              Positioned(
                top: 0,
                right: 0,
                child: Checkbox(
                  value: isCheck,
                  onChanged: (bool? newValue) => _handleCheckboxChange(item, newValue),
                  activeColor: kPrimaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String? imageUri) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        image: DecorationImage(
          image: imageUri != null && imageUri.isNotEmpty ? NetworkImage(imageUri) : const AssetImage('assets/img/noimage.png') as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _toggleCheckBoxes() {
    setState(() {
      showCheckBox = !showCheckBox;
      if (!showCheckBox) {
        guidListChecked.clear();
      }
    });
  }

  void _showDeleteConfirmation() {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(global.language('delete_data')),
        content: Text(global.language('are_you_sure_you_want_to_delete')),
        actions: <Widget>[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryLightColor,
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(global.language('no'), style: const TextStyle(color: kTextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
            ),
            onPressed: () {
              Navigator.pop(context);
              context.read<ProductBarcodeBloc>().add(ProductBarcodeDeleteMany(guid: guidListChecked));
            },
            child: Text(global.language('confirm'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleCardTap(ProductBarcodeModel item, bool isCheck) {
    if (showCheckBox) {
      setState(() {
        if (isCheck) {
          guidListChecked.remove(item.guidfixed);
        } else {
          guidListChecked.add(item.guidfixed);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddProductBarcodeScreen(productToEdit: item),
        ),
      ).then((result) {
        if (result != null) {
          _refreshList();
        }
      });
    }
  }

  void _handleCheckboxChange(ProductBarcodeModel item, bool? newValue) {
    setState(() {
      if (newValue == true) {
        guidListChecked.add(item.guidfixed);
      } else {
        guidListChecked.remove(item.guidfixed);
      }
    });
  }

  void _refreshList() {
    setState(() {
      listData.clear();
      hasReachedMax = false;
    });
    loadDataList(searchController.text, filterBarcode);
  }
}
