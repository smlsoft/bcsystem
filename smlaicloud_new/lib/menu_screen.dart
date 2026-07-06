import 'dart:convert';
import 'package:smlaicloud/components/create_sub_shop_dialog.dart';
import 'package:smlaicloud/model/shop_model.dart';
import 'package:smlaicloud/screens/report/stock/report_stock_balance_barcode_wh_location.dart';
import 'package:smlaicloud/screens/report/stock/report_stock_balance_location_barcode.dart';
import 'package:smlaicloud/screens/report/stock/report_stock_balance_wh_barcode.dart';
import 'package:smlaicloud/screens/report/stock/report_stock_movement_cost.dart';
import 'package:smlaicloud/usersystem/select_shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:smlaicloud/bloc/login_bloc/login_bloc.dart';
import 'package:smlaicloud/bloc/profile/profile_bloc.dart';
import 'package:smlaicloud/global.dart';
import 'package:smlaicloud/model/profile_model.dart';
import 'package:smlaicloud/model/timezones_model.dart';
import 'package:smlaicloud/screens/config/add_product_to_branch_screen.dart';
import 'package:smlaicloud/screens/config/add_product_to_department_screen.dart';
import 'package:smlaicloud/screens/config/add_product_to_kitchen_screen.dart';
import 'package:smlaicloud/screens/config/book_bank_screen.dart';
import 'package:smlaicloud/screens/config/business_type_screen.dart';
import 'package:smlaicloud/screens/config/holiday_screen.dart';
import 'package:smlaicloud/screens/config/order_type_screen.dart';
import 'package:smlaicloud/screens/config/product_category_list_screen.dart';
import 'package:smlaicloud/screens/config/product_location.dart';
import 'package:smlaicloud/screens/config/product_type_screen.dart';
import 'package:smlaicloud/screens/config/product_warehouse.dart';
import 'package:smlaicloud/screens/config/promotion_screen.dart';
import 'package:smlaicloud/screens/config/sale_channel.dart';
import 'package:smlaicloud/screens/config/transport_channel.dart';
import 'package:smlaicloud/screens/config/work_day_screen.dart';
import 'package:smlaicloud/screens/transaction/transaction_paid.dart';
import 'package:smlaicloud/screens/transaction/transaction_edit.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:smlaicloud/screens/config/color_screen.dart';
import 'package:smlaicloud/global.dart' as global;
import 'package:smlaicloud/select_language_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rounded_date_picker/flutter_rounded_date_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'flavors.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => MenuScreenState();
}

class MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late TabController mainTabController = TabController(length: 4, vsync: this, initialIndex: global.activeIndexMenu);
  List<Widget> masterMenuList = [];
  List<Widget> masterProductMenuList = [];
  List<Widget> transactionPurchaseMenuList = [];
  List<Widget> transactionSaleMenuList = [];
  List<Widget> transactionStockMenuList = [];
  List<Widget> transactionPaidMenuList = [];
  List<Widget> reportMenuListOld = [];
  Widget reportMenuList = const SizedBox();
  List<Widget> customerMenuList = [];
  List<Widget> newMenuList = [];
  List<Widget> configMenuList = [];
  List<Widget> restaurantMenuList = [];
  List<Widget> glMenuList = [];
  List<Widget> configCompanyMenuList = [];
  List<Widget> masterDataMenuList = [];

  // สีจากตารางสี
  final Color primaryColor = const Color(0xFF1A73E8);
  final Color primaryDarkColor = const Color(0xFF0D47A1);
  final Color primaryLightColor = const Color(0xFF90CAF9);
  final Color secondaryColor = const Color(0xFF00BCD4);
  final Color secondaryDarkColor = const Color(0xFF0097A7);
  final Color secondaryLightColor = const Color(0xFF80DEEA);
  final Color backgroundColor = const Color(0xFFF7F7F7);
  final Color surfaceColor = const Color(0xFFFFFFFF);
  final Color errorColor = const Color(0xFFB00020);
  final Color successColor = const Color(0xFF107E3E);
  final Color warningColor = const Color(0xFFE9730C);
  final Color infoColor = const Color(0xFF0070F2);

  // สีสำหรับปุ่มและการแสดงข้อมูลทางการเงิน
  final Color positiveColor = const Color(0xFF0B8043);
  final Color negativeColor = const Color(0xFFD50000);
  final Color pendingColor = const Color(0xFFF9A825);
  final Color verifiedColor = const Color(0xFF039BE5);
  final Color taxColor = const Color(0xFF7B1FA2);
  final Color assetColor = const Color(0xFF00897B);
  final Color liabilityColor = const Color(0xFFC2185B);

  // สีสำหรับชาร์ตและการวิเคราะห์
  final Map<String, Color> chartColors = {
    'income': const Color(0xFF2E7D32),
    'expense': const Color(0xFFC62828),
    'assets': const Color(0xFF1565C0),
    'liabilities': const Color(0xFFD81B60),
    'equity': const Color(0xFF6A1B9A),
    'series1': const Color(0xFF5899DA),
    'series2': const Color(0xFFE8743B),
    'series3': const Color(0xFF19A979),
    'series4': const Color(0xFFED4A7B),
    'series5': const Color(0xFF945ECF),
    'series6': const Color(0xFF13A4B4),
    'series7': const Color(0xFF525DF4),
    'series8': const Color(0xFFBF399E),
  };

  // ปรับปรุงสีใหม่สำหรับปุ่มเมนู (เพิ่มความสว่าง)
  final Map<String, List<Color>> menuButtonColors = {
    'config': [const Color(0xFF1976D2), const Color(0xFF2196F3)],
    'customer': [const Color(0xFF00ACC1), const Color(0xFF26C6DA)],
    'master': [const Color(0xFF00897B), const Color(0xFF26A69A)],
    'transaction': [const Color(0xFF43A047), const Color(0xFF66BB6A)],
    'report': [const Color(0xFFFB8C00), const Color(0xFFFFB74D)],
    'restaurant': [const Color(0xFF7E57C2), const Color(0xFF9575CD)],
    'gl': [const Color(0xFF00ACC1), const Color(0xFF4DD0E1)],
    'finance': [const Color(0xFFEC407A), const Color(0xFFF48FB1)],
    'system': [const Color(0xFF5C6BC0), const Color(0xFF7986CB)],
  };

  Widget menuWidget({
    required String label,
    required String category,
    IconData? icon,
    required Function callback,
  }) {
    List<Color> gradientColors = menuButtonColors[category] ?? [primaryDarkColor, primaryColor];

    // เพิ่มเงาให้คมชัดขึ้น
    List<Shadow> textShadows = [
      Shadow(
        offset: const Offset(1.0, 1.0),
        blurRadius: 2.0,
        color: Colors.black.withOpacity(0.4),
      ),
    ];

    Widget textWidget = Center(
      child: AutoSizeText(
        label,
        maxLines: 3,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ).copyWith(shadows: textShadows),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(8),
          foregroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          callback();
        },
        child: (icon == null)
            ? textWidget
            : Stack(
                children: [
                  textWidget,
                  Positioned(
                    right: 4,
                    top: 8,
                    child: Icon(
                      icon,
                      size: 22,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: const Offset(1.0, 1.0),
                          blurRadius: 2.0,
                          color: Colors.black.withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void buildMenu() {
    // เช็คค่า ismainshop จาก shop_info
    bool showCreateSubShop = false;
    String? shopInfoJson = global.appConfig.getString("shop_info");

    if (shopInfoJson != null && shopInfoJson.isNotEmpty) {
      try {
        ShopModel shopModel = ShopModel.fromJson(jsonDecode(shopInfoJson));
        String mainShopId = shopModel.mainshopid ?? '';
        bool ismainShopid = shopModel.ismainshop ?? false;
        if (ismainShopid) {
          showCreateSubShop = true;
        }
      } catch (e) {
        // ถ้า error ในการ parse ให้ไม่แสดงเมนู
        showCreateSubShop = false;
      }
    }

    // เช็ค role จาก storage
    String userRole = global.appConfig.getString("role") ?? "0";
    bool isUser = userRole == "0";
    bool isAdmin = userRole == "1";
    bool isSuperAdmin = userRole == "2";

    // เช็คว่าเป็น flavor ที่ต้องการหรือไม่
    bool isTargetFlavor = (F.appFlavor == Flavor.dohomedev || F.appFlavor == Flavor.dohomeprod || F.appFlavor == Flavor.dohomeuat);
    configMenuList = [];

    // เพิ่มเมนูพื้นฐานสำหรับ superadmin เท่านั้น
    if (isSuperAdmin) {
      // configMenuList.add(menuWidget(
      //     label: global.language("system_config"),
      //     category: 'config',
      //     icon: Icons.settings_applications,
      //     callback: () {
      //       Navigator.pushNamed(context, '/config_system');
      //     }));
      configMenuList.add(menuWidget(
          label: global.language("company"),
          category: 'config',
          icon: Icons.domain,
          callback: () {
            Navigator.pushNamed(context, '/company');
          }));
      configMenuList.add(
        menuWidget(
            label: global.language("company_branch"),
            category: 'config',
            icon: Icons.account_tree,
            callback: () {
              Navigator.pushNamed(context, '/branch');
            }),
      );
      configMenuList.add(
        menuWidget(
            label: global.language("company_department"),
            category: 'config',
            icon: Icons.groups,
            callback: () {
              Navigator.pushNamed(context, '/department');
            }),
      );
      configMenuList.add(
        menuWidget(
            label: global.language("company_type"),
            category: 'config',
            icon: Icons.business_center,
            callback: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BusinessTypeScreen()),
              );
            }),
      );
      if (global.posVersion == global.PosVersionEnum.restaurant) {
        configMenuList.add(
          menuWidget(
              label: global.language("workday"),
              category: 'config',
              icon: Icons.calendar_today,
              callback: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkDayScreen()),
                );
              }),
        );

        configMenuList.add(
          menuWidget(
              label: global.language("holidays"),
              category: 'config',
              icon: Icons.beach_access,
              callback: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HolidayScreen()),
                );
              }),
        );
      }
    }

    // เมนู employee - แสดงสำหรับ user, admin และ superadmin
    if (isTargetFlavor) {
      configMenuList.add(
        menuWidget(
            label: global.language("employee"),
            category: 'system',
            icon: Icons.badge,
            callback: () {
              Navigator.pushNamed(context, '/employee');
            }),
      );

      // เมนู user - แสดงสำหรับ admin และ superadmin เท่านั้น
      if (isAdmin || isSuperAdmin) {
        configMenuList.add(
          menuWidget(
              label: global.language("user"),
              category: 'system',
              icon: Icons.person_add,
              callback: () {
                Navigator.pushNamed(context, '/user');
              }),
        );
      }
    } else {
      // สำหรับ flavor อื่น ๆ ให้แสดงเมนูปกติ
      configMenuList.add(
        menuWidget(
            label: global.language("employee"),
            category: 'system',
            icon: Icons.badge,
            callback: () {
              Navigator.pushNamed(context, '/employee');
            }),
      );
      configMenuList.add(
        menuWidget(
            label: global.language("user"),
            category: 'system',
            icon: Icons.person_add,
            callback: () {
              Navigator.pushNamed(context, '/user');
            }),
      );
    }
    // เพิ่มเมนูสร้างร้านย่อยเฉพาะเมื่อ ismainshop = true
    if (showCreateSubShop) {
      configMenuList.add(
        menuWidget(
            label: "สร้างร้านย่อย",
            category: 'system',
            icon: Icons.store,
            callback: () {
              CreateSubShopDialog.show(context);
            }),
      );
    }
    if (global.posVersion == global.PosVersionEnum.restaurant && isSuperAdmin) {
      configMenuList.add(
        menuWidget(
            label: global.language("line_notify"),
            category: 'system',
            icon: FontAwesomeIcons.bell,
            callback: () {
              Navigator.pushNamed(context, '/line_notify');
            }),
      );
    }

    customerMenuList = [];
    // สำหรับ target flavor ให้เช็ค role, สำหรับ flavor อื่น ๆ ให้แสดงปกติ
    if (!isTargetFlavor || isUser || isAdmin || isSuperAdmin) {
      customerMenuList.add(menuWidget(
          label: global.language("creditor"),
          category: 'customer',
          icon: Icons.attach_money,
          callback: () {
            Navigator.pushNamed(context, '/creditor');
          }));
      customerMenuList.add(menuWidget(
          label: global.language("creditor_group"),
          category: 'customer',
          icon: Icons.group_work,
          callback: () {
            Navigator.pushNamed(context, '/creditorgroup');
          }));
      customerMenuList.add(menuWidget(
          label: global.language("debtor"),
          category: 'customer',
          icon: Icons.account_balance_wallet,
          callback: () {
            Navigator.pushNamed(context, '/debtor');
          }));
      customerMenuList.add(menuWidget(
          label: global.language("debtor_group"),
          category: 'customer',
          icon: Icons.bubble_chart,
          callback: () {
            Navigator.pushNamed(context, '/debtorgroup');
          }));
    }

    newMenuList = [];
    if (global.posVersion == global.PosVersionEnum.restaurant && isSuperAdmin) {
      newMenuList.add(
        menuWidget(
            label: global.language("color"),
            category: 'system',
            icon: Icons.palette,
            callback: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ColorScreen()),
              );
            }),
      );
    }

    // สำหรับ target flavor เฉพาะ admin และ superadmin เท่านั้น
    if (!isTargetFlavor || isAdmin || isSuperAdmin) {
      newMenuList.add(menuWidget(
          label: global.language("qr_provider"),
          category: 'system',
          icon: Icons.qr_code_scanner,
          callback: () {
            Navigator.pushNamed(context, '/qrprovider');
          }));
      newMenuList.add(
        menuWidget(
            label: global.language("bank"),
            category: 'finance',
            icon: Icons.account_balance,
            callback: () {
              Navigator.pushNamed(context, '/bank');
            }),
      );
      newMenuList.add(
        menuWidget(
            label: global.language("book_bank"),
            category: 'finance',
            icon: Icons.menu_book,
            callback: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BookBankScreen()),
              );
            }),
      );
    }

    if (global.posVersion == global.PosVersionEnum.restaurant && isSuperAdmin) {
      newMenuList.add(
        menuWidget(
            label: global.language("sale_channel"),
            category: 'master',
            icon: Icons.shopping_basket,
            callback: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SaleChannelScreen()),
              );
            }),
      );
      newMenuList.add(
        menuWidget(
            label: global.language("transport_channel"),
            category: 'master',
            icon: Icons.local_shipping,
            callback: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TransportChannelScreen()),
              );
            }),
      );
    }

    // สำหรับ target flavor เฉพาะ admin และ superadmin เท่านั้น
    if (!isTargetFlavor || isAdmin || isSuperAdmin) {
      newMenuList.add(
        menuWidget(
            label: global.language("pos_setting"),
            category: 'system',
            icon: Icons.point_of_sale,
            callback: () {
              Navigator.pushNamed(context, '/possetting');
            }),
      );
    }

    if (isSuperAdmin) {
      newMenuList.add(
        menuWidget(
            label: global.language("pos_media"),
            category: 'system',
            icon: Icons.perm_media,
            callback: () {
              Navigator.pushNamed(context, '/posmedia');
            }),
      );
      newMenuList.add(
        menuWidget(
            label: 'กำหนดแต้มสะสม',
            category: 'system',
            icon: Icons.card_membership,
            callback: () {
              Navigator.pushNamed(context, '/point_setting');
            }),
      );
      newMenuList.add(
        menuWidget(
            label: 'กำหนดคูปอง',
            category: 'system',
            icon: Icons.card_membership,
            callback: () {
              Navigator.pushNamed(context, '/coupon_setting');
            }),
      );
      if (global.posVersion == global.PosVersionEnum.restaurant) {
        newMenuList.add(
          menuWidget(
              label: global.language("doc_format"),
              category: 'system',
              icon: Icons.description,
              callback: () {
                Navigator.pushNamed(context, '/docformat');
              }),
        );
        newMenuList.add(
          menuWidget(
              label: global.language("bill_design"),
              category: 'system',
              icon: Icons.receipt_long,
              callback: () {
                Navigator.pushNamed(context, '/billdesign');
              }),
        );
      }
    }
    masterMenuList = [];

    // เมนูที่ user, admin และ superadmin เห็นได้ทั้งหมด
    if (!isTargetFlavor || isUser || isAdmin || isSuperAdmin) {
      masterMenuList.add(
        menuWidget(
            label: global.language("barcode"),
            category: 'master',
            icon: Icons.qr_code,
            callback: () {
              Navigator.pushNamed(context, '/product_barcode');
            }),
      );
      masterMenuList.add(
        menuWidget(
            label: global.language("product_unit"),
            category: 'master',
            icon: Icons.straighten,
            callback: () {
              Navigator.pushNamed(context, '/productunit');
            }),
      );
      masterMenuList.add(
        menuWidget(
            label: 'พิมพ์ Label สินค้า',
            category: 'master',
            icon: Icons.print,
            callback: () {
              Navigator.pushNamed(context, '/product_barcode_shelf');
            }),
      );
    }

    // เมนูที่เฉพาะ superadmin หรือ flavor อื่น ๆ เท่านั้น
    if (!isTargetFlavor || isSuperAdmin) {
      masterMenuList.add(
        menuWidget(
            label: global.language("product"),
            category: 'master',
            icon: Icons.inventory_2,
            callback: () {
              Navigator.pushNamed(context, '/product');
            }),
      );
      // masterMenuList.add(
      //   menuWidget(
      //       label: global.language("product_group"),
      //       category: 'master',
      //       icon: Icons.category,
      //       callback: () {
      //         Navigator.pushNamed(context, '/productgroup');
      //       }),
      // );
      masterMenuList.add(
        menuWidget(
            label: global.language("product_category"),
            category: 'master',
            icon: Icons.folder,
            callback: () {
              Navigator.pushNamed(context, '/product_category_group_select_screen');
            }),
      );
      masterMenuList.add(
        menuWidget(
            label: global.language("product_category_list"),
            category: 'master',
            icon: Icons.list,
            callback: () {
              Navigator.pushNamed(context, '/productcategorylist');
            }),
      );
      masterMenuList.add(menuWidget(
          label: global.language("product_warehouse"),
          category: 'master',
          icon: Icons.warehouse,
          callback: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProductWarehouseScreen()),
            );
          }));
      masterMenuList.add(menuWidget(
          label: global.language("product_location"),
          category: 'master',
          icon: Icons.location_on,
          callback: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProductLocaltionScreen()),
            );
          }));
      if (global.posVersion == global.PosVersionEnum.restaurant) {
        masterMenuList.add(menuWidget(
            label: global.language("order_type"),
            category: 'master',
            icon: Icons.restaurant_menu,
            callback: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderTypeScreen()),
              );
            }));
      }
      masterMenuList.add(menuWidget(
          label: global.language("product_type"),
          category: 'master',
          icon: Icons.style,
          callback: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProductTypeScreen()),
            );
          }));
      masterMenuList.add(menuWidget(
          label: global.language("product_dimension"),
          category: 'master',
          icon: Icons.architecture,
          callback: () {
            Navigator.pushNamed(context, '/product_dimension');
          }));
      if (global.posVersion == global.PosVersionEnum.restaurant) {
        masterMenuList.add(
          menuWidget(
              label: global.language("product_bom"),
              category: 'master',
              icon: Icons.ballot,
              callback: () {
                Navigator.pushNamed(context, '/product_bom');
              }),
        );
      }
    }

    // เมนูที่เฉพาะ admin และ superadmin เท่านั้น สำหรับ target flavor
    if (!isTargetFlavor || isAdmin || isSuperAdmin) {
      masterMenuList.add(menuWidget(
          label: global.language("promotion"),
          category: 'master',
          icon: Icons.card_giftcard,
          callback: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PromotionScreen()),
            );
          }));
      masterMenuList.add(
        menuWidget(
            label: 'ประวัติการแก้ไขราคาสินค้า',
            category: 'master',
            icon: Icons.money,
            callback: () {
              Navigator.pushNamed(context, '/price_history');
            }),
      );
    }
    masterProductMenuList = [];
    // สำหรับ target flavor เฉพาะ admin และ superadmin เท่านั้น
    if (!isTargetFlavor || isAdmin || isSuperAdmin) {
      if (F.appFlavor == Flavor.smlaidev || F.appFlavor == Flavor.smlaiprod || F.appFlavor == Flavor.smlaiuat) {
        masterProductMenuList.add(
          menuWidget(
              label: global.language("add_product_from_data_center"),
              category: 'master',
              icon: Icons.cloud_download,
              callback: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductCategoryListScreen()),
                );
              }),
        );
      }

      if (global.posVersion == global.PosVersionEnum.restaurant) {
        masterProductMenuList.add(
          menuWidget(
              label: global.language("add_product_to_branch"),
              category: 'master',
              icon: Icons.merge_type,
              callback: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddProductToBranchScreen()),
                );
              }),
        );
        masterProductMenuList.add(menuWidget(
            label: global.language("add_product_to_department"),
            category: 'master',
            icon: Icons.add_business,
            callback: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddProductToDepartmentScreen()),
              );
            }));
      }

      masterProductMenuList.add(
        menuWidget(
            label: global.language("import_product"),
            category: 'master',
            icon: Icons.file_upload,
            callback: () {
              Navigator.pushNamed(context, '/importproduct');
            }),
      );
    }

    // เฉพาะ superadmin เท่านั้น สำหรับ target flavor
    if (!isTargetFlavor || isSuperAdmin) {
      masterProductMenuList.add(
        menuWidget(
            label: global.language("import_product_image"),
            category: 'master',
            icon: Icons.image,
            callback: () {
              Navigator.pushNamed(context, '/importproductimage');
            }),
      );
    }
    transactionPurchaseMenuList = [];
    transactionPurchaseMenuList.add(
      menuWidget(
          label: global.language("transaction_purchase_order"),
          category: 'transaction',
          icon: Icons.shopping_cart,
          callback: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionEditScreen(type: global.TransactionTypeEnum.purchaseorder)),
            );
          }),
    );
    transactionPurchaseMenuList.add(
      menuWidget(
          label: global.language("transaction_purchase"),
          category: 'transaction',
          icon: Icons.add_shopping_cart,
          callback: () {
            Navigator.pushNamed(context, '/transaction/purchase');
          }),
    );
    transactionPurchaseMenuList.add(
      menuWidget(
          label: global.language("transaction_purchase_return"),
          category: 'transaction',
          icon: Icons.assignment_return,
          callback: () {
            Navigator.pushNamed(context, '/transaction/purchasereturn');
          }),
    );
    transactionPurchaseMenuList.add(
      menuWidget(
          label: 'รับสินค้าแบบทยอย',
          category: 'transaction',
          icon: Icons.add_shopping_cart,
          callback: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionEditScreen(type: global.TransactionTypeEnum.purchasepartial)),
            );
          }),
    );
    transactionPurchaseMenuList.add(
      menuWidget(
          label: 'ตั้งหนี้จากการทยอยรับสินค้า',
          category: 'transaction',
          icon: Icons.add_shopping_cart,
          callback: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionEditScreen(type: global.TransactionTypeEnum.accrualreceive)),
            );
          }),
    );

    transactionSaleMenuList = [];
    transactionSaleMenuList.add(
      menuWidget(
          label: global.language("transaction_sale_order"),
          category: 'transaction',
          icon: Icons.shopping_cart,
          callback: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionEditScreen(type: global.TransactionTypeEnum.saleorder)),
            );
          }),
    );
    transactionSaleMenuList.add(
      menuWidget(
          label: global.language("transaction_sale"),
          category: 'transaction',
          icon: Icons.shopping_cart_checkout,
          callback: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionEditScreen(type: global.TransactionTypeEnum.sale)),
            );
          }),
    );
    transactionSaleMenuList.add(
      menuWidget(
          label: global.language("transaction_sale_return"),
          category: 'transaction',
          icon: Icons.assignment_return,
          callback: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionEditScreen(type: global.TransactionTypeEnum.salereturn)),
            );
          }),
    );
    transactionStockMenuList = [];
    transactionStockMenuList.add(
      menuWidget(
          label: global.language("transaction_stock_transfer"),
          category: 'transaction',
          icon: Icons.swap_horiz,
          callback: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionEditScreen(type: global.TransactionTypeEnum.stocktransfer)),
            );
          }),
    );
    transactionStockMenuList.add(
      menuWidget(
          label: global.language("transaction_stock_receive_product"),
          category: 'transaction',
          icon: Icons.move_to_inbox,
          callback: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionEditScreen(type: global.TransactionTypeEnum.stockreceiveproduct)),
            );
          }),
    );

    transactionStockMenuList.add(
      menuWidget(
          label: global.language("transaction_stock_pick_up_product"),
          category: 'transaction',
          icon: Icons.outbox,
          callback: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionEditScreen(type: global.TransactionTypeEnum.stockpickupproduct)),
            );
          }),
    );
    transactionStockMenuList.add(
      menuWidget(
          label: global.language("transaction_stock_return_product"),
          category: 'transaction',
          icon: Icons.assignment_return,
          callback: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionEditScreen(type: global.TransactionTypeEnum.stockreturnproduct)),
            );
          }),
    );
    transactionStockMenuList.add(
      menuWidget(
          label: global.language("transaction_adjust"),
          category: 'transaction',
          icon: Icons.balance,
          callback: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionEditScreen(type: global.TransactionTypeEnum.adjust)),
            );
          }),
    );
    transactionStockMenuList.add(
      menuWidget(
          label: global.language("transaction_stock_balance"),
          category: 'transaction',
          icon: Icons.inventory,
          callback: () {
            Navigator.pushNamed(context, '/transaction/stockbalance');
          }),
    );
    transactionPaidMenuList = [];
    transactionPaidMenuList.addAll([
      menuWidget(
          label: global.language("transaction_paid"),
          category: 'finance',
          icon: Icons.payments,
          callback: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionPaidScreen(type: global.TransactionTypeEnum.paid)),
            );
          }),
      menuWidget(
          label: global.language("transaction_pay"),
          category: 'finance',
          icon: Icons.credit_card,
          callback: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionPaidScreen(type: global.TransactionTypeEnum.pay)),
            );
          }),
    ]);
    reportMenuListOld = [];
    reportMenuListOld.addAll([
      menuWidget(
          label: global.language("report"),
          category: 'report',
          icon: Icons.assessment,
          callback: () {
            Navigator.pushNamed(context, '/report/pdfreport');
          }),
      if (F.appFlavor == Flavor.smlaidev || F.appFlavor == Flavor.smlaiprod || F.appFlavor == Flavor.smlaiuat) ...[
        menuWidget(
            label: 'รายงานยอดขาย',
            category: 'report',
            icon: Icons.assessment,
            callback: () {
              Navigator.pushNamed(context, '/report/report_dedebi_sales');
            }),
        menuWidget(
            label: 'รายงานยอดขาย ตามวันที่',
            category: 'report',
            icon: Icons.assessment,
            callback: () {
              Navigator.pushNamed(context, '/report/report_dedebi_sales_daily');
            }),
        menuWidget(
            label: 'เคลื่อนไหวสินค้า',
            category: 'report',
            icon: Icons.assessment,
            callback: () {
              Navigator.pushNamed(context, '/report/report_stock_movement');
            }),
        menuWidget(
            label: 'รายงานรับเงิน ตามวันที่',
            category: 'report',
            icon: Icons.assessment,
            callback: () {
              Navigator.pushNamed(context, '/report/report_dedebi_payment_daily');
            }),
        menuWidget(
            label: 'รายงานลดหนี้/รับคืน',
            category: 'report',
            icon: Icons.assessment,
            callback: () {
              Navigator.pushNamed(context, '/report/report_dedebi_sale_return');
            }),
        menuWidget(
            label: 'รายงานสินค้าคงเหลือ',
            category: 'report',
            icon: Icons.assessment,
            callback: () {
              Navigator.pushNamed(context, '/report/report_dedebi_stock_balance');
            }),
      ]
    ]);
    var reporMenuProductList = [
      menuWidget(
          label: global.language("Build"),
          category: 'report',
          icon: Icons.build,
          callback: () async {
            // Show loading dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return Dialog(
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text(
                          global.language("processing..."),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

            try {
              var payload = {
                "shop_id": global.getShopId(),
                "command_id": "rebuild",
              };
              var jsonPayload = jsonEncode(payload);
              var jsonResult = await reportServicePost(jsonPayload);

              // Close the loading dialog
              Navigator.of(context).pop();

              if (jsonResult['code'] == 200) {
                global.showSnackBar(
                    context,
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                    ),
                    global.language("success"),
                    Colors.green);
              } else {
                global.showSnackBar(
                    context,
                    const Icon(
                      Icons.error,
                      color: Colors.white,
                    ),
                    global.language("error") + ": " + jsonResult['message'],
                    Colors.red);
              }
            } catch (e) {
              // Close the loading dialog in case of error
              Navigator.of(context).pop();

              global.showSnackBar(
                  context,
                  const Icon(
                    Icons.error,
                    color: Colors.white,
                  ),
                  global.language("error") + ": " + e.toString(),
                  Colors.red);
            }
          }),
      menuWidget(
          label: global.language("สินค้าคงเหลือ ตามสินค้า"),
          category: 'report',
          icon: Icons.description,
          callback: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportStockBalanceBarcodeWhLocation(),
                ));
          }),
      menuWidget(
          label: global.language("สินค้าคงเหลือ ตามคลัง"),
          category: 'report',
          icon: Icons.summarize,
          callback: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportStockBalanceWhBarcode(),
                ));
          }),
      menuWidget(
          label: global.language("สินค้าคงเหลือ ตามที่เก็บ"),
          category: 'report',
          icon: Icons.insert_chart,
          callback: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportStockBalanceLocationBarcode(),
                ));
          }),
      menuWidget(
          label: global.language("เคลื่อนไหวสินค้า พร้อมต้นทุน"),
          category: 'report',
          icon: Icons.insert_chart,
          callback: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportStockMovementCost(),
                ));
          }),
    ];
    reportMenuList = SingleChildScrollView(
      child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            buildMenuCategoryContainer(
              title: "รายงานสินค้าคงเหลือ",
              menuItems: reporMenuProductList,
            ),
            const SizedBox(height: 15),
            buildMenuCategoryContainer(
              title: "รายงานอื่นๆ",
              menuItems: reportMenuListOld,
            ),
          ])),
    );
    restaurantMenuList = [];
    if (global.posVersion == global.PosVersionEnum.restaurant && isSuperAdmin) {
      restaurantMenuList.add(
        menuWidget(
            label: global.language("zone"),
            category: 'restaurant',
            icon: Icons.grid_on,
            callback: () {
              Navigator.pushNamed(context, '/zone_group_select_screen');
            }),
      );
      restaurantMenuList.add(
        menuWidget(
            label: global.language("table"),
            category: 'restaurant',
            icon: Icons.table_bar,
            callback: () {
              Navigator.pushNamed(context, '/table_group_select_screen');
            }),
      );
      restaurantMenuList.add(
        menuWidget(
            label: global.language("table_map"),
            category: 'restaurant',
            icon: Icons.maps_home_work,
            callback: () {
              Navigator.pushNamed(context, '/table_map_group_select_screen');
            }),
      );
      restaurantMenuList.add(
        menuWidget(
            label: global.language("kitchen"),
            category: 'restaurant',
            icon: Icons.kitchen,
            callback: () {
              Navigator.pushNamed(context, '/kitchen_group_select_screen');
            }),
      );
      restaurantMenuList.add(
        menuWidget(
            label: global.language("add_product_to_kitchen"),
            category: 'restaurant',
            icon: Icons.restaurant,
            callback: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddProductToKitchenScreen()),
              );
            }),
      );
      restaurantMenuList.add(
        menuWidget(
            label: global.language("qr_code_order"),
            category: 'restaurant',
            icon: Icons.qr_code_2,
            callback: () {
              Navigator.pushNamed(context, '/qrcodeorder_group_select_screen');
            }),
      );
      restaurantMenuList.add(
        menuWidget(
            label: global.language("order_template_setting"),
            category: 'restaurant',
            icon: Icons.receipt,
            callback: () {
              Navigator.pushNamed(context, '/ordertemplatsetting');
            }),
      );
      restaurantMenuList.add(
        menuWidget(
            label: global.language("order_setting"),
            category: 'restaurant',
            icon: Icons.settings_applications,
            callback: () {
              Navigator.pushNamed(context, '/ordersetting');
            }),
      );
    }
    glMenuList = [];
    if (isSuperAdmin || isAdmin || isUser) {
      glMenuList.addAll([
        // menuWidget(
        //     label: global.language("gl_process"),
        //     category: 'gl',
        //     icon: Icons.account_balance,
        //     callback: () {
        //       Navigator.pushNamed(context, '/gl/gl_process');
        //     }),
        menuWidget(
            label: global.language("check_daily"),
            category: 'gl',
            icon: Icons.fact_check,
            callback: () {
              Navigator.pushNamed(context, '/check_daily/daily_info_screen');
            }),
        menuWidget(
            label: 'การรับเงิน/การส่งเงิน (POS)',
            category: 'gl',
            icon: Icons.fact_check,
            callback: () {
              Navigator.pushNamed(context, '/cashing_in_the_drawer');
            }),
      ]);
    }

    /// ข้อมูลหลัก
    masterDataMenuList = [];
    if (isSuperAdmin) {
      masterDataMenuList.add(
        menuWidget(
            label: global.language("brand"),
            category: 'master',
            icon: Icons.settings,
            callback: () {
              Navigator.pushNamed(context, '/master_brand_screen');
            }),
      );
      masterDataMenuList.add(
        menuWidget(
            label: global.language("category"),
            category: 'master',
            icon: Icons.category,
            callback: () {
              Navigator.pushNamed(context, '/master_category_screen');
            }),
      );
      masterDataMenuList.add(
        menuWidget(
            label: global.language("class"),
            category: 'master',
            icon: Icons.class_,
            callback: () {
              Navigator.pushNamed(context, '/master_class_screen');
            }),
      );
      masterDataMenuList.add(
        menuWidget(
            label: global.language("design"),
            category: 'master',
            icon: Icons.design_services,
            callback: () {
              Navigator.pushNamed(context, '/master_design_screen');
            }),
      );
      masterDataMenuList.add(
        menuWidget(
            label: global.language("grade"),
            category: 'master',
            icon: Icons.grade,
            callback: () {
              Navigator.pushNamed(context, '/master_grade_screen');
            }),
      );
      masterDataMenuList.add(
        menuWidget(
            label: global.language("model"),
            category: 'master',
            icon: Icons.model_training,
            callback: () {
              Navigator.pushNamed(context, '/master_model_screen');
            }),
      );
      masterDataMenuList.add(
        menuWidget(
            label: global.language("pattern"),
            category: 'master',
            icon: Icons.pattern,
            callback: () {
              Navigator.pushNamed(context, '/master_pattern_screen');
            }),
      );
      masterDataMenuList.add(
        menuWidget(
            label: global.language("group_main"),
            category: 'master',
            icon: Icons.pattern,
            callback: () {
              Navigator.pushNamed(context, '/master_group_screen');
            }),
      );
      masterDataMenuList.add(
        menuWidget(
            label: global.language("group_sub1"),
            category: 'master',
            icon: Icons.pattern,
            callback: () {
              Navigator.pushNamed(context, '/master_group_sub1_screen');
            }),
      );
      masterDataMenuList.add(
        menuWidget(
            label: global.language("group_sub2"),
            category: 'master',
            icon: Icons.pattern,
            callback: () {
              Navigator.pushNamed(context, '/master_group_sub2_screen');
            }),
      );
    }
  }

  // วิดเจ็ตสำหรับแสดงส่วนหัวของกลุ่มเมนู
  Widget buildMenuCategoryContainer({
    required String title,
    required List<Widget> menuItems,
  }) {
    // ถ้าไม่มีเมนูให้ return SizedBox.shrink() เพื่อซ่อน
    if (menuItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                color: primaryDarkColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.all(0),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: menuItems.length,
            itemBuilder: (BuildContext ctx, index) {
              return menuItems[index];
            },
          ),
        ],
      ),
    );
  }

  void setSystemLanguageList() async {
    await global.setSystemLanguage(context);
    mainTabController.addListener(() {
      global.activeIndexMenu = mainTabController.index;
    });
    buildMenu();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    TabController(length: 4, vsync: this, initialIndex: global.activeIndexMenu);
    setSystemLanguageList();
    global.getApiServiceVersion().then((value) {
      global.goApiVersion = value.toString();
      setState(() {});
    });
  }

  String getHeader() {
    String headTitle = "";
    global.activeLangName(global.companyBranchSelectData.names);
    if (mounted) {
      setState(() {
        switch (global.activeIndexMenu) {
          case 0:
            headTitle = global.language("menu_transaction");
            break;
          case 1:
            headTitle = global.language("menu_report");
            break;
          case 2:
            headTitle = global.language("menu_master");
            break;
          case 3:
            headTitle = global.language("menu_setup");
            break;
        }
      });
    }
    return headTitle;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LogoutSuccess) {
              Navigator.pushNamedAndRemoveUntil(context, '/login_screen', (route) => false);
            }
          },
        ),
        BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is UpdateProfileSuccess) {
              setState(() {
                global.showSnackBar(
                    context,
                    const Icon(
                      Icons.edit,
                      color: Colors.white,
                    ),
                    global.language("edit_success"),
                    Colors.blue);
              });
              context.read<ProfileBloc>().add(const GetProfile());
            }
            if (state is GetProfileSuccess) {
              setState(() {
                global.profileData = state.profile;
                if (global.profileData.yeartype == "buddhist") {
                  global.local = const Locale('th', 'TH');
                  global.eraMode = EraMode.BUDDHIST_YEAR;
                }
              });
            }
          },
        ),
      ],
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Text(
                getHeader(),
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      offset: const Offset(1.5, 1.5),
                      blurRadius: 3.0,
                      color: Colors.black.withOpacity(0.4),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0A3880),
          actions: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.swap_vert,
                    shadows: [
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 3.0,
                        color: Color.fromARGB(128, 0, 0, 0),
                      ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SelectShopScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.logout,
                    shadows: [
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 3.0,
                        color: Color.fromARGB(128, 0, 0, 0),
                      ),
                    ],
                  ),
                  onPressed: () {
                    context.read<LoginBloc>().add(const Logout());
                  },
                ),
                IconButton(
                  icon: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Image.asset('assets/flags/${global.userLanguage}.png')),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SelectLanguageScreen()),
                    ).then((value) {
                      if (value != null) {
                        setState(() {
                          global.userLanguage = value;
                          global.appConfig.setString('language', global.userLanguage);
                          global.languageSelect(global.userLanguage);
                          Navigator.of(context).pushReplacementNamed('/menu');
                        });
                      }
                    });
                  },
                )
              ],
            )
          ],
        ),
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Colors.white,
                primaryLightColor.withOpacity(0.3),
                Colors.white.withOpacity(0.9),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 10, right: 10, top: 4, bottom: 4),
                color: primaryDarkColor.withOpacity(0.95),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                          (appConfig.getString("name") != "")
                              ? (appConfig.getString("name") ?? "")
                              : global.activeLangName(
                                  global.shopSelectData.names!,
                                ),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(width: 10),
                      Text(
                        " (${global.activeLangName(global.companyBranchSelectData.names)})",
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      /*if (appConfig.getInt("branch_total") != 1)
                      ElevatedButton(
                        onPressed: (appConfig.getInt("branch_total") != 1)
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SelectBranchScreen()),
                                );
                              }
                            : null,
                        child: null,
                      ),*/
                      SizedBox(width: 10),
                      Text("SHOP ID : ${global.getShopId()} : Api (${global.goApiVersion})",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ))
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 5),
                    child: ElevatedButton(
                      onPressed: () {
                        dialogProfile(context);
                      },
                      child: Row(
                        children: [
                          Text(
                            "${global.userLoginData.name} (${global.userLoginData.email})",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(1.0, 1.0),
                                  blurRadius: 3.0,
                                  color: Color.fromARGB(128, 0, 0, 0),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            color: Colors.white,
                            Icons.person,
                            shadows: [
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 3.0,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
              Expanded(
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: mainTabController,
                  children: [
                    SingleChildScrollView(
                        child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(children: [
                              buildMenuCategoryContainer(
                                title: "รายการซื้อ",
                                menuItems: transactionPurchaseMenuList,
                              ),
                              const SizedBox(height: 15),
                              buildMenuCategoryContainer(
                                title: "รายการขาย",
                                menuItems: transactionSaleMenuList,
                              ),
                              const SizedBox(height: 15),
                              buildMenuCategoryContainer(
                                title: "รายการสต็อก",
                                menuItems: transactionStockMenuList,
                              ),
                              const SizedBox(height: 15),
                              buildMenuCategoryContainer(
                                title: "รายการชำระเงิน",
                                menuItems: transactionPaidMenuList,
                              ),
                              const SizedBox(height: 15),
                              buildMenuCategoryContainer(
                                title: "รายการบัญชี",
                                menuItems: glMenuList,
                              ),
                            ]))),
                    reportMenuList,
                    SingleChildScrollView(
                        child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(children: [
                              buildMenuCategoryContainer(
                                title: "จัดการสินค้า",
                                menuItems: masterMenuList,
                              ),
                              const SizedBox(height: 15),
                              buildMenuCategoryContainer(
                                title: "จัดการฐานข้อมูล",
                                menuItems: masterProductMenuList,
                              ),
                              const SizedBox(height: 15),
                              buildMenuCategoryContainer(
                                title: "จัดการลูกค้า/เจ้าหนี้",
                                menuItems: customerMenuList,
                              ),
                              const SizedBox(height: 15),
                              buildMenuCategoryContainer(
                                title: "ตั้งค่าการขาย",
                                menuItems: newMenuList,
                              ),
                              const SizedBox(height: 15),
                              buildMenuCategoryContainer(
                                title: "ข้อมูลหลัก",
                                menuItems: masterDataMenuList,
                              ),
                              const SizedBox(height: 15),
                              if (global.posVersion == global.PosVersionEnum.restaurant)
                                buildMenuCategoryContainer(
                                  title: "ร้านอาหาร/คาเฟ่",
                                  menuItems: restaurantMenuList,
                                ),
                            ]))),
                    SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: buildMenuCategoryContainer(
                          title: "การตั้งค่าระบบ",
                          menuItems: configMenuList,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          elevation: 10.0,
          currentIndex: global.activeIndexMenu,
          backgroundColor: primaryDarkColor.withOpacity(0.95),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(.60),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 3.0,
                color: Color.fromARGB(150, 0, 0, 0),
              ),
            ],
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          onTap: (value) {
            setState(() {
              global.activeIndexMenu = value;
              mainTabController.animateTo(value);
            });
          },
          items: [
            BottomNavigationBarItem(
              label: global.language("menu_transaction"),
              icon: const Icon(
                Icons.transcribe,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 3.0,
                    color: Color.fromARGB(150, 0, 0, 0),
                  ),
                ],
              ),
            ),
            BottomNavigationBarItem(
              label: global.language("menu_report"),
              icon: const Icon(
                Icons.assessment,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 3.0,
                    color: Color.fromARGB(150, 0, 0, 0),
                  ),
                ],
              ),
            ),
            BottomNavigationBarItem(
              label: global.language("menu_master"),
              icon: const Icon(
                Icons.inventory_2,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 3.0,
                    color: Color.fromARGB(150, 0, 0, 0),
                  ),
                ],
              ),
            ),
            BottomNavigationBarItem(
              label: global.language("menu_setup"),
              icon: const Icon(
                Icons.settings,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 3.0,
                    color: Color.fromARGB(150, 0, 0, 0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> dialogProfile(BuildContext contexte) {
    TimezonesModel timezonesModel = TimezonesModel(
      abbr: '',
      isDst: false,
      offset: '',
      text: '',
      utc: [],
      value: '',
    );
    String yeartype = "";
    if (global.profileData.timezonelabel!.isNotEmpty) {
      timezonesModel = global.timezonesListData.firstWhere((element) => element.text == global.profileData.timezonelabel);
    }
    if (global.profileData.yeartype!.isNotEmpty) {
      yeartype = global.profileData.yeartype!;
    }
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text((appConfig.getString("name") != "") ? appConfig.getString("name") ?? "" : global.activeLangName(global.shopSelectData.names!)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                width: 500,
                height: 200,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person),
                        Text(global.profileData.name!),
                      ],
                    ),
                    const SizedBox(
                      height: 15.0,
                    ),
                    DropdownSearch<TimezonesModel>(
                      asyncItems: (String filter) => global.getTimezonesList(filter),
                      compareFn: (item, selectedItem) => item.text == selectedItem.text,
                      itemAsString: (TimezonesModel? timezone) {
                        if (timezone!.text.isEmpty) return '';
                        return timezone.text;
                      },
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.only(left: 10, top: 0, bottom: 0, right: 10),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: global.language("timezone"),
                        ),
                      ),
                      onChanged: (TimezonesModel? value) {
                        setState(() {
                          timezonesModel = value!;
                        });
                      },
                      popupProps: const PopupPropsMultiSelection.dialog(
                        showSearchBox: true,
                        showSelectedItems: true,
                      ),
                      selectedItem: timezonesModel,
                    ),
                    const SizedBox(
                      height: 15.0,
                    ),
                    Row(
                      children: [
                        Radio(
                          value: "christian",
                          groupValue: yeartype,
                          onChanged: (value) {
                            setState(() {
                              yeartype = value.toString();
                            });
                          },
                        ),
                        Text(global.language("christian")),
                        Radio(
                          value: "buddhist",
                          groupValue: yeartype,
                          onChanged: (value) {
                            setState(() {
                              yeartype = value.toString();
                            });
                          },
                        ),
                        Text(global.language("buddhist")),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                ProfileModel profileModel = ProfileModel(
                  username: global.profileData.username,
                  name: global.profileData.name,
                  avatar: global.profileData.avatar,
                  timezonelabel: timezonesModel.text,
                  timezoneoffset: timezonesModel.offset,
                  yeartype: yeartype,
                );
                Navigator.pop(context);
                context.read<ProfileBloc>().add(UpdateProfile(profile: profileModel));
              },
              child: Text(global.language("update")),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(global.language("close")),
            ),
          ],
        );
      },
    );
  }
}

