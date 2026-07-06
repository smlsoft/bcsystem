import 'package:cocomerchant_lite/components/loadding_widget.dart';
import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/screens/unit/add_unit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cocomerchant_lite/bloc/unit/unit_bloc.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/model/product_model.dart';

class UnitSearchScreen extends StatefulWidget {
  const UnitSearchScreen({super.key, required this.word});
  final String word;

  @override
  State<UnitSearchScreen> createState() => UnitSearchScreenState();
}

class UnitSearchScreenState extends State<UnitSearchScreen> {
  TextEditingController searchController = TextEditingController();
  ScrollController listScrollController = ScrollController();
  String searchText = "";
  List<UnitModel> unitListData = [];
  bool isLoading = false;
  bool hasReachedMax = false;

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
    context.read<UnitBloc>().add(UnitLoadList(offset: unitListData.length, limit: 20, search: search));
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
          global.language('product_unit'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, global.SearchCodeNameModel(code: "", names: [], isCancel: true));
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, AddUnitScreen.routeName);
            },
          ),
        ],
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
                setState(() {
                  searchText = value;
                  unitListData.clear();
                  hasReachedMax = false;
                });
                loadDataList(value);
              },
            ),
          ),
          Expanded(
            child: BlocConsumer<UnitBloc, UnitState>(
              listener: (context, state) {
                if (state is UnitLoadSuccess) {
                  setState(() {
                    isLoading = false;
                    if (state.units.isEmpty) {
                      hasReachedMax = true;
                    } else {
                      unitListData.addAll(state.units);
                    }
                  });
                } else if (state is UnitInProgress) {
                  setState(() {
                    isLoading = true;
                  });
                } else {
                  setState(() {
                    isLoading = false;
                  });
                }
              },
              builder: (context, state) {
                return Stack(
                  children: [
                    ListView.builder(
                      controller: listScrollController,
                      itemCount: unitListData.length,
                      padding: const EdgeInsets.all(8.0),
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: kPrimaryColor,
                              child: Text(
                                unitListData[index].unitcode?.substring(0, 1).toUpperCase() ?? '',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              unitListData[index].unitcode!,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              global.packName(unitListData[index].names!),
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, color: kPrimaryColor),
                            onTap: () {
                              Navigator.pop(
                                context,
                                global.SearchCodeNameModel(
                                  code: unitListData[index].unitcode!,
                                  names: unitListData[index].names!,
                                  isCancel: false,
                                ),
                              );
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
