enum Flavor {
  smlaidev,
  smlaiprod,
  smlaiuat,
  dohomedev,
  dohomeuat,
  dohomeprod,
}

class F {
  static Flavor? appFlavor;

  static String get name => appFlavor?.name ?? '';

  static String get title {
    switch (appFlavor) {
      case Flavor.smlaidev:
        return 'SMLAI Dev';
      case Flavor.smlaiprod:
        return 'SMLAI Prod';
      case Flavor.smlaiuat:
        return 'SMLAI UAT';
      case Flavor.dohomedev:
        return 'Dohome Dev';
      case Flavor.dohomeuat:
        return 'Dohome UAT';
      case Flavor.dohomeprod:
        return 'Dohome Prod';
      default:
        return 'title';
    }
  }
}