class smlaicloudWidget extends StatelessWidget {
  const smlaicloudWidget({
    super.key,
    required this.mainTabController,
    required this.transactionPurchaseMenuList,
    required this.transactionSaleMenuList,
    required this.transactionStockMenuList,
    required this.transactionPaidMenuList,
    required this.reportMenuList,
    required this.glMenuList,
    required this.masterMenuList,
    required this.masterProductMenuList,
    required this.customerMenuList,
    required this.newMenuList,
    required this.restaurantMenuList,
    required this.configMenuList,
    required this.primaryColor,
    required this.primaryDarkColor,
    required this.masterDataMenuList,
  });

  final TabController mainTabController;
  final List<Widget> transactionPurchaseMenuList;
  final List<Widget> transactionSaleMenuList;
  final List<Widget> transactionStockMenuList;
  final List<Widget> transactionPaidMenuList;
  final Widget reportMenuList;
  final List<Widget> glMenuList;
  final List<Widget> masterMenuList;
  final List<Widget> masterProductMenuList;
  final List<Widget> customerMenuList;
  final List<Widget> newMenuList;
  final List<Widget> restaurantMenuList;
  final List<Widget> configMenuList;
  final Color primaryColor;
  final Color primaryDarkColor;
  final List<Widget> masterDataMenuList;

