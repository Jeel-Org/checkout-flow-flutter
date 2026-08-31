// swift-tools-version: 5.10
import PackageDescription

let checkoutComponentsVersion = "2.6.0"
let checkoutComponentsChecksum = "1ebbbd4fd39a4223cbddafecee9bc7377c1a3071333b77637c50039d6f890071"

let package = Package(
    name: "checkout_flow_flutter",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "checkout-flow-flutter", targets: ["checkout_flow_flutter"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(
            url: "https://github.com/checkout/checkout-risk-sdk-ios",
            from: "4.0.1"
        )
    ],
    targets: [
        .target(
            name: "checkout_flow_flutter",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "Risk", package: "checkout-risk-sdk-ios"),
                .target(name: "CheckoutComponentsSDK")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")]
        ),
        .binaryTarget(
            name: "CheckoutComponentsSDK",
            url: "https://github.com/checkout/checkout-ios-components/releases/download/\(checkoutComponentsVersion)/CheckoutComponentsSDK.xcframework.zip",
            checksum: checkoutComponentsChecksum
        )
    ]
)
