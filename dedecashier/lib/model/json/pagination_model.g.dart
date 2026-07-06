// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pagination_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginationModel _$PaginationModelFromJson(Map<String, dynamic> json) =>
    PaginationModel(
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      perPage: (json['perPage'] as num).toInt(),
      prev: (json['prev'] as num).toInt(),
      next: (json['next'] as num).toInt(),
      totalPage: (json['totalPage'] as num).toInt(),
    );

Map<String, dynamic> _$PaginationModelToJson(PaginationModel instance) =>
    <String, dynamic>{
      'total': instance.total,
      'page': instance.page,
      'perPage': instance.perPage,
      'prev': instance.prev,
      'next': instance.next,
      'totalPage': instance.totalPage,
    };
