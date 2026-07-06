// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmployeeModel _$EmployeeModelFromJson(Map<String, dynamic> json) =>
    EmployeeModel(
      guidfixed: json['guidfixed'] as String,
      code: json['code'] as String,
      profilepicture: json['profilepicture'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      isenabled: json['isenabled'] as bool,
      pincode: json['pincode'] as String,
      isusepos: json['isusepos'] as bool,
    );

Map<String, dynamic> _$EmployeeModelToJson(EmployeeModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'code': instance.code,
      'email': instance.email,
      'isenabled': instance.isenabled,
      'isusepos': instance.isusepos,
      'name': instance.name,
      'profilepicture': instance.profilepicture,
      'pincode': instance.pincode,
    };
