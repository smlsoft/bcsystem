// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'promotion_model.g.dart';

@JsonSerializable()
class PromotionModel {
  // หัวข้อส่วนลด
  late String promotion_code;
  late DateTime date_begin;
  late DateTime date_end;
  late String promotion_name_1;
  late String promotion_name_2;
  late String promotion_name_3;
  late String promotion_name_4;
  late String promotion_name_5;
  late int customer_only;

  PromotionModel({required this.promotion_code, required this.date_begin, required this.date_end, required this.promotion_name_1, this.promotion_name_2 = '', this.promotion_name_3 = '', this.promotion_name_4 = '', this.promotion_name_5 = '', this.customer_only = 0});

  factory PromotionModel.fromJson(Map<String, dynamic> json) => _$PromotionModelFromJson(json);
  Map<String, dynamic> toJson() => _$PromotionModelToJson(this);

  /*factory PromotionStruct.fromJson(dynamic json) {
    return PromotionStruct(
      promotion_code: json['promotion_code'],
      date_begin: json['date_begin'],
      date_end: json['date_end'],
      promotion_name_1: json['promotion_name_1'],
      promotion_name_2: json['promotion_name_2'],
      promotion_name_3: json['promotion_name_3'],
      promotion_name_4: json['promotion_name_4'],
      promotion_name_5: json['promotion_name_5'],
      customer_only: json['customer_only'],
    );
  }
  Map toJson() => {'promotion_code': promotion_code, 'date_begin': date_begin, 'date_end': date_end, 'promotion_name_1': promotion_name_1, 'promotion_name_2': promotion_name_2, 'promotion_name_3': promotion_name_3, 'promotion_name_4': promotion_name_4, 'promotion_name_5': promotion_name_5, 'customer_only': customer_only};

  PromotionStruct.map(dynamic obj) {
    promotion_code = obj["promotion_code"];
    date_begin = obj["date_begin"];
    date_end = obj["date_end"];
    promotion_name_1 = obj["promotion_name_1"];
    promotion_name_2 = obj["promotion_name_2"];
    promotion_name_3 = obj["promotion_name_3"];
    promotion_name_4 = obj["promotion_name_4"];
    promotion_name_5 = obj["promotion_name_5"];
    customer_only = int.parse(obj["customer_only"].toString());
  }

  Map<String, dynamic> toMap() {
    var _map = <String, dynamic>{};

    _map["promotion_code"] = promotion_code;
    _map["promotion_name_1"] = promotion_name_1;
    _map["promotion_name_2"] = promotion_name_2;
    _map["promotion_name_3"] = promotion_name_3;
    _map["promotion_name_4"] = promotion_name_4;
    _map["promotion_name_5"] = promotion_name_5;
    _map["date_begin"] = date_begin;
    _map["date_end"] = date_end;
    _map["customer_only"] = customer_only;

    return _map;
  }*/
}

@JsonSerializable()
class PromotionDiscountModel {
  // ส่วนลด เช่น ซื้อ 2 แถม 1 = ลด 50%
  late String code_detail;
  late String promotion_code;
  late String promotion_barcode;
  late double limit_qty;
  late String promotion_discount;
  late int include_extra; // เอายอดรวมของส่วนเพิ่มมาคิดด้วยหรือไม่ (1=Yes,0=No)

  PromotionDiscountModel({required this.code_detail, required this.promotion_code, required this.promotion_barcode, required this.limit_qty, required this.promotion_discount, this.include_extra = 0});
  factory PromotionDiscountModel.fromJson(Map<String, dynamic> json) => _$PromotionDiscountModelFromJson(json);
  Map<String, dynamic> toJson() => _$PromotionDiscountModelToJson(this);
  /*factory PromotionDiscountStruct.fromJson(dynamic json) {
    return PromotionDiscountStruct(
      code_detail: json['code_detail'],
      promotion_code: json['promotion_code'],
      promotion_barcode: json['promotion_barcode'],
      limit_qty: json['limit_qty'],
      discount: json['promotion_discount'],
      include_extra: json['include_extra'],
    );
  }

  Map toJson() => {'code_detail': code_detail, 'promotion_code': promotion_code, 'promotion_barcode': promotion_barcode, 'limit_qty': limit_qty, 'promotion_discount': discount, 'include_extra': include_extra};

  PromotionDiscountStruct.map(dynamic obj) {
    code_detail = obj["code_detail"];
    promotion_code = obj["promotion_code"];
    promotion_barcode = obj["promotion_barcode"];
    limit_qty = double.parse(obj["limit_qty"].toString());
    discount = obj["promotion_discount"];
    include_extra = int.parse(obj["include_extra"].toString());
  }

  Map<String, dynamic> toMap() {
    var _map = <String, dynamic>{};

    _map["code_detail"] = code_detail;
    _map["promotion_code"] = promotion_code;
    _map["promotion_barcode"] = promotion_barcode;
    _map["limit_qty"] = limit_qty;
    _map["promotion_discount"] = discount;
    _map["include_extra"] = include_extra;

    return _map;
  }*/
}

