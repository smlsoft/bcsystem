import 'package:dedecashier/bloc/bill_bloc.dart';
import 'package:dedecashier/bloc/find_member_by_tel_name_bloc.dart';
import 'package:dedecashier/api/api_repository.dart';
import 'package:dedecashier/db/bill_helper.dart';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/model/objectbox/bill_struct.dart';
import 'package:dedecashier/model/json/member_model.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_print.dart';
import 'package:dedecashier/features/pos/presentation/screens/pos_util.dart';
import 'package:dedecashier/global_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/global.dart' as global;

// ⭐ Theme Colors: MARINEPOS = น้ำเงินเข้ม, อื่นๆ = อิฐบ้านเชียง (Terracotta)
final Color _themeColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);

class PosBillVatDetailScreen extends StatefulWidget {
  final global.PosScreenModeEnum posScreenMode;
  final String docNumber;

  @override
  const PosBillVatDetailScreen({super.key, required this.docNumber, required this.posScreenMode});

  @override
  State<PosBillVatDetailScreen> createState() => _PosBillVatDetailScreenState();
}

class _PosBillVatDetailScreenState extends State<PosBillVatDetailScreen> {
  late BillObjectBoxStruct bill;
  TextEditingController taxIdController = TextEditingController();
  TextEditingController customerCodeController = TextEditingController();
  TextEditingController branchNumberController = TextEditingController();
  TextEditingController customerNameController = TextEditingController();
  TextEditingController customerAddressController = TextEditingController();
  TextEditingController customerTelephoneController = TextEditingController();
  // Add FindMemberByTelNameBloc instance
  late FindMemberByTelNameBloc findMemberBloc;
  List<MemberModel> searchResults = [];
  bool isSearching = false;
  bool hasProcessedLastSearch = false; // Add flag to prevent infinite loop
  @override
  void initState() {
    super.initState();
    // Initialize the FindMemberByTelNameBloc with a new ApiRepository instance

    findMemberBloc = FindMemberByTelNameBloc(apiFindMemberByTelName: ApiRepository(), offset: 0, limit: 50);
    context.read<BillBloc>().add(BillLoadByDocNumber(docNumber: widget.docNumber, posScreenMode: widget.posScreenMode));
  }

  @override
  void dispose() {
    taxIdController.dispose();
    customerCodeController.dispose();
    branchNumberController.dispose();
    customerNameController.dispose();
    customerAddressController.dispose();
    customerTelephoneController.dispose();
    findMemberBloc.close();
    super.dispose();
  }

