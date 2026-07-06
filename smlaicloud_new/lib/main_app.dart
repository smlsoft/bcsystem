import 'package:smlaicloud/bloc/api_key/apikey_bloc.dart';
import 'package:smlaicloud/bloc/bi_report/bi_report_bloc.dart';
import 'package:smlaicloud/bloc/coupon_bloc.dart';
import 'package:smlaicloud/bloc/export_csv/export_csv_bloc.dart';
import 'package:smlaicloud/bloc/import_product/import_product_bloc.dart';
import 'package:smlaicloud/bloc/master_brand/master_brand_bloc.dart';
import 'package:smlaicloud/bloc/master_category/master_category_bloc.dart';
import 'package:smlaicloud/bloc/master_class/master_class_bloc.dart';
import 'package:smlaicloud/bloc/master_design/master_design_bloc.dart';
import 'package:smlaicloud/bloc/master_grade/master_grade_bloc.dart';
import 'package:smlaicloud/bloc/master_group/master_group_bloc.dart';
import 'package:smlaicloud/bloc/master_group_sub1/master_group_sub1_bloc.dart';
import 'package:smlaicloud/bloc/master_group_sub2/master_group_sub2_bloc.dart';
import 'package:smlaicloud/bloc/master_model/master_model_bloc.dart';
import 'package:smlaicloud/bloc/master_pattern/master_pattern_bloc.dart';
import 'package:smlaicloud/bloc/product_dimension/product_dimension_bloc.dart';
import 'package:smlaicloud/bloc/productmaster/productmaster_bloc.dart';
import 'package:smlaicloud/bloc/report/report_bloc.dart';
import 'package:smlaicloud/bloc/shop/shop_bloc.dart';
import 'package:smlaicloud/bloc/stock_balance/stock_balance_bloc.dart';
import 'package:smlaicloud/repositories/apikey_repository.dart';
import 'package:smlaicloud/repositories/bi_report_repository.dart';
import 'package:smlaicloud/repositories/coupon_repository.dart';
import 'package:smlaicloud/repositories/export_csv_repository.dart';
import 'package:smlaicloud/repositories/file_status_repository.dart';
import 'package:smlaicloud/repositories/master_brand_repository.dart';
import 'package:smlaicloud/repositories/master_category_repository.dart';
import 'package:smlaicloud/repositories/master_class_repository.dart';
import 'package:smlaicloud/repositories/master_design_repository.dart';
import 'package:smlaicloud/repositories/master_grade_repository.dart';
import 'package:smlaicloud/repositories/master_group_repository.dart';
import 'package:smlaicloud/repositories/master_group_sub1_repository.dart';
import 'package:smlaicloud/repositories/master_group_sub2_repository.dart';
import 'package:smlaicloud/repositories/master_model_repository.dart';
import 'package:smlaicloud/repositories/master_pattern_repository.dart';
import 'package:smlaicloud/repositories/product_dimension_reporsitory.dart';
import 'package:smlaicloud/repositories/product_import_repository.dart';
import 'package:smlaicloud/repositories/product_master_repository.dart';
import 'package:smlaicloud/repositories/report_repository.dart';
import 'package:smlaicloud/repositories/shop_repository.dart';
import 'package:smlaicloud/repositories/stock_balance_import_repository.dart';
import 'package:smlaicloud/screens/config/point_setting_screen.dart';
import 'package:smlaicloud/screens/config/price_history/price_history_screen.dart';
import 'package:smlaicloud/screens/coupon/coupon_screen.dart';
import 'package:smlaicloud/screens/enhanced_cash_drawer_screen.dart';
import 'package:smlaicloud/screens/check_daily/daily_info_screen.dart';
import 'package:smlaicloud/screens/config/bank_screen.dart';
import 'package:smlaicloud/screens/config/bill_design_screen.dart';
import 'package:smlaicloud/screens/config/company_branch_screen.dart';
import 'package:smlaicloud/screens/config/company_screen.dart';
import 'package:smlaicloud/screens/config/config_screen.dart';
import 'package:smlaicloud/screens/config/creditor_group_screen.dart';
import 'package:smlaicloud/screens/config/creditor_screen.dart';
import 'package:smlaicloud/screens/config/debtor_group_screen.dart';
import 'package:smlaicloud/screens/config/debtor_screen.dart';
import 'package:smlaicloud/screens/config/department_screen.dart';
import 'package:smlaicloud/screens/config/doc_format_screen.dart';
import 'package:smlaicloud/screens/config/employee_screen.dart';
import 'package:smlaicloud/screens/config/group_number_select_screen.dart';
import 'package:smlaicloud/screens/config/line_notify_screen.dart';
import 'package:smlaicloud/screens/config/order_setting_screen.dart';
import 'package:smlaicloud/screens/config/order_setting_teamplate_screen.dart';
import 'package:smlaicloud/screens/config/pos_media_screen.dart';
import 'package:smlaicloud/screens/config/pos_setting_screen.dart';
import 'package:smlaicloud/screens/config/product_barcode_bom_screen.dart';
import 'package:smlaicloud/screens/config/product_barcode_screen.dart';
import 'package:smlaicloud/screens/config/product_barcode_shelf.dart';
import 'package:smlaicloud/screens/config/product_category_list_screen.dart';
import 'package:smlaicloud/screens/config/product_dimension_screen.dart';
import 'package:smlaicloud/screens/config/product_group_screen.dart';
import 'package:smlaicloud/screens/config/product_screen.dart';
import 'package:smlaicloud/screens/config/product_unit_screen.dart';
import 'package:smlaicloud/screens/config/promotion_screen.dart';
import 'package:smlaicloud/screens/config/qr_screen.dart';
import 'package:smlaicloud/screens/config/reminder_screen.dart';
import 'package:smlaicloud/screens/config/user_screen.dart';
import 'package:smlaicloud/screens/gl/gl_process_screen.dart';
import 'package:smlaicloud/screens/import/import_product_image_screen.dart';
import 'package:smlaicloud/screens/import/import_product_screen.dart';
import 'package:smlaicloud/screens/master/master_brand_screen.dart';
import 'package:smlaicloud/screens/master/master_category_screen.dart';
import 'package:smlaicloud/screens/master/master_class_screen.dart';
import 'package:smlaicloud/screens/master/master_design_screen.dart';
import 'package:smlaicloud/screens/master/master_grade_screen.dart';
import 'package:smlaicloud/screens/master/master_group_screen.dart';
import 'package:smlaicloud/screens/master/master_group_sub1_screen.dart';
import 'package:smlaicloud/screens/master/master_group_sub2_screen.dart';
import 'package:smlaicloud/screens/master/master_model_screen.dart';
import 'package:smlaicloud/screens/master/master_pattern_screen.dart';
import 'package:smlaicloud/screens/report/dedebi/report_dedebi_payment_daily.dart';
import 'package:smlaicloud/screens/report/dedebi/report_dedebi_sale_daily.dart';
import 'package:smlaicloud/screens/report/dedebi/report_dedebi_sale_return.dart';
import 'package:smlaicloud/screens/report/dedebi/report_dedebi_sales.dart';
import 'package:smlaicloud/screens/report/dedebi/report_dedebi_stock_balance.dart';
import 'package:smlaicloud/screens/report/dedebi/report_dedebi_stock_movement_screen.dart';
import 'package:smlaicloud/screens/report/pdf_report_main_screen.dart';
import 'package:smlaicloud/screens/report/report_product_balance.dart';
import 'package:smlaicloud/screens/report/reportmovement_screen.dart';
import 'package:smlaicloud/screens/transaction/transaction_edit.dart';
import 'package:smlaicloud/screens/transaction/transaction_stock_balance.dart';
import 'package:smlaicloud/service_locator.dart';
import 'package:smlaicloud/usersystem/flavor_login_selector.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smlaicloud/menu_screen.dart';
import 'package:smlaicloud/select_language_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smlaicloud/usersystem/login_shop_screen.dart';
import 'global.dart' as global;

