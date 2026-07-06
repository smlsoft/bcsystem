import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smlaicloud/imports_bloc.dart';
import 'package:smlaicloud/model/bi_report/bi_report_models.dart';
import 'package:smlaicloud/repositories/creditor_repository.dart';
import 'package:smlaicloud/repositories/employee_repository.dart';
import 'package:smlaicloud/model/bi_report/branch_selection_model.dart';
import 'package:smlaicloud/model/bi_report/entity_selection_model.dart';
import 'package:smlaicloud/screen_search/dedebi/multi_branch_search_screen.dart';
import 'package:smlaicloud/screen_search/dedebi/multi_entity_search_screen.dart';
import 'package:smlaicloud/utils/date_picker.dart';

class ReportConditions {
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool? showDetails;
  final String? showCancelled;
  final String? saleType;
  final String? posType;
  final BranchSelectionModel? selectedBranches;
  final EntitySelectionModel? selectedCreditors;
  final EntitySelectionModel? selectedSalespersons;
  final EntitySelectionModel? selectedBarcodes;

  const ReportConditions({
    this.fromDate,
    this.toDate,
    this.showDetails,
    this.showCancelled,
    this.saleType,
    this.posType,
    this.selectedBranches,
    this.selectedCreditors,
    this.selectedSalespersons,
    this.selectedBarcodes,
  });
}

class ReportConditionDialog extends StatefulWidget {
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final bool? initialShowDetails;
  final String? initialShowCancelled;
  final String? initialSaleType;
  final String? initialPosType;
  final BranchSelectionModel? initialSelectedBranches;
  final EntitySelectionModel? initialSelectedCreditors;
  final EntitySelectionModel? initialSelectedSalespersons;
  final EntitySelectionModel? initialSelectedBarcodes;
  final Function(ReportConditions) onConditionsSet;
  final BiReportType reportType;

  const ReportConditionDialog({
    super.key,
    this.initialFromDate,
    this.initialToDate,
    this.initialShowDetails = true,
    this.initialShowCancelled = 'ทั้งหมด',
    this.initialSaleType = 'ทั้งหมด',
    this.initialPosType = 'ทั้งหมด',
    this.initialSelectedBranches = const BranchSelectionModel(selectedBranches: [], isCancel: false),
    this.initialSelectedCreditors = const EntitySelectionModel(selectedEntities: [], isCancel: false),
    this.initialSelectedSalespersons = const EntitySelectionModel(selectedEntities: [], isCancel: false),
    this.initialSelectedBarcodes = const EntitySelectionModel(selectedEntities: [], isCancel: false),
    required this.onConditionsSet,
    required this.reportType,
  });

  @override
  State<ReportConditionDialog> createState() => _ReportConditionDialogState();
}

