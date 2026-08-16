#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_ROOT="$PROJECT_ROOT/.toolchain"
FLUTTER_VERSION="3.44.6"
FLUTTER_ROOT="$TOOLS_ROOT/flutter"
ANDROID_ROOT="$TOOLS_ROOT/android-sdk"
JAVA_ROOT="$TOOLS_ROOT/jdk17"

mkdir -p "$TOOLS_ROOT"

OS="$(uname -s)"
ARCH="$(uname -m)"

if [[ "$OS" == "Linux" ]]; then
  FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  ANDROID_URL="https://dl.google.com/android/repository/commandlinetools-linux-15859902_latest.zip"
  JAVA_OS="linux"
  FLUTTER_ARCHIVE="$TOOLS_ROOT/flutter.tar.xz"
elif [[ "$OS" == "Darwin" ]]; then
  if [[ "$ARCH" == "arm64" ]]; then
    FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_${FLUTTER_VERSION}-stable.zip"
    JAVA_ARCH="aarch64"
  else
    FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_${FLUTTER_VERSION}-stable.zip"
    JAVA_ARCH="x64"
  fi
  ANDROID_URL="https://dl.google.com/android/repository/commandlinetools-mac_${ARCH}-15859902_latest.zip"
  JAVA_OS="mac"
  FLUTTER_ARCHIVE="$TOOLS_ROOT/flutter.zip"
else
  echo "Unsupported OS: $OS"; exit 1
fi

download() { curl -fL --retry 3 --retry-delay 2 "$1" -o "$2"; }

if [[ ! -x "$FLUTTER_ROOT/bin/flutter" ]]; then
  download "$FLUTTER_URL" "$FLUTTER_ARCHIVE"
  if [[ "$FLUTTER_ARCHIVE" == *.zip ]]; then unzip -q "$FLUTTER_ARCHIVE" -d "$TOOLS_ROOT"; else tar -xf "$FLUTTER_ARCHIVE" -C "$TOOLS_ROOT"; fi
  rm -f "$FLUTTER_ARCHIVE"
fi

if [[ ! -x "$ANDROID_ROOT/cmdline-tools/latest/bin/sdkmanager" ]]; then
  download "$ANDROID_URL" "$TOOLS_ROOT/android-cli.zip"
  mkdir -p "$ANDROID_ROOT/cmdline-tools/latest"
  unzip -q "$TOOLS_ROOT/android-cli.zip" -d "$TOOLS_ROOT/android-cli-tmp"
  cp -R "$TOOLS_ROOT/android-cli-tmp/cmdline-tools/"* "$ANDROID_ROOT/cmdline-tools/latest/"
  rm -rf "$TOOLS_ROOT/android-cli.zip" "$TOOLS_ROOT/android-cli-tmp"
fi

if [[ ! -x "$JAVA_ROOT/bin/java" ]]; then
  if command -v brew >/dev/null 2>&1 && [[ "$OS" == "Darwin" ]]; then
    brew install --cask temurin@17 || true
    JAVA_HOME="$(/usr/libexec/java_home -v 17)"
    ln -s "$JAVA_HOME" "$JAVA_ROOT" 2>/dev/null || true
  else
    echo "Temurin 17 is required. Install it from Adoptium, then rerun this script."
    exit 2
  fi
fi

export JAVA_HOME="$JAVA_ROOT"
export ANDROID_HOME="$ANDROID_ROOT"
export ANDROID_SDK_ROOT="$ANDROID_ROOT"
export PATH="$FLUTTER_ROOT/bin:$ANDROID_ROOT/cmdline-tools/latest/bin:$ANDROID_ROOT/platform-tools:$JAVA_ROOT/bin:$PATH"

"$FLUTTER_ROOT/bin/flutter" --version
"$FLUTTER_ROOT/bin/flutter" config --no-analytics
yes | "$ANDROID_ROOT/cmdline-tools/latest/bin/sdkmanager" --licenses >/dev/null || true
"$ANDROID_ROOT/cmdline-tools/latest/bin/sdkmanager" "platform-tools" "platforms;android-35" "build-tools;35.0.0"
"$FLUTTER_ROOT/bin/flutter" create --platforms=android,web,windows,linux,macos,ios --project-name optimistic_browser .
"$FLUTTER_ROOT/bin/flutter" pub get
"$FLUTTER_ROOT/bin/flutter" analyze
"$FLUTTER_ROOT/bin/flutter" test
"$FLUTTER_ROOT/bin/flutter" build apk --release

echo
echo "V6 bootstrap completed. APK: build/app/outputs/flutter-apk/app-release.apk"
