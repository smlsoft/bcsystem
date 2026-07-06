#!/usr/bin/env python3
"""
Script to replace print statements with Logger calls in DeDe Kiosk
This ensures logs only appear in debug mode, not in production
"""

import os
import re
import sys

# Files to process (high priority files first)
PRIORITY_FILES = [
    'lib/main.dart',
    'lib/global.dart',
    'lib/util/api.dart',
    'lib/order/pay_creditcard_page.dart',
    'lib/util/check_payment.dart',
    'lib/util/print_queue.dart',
]

def add_logger_import(content):
    """Add logger import if not present"""
    if "import 'package:dedekiosk/util/logger.dart';" in content:
        return content

    # Find the last import statement
    import_pattern = r"^import\s+['\"].*['\"];?\s*$"
    lines = content.split('\n')
    last_import_idx = -1

    for i, line in enumerate(lines):
        if re.match(import_pattern, line.strip()):
            last_import_idx = i

    if last_import_idx >= 0:
        # Insert logger import after last import
        lines.insert(last_import_idx + 1, "import 'package:dedekiosk/util/logger.dart';")
        return '\n'.join(lines)

    return content

def replace_prints(content):
    """Replace print statements with Logger calls"""
    changes = 0

    # Pattern 1: if (kDebugMode) { print(...); }
    pattern1 = r"if\s*\(\s*kDebugMode\s*\)\s*\{\s*print\((.*?)\);\s*\}"
    def repl1(match):
        nonlocal changes
        changes += 1
        msg = match.group(1).strip()
        return f"Logger.d({msg});"
    content = re.sub(pattern1, repl1, content, flags=re.DOTALL)

    # Pattern 2: print(...) inside if (kDebugMode) blocks
    pattern2 = r"if\s*\(\s*kDebugMode\s*\)\s*\{[^}]*?print\((.*?)\);[^}]*?\}"
    def repl2(match):
        nonlocal changes
        changes += 1
        msg = match.group(1).strip()
        block = match.group(0)
        # Replace just the print part
        return block.replace(f"print({msg});", f"Logger.d({msg});")
    content = re.sub(pattern2, repl2, content, flags=re.DOTALL)

    # Pattern 3: Standalone print(...) - wrap with Logger.d
    # This is more aggressive and might need manual review
    pattern3 = r"(?<!\/\/\s*)print\((.*?)\);"
    def repl3(match):
        nonlocal changes
        msg = match.group(1).strip()
        # Skip if already in a kDebugMode check (basic check)
        if 'kDebugMode' in msg:
            return match.group(0)
        changes += 1
        return f"Logger.d({msg});"

    # Only replace if not already Logger or debugPrint
    if 'Logger.' not in content.split('\n')[content.count('\n') // 2]:
        content = re.sub(pattern3, repl3, content)

    return content, changes

def process_file(filepath):
    """Process a single file"""
    print(f"Processing: {filepath}")

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content

        # Add logger import
        content = add_logger_import(content)

        # Replace print statements
        content, changes = replace_prints(content)

        if content != original_content:
            # Create backup
            backup_path = filepath + '.bak'
            with open(backup_path, 'w', encoding='utf-8') as f:
                f.write(original_content)

            # Write updated content
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)

            print(f"  ✓ Updated: {changes} print statements replaced")
            print(f"  ✓ Backup created: {backup_path}")
            return True, changes
        else:
            print(f"  - No changes needed")
            return False, 0

    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False, 0

def main():
    """Main function"""
    print("=" * 60)
    print("DeDe Kiosk - Replace print with Logger")
    print("=" * 60)
    print()

    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(base_dir)

    total_files = 0
    total_changes = 0

    print("Processing high-priority files...")
    print()

    for filepath in PRIORITY_FILES:
        if os.path.exists(filepath):
            updated, changes = process_file(filepath)
            if updated:
                total_files += 1
                total_changes += changes
        else:
            print(f"Warning: {filepath} not found")

    print()
    print("=" * 60)
    print(f"Summary:")
    print(f"  Files updated: {total_files}")
    print(f"  Total print statements replaced: {total_changes}")
    print()
    print("Note: This script only processed high-priority files.")
    print("To process all files, extend the PRIORITY_FILES list.")
    print()
    print("Backup files created with .bak extension.")
    print("Review changes and delete backups if satisfied.")
    print("=" * 60)

if __name__ == '__main__':
    main()
