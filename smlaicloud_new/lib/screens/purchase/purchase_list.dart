import 'package:flutter/material.dart';
import 'package:smlaicloud/screens/purchase/components/body.dart';
import 'package:smlaicloud/screens/purchase/purchase_add.dart';
import 'package:smlaicloud/components/appbar.dart';

class PurchaseScreen extends StatelessWidget {
  const PurchaseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar(
        title: const Text('ซื้อสินค้า'),
        appBar: AppBar(),
        widgets: const <Widget>[],
      ),
      body: const Body(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return const PurchaseAdd();
              },
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}
