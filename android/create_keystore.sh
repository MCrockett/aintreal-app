#!/bin/bash
# Create upload keystore for Google Play Store
# Run this script from the android directory

KEYSTORE_FILE="upload-keystore.jks"

if [ -f "$KEYSTORE_FILE" ]; then
    echo "Keystore already exists: $KEYSTORE_FILE"
    echo "Delete it first if you want to create a new one."
    exit 1
fi

echo "Creating upload keystore for AIn't Real..."
echo "You will be prompted for:"
echo "  1. Keystore password (enter twice)"
echo "  2. Key password (press Enter to use same as keystore)"
echo "  3. Your name, organization, etc. (can press Enter for defaults)"
echo ""

keytool -genkey -v \
    -keystore "$KEYSTORE_FILE" \
    -storetype JKS \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias upload

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Keystore created: $KEYSTORE_FILE"
    echo ""
    echo "IMPORTANT: Save this information securely!"
    echo "  - Keystore file: android/$KEYSTORE_FILE"
    echo "  - Key alias: upload"
    echo "  - Remember your passwords!"
    echo ""
    echo "Now create android/key.properties with:"
    echo "  storePassword=YOUR_PASSWORD"
    echo "  keyPassword=YOUR_PASSWORD"
    echo "  keyAlias=upload"
    echo "  storeFile=upload-keystore.jks"
else
    echo "Failed to create keystore"
    exit 1
fi
