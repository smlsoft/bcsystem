import 'package:dedeorder/bloc/process_bloc.dart';
import 'package:dedeorder/model/pos_process_model.dart';
import 'package:dedeorder/model/table_model.dart';
import 'package:dedeorder/table/table_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slider_captcha/slider_captcha.dart';
import 'package:dedeorder/global.dart' as global;
import 'package:dedeorder/utility/api.dart' as api;
import 'package:dedeorder/utility/printer.dart' as printer;

class TableManagerInfoPage extends StatefulWidget {
  final TableProcessObjectBoxStruct tableData;

  const TableManagerInfoPage({super.key, required this.tableData});

  @override
  _TableManagerInfoPageState createState() => _TableManagerInfoPageState();
}

class _TableManagerInfoPageState extends State<TableManagerInfoPage> {
  SliderController sliderController = SliderController();
  PosProcessModel? processResult;
  bool isProcess = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        context.read<ProcessBloc>().add(ProcessGetData(holdId: "T-${widget.tableData.number}", discountWord: "", isCash: false));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProcessBloc, ProcessState>(
        listener: (context, state) {
          if (state is ProcessGetDataSuccess) {
            context.read<ProcessBloc>().add(ProcessGetDataFinish());
            processResult = state.result;
            isProcess = false;
            setState(() {});
          }
        },
        child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.deepPurple.shade900,
              title: Text((widget.tableData.is_delivery == false) ? "สถานะโต๊ะ ${widget.tableData.number}" : "สถานะ Order ${global.getDeliveryName(code: widget.tableData.delivery_code)} : ${widget.tableData.delivery_number}"),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: () {
                    printer.printTableSummery(table: widget.tableData, processResult: processResult!);
                  },
                ),
              ],
            ),
            body: (isProcess) ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(child: (processResult == null) ? Container() : tableProcessWidget(processResult!))));
  }
}
