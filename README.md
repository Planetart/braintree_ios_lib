# Braintree iOS SPM

This repository contains the Swift Package Manager distribution of the Braintree iOS SDK.

## MCP Server Setup

The MCP server automatically updates the SPM package when new versions of the Braintree iOS SDK are released.

### Prerequisites

- Node.js >= 14.0.0
- Git configured with write access to this repository

### Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
# Server Configuration
PORT=3000

# GitHub Configuration
GITHUB_SECRET=your-webhook-secret
GITHUB_TOKEN=your-github-token
BRAINTREE_REPO=braintree/braintree_ios
```

### Installation

1. Install dependencies:
   ```bash
   npm install
   ```

2. Start the server:
   ```bash
   npm start
   ```

   For development with auto-reload:
   ```bash
   npm run dev
   ```

### GitHub Webhook Setup

1. Go to your GitHub repository settings
2. Navigate to Webhooks > Add webhook
3. Set Payload URL to your server URL (e.g., `https://your-server.com/webhook`)
4. Set Content type to `application/json`
5. Set Secret to the same value as `GITHUB_SECRET` in your `.env` file
6. Select "Let me select individual events"
7. Choose only "Releases"
8. Click "Add webhook"

### How It Works

1. When a new release is published in the Braintree iOS repository, GitHub sends a webhook event to the MCP server
2. The server verifies the webhook signature using the secret
3. If the event is a new release, the server:
   - Downloads the new XCFramework
   - Updates the package version
   - Commits and pushes the changes
   - Creates a new tag for the release

### Manual Update

You can manually update the frameworks using:

```bash
./update-framework.sh <version> [--force]
```

Example:
```bash
./update-framework.sh 6.30.0 --force
```

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/braintree_ios_spm.git", from: "6.30.0")
]
```

Then add the specific Braintree modules you need to your target dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "BraintreeCore", package: "braintree_ios_spm"),
            .product(name: "BraintreeCard", package: "braintree_ios_spm"),
            .product(name: "BraintreePayPal", package: "braintree_ios_spm")
            // Add other modules as needed
        ]
    )
]
```

## Available Modules

This package provides the following Braintree modules:

- BraintreeCore - Core functionality required by all other modules
- BraintreeAmericanExpress - American Express payments
- BraintreeApplePay - Apple Pay integration
- BraintreeCard - Credit and debit card payments
- BraintreeDataCollector - Fraud detection tools
- BraintreeLocalPayment - Local payment methods
- BraintreePayPal - PayPal payments
- BraintreePayPalMessaging - PayPal messaging components
- BraintreePayPalNativeCheckout - Native PayPal checkout experience
- BraintreeSEPADirectDebit - SEPA direct debit payments
- BraintreeShopperInsights - Shopper data collection
- BraintreeThreeDSecure - 3D Secure authentication
- BraintreeVenmo - Venmo payments

## How it Works

This repository automatically downloads the official Braintree iOS SDK XCFramework from the official Braintree repository and creates a Swift Package Manager compatible package.

The GitHub Action workflow runs whenever a new release is published, downloading the specified version of the Braintree XCFramework, calculating its checksum, and updating the Package.swift file.

## Documentation

For documentation and usage instructions, see the [official Braintree documentation](https://developer.paypal.com/braintree/docs/start/hello-client/ios/v5). 