  // วิดเจ็ตสำหรับแสดงส่วนหัวของกลุ่มเมนู
  Widget buildMenuCategoryContainer({
    required String title,
    required List<Widget> menuItems,
  }) {
    // ถ้าไม่มีเมนูให้ return SizedBox.shrink() เพื่อซ่อน
    if (menuItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                color: primaryDarkColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.all(0),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: menuItems.length,
            itemBuilder: (BuildContext ctx, index) {
              return menuItems[index];
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.white,
              const Color(0xFFBBDEFB).withOpacity(0.5),
              Colors.white,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
                color: primaryColor.withOpacity(0.2),
                child: Text("SHOP : ${global.getShopId()} : Api (${global.goApiVersion})",
                    style: TextStyle(
                      color: primaryDarkColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ))),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                controller: mainTabController,
                children: [
                  SingleChildScrollView(
                      child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(children: [
                            buildMenuCategoryContainer(
                              title: "รายการซื้อ",
                              menuItems: transactionPurchaseMenuList,
                            ),
                            const SizedBox(height: 15),
                            buildMenuCategoryContainer(
                              title: "รายการขาย",
                              menuItems: transactionSaleMenuList,
                            ),
                            const SizedBox(height: 15),
                            buildMenuCategoryContainer(
                              title: "รายการสต็อก",
                              menuItems: transactionStockMenuList,
                            ),
                            const SizedBox(height: 15),
                            buildMenuCategoryContainer(
                              title: "รายการชำระเงิน",
                              menuItems: transactionPaidMenuList,
                            ),
                            const SizedBox(height: 15),
                            buildMenuCategoryContainer(
                              title: "รายการบัญชี",
                              menuItems: glMenuList,
                            ),
                          ]))),
                  reportMenuList,
                  SingleChildScrollView(
                      child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(children: [
                            buildMenuCategoryContainer(
                              title: "จัดการสินค้า",
                              menuItems: masterMenuList,
                            ),
                            const SizedBox(height: 15),
                            buildMenuCategoryContainer(
                              title: "จัดการฐานข้อมูล",
                              menuItems: masterProductMenuList,
                            ),
                            const SizedBox(height: 15),
                            buildMenuCategoryContainer(
                              title: "จัดการลูกค้า/เจ้าหนี้",
                              menuItems: customerMenuList,
                            ),
                            const SizedBox(height: 15),
                            buildMenuCategoryContainer(
                              title: "ตั้งค่าการขาย",
                              menuItems: newMenuList,
                            ),
                            const SizedBox(height: 15),
                            buildMenuCategoryContainer(
                              title: "ข้อมูลหลัก",
                              menuItems: masterDataMenuList,
                            ),
                            const SizedBox(height: 15),
                            if (global.posVersion == global.PosVersionEnum.restaurant)
                              buildMenuCategoryContainer(
                                title: "ร้านอาหาร/คาเฟ่",
                                menuItems: restaurantMenuList,
                              ),
                          ]))),
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: buildMenuCategoryContainer(
                        title: "การตั้งค่าระบบ",
                        menuItems: configMenuList,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ));
  }
}

