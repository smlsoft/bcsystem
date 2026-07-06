#!/usr/bin/env python3
"""
🔧 Fix AppLogger Method Names
แก้ไขชื่อ method ใน AppLogger ให้เป็นชื่อเต็ม

เปลี่ยนจาก:
- AppLogger.d() → AppLogger.debug()
- AppLogger.i() → AppLogger.info()
- AppLogger.success() → คงเดิม (เป็น helper method)

Usage:
    python fix_applogger_method_names.py
"""

import re
import os
from pathlib import Path
from typing import Tuple


class AppLoggerMethodFixer:
    """แก้ไขชื่อ method ของ AppLogger"""
    
    def __init__(self):
        self.files_processed = 0
        self.files_modified = 0
        self.replacements_made = 0
    
    def fix_method_calls(self, content: str) -> Tuple[str, int]:
        """แก้ไขการเรียก method ของ AppLogger"""
        original_content = content
        count = 0
        
        # Replace AppLogger.d( → AppLogger.debug(
        pattern1 = r'AppLogger\.d\('
        matches = len(re.findall(pattern1, content))
        content = re.sub(pattern1, 'AppLogger.debug(', content)
        count += matches
        
        # Replace AppLogger.i( → AppLogger.info(
        pattern2 = r'AppLogger\.i\('
        matches = len(re.findall(pattern2, content))
        content = re.sub(pattern2, 'AppLogger.info(', content)
        count += matches
        
        return content, count
    
    def process_file(self, file_path: Path) -> bool:
        """ประมวลผลไฟล์เดียว"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Skip if no AppLogger calls
            if 'AppLogger.' not in content:
                return False
            
            # Fix method calls
            new_content, count = self.fix_method_calls(content)
            
            # Skip if no changes
            if new_content == content:
                return False
            
            # Write back
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            
            self.replacements_made += count
            return True
            
        except Exception as e:
            print(f"  ❌ Error processing {file_path}: {e}")
            return False
    
    def process_directory(self, directory: Path):
        """ประมวลผล directory ทั้งหมด"""
        # Get all Dart files
        dart_files = list(directory.rglob('*.dart'))
        
        # Filter out test files and generated files
        dart_files = [
            f for f in dart_files
            if 'test/' not in str(f)
            and '.g.dart' not in str(f)
            and 'generated' not in str(f).lower()
        ]
        
        print(f"🔍 Found {len(dart_files)} Dart files to process...")
        print()
        
        for file_path in dart_files:
            self.files_processed += 1
            
            if self.process_file(file_path):
                self.files_modified += 1
                print(f"  ✅ Updated: {file_path}")
            else:
                print(f"  ⏭️  Skipped: {file_path}")
        
        print()
        print("=" * 70)
        print(f"✅ Conversion Complete!")
        print(f"   Files processed: {self.files_processed}")
        print(f"   Files modified: {self.files_modified}")
        print(f"   Method calls renamed: {self.replacements_made}")
        print("=" * 70)


def main():
    """Main entry point"""
    print("🚀 AppLogger Method Name Fixer")
    print("=" * 70)
    print("Changes:")
    print("  - AppLogger.d() → AppLogger.debug()")
    print("  - AppLogger.i() → AppLogger.info()")
    print("=" * 70)
    print()
    
    # Get project root (where this script is located)
    project_root = Path(__file__).parent
    lib_dir = project_root / 'lib'
    
    if not lib_dir.exists():
        print(f"❌ Error: lib directory not found at {lib_dir}")
        return
    
    fixer = AppLoggerMethodFixer()
    fixer.process_directory(lib_dir)


if __name__ == '__main__':
    main()
