import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dedecashier/global.dart' as global;
import 'package:dedecashier/model/json/member_model.dart';

/// Widgets สำหรับแสดงผลการค้นหาสมาชิก
/// แยกออกจาก pos_screen.dart เพื่อลดความซับซ้อน
class PosMemberSearchWidgets {
  /// แสดง Empty State เมื่อไม่มีผลการค้นหา
  static Widget buildEmptyState({required String searchText}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            searchText.isEmpty
                ? global.language("enter_search_terms")
                : global.language("no_customers_found"),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// แสดงรายการสมาชิกที่ค้นหาได้
  static Widget buildMembersList({
    required List<MemberModel> members,
    required Function(MemberModel, String) onMemberTap,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      itemCount: members.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: 2), // ลดระยะห่าง
      itemBuilder: (context, index) {
        final member = members[index];
        String phoneNumber = member.addressforbilling.phoneprimary;
        if (member.addressforbilling.phonesecondary.isNotEmpty) {
          phoneNumber += ", ${member.addressforbilling.phonesecondary}";
        }

        return buildMemberCard(
          member: member,
          phoneNumber: phoneNumber,
          onTap: () => onMemberTap(member, phoneNumber),
        );
      },
    );
  }

  /// Card แสดงข้อมูลสมาชิกแต่ละคน
  static Widget buildMemberCard({
    required MemberModel member,
    required String phoneNumber,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 0.5,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ชื่อ-นามสกุล
                Row(
                  children: [
                    Icon(Icons.person, size: 18, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        global.getNameFromJsonLanguage(
                          jsonEncode(
                            member.names.map((e) => e.toJson()).toList(),
                          ),
                          global.userScreenLanguage,
                        ),


                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // เบอร์โทร
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        phoneNumber,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // แสดงคะแนน (ถ้ามี)
                if (member.pointbalance > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.stars, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 6),
                      Text(
                        "${global.moneyFormat.format(member.pointbalance)} ${global.language("points")}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
