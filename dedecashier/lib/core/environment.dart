// ignore_for_file: constant_identifier_names

import 'package:dedecashier/app/app_constant.dart';

class Environment {
  factory Environment() {
    return _singleton;
  }

  Environment._internal();

  static final Environment _singleton = Environment._internal();

  static const String DEV = 'DEV';
  static const String STAGING = 'STAGING';
  static const String PROD = 'PROD';

  late BaseConfig config;
  late bool isDev;

  initConfig(String environment) {
    config = _getConfig(environment);
    isDev = environment == DEV;
  }

  BaseConfig _getConfig(String environment) {
    switch (environment) {
      case Environment.PROD:
        return ProdConfig();
      case Environment.STAGING:
        return StagingConfig();
      default:
        return DevConfig();
    }
  }
}

abstract class BaseConfig {
  String get serviceApi;
}

class DevConfig extends BaseConfig {
  @override
  String get serviceApi => AppConstant.serviceDevApi;
}

class ProdConfig extends BaseConfig {
  @override
  String get serviceApi => AppConstant.serviceApi;
}

class StagingConfig extends BaseConfig {
  @override
  String get serviceApi => AppConstant.serviceUatApi;
}
