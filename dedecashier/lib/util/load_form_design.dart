import 'dart:convert';

import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/global_model.dart';
import 'package:dedecashier/model/objectbox/form_design_struct.dart';
import 'package:dedecashier/services/print_process.dart';

FormDesignObjectBoxStruct formSummaryStatement() {
  // ใบสรุปยอด/ไม่ใช่ใบเสร็จรับเงิน
  List<FormDesignColumnModel> detailColumn = [
    FormDesignColumnModel(
      command_text: "&item_qty& &item_name&/&item_unit_name& &item_price_and_symbol& &item_discount&",
      header_names: [
        LanguageDataModel(code: "th", name: "รายละเอียด"),
        LanguageDataModel(code: "en", name: "Description"),
      ],
      font_weight_bold: true,
      width: 5,
    ),
    FormDesignColumnModel(
      command_text: "&item_total_amount&",
      text_align: PrintColumnAlign.right,
      header_names: [
        LanguageDataModel(code: "th", name: "รวม"),
        LanguageDataModel(code: "en", name: "Amount"),
      ],
      font_weight_bold: true,
      width: 2,
    ),
  ];
  List<FormDesignColumnModel> detailExtraColumn = [
    FormDesignColumnModel(command_text: " + &item_extra_name& &item_extra_qty& &item_extra_unit_name&", width: 5),
    FormDesignColumnModel(command_text: "&item_extra_price&", text_align: PrintColumnAlign.right, width: 1),
    FormDesignColumnModel(command_text: "&item_extra_total_amount&", text_align: PrintColumnAlign.right, width: 2),
  ];
  List<List<FormDesignColumnModel>> detailTotalColumn = [
    [
      // จำนวนชิ้น
      FormDesignColumnModel(command_text: "&total_piece_name&", width: 5),
      FormDesignColumnModel(command_text: "&total_piece&", text_align: PrintColumnAlign.right, width: 2),
    ],
    [
      // ยอดรวมสินค้ายกเว้นภาษี
      FormDesignColumnModel(command_text: "&total_itm_except_vat_amount_name&", width: 5),
      FormDesignColumnModel(command_text: "&total_itm_except_vat_amount&", text_align: PrintColumnAlign.right, width: 2),
    ],
    [
      // ยอดรวมสินค้ามีภาษี
      FormDesignColumnModel(command_text: "&total_item_vat_amount_name&", width: 5),
      FormDesignColumnModel(command_text: "&total_item_vat_amount&", text_align: PrintColumnAlign.right, width: 2),
    ],
    [
      // ยอดภาษี
      FormDesignColumnModel(command_text: "&total_vat_name&", width: 5),
      FormDesignColumnModel(command_text: "&total_vat&", text_align: PrintColumnAlign.right, width: 2),
    ],
    // ส่วนลด
    [FormDesignColumnModel(command_text: "&total_discount_name&", width: 5), FormDesignColumnModel(command_text: "&total_discount_amount&", text_align: PrintColumnAlign.right, width: 2)],
    [
      // ยอดรวมสุทธิ
      FormDesignColumnModel(command_text: "&total_amount_name&", width: 5, font_size: 32, font_weight_bold: true),
      FormDesignColumnModel(command_text: "&total_amount&", text_align: PrintColumnAlign.right, font_weight_bold: true, font_size: 32, width: 2),
    ],
  ];
  return FormDesignObjectBoxStruct(
    guid_fixed: "",
    code: global.formS01,
    form_code: global.getPosFormCodeByCode(global.formS01),
    sum_by_type: true,
    sum_by_barcode: true,
    print_logo: true,
    print_prompt_pay: true,
    names_json: global.getPosFormHeaderNameByCode(global.formS01),
    detail_json: jsonEncode(detailColumn),
    detail_total_json: jsonEncode(detailTotalColumn),
    detail_extra_json: jsonEncode(detailExtraColumn),
    detail_footer_json: "{}",
  );
}

