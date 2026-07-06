import 'package:objectbox/objectbox.dart';
import 'package:json_annotation/json_annotation.dart';

part 'kitchen_struct.g.dart';

@JsonSerializable(explicitToJson: true)
@Entity()
class KitchenObjectBoxStruct {
  int id = 0;

  @Unique()
  @Index(type: IndexType.hash)
  String guidfixed;

  @Index(type: IndexType.hash)
  String code;

  @Index()
  String names;

  List<String> products;
  List<String> zones;

  KitchenObjectBoxStruct({
    required this.guidfixed,
    required this.code,
    required this.names,
    required this.products,
    required this.zones,
  });

  factory KitchenObjectBoxStruct.fromJson(Map<String, dynamic> json) =>
      _$KitchenObjectBoxStructFromJson(json);
  Map<String, dynamic> toJson() => _$KitchenObjectBoxStructToJson(this);
}
