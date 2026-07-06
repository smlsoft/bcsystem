import 'package:dedecashier/bloc/find_employee_by_name_bloc.dart';
import 'package:dedecashier/flavors.dart';
import 'package:dedecashier/model/find/find_employee_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:cached_network_image/cached_network_image.dart';

// ⭐ Theme Colors: MARINEPOS = น้ำเงินเข้ม, อื่นๆ = อิฐบ้านเชียง (Terracotta)
final Color _themeColor = (F.appFlavor == Flavor.MARINEPOS) ? const Color(0xFF005598) : const Color(0xFFB5651D);
final MaterialColor _themeSwatch = (F.appFlavor == Flavor.MARINEPOS)
    ? Colors.blue
    : MaterialColor(0xFFB5651D, const <int, Color>{
        50: Color(0xFFFBF5F0),
        100: Color(0xFFF5E6D8),
        200: Color(0xFFEAC9AC),
        300: Color(0xFFDEAB7F),
        400: Color(0xFFD18D52),
        500: Color(0xFFB5651D),
        600: Color(0xFF9A5518),
        700: Color(0xFF7F4513),
        800: Color(0xFF64350E),
        900: Color(0xFF4A2509),
      });

class FindEmployee extends StatefulWidget {
  const FindEmployee({super.key});

  @override
  State<FindEmployee> createState() => _FindEmployeeState();
}

class _FindEmployeeState extends State<FindEmployee> with TickerProviderStateMixin {
  final debouncer = global.Debounce(500);
  final List<FindEmployeeModel> findResult = [];
  final TextEditingController textFindByTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<FindEmployeeByNameBloc>().add(FindEmployeeByNameLoadStart(''));
  }

  Widget findByText() {
    return BlocBuilder<FindEmployeeByNameBloc, FindEmployeeByNameState>(
      builder: (context, state) {
        if (state is FindEmployeeByNameLoadSuccess) {
          findResult.clear(); // ล้างข้อมูลเก่าก่อน
          findResult.addAll(state.result);
          context.read<FindEmployeeByNameBloc>().add(FindEmployeeByNameLoadFinish());
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: TextField(
                  controller: textFindByTextController,
                  onChanged: (string) {
                    setState(() {
                      // ล้างผลลัพธ์เก่าและอัพเดท UI
                    });
                    debouncer.run(() {
                      context.read<FindEmployeeByNameBloc>().add(FindEmployeeByNameLoadStart(textFindByTextController.text));
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "ค้นหาพนักงาน (ชื่อ)",
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 24),
                    suffixIcon: textFindByTextController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () => setState(() {
                              findResult.clear();
                              textFindByTextController.clear();
                            }),
                            icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                            splashRadius: 20,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: employeeContent()),
            ],
          ),
        );
      },
    );
  }

  Widget employeeContent() {
    return BlocBuilder<FindEmployeeByNameBloc, FindEmployeeByNameState>(
      builder: (context, state) {
        // แสดง loading เมื่อกำลังค้นหา
        if (state is FindEmployeeByNameLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // แสดง empty state เมื่อไม่พบผลลัพธ์
        if (findResult.isEmpty && textFindByTextController.text.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'ไม่พบพนักงาน',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text('ลองค้นหาด้วยคำอื่น', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 160, childAspectRatio: 0.8, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: findResult.length,
          itemBuilder: (BuildContext ctx, index) {
            return employeeButton(index);
          },
        );
      },
    );
  }

  Widget employeeButton(int index) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), spreadRadius: 1, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            Navigator.pop(context, [findResult[index].code, findResult[index].name]);
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (findResult[index].profile_picture.trim().isNotEmpty)
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: findResult[index].profile_picture,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.person, color: Colors.grey[400], size: 30),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.person, color: Colors.grey[400], size: 30),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.person, color: Colors.grey[400], size: 30),
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    findResult[index].name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(global.language("find_employee"), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: _themeColor,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_themeSwatch[400]!, _themeSwatch[600]!]),
          ),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: findByText(),
    );
  }
}
