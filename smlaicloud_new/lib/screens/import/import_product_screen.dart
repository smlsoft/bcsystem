import 'dart:async';
import 'dart:typed_data';

import 'package:smlaicloud/bloc/import_product/import_product_bloc.dart';
import 'package:smlaicloud/model/global_model.dart';
import 'package:smlaicloud/model/import_product_model.dart';
import 'package:smlaicloud/model/pagination.dart';
import 'package:smlaicloud/model/product_model.dart';
import 'package:smlaicloud/repositories/product_barcode_repository.dart';
import 'package:smlaicloud/screen_search/unit_search_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smlaicloud/global.dart' as global;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:smlaicloud/screens/report/file_download.dart';

class ImportProductScreen extends StatefulWidget {
  const ImportProductScreen({super.key});

  @override
  State<ImportProductScreen> createState() => _ImportProductScreenState();
}

class _ImportProductScreenState extends State<ImportProductScreen> {
  final ProductBarcodeRepository _productBarcodeRepository = ProductBarcodeRepository();
  String fileImportName = '';
  bool isLoading = false;
  bool isShowTable = false;
  bool isLoadingTable = false;
  bool isLoadingText = false;
  bool isLoadingSaveTaskid = false;
  int page = 1;
  int limit = 20;
  String q = '';
  String taskid = '';
  final List<int> _limitOptions = <int>[10, 20, 50, 100];

  List<ImportProductModel> detaillmportProductModel = [];
  Pagination pagination = Pagination(
    page: 1,
    perPage: 20,
    total: 10,
    totalPage: 1,
    next: 0,
    prev: 0,
  );

  LanguageModel languangeImport = global.config.languages[0];

  @override
  void initState() {
    super.initState();
  }

  void fetchData(int page, int limit, String q) {
    setState(() {
      isLoadingTable = true;
    });

    page = page;
    limit = limit;
    q = q;

    context.read<ImportProductBloc>().add(
          LoadImportProductByTaskid(
            taskid: taskid,
            q: q,
            limit: limit,
            page: page,
          ),
        );
  }

  String getTextError(ImportProductModel item) {
    List<String> errorMessages = [];

    if (item.isexist!) {
      errorMessages.add(global.language('product_exist'));
    }

    if (item.isduplicate!) {
      errorMessages.add(global.language('product_duplicate'));
    }

    if (item.isunitnotexist!) {
      errorMessages.add(global.language('product_unit_not_exist'));
    }

    // Join the error messages with a comma and space, and trim any trailing commas just in case
    return errorMessages.join(', ').trim();
  }

