// product_type_dropdown.dart
import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/global.dart' as global;

class ProductTypeDropdown extends StatelessWidget {
  final int value;
  final bool isEditMode;
  final Function(int?) onChanged;

  const ProductTypeDropdown({
    super.key,
    required this.value,
    required this.isEditMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> productTypes = [
      {"value": 0, "label": "product_is_stock", "color": Colors.blue},
      {"value": 1, "label": "product_is_service", "color": Colors.red},
      {"value": 2, "label": "product_is_set", "color": Colors.yellow},
      {"value": 3, "label": "product_is_material", "color": Colors.red},
      {"value": 4, "label": "product_semi_finished", "color": Colors.red},
      {"value": 5, "label": "product_is_not_stock", "color": Colors.red},
    ];

    return DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
      items: productTypes.map((type) {
        return DropdownMenuItem<int>(
          value: type["value"],
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: type["color"],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  global.language(type["label"]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: isEditMode ? onChanged : null,
    );
  }
}
