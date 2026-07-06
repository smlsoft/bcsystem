// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_pay_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PosPayModel _$PosPayModelFromJson(Map<String, dynamic> json) =>
    PosPayModel(
        total_amount: (json['total_amount'] as num?)?.toDouble() ?? 0,
        cash_amount_text: json['cash_amount_text'] as String? ?? "",
        cash_amount: (json['cash_amount'] as num?)?.toDouble() ?? 0,
        point_amount: (json['point_amount'] as num?)?.toDouble() ?? 0,
        total_after_discount:
            (json['total_after_discount'] as num?)?.toDouble() ?? 0,
        total_after_round: (json['total_after_round'] as num?)?.toDouble() ?? 0,
        discount_formula: json['discount_formula'] as String? ?? "",
        discount_amount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
        credit_amount: (json['credit_amount'] as num?)?.toDouble() ?? 0,
        round_amount: (json['round_amount'] as num?)?.toDouble() ?? 0,
        round_amount_cash: (json['round_amount_cash'] as num?)?.toDouble(),
        round_amount_credit_card:
            (json['round_amount_credit_card'] as num?)?.toDouble() ?? 0,
        round_amount_transfer:
            (json['round_amount_transfer'] as num?)?.toDouble() ?? 0,
        round_amount_cheque:
            (json['round_amount_cheque'] as num?)?.toDouble() ?? 0,
        round_amount_coupon:
            (json['round_amount_coupon'] as num?)?.toDouble() ?? 0,
        round_amount_qr: (json['round_amount_qr'] as num?)?.toDouble() ?? 0,
        round_amount_delivery:
            (json['round_amount_delivery'] as num?)?.toDouble() ?? 0,
        round_amount_credit:
            (json['round_amount_credit'] as num?)?.toDouble() ?? 0,
        is_delivery: json['is_delivery'] as bool? ?? false,
        delivery_code: json['delivery_code'] as String? ?? "",
        delivery_number: json['delivery_number'] as String? ?? "",
      )
      ..credit_card = (json['credit_card'] as List<dynamic>)
          .map((e) => PayCreditCardModel.fromJson(e as Map<String, dynamic>))
          .toList()
      ..transfer = (json['transfer'] as List<dynamic>)
          .map((e) => PayTransferModel.fromJson(e as Map<String, dynamic>))
          .toList()
      ..cheque = (json['cheque'] as List<dynamic>)
          .map((e) => PayChequeModel.fromJson(e as Map<String, dynamic>))
          .toList()
      ..coupon = (json['coupon'] as List<dynamic>)
          .map((e) => PayCouponModel.fromJson(e as Map<String, dynamic>))
          .toList()
      ..qr = (json['qr'] as List<dynamic>)
          .map((e) => PayQrModel.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$PosPayModelToJson(PosPayModel instance) =>
    <String, dynamic>{
      'cash_amount_text': instance.cash_amount_text,
      'total_amount': instance.total_amount,
      'cash_amount': instance.cash_amount,
      'point_amount': instance.point_amount,
      'discount_formula': instance.discount_formula,
      'discount_amount': instance.discount_amount,
      'total_after_discount': instance.total_after_discount,
      'round_amount': instance.round_amount,
      'round_amount_cash': instance.round_amount_cash,
      'round_amount_credit_card': instance.round_amount_credit_card,
      'round_amount_transfer': instance.round_amount_transfer,
      'round_amount_cheque': instance.round_amount_cheque,
      'round_amount_coupon': instance.round_amount_coupon,
      'round_amount_qr': instance.round_amount_qr,
      'round_amount_delivery': instance.round_amount_delivery,
      'round_amount_credit': instance.round_amount_credit,
      'total_after_round': instance.total_after_round,
      'credit_amount': instance.credit_amount,
      'is_delivery': instance.is_delivery,
      'delivery_code': instance.delivery_code,
      'delivery_number': instance.delivery_number,
      'credit_card': instance.credit_card.map((e) => e.toJson()).toList(),
      'transfer': instance.transfer.map((e) => e.toJson()).toList(),
      'cheque': instance.cheque.map((e) => e.toJson()).toList(),
      'coupon': instance.coupon.map((e) => e.toJson()).toList(),
      'qr': instance.qr.map((e) => e.toJson()).toList(),
    };

PayCouponModel _$PayCouponModelFromJson(Map<String, dynamic> json) =>
    PayCouponModel(
      number: json['number'] as String,
      description: json['description'] as String,
      discount_amount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      cash_voucher_amount:
          (json['cash_voucher_amount'] as num?)?.toDouble() ?? 0.0,
      coupon_type: (json['coupon_type'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PayCouponModelToJson(PayCouponModel instance) =>
    <String, dynamic>{
      'number': instance.number,
      'description': instance.description,
      'discount_amount': instance.discount_amount,
      'cash_voucher_amount': instance.cash_voucher_amount,
      'coupon_type': instance.coupon_type,
    };

PayCashModel _$PayCashModelFromJson(Map<String, dynamic> json) => PayCashModel(
  wallet_id: json['wallet_id'] as String,
  amount: json['amount'] as String,
);

Map<String, dynamic> _$PayCashModelToJson(PayCashModel instance) =>
    <String, dynamic>{
      'wallet_id': instance.wallet_id,
      'amount': instance.amount,
    };

PayCreditCardModel _$PayCreditCardModelFromJson(Map<String, dynamic> json) =>
    PayCreditCardModel(
      book_bank_code: json['book_bank_code'] as String,
      bank_code: json['bank_code'] as String,
      bank_name: json['bank_name'] as String,
      card_number: json['card_number'] as String,
      approved_code: json['approved_code'] as String,
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$PayCreditCardModelToJson(PayCreditCardModel instance) =>
    <String, dynamic>{
      'book_bank_code': instance.book_bank_code,
      'bank_code': instance.bank_code,
      'bank_name': instance.bank_name,
      'card_number': instance.card_number,
      'approved_code': instance.approved_code,
      'amount': instance.amount,
    };

PayTransferModel _$PayTransferModelFromJson(Map<String, dynamic> json) =>
    PayTransferModel(
      book_bank_code: json['book_bank_code'] as String,
      bank_code: json['bank_code'] as String,
      bank_name: json['bank_name'] as String,
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$PayTransferModelToJson(PayTransferModel instance) =>
    <String, dynamic>{
      'book_bank_code': instance.book_bank_code,
      'bank_code': instance.bank_code,
      'bank_name': instance.bank_name,
      'amount': instance.amount,
    };

PayChequeModel _$PayChequeModelFromJson(Map<String, dynamic> json) =>
    PayChequeModel(
      due_date: DateTime.parse(json['due_date'] as String),
      bank_code: json['bank_code'] as String,
      bank_name: json['bank_name'] as String,
      branch_number: json['branch_number'] as String,
      cheque_number: json['cheque_number'] as String,
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$PayChequeModelToJson(PayChequeModel instance) =>
    <String, dynamic>{
      'due_date': instance.due_date.toIso8601String(),
      'bank_code': instance.bank_code,
      'bank_name': instance.bank_name,
      'branch_number': instance.branch_number,
      'cheque_number': instance.cheque_number,
      'amount': instance.amount,
    };

PayDiscountModel _$PayDiscountModelFromJson(Map<String, dynamic> json) =>
    PayDiscountModel(
      code: json['code'] as String,
      description: json['description'] as String,
      formula: json['formula'] as String,
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$PayDiscountModelToJson(PayDiscountModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'description': instance.description,
      'formula': instance.formula,
      'amount': instance.amount,
    };

PayQrModel _$PayQrModelFromJson(Map<String, dynamic> json) => PayQrModel(
  provider_code: json['provider_code'] as String? ?? "",
  provider_name: json['provider_name'] as String? ?? "",
  description: json['description'] as String? ?? "",
  transactionId: json['transactionId'] as String?,
  amount: (json['amount'] as num).toDouble(),
  logo: json['logo'] as String? ?? "",
);

Map<String, dynamic> _$PayQrModelToJson(PayQrModel instance) =>
    <String, dynamic>{
      'provider_code': instance.provider_code,
      'provider_name': instance.provider_name,
      'description': instance.description,
      'transactionId': instance.transactionId,
      'logo': instance.logo,
      'amount': instance.amount,
    };
