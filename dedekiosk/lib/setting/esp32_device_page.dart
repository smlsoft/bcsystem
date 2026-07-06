import 'package:flutter/material.dart';
import 'package:dedekiosk/global.dart' as global;
import 'package:dedekiosk/util/api.dart' as api;

class Esp32DevicePage extends StatefulWidget {
  const Esp32DevicePage({super.key});

  @override
  State<Esp32DevicePage> createState() => _Esp32DevicePageState();
}

class _Esp32DevicePageState extends State<Esp32DevicePage> {
  List<Map<String, dynamic>> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _loading = true);
    try {
      final result = await api.clickHouseSelect(
        "SELECT mac, tablenum, label, toString(updatedAt) as updatedAt "
        "FROM ${global.clickHouseDatabaseName}.esp32device "
        "WHERE shopid='${global.deviceConfig.shopId}' "
        "AND branchid='${global.deviceConfig.branchId}' "
        "ORDER BY label",
      );
      final rows = (result['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (mounted) setState(() { _devices = rows; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteDevice(String mac) async {
    try {
      await api.clickHouseExecute(
        "ALTER TABLE ${global.clickHouseDatabaseName}.esp32device "
        "DELETE WHERE mac='$mac' AND shopid='${global.deviceConfig.shopId}'",
      );
      await _loadDevices();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบไม่สำเร็จ: $e')),
        );
      }
    }
  }

  void _showAddDialog({Map<String, dynamic>? existing}) {
    final macCtrl = TextEditingController(text: existing?['mac'] ?? '');
    final tableCtrl = TextEditingController(text: existing?['tablenum'] ?? '');
    final labelCtrl = TextEditingController(text: existing?['label'] ?? '');
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'แก้ไขอุปกรณ์ ESP32' : 'เพิ่มอุปกรณ์ ESP32'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: macCtrl,
                readOnly: isEdit,
                decoration: const InputDecoration(
                  labelText: 'MAC Address',
                  hintText: 'XX:XX:XX:XX:XX:XX',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tableCtrl,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'เลขโต๊ะ',
                  hintText: '10',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'ชื่อโต๊ะ (label)',
                  hintText: 'โต๊ะ 10',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final mac = macCtrl.text.trim().toUpperCase();
              final tablenum = tableCtrl.text.trim();
              final label = labelCtrl.text.trim();
              if (mac.isEmpty || tablenum.isEmpty) return;

              Navigator.pop(ctx);
              try {
                // Upsert: delete old then insert
                await api.clickHouseExecute(
                  "ALTER TABLE ${global.clickHouseDatabaseName}.esp32device "
                  "DELETE WHERE mac='$mac' AND shopid='${global.deviceConfig.shopId}'",
                );
                await Future.delayed(const Duration(milliseconds: 300));
                await api.clickHouseExecute(
                  "INSERT INTO ${global.clickHouseDatabaseName}.esp32device "
                  "(mac, shopid, branchid, tablenum, label, updatedAt) VALUES "
                  "('$mac', '${global.deviceConfig.shopId}', '${global.deviceConfig.branchId}', "
                  "'$tablenum', '${label.isEmpty ? 'โต๊ะ $tablenum' : label}', now())",
                );
                await _loadDevices();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
                  );
                }
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32 Devices'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDevices,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มอุปกรณ์'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.developer_board_off, size: 72, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('ยังไม่มีอุปกรณ์ ESP32',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Text('กด + เพื่อเพิ่มอุปกรณ์',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _devices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final d = _devices[i];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.developer_board, color: Color(0xFF1976D2), size: 28),
                        ),
                        title: Text(
                          d['label'] ?? 'โต๊ะ ${d['tablenum']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MAC: ${d['mac']}',
                                style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                            Text('โต๊ะ: ${d['tablenum']}',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _showAddDialog(existing: d),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('ลบอุปกรณ์'),
                                    content: Text('ลบ ${d['label'] ?? d['mac']} ออกจากระบบ?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
                                      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ')),
                                    ],
                                  ),
                                );
                                if (confirm == true) await _deleteDevice(d['mac']);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
