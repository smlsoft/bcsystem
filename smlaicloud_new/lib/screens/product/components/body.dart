// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smlaicloud/screens/product/product_add.dart';
import 'package:smlaicloud/bloc/inventory/inventory_bloc.dart';
import 'package:smlaicloud/components/background_main.dart';
import 'package:smlaicloud/components/textfield_search.dart';
import 'package:smlaicloud/model/inventory_model.dart';
import 'package:smlaicloud/utils/util.dart';

class Body extends StatefulWidget {
  const Body({Key? key}) : super(key: key);

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final ScrollController _scrollController = ScrollController();
  double currentScroll = 0.0;

  int perPage = 8;
  String search = "";

  @override
  initState() {
    context.read<InventoryBloc>().add(ListInventoryLoad(page: 0, perPage: perPage, search: search, nextPage: true));
    _scrollController.addListener(_onScroll);
    super.initState();
  }

  void _searchText(String enteredKeyword) {
    List<Map<String, dynamic>> results = [];
  }

  void _onScroll() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
      InventoryBloc inventoryBloc = context.read<InventoryBloc>();
      InventoryLoadSuccess inventoryLoadSuccess;

      setState(() {
        currentScroll = _scrollController.position.maxScrollExtent;
      });

      if (inventoryBloc.state is InventoryLoadSuccess) {
        inventoryLoadSuccess = (inventoryBloc.state as InventoryLoadSuccess);
        if (inventoryLoadSuccess.page!.page < inventoryLoadSuccess.page!.totalPage) {
          inventoryBloc.add(ListInventoryLoad(page: inventoryLoadSuccess.page!.page + 1, perPage: perPage, search: search, nextPage: false));
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return MultiBlocListener(
      listeners: [
        BlocListener<InventoryBloc, InventoryState>(
          listener: (context, state) {
            if (state is InventoryLoadSuccess) {
              if (currentScroll > 0) {
                Future.delayed(
                  const Duration(milliseconds: 100),
                  () {
                    setState(() {
                      _scrollController.jumpTo(currentScroll);
                    });
                  },
                );
              }
            }
          },
        ),
      ],
      child: BackgroundMain(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Card(
                child: TextFieldSearch(
                  onChange: (value) {
                    _searchText(value);
                  },
                ),
              ),
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Expanded(child: BlocBuilder<InventoryBloc, InventoryState>(
                        builder: (context, state) {
                          return (state is InventoryLoadSuccess)
                              ? GridView.builder(
                                  controller: _scrollController,
                                  shrinkWrap: true,
                                  physics: BouncingScrollPhysics(),
                                  itemCount: state.inventory.length,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    childAspectRatio: 1,
                                    crossAxisCount: (Util.isLandscape(context)) ? 5 : 2,
                                    crossAxisSpacing: 4.0,
                                    mainAxisSpacing: 4.0,
                                    mainAxisExtent: 208,
                                  ),
                                  itemBuilder: (context, index) {
                                    return Card(
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ProductAdd(
                                                  guidfixed: state.inventory[index].guidfixed,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Column(
                                            children: <Widget>[
                                              SizedBox(
                                                height: 100,
                                                child: Image.asset("assets/img/vficon.png", fit: BoxFit.fill),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  children: [
                                                    Align(
                                                      alignment: Alignment.topLeft,
                                                      child: Text(
                                                        state.inventory[index].name1,
                                                        // text 1 line
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          color: Colors.black,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    Align(
                                                      alignment: Alignment.topLeft,
                                                      child: Text(
                                                        state.inventory[index].barcode,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                    Align(
                                                      alignment: Alignment.topRight,
                                                      child: Text(
                                                        state.inventory[index].price.toString(),
                                                        style: TextStyle(
                                                          color: Colors.orange,
                                                          fontSize: 24,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : (state is InventoryLoadFailed)
                                  ? Text(
                                      'ไม่เจอข้อมูล',
                                      style: TextStyle(fontSize: 24),
                                    )
                                  : Container();
                        },
                      )),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
