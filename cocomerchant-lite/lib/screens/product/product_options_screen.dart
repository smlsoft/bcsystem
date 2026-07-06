import 'package:cocomerchant_lite/constants.dart';
import 'package:flutter/material.dart';
import 'package:cocomerchant_lite/model/product_model.dart';
import 'package:cocomerchant_lite/global.dart' as global;
import 'package:cocomerchant_lite/screens/product/option_edit_screen.dart';

class ProductOptionsScreen extends StatefulWidget {
  final List<ProductOptionModel> options;
  final Function(List<ProductOptionModel>) onOptionsUpdated;

  const ProductOptionsScreen({
    Key? key,
    required this.options,
    required this.onOptionsUpdated,
  }) : super(key: key);

  @override
  _ProductOptionsScreenState createState() => _ProductOptionsScreenState();
}

class _ProductOptionsScreenState extends State<ProductOptionsScreen> {
  late List<ProductOptionModel> _options;

  @override
  void initState() {
    super.initState();
    _options = List.from(widget.options);
  }

  void _addNewOption() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OptionEditScreen(
          onOptionUpdated: (newOption) {
            setState(() {
              _options.add(newOption);
            });
          },
          isEditMode: false,
        ),
      ),
    );
  }

  void _editOption(ProductOptionModel option) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OptionEditScreen(
          option: option,
          onOptionUpdated: (updatedOption) {
            setState(() {
              int index = _options.indexWhere((o) => o.guid == updatedOption.guid);
              if (index != -1) {
                _options[index] = updatedOption;
              }
            });
          },
          isEditMode: true,
        ),
      ),
    );
  }

  void _removeOption(String guid) {
    setState(() {
      _options.removeWhere((option) => option.guid == guid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            widget.onOptionsUpdated(_options);
            Navigator.pop(context);
          },
        ),
        backgroundColor: kPrimaryColor,
        title: Text(
          global.language('product_options'),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _options.isNotEmpty
                ? ListView.builder(
                    itemCount: _options.length,
                    itemBuilder: (context, index) {
                      return _buildOptionItem(_options[index]);
                    },
                  )
                : Center(
                    child: Text(global.language('no_option')),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addNewOption,
                icon: Icon(Icons.add),
                label: Text(global.language('add_option')),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: kPrimaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionItem(ProductOptionModel option) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(
          option.names.isNotEmpty ? option.names.first.name : global.language('unnamed_option'),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${option.choices.length} ${global.language('choices')}'),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeOption(option.guid),
        ),
        onTap: () => _editOption(option),
      ),
    );
  }
}
