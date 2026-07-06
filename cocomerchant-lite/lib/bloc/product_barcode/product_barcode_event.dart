part of 'product_barcode_bloc.dart';

abstract class ProductBarcodeEvent extends Equatable {
  const ProductBarcodeEvent();

  @override
  List<Object> get props => [];
}

class ProductBarcodeGet extends ProductBarcodeEvent {
  final String guid;

  const ProductBarcodeGet({required this.guid});

  @override
  List<Object> get props => [guid];
}

class ProductBarcodeGetRef extends ProductBarcodeEvent {
  final String guid;

  const ProductBarcodeGetRef({required this.guid});

  @override
  List<Object> get props => [guid];
}

class ProductBarcodeLoadList extends ProductBarcodeEvent {
  final int limit;
  final int offset;
  final String search;
  final String? itemtype;
  final String branchcode;
  final String businesstypecode;

  /// showbom | notshowbom | all
  final String? isbom;

  /// showsubbarcodes | notshowsubbarcodes | all
  final String? isusesubbarcodes;

  const ProductBarcodeLoadList({
    required this.offset,
    required this.limit,
    required this.search,
    this.itemtype = '',
    required this.branchcode,
    required this.businesstypecode,

    /// showbom | notshowbom | all
    this.isbom = '',

    /// showsubbarcodes | notshowsubbarcodes | all
    this.isusesubbarcodes = '',
  });

  @override
  List<Object> get props => [offset, limit, search, itemtype!, branchcode, businesstypecode];
}

class ProductBarcodeLoadListSearch extends ProductBarcodeEvent {
  final int limit;
  final int offset;
  final String search;
  final String? itemtype;
  final String branchcode;
  final String businesstypecode;

  /// showbom | notshowbom | all
  final String? isbom;

  /// showsubbarcodes | notshowsubbarcodes | all
  final String? isusesubbarcodes;

  const ProductBarcodeLoadListSearch({
    required this.offset,
    required this.limit,
    required this.search,
    this.itemtype = '',
    required this.branchcode,
    required this.businesstypecode,

    /// showbom | notshowbom | all
    this.isbom = '',

    /// showsubbarcodes | notshowsubbarcodes | all
    this.isusesubbarcodes = '',
  });

  @override
  List<Object> get props => [offset, limit, search, itemtype!, branchcode, businesstypecode];
}

class ProductBarcodeDelete extends ProductBarcodeEvent {
  final String guid;

  const ProductBarcodeDelete({
    required this.guid,
  });

  @override
  List<Object> get props => [guid];
}

class ProductBarcodeDeleteMany extends ProductBarcodeEvent {
  final List<String> guid;

  const ProductBarcodeDeleteMany({
    required this.guid,
  });

  @override
  List<Object> get props => [guid];
}

class ProductBarcodeSave extends ProductBarcodeEvent {
  final ProductBarcodeModel productBarcode;

  const ProductBarcodeSave({
    required this.productBarcode,
  });

  @override
  List<Object> get props => [productBarcode];
}

class ProductBarcodeUpdate extends ProductBarcodeEvent {
  final String guid;
  final ProductBarcodeModel productBarcode;

  const ProductBarcodeUpdate({
    required this.guid,
    required this.productBarcode,
  });

  @override
  List<Object> get props => [productBarcode];
}

class ProductBarcodeWithImageSave extends ProductBarcodeEvent {
  final File imageFile;
  final ProductBarcodeModel productBarcode;
  final Uint8List? imageWeb;
  const ProductBarcodeWithImageSave({
    required this.imageWeb,
    required this.imageFile,
    required this.productBarcode,
  });

  @override
  List<Object> get props => [productBarcode, imageFile];
}

class ProductBarcodeWithImageUpdate extends ProductBarcodeEvent {
  final String guid;
  final ProductBarcodeModel productBarcode;
  final File imageFile;
  final Uint8List imageWeb;
  const ProductBarcodeWithImageUpdate({
    required this.guid,
    required this.imageFile,
    required this.imageWeb,
    required this.productBarcode,
  });

  @override
  List<Object> get props => [productBarcode, imageWeb, productBarcode];
}

class ProductBarcodeGetBom extends ProductBarcodeEvent {
  final String barcode;

  const ProductBarcodeGetBom({required this.barcode});

  @override
  List<Object> get props => [barcode];
}
