// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_category_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductCategoryListModel _$ProductCategoryListModelFromJson(
        Map<String, dynamic> json) =>
    ProductCategoryListModel(
      detail:
          ProductCategoryModel.fromJson(json['detail'] as Map<String, dynamic>),
      childCategories: (json['childCategories'] as List<dynamic>)
          .map((e) =>
              ProductCategoryListModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    )
      ..isExpand = json['isExpand'] as bool
      ..isMoveUp = json['isMoveUp'] as bool
      ..isMoveDown = json['isMoveDown'] as bool;

Map<String, dynamic> _$ProductCategoryListModelToJson(
        ProductCategoryListModel instance) =>
    <String, dynamic>{
      'detail': instance.detail.toJson(),
      'childCategories':
          instance.childCategories.map((e) => e.toJson()).toList(),
      'isExpand': instance.isExpand,
      'isMoveUp': instance.isMoveUp,
      'isMoveDown': instance.isMoveDown,
    };
