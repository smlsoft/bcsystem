import 'package:dedecashier/core/environment.dart';
import 'package:dedecashier/features/authentication/auth.dart';
import 'package:dedecashier/features/dashboard/presentation/widgets/dashboard_menu_item.dart';
import 'package:dedecashier/features/dashboard/presentation/widgets/top_bar_shop.dart';
import 'package:dedecashier/util/menu_screen.dart';
import 'package:dedecashier/util/shift_and_money.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/global.dart' as global;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Widget buttonMenuPOS() => ItemMenuDashboard(
        icon: Icons.point_of_sale,
        title: 'POS',
        callBack: () {
          //context.router.push(const POSLoginRoute());
        },
      );

  Widget buttonMenuMoneyFill() => ItemMenuDashboard(
        icon: Icons.payments,
        title: global.language("add_change_money"), // 'รับเงินทอน',
        callBack: () {
          showDialogShiftAndMoney(0);
        },
      );

// ย้ายไป ในหน้าจอ POS
  // Widget buttonMenuPrintFullVatInvoice() => ItemMenuDashboard(
  //       icon: Icons.receipt,
  //       title: global.language(
  //           "print_tax_invoice_full_format"), // พิมพ์ใบกำกับภาษี (แบบเต็ม)
  //       callBack: () {},
  //     );

  Widget buttonPrinterConfig() => ItemMenuDashboard(
      icon: Icons.print_rounded,
      title: global.language('printer_config'),
      callBack: () {
        //context.router.push(const PrinterConfigRoute());
      });

  Widget buttonCancelBillPos() => ItemMenuDashboard(
        icon: Icons.add,
        title: global.language("cancel_invoice"), // 'ยกเลิกใบเสร็จ',
        callBack: () {},
      );

  Widget buttonReprintPos() => ItemMenuDashboard(
        icon: Icons.text_snippet,
        title: global.language("re_print_invoice"), // 'พิมพ์สำเนาใบเสร็จ',
        callBack: () {},
      );

  Widget buttonProductReturn() => ItemMenuDashboard(
        icon: Icons.repartition,
        title: global.language("return_product"), //'คืนสินค้า',
        callBack: () {
          /*context.router.pushAndPopUntil(
              PosRoute(posScreenMode: global.PosScreenModeEnum.posSale),
              predicate: (_) => false);*/
        },
      );

  Widget buttonSubmitSale() => ItemMenuDashboard(
        icon: Icons.monetization_on,
        title: global.language("submit_sales"), // 'ส่งยอดขาย',
        callBack: () {
          showDialogShiftAndMoney(1);
        },
      );
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthenticationInitialState) {
          /*context.router.pushAndPopUntil(const AuthenticationRoute(),
              predicate: (route) => false);*/
        }
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              const TopBarShop(height: 250),
              // Center(
              //   child: Text('xxxxxxxx'),
              // ),
              Visibility(
                  visible: global.isPhoneDevice(),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Row(children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: buttonMenuPOS(),
                            ),
                          ),
                        ]),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: buttonMenuMoneyFill(),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: buttonMenuMoneyFill(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
              Visibility(
                visible: global.isTabletDevice(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: buttonMenuPOS(),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: buttonMenuMoneyFill(),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: buttonSubmitSale(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                visible: global.isTabletDevice(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: buttonReprintPos(),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: buttonCancelBillPos(),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: buttonProductReturn(),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: buttonPrinterConfig(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Visibility(
                  visible: (global.isPhoneDevice()),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: buttonReprintPos(),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: buttonCancelBillPos(),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: buttonProductReturn(),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: buttonPrinterConfig(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )),
              Visibility(
                visible: Environment().isDev,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ItemMenuDashboard(
                              icon: Icons.receipt,
                              title: 'Other Menu',
                              callBack: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MenuScreen()));
                              },
                            ),
                          ),
                        ),
                      ],
                    )),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ItemMenuDashboard(
                          icon: Icons.logout,
                          title: global.language("log_out"), // 'ออกจากระบบ',
                          callBack: () {
                            context.read<AuthenticationBloc>().add(const UserLogoutEvent());
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void showDialogShiftAndMoney(int mode) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              insetPadding: const EdgeInsets.all(0),
              contentPadding: const EdgeInsets.all(0),
              backgroundColor: Colors.transparent,
              content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
                return Container();
              }));
        });
  }
}
