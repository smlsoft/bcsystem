import 'dart:convert';

import 'package:cocomerchant_lite/bloc/business_type/business_type_bloc.dart';
import 'package:cocomerchant_lite/bloc/creditor/creditor_bloc.dart';
import 'package:cocomerchant_lite/bloc/creditor_group/creditor_group_bloc.dart';
import 'package:cocomerchant_lite/bloc/pos_setting/pos_setting_bloc.dart';
import 'package:cocomerchant_lite/bloc/product_dimension/product_dimension_bloc.dart';
import 'package:cocomerchant_lite/bloc/report/product_status_bloc.dart';
import 'package:cocomerchant_lite/bloc/report/sale_daily_bloc.dart';
import 'package:cocomerchant_lite/bloc/report/sale_daily_list_bloc.dart';
import 'package:cocomerchant_lite/bloc/report/sale_summery_bloc.dart';
import 'package:cocomerchant_lite/bloc/shop/shop_bloc.dart';
import 'package:cocomerchant_lite/firebase_options.dart';
import 'package:cocomerchant_lite/imports_bloc.dart';
import 'package:cocomerchant_lite/imports_repositories.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/repositories/business_type_repository.dart';
import 'package:cocomerchant_lite/repositories/creditor_group_repository.dart';
import 'package:cocomerchant_lite/repositories/creditor_repository.dart';
import 'package:cocomerchant_lite/repositories/pos_setting_repository.dart';
import 'package:cocomerchant_lite/repositories/product_dimension_reporsitory.dart';
import 'package:cocomerchant_lite/repositories/shop_repository.dart';
import 'package:cocomerchant_lite/service_locator.dart';
import 'package:cocomerchant_lite/utils/google_sheet.dart';
import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/routes.dart';
import 'package:cocomerchant_lite/screens/splash/splash_screen.dart';
import 'package:cocomerchant_lite/theme.dart';
import 'package:cocomerchant_lite/environment.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'global.dart' as global;
import 'package:get_storage/get_storage.dart';

