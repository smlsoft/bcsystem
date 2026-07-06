# PowerShell script to migrate print statements to Logger
# DeDe Kiosk Performance Optimization

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "DeDe Kiosk - Print Statement Migration" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$files = @(
    "lib/global.dart",
    "lib/util/api.dart",
    "lib/main.dart",
    "lib/order/pay_creditcard_page.dart",
    "lib/order/pay_qr_payment_page.dart",
    "lib/order/pay_qr_edc_page.dart",
    "lib/print/print.dart",
    "lib/order/order_save.dart",
    "lib/util/check_payment.dart",
    "lib/util/print_queue.dart"
)

$totalFiles = 0
$totalChanges = 0

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Processing: $file" -ForegroundColor Yellow

        # Read file content
        $content = Get-Content $file -Raw
        $originalContent = $content

        # Add logger import if not present
        if ($content -notmatch "import 'package:dedekiosk/util/logger.dart';") {
            # Find last import
            $lines = $content -split "`n"
            $lastImportIdx = -1

            for ($i = 0; $i -lt $lines.Length; $i++) {
                if ($lines[$i] -match "^import\s+['\`"].*['\`"];") {
                    $lastImportIdx = $i
                }
            }

            if ($lastImportIdx -ge 0) {
                $lines = $lines[0..$lastImportIdx] + "import 'package:dedekiosk/util/logger.dart';" + $lines[($lastImportIdx + 1)..($lines.Length - 1)]
                $content = $lines -join "`n"
                Write-Host "  + Added logger import" -ForegroundColor Green
            }
        }

        # Pattern 1: if (kDebugMode) { print(msg); }
        $pattern1 = 'if\s*\(\s*kDebugMode\s*\)\s*\{\s*print\(([^)]+)\);\s*\}'
        $matches1 = [regex]::Matches($content, $pattern1)
        foreach ($match in $matches1) {
            $msg = $match.Groups[1].Value
            $replacement = "Logger.d($msg);"
            $content = $content.Replace($match.Value, $replacement)
        }

        # Pattern 2: if (kDebugMode) { print(e); print(s); }
        $pattern2 = 'if\s*\(\s*kDebugMode\s*\)\s*\{\s*print\((\w+)\);\s*print\((\w+)\);\s*\}'
        $matches2 = [regex]::Matches($content, $pattern2)
        foreach ($match in $matches2) {
            $e = $match.Groups[1].Value
            $s = $match.Groups[2].Value
            $replacement = "Logger.e('Error occurred', error: $e, stackTrace: $s);"
            $content = $content.Replace($match.Value, $replacement)
        }

        # Count changes
        if ($content -ne $originalContent) {
            # Create backup
            $backup = $file + ".bak"
            $originalContent | Set-Content $backup

            # Write updated content
            $content | Set-Content $file -NoNewline

            $changes = ($matches1.Count + $matches2.Count)
            Write-Host "  ✓ Updated: $changes patterns replaced" -ForegroundColor Green
            Write-Host "  ✓ Backup: $backup" -ForegroundColor Green
            $totalFiles++
            $totalChanges += $changes
        }
        else {
            Write-Host "  - No changes needed" -ForegroundColor Gray
        }

        Write-Host ""
    }
    else {
        Write-Host "Warning: $file not found" -ForegroundColor Red
    }
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Files updated: $totalFiles" -ForegroundColor Green
Write-Host "  Patterns replaced: $totalChanges" -ForegroundColor Green
Write-Host ""
Write-Host "Note: This is a basic migration script." -ForegroundColor Yellow
Write-Host "Some complex patterns may need manual review." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review changes in each file" -ForegroundColor White
Write-Host "  2. Run: flutter analyze" -ForegroundColor White
Write-Host "  3. Run: flutter run" -ForegroundColor White
Write-Host "  4. Delete .bak files if satisfied" -ForegroundColor White
Write-Host "=============================================" -ForegroundColor Cyan