@JsonSerializable()
class PromotionTempModel {
  // เพื่อเพิ่มความเร็วในการประมวลผล เอาทุกอย่างมาไว้ที่เดียว
  late String promotion_code;
  late DateTime date_begin;
  late DateTime date_end;
  late String name_1;
  late String name_2;
  late String name_3;
  late String name_4;
  late String name_5;
  late String promotion_name_1;
  late String promotion_name_2;
  late String promotion_name_3;
  late String promotion_name_4;
  late String promotion_name_5;
  late int customer_only;
  late String barcode_promotion;
  late double limit_qty;
  late String discount_text;
  late int include_extra; // เอายอดรวมของส่วนเพิ่มมาคิดด้วยหรือไม่ (1=Yes,0=No)

  PromotionTempModel({required this.promotion_code, required this.date_begin, required this.date_end, this.name_1 = "", this.name_2 = "", this.name_3 = "", this.name_4 = "", this.name_5 = "", required this.barcode_promotion, this.customer_only = 0, required this.discount_text, required this.limit_qty, required this.promotion_name_1, this.promotion_name_2 = "", this.promotion_name_3 = "", this.promotion_name_4 = "", this.promotion_name_5 = "", this.include_extra = 0});

  factory PromotionTempModel.fromJson(Map<String, dynamic> json) => _$PromotionTempModelFromJson(json);
  Map<String, dynamic> toJson() => _$PromotionTempModelToJson(this);

  /*factory PromotionTempStruct.fromJson(dynamic json) {
    return PromotionTempStruct(promotion_code: json["promotion_code"], date_begin: json["date_begin"], date_end: json["date_end"], name_1: json["name_1"], name_2: json["name_2"], name_3: json["name_3"], name_4: json["name_4"], name_5: json["name_5"], promotion_name_1: json["promotion_name_1"], promotion_name_2: json["promotion_name_2"], promotion_name_3: json["promotion_name_3"], promotionName_4: json["promotion_name_4"], promotionName_5: json["promotion_name_5"], customer_only: json["customer_only"], barcode_promotion: json["barcode_promotion"], limit_qty: json["limit_qty"], discount: json["discount"], include_extra: json["include_extra"]);
  }

  Map toJson() => {"promotion_code": promotion_code, "date_begin": date_begin, "date_end": date_end, "name_1": name_1, "name_2": name_2, "name_3": name_3, "name_4": name_4, "name_5": name_5, "promotion_name_1": promotion_name_1, "promotion_name_2": promotion_name_2, "promotion_name_3": promotion_name_3, "promotion_name_4": promotionName_4, "promotion_name_5": promotionName_5, "customer_only": customer_only, "barcode_promotion": barcode_promotion, "limit_qty": limit_qty, "discount": discount, "include_extra": include_extra};

  PromotionTempStruct.map(dynamic obj) {
    promotion_code = obj["promotion_code"];
    date_begin = obj["date_begin"];
    date_end = obj["date_end"];
    name_1 = obj["name_1"];
    name_2 = obj["name_2"];
    name_3 = obj["name_3"];
    name_4 = obj["name_4"];
    name_5 = obj["name_5"];
    promotion_name_1 = obj["promotion_name_1"];
    promotion_name_2 = obj["promotion_name_2"];
    promotion_name_3 = obj["promotion_name_3"];
    promotionName_4 = obj["promotion_name_4"];
    promotionName_5 = obj["promotion_name_5"];
    customer_only = int.parse(obj["customer_only"].toString());
    barcode_promotion = obj["barcode_promotion"];
    limit_qty = double.parse(obj["limit_qty"].toString());
    discount = obj["discount"];
    include_extra = int.parse(obj["include_extra"].toString());
  }

  Map<String, dynamic> toMap() {
    var _map = <String, dynamic>{};

    _map["promotion_code"] = promotion_code;
    _map["date_begin"] = date_begin;
    _map["date_end"] = date_end;
    _map["name_1"] = name_1;
    _map["name_2"] = name_2;
    _map["name_3"] = name_3;
    _map["name_4"] = name_4;
    _map["name_5"] = name_5;
    _map["promotion_name_1"] = promotion_name_1;
    _map["promotion_name_2"] = promotion_name_2;
    _map["promotion_name_3"] = promotion_name_3;
    _map["promotion_name_4"] = promotionName_4;
    _map["promotion_name_5"] = promotionName_5;
    _map["customer_only"] = customer_only;
    _map["barcode_promotion"] = barcode_promotion;
    _map["limit_qty"] = limit_qty;
    _map["discount"] = discount;
    _map["include_extra"] = include_extra;

    return _map;
  }*/
}

class PromotionProcessByModel {
  late String barcode;
  late double amount;
  late double sum_qty;
  late double extra_amount;

  PromotionProcessByModel({required this.barcode, required this.amount, required this.sum_qty, required this.extra_amount});
}