import 'package:smlaicloud/imports_repositories.dart';
import 'package:smlaicloud/imports_bloc.dart';

import 'flavors.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProductCategoryBloc>(
          create: (_) => ProductCategoryBloc(productCategoryRepository: ProductCategoryRepository()),
        ),
        BlocProvider<ProductGroupBloc>(
          create: (_) => ProductGroupBloc(productGroupRepository: ProductGroupRepository()),
        ),
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
        BlocProvider<InventoryBloc>(
          create: (_) => InventoryBloc(inventoryRepository: InventoryRepository()),
        ),
        BlocProvider<MemberBloc>(
          create: (_) => MemberBloc(memberRepository: MemberRepository()),
        ),
        BlocProvider<CustomerBloc>(
          create: (_) => CustomerBloc(customerRepository: CustomerRepository()),
        ),
        BlocProvider<CompanyBloc>(
          create: (_) => CompanyBloc(jsonRepository: JsonRepository()),
        ),
        BlocProvider<HolidayBloc>(
          create: (_) => HolidayBloc(jsonRepository: JsonRepository()),
        ),
        BlocProvider<KitchenPrinterBloc>(
          create: (_) => KitchenPrinterBloc(jsonRepository: JsonRepository()),
        ),
        BlocProvider<DevicePrintBloc>(
          create: (_) => DevicePrintBloc(jsonRepository: JsonRepository()),
        ),
        BlocProvider<CustomerGroupBloc>(
          create: (_) => CustomerGroupBloc(customerGroupRepository: CustomerGroupRepository()),
        ),
        BlocProvider<OptionBloc>(
          create: (_) => OptionBloc(optionRepository: OptionRepository()),
        ),
        BlocProvider<ImageUploadBloc>(
          create: (_) => ImageUploadBloc(imageUploadRepository: ImageUploadRepository()),
        ),
        BlocProvider<UnitBloc>(
          create: (_) => UnitBloc(unitRepository: UnitRepository()),
        ),
        BlocProvider<ColorBloc>(
          create: (_) => ColorBloc(colorRepository: ColorRepository()),
        ),
        BlocProvider<PrinterBloc>(
          create: (_) => PrinterBloc(printerRepository: PrinterRepository()),
        ),
        BlocProvider<ProductBarcodeBloc>(
          create: (_) => ProductBarcodeBloc(productBarcodeRepository: ProductBarcodeRepository()),
        ),
        BlocProvider<ProductBloc>(
            create: (_) => ProductBloc(
                  productRepository: ProductRepository(),
                  productSectionRepository: ProductSectionRepository(),
                  productBarcodeRepository: ProductBarcodeRepository(),
                )),
        BlocProvider<KitchenBloc>(
          create: (_) => KitchenBloc(kitchenRepository: KitchenRepository(), productBarcodeRepository: ProductBarcodeRepository()),
        ),
        BlocProvider<StaffBloc>(
          create: (_) => StaffBloc(staffRepository: StaffRepository()),
        ),
        BlocProvider<EmployeeBloc>(
          create: (_) => EmployeeBloc(employeeRepository: EmployeeRepository()),
        ),
        BlocProvider<DevicesBloc>(
          create: (_) => DevicesBloc(devicesRepository: DevicesRepository()),
        ),
        BlocProvider<BankBloc>(
          create: (_) => BankBloc(bankRepository: BankRepository(), jsonRepository: JsonRepository()),
        ),
        BlocProvider<WorkDayBloc>(
          create: (_) => WorkDayBloc(jsonRepository: JsonRepository()),
        ),
        BlocProvider<WalletPayBloc>(
          create: (_) => WalletPayBloc(jsonRepository: JsonRepository()),
        ),
        BlocProvider<TableBloc>(
          create: (_) => TableBloc(tableRepository: TableRepository()),
        ),
        BlocProvider<BookBankBloc>(
          create: (_) => BookBankBloc(bookBankRepository: BookBankRepository(), jsonRepository: JsonRepository()),
        ),
        BlocProvider<WarehouseBloc>(
          create: (_) => WarehouseBloc(warehouseRepository: WarehouseRepository()),
        ),
        BlocProvider<WarehouseLocationBloc>(
          create: (_) => WarehouseLocationBloc(warehouseLocationRepository: WarehouseLocationRepository()),
        ),
        BlocProvider<TransBloc>(
          create: (_) => TransBloc(transRepository: TransRepository()),
        ),
        BlocProvider<BusinessTypeBloc>(
          create: (_) => BusinessTypeBloc(businessTypeRepository: BusinessTypeRepository()),
        ),
        BlocProvider<DepartmentBloc>(
          create: (_) => DepartmentBloc(departmentRepository: DepartmentRepository()),
        ),
        BlocProvider<CompanyBranchBloc>(
          create: (_) => CompanyBranchBloc(companyBranchRepository: CompanyBranchRepository()),
        ),
        BlocProvider<SaleChannelBloc>(
          create: (_) => SaleChannelBloc(saleChannelRepository: SaleChannelRepository()),
        ),
        BlocProvider<TransportChannelBloc>(
          create: (_) => TransportChannelBloc(transportChannelRepository: TransportChannelRepository()),
        ),
        BlocProvider<ConfigSystemBloc>(
          create: (_) => ConfigSystemBloc(jsonRepository: JsonRepository()),
        ),
        BlocProvider<CreditorBloc>(
          create: (_) => CreditorBloc(creditorRepository: CreditorRepository()),
        ),
        BlocProvider<DebtorBloc>(
          create: (_) => DebtorBloc(debtorRepository: DebtorRepository()),
        ),
        BlocProvider<CreditorGroupBloc>(
          create: (_) => CreditorGroupBloc(creditorGroupRepository: CreditorGroupRepository()),
        ),
        BlocProvider<DebtorGroupBloc>(
          create: (_) => DebtorGroupBloc(debtorGroupRepository: DebtorGroupRepository()),
        ),
        BlocProvider<TransactionPaidPayBloc>(
          create: (_) => TransactionPaidPayBloc(transactionPaidPayRepository: TransactionPaidPayRepository()),
        ),
        BlocProvider<PromotionBloc>(
          create: (_) => PromotionBloc(promotionRepository: PromotionRepository()),
        ),
        BlocProvider<OrderTypeBloc>(
          create: (_) => OrderTypeBloc(orderTypeRepository: OrderTypeRepository()),
        ),
        BlocProvider<UserBloc>(
          create: (_) => UserBloc(userRepository: UserRepository()),
        ),
        BlocProvider<ZoneBloc>(
          create: (_) => ZoneBloc(zoneRepository: ZoneRepository()),
        ),
        BlocProvider<PosSettingBloc>(
          create: (_) => PosSettingBloc(posSettingRepository: PosSettingRepository()),
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
        BlocProvider<ChartAccountBloc>(
          create: (_) => ChartAccountBloc(chartAccountRepository: ChartAccountRepository()),
        ),
        BlocProvider<DocFormatBloc>(
          create: (_) => DocFormatBloc(documentFormateRepository: DocumentFormateRepository()),
        ),
        BlocProvider<ProductTypeBloc>(
          create: (_) => ProductTypeBloc(productTypeRepository: ProductTypeRepository()),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => ProfileBloc(profileRepository: ProfileRepository()),
        ),
        BlocProvider<CashInDrawerBloc>(
          create: (_) => CashInDrawerBloc(cashInDrawerRepository: CashInDrawerRepository()),
        ),
        BlocProvider<QrBloc>(
          create: (_) => QrBloc(qrRepository: QrPaymentRepository(), jsonRepository: JsonRepository()),
        ),
        BlocProvider<GlProcessBloc>(
          create: (_) => GlProcessBloc(glProcessRepository: GlProcessRepository()),
        ),
        BlocProvider(create: (context) => PayScreenBloc()),
        BlocProvider<LineNotifyBloc>(
          create: (_) => LineNotifyBloc(lineNotifyRepository: LineNotifyRepository()),
        ),
        BlocProvider<ShopBloc>(
          create: (_) => ShopBloc(shopRepository: ShopRepository()),
        ),
        BlocProvider<StockBalanceBloc>(
          create: (_) => StockBalanceBloc(stockBalanceRepository: StockBalanceImportRepository()),
        ),
        BlocProvider<ImportProductBloc>(
          create: (_) => ImportProductBloc(importProductRepository: ImportProductRepository()),
        ),
        BlocProvider<ProductDimensionBloc>(
          create: (_) => ProductDimensionBloc(productDimensionRepository: ProductDimensionRepository()),
        ),
        BlocProvider<ExportCsvBloc>(
          create: (_) => ExportCsvBloc(exportCsvRepository: ExportCsvRepository()),
        ),
        BlocProvider<ReportBloc>(
          create: (_) => ReportBloc(reportRepository: ReportRepository(), fileStatusRepository: FileStatusRepository()),
        ),
        BlocProvider<ApiKeyBloc>(
          create: (_) => ApiKeyBloc(apiKeyRepository: ApiKeyRepository()),
        ),
        BlocProvider<ProductMasterBloc>(
          create: (_) => ProductMasterBloc(productMasterRepository: ProductMasterRepository()),
        ),
        BlocProvider<MasterBrandBloc>(
          create: (_) => MasterBrandBloc(masterBrandRepository: MasterBrandRepository()),
        ),
        BlocProvider<MasterCategoryBloc>(
          create: (_) => MasterCategoryBloc(masterCategoryRepository: MasterCategoryRepository()),
        ),
        BlocProvider<MasterClassBloc>(
          create: (_) => MasterClassBloc(masterClassRepository: MasterClassRepository()),
        ),
        BlocProvider<MasterDesignBloc>(
          create: (_) => MasterDesignBloc(masterDesignRepository: MasterDesignRepository()),
        ),
        BlocProvider<MasterGradeBloc>(
          create: (_) => MasterGradeBloc(masterGradeRepository: MasterGradeRepository()),
        ),
        BlocProvider<MasterModelBloc>(
          create: (_) => MasterModelBloc(masterModelRepository: MasterModelRepository()),
        ),
        BlocProvider<MasterPatternBloc>(
          create: (_) => MasterPatternBloc(masterPatternRepository: MasterPatternRepository()),
        ),
        BlocProvider<MasterGroupBloc>(
          create: (_) => MasterGroupBloc(masterGroupRepository: MasterGroupRepository()),
        ),
        BlocProvider<MasterGroupSub1Bloc>(
          create: (_) => MasterGroupSub1Bloc(masterGroupSub1Repository: MasterGroupSub1Repository()),
        ),
        BlocProvider<MasterGroupSub2Bloc>(
          create: (_) => MasterGroupSub2Bloc(masterGroupSub2Repository: MasterGroupSub2Repository()),
        ),
        BlocProvider<CouponBloc>(
          create: (_) => CouponBloc(couponRepository: CouponRepository()),
        ),
        BlocProvider<BiReportBloc>(
          create: (_) => BiReportBloc(biReportRepository: BiReportRepository()),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('th', 'TH'),
          Locale('en', 'US'),
        ],
        debugShowCheckedModeBanner: false,
        title: F.title,
        theme: ThemeData(
          useMaterial3: false,
          primarySwatch: Colors.blue,
          appBarTheme: const AppBarTheme(
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
        home: const FlavorLoginSelector(),
        routes: <String, WidgetBuilder>{
          '/login_screen': (BuildContext context) => const FlavorLoginSelector(),
          '/login_screen_shop': (BuildContext context) => const LoginShopScreen(),
          '/menu': (BuildContext context) => const MenuScreen(),
          '/company': (BuildContext context) => const CompanyScreen(),
          '/product': (BuildContext context) => const ProductScreen(),
          '/product_barcode': (BuildContext context) => const ProductBarcodeScreen(),
          '/productunit': (BuildContext context) => const ProductUnitScreen(),
          '/productgroup': (BuildContext context) => const ProductGroupScreen(),
          '/productcategorylist': (BuildContext context) => const ProductCategoryListScreen(),
          '/branch': (BuildContext context) => const CompanyBranchScreen(),
          '/department': (BuildContext context) => const DepartmentScreen(),
          '/employee': (BuildContext context) => const EmployeeScreen(),
          '/user': (BuildContext context) => const UserScreen(),
          '/creditor': (BuildContext context) => const CreditorScreen(),
          '/creditorgroup': (BuildContext context) => const CreditorGroupScreen(),
          '/debtor': (BuildContext context) => const DebtorScreen(),
          '/debtorgroup': (BuildContext context) => const DebtorGroupScreen(),
          '/bank': (BuildContext context) => const BankScreen(),
          '/possetting': (BuildContext context) => const PosSettingScreen(),
          '/ordersetting': (BuildContext context) => const OrderSettingScreen(),
          '/ordertemplatsetting': (BuildContext context) => const OrderTemplateSettingScreen(),
          '/posmedia': (BuildContext context) => const PosMediaScreen(),
          '/docformat': (BuildContext context) => const DocFormatScreen(),
          '/billdesign': (BuildContext context) => const BillDesignScreen(),
          '/qrprovider': (BuildContext context) => const QrScreen(),
          '/config_system': (BuildContext context) => const ConfigScreen(),
          '/product_dimension': (BuildContext context) => const ProductDimensionScreen(),
          '/product_bom': (BuildContext context) => const ProductBarcodeBomScreen(),
          '/promotion_screen': (BuildContext context) => const PromotionScreen(),
          '/product_barcode_shelf': (BuildContext context) => const ProductBarcodeShelf(),
          '/price_history': (BuildContext context) => const PriceHistoryScreen(),
          // '/report/product': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.product,
          //     ),
          // '/report/debtor': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.debtor,
          //     ),
          // '/report/creditor': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.creditor,
          //     ),
          // '/report/bookbank': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.bookbank,
          //     ),
          // '/report/purchase': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.purchase,
          //     ),
          // '/report/purchasereturn': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.purchasereturn,
          //     ),
          // '/report/saleinvoice': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.saleinvoice,
          //     ),
          // '/report/saleinvoicereturn': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.saleinvoicereturn,
          //     ),
          // '/report/transfer': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.transfer,
          //     ),
          // '/report/receive': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.receive,
          //     ),
          // '/report/pickup': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.pickup,
          //     ),
          // '/report/returnproduct': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.returnproduct,
          //     ),
          // '/report/stockadjustment': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.stockadjustment,
          //     ),
          // '/report/paid': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.paid,
          //     ),
          // '/report/pay': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.pay,
          //     ),
          // '/report/getpaid': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.getpaid,
          //     ),
          // '/report/getpay': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.getpay,
          //     ),
          // '/report/vatsale': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.vatsale,
          //     ),
          // '/report/vatpurchase': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.vatpurchase,
          //     ),
          // '/report/salebydebtor': (BuildContext context) => const ReportScreen(
          //       type: global.ReportEnum.salebydebtor,
          //     ),

          //// report new
          // '/report/salebydate': (BuildContext context) => const ReportMainScreen(
          //       type: global.ReportEnum.salebydate,
          //     ),
          // '/report/receivemoney': (BuildContext context) => const ReportMainScreen(
          //       type: global.ReportEnum.receivemoney,
          //     ),
          // '/report/saleinvoicenew': (BuildContext context) => const ReportMainScreen(
          //       type: global.ReportEnum.saleinvoice,
          //     ),

          '/report/movement': (BuildContext context) => const ReportMovementScreen(),
          '/report/pdfreport': (BuildContext context) => const PdfReportMainScreen(),

          /// bi report service
          '/report/report_dedebi_sales': (BuildContext context) => const ReportDedebiSalesScreen(),
          '/report/report_dedebi_sales_daily': (BuildContext context) => const ReportDedebiSaleDailyScreen(),
          '/report/report_stock_movement': (BuildContext context) => const ReportStockMovementScreen(),
          '/report/report_dedebi_payment_daily': (BuildContext context) => const ReportPaymentDailyScreen(),
          '/report/report_dedebi_sale_return': (BuildContext context) => const ReportDedebiSaleReturnScreen(),
          '/report/report_dedebi_stock_balance': (BuildContext context) => const ReportStockBalanceScreen(),

          '/report/product_balance': (BuildContext context) => const ReportProductBalanceScreen(),
          '/importproduct': (BuildContext context) => const ImportProductScreen(),
          '/importproductimage': (BuildContext context) => const ImportProductImageScreen(),
          '/transaction/stockbalance': (BuildContext context) => const TransactionStockBalaceScreen(
                type: global.TransactionTypeEnum.stockbalance,
              ),
          '/transaction/purchase': (BuildContext context) => const TransactionEditScreen(
                type: global.TransactionTypeEnum.purchase,
              ),
          '/transaction/purchasereturn': (BuildContext context) => const TransactionEditScreen(
                type: global.TransactionTypeEnum.purchasereturn,
              ),
          '/selectlanguage': (BuildContext context) => const SelectLanguageScreen(),
          '/gl/gl_process': (BuildContext context) => const GlProcessScreen(),
          '/check_daily/daily_info_screen': (BuildContext context) => const DailyInfoScreen(),
          '/product_category_group_select_screen': (BuildContext context) => const GroupNumberSelectScreen(
                type: global.SelectGroupNumberEnum.category,
              ),
          '/zone_group_select_screen': (BuildContext context) => const GroupNumberSelectScreen(
                type: global.SelectGroupNumberEnum.zone,
              ),
          '/table_group_select_screen': (BuildContext context) => const GroupNumberSelectScreen(
                type: global.SelectGroupNumberEnum.table,
              ),
          '/table_map_group_select_screen': (BuildContext context) => const GroupNumberSelectScreen(
                type: global.SelectGroupNumberEnum.tableOrder,
              ),
          '/kitchen_group_select_screen': (BuildContext context) => const GroupNumberSelectScreen(
                type: global.SelectGroupNumberEnum.kitchen,
              ),
          '/qrcodeorder_group_select_screen': (BuildContext context) => const GroupNumberSelectScreen(
                type: global.SelectGroupNumberEnum.genQrcode,
              ),
          '/line_notify': (BuildContext context) => const LineNotifyScreen(),
          '/reminder': (BuildContext context) => const ReminderScreen(),
          '/cashing_in_the_drawer': (BuildContext context) => const EnhancedCashInDrawerScreen(),
          '/point_setting': (BuildContext context) => const PointSettingScreen(),
          '/coupon_setting': (BuildContext context) => const CouponScreen(),

          /// ข้อมูลหลัก
          '/master_brand_screen': (BuildContext context) => const MasterBrandScreen(),
          '/master_category_screen': (BuildContext context) => const MasterCategoryScreen(),
          '/master_class_screen': (BuildContext context) => const MasterClassScreen(),
          '/master_design_screen': (BuildContext context) => const MasterDesignScreen(),
          '/master_grade_screen': (BuildContext context) => const MasterGradeScreen(),
          '/master_model_screen': (BuildContext context) => const MasterModelScreen(),
          '/master_pattern_screen': (BuildContext context) => const MasterPatternScreen(),
          '/master_group_screen': (BuildContext context) => const MasterGroupScreen(),
          '/master_group_sub1_screen': (BuildContext context) => const MasterGroupSub1Screen(),
          '/master_group_sub2_screen': (BuildContext context) => const MasterGroupSub2Screen(),
        },
      ),
    );
  }
}
