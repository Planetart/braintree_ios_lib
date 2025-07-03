#!/bin/bash

# Script to zip individual XCFrameworks extracted from Braintree.xcframework.zip
# These zips can then be used in Package.swift with url: "file:/path/to/zip" and checksum

set -e

FRAMEWORKS_DIR="./Frameworks/Carthage/Build"
XCFRAMEWORKS_DIR="./Frameworks/XCFrameworks"
OUTPUT_DIR="./XCFrameworkZips"

# Create the output directory
mkdir -p $OUTPUT_DIR

# List of frameworks to zip from Carthage/Build
FRAMEWORKS=(
    "BraintreeAmericanExpress"
    "BraintreeApplePay"
    "BraintreeCard"
    "BraintreeCore"
    "BraintreeDataCollector"
    "BraintreeLocalPayment"
    "BraintreePayPal"
    "BraintreePayPalMessaging"
    "BraintreePayPalNativeCheckout"
    "BraintreeSEPADirectDebit"
    "BraintreeShopperInsights"
    "BraintreeThreeDSecure"
    "BraintreeVenmo"
)

# Additional frameworks from XCFrameworks directory
ADDITIONAL_FRAMEWORKS=(
    "CardinalMobile"
    "PPRiskMagnes"
)

# Check if frameworks directory exists
if [ ! -d "$FRAMEWORKS_DIR" ]; then
    echo "Error: $FRAMEWORKS_DIR does not exist."
    echo "Please run ./update-framework.sh first to extract the frameworks."
    exit 1
fi

# Zip each framework from Carthage/Build and calculate checksum
for framework in "${FRAMEWORKS[@]}"; do
    echo "Zipping $framework.xcframework..."
    
    # Check if the framework exists
    if [ ! -d "$FRAMEWORKS_DIR/$framework.xcframework" ]; then
        echo "Warning: $framework.xcframework not found. Skipping..."
        continue
    fi
    
    # Remove any existing zip
    rm -f "$OUTPUT_DIR/$framework.xcframework.zip"
    
    # Create the zip
    zip -r "$OUTPUT_DIR/$framework.xcframework.zip" "$FRAMEWORKS_DIR/$framework.xcframework"
    
    # Calculate checksum (SHA-256)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        CHECKSUM=$(shasum -a 256 "$OUTPUT_DIR/$framework.xcframework.zip" | awk '{print $1}')
    else
        CHECKSUM=$(sha256sum "$OUTPUT_DIR/$framework.xcframework.zip" | awk '{print $1}')
    fi
    
    echo "$framework.xcframework.zip checksum: $CHECKSUM"
    echo "$framework.xcframework.zip: $CHECKSUM" >> "$OUTPUT_DIR/checksums.txt"
done

# Zip each additional framework from XCFrameworks directory
for framework in "${ADDITIONAL_FRAMEWORKS[@]}"; do
    echo "Zipping $framework.xcframework..."
    
    # Check if the framework exists
    if [ ! -d "$XCFRAMEWORKS_DIR/$framework.xcframework" ]; then
        echo "Warning: $XCFRAMEWORKS_DIR/$framework.xcframework not found. Skipping..."
        continue
    fi
    
    # Remove any existing zip
    rm -f "$OUTPUT_DIR/$framework.xcframework.zip"
    
    # Create the zip
    zip -r "$OUTPUT_DIR/$framework.xcframework.zip" "$XCFRAMEWORKS_DIR/$framework.xcframework"
    
    # Calculate checksum (SHA-256)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        CHECKSUM=$(shasum -a 256 "$OUTPUT_DIR/$framework.xcframework.zip" | awk '{print $1}')
    else
        CHECKSUM=$(sha256sum "$OUTPUT_DIR/$framework.xcframework.zip" | awk '{print $1}')
    fi
    
    echo "$framework.xcframework.zip checksum: $CHECKSUM"
    echo "$framework.xcframework.zip: $CHECKSUM" >> "$OUTPUT_DIR/checksums.txt"
done

echo "Done! All frameworks have been zipped to $OUTPUT_DIR"
echo "Checksums have been saved to $OUTPUT_DIR/checksums.txt" 