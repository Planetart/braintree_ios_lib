// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Braintree",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "BraintreeAmericanExpress",
            targets: ["BraintreeAmericanExpress"]
        ),
        .library(
            name: "BraintreeApplePay",
            targets: ["BraintreeApplePay"]
        ),
        .library(
            name: "BraintreeCard",
            targets: ["BraintreeCard"]
        ),
        .library(
            name: "BraintreeCore",
            targets: ["BraintreeCore"]
        ),
        .library(
            name: "BraintreeDataCollector",
            targets: ["BraintreeDataCollector", "PPRiskMagnes"]
        ),
        .library(
            name: "BraintreeLocalPayment",
            targets: ["BraintreeLocalPayment", "PPRiskMagnes"]
        ),
        .library(
            name: "BraintreePayPal",
            targets: ["BraintreePayPal", "PPRiskMagnes"]
        ),
        .library(
            name: "BraintreePayPalMessaging",
            targets: ["BraintreePayPalMessaging"]
        ),
        .library(
            name: "BraintreePayPalNativeCheckout",
            targets: ["BraintreePayPalNativeCheckout"]
        ),
        .library(
            name: "BraintreeSEPADirectDebit",
            targets: ["BraintreeSEPADirectDebit"]
        ),
        .library(
            name: "BraintreeShopperInsights",
            targets: ["BraintreeShopperInsights"]
        ),
        .library(
            name: "BraintreeThreeDSecure",
            targets: ["BraintreeThreeDSecure", "CardinalMobile", "PPRiskMagnes"]
        ),
        .library(
            name: "BraintreeVenmo",
            targets: ["BraintreeVenmo"]
        ),
        // Complete SDK for FreePrints
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
    ],
    dependencies: [],
    targets: [
        // All binary targets pointing to individual XCFramework zips
        .binaryTarget(
            name: "BraintreeCore",
            path: "XCFrameworkZips/BraintreeCore.xcframework.zip"
        ),
        .binaryTarget(
            name: "BraintreeCard",
            path: "XCFrameworkZips/BraintreeCard.xcframework.zip"
        ),
        .binaryTarget(
            name: "BraintreeAmericanExpress",
            path: "XCFrameworkZips/BraintreeAmericanExpress.xcframework.zip"
        ),
        .binaryTarget(
            name: "BraintreeApplePay",
            path: "XCFrameworkZips/BraintreeApplePay.xcframework.zip"
        ),
        .target(
            name: "BraintreeDataCollector",
            dependencies: ["BraintreeCore", "PPRiskMagnes"],
            path: "Sources/BraintreeDataCollector",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "BraintreeLocalPayment",
            dependencies: ["BraintreeCore", "BraintreeDataCollector"],
            path: "Sources/BraintreeLocalPayment",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "BraintreePayPal",
            dependencies: ["BraintreeCore", "BraintreeDataCollector"],
            path: "Sources/BraintreePayPal",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "BraintreePayPalMessaging",
            dependencies: ["BraintreeCore", "PayPalMessages"],
            path: "Sources/BraintreePayPalMessaging",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "BraintreePayPalNativeCheckout",
            dependencies: ["BraintreeCore", "BraintreePayPal", "PayPalCheckout"],
            path: "Sources/BraintreePayPalNativeCheckout",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .binaryTarget(
            name: "BraintreeSEPADirectDebit",
            path: "XCFrameworkZips/BraintreeSEPADirectDebit.xcframework.zip"
        ),
        .binaryTarget(
            name: "BraintreeShopperInsights",
            path: "XCFrameworkZips/BraintreeShopperInsights.xcframework.zip"
        ),
        .target(
            name: "BraintreeThreeDSecure",
            dependencies: ["BraintreeCard", "CardinalMobile", "PPRiskMagnes", "BraintreeCore"],
            path: "Sources/BraintreeThreeDSecure",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .binaryTarget(
            name: "BraintreeVenmo",
            path: "XCFrameworkZips/BraintreeVenmo.xcframework.zip"
        ),
        // Required additional binary targets
        .binaryTarget(
            name: "CardinalMobile",
            path: "XCFrameworkZips/CardinalMobile.xcframework.zip"
        ),
        .binaryTarget(
            name: "PPRiskMagnes",
            path: "XCFrameworkZips/PPRiskMagnes.xcframework.zip"
        ),
        // PayPal dependencies
        .binaryTarget(
            name: "PayPalMessages",
            url: "https://github.com/paypal/paypal-messages-ios/releases/download/1.0.0/PayPalMessages.xcframework.zip",
            checksum: "565ab72a3ab75169e41685b16e43268a39e24217a12a641155961d8b10ffe1b4"
        ),
        .binaryTarget(
            name: "PayPalCheckout",
            url: "https://github.com/paypal/paypalcheckout-ios/releases/download/1.3.0/PayPalCheckout.xcframework.zip",
            checksum: "d65186f38f390cb9ae0431ecacf726774f7f89f5474c48244a07d17b248aa035"
        )
    ]
) 
