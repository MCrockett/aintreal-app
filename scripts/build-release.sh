#!/bin/bash
# Build release AAB and clean up intermediate files
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
FLUTTER=~/Library/flutter/bin/flutter
OUTPUT_DIR="$PROJECT_DIR/release"

cd "$PROJECT_DIR"

echo "Building release AAB..."
$FLUTTER build appbundle --release

# Copy AAB to release directory
mkdir -p "$OUTPUT_DIR"
AAB_PATH="$PROJECT_DIR/build/app/outputs/bundle/release/app-release.aab"
if [ -f "$AAB_PATH" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    cp "$AAB_PATH" "$OUTPUT_DIR/aintreal-$TIMESTAMP.aab"
    echo "AAB copied to: $OUTPUT_DIR/aintreal-$TIMESTAMP.aab"
fi

# Clean up intermediate files (keeps the AAB)
echo "Cleaning up build intermediates..."
rm -rf "$PROJECT_DIR/build/app/intermediates"
rm -rf "$PROJECT_DIR/build/app/.transforms"
rm -rf "$PROJECT_DIR/build/app/generated"
rm -rf "$PROJECT_DIR/build/kotlin"
rm -rf "$PROJECT_DIR/build/.transforms"

# Show final size
echo ""
echo "Build complete!"
du -sh "$PROJECT_DIR/build/" 2>/dev/null || true
ls -lh "$OUTPUT_DIR"/*.aab 2>/dev/null | tail -3
