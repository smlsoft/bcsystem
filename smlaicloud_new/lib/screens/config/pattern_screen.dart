import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smlaicloud/global.dart' as global;
import 'package:smlaicloud/model/public_name_model.dart';

class PatternDetailModel {
  String code = "";
  List<PublicNameModel> names = [];
  List<TextEditingController> editController = [];
  List<FocusNode> focus = [];
}

class PatternScreen extends StatefulWidget {
  const PatternScreen({Key? key}) : super(key: key);

  @override
  State<PatternScreen> createState() => PatternScreenState();
}

class PatternScreenState extends State<PatternScreen> with SingleTickerProviderStateMixin {
  late TabController tabController;
  ScrollController editScrollController = ScrollController();
  TextEditingController codeController = TextEditingController();
  List<TextEditingController> nameController = [];
  List<String> fieldName = [];
  List<FocusNode> nameFocusNode = [];
  List<PatternDetailModel> details = [];

  void setSystemLanguageList() async {
    await global.setSystemLanguage(context);

    for (int i = 0; i < global.config.languages.length; i++) {
      nameController.add(TextEditingController());
      nameFocusNode.add(FocusNode());
      fieldName.add("name${i + 1}");
    }
  }

  @override
  void initState() {
    setSystemLanguageList();
    tabController = TabController(vsync: this, length: 2);

    super.initState();
  }

  @override
  void dispose() {
    tabController.dispose();
    editScrollController.dispose();
    codeController.dispose();
    for (int i = 0; i < nameController.length; i++) {
      nameController[i].dispose();
      nameFocusNode[i].dispose();
    }
    super.dispose();
  }

  Widget listScreen() {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: global.theme.appBarColor,
          title: Text(global.language("product_type")),
          actions: <Widget>[
            Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {});
                  },
                  child: const Icon(
                    Icons.delete,
                    size: 26.0,
                  ),
                )),
            Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: () {
                    tabController.index = 1;
                    nameFocusNode[0].requestFocus();
                  },
                  child: const Icon(
                    Icons.add,
                    size: 26.0,
                  ),
                )),
          ],
        ),
        body: Container());
  }

  void saveData() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 1),
        content: (Row(
          children: const [
            Icon(
              Icons.save,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Text("บันทึกสำเร็จ")
          ],
        ))));
  }

  void addDetail() {
    setState(() {
      PatternDetailModel detail = PatternDetailModel();
      for (int i = 0; i < global.config.languages.length; i++) {
        detail.editController.add(TextEditingController());
        detail.names.add(PublicNameModel());
        detail.focus.add(FocusNode());
      }
      details.add(detail);
      detail.focus[0].requestFocus();
    });
  }

  Widget editScreen({showBackButton = true}) {
    return Scaffold(
        appBar: AppBar(
            leading: showBackButton
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      tabController.index = 0;
                    },
                  )
                : null,
            backgroundColor: global.theme.appBarColor,
            title: Text(global.language("product_type")),
            actions: <Widget>[
              Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: GestureDetector(
                    onTap: () {
                      addDetail();
                    },
                    child: const Icon(
                      Icons.add,
                      size: 26.0,
                    ),
                  )),
              Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: GestureDetector(
                    onTap: () {
                      saveData();
                    },
                    child: const Icon(
                      Icons.save,
                      size: 26.0,
                    ),
                  ))
            ]),
        body: Column(children: [
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              child: Column(children: [
                for (int i = 0; i < global.config.languages.length; i++)
                  if (global.config.languages[i].isuse!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        focusNode: nameFocusNode[i],
                        textAlign: TextAlign.left,
                        controller: nameController[i],
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: global.language("namepdtype") + " (${global.config.languages[i].name})",
                        ),
                      ),
                    ),
                Wrap(
                  spacing: 4.0,
                  runSpacing: 4.0,
                  children: [
                    for (var i = 0; i < details.length; i++)
                      ElevatedButton(
                        onPressed: () {
                          details[i].focus[0].requestFocus();
                        },
                        child: Text(details[i].names[0].name),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ])),
          Expanded(
              child: SingleChildScrollView(
                  controller: editScrollController,
                  child: Column(children: [
                    for (var i = 0; i < details.length; i++)
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(children: [
                            for (int j = 0; j < global.config.languages.length; j++)
                              if (global.config.languages[j].isuse!)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: TextField(
                                    focusNode: details[i].focus[j],
                                    onChanged: (value) {
                                      setState(() {
                                        details[i].names[j].name = value;
                                      });
                                    },
                                    textAlign: TextAlign.left,
                                    controller: details[i].editController[j],
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      labelText: "ชื่อรูปแบบย่อย (${global.config.languages[j].name})",
                                    ),
                                  ),
                                ),
                          ])),
                    const SizedBox(height: 10),
                    SizedBox(
                        width: double.infinity,
                        child: Row(children: [
                          ElevatedButton.icon(
                              onPressed: () {
                                addDetail();
                              },
                              icon: const Icon(Icons.add),
                              label: const Text("เพิ่มรายการย่อย")),
                          ElevatedButton.icon(
                              onPressed: () {
                                saveData();
                              },
                              icon: const Icon(Icons.save),
                              label: const Text("บันทึก"))
                        ]))
                  ])))
        ]));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
          body: (constraints.maxWidth > 800)
              ? Row(
                  children: [
                    Expanded(child: listScreen()),
                    Container(width: 1.5, color: Colors.black),
                    Expanded(child: editScreen(showBackButton: false)),
                  ],
                )
              : TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: tabController,
                  children: [listScreen(), editScreen()],
                ));
    });
  }
}
