#!/usr/bin/env bash
set -e
echo "==================================================="
echo "  JARVIS PRO (HINDI + ENGLISH) - APK BUILDER"
echo "==================================================="
flutter create --platforms=android --org com.topg.jarvis .
flutter pub get
flutter build apk --release
echo ""
echo "[DONE, TOPG!] Your installable Android APK is ready at:"
echo "build/app/outputs/flutter-apk/app-release.apk"
