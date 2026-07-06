// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  name: json['name'] as String? ?? '',
  username: json['username'] as String? ?? '',
  token: json['token'] as String? ?? '',
  isDev: (json['isDev'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'name': instance.name,
  'username': instance.username,
  'token': instance.token,
  'isDev': instance.isDev,
};
