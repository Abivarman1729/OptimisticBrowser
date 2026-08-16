$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ToolsRoot = Join-Path $ProjectRoot ".toolchain"
$FlutterRoot = Join-Path $ToolsRoot "flutter"
$AndroidRoot = Join-Path $ToolsRoot "android-sdk"
$JavaRoot = Join-Path $ToolsRoot "jdk17"

$FlutterVersion = "3.44.6"
$FlutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.44.6-stable.zip"
$AndroidUrl = "https://dl.google.com/android/repository/commandlinetools-win-15859902_latest.zip"
$AndroidSha256 = "90ae805d20434428bffcb699c290860f19bb5f66a67e6b330067e3de801fb04a"
$TemurinApi = "https://api.adoptium.net/v3/assets/latest/17/hotspot?vendor=eclipse"

New-Item -ItemType Directory -Force -Path $ToolsRoot | Out-Null

function Download-File($Url, $Out) {
  Write-Host "Downloading $Url"
  Invoke-WebRequest -Uri $Url -OutFile $Out
}

function Ensure-Flutter {
  if (Test-Path (Join-Path $FlutterRoot "bin\flutter.bat")) { return }
  $zip = Join-Path $ToolsRoot "flutter-$FlutterVersion.zip"
  Download-File $FlutterUrl $zip
  Expand-Archive -Force $zip $ToolsRoot
  Remove-Item $zip -Force
}

function Ensure-Android {
  if (Test-Path (Join-Path $AndroidRoot "cmdline-tools\latest\bin\sdkmanager.bat")) { return }
  $zip = Join-Path $ToolsRoot "android-cli.zip"
  Download-File $AndroidUrl $zip
  $sha = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
  if ($sha -ne $AndroidSha256) { throw "Android CLI SHA-256 mismatch. Expected $AndroidSha256, got $sha." }
  $tmp = Join-Path $ToolsRoot "android-cli-tmp"
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  Expand-Archive -Force $zip $tmp
  New-Item -ItemType Directory -Force -Path (Join-Path $AndroidRoot "cmdline-tools\latest") | Out-Null
  Copy-Item (Join-Path $tmp "cmdline-tools\*") (Join-Path $AndroidRoot "cmdline-tools\latest") -Recurse -Force
  Remove-Item $tmp -Recurse -Force
  Remove-Item $zip -Force
}

function Ensure-Java {
  if (Test-Path (Join-Path $JavaRoot "bin\java.exe")) { return }
  $assets = Invoke-RestMethod $TemurinApi
  $asset = $assets | Where-Object { $_.binary.os -eq "windows" -and $_.binary.architecture -eq "x64" -and $_.binary.image_type -eq "jdk" } | Select-Object -First 1
  if (-not $asset) { throw "Could not locate a Temurin 17 Windows x64 JDK asset." }
  $zip = Join-Path $ToolsRoot "temurin17.zip"
  Download-File $asset.binary.package.link $zip
  $tmp = Join-Path $ToolsRoot "jdk-tmp"
  Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  Expand-Archive -Force $zip $tmp
  $dir = Get-ChildItem $tmp -Directory | Select-Object -First 1
  New-Item -ItemType Directory -Force -Path $JavaRoot | Out-Null
  Copy-Item "$($dir.FullName)\*" $JavaRoot -Recurse -Force
  Remove-Item $tmp -Recurse -Force
  Remove-Item $zip -Force
}

Ensure-Flutter
Ensure-Android
Ensure-Java

$env:JAVA_HOME = $JavaRoot
$env:ANDROID_HOME = $AndroidRoot
$env:ANDROID_SDK_ROOT = $AndroidRoot
$env:Path = "$(Join-Path $FlutterRoot 'bin');$(Join-Path $AndroidRoot 'cmdline-tools\latest\bin');$(Join-Path $AndroidRoot 'platform-tools');$(Join-Path $JavaRoot 'bin');$env:Path"

$flutter = Join-Path $FlutterRoot "bin\flutter.bat"
& $flutter --version
& $flutter config --no-analytics
& $flutter doctor --android-licenses
& (Join-Path $AndroidRoot "cmdline-tools\latest\bin\sdkmanager.bat") "platform-tools" "platforms;android-35" "build-tools;35.0.0"
& $flutter create --platforms=android,web,windows,linux,macos,ios --project-name optimistic_browser .
& $flutter pub get
& $flutter analyze
& $flutter test
& $flutter build apk --release

Write-Host "`nV6 bootstrap completed. APK: build\app\outputs\flutter-apk\app-release.apk"