void loadFormDesign() {
  global.formDesignList = [];
  {
    // ใบสรุปยอด/ไม่ใช่ใบเสร็จรับเงิน
    global.formDesignList.add(formSummaryStatement());
  }
  {
    List<FormDesignColumnModel> detailRows = [
      FormDesignColumnModel(
        command_text: "&item_qty& &item_name&/&item_unit_name& &item_price_and_symbol& &item_discount&",
        header_names: [
          LanguageDataModel(code: "th", name: "รายละเอียด"),
          LanguageDataModel(code: "en", name: "Description"),
        ],
        font_weight_bold: true,
        width: 5,
      ),
      FormDesignColumnModel(
        command_text: "&item_total_amount&",
        text_align: PrintColumnAlign.right,
        header_names: [
          LanguageDataModel(code: "th", name: "รวม"),
          LanguageDataModel(code: "en", name: "Amount"),
        ],
        font_weight_bold: true,
        width: 2,
      ),
    ];
    List<FormDesignColumnModel> detailExtraColumn = [
      FormDesignColumnModel(command_text: " + &item_extra_name& &item_extra_qty& &item_extra_unit_name&", width: 5),
      FormDesignColumnModel(command_text: "&item_extra_price&", text_align: PrintColumnAlign.right, width: 1),
      FormDesignColumnModel(command_text: "&item_extra_total_amount&", text_align: PrintColumnAlign.right, width: 2),
    ];
    List<FormDesignRowModel> detailTotalColumn = [
      FormDesignRowModel(
        columns: [
          // ยอดรวม
          FormDesignColumnModel(command_text: "&detail_total_amount_before_discount_name&", width: 5),
          FormDesignColumnModel(command_text: "&detail_total_amount_before_discount&", text_align: PrintColumnAlign.right, width: 2),
        ],
      ),
      FormDesignRowModel(
        // ยอดรวมอาหาร
        condition: [7],
        columns: [
          FormDesignColumnModel(command_text: "&detail_total_amount_food_name&", width: 5),
          FormDesignColumnModel(command_text: "&detail_total_amount_food_amount&", text_align: PrintColumnAlign.right, width: 2),
        ],
      ),
      FormDesignRowModel(
        // ยอดรวมเครื่องดื่ม/ขนม
        condition: [7],
        columns: [
          FormDesignColumnModel(command_text: "&detail_total_amount_drink_name&", width: 5),
          FormDesignColumnModel(command_text: "&detail_total_amount_drink_amount&", text_align: PrintColumnAlign.right, width: 2),
        ],
      ),
      FormDesignRowModel(
        condition: [1],
        columns: [
          // มูลค่าสินค้ามีภาษี
          FormDesignColumnModel(condition_join_is_vat_register: 1, command_text: "&total_item_vat_amount_name&", width: 5),
          FormDesignColumnModel(condition_join_is_vat_register: 1, command_text: "&total_item_vat_amount&", text_align: PrintColumnAlign.right, width: 2),
        ],
      ),
      FormDesignRowModel(
        condition: [1],
        columns: [
          // มูลค่าสินค้ายกเว้นภาษี
          FormDesignColumnModel(condition_join_is_vat_register: 1, command_text: "&total_itm_except_vat_amount_name&", width: 5),
          FormDesignColumnModel(condition_join_is_vat_register: 1, command_text: "&total_itm_except_vat_amount&", text_align: PrintColumnAlign.right, width: 2),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // ยอดส่วนลด Prtomotion
          FormDesignColumnModel(command_text: "&total_discount_from_promotion_name&", width: 5),
          FormDesignColumnModel(command_text: "&total_discount_from_promotion_amount&", text_align: PrintColumnAlign.right, font_weight_bold: false, width: 2),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // ใช้แตม
          FormDesignColumnModel(command_text: "&point_discount_amount_name&", width: 5),
          FormDesignColumnModel(command_text: "&point_discount_amount&", text_align: PrintColumnAlign.right, font_weight_bold: false, width: 2),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // ยอดส่วนลดก่อนชำระเงิน
          FormDesignColumnModel(command_text: "&detail_coupon_discount_name&", width: 5),
          FormDesignColumnModel(command_text: "&detail_coupon_discount_amount&", text_align: PrintColumnAlign.right, font_weight_bold: false, width: 2),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // ยอดส่วนลดก่อนชำระเงิน
          FormDesignColumnModel(command_text: "&detail_total_discount_name&", width: 5),
          FormDesignColumnModel(command_text: "&detail_total_discount_amount&", text_align: PrintColumnAlign.right, font_weight_bold: false, width: 2),
        ],
      ),
      FormDesignRowModel(
        condition: [1],
        columns: [
          // ยอดส่วนลดสินค้ามีภาษี
          FormDesignColumnModel(condition_join_is_vat_register: 1, command_text: "&total_discount_vat_name&", width: 5),
          FormDesignColumnModel(condition_join_is_vat_register: 1, command_text: "&total_discount_vat_amount&", text_align: PrintColumnAlign.right, width: 2),
        ],
      ),
      FormDesignRowModel(
        condition: [1],
        columns: [
          // ยอดส่วนลดสินค้ายกเว้นภาษี
          FormDesignColumnModel(condition_join_is_vat_register: 1, command_text: "&total_discount_vat_except_name&", width: 5),
          FormDesignColumnModel(condition_join_is_vat_register: 1, command_text: "&total_discount_vat_except_amount&", text_align: PrintColumnAlign.right, width: 2),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // มูลค่าก่อนภาษีมูลค่าเพิ่ม
          FormDesignColumnModel(condition_join_is_vat_register: 1, command_text: "&total_before_vat_name&", width: 5),
          FormDesignColumnModel(condition_join_is_vat_register: 1, command_text: "&total_before_vat&", text_align: PrintColumnAlign.right, width: 2),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // ยอดภาษี
          FormDesignColumnModel(condition_join_is_vat_register: 1, command_text: "&total_vat_name&", width: 5),
          FormDesignColumnModel(condition_join_is_vat_register: 1, command_text: "&total_vat&", text_align: PrintColumnAlign.right, width: 2),
        ],
      ),
      FormDesignRowModel(
        condition: [6],
        columns: [
          // มูลค่าหลังคิดภาษี ก่อนหักส่วนลด
          FormDesignColumnModel(condition_join_is_vat_register: 1, command_text: "&total_item_vat_amount_after_discount_name&", width: 5),
          FormDesignColumnModel(condition_join_is_vat_register: 1, command_text: "&total_item_vat_amount_after_discount&", text_align: PrintColumnAlign.right, width: 2),
        ],
      ),
      FormDesignRowModel(
        condition: [6],
        columns: [
          // มูลค่ายกเว้นภาษี ก่อนหักส่วนลด
          FormDesignColumnModel(condition_join_is_vat_register: 1, command_text: "&total_item_except_vat_amount_after_discount_name&", width: 5),
          FormDesignColumnModel(condition_join_is_vat_register: 1, command_text: "&total_item_except_vat_amount_after_discount&", text_align: PrintColumnAlign.right, width: 2),
        ],
      ),
      FormDesignRowModel(
        condition: [2],
        columns: [
          // ยอดรวมก่อนคิดเงิน -- ยอดรวมสุทธิ (ก่อนจ่ายเงิน)
          FormDesignColumnModel(command_text: "&detail_total_amount_name&", width: 5),
          FormDesignColumnModel(command_text: "&detail_total_amount&", text_align: PrintColumnAlign.right, width: 2),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // ยอดส่วนลดทั้งหมด (ท้ายบิล)
          FormDesignColumnModel(command_text: "&total_discount_name&", width: 5),
          FormDesignColumnModel(command_text: "&total_discount_amount&", text_align: PrintColumnAlign.right, width: 2),
        ],
      ),
      FormDesignRowModel(
        condition: [6],
        columns: [
          // ยอดรวมหลังหักส่วนลด (ท้ายบิล)
          FormDesignColumnModel(command_text: "&total_amount_after_discount_name&", width: 5),
          FormDesignColumnModel(command_text: "&total_amount_after_discount&", text_align: PrintColumnAlign.right, width: 2),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // ยอดปัดเศษ (ท้ายบิล)
          FormDesignColumnModel(command_text: "&round_amount_name&", width: 5),
          FormDesignColumnModel(command_text: "&round_amount&", text_align: PrintColumnAlign.right, width: 2),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // ยอดรวมสุทธิ
          FormDesignColumnModel(command_text: "&total_amount_name&", width: 5, font_size: 32, font_weight_bold: true),
          FormDesignColumnModel(command_text: "&total_amount&", text_align: PrintColumnAlign.right, font_weight_bold: true, font_size: 32, width: 2),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // ชำระด้วยบ Qr Code
          FormDesignColumnModel(command_text: "&total_pay_qr_name&", width: 5, font_size: 32, font_weight_bold: true),
          FormDesignColumnModel(command_text: "&total_pay_qr&", text_align: PrintColumnAlign.right, width: 2, font_size: 32, font_weight_bold: true),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // ชำระด้วยบ Qr Code
          FormDesignColumnModel(command_text: "&total_pay_qr_transaction&", width: 4, font_size: 17, font_weight_bold: false),
          FormDesignColumnModel(command_text: "&total_pay_qr_transaction_value&", text_align: PrintColumnAlign.right, width: 3, font_size: 17, font_weight_bold: false),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // ชำระด้วยบัตรเครดิต
          FormDesignColumnModel(command_text: "&total_pay_credit_card_name&", width: 5, font_size: 32, font_weight_bold: true),
          FormDesignColumnModel(command_text: "&total_pay_credit_card&", text_align: PrintColumnAlign.right, width: 2, font_size: 32, font_weight_bold: true),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // ชำระด้วยเงินโอน
          FormDesignColumnModel(command_text: "&total_pay_transfer_name&", width: 5, font_size: 32, font_weight_bold: true),
          FormDesignColumnModel(command_text: "&total_pay_transfer&", text_align: PrintColumnAlign.right, width: 2, font_size: 32, font_weight_bold: true),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // ชำระด้วยเช็ค
          FormDesignColumnModel(command_text: "&total_pay_cheque_name&", width: 5, font_size: 32, font_weight_bold: true),
          FormDesignColumnModel(command_text: "&total_pay_cheque&", text_align: PrintColumnAlign.right, width: 2, font_size: 32, font_weight_bold: true),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // ชำระด้วยคูปอง
          FormDesignColumnModel(command_text: "&total_pay_coupon_name&", width: 5, font_size: 32, font_weight_bold: true),
          FormDesignColumnModel(command_text: "&total_pay_coupon&", text_align: PrintColumnAlign.right, width: 2, font_size: 32, font_weight_bold: true),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // เงินเชื่อ
          FormDesignColumnModel(command_text: "&total_pay_credit_name&", width: 5, font_size: 32, font_weight_bold: true),
          FormDesignColumnModel(command_text: "&total_pay_credit&", text_align: PrintColumnAlign.right, width: 2, font_size: 32, font_weight_bold: true),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // ชำระเงินแต้ม
          FormDesignColumnModel(command_text: "&point_payment_name&", width: 5, font_size: 32, font_weight_bold: true),
          FormDesignColumnModel(command_text: "&point_payment&", text_align: PrintColumnAlign.right, width: 2, font_size: 32, font_weight_bold: true),
        ],
      ),

      FormDesignRowModel(
        columns: [
          // ชำระเงินสด
          FormDesignColumnModel(command_text: "&total_pay_cash_name&", width: 5, font_size: 32, font_weight_bold: true),
          FormDesignColumnModel(command_text: "&total_pay_cash&", text_align: PrintColumnAlign.right, width: 2, font_size: 32, font_weight_bold: true),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // เงินทอน
          FormDesignColumnModel(command_text: "&total_pay_cash_change_name&", width: 5, font_size: 32, font_weight_bold: true),
          FormDesignColumnModel(command_text: "&total_pay_cash_change&", text_align: PrintColumnAlign.right, width: 2, font_size: 32, font_weight_bold: true),
        ],
      ),
      FormDesignRowModel(
        columns: [
          // จำนวนชิ้น
          FormDesignColumnModel(command_text: "&total_piece_name&", width: 5),
          FormDesignColumnModel(command_text: "&total_piece&", text_align: PrintColumnAlign.right, width: 2),
        ],
      ),
      // FormDesignRowModel(
      //   columns: [
      //     // ได้รับแต้ม
      //     FormDesignColumnModel(command_text: "&earn_point_name&", width: 5, font_weight_bold: true),
      //     FormDesignColumnModel(command_text: "&earn_point&", text_align: PrintColumnAlign.right, width: 2, font_weight_bold: true),
      //   ],
      // ),
      FormDesignRowModel(
        columns: [
          // แต้มของลูกค้า
          FormDesignColumnModel(command_text: "&point_balance_after_name&", width: 5, font_weight_bold: true),
          FormDesignColumnModel(command_text: "&point_balance_after&", text_align: PrintColumnAlign.right, width: 2, font_weight_bold: true),
        ],
      ),
    ];

    // ใบเสร็จรับเงิน/ใบกำกับภาษีแบบย่อ
    global.formDesignList.add(
      FormDesignObjectBoxStruct(
        guid_fixed: "",
        code: global.formS02,
        form_code: global.getPosFormCodeByCode(global.formS02),
        sum_by_type: true,
        sum_by_barcode: true,
        print_logo: true,
        print_prompt_pay: true,
        names_json: global.getPosFormHeaderNameByCode(global.formS02),
        detail_json: jsonEncode(detailRows),
        detail_total_json: jsonEncode(detailTotalColumn),
        detail_extra_json: jsonEncode(detailExtraColumn),
        detail_footer_json: "{}",
      ),
    );

    // ใบเสร็จรับเงิน/ใบกำกับภาษีแบบเต็ม
    global.formDesignList.add(
      FormDesignObjectBoxStruct(
        guid_fixed: "",
        code: global.formS03,
        form_code: global.getPosFormCodeByCode(global.formS03),
        sum_by_type: true,
        sum_by_barcode: true,
        print_logo: true,
        print_prompt_pay: true,
        names_json: global.getPosFormHeaderNameByCode(global.formS03),
        detail_json: jsonEncode(detailRows),
        detail_total_json: jsonEncode(detailTotalColumn),
        detail_extra_json: jsonEncode(detailExtraColumn),
        detail_footer_json: "{}",
      ),
    );

    // ใบเสร็จรับเงิน (ไม่ได้จดทะเบียนเป็นผู้เสียภาษีมูลค่าเพิ่ม)
    global.formDesignList.add(
      FormDesignObjectBoxStruct(
        guid_fixed: "",
        code: global.formS04,
        form_code: global.getPosFormCodeByCode(global.formS04),
        sum_by_type: true,
        sum_by_barcode: true,
        print_logo: true,
        print_prompt_pay: true,
        names_json: global.getPosFormHeaderNameByCode(global.formS04),
        detail_json: jsonEncode(detailRows),
        detail_total_json: jsonEncode(detailTotalColumn),
        detail_extra_json: jsonEncode(detailExtraColumn),
        detail_footer_json: "{}",
      ),
    );
  }
}
