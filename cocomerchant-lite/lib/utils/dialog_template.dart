import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/global.dart' as global;

class DialogTemplate {
  static Future<List<dynamic>> showDataListTemplateDialog(BuildContext context, dynamic jsonData, String menu) async {
    List<dynamic> selectedItemTemp = List.filled(jsonData.length, false);
    bool selectItemTempAll = false;
    String headerMenu = "";

    switch (menu) {
      case 'bank':
        headerMenu = global.language('select_bank_template');
        break;
      case 'transportchannel':
        headerMenu = global.language('select_transportchannel_template');
        break;
      case 'salechannel':
        headerMenu = global.language('select_salechannel_template');
        break;
      case 'unit':
        headerMenu = global.language('select_unit_template');
        break;
      case 'qrcode':
        headerMenu = global.language('select_qrcode_template');
        break;
    }

    return await showModalBottomSheet<List<dynamic>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.9,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 6,
                        width: 50,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      AppBar(
                        title: Text(headerMenu, style: const TextStyle(color: Colors.black)),
                        centerTitle: true,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Switch(
                              value: selectItemTempAll,
                              onChanged: (value) {
                                setState(() {
                                  selectItemTempAll = value;
                                  selectedItemTemp = List.filled(jsonData.length, value);
                                });
                              },
                            ),
                            Text(global.language('select_all'), style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text('${selectedItemTemp.where((item) => item).length}/${jsonData.length} ${global.language('selected')}'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: jsonData.length,
                          itemBuilder: (context, index) {
                            var item = jsonData[index];
                            var packName = '';
                            var logo = '';

                            switch (menu) {
                              case 'bank':
                                packName = global.packName(item.names);
                                logo = item.logo;
                                break;
                              case 'transportchannel':
                              case 'salechannel':
                                packName = item.name;
                                logo = item.imageuri;
                                break;
                              case 'unit':
                                packName = global.packName(item.names);
                                break;
                              case 'qrcode':
                                packName = global.packName(item.qrnames);
                                logo = item.logo;
                                break;
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: CheckboxListTile(
                                title: Text(packName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                secondary: logo.isNotEmpty
                                    ? SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: Image.network(logo, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error)),
                                      )
                                    : null,
                                value: selectedItemTemp[index],
                                onChanged: (value) {
                                  setState(() {
                                    selectedItemTemp[index] = value!;
                                    selectItemTempAll = selectedItemTemp.every((element) => element);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => Navigator.of(context).pop([]),
                                child: Text(global.language('cancel')),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => Navigator.of(context).pop(selectedItemTemp),
                                child: Text(global.language('confirm')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ) ??
        [];
  }
}
