import 'dart:convert';

import 'package:dedecashier/api/sync/model/promotion_model.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class PromotionObjectBoxStruct {
  int id = 0;

  @Unique()
  @Index(type: IndexType.hash)
  String guidfixed;

  int type;
  int index;

  @Index(type: IndexType.hash)
  String promotion_code;

  @Property(type: PropertyType.date)
  @Index()
  DateTime date_begin;

  @Property(type: PropertyType.date)
  @Index()
  DateTime date_end;

  @Index()
  String promotion_name;

  int customer_only;
  String discount_text;
  String promotion_item_code_include_list_json;
  double limit_qty;
  double promotion_qty;
  double limit_amount;

  PromotionObjectBoxStruct({
    this.guidfixed = "",
    this.type = 0,
    this.index = 0,
    this.promotion_code = "",
    DateTime? date_begin,
    DateTime? date_end,
    this.promotion_name = "",
    this.discount_text = "",
    List<PromotionProductIncludeModel>? promotion_item_code_include_list,
    this.limit_qty = 0,
    this.promotion_qty = 0,
    this.limit_amount = 0,
    this.customer_only = 0,
  }) : promotion_item_code_include_list_json = jsonEncode(
         promotion_item_code_include_list?.map((e) => e.toJson()).toList() ??
             [],
       ),
       date_begin = date_begin ?? DateTime.now(),
       date_end = date_end ?? DateTime.now();

  List<PromotionProductIncludeModel> get promotion_item_code_include_list {
    return (jsonDecode(promotion_item_code_include_list_json) as List)
        .map((e) => PromotionProductIncludeModel.fromJson(e))
        .toList();
  }
}