class _ReportConditionDialogState extends State<ReportConditionDialog> {
  late DateTime? _fromDate;
  late DateTime? _toDate;
  late bool _showDetails;
  late String _showCancelled;
  late String _saleType;
  late String _posType;
  late BranchSelectionModel _selectedBranches;
  late EntitySelectionModel _selectedCreditors;
  late EntitySelectionModel _selectedSalespersons;
  late EntitySelectionModel _selectedBarcodes;

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _showDetails = widget.initialShowDetails!;
    _showCancelled = widget.initialShowCancelled!;
    _saleType = widget.initialSaleType!;
    _posType = widget.initialPosType!;
    _selectedBranches = widget.initialSelectedBranches!;
    _selectedCreditors = widget.initialSelectedCreditors!;
    _selectedSalespersons = widget.initialSelectedSalespersons!;
    _selectedBarcodes = widget.initialSelectedBarcodes!;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width > 800 ? MediaQuery.of(context).size.width * 0.5 : MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85, // กำหนดความสูงให้เป็น 85% ของหน้าจอ
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (ไม่ scroll)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  const Divider(),
                ],
              ),
            ),
            // Content ที่สามารถ scroll ได้
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateRangeSection(),
                    if (widget.reportType == BiReportType.paymentDaily || widget.reportType == BiReportType.saleReturn) ...[
                      const SizedBox(height: 16),
                      _buildBranchSelectionSection(),
                      const SizedBox(height: 16),
                    ] else if (widget.reportType == BiReportType.stockMovement || widget.reportType == BiReportType.stockBalance) ...[
                      const SizedBox(height: 16),
                      _buildBarcodeSection(),
                      const SizedBox(height: 16),
                    ] else if (widget.reportType != BiReportType.stockMovement && widget.reportType != BiReportType.stockBalance) ...[
                      const SizedBox(height: 16),
                      _buildBranchSelectionSection(),
                      const SizedBox(height: 16),
                      if (widget.reportType == BiReportType.sale) ...[
                        _buildCreditorAndSalespersonSection(),
                        const SizedBox(height: 16),
                      ],
                      _buildFilterOptionsSection(),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
            // Footer (ปุ่มแอ็คชัน - ไม่ scroll)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.tune,
            color: Colors.indigo.shade700,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.reportType.displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const Text(
                'กรุณาระบุช่วงวันที่และตัวเลือกการแสดงผล',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: 'ปิด',
        ),
      ],
    );
  }

  Widget _buildDateRangeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range, color: Colors.indigo.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                (widget.reportType == BiReportType.stockBalance) ? 'ณ วันที่' : 'ช่วงวันที่รายงาน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.reportType != BiReportType.stockBalance) ...[
                Expanded(
                  child: CustomDatePicker(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: const Icon(Icons.calendar_today),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    initialDate: _fromDate,
                    useBuddhistCalendar: true,
                    onDateSelected: (date) {
                      setState(() {
                        _fromDate = date;
                      });
                    },
                    labelText: 'เลือกวันที่เริ่มต้น',
                  ),
                ),
              ],
              const SizedBox(width: 16),
              Expanded(
                child: CustomDatePicker(
                  decoration: InputDecoration(
                    labelText: (widget.reportType == BiReportType.stockBalance) ? 'ณ วันที่' : 'เลือกวันที่สิ้นสุด',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  initialDate: _toDate,
                  useBuddhistCalendar: true,
                  onDateSelected: (date) {
                    setState(() {
                      _toDate = date;
                    });
                  },
                  labelText: (widget.reportType == BiReportType.stockBalance) ? 'ณ วันที่' : 'เลือกวันที่สิ้นสุด',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // _buildBarcodeSection
  Widget _buildBarcodeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code, color: Colors.purple.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                'เลือกบาร์โค้ด',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final result = await Navigator.push<EntitySelectionModel?>(
                context,
                MaterialPageRoute(
                  builder: (context) => MultiEntitySearchScreen(
                    word: '',
                    entityType: EntityType.barcode,
                    preSelectedEntities: _selectedBarcodes.selectedEntities,
                  ),
                ),
              );

              if (result != null && !result.isCancel) {
                setState(() {
                  _selectedBarcodes = result;
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedBarcodes.selectedEntities.isEmpty
                          ? 'กดเพื่อเลือกบาร์โค้ด'
                          : '${_selectedBarcodes.selectedEntities.first.code} : ${_selectedBarcodes.selectedEntities.first.getDisplayName()}',
                      style: TextStyle(
                        color: _selectedBarcodes.selectedEntities.isEmpty ? Colors.grey.shade600 : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.purple.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (_selectedBarcodes.selectedEntities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.purple.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _selectedBarcodes.selectedEntities.isEmpty
                      ? 'ยังไม่ได้เลือกบาร์โค้ด'
                      : 'เลือกแล้ว: ${_selectedBarcodes.selectedEntities.first.code} : ${_selectedBarcodes.selectedEntities.first.getDisplayName()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.purple.shade700,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedBarcodes = const EntitySelectionModel(
                        selectedEntities: [],
                        isCancel: false,
                      );
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ลบทั้งหมด',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBranchSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.business,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'เลือกสาขา',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final result = await Navigator.push<BranchSelectionModel?>(
                context,
                MaterialPageRoute(
                  builder: (context) => MultiBranchSearchScreen(
                    word: '',
                    preSelectedBranches: _selectedBranches.selectedBranches,
                  ),
                ),
              );

              if (result != null && !result.isCancel) {
                setState(() {
                  _selectedBranches = result;
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedBranches.selectedBranches.isEmpty ? 'กดเพื่อเลือกสาขา (ทั้งหมด)' : _selectedBranches.getBranchDisplayString(),
                      style: TextStyle(
                        color: _selectedBranches.selectedBranches.isEmpty ? Colors.grey.shade600 : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.orange.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (_selectedBranches.selectedBranches.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'เลือกแล้ว ${_selectedBranches.selectedBranches.length} สาขา',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedBranches = const BranchSelectionModel(
                        selectedBranches: [],
                        isCancel: false,
                      );
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ลบทั้งหมด',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreditorAndSalespersonSection() {
    return Row(
      children: [
        Expanded(child: _buildCreditorSelectionSection()),
        const SizedBox(width: 16),
        Expanded(child: _buildSalespersonSelectionSection()),
      ],
    );
  }

  Widget _buildCreditorSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'เลือกลูกค้า',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final result = await Navigator.push<EntitySelectionModel?>(
                context,
                MaterialPageRoute(
                  builder: (context) => MultiBlocProvider(
                    providers: [
                      BlocProvider<CreditorBloc>(
                        create: (context) => CreditorBloc(creditorRepository: CreditorRepository()),
                      ),
                    ],
                    child: MultiEntitySearchScreen(
                      word: '',
                      entityType: EntityType.debtor,
                      preSelectedEntities: _selectedCreditors.selectedEntities,
                    ),
                  ),
                ),
              );

              if (result != null && !result.isCancel) {
                setState(() {
                  _selectedCreditors = result;
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedCreditors.selectedEntities.isEmpty ? 'กดเพื่อเลือกลูกค้า (ทั้งหมด)' : _selectedCreditors.getEntityDisplayString(),
                      style: TextStyle(
                        color: _selectedCreditors.selectedEntities.isEmpty ? Colors.grey.shade600 : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (_selectedCreditors.selectedEntities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'เลือกแล้ว ${_selectedCreditors.selectedEntities.length} ลูกค้า',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCreditors = const EntitySelectionModel(
                        selectedEntities: [],
                        isCancel: false,
                      );
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ลบทั้งหมด',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSalespersonSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_pin,
                color: Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'เลือกพนักงานขาย',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final result = await Navigator.push<EntitySelectionModel?>(
                context,
                MaterialPageRoute(
                  builder: (context) => MultiBlocProvider(
                    providers: [
                      BlocProvider<EmployeeBloc>(
                        create: (context) => EmployeeBloc(employeeRepository: EmployeeRepository()),
                      ),
                    ],
                    child: MultiEntitySearchScreen(
                      word: '',
                      entityType: EntityType.employee,
                      preSelectedEntities: _selectedSalespersons.selectedEntities,
                    ),
                  ),
                ),
              );

              if (result != null && !result.isCancel) {
                setState(() {
                  _selectedSalespersons = result;
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedSalespersons.selectedEntities.isEmpty ? 'กดเพื่อเลือกพนักงานขาย (ทั้งหมด)' : _selectedSalespersons.getEntityDisplayString(),
                      style: TextStyle(
                        color: _selectedSalespersons.selectedEntities.isEmpty ? Colors.grey.shade600 : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.green.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (_selectedSalespersons.selectedEntities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'เลือกแล้ว ${_selectedSalespersons.selectedEntities.length} พนักงาน',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSalespersons = const EntitySelectionModel(
                        selectedEntities: [],
                        isCancel: false,
                      );
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ลบทั้งหมด',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterOptionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'ตัวกรองข้อมูล',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // _buildShowDetailsToggle(),
          // const SizedBox(height: 12),
          _buildShowCancelledToggle(),
          const SizedBox(height: 12),
          _buildSaleTypeSelection(),
          const SizedBox(height: 12),
          _buildPosTypeSelection(),
        ],
      ),
    );
  }

  // Widget _buildShowDetailsToggle() {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               const Text(
  //                 'แสดงรายละเอียดสินค้า',
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //               const SizedBox(height: 4),
  //               Text(
  //                 _showDetails ? 'แสดงข้อมูลรายการสินค้าในแต่ละใบเสร็จ' : 'แสดงเฉพาะยอดรวมของแต่ละใบเสร็จ',
  //                 style: TextStyle(
  //                   fontSize: 12,
  //                   color: Colors.grey.shade600,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         Switch.adaptive(
  //           value: _showDetails,
  //           onChanged: (value) {
  //             setState(() {
  //               _showDetails = value;
  //             });
  //           },
  //           activeColor: Colors.indigo.shade600,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildShowCancelledToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'แสดงเอกสารยกเลิก',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('ทั้งหมด', style: TextStyle(fontSize: 12)),
                  value: 'ทั้งหมด',
                  groupValue: _showCancelled,
                  onChanged: (value) {
                    setState(() {
                      _showCancelled = value!;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.green.shade600,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('แสดง', style: TextStyle(fontSize: 12)),
                  value: 'แสดง',
                  groupValue: _showCancelled,
                  onChanged: (value) {
                    setState(() {
                      _showCancelled = value!;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.green.shade600,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('ไม่แสดง', style: TextStyle(fontSize: 12)),
                  value: 'ไม่แสดง',
                  groupValue: _showCancelled,
                  onChanged: (value) {
                    setState(() {
                      _showCancelled = value!;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.green.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaleTypeSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ประเภทการขาย',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('ทั้งหมด', style: TextStyle(fontSize: 12)),
                  value: 'ทั้งหมด',
                  groupValue: _saleType,
                  onChanged: (value) {
                    setState(() {
                      _saleType = value!;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.green.shade600,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('เงินเชื่อ', style: TextStyle(fontSize: 12)),
                  value: 'เงินเชื่อ',
                  groupValue: _saleType,
                  onChanged: (value) {
                    setState(() {
                      _saleType = value!;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.green.shade600,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('เงินสด', style: TextStyle(fontSize: 12)),
                  value: 'เงินสด',
                  groupValue: _saleType,
                  onChanged: (value) {
                    setState(() {
                      _saleType = value!;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.green.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPosTypeSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'แสดงรายการ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('ทั้งหมด', style: TextStyle(fontSize: 12)),
                  value: 'ทั้งหมด',
                  groupValue: _posType,
                  onChanged: (value) {
                    setState(() {
                      _posType = value!;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.green.shade600,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('POS เท่านั้น', style: TextStyle(fontSize: 12)),
                  value: 'POS เท่านั้น',
                  groupValue: _posType,
                  onChanged: (value) {
                    setState(() {
                      _posType = value!;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.green.shade600,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('หลังบ้าน', style: TextStyle(fontSize: 12)),
                  value: 'หลังบ้าน',
                  groupValue: _posType,
                  onChanged: (value) {
                    setState(() {
                      _posType = value!;
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.green.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // ตรวจสอบเงื่อนไขการค้นหา
    bool canSearch = true;
    String errorMessage = '';

    // เฉพาะ Stock Movement ต้องเลือกบาร์โค้ด (Stock Balance ไม่บังคับ)
    if (widget.reportType == BiReportType.stockMovement) {
      if (_selectedBarcodes.selectedEntities.isEmpty) {
        canSearch = false;
        errorMessage = 'กรุณาเลือกบาร์โค้ดก่อนค้นหารายงาน';
      }
    }

    return Column(
      children: [
        // แสดงข้อความแจ้งเตือนหากไม่สามารถค้นหาได้
        if (!canSearch) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.red.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ปุ่มแอ็คชัน
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                label: const Text('ยกเลิก'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: canSearch
                    ? () {
                        late ReportConditions conditions;
                        if (widget.reportType == BiReportType.sale) {
                          conditions = ReportConditions(
                            fromDate: _fromDate,
                            toDate: _toDate,
                            showDetails: _showDetails,
                            showCancelled: _showCancelled,
                            saleType: _saleType,
                            posType: _posType,
                            selectedBranches: _selectedBranches,
                            selectedCreditors: _selectedCreditors,
                            selectedSalespersons: _selectedSalespersons,
                          );
                        } else if (widget.reportType == BiReportType.saleDaily) {
                          conditions = ReportConditions(
                            fromDate: _fromDate,
                            toDate: _toDate,
                            showDetails: _showDetails,
                            showCancelled: _showCancelled,
                            saleType: _saleType,
                            posType: _posType,
                            selectedBranches: _selectedBranches,
                          );
                        } else if (widget.reportType == BiReportType.stockMovement) {
                          conditions = ReportConditions(
                            fromDate: _fromDate,
                            toDate: _toDate,
                            selectedBarcodes: _selectedBarcodes,
                          );
                        } else if (widget.reportType == BiReportType.stockBalance) {
                          conditions = ReportConditions(
                            toDate: _toDate,
                            selectedBarcodes: _selectedBarcodes,
                          );
                        } else if (widget.reportType == BiReportType.paymentDaily) {
                          conditions = ReportConditions(
                            fromDate: _fromDate,
                            toDate: _toDate,
                            selectedBranches: _selectedBranches,
                          );
                        } else if (widget.reportType == BiReportType.saleReturn) {
                          conditions = ReportConditions(
                            fromDate: _fromDate,
                            toDate: _toDate,
                            showDetails: _showDetails,
                            selectedBranches: _selectedBranches,
                          );
                        } else {
                          // Show error
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('ไม่สามารถสร้างเงื่อนไขสำหรับรายงานนี้ได้')),
                          );
                        }

                        Navigator.of(context).pop();
                        widget.onConditionsSet(conditions);
                      }
                    : null, // ปิดการใช้งานปุ่มหากไม่สามารถค้นหาได้
                icon: const Icon(Icons.search),
                label: const Text('ค้นหารายงาน'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSearch ? Colors.indigo.shade600 : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: canSearch ? 2 : 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
