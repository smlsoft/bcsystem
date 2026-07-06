// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      role: json['role'] as int,
      shopid: json['shopid'] as String,
      username: json['username'] as String,
      editusername: json['editusername'] as String?,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'role': instance.role,
      'shopid': instance.shopid,
      'username': instance.username,
      'editusername': instance.editusername,
    };
