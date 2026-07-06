import 'package:smlaicloud/app_const.dart';

class Environment {
  factory Environment() {
    return _singleton;
  }

  Environment._internal();

  static final Environment _singleton = Environment._internal();

  static const String DEV = 'DEV';
  static const String PROD = 'PROD';
  static const String UAT = 'UAT';
  static const String DOHOME_DEV = 'DOHOME_DEV';
  static const String DOHOME_PROD = 'DOHOME_PROD';
  static const String DOHOME_UAT = 'DOHOME_UAT';

  late BaseConfig config;
  late bool isDev;

  initConfig(String environment) {
    config = _getConfig(environment);
    isDev = environment == DEV || environment == UAT;
  }

  BaseConfig _getConfig(String environment) {
    switch (environment) {
      case DEV:
        return DevConfig();
      case PROD:
        return ProdConfig();
      case UAT:
        return UATConfig();
      case DOHOME_DEV:
        return DohomeDevConfig();
      case DOHOME_PROD:
        return DohomeProdConfig();
      case DOHOME_UAT:
        return DohomeUATConfig();
      default:
        throw Exception('Invalid environment: $environment');
    }
  }

  // API URLs by environment
  // Using AppConfig for API URL references
  static String get devServiceClickhouse => AppConfig.devServiceClickhouse;
  static String get devServiceApi => AppConfig.devServiceApi;

  static String get uatServiceClickhouse => AppConfig.uatServiceClickhouse;
  static String get uatServiceApi => AppConfig.uatServiceApi;

  static String get prodServiceClickhouse => AppConfig.prodServiceClickhouse;
  static String get prodServiceApi => AppConfig.prodServiceApi;

  // SMLA Cloud API URLs
  static String get serviceDevApi => AppConfig.serviceDevApi;
  static String get reportDevApi => AppConfig.reportDevApi;

  // Report BI APIs
  static String get reportDevBiApi => AppConfig.reportDevBiApi;
  static String get reportProdBiApi => AppConfig.reportPrdBiApi;
  static String get reportUATBiApi => AppConfig.reportUATBiApi;

  // Dohome API URLs
  static String get dohomeDevServiceClickhouse => AppConfig.dohomeDevServiceClickhouse;
  static String get dohomeDevServiceApi => AppConfig.dohomeDevServiceApi;

  static String get dohomeProdServiceClickhouse => AppConfig.dohomeProdServiceClickhouse;
  static String get dohomeProdServiceApi => AppConfig.dohomeProdServiceApi;

  static String get dohomeUATServiceClickhouse => AppConfig.dohomeUATServiceClickhouse;
  static String get dohomeUATServiceApi => AppConfig.dohomeUATService;
}

abstract class BaseConfig {
  String get serviceApi;
  String get reportApi;
  String get webSocketCartService;
  String get serviceClickhouse;
  String get reportApiPath;
  String get reportApiPort;
  String get reportBiApi;
}

class DevConfig extends BaseConfig {
  @override
  String get serviceApi => AppConfig.serviceDevApi;

  @override
  String get reportApi => AppConfig.reportDevApi;

  @override
  String get webSocketCartService => AppConfig.webSocketCartServiceDev;

  @override
  String get serviceClickhouse => Environment.devServiceClickhouse;

  @override
  String get reportApiPath => Environment.devServiceApi;

  @override
  String get reportApiPort => "";

  @override
  String get reportBiApi => AppConfig.reportDevBiApi;
}

class ProdConfig extends BaseConfig {
  @override
  String get serviceApi => AppConfig.servicePrdApi;

  @override
  String get reportApi => AppConfig.reportPrdApi;

  @override
  String get webSocketCartService => AppConfig.webSocketCartServicePrd;

  @override
  String get serviceClickhouse => Environment.prodServiceClickhouse;

  @override
  String get reportApiPath => Environment.prodServiceApi;

  @override
  String get reportApiPort => "";

  @override
  String get reportBiApi => AppConfig.reportPrdBiApi;
}

class UATConfig extends BaseConfig {
  @override
  String get serviceApi => AppConfig.serviceUATApi;

  @override
  String get reportApi => AppConfig.reportUATApi;

  @override
  String get webSocketCartService => AppConfig.webSocketCartServiceUAT;

  @override
  String get serviceClickhouse => Environment.uatServiceClickhouse;

  @override
  String get reportApiPath => Environment.uatServiceApi;

  @override
  String get reportApiPort => "";

  @override
  String get reportBiApi => AppConfig.reportUATBiApi;
}

class DohomeDevConfig extends BaseConfig {
  @override
  String get serviceApi => AppConfig.serviceDohomeDevApi;

  @override
  String get reportApi => AppConfig.reportDohomeDevApi;

  @override
  String get webSocketCartService => AppConfig.webSocketDohomeCartServiceDev;

  @override
  String get serviceClickhouse => Environment.dohomeDevServiceClickhouse;

  @override
  String get reportApiPath => Environment.dohomeDevServiceApi;

  @override
  String get reportApiPort => "";

  @override
  String get reportBiApi => AppConfig.reportDohomeDevBiApi;
}

class DohomeProdConfig extends BaseConfig {
  @override
  String get serviceApi => AppConfig.serviceDohomePrdApi;

  @override
  String get reportApi => AppConfig.reportDohomePrdApi;

  @override
  String get webSocketCartService => AppConfig.webSocketDohomeCartServicePrd;

  @override
  String get serviceClickhouse => Environment.dohomeProdServiceClickhouse;

  @override
  String get reportApiPath => Environment.dohomeProdServiceApi;

  @override
  String get reportApiPort => "";

  @override
  String get reportBiApi => AppConfig.reportDohomePrdBiApi;
}

class DohomeUATConfig extends BaseConfig {
  @override
  String get serviceApi => AppConfig.serviceDohomeUATApi;

  @override
  String get reportApi => AppConfig.reportDohomeUATApi;

  @override
  String get webSocketCartService => AppConfig.webSocketDohomeCartServiceUAT;

  @override
  String get serviceClickhouse => Environment.dohomeUATServiceClickhouse;

  @override
  String get reportApiPath => Environment.dohomeUATServiceApi;

  @override
  String get reportApiPort => "";

  @override
  String get reportBiApi => AppConfig.reportDohomeUATBiApi;
}
