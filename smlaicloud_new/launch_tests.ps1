# Run this script in PowerShell to access all testing options

function Show-Menu {
    Clear-Host
    Write-Host "======================================================" -ForegroundColor Green
    Write-Host "           SMLAI Cloud Testing Launcher               " -ForegroundColor Green
    Write-Host "======================================================" -ForegroundColor Green
    Write-Host
    Write-Host "Select an option:" -ForegroundColor Cyan
    Write-Host
    Write-Host "  1: Run UAT in Web Browser (Chrome)"
    Write-Host "  2: Run UAT API Tests Only"
    Write-Host "  3: Build Web Release (Production)"
    Write-Host "  4: Run in Windows Desktop Mode"
    Write-Host
    Write-Host "  Q: Quit"
    Write-Host
}

function Run-UatWeb {
    & .\test_uat_web.ps1
}

function Run-ApiTests {
    Start-Process chrome "http://localhost:8080/uat_api_test.html"
    Write-Host "API test page opened in Chrome. Make sure the app is running on port 8080."
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Build-WebRelease {
    Write-Host "Building web release version..." -ForegroundColor Yellow
    flutter clean
    flutter build web --release --web-renderer html
    Write-Host "Build complete! Files are in build/web directory."
    Write-Host "Press any key to continue..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Run-WindowsDesktop {
    Write-Host "Running in Windows Desktop mode..." -ForegroundColor Yellow
    flutter run -d windows --target=lib/main_smlaiuat.dart
}

do {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    
    switch ($selection) {
        '1' { Run-UatWeb }
        '2' { Run-ApiTests }
        '3' { Build-WebRelease }
        '4' { Run-WindowsDesktop }
    }
} until ($selection -eq 'q')
