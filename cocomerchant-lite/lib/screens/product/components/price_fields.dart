import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/model/price_model.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/constants.dart';

class PriceFields extends StatefulWidget {
  final List<PriceDataModel> prices;
  final List<PriceModel> priceList;
  final bool isEditMode;
  final Function(int, double) onChanged;
  final Function(int) onSubmitted;

  const PriceFields({
    super.key,
    required this.prices,
    required this.priceList,
    required this.isEditMode,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  _PriceFieldsState createState() => _PriceFieldsState();
}

class _PriceFieldsState extends State<PriceFields> {
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;
  bool showAllPrices = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    controllers = List.generate(
      widget.priceList.length,
      (index) {
        var price = index < widget.prices.length ? widget.prices[index].price : 0.0;
        return TextEditingController(
          text: price == 0.0 ? "" : global.formatNumber(price),
        );
      },
    );
    focusNodes = List.generate(widget.priceList.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(PriceFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.prices != oldWidget.prices || widget.priceList != oldWidget.priceList) {
      _initializeControllers();
    }
  }

  Widget buildPriceField(int index) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: showAllPrices && index != (widget.priceList.length - 1) ? 15 : 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              readOnly: !widget.isEditMode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [global.NumberInputFormatter()],
              onChanged: (value) {
                if (value.isNotEmpty) {
                  widget.onChanged(index, double.parse(value.replaceAll(',', '')));
                } else {
                  widget.onChanged(index, 0);
                }
              },
              onFieldSubmitted: (value) {
                widget.onSubmitted(index);
              },
              focusNode: focusNodes[index],
              textAlign: TextAlign.right,
              controller: controllers[index],
              decoration: InputDecoration(
                labelText: "${global.language("price")} (${widget.priceList[index].names[0].name})",
                prefixIcon: const Icon(Icons.attach_money, color: kSecondaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              validator: (value) {
                if (index == 0 && (value == null || value.isEmpty)) {
                  return global.language('please_enter_price');
                }
                return null;
              },
            ),
          ),
          if (index == 0)
            Container(
              height: 57,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: showAllPrices ? kPrimaryColor.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: showAllPrices ? kPrimaryColor : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  showAllPrices ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: showAllPrices ? kPrimaryColor : Colors.grey[600],
                ),
                onPressed: () {
                  setState(() {
                    showAllPrices = !showAllPrices;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildPriceField(0),
        if (showAllPrices) ...List.generate(widget.priceList.length - 1, (index) => buildPriceField(index + 1)),
      ],
    );
  }
}
