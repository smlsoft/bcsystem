enum Flavor { DEV, BCPOS, SMLSUPERPOS, SMLMOBILESALES, VFPOS, SMLAIPOS, MARINEPOS, CASHIER }

class F {
  static Flavor? appFlavor;

  static String get name => appFlavor?.name ?? '';

  static String get title {
    switch (appFlavor) {
      case Flavor.SMLAIPOS:
        return 'SML AI POS';
      case Flavor.MARINEPOS:
        return 'Marine POS';
      case Flavor.DEV:
        return 'BC POS DEV';
      case Flavor.BCPOS:
        return 'BC POS';
      case Flavor.CASHIER:
        return 'BC Cashier';
      case Flavor.SMLSUPERPOS:
        return 'SML Super POS';
      case Flavor.SMLMOBILESALES:
        return 'SML Mobile Sales';
      case Flavor.VFPOS:
        return 'Village Fund POS';
      default:
        return 'title';
    }
  }
}
