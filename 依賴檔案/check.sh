#!/usr/bin/env bash
# Fast pre-build gate for TimeFlow.
#
# Catches problems WITHOUT the full/slow build pipeline:
#   1. compileKotlinJs  - verifies commonMain + jsMain compile (no webpack/node)
#   2. jvmTest          - runs the commonTest unit suite on the JVM (logic bugs!)
#   3. detekt           - static analysis (style/unused/etc.)
#   4. compileDebugKotlinAndroid - optional, only when a real Android SDK exists
#
# Usage:
#   ./scripts/check.sh                                   # 1-3
#   ANDROID_HOME=<sdk> ./scripts/check.sh                # 1-4

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> [1/4] Kotlin compile check (JS target)"
./gradlew :composeApp:compileKotlinJs

echo "==> [2/4] Unit tests (JVM target) - catches logic bugs"
./gradlew :composeApp:jvmTest

echo "==> [3/4] Static analysis (detekt)"
./gradlew :composeApp:detekt

if [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME/platforms" ]; then
    echo "==> [4/4] Kotlin compile check (Android target)"
    ./gradlew :composeApp:compileDebugKotlinAndroid
else
    echo "!! ANDROID_HOME not set or no platforms installed - skipping Android compile."
fi

echo "==> All checks passed."
