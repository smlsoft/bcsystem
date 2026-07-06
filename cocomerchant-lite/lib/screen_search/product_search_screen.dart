import 'package:cocomerchant_lite/components/loadding_widget.dart';
import 'package:cocomerchant_lite/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocomerchant_lite/bloc/product_barcode/product_barcode_bloc.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/model/product_model.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({Key? key, required this.word}) : super(key: key);
  final String word;

  @override
  State<ProductSearchScreen> createState() => ProductSearchScreenState();
}

class ProductSearchScreenState extends State<ProductSearchScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final List<ProductBarcodeModel> productListData = [];
  String searchText = "";
  bool isLoading = false;
  bool hasReachedMax = false;
  final _debouncer = global.Debouncer(500);

  @override
  void initState() {
    super.initState();
    searchController.text = widget.word;
    loadDataList(searchController.text);
    listScrollController.addListener(_onScroll);
  }

  void loadDataList(String search) {
    if (isLoading || hasReachedMax) return;
    setState(() {
      isLoading = true;
    });
    context.read<ProductBarcodeBloc>().add(ProductBarcodeLoadListSearch(
          offset: productListData.length,
          limit: global.loadDataPerPage,
          search: search,
          branchcode: "",
          businesstypecode: "",
        ));
  }

  void _onScroll() {
    if (_isBottom && !isLoading) {
      loadDataList(searchController.text);
    }
  }

  bool get _isBottom {
    if (!listScrollController.hasClients) return false;
    final maxScroll = listScrollController.position.maxScrollExtent;
    final currentScroll = listScrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  void dispose() {
    listScrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: Text(
          global.language('product'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, ProductBarcodeModel(guidfixed: "", itemcode: ""));
          },
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: kPrimaryColor,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
                hintText: global.language('search'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                _debouncer.run(() {
                  setState(() {
                    searchText = value;
                    productListData.clear();
                    hasReachedMax = false;
                  });
                  loadDataList(value);
                });
              },
            ),
          ),
          Expanded(
            child: BlocConsumer<ProductBarcodeBloc, ProductBarcodeState>(
              listener: (context, state) {
                if (state is ProductBarcodeLoadSearchSuccess) {
                  setState(() {
                    isLoading = false;
                    if (state.productBarcodes.isEmpty) {
                      hasReachedMax = true;
                    } else {
                      productListData.addAll(state.productBarcodes);
                    }
                  });
                } else if (state is ProductBarcodeSearchInProgress) {
                  setState(() {
                    isLoading = true;
                  });
                } else if (state is ProductBarcodeLoadSearchFailed) {
                  setState(() {
                    isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, state) {
                return Stack(
                  children: [
                    ListView.builder(
                      controller: listScrollController,
                      itemCount: productListData.length,
                      padding: const EdgeInsets.all(8.0),
                      itemBuilder: (context, index) {
                        final product = productListData[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                image: DecorationImage(
                                  image: product.imageuri != null && product.imageuri!.isNotEmpty
                                      ? NetworkImage(product.imageuri!)
                                      : const AssetImage('assets/img/noimage.png') as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: Text(
                              product.barcode ?? '',
                              style: TextStyle(
                                fontSize: global.deviceConfig.listDataFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  global.activeLangName(product.names ?? []),
                                  style: TextStyle(
                                    fontSize: global.deviceConfig.listDataFontSize - 2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${global.language("unit")}: ${global.activeLangName(product.itemunitnames ?? [])}',
                                  style: TextStyle(
                                    fontSize: global.deviceConfig.listDataFontSize - 2,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, color: kPrimaryColor),
                            onTap: () {
                              Navigator.pop(context, product);
                            },
                          ),
                        );
                      },
                    ),
                    LoadingWidget(isLoading: isLoading),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
