import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:smlaicloud/environment.dart';
import 'package:smlaicloud/flavors.dart';

class AppConfigClass {
  String serviceClickhouse = '';
  String serviceApi = '';
  String reportApiPath = '';
  String reportApiPort = "";
}

AppConfigClass appConfigInit() {
  Environment env = Environment();
  AppConfigClass appConfig = AppConfigClass();

  // Get values from current environment
  appConfig.serviceClickhouse = env.config.serviceClickhouse;
  appConfig.serviceApi = env.config.reportApiPath;
  appConfig.reportApiPath = env.config.reportApiPath;
  appConfig.reportApiPort = env.config.reportApiPort;

  // Make sure URLs are correctly formatted for web
  if (kIsWeb) {
    // Force absolute URLs for web environment
    if (!appConfig.serviceClickhouse.startsWith('http')) {
      appConfig.serviceClickhouse = 'https://' + appConfig.serviceClickhouse;
    }
    if (!appConfig.serviceApi.startsWith('http')) {
      appConfig.serviceApi = 'https://' + appConfig.serviceApi;
    }
    if (!appConfig.reportApiPath.startsWith('http')) {
      appConfig.reportApiPath = 'https://' + appConfig.reportApiPath;
    }

    if (kDebugMode) {
      print("Web environment detected, using absolute URLs");
      print("serviceClickhouse: ${appConfig.serviceClickhouse}");
      print("serviceApi: ${appConfig.serviceApi}");
      print("reportApiPath: ${appConfig.reportApiPath}");
    }
  }
  return appConfig;
}
