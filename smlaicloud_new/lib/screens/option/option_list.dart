import 'package:smlaicloud/screens/Option/option_add.dart';
import 'package:flutter/material.dart';
import 'package:smlaicloud/screens/Option/components/body.dart';
import 'package:smlaicloud/components/appbar.dart';

class OptionScreen extends StatelessWidget {
  const OptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar(
        title: const Text('ตัวเลือกเสริม'),
        appBar: AppBar(),
        leading: IconButton(
          color: Colors.black,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {},
        ),
        widgets: const <Widget>[],
      ),
      body: const Body(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OptionAdd()));
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