  // Method to show customer search dialog
  void _showCustomerSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomerSearchDialog(
          findMemberBloc: findMemberBloc,
          onCustomerSelected: (MemberModel member) {
            _populateCustomerData(member);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  // Method to search for customer by code
  void _searchCustomerByCode(String customerCode) {
    if (customerCode.trim().isNotEmpty) {
      setState(() {
        isSearching = true;
        searchResults.clear();
        hasProcessedLastSearch = false; // Reset flag when starting new search
      });
      findMemberBloc.add(FindMemberByTelNameLoadStart(words: customerCode.trim(), offset: 0, limit: 50));
    }
  }

  // Method to populate customer data from search result
  void _populateCustomerData(MemberModel member) {
    setState(() {
      customerCodeController.text = member.code;

      if (member.names.isNotEmpty) {
        customerNameController.text = member.names.first.name;
      } else {
        customerNameController.text = "";
      }

      if (member.taxid.isNotEmpty) {
        taxIdController.text = member.taxid;
      } else {
        taxIdController.text = "";
      }

      if (member.branchnumber.isNotEmpty && member.personaltype == 2) {
        branchNumberController.text = member.branchnumber;
      } else {
        branchNumberController.text = "";
      }

      String address = "";

      if (member.addressforbilling.address.isNotEmpty) {
        member.addressforbilling.address.forEach((line) {
          if (line.isNotEmpty) {
            if (address.isNotEmpty) address += "\n";
            address += line;
          }
        });
      }

      if (member.addressforbilling.contactnames.isNotEmpty) {
        if (address.isNotEmpty) address += "\n";
        if (member.addressforbilling.contactnames.first.name.isNotEmpty) {
          address += "ติดต่อ: ${member.addressforbilling.contactnames.first.name}";
        } else {
          address += "";
        }
      }

      if (member.addressforbilling.phoneprimary.isNotEmpty) {
        customerTelephoneController.text = "${member.addressforbilling.phoneprimary}";
      }
      // if (member.addressforbilling.phonesecondary.isNotEmpty) {
      //   if (address.isNotEmpty) address += "\n";
      //   address += "Phone 2: ${member.addressforbilling.phonesecondary}";
      // }

      if (member.email.isNotEmpty) {
        if (address.isNotEmpty) address += "\n";
        address += "Email: ${member.email}";
      }

      customerAddressController.text = address;

      searchResults.clear();
      isSearching = false;
      hasProcessedLastSearch = true; // Mark as processed
    });
  }

  // Method to clear customer data when no results found
  void _clearCustomerData() {
    setState(() {
      // Keep only the customer code that user typed, clear other fields
      taxIdController.clear();
      branchNumberController.clear();
      customerNameController.clear();
      customerAddressController.clear();
      customerTelephoneController.clear();

      searchResults.clear();
      isSearching = false;
      hasProcessedLastSearch = true; // Mark as processed
    });
  }

  // Helper method to build table rows
  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(value, style: const TextStyle(color: Colors.black54)),
          ),
        ),
      ],
    );
  }

  // Helper method to build form fields
  Widget _buildFormField({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 5),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the correct branch data
    Iterable<ProfileSettingBranchModel> branchModels = global.profileSetting.branch.where((element) => element.guidfixed == global.posConfig.branch.guidfixed);
    ProfileSettingBranchModel branchModel = branchModels.isNotEmpty ? branchModels.first : ProfileSettingBranchModel();

    return BlocBuilder<BillBloc, BillState>(
      builder: (context, state) {
        if (state is BillLoadByDocNumberSuccess) {
          if (state.bill != null) {
            bill = state.bill!;
            taxIdController.text = bill.full_vat_tax_id;
            customerCodeController.text = bill.customer_code;
            branchNumberController.text = bill.full_vat_branch_number;
            customerNameController.text = bill.full_vat_name;
            customerAddressController.text = bill.full_vat_address;
            customerTelephoneController.text = bill.customer_telephone;

            // Auto-search for customer when bill loads if customer_code exists
            if (bill.customer_code.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _searchCustomerByCode(bill.customer_code);
              });
            }
          }
          context.read<BillBloc>().add(BillLoadByDocNumberFinish());
        }
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              global.language("pos_bill_vat_detail"),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: _themeColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Container(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add BlocBuilder for customer search results
                  BlocBuilder<FindMemberByTelNameBloc, FindMemberByTelNameState>(
                    bloc: findMemberBloc,
                    builder: (context, memberState) {
                      if (memberState is FindMemberByTelNameLoadSuccess && !hasProcessedLastSearch) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!hasProcessedLastSearch) {
                            // Double check to prevent race conditions
                            setState(() {
                              searchResults = memberState.result;
                              isSearching = false;
                              hasProcessedLastSearch = true; // Mark as processed
                            }); // Auto-populate if only one result found
                            if (memberState.result.length == 1) {
                              _populateCustomerData(memberState.result.first);
                            } else if (memberState.result.isEmpty && customerCodeController.text.isNotEmpty) {
                              // Clear form when no results found
                              _clearCustomerData();
                              // Show snackbar if no results found
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   SnackBar(
                              //     content: Text("${global.language("search_customer")}: ${global.language("fail")}"),
                              //     duration: const Duration(seconds: 2),
                              //   ),
                              // );
                            }
                          }
                        });
                      } else if (memberState is FindMemberByTelNameLoading) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            isSearching = true;
                          });
                        });
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                  // Company Information Card
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.business, color: _themeColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'ข้อมูลบริษัท',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _themeColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Table(
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(3)},
                            children: [
                              _buildTableRow(global.language("company_name"), branchModel.companynames.isNotEmpty ? branchModel.companynames.first.name : global.language("no_company_name")),
                              _buildTableRow(global.language("branch_name"), branchModel.names.isNotEmpty ? branchModel.names.first.name : global.language("no_branch_name")),
                              _buildTableRow(global.language("branch_code"), branchModel.code.isNotEmpty ? branchModel.code : global.language("no_branch_code")),
                              _buildTableRow(global.language("company_address"), branchModel.contact.address.isNotEmpty ? branchModel.contact.address.first.name : global.language("no_address")),
                              _buildTableRow(global.language("company_tax_id"), (branchModel.pos.taxid?.isNotEmpty ?? false) ? branchModel.pos.taxid! : global.language("no_tax_id")),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Customer Information Form Card
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, color: _themeColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'ข้อมูลลูกค้า',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _themeColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Customer Code Field
                          _buildFormField(
                            label: global.language("customer_code"),
                            child: TextField(
                              controller: customerCodeController,
                              decoration: InputDecoration(
                                hintText: 'กรอกรหัสลูกค้า',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: _themeColor, width: 2),
                                ),
                                suffixIcon: isSearching
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2)),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.search),
                                        onPressed: () {
                                          global.playSound(sound: global.SoundEnum.buttonTing);
                                          _showCustomerSearchDialog();
                                        },
                                      ),
                              ),
                            ),
                          ),

                          // Tax ID Field
                          _buildFormField(
                            label: global.language("customer_tax_id"),
                            child: TextField(
                              controller: taxIdController,
                              decoration: InputDecoration(
                                hintText: 'กรอกเลขประจำตัวผู้เสียภาษี',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: _themeColor, width: 2),
                                ),
                              ),
                            ),
                          ),

                          // Branch Number Field
                          _buildFormField(
                            label: global.language("customer_branch_number"),
                            child: TextField(
                              controller: branchNumberController,
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                hintText: 'กรอกหมายเลขสาขา',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: _themeColor, width: 2),
                                ),
                              ),
                            ),
                          ),

                          // Customer Name Field
                          _buildFormField(
                            label: global.language("customer_name"),
                            child: TextField(
                              controller: customerNameController,
                              decoration: InputDecoration(
                                hintText: 'กรอกชื่อลูกค้า',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: _themeColor, width: 2),
                                ),
                              ),
                            ),
                          ),

                          // Customer Address Field
                          _buildFormField(
                            label: global.language("customer_address"),
                            child: TextField(
                              controller: customerAddressController,
                              keyboardType: TextInputType.multiline,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'กรอกที่อยู่ลูกค้า',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: _themeColor, width: 2),
                                ),
                              ),
                            ),
                          ),
                          // Customer Telephone Field
                          _buildFormField(
                            label: global.language("customer_telephone"),
                            child: TextField(
                              controller: customerTelephoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                hintText: 'กรอกเบอร์โทรลูกค้า',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: _themeColor, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Search Results Card
                  if (searchResults.isNotEmpty) ...[
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.search_rounded, color: _themeColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "${global.language("search_customer")} (${searchResults.length})",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _themeColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 300),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: searchResults.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final member = searchResults[index];
                                  String displayName = member.names.isNotEmpty ? member.names.first.name : global.language("no_name");
                                  String subtitle = "";

                                  if (member.taxid.isNotEmpty) {
                                    subtitle = "Tax ID: ${member.taxid}";
                                  }

                                  if (member.addressforbilling.phoneprimary.isNotEmpty) {
                                    if (subtitle.isNotEmpty) subtitle += " | ";
                                    subtitle += "Tel: ${member.addressforbilling.phoneprimary}";
                                  }

                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        global.playSound(sound: global.SoundEnum.buttonTing);
                                        _populateCustomerData(member);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: (F.appFlavor != Flavor.MARINEPOS) ? Colors.blue.shade100 : const Color(0xFF005598).withOpacity(0.1),
                                              radius: 20,
                                              child: Text(
                                                member.code.isNotEmpty ? member.code[0].toUpperCase() : "?",
                                                style: TextStyle(color: (F.appFlavor != Flavor.MARINEPOS) ? Colors.blue.shade800 : const Color(0xFF005598), fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "${member.code} - $displayName",
                                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (subtitle.isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      subtitle,
                                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (member.taxid.isNotEmpty) const Icon(Icons.receipt, size: 16, color: Colors.green),
                                                if (member.email.isNotEmpty) const Icon(Icons.email, size: 16, color: Colors.blue),
                                                const SizedBox(width: 8),
                                                Icon(Icons.check_circle_outline, color: (F.appFlavor != Flavor.MARINEPOS) ? Colors.blue : const Color(0xFF005598), size: 20),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Action Buttons
                  ],
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      label: Text(global.language("pos_bill_vat"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      icon: const Icon(Icons.print, size: 20),
                      onPressed: () {
                        global.playSound(sound: global.SoundEnum.buttonTing);
                        bool isProcessing = false;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setDialogState) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  title: Text(global.language("pos_bill_vat"), style: const TextStyle(fontWeight: FontWeight.w600)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(bill.doc_number, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                      if (isProcessing) ...[const SizedBox(height: 20), const CircularProgressIndicator(), const SizedBox(height: 16), Text(global.language("processing") != "processing" ? global.language("processing") : "กำลังประมวลผล")],
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: isProcessing
                                          ? null
                                          : () {
                                              global.playSound(sound: global.SoundEnum.buttonTing);
                                              Navigator.of(context).pop();
                                            },
                                      child: Text(global.language("cancel")),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _themeColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: isProcessing
                                          ? null
                                          : () async {
                                              global.playSound(sound: global.SoundEnum.buttonTing);
                                              setDialogState(() {
                                                isProcessing = true;
                                              });

                                              try {
                                                BillHelper().updatesFullVat(
                                                  docNumber: bill.doc_number,
                                                  taxId: taxIdController.text,
                                                  branchNumber: branchNumberController.text,
                                                  customerCode: customerCodeController.text,
                                                  customerName: customerNameController.text,
                                                  customerAddress: customerAddressController.text,
                                                  customerTelephone: customerTelephoneController.text,
                                                );
                                                await printBillProcess(posScreenMode: widget.posScreenMode, docDate: bill.date_time, docNo: bill.doc_number, printLogo: global.posTicket.logo, languageCode: global.userScreenLanguage);

                                                if (mounted) {
                                                  Navigator.pop(context);
                                                  Navigator.pop(context);
                                                  Navigator.pop(context);
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  setDialogState(() {
                                                    isProcessing = false;
                                                  });
                                                }
                                              }
                                            },
                                      child: isProcessing
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                                const SizedBox(width: 8),
                                                Text(global.language("processing") != "processing" ? global.language("processing") : "กำลังประมวลผล"),
                                              ],
                                            )
                                          : Text(global.language("print")),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Bill Details
                  posBillDetail(docNumber: widget.docNumber),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Customer Search Dialog Widget
class CustomerSearchDialog extends StatefulWidget {
  final FindMemberByTelNameBloc findMemberBloc;
  final Function(MemberModel) onCustomerSelected;

  const CustomerSearchDialog({super.key, required this.findMemberBloc, required this.onCustomerSelected});

  @override
  State<CustomerSearchDialog> createState() => _CustomerSearchDialogState();
}

class _CustomerSearchDialogState extends State<CustomerSearchDialog> {
  final TextEditingController searchController = TextEditingController();
  List<MemberModel> searchResults = [];
  bool isSearching = false;
  bool hasSearched = false;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      setState(() {
        isSearching = true;
        searchResults.clear();
        hasSearched = false;
      });

      widget.findMemberBloc.add(FindMemberByTelNameLoadStart(words: query.trim(), offset: 0, limit: 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.search, color: _themeColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      global.language("search_customer"),
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _themeColor),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    global.playSound(sound: global.SoundEnum.buttonTing);
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Field
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "${global.language("customer_code")} / ${global.language("customer_name")} / ${global.language("customer_phone")}",
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon: isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : null,
                      ),
                      onSubmitted: _performSearch,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      global.playSound(sound: global.SoundEnum.buttonTing);
                      _performSearch(searchController.text);
                    },
                    child: Text(global.language("search_customer"), style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Results
            Expanded(
              child: BlocBuilder<FindMemberByTelNameBloc, FindMemberByTelNameState>(
                bloc: widget.findMemberBloc,
                builder: (context, state) {
                  if (state is FindMemberByTelNameLoadSuccess) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!hasSearched) {
                        setState(() {
                          searchResults = state.result;
                          isSearching = false;
                          hasSearched = true;
                        });
                      }
                    });
                  } else if (state is FindMemberByTelNameLoading) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        isSearching = true;
                      });
                    });
                  }

                  if (searchResults.isEmpty && !isSearching) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            hasSearched && searchController.text.isNotEmpty ? "ไม่พบข้อมูลลูกค้า" : "ค้นหาลูกค้า",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                          ),
                          if (!hasSearched || searchController.text.isEmpty) ...[const SizedBox(height: 8), Text("กรอกรหัส ชื่อ หรือเบอร์โทรของลูกค้า", style: TextStyle(fontSize: 14, color: Colors.grey.shade500))],
                          if (hasSearched && searchController.text.isNotEmpty && searchResults.isEmpty) ...[const SizedBox(height: 8), Text("ลองค้นหาด้วยคำอื่น", style: TextStyle(fontSize: 14, color: Colors.grey.shade500))],
                        ],
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: searchResults.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.transparent),
                      itemBuilder: (context, index) {
                        final member = searchResults[index];
                        final displayName = member.names.isNotEmpty ? member.names.first.name : "Unknown";

                        String subtitle = "";
                        if (member.addressforbilling.phoneprimary.isNotEmpty) {
                          subtitle = "Tel: ${member.addressforbilling.phoneprimary}";
                        }
                        if (member.taxid.isNotEmpty) {
                          if (subtitle.isNotEmpty) subtitle += " • ";
                          subtitle += "Tax ID: ${member.taxid}";
                        }
                        if (member.email.isNotEmpty) {
                          if (subtitle.isNotEmpty) subtitle += " • ";
                          subtitle += "Email: ${member.email}";
                        }
                        if (subtitle.isEmpty) {
                          subtitle = "ไม่มีข้อมูลติดต่อ";
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                global.playSound(sound: global.SoundEnum.buttonTing);
                                widget.onCustomerSelected(member);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: _themeColor.withOpacity(0.1),
                                      radius: 24,
                                      child: Text(
                                        member.code.isNotEmpty ? member.code[0].toUpperCase() : "?",
                                        style: TextStyle(color: _themeColor, fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${member.code} - $displayName",
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            subtitle,
                                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (member.taxid.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                            child: const Icon(Icons.receipt, size: 14, color: Colors.green),
                                          ),
                                        if (member.email.isNotEmpty) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(4)),
                                            child: const Icon(Icons.email, size: 14, color: Colors.blue),
                                          ),
                                        ],
                                        const SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_ios, color: (F.appFlavor != Flavor.MARINEPOS) ? Colors.blue : const Color(0xFF005598), size: 16),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
