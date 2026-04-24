$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutterApp = Join-Path $projectRoot "flutter_app"

if (-not (Test-Path $flutterApp)) {
    throw "flutter_app folder not found at: $flutterApp"
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter SDK is not installed or not in PATH."
}

Set-Location $flutterApp

if (-not (Test-Path (Join-Path $flutterApp "android"))) {
    Write-Host "Android wrapper not found. Creating it now..."
    flutter create . --platforms=android
}

Write-Host "Installing Flutter dependencies..."
flutter pub get

if (-not (Test-Path (Join-Path $flutterApp "android\key.properties"))) {
    Write-Warning "android/key.properties was not found."
    Write-Warning "A debug or unsigned build may fail depending on your setup."
    Write-Warning "Create android/key.properties before building a signed release APK."
}

Write-Host "Building release APK..."
flutter build apk --release

$apkPath = Join-Path $flutterApp "build\app\outputs\flutter-apk\app-release.apk"

if (Test-Path $apkPath) {
    Write-Host ""
    Write-Host "APK created successfully:"
    Write-Host $apkPath
} else {
    throw "Build finished but app-release.apk was not found."
}
