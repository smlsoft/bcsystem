import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/constants.dart';
import 'package:cocomerchant_lite/global.dart' as global;

class SelectTypeBottomSheet extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> types;
  final int selectedType;
  final Function(int) onSelect;

  const SelectTypeBottomSheet({
    Key? key,
    required this.title,
    required this.types,
    required this.selectedType,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: types.length,
              itemBuilder: (BuildContext context, int index) {
                final type = types[index];
                final isSelected = selectedType == type['value'];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: isSelected ? kPrimaryLightColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? kPrimaryColor : Colors.grey[300]!,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: kPrimaryColor.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Icon(
                        type['icon'] ?? Icons.circle,
                        color: isSelected ? kPrimaryColor : Colors.grey,
                        size: 28,
                      ),
                      title: Text(
                        global.language(type['label']),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? kPrimaryColor : kTextColor,
                        ),
                      ),
                      subtitle: type['description'] != null
                          ? Text(
                              global.language(type['description']),
                              style: TextStyle(
                                color: isSelected ? kPrimaryColor.withOpacity(0.7) : Colors.grey[600],
                              ),
                            )
                          : null,
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: kPrimaryColor,
                              size: 28,
                            )
                          : null,
                      onTap: () {
                        onSelect(type['value']);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Extension method to show the bottom sheet
extension SelectTypeBottomSheetExtension on BuildContext {
  Future<void> showSelectTypeBottomSheet({
    required String title,
    required List<Map<String, dynamic>> types,
    required int selectedType,
    required Function(int) onSelect,
  }) {
    return showModalBottomSheet(
      context: this,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SelectTypeBottomSheet(
          title: title,
          types: types,
          selectedType: selectedType,
          onSelect: onSelect,
        );
      },
    );
  }
}
