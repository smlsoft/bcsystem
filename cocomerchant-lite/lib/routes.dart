import 'package:cocomerchant_lite/create_shop/create_shop_screen.dart';
import 'package:cocomerchant_lite/enums.dart';
import 'package:cocomerchant_lite/screens/category/category_screen.dart';
import 'package:cocomerchant_lite/screens/config/add_product_to_kitchen_screen.dart';
import 'package:cocomerchant_lite/screens/config/company_screen.dart';
import 'package:cocomerchant_lite/screens/config/config_screen.dart';
import 'package:cocomerchant_lite/screens/config/order_setting_teamplate_screen.dart';
import 'package:cocomerchant_lite/screens/config/pos_media_screen.dart';
import 'package:cocomerchant_lite/screens/config/product_category_list_screen.dart';
import 'package:cocomerchant_lite/screens/config/qr_screen.dart';
import 'package:cocomerchant_lite/screens/config/sale_channel.dart';
import 'package:cocomerchant_lite/screens/group_number_select/group_number_select_screen.dart';
import 'package:cocomerchant_lite/screens/menu/full_menu_screen.dart';
import 'package:cocomerchant_lite/screens/menu/menu_screen.dart';
import 'package:cocomerchant_lite/screens/order_setting/order_setting_screen.dart';
import 'package:cocomerchant_lite/screens/product/add_product_barcode_screen.dart';
import 'package:cocomerchant_lite/screens/product/list_product_barcode_screen.dart';
import 'package:cocomerchant_lite/screens/product/product_barcode_screen.dart';
import 'package:cocomerchant_lite/screens/report/report_dashboard_screen.dart';
import 'package:cocomerchant_lite/screens/report/report_order_screen.dart';
import 'package:cocomerchant_lite/screens/report/report_product_screen.dart';
import 'package:cocomerchant_lite/screens/report/report_receivemoney_screen.dart';
import 'package:cocomerchant_lite/screens/report/report_screen.dart';
import 'package:cocomerchant_lite/screens/unit/add_unit_screen.dart';
import 'package:cocomerchant_lite/screens/unit/unit_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:cocomerchant_lite/screens/cart/cart_screen.dart';
import 'package:cocomerchant_lite/screens/complete_profile/complete_profile_screen.dart';
import 'package:cocomerchant_lite/screens/details/details_screen.dart';
import 'package:cocomerchant_lite/screens/home/home_screen.dart';
import 'package:cocomerchant_lite/screens/login_success/login_success_screen.dart';
import 'package:cocomerchant_lite/screens/otp/otp_screen.dart';
import 'package:cocomerchant_lite/screens/profile/profile_screen.dart';
import 'package:cocomerchant_lite/screens/sign_in/sign_in_screen.dart';
import 'package:cocomerchant_lite/screens/splash/splash_screen.dart';

// We use name route
// All our routes will be available here
final Map<String, WidgetBuilder> routes = {
  CompleteProfileScreen.routeName: (context) => CompleteProfileScreen(),
  DetailsScreen.routeName: (context) => DetailsScreen(),
  CartScreen.routeName: (context) => CartScreen(),

  /// MERCHANT LITE
  SplashScreen.routeName: (context) => const SplashScreen(),
  SignInScreen.routeName: (context) => const SignInScreen(),
  LoginSuccessScreen.routeName: (context) => const LoginSuccessScreen(),
  CreateShopScreen.routeName: (context) => const CreateShopScreen(),
  ProfileScreen.routeName: (context) => const ProfileScreen(),
  ReportScreen.routeName: (context) => const ReportScreen(),
  HomeScreen.routeName: (context) => const HomeScreen(),
  MenuScreen.routeName: (context) => const MenuScreen(),
  ReportProductScreen.routeName: (context) => const ReportProductScreen(),
  ReportOrderScreen.routeName: (context) => const ReportOrderScreen(),
  ReportDashBoardScreen.routeName: (context) => const ReportDashBoardScreen(),
  ReportReceivemoneyScreen.routeName: (context) => const ReportReceivemoneyScreen(),
  FullMenuScreen.routeName: (context) => const FullMenuScreen(),
  CategoryScreen.routeName: (context) => const GroupNumberSelectScreen(
        type: SelectGroupNumberEnum.category,
      ),
  UnitScreen.routeName: (context) => const UnitScreen(),
  ListProductBarcodeScreen.routeName: (context) => const ListProductBarcodeScreen(),
  OrderSettingScreen.routeName: (context) => const OrderSettingScreen(),
  OtpScreen.routeName: (context) => OtpScreen(),
  AddUnitScreen.routeName: (context) => const AddUnitScreen(),
  AddProductBarcodeScreen.routeName: (context) => const AddProductBarcodeScreen(),

  '/product_category_group_select_screen': (BuildContext context) => const GroupNumberSelectScreen(
        type: SelectGroupNumberEnum.category,
      ),
  '/table_group_select_screen': (BuildContext context) => const GroupNumberSelectScreen(
        type: SelectGroupNumberEnum.table,
      ),
  '/qrcodeorder_group_select_screen': (BuildContext context) => const GroupNumberSelectScreen(
        type: SelectGroupNumberEnum.genQrcode,
      ),
  '/kitchen_group_select_screen': (BuildContext context) => const GroupNumberSelectScreen(
        type: SelectGroupNumberEnum.kitchen,
      ),

  '/productcategorylist': (BuildContext context) => const ProductCategoryListScreen(),
  '/qrprovider': (BuildContext context) => const QrScreen(),
  '/ordertemplatsetting': (BuildContext context) => const OrderTemplateSettingScreen(),
  '/posmedia': (BuildContext context) => const PosMediaScreen(),
  '/config_system': (BuildContext context) => const ConfigScreen(),
  '/company': (BuildContext context) => const CompanyScreen(),
  '/salechannel': (BuildContext context) => const SaleChannelScreen(),
  '/addproducttokitchen': (BuildContext context) => const AddProductToKitchenScreen(),
};
