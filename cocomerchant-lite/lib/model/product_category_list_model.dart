import 'package:cocomerchant_lite/model/product_category_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product_category_list_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ProductCategoryListModel {
  late ProductCategoryModel detail;
  late List<ProductCategoryListModel> childCategories;
  late bool isExpand = true;
  late bool isMoveUp = false;
  late bool isMoveDown = false;

  ProductCategoryListModel({
    required this.detail,
    required this.childCategories,
  });

  factory ProductCategoryListModel.fromJson(Map<String, dynamic> json) => _$ProductCategoryListModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductCategoryListModelToJson(this);
}
