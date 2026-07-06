# Run this script in PowerShell to build and test the UAT web app

Write-Host "======================================================" -ForegroundColor Green
Write-Host "     SMLAI Cloud UAT Web Environment Build & Test     " -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green

# Configuration
$webPort = 8080
$targetFile = "lib/main_smlaiuat.dart"
$environment = "UAT"

# Set environment variables
$env:FLUTTER_WEB_PORT = $webPort

Write-Host "`nStep 1: Setting up environment..." -ForegroundColor Cyan
Write-Host "  • Web Port: $webPort"
Write-Host "  • Target: $targetFile"
Write-Host "  • Environment: $environment"

# Option to clean (uncomment if needed)
$cleanBuild = Read-Host "`nDo you want to clean previous builds? (y/n)"
if ($cleanBuild -eq "y") {
    Write-Host "`nCleaning previous builds..." -ForegroundColor Yellow
    flutter clean
}

# Build and run
Write-Host "`nStep 2: Building and running the application..." -ForegroundColor Cyan
flutter run -d chrome --web-port=$webPort --target=$targetFile

# When the app is running, we show this message
Write-Host "`nStep 3: Testing API endpoints" -ForegroundColor Cyan
Write-Host "  To test API endpoints, navigate to: http://localhost:$webPort/uat_api_test.html"
Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