void initializeEnvironmentConfig() {
  const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: Environment.DEV,
  );
  Environment().initConfig(environment);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  initializeEnvironmentConfig();

  // Initialize Firebase

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  // Initialize GetStorage
  try {
    await GetStorage.init('AppConfig');
    print("GetStorage initialized successfully");
  } catch (e) {
    print('Error initializing GetStorage: $e');
  }

  // Set the theme
  global.themeSelect(0);

  // Load Google Multi Language Sheet
  ///ดึงภาษาจาก Google Sheet
  if (global.developerMode) {
    // Developer Mode
    await googleMultiLanguageSheetLoad().then((_) {
      global.userLanguage = "th";
      global.languageSelect(global.userLanguage);
      // Future.delayed(Duration(seconds: 1), () {
      //   createJsonFromGoogleSheet();
      // });
    });
  } else {
    try {
      global.languageSystemCode = (json.decode(await rootBundle.loadString('assets/language.json')) as List).map((i) => LanguageSystemCodeModel.fromJson(i)).toList();
    } catch (_) {}
    global.userLanguage = "th";
    global.languageSelect(global.userLanguage);
  }

  // Load timezone list
  global.getTimezones();

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(
          create: (_) {
            var loginBloc = LoginBloc(userRepository: UserRepository());
            serviceLocator.registerLazySingleton(() => loginBloc);
            return loginBloc;
          },
        ),
        BlocProvider<ListShopBloc>(
          create: (_) => ListShopBloc(userRepository: UserRepository()),
        ),
        BlocProvider<ShopSelectBloc>(
          create: (_) => ShopSelectBloc(userRepository: UserRepository()),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => ProfileBloc(profileRepository: ProfileRepository()),
        ),
        BlocProvider<ProductBarcodeBloc>(
          create: (_) => ProductBarcodeBloc(productBarcodeRepository: ProductBarcodeRepository()),
        ),
        BlocProvider<UnitBloc>(
          create: (_) => UnitBloc(unitRepository: UnitRepository()),
        ),
        BlocProvider<ImageUploadBloc>(
          create: (_) => ImageUploadBloc(imageUploadRepository: ImageUploadRepository()),
        ),
        BlocProvider<ProductCategoryBloc>(
          create: (_) => ProductCategoryBloc(productCategoryRepository: ProductCategoryRepository()),
        ),
        BlocProvider<QrBloc>(
          create: (_) => QrBloc(qrRepository: QrPaymentRepository(), jsonRepository: JsonRepository()),
        ),
        BlocProvider<OrderSettingBloc>(
          create: (_) => OrderSettingBloc(orderSettingRepository: OrderSettingRepository()),
        ),
        BlocProvider<OrderTemplateSettingBloc>(
          create: (_) => OrderTemplateSettingBloc(orderTemplateSettingRepository: OrderTemplateSettingRepository()),
        ),
        BlocProvider<PosMediaBloc>(
          create: (_) => PosMediaBloc(posMediaRepository: PosMediaRepository()),
        ),
        BlocProvider<ConfigSystemBloc>(
          create: (_) => ConfigSystemBloc(jsonRepository: JsonRepository()),
        ),
        BlocProvider<TableBloc>(
          create: (_) => TableBloc(tableRepository: TableRepository()),
        ),
        BlocProvider<CompanyBloc>(
          create: (_) => CompanyBloc(jsonRepository: JsonRepository()),
        ),
        BlocProvider<CompanyBranchBloc>(
          create: (_) => CompanyBranchBloc(companyBranchRepository: CompanyBranchRepository()),
        ),
        BlocProvider<TableBloc>(
          create: (_) => TableBloc(tableRepository: TableRepository()),
        ),
        BlocProvider<ZoneBloc>(
          create: (_) => ZoneBloc(zoneRepository: ZoneRepository()),
        ),
        BlocProvider<SaleChannelBloc>(
          create: (_) => SaleChannelBloc(saleChannelRepository: SaleChannelRepository()),
        ),
        BlocProvider<KitchenBloc>(
          create: (_) => KitchenBloc(kitchenRepository: KitchenRepository(), productBarcodeRepository: ProductBarcodeRepository()),
        ),
        BlocProvider<ShopBloc>(
          create: (_) => ShopBloc(shopRepository: ShopRepository()),
        ),
        BlocProvider<BusinessTypeBloc>(
          create: (_) => BusinessTypeBloc(businessTypeRepository: BusinessTypeRepository()),
        ),
        BlocProvider<CreditorBloc>(
          create: (_) => CreditorBloc(creditorRepository: CreditorRepository()),
        ),
        BlocProvider<ProductDimensionBloc>(
          create: (_) => ProductDimensionBloc(productDimensionRepository: ProductDimensionRepository()),
        ),
        BlocProvider<CreditorGroupBloc>(
          create: (_) => CreditorGroupBloc(creditorGroupRepository: CreditorGroupRepository()),
        ),
        BlocProvider<PosSettingBloc>(
          create: (_) => PosSettingBloc(posSettingRepository: PosSettingRepository()),
        ),
        BlocProvider<SaleDailyBloc>(
          create: (_) => SaleDailyBloc(),
        ),
        BlocProvider<SaleSummeryBloc>(
          create: (_) => SaleSummeryBloc(),
        ),
        BlocProvider<ProductStatusBloc>(
          create: (_) => ProductStatusBloc(),
        ),
        BlocProvider<SaleDailyListBloc>(
          create: (_) => SaleDailyListBloc(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('th', 'TH'),
          Locale('en', 'US'),
        ],
        title: 'COCO MERCHANT LITE',
        theme: AppTheme.lightTheme(context),
        initialRoute: SplashScreen.routeName,
        routes: routes,
      ),
    );
  }
}
