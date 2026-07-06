#!/usr/bin/env python3
"""
🔧 Advanced Print-to-AppLogger Converter
แปลง print() ทุกรูปแบบเป็น AppLogger โดยอัตโนมัติ

Features:
- รองรับ print() ทุกรูปแบบ (single line, multi-line, conditional)
- แยก log level จาก emoji และ prefix
- เพิ่ม import AppLogger อัตโนมัติ
- รองรับ if (kDebugMode) print()
- รักษา format เดิมไว้

Usage:
    python convert_all_prints_to_logger.py
"""

import re
import os
from pathlib import Path
from typing import Tuple, Optional


class PrintToLoggerConverter:
    """ตัวแปลง print() เป็น AppLogger ที่ชาญฉลาด"""
    
    # Emoji และ keyword ที่บ่งบอก log level
    ERROR_INDICATORS = ['❌', '🔴', 'Error', 'error', 'ERROR', 'failed', 'Failed', 'FAILED']
    WARNING_INDICATORS = ['⚠️', '🟡', 'Warning', 'warning', 'WARNING', 'Slow']
    SUCCESS_INDICATORS = ['✅', '🟢', 'Success', 'success', 'complete', 'Complete']
    INFO_INDICATORS = ['ℹ️', '📊', '📋', '🔵']
    
    def __init__(self):
        self.files_processed = 0
        self.files_modified = 0
        self.prints_converted = 0
    
    def detect_log_level(self, content: str) -> str:
        """ตรวจจับ log level จากเนื้อหา"""
        # Check for errors first
        for indicator in self.ERROR_INDICATORS:
            if indicator in content:
                return 'e'
        
        # Then warnings
        for indicator in self.WARNING_INDICATORS:
            if indicator in content:
                return 'w'
        
        # Then success
        for indicator in self.SUCCESS_INDICATORS:
            if indicator in content:
                return 'success'
        
        # Then info
        for indicator in self.INFO_INDICATORS:
            if indicator in content:
                return 'i'
        
        # Default to debug
        return 'd'
    
    def clean_print_content(self, content: str) -> str:
        """ทำความสะอาด content ของ print()"""
        # Remove common prefixes that are redundant with file:line
        patterns_to_remove = [
            r'\[PosScreen\]\s*',
            r'\[PosProcess\]\s*',
            r'\[PrintQueue\]\s*',
            r'\[Printer\]\s*',
            r'\[SyncBill\]\s*',
            r'\[FileCleanup\]\s*',
            r'\[PrintQueueTimer\]\s*',
            r'\[Bootstrap\]\s*',
            r'\[Login\]\s*',
            r'\[Performance\]\s*',
        ]
        
        for pattern in patterns_to_remove:
            content = re.sub(pattern, '', content)
        
        return content.strip()
    
    def convert_simple_print(self, match: re.Match) -> str:
        """แปลง print() แบบธรรมดา"""
        content = match.group(1)
        level = self.detect_log_level(content)
        # Clean content but keep emojis
        cleaned = self.clean_print_content(content)
        
        # Choose quote style based on original
        if '"' in match.group(0) and "'" not in content:
            return f'AppLogger.{level}(\'{cleaned}\');'
        else:
            # Keep original quotes
            original_quote = match.group(0)[match.group(0).index('print(') + 6]
            return f'AppLogger.{level}({original_quote}{cleaned}{original_quote});'
    
    def convert_kDebugMode_print(self, match: re.Match) -> str:
        """แปลง if (kDebugMode) print()"""
        content = match.group(1)
        level = self.detect_log_level(content)
        cleaned = self.clean_print_content(content)
        
        # Preserve original quote style
        if '"' in content and "'" not in content:
            return f'AppLogger.{level}(\'{cleaned}\');'
        else:
            original_quote = '"' if '"' in match.group(0).split('print(')[1][:2] else "'"
            return f'AppLogger.{level}({original_quote}{cleaned}{original_quote});'
    
    def convert_multiline_print(self, content: str) -> str:
        """แปลง print() ที่มีหลายบรรทัด (complex case)"""
        # Pattern: print( ... ); across multiple lines
        pattern = r'print\(\s*([\'"])(.+?)\1\s*\);'
        
        def replace_func(match):
            inner_content = match.group(2)
            level = self.detect_log_level(inner_content)
            cleaned = self.clean_print_content(inner_content)
            quote = match.group(1)
            return f'AppLogger.{level}({quote}{cleaned}{quote});'
        
        return re.sub(pattern, replace_func, content, flags=re.DOTALL)
    
    def process_content(self, content: str) -> Tuple[str, int]:
        """ประมวลผลเนื้อหาทั้งหมด"""
        original_content = content
        conversions = 0
        
        # Pattern 1: if (kDebugMode) { print('...'); }
        pattern1 = r"if\s*\(kDebugMode\)\s*\{\s*print\(['\"]([^'\"]+)['\"]\);\s*\}"
        matches = list(re.finditer(pattern1, content))
        for match in matches:
            replacement = self.convert_kDebugMode_print(match)
            content = content.replace(match.group(0), replacement)
            conversions += 1
        
        # Pattern 2: if (kDebugMode) print('...');
        pattern2 = r"if\s*\(kDebugMode\)\s+print\(['\"]([^'\"]+)['\"]\);"
        matches = list(re.finditer(pattern2, content))
        for match in matches:
            replacement = self.convert_kDebugMode_print(match)
            content = content.replace(match.group(0), replacement)
            conversions += 1
        
        # Pattern 3: Simple print('...'); or print("...");
        pattern3 = r"print\(['\"]([^'\"]+)['\"]\);"
        matches = list(re.finditer(pattern3, content))
        for match in matches:
            replacement = self.convert_simple_print(match)
            content = content.replace(match.group(0), replacement)
            conversions += 1
        
        # Pattern 4: Multi-line print (more complex)
        if 'print(' in content and conversions == 0:
            # Try to handle complex cases
            content = self.convert_multiline_print(content)
        
        return content, conversions
    
    def add_import_if_needed(self, content: str) -> str:
        """เพิ่ม import AppLogger ถ้ายังไม่มี"""
        if 'AppLogger' in content and 'app_logger.dart' not in content:
            # Find the last import statement
            import_pattern = r"(import\s+['\"].*?['\"]\s*;)"
            imports = list(re.finditer(import_pattern, content))
            
            if imports:
                last_import = imports[-1]
                insert_pos = last_import.end()
                new_import = "\nimport 'package:dedecashier/core/logger/app_logger.dart';"
                content = content[:insert_pos] + new_import + content[insert_pos:]
            else:
                # No imports found, add at the beginning after library/part declarations
                lines = content.split('\n')
                insert_line = 0
                for i, line in enumerate(lines):
                    if line.strip().startswith(('library', 'part of', '//')):
                        insert_line = i + 1
                    else:
                        break
                
                lines.insert(insert_line, "import 'package:dedecashier/core/logger/app_logger.dart';")
                content = '\n'.join(lines)
        
        return content
    
    def process_file(self, file_path: Path) -> bool:
        """ประมวลผลไฟล์เดียว"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Skip if no print statements
            if 'print(' not in content:
                return False
            
            # Convert prints
            new_content, conversions = self.process_content(content)
            
            # Skip if no changes
            if new_content == content:
                return False
            
            # Add import if needed
            new_content = self.add_import_if_needed(new_content)
            
            # Write back
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            
            self.prints_converted += conversions
            return True
            
        except Exception as e:
            print(f"  ❌ Error processing {file_path}: {e}")
            return False
    
    def process_directory(self, directory: Path):
        """ประมวลผล directory ทั้งหมด"""
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
        print("=" * 60)
        print(f"✅ Conversion Complete!")
        print(f"   Files processed: {self.files_processed}")
        print(f"   Files modified: {self.files_modified}")
        print(f"   Print statements converted: {self.prints_converted}")
        print("=" * 60)


def main():
    """Main entry point"""
    print("🚀 Print-to-AppLogger Converter")
    print("=" * 60)
    print()
    
    # Get project root (where this script is located)
    project_root = Path(__file__).parent
    lib_dir = project_root / 'lib'
    
    if not lib_dir.exists():
        print(f"❌ Error: lib directory not found at {lib_dir}")
        return
    
    converter = PrintToLoggerConverter()
    converter.process_directory(lib_dir)


if __name__ == '__main__':
    main()