  Future<void> uploadFileExcel() async {
    double filesize = 0;

    /// select file excel from device
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result != null) {
      filesize = result.files.first.size / 1048576;

      /// set filesize 2 decimal
      filesize = double.parse(filesize.toStringAsFixed(2));

      if (filesize <= 2.0) {
        if (mounted) {
          setState(() {
            isLoading = true;
            fileImportName = result.files.first.name;
          });

          late Uint8List file = result.files.first.bytes!;

          context.read<ImportProductBloc>().add(UploadFileExcel(file: file, filename: fileImportName));
        }
      } else {
        setState(() {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(global.language('file_size_exceeds_2_mb')),
                content: RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      TextSpan(text: global.language('please_select_a_file_that_does_not_exceed_2_mb')),
                      const TextSpan(
                        text: ' ',
                      ),
                      TextSpan(
                        text: '${global.language('file_size')} : $filesize MB',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(global.language('close')),
                  ),
                ],
              );
            },
          );
        });
      }
    }
  }

  void _showBarcodeDialog(BuildContext context, ImportProductModel? item) async {
    TextEditingController barcode = TextEditingController();
    TextEditingController name = TextEditingController();
    TextEditingController unitcode = TextEditingController();
    TextEditingController price = TextEditingController();
    TextEditingController pricemember = TextEditingController();
    TextEditingController pricedelivery = TextEditingController();

    ProductBarcodeModel result = ProductBarcodeModel(guidfixed: '');

    barcode.text = "";
    name.text = "";
    unitcode.text = "";
    price.text = "";
    pricemember.text = "";
    pricedelivery.text = "";

    FocusNode barcodefocus = FocusNode();
    FocusNode namefocus = FocusNode();
    FocusNode unitcodefocus = FocusNode();
    FocusNode pricefocus = FocusNode();
    FocusNode pricememberfocus = FocusNode();
    FocusNode pricedeliveryfocus = FocusNode();

    if (item != null) {
      barcode.text = item.barcode!;
      name.text = item.name!;
      unitcode.text = item.unitcode!;
      price.text = item.price.toString();
      pricemember.text = item.pricemember.toString();
      pricedelivery.text = item.pricedelivery.toString();
    }

    return showDialog(
      context: context,
      barrierDismissible: true, // Allows tapping outside the dialog to close it
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(global.language("barcode")),
          content: SizedBox(
            width: (global.isMobileScreen(context)) ? 350 : 500,
            height: 200,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        autofocus: true,
                        controller: barcode,
                        focusNode: barcodefocus,
                        decoration: InputDecoration(
                          labelText: '',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              barcode.text = '';
                              name.text = '';
                              unitcode.text = '';
                              price.text = "";
                              pricemember.text = "";
                              pricedelivery.text = "";
                              Future.delayed(const Duration(milliseconds: 200), () {
                                FocusScope.of(context).requestFocus(barcodefocus);
                              });
                              setState(() {});
                            },
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            String barcodeValue = "";
                            barcodeValue = value.trim();
                            _productBarcodeRepository.getProductBarcodeDetail(barcodeValue).then((value) {
                              if (value.success && value.data != null) {
                                result = ProductBarcodeModel.fromJson(value.data);

                                if (result.itemtype == 3) {
                                  return;
                                }
                                name.text = global.activeLangName(result.names!);
                                unitcode.text = result.itemunitcode!;

                                Future.delayed(const Duration(milliseconds: 200), () {
                                  FocusScope.of(context).requestFocus(pricefocus);
                                });
                              }
                              setState(() {});
                            }).onError((error, stackTrace) {
                              barcode.text = '';
                              Future.delayed(const Duration(milliseconds: 200), () {
                                FocusScope.of(context).requestFocus(barcodefocus);
                              });
                              setState(() {});
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: name,
                        focusNode: namefocus,
                        decoration: InputDecoration(
                          labelText: global.language("product_name"),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: TextField(
                        controller: unitcode,
                        focusNode: unitcodefocus,
                        decoration: InputDecoration(
                          labelText: global.language("unit_code"),
                          border: const OutlineInputBorder(),
                          prefixIcon: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UnitSearchScreen(
                                    word: '',
                                  ),
                                ),
                              ).then((value) {
                                global.SearchCodeNameModel result = value;
                                if (result.code.isNotEmpty) {
                                  setState(() {
                                    unitcode.text = result.code;

                                    Future.delayed(const Duration(milliseconds: 200), () {
                                      FocusScope.of(context).requestFocus(pricefocus);
                                    });
                                  });
                                }
                              });
                            },
                            icon: const Icon(
                              Icons.search,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: price,
                        focusNode: pricefocus,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [global.NumberInputFormatter()],
                        decoration: InputDecoration(
                          labelText: global.language("price"),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            if (value == '0') {
                              price.selection = TextSelection.fromPosition(TextPosition(offset: price.text.length));
                            }
                          } else {
                            price.text = '0';
                          }
                        },
                        onEditingComplete: () {
                          Future.delayed(const Duration(milliseconds: 200), () {
                            FocusScope.of(context).requestFocus(pricememberfocus);
                          });
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: TextField(
                        controller: pricemember,
                        focusNode: pricememberfocus,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [global.NumberInputFormatter()],
                        decoration: InputDecoration(
                          labelText: global.language("product_price_member"),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            if (value == '0') {
                              pricemember.selection = TextSelection.fromPosition(TextPosition(offset: pricemember.text.length));
                            }
                          } else {
                            pricemember.text = '0';
                          }
                        },
                      ),
                    ),
                    // const SizedBox(
                    //   width: 10,
                    // ),
                    // Expanded(
                    //   child: TextField(
                    //     controller: pricedelivery,
                    //     focusNode: pricedeliveryfocus,
                    //     keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    //     inputFormatters: [global.NumberInputFormatter()],
                    //     decoration: InputDecoration(
                    //       labelText: global.language("product_price_delivery"),
                    //       border: const OutlineInputBorder(),
                    //     ),
                    //     onChanged: (value) {
                    //       if (value.isNotEmpty) {
                    //         if (value == '0') {
                    //           pricedelivery.selection = TextSelection.fromPosition(TextPosition(offset: pricedelivery.text.length));
                    //         }
                    //       } else {
                    //         pricedelivery.text = '0';
                    //       }
                    //     },
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(global.language("close")),
              onPressed: () {
                Navigator.pop(context);
              },
            ),

            /// button Save
            ElevatedButton(
              onPressed: () {
                if (barcode.text.isEmpty) {
                  Future.delayed(const Duration(milliseconds: 200), () {
                    FocusScope.of(context).requestFocus(barcodefocus);
                  });
                  return;
                } else {
                  ImportProductModel detail = ImportProductModel(
                    guidfixed: (item == null) ? '' : item.guidfixed!,
                    barcode: barcode.text,
                    name: name.text,
                    unitcode: unitcode.text,
                    price: double.parse(price.text.replaceAll(',', '')),
                    pricemember: double.parse(pricemember.text.replaceAll(',', '')),
                    pricedelivery: double.parse(pricedelivery.text.replaceAll(',', '')),
                    taskid: taskid,
                    rownumber: (item == null) ? 0 : item.rownumber!,
                  );
                  if (item == null) {
                    context.read<ImportProductBloc>().add(AddDetail(importProductModel: detail));
                  } else {
                    context.read<ImportProductBloc>().add(UpdateDetail(guid: item.guidfixed!, importProductModel: detail));
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(
                global.language("save"),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget editProductListDetailWidget(
    double screenHeight,
  ) {
    return (isShowTable)
        ? Column(
            children: [
              ///
              Padding(
                padding: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20),
                child: Row(
                  /// between
                  children: [
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          /// frist page
                          IconButton(
                            icon: const Icon(Icons.first_page),
                            onPressed: pagination.page > 1 ? () => fetchData(1, limit, q) : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: pagination.page > 1 ? () => fetchData(pagination.page - 1, limit, q) : null,
                          ),
                          Text('Page ${pagination.page} of ${pagination.totalPage}'),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: pagination.page < pagination.totalPage ? () => fetchData(pagination.page + 1, limit, q) : null,
                          ),

                          /// last page
                          IconButton(
                            icon: const Icon(Icons.last_page),
                            onPressed: pagination.page < pagination.totalPage ? () => fetchData(pagination.totalPage, limit, q) : null,
                          ),

                          /// size box width 10
                          const SizedBox(
                            width: 10,
                          ),
                          DropdownButton<int>(
                            value: limit,
                            items: _limitOptions.map<DropdownMenuItem<int>>((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString()),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              setState(() {
                                limit = newValue!;
                              });
                              fetchData(page, limit, q); // Go to the first page with the new rows per page
                            },
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Expanded(
                      child: SizedBox(
                        height: 49,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: global.language("select_language_import"),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<LanguageModel>(
                              value: languangeImport,
                              icon: const Icon(Icons.arrow_drop_down),
                              style: const TextStyle(color: Colors.deepPurple),
                              underline: Container(
                                color: Colors.deepPurpleAccent,
                              ),
                              onChanged: (LanguageModel? value) {
                                setState(() {
                                  languangeImport = value!;
                                });
                              },
                              isDense: true,
                              isExpanded: true,
                              items: global.config.languages.map<DropdownMenuItem<LanguageModel>>((LanguageModel value) {
                                return DropdownMenuItem<LanguageModel>(
                                  value: value,
                                  child: Row(
                                    children: <Widget>[
                                      Image.asset(
                                        'assets/flags/${value.code}.png', // Ensure the image path is correct
                                        width: 30,
                                        height: 30,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.error); // Error icon if the image fails to load
                                        },
                                      ),
                                      const SizedBox(width: 10), // Spacing between the image and text
                                      Text(value.name!),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Search',
                          suffixIcon: isLoadingText
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                )
                              : null, // Loading indicator
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() {
                            isLoadingText = true;
                            q = value;

                            fetchData(1, limit, value);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.7,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          columns: <DataColumn>[
                            DataColumn(label: Text(global.language('Barcode'))),
                            DataColumn(label: Text(global.language('item_name'))),
                            DataColumn(label: Text(global.language('unit_code'))),
                            DataColumn(label: Text(global.language('product_price'))),
                            DataColumn(label: Text(global.language('product_price_member'))),
                            // DataColumn(label: Text(global.language('product_price_delivery'))),
                            DataColumn(label: Text(global.language('status'))),
                            DataColumn(label: Text(global.language('edit'))),
                            DataColumn(label: Text(global.language('delete'))),
                            // Add more columns as needed
                          ],
                          rows: (!isLoadingTable)
                              ? detaillmportProductModel
                                  .map<DataRow>(
                                    (item) => DataRow(
                                      cells: <DataCell>[
                                        DataCell(
                                          Text(
                                            item.barcode!,
                                            style: (item.isexist! || item.isduplicate! || item.isunitnotexist!)
                                                ? const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  )
                                                : const TextStyle(
                                                    fontWeight: FontWeight.normal,
                                                  ),
                                          ),
                                        ),
                                        DataCell(Text(
                                          item.name!,
                                          style: (item.isexist! || item.isduplicate! || item.isunitnotexist!)
                                              ? const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                )
                                              : const TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                ),
                                        )),
                                        DataCell(Text(
                                          item.unitcode!,
                                          style: (item.isexist! || item.isduplicate! || item.isunitnotexist!)
                                              ? const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                )
                                              : const TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                ),
                                        )),
                                        DataCell(
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              item.price!.toString(),
                                              style: (item.isexist! || item.isduplicate! || item.isunitnotexist!)
                                                  ? const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.red,
                                                    )
                                                  : const TextStyle(
                                                      fontWeight: FontWeight.normal,
                                                    ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              item.pricemember!.toString(),
                                              style: (item.isexist! || item.isduplicate! || item.isunitnotexist!)
                                                  ? const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.red,
                                                    )
                                                  : const TextStyle(
                                                      fontWeight: FontWeight.normal,
                                                    ),
                                            ),
                                          ),
                                        ),
                                        // DataCell(
                                        //   Align(
                                        //     alignment: Alignment.centerRight,
                                        //     child: Text(
                                        //       item.pricedelivery!.toString(),
                                        //       style: (item.isexist! || item.isduplicate! || item.isunitnotexist!)
                                        //           ? const TextStyle(
                                        //               fontWeight: FontWeight.bold,
                                        //               color: Colors.red,
                                        //             )
                                        //           : const TextStyle(
                                        //               fontWeight: FontWeight.normal,
                                        //             ),
                                        //     ),
                                        //   ),
                                        // ),
                                        DataCell(
                                          Align(
                                            alignment: Alignment.center,
                                            child: (item.isduplicate! == false && item.isexist! == false && item.isunitnotexist == false)
                                                ? const Icon(Icons.check, color: Colors.green)
                                                : ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      foregroundColor: Colors.white, backgroundColor: Colors.red, // Text color
                                                    ),
                                                    onPressed: () {
                                                      showDialog(
                                                        context: context,
                                                        builder: (BuildContext context) {
                                                          return AlertDialog(
                                                            title: const Text('Error'),
                                                            content: Text(getTextError(item)),
                                                            actions: <Widget>[
                                                              TextButton(
                                                                onPressed: () => Navigator.of(context).pop(),
                                                                child: const Text('Close'),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    },
                                                    child: const Icon(Icons.error, color: Colors.white), // Icon color
                                                  ),
                                          ),
                                        ),
                                        DataCell(Align(
                                          alignment: Alignment.center,
                                          child: IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () {
                                              _showBarcodeDialog(context, item);
                                            },
                                          ),
                                        )),
                                        DataCell(
                                          Align(
                                            alignment: Alignment.center,
                                            child: IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () {
                                                /// show dialog confirm delete
                                                showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text(global.language('confirm_delete')),
                                                      content: Text(global.language('are_you_sure_you_want_to_delete_this_item')),
                                                      actions: <Widget>[
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(context).pop();
                                                          },
                                                          child: Text(global.language('close')),
                                                        ),
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                          onPressed: () {
                                                            if (item.guidfixed!.isNotEmpty) {
                                                              context.read<ImportProductBloc>().add(DeleteDetailByGuid(guid: item.guidfixed!));
                                                            }
                                                            Navigator.pop(context);
                                                          },
                                                          child: Text(
                                                            global.language('delete'),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList()
                              : [],
                        ),
                      ),
                      (isLoadingTable)
                          ? const Padding(
                              padding: EdgeInsets.only(top: 10.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 100, // Set the desired width
                                    height: 100, // Set the desired height
                                    child: CircularProgressIndicator(
                                      strokeWidth: 4, // Optional: Set the thickness of the indicator
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue), // Optional: Set the color
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                    ],
                  ),
                ),
              ),
            ],
          )
        : Container();
  }

  Widget menutListButtomBar() {
    return SizedBox(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            (fileImportName.isNotEmpty)
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _showBarcodeDialog(context, null);
                      },
                      child: Text(global.language('add_new_line_by_barcode')),
                    ),
                  )
                : Container(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: (fileImportName.isEmpty)
                  ? Container()
                  : ElevatedButton.icon(
                      /// button red
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                      ),

                      onPressed: () {
                        discardData(callBack: () {
                          context.read<ImportProductBloc>().add(DeleteTaskid(taskid: taskid));
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: Text(fileImportName),
                    ),
            ),
          ],
        ),
      ],
    ));
  }

  void discardData({required Function callBack}) {
    if (fileImportName.isNotEmpty) {
      showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                title: Text(global.language('data_uploaded')),
                content: Text('${global.language('how_do_you_want_to_discard_the_data')} : $fileImportName ?'),
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

  Future<void> downloadAssetFile(String assetPath, String saveFileName) async {
    // Load the asset file
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();

    // Use the download function
    bool success = await downloadAssetFileBytes(bytes, saveFileName);

    if (success) {
      if (kDebugMode) {
        print("File successfully downloaded.");
      }
    } else {
      if (kDebugMode) {
        print("Failed to download file.");
      }
    }
  }

  Future<void> saveTaskIdOperation() async {
    // Simulate a network call or lengthy operation
    await Future.delayed(const Duration(seconds: 2));
    // Here, include the logic you currently have in the onPressed method for saving
    if (taskid.isNotEmpty) {
      if (mounted) {
        context.read<ImportProductBloc>().add(SaveTaskid(taskid: taskid, languangecode: languangeImport.code!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height; // Get the screen height

    return Scaffold(
      appBar: AppBar(
        backgroundColor: global.theme.appBarColor,
        automaticallyImplyLeading: false,
        title: Text(global.language('import_product')),
        leading: IconButton(
          focusNode: FocusNode(skipTraversal: true),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            discardData(callBack: () {
              if (taskid.isNotEmpty) {
                context.read<ImportProductBloc>().add(DeleteTaskid(taskid: taskid));
              }
              Navigator.pushReplacementNamed(context, '/menu');
            });
          },
        ),
        actions: [
          ElevatedButton.icon(
            icon: isLoadingSaveTaskid
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2.0,
                  )
                : const Icon(
                    Icons.save,
                    size: 26.0,
                  ),
            label: Text(global.language('save')), // Adjust text based on your localization setup
            onPressed: fileImportName.isEmpty && !isLoadingSaveTaskid
                ? null
                : () async {
                    // Show confirmation dialog
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(global.language('confirm_import_product')),
                          content: Text('${global.language('confirm_import_product_file_name')} $fileImportName'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(global.language('close')),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(global.language('save')),
                            ),
                          ],
                        );
                      },
                    );

                    // If confirmed, start save operation
                    if (confirm == true) {
                      setState(() => isLoadingSaveTaskid = true);
                      try {
                        // Replace with your save operation
                        await saveTaskIdOperation();
                      } finally {
                        // Always stop the loading indicator, even if an error occurs
                        if (mounted) {
                          setState(() => isLoadingSaveTaskid = false);
                        }
                      }
                    }
                  },
          )
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ImportProductBloc, ImportProductState>(
            listener: (context, state) {
              if (state is UploadFileExcelSuccess) {
                taskid = state.response.id;
                context.read<ImportProductBloc>().add(VerifyTaskid(taskid: taskid));
              } else if (state is UploadFileExcelFailed) {
                setState(() {
                  fileImportName = '';
                  isLoading = false;

                  /// show dialog error
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('${global.language('error')} : ${global.language('file_format_error')}'),
                        content: Text(state.message),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(global.language('close')),
                          ),
                        ],
                      );
                    },
                  );
                });
              }

              if (state is VerifyTaskidSuccess) {
                /// delay 1 second
                Future.delayed(const Duration(seconds: 1), () {
                  fetchData(1, 20, "");
                });
              }

              if (state is LoadImportProductByTaskidSuccess) {
                setState(() {
                  detaillmportProductModel = [];
                  pagination = state.pagination;
                  detaillmportProductModel = state.data;

                  isLoading = false;
                  isLoadingText = false;
                  isLoadingTable = false;
                  isShowTable = true;
                });
              }
              if (state is LoadImportProductByTaskidFailed) {
                setState(() {
                  isLoading = false;
                  isLoadingText = false;
                  isLoadingTable = false;
                  isShowTable = false;

                  global.showSnackBar(
                      context,
                      const Icon(
                        Icons.error,
                        color: Colors.white,
                      ),
                      state.message,
                      Colors.red);
                });
              }

              if (state is DeleteDetailByGuidSuccess) {
                fetchData(page, limit, q);
              }

              if (state is UpdateDetailSuccess) {
                context.read<ImportProductBloc>().add(VerifyTaskid(taskid: taskid));
                global.showSnackBar(
                  context,
                  const Icon(
                    Icons.save,
                    color: Colors.white,
                  ),
                  global.language("update_success"),
                  Colors.blue,
                );
              }

              if (state is AddDetailSuccess) {
                context.read<ImportProductBloc>().add(VerifyTaskid(taskid: taskid));
                global.showSnackBar(
                  context,
                  const Icon(
                    Icons.save,
                    color: Colors.white,
                  ),
                  global.language("save_success"),
                  Colors.blue,
                );
              }

              if (state is DeleteTaskidSuccess) {
                setState(() {
                  pagination = Pagination(
                    page: 1,
                    perPage: 20,
                    total: 10,
                    totalPage: 1,
                    next: 0,
                    prev: 0,
                  );
                  detaillmportProductModel = <ImportProductModel>[];
                  isLoading = false;
                  isLoadingText = false;
                  isLoadingTable = false;
                  isShowTable = false;
                  fileImportName = '';
                });
              }

              if (state is SaveTaskidSuccess) {
                setState(() {
                  pagination = Pagination(
                    page: 1,
                    perPage: 20,
                    total: 10,
                    totalPage: 1,
                    next: 0,
                    prev: 0,
                  );
                  detaillmportProductModel = <ImportProductModel>[];
                  isLoading = false;
                  isLoadingText = false;
                  isLoadingTable = false;
                  isShowTable = false;
                  fileImportName = '';
                });
                global.showSnackBar(
                  context,
                  const Icon(
                    Icons.save,
                    color: Colors.white,
                  ),
                  global.language("save_success"),
                  Colors.blue,
                );
              }

              if (state is SaveTaskidFailed) {
                context.read<ImportProductBloc>().add(VerifyTaskid(taskid: taskid));
                global.showSnackBar(
                  context,
                  const Icon(
                    Icons.save,
                    color: Colors.white,
                  ),
                  '${global.language("save_failed")} : ${state.message}',
                  Colors.red,
                );
              }
            },
          ),
        ],
        child: SafeArea(
          child: (isLoading)
              ? const Center(
                  child: SizedBox(
                    width: 100, // Set the desired width
                    height: 100, // Set the desired height
                    child: CircularProgressIndicator(
                      strokeWidth: 4, // Optional: Set the thickness of the indicator
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue), // Optional: Set the color
                    ),
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  child: (fileImportName.isEmpty)
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              iconSize: 150,
                              color: Colors.grey,
                              tooltip: global.language('import_product'),
                              icon: const Icon(Icons.upload_file),
                              onPressed: () {
                                uploadFileExcel();
                              },
                            ),
                            Text(
                              global.language('import_product_from_excel_file_size_2mb'),
                              style: const TextStyle(fontSize: 20, color: Colors.grey),
                            ),

                            /// download file excel ex sample stock balance
                            TextButton(
                              onPressed: () {
                                try {
                                  downloadAssetFile('assets/file_import/import_product_final.xlsx', 'import_product.xlsx');
                                } catch (e) {
                                  print('An error occurred: //');
                                  // Handle the error or show a message to the user

                                  /// show dialog error
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(global.language('error')),
                                        content: Text(e.toString()),
                                        actions: [
                                          TextButton(
                                            child: Text(global.language('confirm')),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              },
                              child: Text(
                                global.language('download_file_excel_ex_sample_product'),
                                style: const TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: editProductListDetailWidget(screenHeight),
                            ),
                            menutListButtomBar(),
                          ],
                        ),
                ),
        ),
      ),
    );
  }
}
