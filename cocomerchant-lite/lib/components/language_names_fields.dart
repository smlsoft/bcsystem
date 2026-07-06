import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/model/global_model.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/constants.dart';

class LanguageNamesFields extends StatefulWidget {
  final List<LanguageDataModel> names;
  final List<LanguageModel> languageList;
  final String fieldName;
  final bool isEditMode;
  final bool isLoadTranslation;
  final List<TextEditingController> controllers;
  final Function(String, String) onChanged;

  const LanguageNamesFields({
    Key? key,
    required this.names,
    required this.languageList,
    required this.fieldName,
    required this.isEditMode,
    required this.isLoadTranslation,
    required this.controllers,
    required this.onChanged,
  }) : super(key: key);

  @override
  LanguageNamesFieldsState createState() => LanguageNamesFieldsState();
}

class LanguageNamesFieldsState extends State<LanguageNamesFields> {
  bool showAllLanguages = false;
  bool _wasLoading = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.controllers.length; i++) {
      widget.controllers[i].addListener(() {
        _handleTextChange(i);
      });
    }
  }

  void _handleTextChange(int index) {
    final newValue = widget.controllers[index].text;
    widget.onChanged(widget.names[index].code, newValue);
    widget.names[index].name = newValue;
  }

  @override
  void didUpdateWidget(LanguageNamesFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_wasLoading && !widget.isLoadTranslation) {
      _showTranslationSuccessNotification();
    }
    _wasLoading = widget.isLoadTranslation;
  }

  void _showTranslationSuccessNotification() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(global.language('translation_success')),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              global.language(widget.fieldName),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Container(
              height: 50,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: showAllLanguages ? kPrimaryColor.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: showAllLanguages ? kPrimaryColor : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  showAllLanguages ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: showAllLanguages ? kPrimaryColor : Colors.grey[600],
                ),
                onPressed: () {
                  setState(() {
                    showAllLanguages = !showAllLanguages;
                  });
                },
                tooltip: showAllLanguages ? global.language('hide_all_languages') : global.language('show_all_languages'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(
          widget.languageList.length,
          (index) {
            if (index == 0 || showAllLanguages) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: (index == (widget.languageList.length - 1))
                      ? 0
                      : (showAllLanguages)
                          ? 10
                          : 0,
                ),
                child: TextFormField(
                  readOnly: !widget.isEditMode,
                  controller: widget.controllers[index],
                  decoration: InputDecoration(
                    labelText: "${global.language(widget.fieldName)} (${widget.languageList[index].name})",
                    prefixIcon: const Icon(Icons.language, color: kSecondaryColor),
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
                    suffixIcon: widget.isLoadTranslation && index > 0
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : null,
                  ),
                  validator: (value) {
                    if (index == 0 && (value == null || value.isEmpty)) {
                      return '${global.language('please_enter')} ${global.language(widget.fieldName)}';
                    }
                    return null;
                  },
                ),
              );
            }
            return SizedBox.shrink();
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    for (var controller in widget.controllers) {
      controller.removeListener(() {});
    }
    super.dispose();
  }
}
