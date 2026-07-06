import 'package:dedecashier/bloc/server_trans_bloc.dart';
import 'package:dedecashier/features/pos/presentation/bloc/sales_summary_bloc.dart';
import 'package:dedecashier/features/splash/presentation/splash_screen.dart';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/bloc/bloc.dart';
import 'package:dedecashier/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_secondary_screen.dart';
import 'package:dedecashier/features/shop/presentation/bloc/select_shop_bloc.dart';
import 'package:dedecashier/util/login_by_employee_page.dart';
import 'package:dedecashier/util/register_pos_terminal.dart';
import 'package:dedecashier/util/select_ip_server_page.dart';
import 'package:dedecashier/core/performance/app_performance_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // เรียกใช้ Print Queue Lifecycle handler ที่ตั้งไว้ใน bootstrap
    global.handlePrintQueueLifecycle?.call(state);

    // อื่นๆ เพิ่มเติมตามต้องการ
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed');
    } else if (state == AppLifecycleState.paused) {
      debugPrint('App paused');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthenticationBloc()),
        BlocProvider(create: (_) => SelectShopBloc()),
        BlocProvider(create: (context) => FindItemByCodeNameBarcodeBloc(apiFindItemByCodeNameBarcode: RestApiFindItemByCodeNameBarcode())),
        BlocProvider(create: (context) => FindMemberByTelNameBloc(apiFindMemberByTelName: ApiRepository())),
        BlocProvider(create: (context) => FindEmployeeByNameBloc(apiFindEmployeeByName: RestApiFindEmployeeByWord())),
        BlocProvider(create: (context) => BillBloc()),
        BlocProvider(create: (context) => PayScreenBloc()),
        BlocProvider(create: (context) => ServerBloc()),
        BlocProvider(create: (context) => ProductCategoryBloc(categoryGuid: '')),
        BlocProvider(create: (context) => ServerTransBloc()),
        BlocProvider(create: (context) => SalesSummaryBloc()),
      ],
      child: MaterialApp(
        title: 'BC POS',
        theme: ThemeData(primaryColor: (F.appFlavor != Flavor.MARINEPOS) ? const Color(0xFFB5651D) : const Color(0xFF005598), useMaterial3: false),
        themeMode: ThemeMode.system,
        // 🔔 เพิ่ม builder เพื่อแสดง notification overlay
        builder: (context, child) {
          return Stack(children: [child ?? const SizedBox.shrink(), const PrinterNotificationOverlay()]);
        },
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        supportedLocales: const [
          // English
          Locale('en', 'US'),
          // Thai
          Locale('th', 'TH'),
          // Lao
          Locale('lo', 'LA'),
          // Vietnam
          Locale('vi', 'VN'),
          // Myanmar
          Locale('my', 'MM'),
          // Cambodia
          Locale('km', 'KH'),
          // Japan
          Locale('ja', 'JP'),
          // China
          Locale('zh', 'CN'),
          // Korea
          Locale('ko', 'KR'),
          // Malaysia
          Locale('ms', 'MY'),
          // Indonesia
          Locale('id', 'ID'),
          // Singapore
          Locale('en', 'SG'),
          // Philippines
          Locale('en', 'PH'),
          // India
          Locale('en', 'IN'),
          // Hong Kong
          Locale('zh', 'HK'),
          // Taiwan
          Locale('zh', 'TW'),
        ],
        debugShowCheckedModeBanner: false,
        onGenerateRoute: generateRoute,
        initialRoute: '/',
      ),
    );
  }
}

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    case global.selectIpServerPageName:
      return MaterialPageRoute(builder: (_) => const SelectIpServerPage());
    case global.registerPosTerminalPageName:
      return MaterialPageRoute(builder: (_) => const RegisterPosTerminalPage());
    case global.loginByEmployeePageName:
      return MaterialPageRoute(builder: (_) => const LoginByEmployeePage());
    case global.internalCustomerDisplayPageName:
      return MaterialPageRoute(builder: (_) => const PosSecondaryScreen());
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(body: Center(child: Text('No route defined for ${settings.name}'))),
      );
  }
}
