// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_option_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductOptionModel _$ProductOptionModelFromJson(Map<String, dynamic> json) =>
    ProductOptionModel(
      guid: json['guid'] as String,
      choicetype: (json['choicetype'] as num).toInt(),
      maxselect: (json['maxselect'] as num).toInt(),
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      choices: (json['choices'] as List<dynamic>)
          .map((e) => ProductChoiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    )..select_index = (json['select_index'] as num?)?.toInt();

Map<String, dynamic> _$ProductOptionModelToJson(ProductOptionModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'choicetype': instance.choicetype,
      'maxselect': instance.maxselect,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'choices': instance.choices.map((e) => e.toJson()).toList(),
      'select_index': instance.select_index,
    };

ProductChoiceModel _$ProductChoiceModelFromJson(Map<String, dynamic> json) =>
    ProductChoiceModel(
      guid: json['guid'] as String,
      refproductcode: json['refproductcode'] as String?,
      isdefault: json['isdefault'] as bool?,
      refunitcode: json['refunitcode'] as String?,
      barcode: json['barcode'] as String?,
      names: (json['names'] as List<dynamic>)
          .map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      guidcode: json['guidcode'] as String?,
      price: json['price'] as String,
      qty: (json['qty'] as num).toDouble(),
      isstock: json['isstock'] as bool?,
      selected: json['selected'] as bool?,
      refbarcode: json['refbarcode'] as String?,
      refunitnames: (json['refunitnames'] as List<dynamic>?)
          ?.map((e) => LanguageDataModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductChoiceModelToJson(ProductChoiceModel instance) =>
    <String, dynamic>{
      'guid': instance.guid,
      'names': instance.names.map((e) => e.toJson()).toList(),
      'price': instance.price,
      'guidcode': instance.guidcode,
      'isdefault': instance.isdefault,
      'isstock': instance.isstock,
      'refbarcode': instance.refbarcode,
      'refproductcode': instance.refproductcode,
      'refunitcode': instance.refunitcode,
      'barcode': instance.barcode,
      'refunitnames': instance.refunitnames.map((e) => e.toJson()).toList(),
      'qty': instance.qty,
      'selected': instance.selected,
    };
