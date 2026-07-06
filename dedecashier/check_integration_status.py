#!/usr/bin/env python3
"""
Safe integration of BarcodeScannerHandler - does only what's necessary
"""
import re
import shutil

def main():
    file_path = r'c:\gif\dedecashier\lib\features\pos\presentation\screens\pos_screen.dart'
    backup_path = file_path + '.backup_before_handler'
    
    # Create backup
    shutil.copy2(file_path, backup_path)
    print(f"✅ Created backup: {backup_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    original_count = len(lines)
    print(f"📊 Original: {original_count} lines")
    
    # Track what we need to do
    has_import = False
    has_handler_var = False
    methods_found = {}
    
    # First pass: analyze file
    for i, line in enumerate(lines):
        if "import 'pos_barcode_scanner_handler.dart';" in line:
            has_import = True
        if "late BarcodeScannerHandler _barcodeScannerHandler" in line:
            has_handler_var = True
        
        # Check for methods to remove
        for method in ['_searchBarcodeImmediately', '_processBarcodeInSearchMode',
                       '_getCharacterFromKeyEvent', '_handleNumpadInputKeyEvent',
                       '_processBarcode', '_convertThaiToNumbers', '_cleanBarcode',
                       '_isUnicodeCodePoints', '_convertUnicodeCodePointsToString',
                       '_isValidBarcode', '_isCommonBarcodeFormat']:
            if f'  {method}(' in line or f'  Future<void> {method}(' in line or f'  String {method}(' in line or f'  bool {method}(' in line:
                if method not in methods_found:
                    methods_found[method] = i
    
    print(f"\n📝 Analysis:")
    print(f"   Has import: {has_import}")
    print(f"   Has handler var: {has_handler_var}")
    print(f"   Methods found: {len(methods_found)}")
    for method in methods_found:
        print(f"      - {method} at line {methods_found[method] + 1}")
    
    # Now integrate if needed
    if not has_import:
        print("\n❌ Missing import - handler integration not complete")
        print("   Please run the full integration steps first")
        return
    
    if not has_handler_var:
        print("\n❌ Missing handler variable - handler integration not complete")
        print("   Please run the full integration steps first")
        return
    
    if len(methods_found) == 0:
        print("\n✅ All methods already removed - integration complete!")
        return
    
    print(f"\n🔧 Need to remove {len(methods_found)} methods")
    print("❓ This script cannot safely remove methods from 12K line file")
    print("   Recommendation: Use IDE refactoring tools or manual deletion")
    
if __name__ == '__main__':
    main()
