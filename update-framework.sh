#!/bin/bash

# Script to manually update the Braintree XCFramework in this SPM package
# Usage: ./update-framework.sh [version] [--force]
# If no version is provided, it will fetch the latest release version
# Use --force to regenerate zips even if the version hasn't changed

set -e

# Function to fetch latest release version
fetch_latest_version() {
    local api_url="https://api.github.com/repos/braintree/braintree_ios/releases/latest"
    local latest_version
    
    if command -v curl &> /dev/null; then
        latest_version=$(curl -s "$api_url" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    elif command -v wget &> /dev/null; then
        latest_version=$(wget -qO- "$api_url" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    else
        echo "Error: Neither curl nor wget found. Please install one of them or specify version manually."
        exit 1
    fi
    
    if [ -z "$latest_version" ]; then
        echo "Error: Failed to fetch latest version. Please specify version manually."
        exit 1
    fi
    
    echo "$latest_version"
}

# Get version from argument or fetch latest
if [ -n "$1" ] && [ "$1" != "--force" ]; then
    BRAINTREE_VERSION="$1"
else
    echo "No version specified. Fetching latest release version..."
    BRAINTREE_VERSION=$(fetch_latest_version)
    echo "Latest version: $BRAINTREE_VERSION"
fi

FORCE_REGENERATE=false
if [ "$2" = "--force" ] || [ "$1" = "--force" ]; then
    FORCE_REGENERATE=true
fi

BRAINTREE_URL="https://github.com/braintree/braintree_ios/releases/download/$BRAINTREE_VERSION/Braintree.xcframework.zip"
XCFRAMEWORK_DIR="./Frameworks"
TEMP_DIR="./temp"
ZIP_DIR="./XCFrameworkZips"

# Function to extract PayPal framework configurations
extract_paypal_config() {
    local package_file="$1"
    local framework_name="$2"
    
    # Extract version, url and checksum for the framework
    local version=$(grep -A 5 "\"$framework_name\"" "$package_file" | grep "from:" | grep -o '".*"' | tr -d '"')
    local url=$(grep -A 5 "\"$framework_name\"" "$package_file" | grep "url:" | grep -o '".*"' | tr -d '"')
    local checksum=$(grep -A 5 "\"$framework_name\"" "$package_file" | grep "checksum:" | grep -o '".*"' | tr -d '"')
    
    echo "$version|$url|$checksum"
}

echo "Requested Braintree SDK version: $BRAINTREE_VERSION"

# Create directories if they don't exist
mkdir -p $XCFRAMEWORK_DIR $TEMP_DIR $ZIP_DIR

# Check if version has changed
CURRENT_VERSION=""
VERSION_CHANGED=false
if [ -f "package.json" ]; then
    if command -v node &> /dev/null; then
        CURRENT_VERSION=$(node -e "try { const pkg = require('./package.json'); console.log(pkg.braintree?.version || ''); } catch(e) { console.log(''); }")
    else
        # Fallback to grep if node is not available
        CURRENT_VERSION=$(grep -o '"version": "[^"]*"' package.json | head -1 | cut -d'"' -f4)
    fi
fi

if [ "$CURRENT_VERSION" != "$BRAINTREE_VERSION" ]; then
    VERSION_CHANGED=true
    echo "Version changed from $CURRENT_VERSION to $BRAINTREE_VERSION"
fi

# Check if zips exist first
NEED_REGENERATE=false
MISSING_ZIPS=false
for framework in "${FRAMEWORKS[@]}"; do
    if [ ! -f "$ZIP_DIR/$framework.xcframework.zip" ]; then
        MISSING_ZIPS=true
        echo "Missing zip file: $framework.xcframework.zip"
    fi
done

for framework in "${ADDITIONAL_FRAMEWORKS[@]}"; do
    if [ ! -f "$ZIP_DIR/$framework.xcframework.zip" ]; then
        MISSING_ZIPS=true
        echo "Missing zip file: $framework.xcframework.zip"
    fi
done

if [ "$MISSING_ZIPS" = true ]; then
    echo "Some framework zips are missing. Will regenerate all zips."
    NEED_REGENERATE=true
fi

# Only check version and force flag if we don't need to regenerate due to missing files
if [ "$NEED_REGENERATE" = false ] && [ "$VERSION_CHANGED" = false ] && [ "$FORCE_REGENERATE" = false ]; then
    echo "Current version is already $BRAINTREE_VERSION."
    
    # Use existing checksums from package.json
    if command -v node &> /dev/null; then
        EXISTING_CHECKSUMS_JSON=$(node -e "try { const pkg = require('./package.json'); console.log(JSON.stringify(pkg.braintree?.frameworks || [])); } catch(e) { console.log('[]'); }")
        MAIN_CHECKSUM=$(node -e "try { const pkg = require('./package.json'); console.log(pkg.braintree?.mainChecksum || ''); } catch(e) { console.log(''); }")
        
        # Check if we have valid existing checksums
        if [ "$EXISTING_CHECKSUMS_JSON" != "[]" ] && [ -n "$MAIN_CHECKSUM" ]; then
            echo "Using existing framework zips and checksums."
        else
            NEED_REGENERATE=true
        fi
    fi
else
    NEED_REGENERATE=true
fi

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

# Download source code once and use it for both PrivacyInfo and framework generation
echo "Downloading Braintree source code..."
temp_zip="$TEMP_DIR/braintree_source.zip"
temp_src="$TEMP_DIR/braintree_src"
source_url="https://github.com/braintree/braintree_ios/archive/refs/tags/$BRAINTREE_VERSION.zip"

echo "Downloading from $source_url"
curl -L "$source_url" -o "$temp_zip"

echo "Extracting source code..."
rm -rf "$temp_src"
mkdir -p "$temp_src"
unzip -q "$temp_zip" -d "$temp_src"

# The extracted folder will be named braintree_ios-{version}
src_dir="$temp_src/braintree_ios-$BRAINTREE_VERSION"
workspace_dir="$PWD"

# Copy entire Sources directory
echo "Copying source files..."
rm -rf "$workspace_dir/Sources"
mkdir -p "$workspace_dir/Sources"
cp -R "$src_dir/Sources/"* "$workspace_dir/Sources/"
echo "✅ Copied all source files"

# Copy XCFrameworks directory
echo "Copying XCFrameworks directory..."
rm -rf "$workspace_dir/Frameworks/XCFrameworks"
mkdir -p "$workspace_dir/Frameworks"
if [ -d "$src_dir/Frameworks/XCFrameworks" ]; then
    cp -R "$src_dir/Frameworks/XCFrameworks" "$workspace_dir/Frameworks/"
    echo "✅ Copied XCFrameworks directory"
else
    echo "Warning: XCFrameworks directory not found in source code"
fi

# Update Package-original.swift from source code
echo "Updating Package-original.swift..."
if [ -f "$src_dir/Package.swift" ]; then
    cp "$src_dir/Package.swift" "$workspace_dir/Package-original.swift"
    echo "✅ Updated Package-original.swift from source code"
    
    # Extract PayPal frameworks configuration
    echo "Extracting PayPal frameworks configuration..."
    
    # Extract PayPalMessages config
    PAYPAL_MESSAGES_CONFIG=$(extract_paypal_config "$workspace_dir/Package-original.swift" "PayPalMessages")
    PAYPAL_MESSAGES_URL=$(echo "$PAYPAL_MESSAGES_CONFIG" | cut -d'|' -f2)
    PAYPAL_MESSAGES_CHECKSUM=$(echo "$PAYPAL_MESSAGES_CONFIG" | cut -d'|' -f3)
    
    # Extract PayPalCheckout config
    PAYPAL_CHECKOUT_CONFIG=$(extract_paypal_config "$workspace_dir/Package-original.swift" "PayPalCheckout")
    PAYPAL_CHECKOUT_URL=$(echo "$PAYPAL_CHECKOUT_CONFIG" | cut -d'|' -f2)
    PAYPAL_CHECKOUT_CHECKSUM=$(echo "$PAYPAL_CHECKOUT_CONFIG" | cut -d'|' -f3)
    
    echo "✅ Extracted PayPal frameworks configuration"
    
    # Update products section in Package.swift
    echo "Updating products in Package.swift..."
    
    # Create temporary files
    temp_products="$workspace_dir/products.tmp"
    temp_package="$workspace_dir/Package.swift.tmp"
    temp_no_products="$workspace_dir/no_products.tmp"
    
    # Extract products section from Package-original.swift
    sed -n '/products: \[/,/\],/p' "$workspace_dir/Package-original.swift" > "$temp_products"
    
    if [ -s "$temp_products" ]; then
        # Remove old products section from Package.swift
        echo "Removing old products section..."
        # Get everything before products section
        sed -n '1,/products: \[/p' "$workspace_dir/Package.swift" | sed '$d' > "$temp_no_products"
        # Get everything after products section
        sed -n '/\],/,$p' "$workspace_dir/Package.swift" | sed '1d' >> "$temp_no_products"
        
        # Create new Package.swift with updated products
        echo "Adding new products section..."
        
        # Copy everything up to products section
        sed -n '1,/products: \[/p' "$temp_no_products" | sed '$d' > "$temp_package"
        
        # Add the new products section but remove the last line (closing bracket)
        sed '$d' "$temp_products" >> "$temp_package"
        
        # Check if last line ends with comma
        last_line=$(tail -n 1 "$temp_package")
        if [[ "$last_line" != *"," ]]; then
            echo "," >> "$temp_package"
        fi
        
        # Add FreePrints and additional modules to products
        echo '        // Complete SDK for FreePrints
        .library(
            name: "BraintreeFreePrints",
            targets: [
                "BraintreeCore",
                "BraintreeCard",
                "BraintreePayPal",
                "BraintreeApplePay",
                "BraintreeDataCollector",
                "BraintreeThreeDSecure",
                "BraintreeLocalPayment",
                "BraintreeSEPADirectDebit",
                "CardinalMobile",
                "PPRiskMagnes"
            ]
        ),
        // Required additional modules
        .library(
            name: "CardinalMobile",
            targets: ["CardinalMobile"]
        ),
        .library(
            name: "PPRiskMagnes",
            targets: ["PPRiskMagnes"]
        ),
        .library(
            name: "PayPalMessages",
            targets: ["PayPalMessages"]
        ),
        .library(
            name: "PayPalCheckout",
            targets: ["PayPalCheckout"]
        )
    ],' >> "$temp_package"
        
        # Add everything after products section
        sed -n '/dependencies: \[/,$p' "$temp_no_products" >> "$temp_package"
        
        if [ -s "$temp_package" ]; then
            mv "$temp_package" "$workspace_dir/Package.swift"
            echo "✅ Updated products in Package.swift"
        else
            echo "Warning: Failed to create updated Package.swift"
        fi
    else
        echo "Warning: Could not extract products section from Package-original.swift"
    fi
    
    # Clean up temporary files
    rm -f "$temp_products" "$temp_package" "$temp_no_products"
else
    echo "Warning: Package.swift not found in source code"
    exit 1
fi

# If we need to regenerate, use the already downloaded source code
if [ "$NEED_REGENERATE" = true ] || [ "$FORCE_REGENERATE" = true ]; then
    echo "Will regenerate framework zips."
    
    # Clean existing frameworks
    echo "Cleaning existing frameworks..."
    rm -rf $XCFRAMEWORK_DIR/Carthage
    rm -f $ZIP_DIR/*.zip
    rm -f $ZIP_DIR/checksums.txt
    
    # Download the XCFramework
    echo "Downloading from $BRAINTREE_URL"
    curl -L $BRAINTREE_URL -o "$TEMP_DIR/Braintree.xcframework.zip"
    
    # Calculate checksum of the main framework zip
    if [[ "$OSTYPE" == "darwin"* ]]; then
      MAIN_CHECKSUM=$(shasum -a 256 "$TEMP_DIR/Braintree.xcframework.zip" | awk '{print $1}')
    else
      MAIN_CHECKSUM=$(sha256sum "$TEMP_DIR/Braintree.xcframework.zip" | awk '{print $1}')
    fi
    
    echo "Main Checksum: $MAIN_CHECKSUM"
    
    # Extract XCFrameworks
    echo "Extracting XCFrameworks..."
    unzip -q -d $XCFRAMEWORK_DIR "$TEMP_DIR/Braintree.xcframework.zip"
    
    # Initialize empty JSON array for checksums
    CHECKSUMS_JSON="["
    
    # Zip each framework from Carthage/Build and calculate checksum
    for framework in "${FRAMEWORKS[@]}"; do
        echo "Zipping $framework.xcframework..."
        
        # Check if the framework exists
        if [ ! -d "$XCFRAMEWORK_DIR/Carthage/Build/$framework.xcframework" ]; then
            echo "Warning: $framework.xcframework not found. Skipping..."
            continue
        fi
        
        # Remove any existing zip
        rm -f "$ZIP_DIR/$framework.xcframework.zip"
        
        # Create the zip
        zip -r -q "$ZIP_DIR/$framework.xcframework.zip" "$XCFRAMEWORK_DIR/Carthage/Build/$framework.xcframework"
        
        # Calculate checksum (SHA-256)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            CHECKSUM=$(shasum -a 256 "$ZIP_DIR/$framework.xcframework.zip" | awk '{print $1}')
        else
            CHECKSUM=$(sha256sum "$ZIP_DIR/$framework.xcframework.zip" | awk '{print $1}')
        fi
        
        echo "$framework.xcframework.zip checksum: $CHECKSUM"
        echo "$framework.xcframework.zip: $CHECKSUM" >> "$ZIP_DIR/checksums.txt"
        
        # Add to JSON array
        CHECKSUMS_JSON+="{ \"name\": \"$framework\", \"checksum\": \"$CHECKSUM\" },"
    done
    
    # Zip each additional framework from XCFrameworks directory
    for framework in "${ADDITIONAL_FRAMEWORKS[@]}"; do
        echo "Zipping $framework.xcframework..."
        
        # Check if the framework exists
        if [ ! -d "$XCFRAMEWORK_DIR/XCFrameworks/$framework.xcframework" ]; then
            echo "Warning: $XCFRAMEWORK_DIR/XCFrameworks/$framework.xcframework not found. Skipping..."
            continue
        fi
        
        # Remove any existing zip
        rm -f "$ZIP_DIR/$framework.xcframework.zip"
        
        # Create the zip
        zip -r -q "$ZIP_DIR/$framework.xcframework.zip" "$XCFRAMEWORK_DIR/XCFrameworks/$framework.xcframework"
        
        # Calculate checksum (SHA-256)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            CHECKSUM=$(shasum -a 256 "$ZIP_DIR/$framework.xcframework.zip" | awk '{print $1}')
        else
            CHECKSUM=$(sha256sum "$ZIP_DIR/$framework.xcframework.zip" | awk '{print $1}')
        fi
        
        echo "$framework.xcframework.zip checksum: $CHECKSUM"
        echo "$framework.xcframework.zip: $CHECKSUM" >> "$ZIP_DIR/checksums.txt"
        
        # Add to JSON array
        CHECKSUMS_JSON+="{ \"name\": \"$framework\", \"checksum\": \"$CHECKSUM\" },"
    done
    
    # Add PayPal external frameworks to JSON array
    CHECKSUMS_JSON+="{ \"name\": \"PayPalMessages\", \"checksum\": \"$PAYPAL_MESSAGES_CHECKSUM\", \"url\": \"$PAYPAL_MESSAGES_URL\" },"
    CHECKSUMS_JSON+="{ \"name\": \"PayPalCheckout\", \"checksum\": \"$PAYPAL_CHECKOUT_CHECKSUM\", \"url\": \"$PAYPAL_CHECKOUT_URL\" },"
    
    # Remove trailing comma and close the array
    CHECKSUMS_JSON=${CHECKSUMS_JSON%,}
    CHECKSUMS_JSON+="]"
    
    # Clean up Frameworks directory after zipping
    echo "Cleaning up Frameworks directory..."
    rm -rf "$XCFRAMEWORK_DIR"
    echo "✅ Removed Frameworks directory"
else
    # Use existing checksums
    CHECKSUMS_JSON=$EXISTING_CHECKSUMS_JSON
fi

if [ "$VERSION_CHANGED" = true ] || [ "$FORCE_REGENERATE" = true ] || [ "$NEED_REGENERATE" = true ]; then
    echo "✅ Successfully updated to Braintree SDK version $BRAINTREE_VERSION"
else
    echo "✅ No changes needed for Braintree SDK version $BRAINTREE_VERSION"
fi

echo "Now you can commit these changes and create a new release"

# Update package.json
if command -v node &> /dev/null; then
  node -e "
    const fs = require('fs');
    const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    
    pkg.version = '$BRAINTREE_VERSION';
    if (!pkg.braintree) pkg.braintree = {};
    pkg.braintree.version = '$BRAINTREE_VERSION';
    pkg.braintree.url = '$BRAINTREE_URL';
    pkg.braintree.mainChecksum = '$MAIN_CHECKSUM';
    pkg.braintree.frameworks = $CHECKSUMS_JSON;
    
    fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
  "
  echo "Updated package.json with framework information"
  
  # Update package-lock.json
  if command -v npm &> /dev/null; then
    echo "Updating package-lock.json..."
    npm install --package-lock-only
    echo "✅ Updated package-lock.json"
  else
    echo "npm not found. Skipping package-lock.json update."
  fi
else
  echo "Node.js not found. Skipping package.json and package-lock.json updates."
fi

# Update README
sed -i.bak "s/version [0-9]\+\.[0-9]\+\.[0-9]\+/version $BRAINTREE_VERSION/g" README.md
sed -i.bak "s/from: \"[0-9]\+\.[0-9]\+\.[0-9]\+\"/from: \"$BRAINTREE_VERSION\"/g" README.md
rm README.md.bak 

# Clean up unzipped frameworks only if we regenerated them
if [ "$NEED_REGENERATE" = true ] || [ "$FORCE_REGENERATE" = true ]; then
    echo "Cleaning up unzipped frameworks..."
    rm -rf $XCFRAMEWORK_DIR/Carthage
    rm -f $TEMP_DIR/Braintree.xcframework.zip
    echo "✅ Cleanup complete. Only zipped frameworks and XCFrameworks directory remain."
fi 

# Final cleanup - remove entire temp directory
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"
echo "✅ Cleanup complete" 