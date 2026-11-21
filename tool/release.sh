#!/usr/bin/env bash
# Подписанные AAB и APK + загрузка символов Dart в Crashlytics.
set -euo pipefail
cd "$(dirname "$0")/.."
APP_ID=1:742800135927:android:0e29462a54f8a98e0465f2

[ -f android/key.properties ] || { echo "Нет android/key.properties — см. README, раздел «Релиз»" >&2; exit 1; }

flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
flutter build apk --release --obfuscate --split-debug-info=build/symbols
firebase crashlytics:symbols:upload --app="$APP_ID" build/symbols

echo "AAB: build/app/outputs/bundle/release/app-release.aab"
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
