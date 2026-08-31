# checkout_flow_flutter

An app-agnostic Flutter plugin for presenting Checkout Flow Apple Pay from an
existing Checkout.com payment session.

The package exposes a Dart API and keeps the Checkout iOS SDK and platform
channel implementation internal. Checkout-session creation and payment-status
polling remain the responsibility of the integrating application and backend.

## Requirements

- Flutter 3.44 or newer
- iOS 15 or newer
- An arm64 device or simulator (required by Checkout's iOS binary)
- A Checkout.com public key and payment session
- An Apple Pay merchant identifier configured for the host application

## Installation

Until the package is published on pub.dev, add the Git dependency:

```yaml
dependencies:
  checkout_flow_flutter:
    git:
      url: git@github.com:Jeel-Org/checkout-flow-flutter.git
      ref: v0.1.0
```

## Usage

```dart
import 'package:checkout_flow_flutter/checkout_flow_flutter.dart';

final checkoutFlow = CheckoutFlowFlutter();

final available = await checkoutFlow.isApplePayAvailable();
if (!available) return;

final result = await checkoutFlow.payWithApplePay(
  paymentSession: CheckoutFlowPaymentSession(
    id: paymentSessionId,
    secret: paymentSessionSecret,
  ),
  publicKey: checkoutPublicKey,
  merchantIdentifier: appleMerchantIdentifier,
  environment: CheckoutFlowEnvironment.sandbox,
);

switch (result.status) {
  case CheckoutFlowPaymentStatus.submitted:
    // Verify or poll the payment using your backend.
  case CheckoutFlowPaymentStatus.cancelled:
    // The customer closed Apple Pay.
  case CheckoutFlowPaymentStatus.failed:
    // Inspect result.errorCode and result.errorMessage.
}
```

## Host-app configuration

Enable the Apple Pay capability for the iOS application target and select the
same merchant identifier passed to `payWithApplePay`. The plugin deliberately
does not modify application entitlements or contain merchant-specific values.

The plugin supports both CocoaPods and Swift Package Manager. Existing Flutter
applications can keep their current native dependency manager; no manual
Checkout SDK or platform-channel setup is required in the host application.

Do not embed Checkout.com secret keys in a Flutter application. Only the public
key belongs in the client; payment sessions must be created by the backend.
