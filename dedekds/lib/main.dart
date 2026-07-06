import 'dart:io';
import 'package:dedekds/bloc/kitchen_bloc.dart';
import 'package:dedekds/bloc/order_temp_bloc.dart';
import 'package:dedekds/kds_home_page.dart';
import 'package:dedekds/kds_start_page.dart';
import 'package:dedekds/scan_server_page.dart';
import 'package:dedekds/select_kitchen_page.dart';
import 'package:dedekds/utility/printer_config_select_printer.dart';
import 'package:flutter/material.dart';
import 'package:dedekds/global.dart' as global;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  global.initTts();

  runApp(MultiBlocProvider(
      providers: [
        BlocProvider(create: (BuildContext context) => KitchenBloc()),
        BlocProvider(create: (BuildContext context) => OrderTempBloc()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DEDE Kitchen Display',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: false,
        ),
        home: const KdsStartPage(),
        routes: <String, WidgetBuilder>{
          '/start': (BuildContext context) => const KdsStartPage(),
          '/home': (BuildContext context) => const KdsHomePage(),
          '/scan_server': (BuildContext context) => const ScanServerPage(),
          '/scan_printer': (BuildContext context) =>
              const PrinterConfigSelectPrinterScreen(),
          '/select_kitchen': (BuildContext context) =>
              const SelectKitchenPage(),
        },
      )));
}
