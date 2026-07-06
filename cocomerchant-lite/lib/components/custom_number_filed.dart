import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/constants.dart';

class CustomNumberField extends StatefulWidget {
  final bool readOnly;
  final TextEditingController controller;
  final String labelText;
  final IconData? prefixIcon;
  final int index;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final void Function(String)? onChanged;

  const CustomNumberField({
    Key? key,
    required this.readOnly,
    required this.controller,
    required this.labelText,
    this.prefixIcon,
    required this.index,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  }) : super(key: key);

  @override
  _CustomNumberFieldState createState() => _CustomNumberFieldState();
}

class _CustomNumberFieldState extends State<CustomNumberField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: widget.controller.text);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.onChanged != null) {
      widget.onChanged!(_controller.text);
    }
    widget.controller.text = _controller.text;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        focusNode: _focusNode,
        textAlign: TextAlign.right,
        readOnly: widget.readOnly,
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.labelText,
          prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, color: kSecondaryColor) : null,
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
        validator: widget.validator,
        keyboardType: widget.keyboardType,
      ),
    );
  }
}
