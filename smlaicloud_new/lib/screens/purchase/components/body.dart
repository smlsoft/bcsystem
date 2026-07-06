import 'package:flutter/material.dart';
import 'package:smlaicloud/components/background_main.dart';
import 'package:smlaicloud/components/textfield_search.dart';

class Body extends StatefulWidget {
  const Body({Key? key}) : super(key: key);

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final List<Map<String, dynamic>> _allCategory = [
    {"id": 1, "doc_date": "10/04/2565", "name": "สิธิพัช  สามวง", "sale_type": "ซื้อเงินเชื่อ", "qty": "3", "creaeter_code": "เบอรรี่  ดูดี", "sum_amount": "1800"},
    {"id": 2, "doc_date": "10/04/2565", "name": "วงเหลา  คำปลา", "sale_type": "ซื้อเงินสด", "qty": "5", "creaeter_code": "เบอรรี่  ดูดี", "sum_amount": "900"},
  ];

  List<Map<String, dynamic>> _category = [];
  @override
  initState() {
    _category = _allCategory;
    super.initState();
  }

  void _searchText(String enteredKeyword) {
    List<Map<String, dynamic>> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allCategory;
    } else {
      results = _allCategory.where((cate) => cate["name"].toLowerCase().contains(enteredKeyword.toLowerCase())).toList();
    }

    setState(() {
      _category = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return BackgroundMain(
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
                    Expanded(
                      child: _category.isNotEmpty
                          ? ListView.builder(
                              itemCount: _category.length,
                              itemBuilder: (context, index) => Card(
                                key: ValueKey(_category[index]["id"]),
                                elevation: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            _category[index]['doc_date'],
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            _category[index]['name'],
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Align(
                                            alignment: Alignment.topRight,
                                            child: Text(
                                              _category[index]['sale_type'],
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              'สินค้า: ${_category[index]["qty"]} รายการ',
                                              style: const TextStyle(
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              'ผู้จัดทำ: ${_category[index]["creaeter_code"]} ',
                                              style: const TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Align(
                                              alignment: Alignment.topRight,
                                              child: RichText(
                                                text: TextSpan(
                                                  style: const TextStyle(
                                                    fontSize: 18.0,
                                                    color: Colors.orange,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  children: <TextSpan>[
                                                    const TextSpan(text: 'รวม '),
                                                    TextSpan(
                                                      text: ' ${_category[index]["sum_amount"]}',
                                                      style: const TextStyle(
                                                        fontSize: 26.0,
                                                        color: Colors.orange,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const TextSpan(text: ' บาท'),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const Text(
                              'ไม่เจอข้อมูล',
                              style: TextStyle(fontSize: 24),
                            ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
