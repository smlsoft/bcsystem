// ignore_for_file: constant_identifier_names

import 'package:cocomerchant_lite/app_const.dart';

class Environment {
  factory Environment() {
    return _singleton;
  }

  Environment._internal();

  static final Environment _singleton = Environment._internal();

  static const String DEV = 'DEV';
  static const String STAGING = 'STAGING';
  static const String PROD = 'PROD';
  static const String INTERNALDEV = 'INTERNALDEV';
  static const String FRONTENDDEV = 'FRONTENDDEV';

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
      case Environment.INTERNALDEV:
        return InternalDevConfig();
      case Environment.STAGING:
        return StagingConfig();
      case Environment.FRONTENDDEV:
        return FrontEndDevConfig();
      default:
        return DevConfig();
    }
  }
}

abstract class BaseConfig {
  String get serviceApi;
  String get reportApi;
}

class DevConfig extends BaseConfig {
  @override
  String get serviceApi => AppConfig.serviceDevApi;

  @override
  String get reportApi => AppConfig.reportDevApi;
}

class ProdConfig extends BaseConfig {
  @override
  String get serviceApi => AppConfig.servicePrdApi;

  @override
  String get reportApi => AppConfig.reportPrdApi;
}

class StagingConfig extends BaseConfig {
  @override
  String get serviceApi => AppConfig.servicePrdApi;

  @override
  String get reportApi => AppConfig.reportPrdApi;
}

class InternalDevConfig extends BaseConfig {
  @override
  String get serviceApi => AppConfig.serviceInternalDevApi;

  @override
  String get reportApi => AppConfig.reportInternalDevApi;
}

class FrontEndDevConfig extends BaseConfig {
  @override
  String get serviceApi => AppConfig.serviceFrontEndDevApi;

  @override
  String get reportApi => AppConfig.reportFrontEndDevApi;
}

class VFDevConfig extends BaseConfig {
  @override
  String get serviceApi => AppConfig.serviceVFDevApi;

  @override
  String get reportApi => AppConfig.reportVFDevApi;
}

class VFPrdConfig extends BaseConfig {
  @override
  String get serviceApi => AppConfig.serviceVFPrdApi;

  @override
  String get reportApi => AppConfig.reportVFPrdApi;
}
