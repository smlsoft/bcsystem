#!/usr/bin/env python3
"""
Fix missing AppLogger imports in Dart files
"""

import os
import re

# Import statement to add
IMPORT_STATEMENT = "import 'package:dedecashier/core/logger/app_logger.dart';"

def has_app_logger_usage(content):
    """Check if file uses AppLogger"""
    return 'AppLogger.' in content

def has_app_logger_import(content):
    """Check if file already has AppLogger import"""
    return 'app_logger.dart' in content

def add_import_after_last_import(content):
    """Add import statement after the last import"""
    lines = content.split('\n')
    last_import_idx = -1
    
    # Find the last import statement
    for i, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith('import '):
            last_import_idx = i
    
    if last_import_idx >= 0:
        # Insert after the last import
        lines.insert(last_import_idx + 1, IMPORT_STATEMENT)
        return '\n'.join(lines)
    else:
        # No imports found, add at the top (after comments if any)
        first_code_line = 0
        for i, line in enumerate(lines):
            stripped = line.strip()
            if stripped and not stripped.startswith('//') and not stripped.startswith('/*') and not stripped.startswith('*'):
                first_code_line = i
                break
        lines.insert(first_code_line, IMPORT_STATEMENT)
        return '\n'.join(lines)

def process_file(filepath):
    """Process a single file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Check if file uses AppLogger but doesn't have the import
        if has_app_logger_usage(content) and not has_app_logger_import(content):
            print(f"  ✅ Adding import: {filepath}")
            new_content = add_import_after_last_import(content)
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            
            return True
        else:
            return False
            
    except Exception as e:
        print(f"  ❌ Error processing {filepath}: {e}")
        return False

def main():
    root_dir = os.path.dirname(os.path.abspath(__file__))
    lib_dir = os.path.join(root_dir, 'lib')
    
    print("🔍 Scanning for files with missing AppLogger imports...")
    
    dart_files = []
    for root, dirs, files in os.walk(lib_dir):
        # Skip generated files
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        
        for file in files:
            if file.endswith('.dart') and not file.endswith('.g.dart') and not file.endswith('.freezed.dart'):
                dart_files.append(os.path.join(root, file))
    
    print(f"Found {len(dart_files)} Dart files\n")
    
    updated_count = 0
    for filepath in dart_files:
        if process_file(filepath):
            updated_count += 1
    
    print(f"\n✅ Completed!")
    print(f"   Updated: {updated_count} files")
    print(f"   Total: {len(dart_files)} files")

if __name__ == '__main__':
    main()
