import 'dart:async';
import 'package:camera/camera.dart';
import 'package:dedeorder/bloc/caller_bloc.dart';
import 'package:dedeorder/bloc/delivery_ticket_bloc.dart';
import 'package:dedeorder/bloc/order_temp_bloc.dart';
import 'package:dedeorder/bloc/process_bloc.dart';
import 'package:dedeorder/bloc/product_barcode_status_bloc.dart';
import 'package:dedeorder/bloc/sml_qr_bloc.dart';
import 'package:dedeorder/bloc/staff_bloc.dart';
import 'package:dedeorder/bloc/table_bloc.dart';
import 'package:dedeorder/model/global_model.dart';
import 'package:dedeorder/delivery/delivery_page.dart';
import 'package:dedeorder/home_page.dart';
import 'package:dedeorder/order/order_cancel_page.dart';
import 'package:dedeorder/order/order_page.dart';
import 'package:dedeorder/utility/staff_select_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dedeorder/global.dart' as global;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  try {
    await [
      Permission.camera,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();
  } catch (e, s) {
    if (kDebugMode) {
      print(e);
    }
    global.sendErrorToDevTeam("main:$e $s");
  }
  /*global.posSaleChannelLists.add(PosSaleChannelModel(
    code: 'SHOP',
    name: 'รับที่ร้าน',
    logoUrl:
        'https://cdn.freebiesupply.com/logos/large/2x/grab-logo-png-transparent.png',
  ));
  // Test Data
  global.posSaleChannelLists.add(PosSaleChannelModel(
    code: 'GRAB',
    name: 'Grab Delivery',
    logoUrl:
        'https://cdn.freebiesupply.com/logos/large/2x/grab-logo-png-transparent.png',
  ));
  global.posSaleChannelLists.add(PosSaleChannelModel(
    code: 'FOODPANDA',
    name: 'Food Panda',
    logoUrl:
        'https://www.foodpanda.co.th/assets/production/th/images/logos/foodpanda-logo.svg',
  ));
  global.posSaleChannelLists.add(PosSaleChannelModel(
    code: 'LINEMAN',
    name: 'Lineman',
    logoUrl:
        'https://www.linemanthailand.com/assets/images/logo/lineman-logo.png',
  ));
  global.posSaleChannelLists.add(PosSaleChannelModel(
    code: 'WONGNAI',
    name: 'Wongnai',
    logoUrl:
        'https://www.wongnai.com/static/asset/img/logo/logo-wongnai-white.svg',
  ));
  global.posSaleChannelLists.add(PosSaleChannelModel(
    code: 'GET',
    name: 'Get',
    logoUrl: 'https://www.get.co.th/assets/images/logo/get-logo-white-2x.png',
  ));
  global.posSaleChannelLists.add(PosSaleChannelModel(
    code: 'LINE',
    name: 'Line',
    logoUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/41/LINE_logo.svg/1200px-LINE_logo.svg.png',
  ));
  global.posSaleChannelLists.add(PosSaleChannelModel(
    code: 'SHOPEE',
    name: 'Shopee',
    logoUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/41/LINE_logo.svg/1200px-LINE_logo.svg.png',
  ));
  global.posSaleChannelLists.add(PosSaleChannelModel(
    code: 'LAZADA',
    name: 'Lazada',
    logoUrl:
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/41/LINE_logo.svg/1200px-LINE_logo.svg.png',
  ));*/
  //
  Timer.periodic(const Duration(seconds: 5), (Timer t) async {
    await global.checkConnectToPosTerminalAndLoadData();
    // check Caller
    await global.callerCheck();
  });
  try {
    global.cameras = await availableCameras();
  } catch (_) {
    global.cameras = [];
  }
  // ชื่อประเภทสินค้า
  global.productTypeLists.add(ProductTypeModel(name: [
    LanguageNameModel(code: 'th', name: "อาหาร"),
  ]));
  global.productTypeLists.add(ProductTypeModel(name: [
    LanguageNameModel(code: 'th', name: "เครื่องดื่ม"),
  ]));
  global.productTypeLists.add(ProductTypeModel(name: [
    LanguageNameModel(code: 'th', name: "เครื่องดื่มแอลกอฮอล์"),
  ]));
  global.productTypeLists.add(ProductTypeModel(name: [
    LanguageNameModel(code: 'th', name: "ของหวาน"),
  ]));
  global.flutterTts = FlutterTts();
  global.speak('สวัสดี ยินดีต้อนรับ ขอให้พนักงานทุกท่าน มีความสุขในการทำงาน');
  runApp(MultiBlocProvider(
      providers: [
        BlocProvider<TableBloc>(
          create: (BuildContext context) => TableBloc(),
        ),
        BlocProvider<OrderTempBloc>(
          create: (BuildContext context) => OrderTempBloc(),
        ),
        BlocProvider<ProcessBloc>(
          create: (BuildContext context) => ProcessBloc(),
        ),
        BlocProvider<ProductBarcodeStatusBloc>(
          create: (BuildContext context) => ProductBarcodeStatusBloc(),
        ),
        BlocProvider<DeliveryTicketBloc>(
          create: (BuildContext context) => DeliveryTicketBloc(),
        ),
        BlocProvider<CallerBloc>(
          create: (BuildContext context) => CallerBloc(),
        ),
        BlocProvider<StaffBloc>(
          create: (BuildContext context) => StaffBloc(),
        ),
        BlocProvider<SmlQrBloc>(
          create: (BuildContext context) => SmlQrBloc(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(primarySwatch: Colors.blue, fontFamily: "nato", useMaterial3: false),
        debugShowCheckedModeBanner: false,
        home: const HomePage(),
        routes: <String, WidgetBuilder>{
          '/home': (BuildContext context) => const HomePage(),
          '/staff': (BuildContext context) => const StaffSelectPage(),
          '/delivery': (BuildContext context) => const DeliveryPage(),
          '/order': (BuildContext context) => const OrderPage(),
          '/ordercancel': (BuildContext context) => const OrderCancelPage(),
        },
      )));
}
