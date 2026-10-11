#!/usr/bin/env bash
# ============================================================================
# Lawin Admin — ساخت نسخه‌ی release برای Linux و Android
#
# استفاده:
#   API_BASE_URL=https://<هاست-عمومی> ./tool/build_release.sh linux
#   API_BASE_URL=https://<هاست-عمومی> ./tool/build_release.sh android
#   API_BASE_URL=https://<هاست-عمومی> ./tool/build_release.sh all
#
# آدرس API هنگام Build تزریق می‌شود (هیچ آدرسی در کد hardcode نیست).
# ============================================================================
set -euo pipefail

TARGET="${1:-all}"
API_BASE_URL="${API_BASE_URL:-}"

if [[ -z "$API_BASE_URL" ]]; then
  echo "خطا: متغیر API_BASE_URL را تعیین کنید." >&2
  echo "مثال: API_BASE_URL=https://lawin.example.ts.net $0 $TARGET" >&2
  exit 2
fi

command -v flutter >/dev/null || { echo "flutter در PATH نیست." >&2; exit 2; }

echo "==> API_BASE_URL = $API_BASE_URL"
echo "==> flutter pub get"
flutter pub get

build_linux() {
  echo "==> ساخت Linux (release)"
  flutter build linux --release --dart-define=API_BASE_URL="$API_BASE_URL"
  echo "خروجی: build/linux/x64/release/bundle/"
}

build_android() {
  echo "==> ساخت Android APK (release)"
  flutter build apk --release --dart-define=API_BASE_URL="$API_BASE_URL"
  echo "خروجی: build/app/outputs/flutter-apk/app-release.apk"
}

case "$TARGET" in
  linux)   build_linux ;;
  android) build_android ;;
  all)     build_linux; build_android ;;
  *)       echo "هدف نامعتبر: $TARGET (linux|android|all)" >&2; exit 2 ;;
esac

echo "==> پایان ساخت."
