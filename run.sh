#!/bin/zsh
set -euo pipefail
cd "${0:A:h}"

ENVIRONMENT="${1:-Test}"
case "$ENVIRONMENT" in
  Test) CONFIGURATION=Debug ;;
  Production) CONFIGURATION=Release ;;
  *) echo "Usage: ./run.sh [Test|Production]" >&2; exit 1 ;;
esac

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
SIMULATOR="${SIMULATOR:-iPhone 17}"
EXTRA_SETTINGS=()
[[ -n "${VERSION:-}" ]] && EXTRA_SETTINGS+=("MARKETING_VERSION=$VERSION")
[[ -n "${BUILD:-}" ]] && EXTRA_SETTINGS+=("CURRENT_PROJECT_VERSION=$BUILD")

xcrun simctl boot "$SIMULATOR" 2>/dev/null || true
open "$DEVELOPER_DIR/Applications/Simulator.app"

xcodebuild -quiet \
  -project PulsePair.xcodeproj \
  -scheme PulsePair \
  -configuration "$CONFIGURATION" \
  -destination "platform=iOS Simulator,name=$SIMULATOR" \
  -derivedDataPath build \
  PULSEPAIR_ENV="$ENVIRONMENT" "${EXTRA_SETTINGS[@]}" \
  build

PRODUCTS="build/Build/Products/$CONFIGURATION-iphonesimulator"
xcrun simctl install "$SIMULATOR" "$PRODUCTS/PulsePair.app"
xcrun simctl launch --terminate-running-process "$SIMULATOR" com.pulsepair.companion
echo "dSYM: $PWD/$PRODUCTS/PulsePair.app.dSYM"
