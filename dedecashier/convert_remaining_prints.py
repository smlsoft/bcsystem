#!/usr/bin/env python3
"""
🔄 Convert Remaining print() to AppLogger

แปลง print() statements ทั้งหมดที่เหลืออยู่ให้เป็น AppLogger
รองรับทั้ง simple และ complex patterns

Features:
- Smart log level detection (debug, info, warning, error)
- Preserves emoji and formatting
- Handles multi-line strings
- Handles variable-only prints
- Auto-adds import if missing
- Safe: Skips test files และ .md files
"""

import os
import re
from pathlib import Path
from typing import List, Tuple

class PrintToLoggerConverter:
    def __init__(self):
        self.files_processed = 0
        self.files_modified = 0
        self.prints_converted = 0
        
        # Error/Warning indicators
        self.ERROR_INDICATORS = [
            'error', 'failed', 'exception', 'crash', 'fatal',
            '❌', '🔴', '💥', 'ERROR', 'FAILED', 'Exception'
        ]
        
        self.WARNING_INDICATORS = [
            'warning', 'warn', 'deprecated', 'caution',
            '⚠️', '🟡', 'WARNING', 'WARN'
        ]
        
        self.SUCCESS_INDICATORS = [
            'success', 'completed', 'done', 'ok',
            '✅', '🎉', '✓', 'SUCCESS', 'COMPLETED'
        ]
        
        self.INFO_INDICATORS = [
            'info', 'loaded', 'initialized', 'started',
            'ℹ️', '📝', '🔵', 'INFO'
        ]
    
    def should_skip_file(self, file_path: str) -> bool:
        """ตรวจสอบว่าควร skip ไฟล์หรือไม่"""
        # Skip test files
        if '/test/' in file_path or '\\test\\' in file_path:
            return True
        
        # Skip markdown files
        if file_path.endswith('.md'):
            return True
        
        # Skip Python files
        if file_path.endswith('.py'):
            return True
        
        return False
    
    def detect_log_level(self, content: str) -> str:
        """ตรวจจับ log level จากเนื้อหา"""
        content_lower = content.lower()
        
        # Check for error
        if any(indicator.lower() in content_lower for indicator in self.ERROR_INDICATORS):
            return 'error'
        
        # Check for warning
        if any(indicator.lower() in content_lower for indicator in self.WARNING_INDICATORS):
            return 'warning'
        
        # Check for success
        if any(indicator.lower() in content_lower for indicator in self.SUCCESS_INDICATORS):
            return 'success'
        
        # Check for info
        if any(indicator.lower() in content_lower for indicator in self.INFO_INDICATORS):
            return 'info'
        
        # Default to debug
        return 'debug'
    
    def has_applogger_import(self, content: str) -> bool:
        """เช็คว่ามี import AppLogger แล้วหรือยัง"""
        return "import 'package:dedecashier/core/logger/app_logger.dart'" in content
    
    def add_applogger_import(self, content: str) -> str:
        """เพิ่ม import AppLogger"""
        if self.has_applogger_import(content):
            return content
        
        # หา import block สุดท้าย
        import_pattern = re.compile(r"^import .+;$", re.MULTILINE)
        matches = list(import_pattern.finditer(content))
        
        if matches:
            # แทรกหลัง import สุดท้าย
            last_import = matches[-1]
            insert_pos = last_import.end()
            return (
                content[:insert_pos] +
                "\nimport 'package:dedecashier/core/logger/app_logger.dart';" +
                content[insert_pos:]
            )
        else:
            # ไม่มี import เลย แทรกที่ต้นไฟล์
            return "import 'package:dedecashier/core/logger/app_logger.dart';\n\n" + content
    
    def convert_print_statement(self, match: re.Match) -> str:
        """แปลง print() เป็น AppLogger"""
        full_match = match.group(0)
        indent = match.group(1)
        content = match.group(2)
        
        # ตรวจจับ log level
        log_level = self.detect_log_level(content)
        
        # สร้าง AppLogger call
        return f"{indent}AppLogger.{log_level}({content});"
    
    def process_file(self, file_path: str) -> bool:
        """ประมวลผลไฟล์เดียว - return True ถ้ามีการแก้ไข"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                original_content = f.read()
            
            modified_content = original_content
            changes_made = False
            
            # Pattern 1: Simple single-line print()
            # print('...');
            # print("...");
            pattern1 = re.compile(
                r'^(\s*)print\((.*?)\);$',
                re.MULTILINE
            )
            
            def replace_simple(match):
                nonlocal changes_made
                changes_made = True
                self.prints_converted += 1
                return self.convert_print_statement(match)
            
            modified_content = pattern1.sub(replace_simple, modified_content)
            
            # Pattern 2: Multi-line print() with proper closing
            # print(
            #   '...'
            # );
            pattern2 = re.compile(
                r'^(\s*)print\(\s*\n(.*?)\n\s*\);$',
                re.MULTILINE | re.DOTALL
            )
            
            def replace_multiline(match):
                nonlocal changes_made
                indent = match.group(1)
                content = match.group(2)
                
                # ตรวจจับ log level
                log_level = self.detect_log_level(content)
                
                changes_made = True
                self.prints_converted += 1
                
                return f"{indent}AppLogger.{log_level}(\n{content}\n{indent});"
            
            modified_content = pattern2.sub(replace_multiline, modified_content)
            
            # ถ้ามีการแก้ไข ให้เช็คและเพิ่ม import
            if changes_made:
                modified_content = self.add_applogger_import(modified_content)
                
                # เขียนกลับไปไฟล์
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(modified_content)
                
                return True
            
            return False
            
        except Exception as e:
            print(f"  ❌ Error processing {file_path}: {e}")
            return False
    
    def get_dart_files(self, directory: str) -> List[str]:
        """ค้นหาไฟล์ .dart ทั้งหมด"""
        dart_files = []
        for root, dirs, files in os.walk(directory):
            for file in files:
                if file.endswith('.dart'):
                    file_path = os.path.join(root, file)
                    if not self.should_skip_file(file_path):
                        dart_files.append(file_path)
        return dart_files
    
    def run(self, lib_dir: str):
        """รันการแปลง"""
        print(f"🔍 Found {len(self.get_dart_files(lib_dir))} Dart files to process...")
        print()
        
        dart_files = self.get_dart_files(lib_dir)
        
        for file_path in dart_files:
            self.files_processed += 1
            
            if self.process_file(file_path):
                self.files_modified += 1
                print(f"  ✅ Updated: {file_path}")
            
        print()
        print("=" * 60)
        print(f"✅ Conversion Complete!")
        print(f"   Files processed: {self.files_processed}")
        print(f"   Files modified: {self.files_modified}")
        print(f"   Print statements converted: {self.prints_converted}")
        print("=" * 60)

def main():
    print("🚀 Print-to-AppLogger Converter (Remaining)")
    print("=" * 60)
    print()
    
    # หา lib directory
    current_dir = Path(__file__).parent
    lib_dir = current_dir / 'lib'
    
    if not lib_dir.exists():
        print(f"❌ Error: lib directory not found at {lib_dir}")
        return
    
    # รันการแปลง
    converter = PrintToLoggerConverter()
    converter.run(str(lib_dir))

if __name__ == '__main__':
    main()
