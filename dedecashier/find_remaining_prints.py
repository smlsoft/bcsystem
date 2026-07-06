#!/usr/bin/env python3
"""
Find remaining print() statements that were not converted to AppLogger
"""

import os
import re

def find_print_statements(filepath):
    """Find print statements in a file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        found_prints = []
        for line_num, line in enumerate(lines, 1):
            # Skip comments
            if line.strip().startswith('//'):
                continue
            
            # Find print() statements (not in comments)
            if 'print(' in line and 'AppLogger.' not in line:
                # Check if it's not in a comment
                code_part = line.split('//')[0]
                if 'print(' in code_part:
                    found_prints.append({
                        'line': line_num,
                        'content': line.strip()
                    })
        
        return found_prints
    except Exception as e:
        return None

def main():
    root_dir = os.path.dirname(os.path.abspath(__file__))
    lib_dir = os.path.join(root_dir, 'lib')
    
    print("🔍 Searching for remaining print() statements...\n")
    
    dart_files = []
    for root, dirs, files in os.walk(lib_dir):
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        for file in files:
            if file.endswith('.dart') and not file.endswith('.g.dart'):
                dart_files.append(os.path.join(root, file))
    
    files_with_prints = []
    total_prints = 0
    
    for filepath in dart_files:
        prints = find_print_statements(filepath)
        if prints:
            rel_path = os.path.relpath(filepath, lib_dir)
            files_with_prints.append({
                'path': rel_path,
                'prints': prints
            })
            total_prints += len(prints)
    
    if files_with_prints:
        print(f"📄 Found {total_prints} print() statements in {len(files_with_prints)} files:\n")
        
        for file_info in sorted(files_with_prints, key=lambda x: len(x['prints']), reverse=True):
            print(f"📁 {file_info['path']} - {len(file_info['prints'])} print(s)")
            for p in file_info['prints'][:5]:  # Show first 5
                print(f"   Line {p['line']}: {p['content'][:80]}")
            if len(file_info['prints']) > 5:
                print(f"   ... and {len(file_info['prints']) - 5} more")
            print()
    else:
        print("✅ No print() statements found! All converted to AppLogger.")
    
    print(f"\n📊 Summary:")
    print(f"   Total files scanned: {len(dart_files)}")
    print(f"   Files with print(): {len(files_with_prints)}")
    print(f"   Total print() found: {total_prints}")

if __name__ == '__main__':
    main()
