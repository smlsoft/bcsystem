import 'package:flutter/material.dart';

class TextFieldSearch extends StatelessWidget {
  final void Function(String)? onChange;
  const TextFieldSearch({
    Key? key,
    required this.onChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 5,
      ),
      child: TextField(
        onChanged: onChange,
        decoration: const InputDecoration(
          icon: Icon(
            Icons.search,
            color: Color(0xff046AF3),
          ),
          hintText: 'ค้นหา',
          border: InputBorder.none,
        ),
      ),
    );
  }
}
