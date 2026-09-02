## 0.3.1

* Enable Swift Package Manager in the example application.
* Package the privacy manifest consistently with Swift Package Manager and CocoaPods.
* Resolve the host view controller from the platform view hierarchy for both package managers.

## 0.3.0

* Add Android support for `CheckoutFlowView`.
* Add direct Google Pay availability and payment APIs.
* Keep Android Checkout SDK setup and payment coordination inside the plugin.
* Add an Android example and cross-platform usage documentation.
* Migrate the Android plugin to Flutter's built-in Kotlin-compatible setup.

## 0.2.0

* Add `CheckoutFlowView` for the complete Checkout Flow experience on iOS.
* Keep direct Apple Pay available through `payWithApplePay`.
* Include payment ID and component name in successful payment results.
* Expand the example application with full Flow and direct Apple Pay demos.

## 0.1.1

* Add CocoaPods support using Checkout's official iOS XCFramework.
* Keep Swift Package Manager support for migrated Flutter projects.

## 0.1.0

* Add Checkout Flow Apple Pay submission from an existing payment session.
* Add Apple Pay availability detection and structured payment results.