class SmlAiCloudLiteWidget extends StatelessWidget {
  const SmlAiCloudLiteWidget({
    super.key,
    required this.masterMenuList,
    required this.configMenuList,
    required this.configCompanyMenuList,
  });
  final List<Widget> masterMenuList;
  final List<Widget> configMenuList;
  final List<Widget> configCompanyMenuList;

  // วิดเจ็ตสำหรับแสดงส่วนหัวของกลุ่มเมนู
  Widget buildMenuCategoryContainer({
    required String title,
    required List<Widget> menuItems,
  }) {
    // ถ้าไม่มีเมนูให้ return SizedBox.shrink() เพื่อซ่อน
    if (menuItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1A73E8).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0D47A1),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.all(0),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: menuItems.length,
            itemBuilder: (BuildContext ctx, index) {
              return menuItems[index];
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.white,
            Color(0xFFBBDEFB),
            Colors.white,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    buildMenuCategoryContainer(
                      title: "จัดการสินค้า",
                      menuItems: masterMenuList,
                    ),
                    buildMenuCategoryContainer(
                      title: "การตั้งค่าระบบ",
                      menuItems: configMenuList,
                    ),
                    buildMenuCategoryContainer(
                      title: "การตั้งค่าบริษัท",
                      menuItems: configCompanyMenuList,
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
