#!/usr/bin/env python3
"""
Script to integrate BarcodeScannerHandler into pos_screen.dart
Removes old barcode-related methods and integrates the new handler
"""
import re

def integrate_handler():
    file_path = r'c:\gif\dedecashier\lib\features\pos\presentation\screens\pos_screen.dart'
    
    # Read file
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_lines = len(content.split('\n'))
    print(f"📊 Original file: {original_lines} lines")
    
    # Step 1: Add import if not exists
    import_line = "import 'pos_barcode_scanner_handler.dart';"
    if import_line not in content:
        # Find the last import statement
        import_pattern = r"(import '[^']+';)\n"
        imports = list(re.finditer(import_pattern, content))
        if imports:
            last_import_end = imports[-1].end()
            content = content[:last_import_end] + import_line + '\n' + content[last_import_end:]
            print("✅ Step 1: Added import statement")
        else:
            print("❌ Could not find import section")
            return
    else:
        print("✅ Step 1: Import already exists")
    
    # Step 2: Replace barcode state variables with handler
    state_vars_pattern = r'  // 🆕 Barcode Scanner Variables.*?  Timer\? _barcodeClearTimer;'
    handler_var = '  // ✅ Barcode Scanner Handler\n  late BarcodeScannerHandler _barcodeScannerHandler;'
    
    content, replacements = re.subn(state_vars_pattern, handler_var, content, flags=re.DOTALL)
    if replacements > 0:
        print(f"✅ Step 2: Replaced {replacements} state variable blocks with handler")
    else:
        print("⚠️ Step 2: State variables not found (might already be replaced)")
    
    # Step 3: Remove old barcode methods (one by one to be safe)
    methods_to_remove = [
        ('_searchBarcodeImmediately', r'  // 🆕 ค้นหาสินค้าทันที.*?(?=\n  //|\n  Future<void>|\n  void |\n  String |\n  bool |\n\}\n)'),
        ('_processBarcodeInSearchMode', r'  // 🆕 ค้นหาสินค้าเมื่อสแกน barcode.*?(?=\n  //|\n  Future<void>|\n  void |\n  String |\n  bool |\n\}\n)'),
        ('_getCharacterFromKeyEvent', r'  // ดึงตัวอักษรจาก KeyEvent.*?(?=\n  //|\n  Future<void>|\n  void |\n  String |\n  bool |\n\}\n)'),
        ('_handleNumpadInputKeyEvent', r'  // จัดการ numpad input.*?(?=\n  //|\n  Future<void>|\n  void |\n  String |\n  bool |\n\}\n)'),
        ('_processBarcode', r'  // ประมวลผล barcode ที่สะสมใน buffer.*?(?=\n  //|\n  Future<void>|\n  void |\n  String |\n  bool |\n\} // แปลง|\n\}\n)'),
        ('_convertThaiToNumbers', r'  // แปลงอักษรไทยเป็นตัวเลข.*?(?=\n  //|\n  Future<void>|\n  void |\n  String |\n  bool |\n\}\n)'),
        ('_cleanBarcode', r'  // ทำความสะอาด barcode.*?(?=\n  //|\n  Future<void>|\n  void |\n  String |\n  bool |\n\}\n)'),
        ('_isUnicodeCodePoints', r'  // ตรวจสอบว่าเป็น Unicode code points.*?(?=\n  //|\n  Future<void>|\n  void |\n  String |\n  bool |\n\}\n)'),
        ('_convertUnicodeCodePointsToString', r'  // แปลง Unicode code points เป็น string.*?(?=\n  //|\n  Future<void>|\n  void |\n  String |\n  bool |\n\}\n)'),
        ('_isValidBarcode', r'  // ตรวจสอบว่า barcode ถูกต้องหรือไม่.*?(?=\n  //|\n  Future<void>|\n  void |\n  String |\n  bool |\n\}\n)'),
        ('_isCommonBarcodeFormat', r'  // ตรวจสอบ format ของ barcode.*?(?=\n  //|\n  Future<void>|\n  void |\n  String |\n  bool |\n\}\n)'),
    ]
    
    total_removed = 0
    for method_name, pattern in methods_to_remove:
        before_len = len(content)
        content, replacements = re.subn(pattern, '', content, flags=re.DOTALL, count=1)
        after_len = len(content)
        
        if replacements > 0:
            lines_removed = (before_len - after_len) // 50  # Approximate
            total_removed += lines_removed
            print(f"✅ Removed {method_name}() (~{lines_removed} lines)")
        else:
            print(f"⚠️ {method_name}() not found")
    
    # Step 4: Replace _handleKeyEvent with delegation
    old_handleKeyEvent = re.compile(
        r'  // 🆕 Handle keyboard events.*?'
        r'void _handleKeyEvent\(KeyEvent event\) \{.*?\n  \}',
        re.DOTALL
    )
    new_handleKeyEvent = '''  // ✅ ใช้ BarcodeScannerHandler แทน - delegating ไปยัง handler
  void _handleKeyEvent(KeyEvent event) {
    _barcodeScannerHandler.handleKeyEvent(event);
  }'''
    
    content, replacements = old_handleKeyEvent.subn(new_handleKeyEvent, content)
    if replacements > 0:
        print(f"✅ Step 4: Replaced _handleKeyEvent() with delegation")
    else:
        print("⚠️ Step 4: _handleKeyEvent() not found or already replaced")
    
    # Write back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    final_lines = len(content.split('\n'))
    lines_saved = original_lines - final_lines
    percentage = (lines_saved / original_lines) * 100 if original_lines > 0 else 0
    
    print(f"\n📊 SUMMARY:")
    print(f"   Original: {original_lines} lines")
    print(f"   Final: {final_lines} lines")
    print(f"   Saved: {lines_saved} lines ({percentage:.1f}%)")
    print(f"   Methods removed: {total_removed} methods")
    print(f"\n✅ Integration complete!")

if __name__ == '__main__':
    integrate_handler()
