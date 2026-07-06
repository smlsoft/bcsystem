import 'package:flutter/material.dart';
import 'package:smlaicloud/model/transaction_model.dart';
import 'package:smlaicloud/global.dart' as global;

class DocumentPreviewWidget extends StatelessWidget {
  final TransactionModel screenData;
  final global.TransactionTypeEnum transactionType;
  final bool docDateTimeValidated;
  final String fieldNameCustCode;
  final String fieldNamecustnames;

  const DocumentPreviewWidget({
    super.key,
    required this.screenData,
    required this.transactionType,
    required this.docDateTimeValidated,
    required this.fieldNameCustCode,
    required this.fieldNamecustnames,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: _buildPreviewContent());
  }

  List<Widget> _buildPreviewContent() {
    List<Widget> previewResult = [];
    List<Widget> fittedBox = [];
    List<Widget> detailsBody = [];

    TextStyle dataTextStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black);

    // Header information
    fittedBox.add(
      Row(
        children: [
          Expanded(
            child: Text(
              (docDateTimeValidated)
                  ? "${global.language("doc_date")} ${global.dateTimeBuddhist(DateTime.parse(screenData.docdatetime), format: global.DateTimeFormatEnum.dateDay)} ${global.dateTimeBuddhist(DateTime.parse(screenData.docdatetime), format: global.DateTimeFormatEnum.time)}"
                  : global.language("invalid_date"),
              style: dataTextStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Expanded(
            child: (screenData.guidfixed!.isNotEmpty)
                ? Text(
                    "${global.language("doc_number")} ${screenData.docno}",
                    style: dataTextStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );

    // Customer/Supplier information
    if (transactionType != global.TransactionTypeEnum.stocktransfer) {
      fittedBox.add(Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(global.language(fieldNameCustCode)),
                const SizedBox(width: 10),
                Text(screenData.custcode, style: dataTextStyle),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(global.language(fieldNamecustnames)),
                const SizedBox(width: 10),
                Text(global.activeLangName(screenData.custnames!), style: dataTextStyle),
              ],
            ),
          ),
        ],
      ));
    }

    // Sale information
    fittedBox.add(
      Row(
        children: [
          Expanded(
              child: Row(
            children: [
              Text(global.language('sale_code')),
              const SizedBox(width: 10),
              Text(screenData.salecode, style: dataTextStyle),
            ],
          )),
          Expanded(
              child: Row(
            children: [
              Text(global.language('sale_name')),
              const SizedBox(width: 10),
              Text(screenData.salename, style: dataTextStyle),
            ],
          )),
        ],
      ),
    );

    // VAT and Inquiry type information (for specific transaction types)
    if (_shouldShowVatAndInquiryType()) {
      fittedBox.add(Row(
        children: [
          Expanded(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: "${global.language("vat_type")} ",
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  TextSpan(
                    text: global.getVatName(screenData.vattype),
                    style: dataTextStyle,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    text: "${global.language("inquiry_type")} ",
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  TextSpan(
                    text: global.getInquiryName(screenData.inquirytype),
                    style: dataTextStyle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ));
    }

    // Reference document information
    fittedBox.add(
      Row(
        children: [
          Expanded(
            child: Text(
              "${global.language('doc_ref')} ${screenData.docrefno}",
              style: dataTextStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Expanded(
            child: (screenData.taxdocno != "")
                ? Text(
                    "${global.language('doc_ref_date')} ${global.dateTimeBuddhist(DateTime.parse(screenData.docrefdate), format: global.DateTimeFormatEnum.dateDay)}",
                    style: dataTextStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : const Text(''),
          ),
        ],
      ),
    );

    // Tax document information (for specific transaction types)
    if (_shouldShowTaxDocument()) {
      fittedBox.add(Row(
        children: [
          Expanded(
              child: Text(
            "${global.language('tax_docno')} ${screenData.taxdocno}",
            style: dataTextStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          )),
          Expanded(
            child: (screenData.taxdocno != "")
                ? Text("${global.language('tax_doc_date')} ${global.dateTimeBuddhist(DateTime.parse(screenData.taxdocdate), format: global.DateTimeFormatEnum.dateDay)}",
                    style: dataTextStyle, maxLines: 1, overflow: TextOverflow.ellipsis)
                : const Text(''),
          ),
        ],
      ));
    }

    fittedBox.add(const SizedBox(height: 10));

    previewResult.add(
      Container(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Column(
            children: fittedBox,
          ),
        ),
      ),
    );

    // Product list header
    previewResult.add(Row(
      children: [
        Expanded(
            child: Row(
          children: [
            Text(
              '${global.language("product_list")} ${screenData.details!.length} ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        )),
      ],
    ));

    // Product details table
    _buildProductTable(detailsBody);

    previewResult.add(Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: detailsBody,
        ),
      ),
    ));

    // Financial summary (for specific transaction types)
    if (_shouldShowFinancialSummary()) {
      _buildFinancialSummary(previewResult);
    }

    return previewResult;
  }

  void _buildProductTable(List<Widget> detailsBody) {
    if (_shouldShowPriceColumns()) {
      detailsBody.add(Table(
        columnWidths: const {
          0: FractionColumnWidth(0.08),
          1: FractionColumnWidth(0.40),
          2: FractionColumnWidth(0.15),
          3: FractionColumnWidth(0.15),
          4: FractionColumnWidth(0.2),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Colors.white),
            children: [
              const Center(child: Text('#')),
              Center(child: Text(global.language("product"))),
              Center(child: Text(global.language("product_qty"))),
              Center(child: Text(global.language("price"))),
              Center(child: Text(global.language("total_value"))),
            ],
          ),
          ...screenData.details!.expand((item) {
            return [
              TableRow(
                children: [
                  Center(
                    child: Text((screenData.details!.indexOf(item) + 1).toString()),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(global.activeLangName(item.itemnames!)),
                      if (item.description!.isNotEmpty) Text('หมายเหตุ : ${item.description!}'),
                    ],
                  ),
                  Align(alignment: Alignment.centerRight, child: Text(global.formatNumber(item.qty).toString())),
                  Align(alignment: Alignment.centerRight, child: Text(global.formatNumber(item.price).toString())),
                  Align(alignment: Alignment.centerRight, child: Text(global.formatNumber(item.sumamount).toString())),
                ],
              ),
              ...item.extrajsonlist!.map((extra) {
                return TableRow(
                  children: [
                    const SizedBox(),
                    Text("- ${global.activeLangName(extra.itemnames!)}"),
                    Align(alignment: Alignment.centerRight, child: Text(global.formatNumber((extra.qty! != 0.0) ? extra.qty! : 1.0).toString())),
                    Align(alignment: Alignment.centerRight, child: Text(global.formatNumber(extra.price!).toString())),
                  ],
                );
              }).toList(),
            ];
          }).toList(),
        ],
      ));
    } else {
      detailsBody.add(Table(
        columnWidths: const {
          0: FractionColumnWidth(0.08),
          1: FractionColumnWidth(0.52),
          2: FractionColumnWidth(0.4),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Colors.white),
            children: [
              const Center(child: Text('#')),
              Center(child: Text(global.language("product"))),
              Center(child: Text(global.language("product_qty"))),
            ],
          ),
          ...screenData.details!.map((item) {
            return TableRow(
              children: [
                Center(
                  child: Text((screenData.details!.indexOf(item) + 1).toString()),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(global.activeLangName(item.itemnames!)),
                    if (item.description!.isNotEmpty) Text('หมายเหตุ : ${item.description!}'),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(item.qty.toString()),
                ),
              ],
            );
          }).toList(),
        ],
      ));
    }
  }

  void _buildFinancialSummary(List<Widget> previewResult) {
    // Total value
    previewResult.add(Row(
      children: [
        Expanded(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              global.language('total_value'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              global.formatNumber(screenData.totalvalue),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        )),
      ],
    ));

    // Detail total discount
    if (screenData.detailtotaldiscount != 0) {
      previewResult.add(
        Row(
          children: [
            Expanded(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${global.language('detail_total_discount')} + ${screenData.detaildiscountformula}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  screenData.detailtotaldiscount.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            )),
          ],
        ),
      );
    }

    // VAT discount amount
    if (screenData.totaldiscountvatamount != 0) {
      previewResult.add(
        Row(
          children: [
            Expanded(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  global.language('total_discount_vat_amount'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  screenData.totaldiscountvatamount.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            )),
          ],
        ),
      );
    }

    // Except VAT discount amount
    if (screenData.totaldiscountexceptvatamount != 0) {
      previewResult.add(
        Row(
          children: [
            Expanded(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  global.language('total_discount_except_vat_amount'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  global.formatNumber(screenData.totaldiscountexceptvatamount!),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            )),
          ],
        ),
      );
    }

    // Total before VAT
    if (screenData.totalbeforevat != 0) {
      previewResult.add(Row(
        children: [
          Expanded(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                global.language('total_before_vat'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                global.formatNumber(screenData.totalbeforevat),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          )),
        ],
      ));
    }

    // VAT amount
    if (screenData.totalvatvalue != 0) {
      previewResult.add(Row(
        children: [
          Expanded(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${global.language('doc_vat_amount')} : ${screenData.vatrate}%",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                global.formatNumber(screenData.totalvatvalue),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          )),
        ],
      ));
    }

    // Total after VAT
    if (screenData.totalaftervat != 0) {
      previewResult.add(Row(
        children: [
          Expanded(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                global.language('total_after_vat'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                global.formatNumber(screenData.totalaftervat),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          )),
        ],
      ));
    }

    // Total except VAT
    if (screenData.totalexceptvat != 0) {
      previewResult.add(Row(
        children: [
          Expanded(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                global.language('total_except_vat'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                global.formatNumber(screenData.totalexceptvat),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          )),
        ],
      ));
    }

    // Bill discount
    if (screenData.totaldiscount != 0) {
      previewResult.add(Row(
        children: [
          Expanded(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                global.language('discount_bill'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                global.formatNumber(screenData.totaldiscount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          )),
        ],
      ));
    }

    // Total amount after discount
    if (screenData.totalamountafterdiscount != 0) {
      previewResult.add(Row(
        children: [
          Expanded(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                global.language('total_amount_after_discount'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                global.formatNumber(screenData.totalamountafterdiscount!),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          )),
        ],
      ));
    }

    // Round amount
    if (screenData.roundamount != 0) {
      previewResult.add(Row(
        children: [
          Expanded(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                global.language('round_amount'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                global.formatNumber(screenData.roundamount!),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          )),
        ],
      ));
    }

    // Final total
    previewResult.add(Row(
      children: [
        Expanded(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              global.language('sum_pay'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            Text(
              global.formatNumber(screenData.totalamount + (screenData.roundamount ?? 0)),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        )),
      ],
    ));
  }

  bool _shouldShowVatAndInquiryType() {
    return !(transactionType == global.TransactionTypeEnum.stocktransfer ||
        transactionType == global.TransactionTypeEnum.stockreceiveproduct ||
        transactionType == global.TransactionTypeEnum.stockpickupproduct ||
        transactionType == global.TransactionTypeEnum.stockreturnproduct ||
        transactionType == global.TransactionTypeEnum.adjust);
  }

  bool _shouldShowTaxDocument() {
    return !(transactionType == global.TransactionTypeEnum.stocktransfer ||
        transactionType == global.TransactionTypeEnum.stockreceiveproduct ||
        transactionType == global.TransactionTypeEnum.stockpickupproduct ||
        transactionType == global.TransactionTypeEnum.stockreturnproduct ||
        transactionType == global.TransactionTypeEnum.adjust);
  }

  bool _shouldShowPriceColumns() {
    return !(transactionType == global.TransactionTypeEnum.stocktransfer ||
        transactionType == global.TransactionTypeEnum.stockpickupproduct ||
        transactionType == global.TransactionTypeEnum.stockreturnproduct ||
        transactionType == global.TransactionTypeEnum.adjust ||
        transactionType == global.TransactionTypeEnum.saleorder ||
        transactionType == global.TransactionTypeEnum.quotation ||
        transactionType == global.TransactionTypeEnum.purchaseorder);
  }

  bool _shouldShowFinancialSummary() {
    return !(transactionType == global.TransactionTypeEnum.stocktransfer ||
        transactionType == global.TransactionTypeEnum.stockpickupproduct ||
        transactionType == global.TransactionTypeEnum.stockreturnproduct ||
        transactionType == global.TransactionTypeEnum.adjust);
  }
}
