#!/usr/bin/env python3
"""
สคริปต์สำหรับแทนที่ print() ด้วย AppLogger ใน Flutter project

Usage:
    python replace_print_with_logger.py
"""

import re
import os
from pathlib import Path


def replace_print_statements(content: str) -> str:
    """แทนที่ print() statements ด้วย AppLogger"""
    
    # Pattern 1: if (kDebugMode) { print('...'); }
    pattern1 = r"if \(kDebugMode\) \{\s*print\('([^']+)'\);\s*\}"
    content = re.sub(pattern1, r"AppLogger.d('\1');", content)
    
    # Pattern 2: if (kDebugMode) { print("..."); }
    pattern2 = r'if \(kDebugMode\) \{\s*print\("([^"]+)"\);\s*\}'
    content = re.sub(pattern2, r'AppLogger.d("\1");', content)
    
    # Pattern 3: print('[Level] message') → AppLogger
    replacements = [
        (r"print\('\[PosProcess\] ⚠️ ([^']+)'\);", r"AppLogger.w('\1');"),
        (r'print\("\[PosProcess\] ⚠️ ([^"]+)"\);', r'AppLogger.w("\1");'),
        (r"print\('\[PosProcess\] ❌ ([^']+)'\);", r"AppLogger.e('\1');"),
        (r'print\("\[PosProcess\] ❌ ([^"]+)"\);', r'AppLogger.e("\1");'),
        (r"print\('\[PosProcess\] ✅ ([^']+)'\);", r"AppLogger.success('\1');"),
        (r'print\("\[PosProcess\] ✅ ([^"]+)"\);', r'AppLogger.success("\1");'),
        (r"print\('\[PosProcess\] 🎯 ([^']+)'\);", r"AppLogger.d('🎯 \1');"),
        (r'print\("\[PosProcess\] 🎯 ([^"]+)"\);', r'AppLogger.d("🎯 \1");'),
        (r"print\('\[PosProcess\] 📊 ([^']+)'\);", r"AppLogger.d('📊 \1');"),
        (r'print\("\[PosProcess\] 📊 ([^"]+)"\);', r'AppLogger.d("📊 \1");'),
        (r"print\('\[PosProcess\] 🎟️ ([^']+)'\);", r"AppLogger.d('🎟️ \1');"),
        (r'print\("\[PosProcess\] 🎟️ ([^"]+)"\);', r'AppLogger.d("🎟️ \1");'),
        (r"print\('\[PosProcess\] ([^']+)'\);", r"AppLogger.d('\1');"),
        (r'print\("\[PosProcess\] ([^"]+)"\);', r'AppLogger.d("\1");'),
    ]
    
    for pattern, replacement in replacements:
        content = re.sub(pattern, replacement, content, flags=re.MULTILINE)
    
    # Pattern 4: Separators
    content = re.sub(
        r"print\('═+'\);",
        "// Separator",
        content
    )
    content = re.sub(
        r"print\('─+'\);",
        "// Separator",
        content
    )
    
    # Pattern 5: Generic print with kDebugMode
    pattern_generic = r"if \(kDebugMode\) \{\s*print\(([^;]+)\);\s*\}"
    content = re.sub(pattern_generic, r"AppLogger.d(\1);", content, flags=re.MULTILINE)
    
    return content


def process_file(file_path: Path):
    """ประมวลผลไฟล์เดียว"""
    print(f"Processing: {file_path}")
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Replace print statements
        content = replace_print_statements(content)
        
        # Add import if needed and not exists
        if 'AppLogger' in content and 'app_logger.dart' not in content:
            # Find import section
            import_pattern = r"(import 'package:dedecashier/core/core.dart';)"
            replacement = r"\1\nimport 'package:dedecashier/core/logger/app_logger.dart';"
            content = re.sub(import_pattern, replacement, content)
        
        # Write back only if changed
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"  ✅ Updated: {file_path}")
            return True
        else:
            print(f"  ⏭️  No changes: {file_path}")
            return False
            
    except Exception as e:
        print(f"  ❌ Error: {e}")
        return False


def main():
    """Main function"""
    project_root = Path(__file__).parent
    lib_path = project_root / 'lib'
    
    if not lib_path.exists():
        print(f"❌ lib folder not found: {lib_path}")
        return
    
    print("🔍 Scanning Dart files...")
    
    # Find all .dart files
    dart_files = list(lib_path.rglob('*.dart'))
    print(f"Found {len(dart_files)} Dart files")
    
    # Process each file
    updated_count = 0
    for dart_file in dart_files:
        # Skip generated files
        if '.g.dart' in str(dart_file) or '.freezed.dart' in str(dart_file):
            continue
        
        # Skip logger files themselves
        if 'logger' in str(dart_file).lower():
            continue
        
        if process_file(dart_file):
            updated_count += 1
    
    print(f"\n✅ Completed!")
    print(f"   Updated: {updated_count} files")
    print(f"   Total: {len(dart_files)} files")


if __name__ == '__main__':
    main()
