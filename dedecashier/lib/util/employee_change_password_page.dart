import 'dart:io';
import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/util/loading_screen.dart';
import 'package:dedecashier/util/login_by_employee_page.dart';
import 'package:dedecashier/util/select_language_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/core/logger/app_logger.dart';

class EmployeeChangePasswordPage extends StatefulWidget {
  const EmployeeChangePasswordPage({super.key});

  @override
  _EmployeeChangePasswordState createState() => _EmployeeChangePasswordState();
}

class _EmployeeChangePasswordState extends State<EmployeeChangePasswordPage> {
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newFirstPasswordController = TextEditingController();
  TextEditingController newSecondPasswordController = TextEditingController();
  String lastStatus = "";

  @override
  void initState() {
    super.initState();
    oldPasswordController.text = '';
    newFirstPasswordController.text = '';
    newSecondPasswordController.text = '';
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newFirstPasswordController.dispose();
    newSecondPasswordController.dispose();
    super.dispose();
  }

  void changePassword() {
    oldPasswordController.text = oldPasswordController.text.trim();
    newFirstPasswordController.text = newFirstPasswordController.text.trim();
    newSecondPasswordController.text = newSecondPasswordController.text.trim();
    AppLogger.debug(global.userLogin!.pin_code);
    if (oldPasswordController.text != global.userLogin!.pin_code) {
      setState(() {
        lastStatus = global.language("old_password_not_match");
      });
      return;
    } else if (newFirstPasswordController.text !=
        newSecondPasswordController.text) {
      setState(() {
        lastStatus = global.language("new_password_not_match");
      });
      return;
    } else {
      ApiRepository apiRepository = ApiRepository();
      apiRepository
          .userChangePassword(
            global.userLogin!.code,
            newFirstPasswordController.text,
          )
          .then((result) {
            if (result == true) {
              global.loadConfig();
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginByEmployeePage(),
                  ),
                );
              }
            } else {
              setState(() {
                lastStatus = global.language("change_password_fail");
              });
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.red[100],
        appBar: AppBar(
          title: Text(
            "${global.language("change_password")} ${global.applicationName}",
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginByEmployeePage(),
                ),
              );
            },
          ),
          actions: [
            IconButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(global.language('register_new_machine')),
                      content: Text(
                        global.language(
                          'register_new_machine_for_other_databases',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(global.language("not_required")),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            /*context.router.pushAndPopUntil(
                                        const RegisterPosTerminalRoute(),
                                        predicate: (route) => false);*/
                          },
                          child: Text(global.language("required")),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.settings),
            ),
            IconButton(
              icon: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Image.asset(
                  'assets/flags/${global.userScreenLanguage}.png',
                ),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectLanguageScreen(),
                  ),
                );
                setState(() {});
              },
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.file(
                    File(global.getShopLogoPathName()),
                    width: 100,
                    height: 100,
                  ),
                  Text(
                    global.getNameFromLanguage(
                      global.profileSetting.company.names,
                      global.userScreenLanguage,
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    autofocus: true,
                    controller: oldPasswordController,
                    decoration: InputDecoration(
                      labelText: global.language("old_password"),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: newFirstPasswordController,
                    decoration: InputDecoration(
                      labelText: global.language("new_password"),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: newSecondPasswordController,
                    decoration: InputDecoration(
                      labelText: global.language("new_password_confirm"),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(lastStatus, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {
                        changePassword();
                      },
                      child: Text(global.language("change_password")),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
