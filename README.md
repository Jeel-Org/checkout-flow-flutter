# Checkout Flow Flutter

An unofficial iOS-only Flutter plugin for presenting the complete Checkout.com
Flow experience or opening Apple Pay directly from an existing payment
session.

This branch intentionally contains no Android plugin registration, native
Android source, Checkout Android Components dependency, or Google Pay API. It
can therefore be included in a cross-platform host application without adding
Checkout's Ktor 3 dependency to the Android build. This avoids the unresolved
[Zoho Desk ASAP Ktor compatibility issue](https://github.com/zoho/zdesk-asap-flutter/issues/41)
until the upstream dependency chain is compatible.

> [!IMPORTANT]
> This package is maintained by Jeel and is not an official Checkout.com
> package. It is not affiliated with, endorsed by, or supported by Checkout.com.
> For the official native SDK and documentation, see
> [Flow for Mobile iOS SDK](https://github.com/checkout/checkout-ios-components)
> and the [Checkout.com documentation](https://www.checkout.com/docs/).

## Scope

This package currently provides:

- `CheckoutFlowView` for full Flow on iOS
- `payWithApplePay()` for an application-owned Apple Pay button on iOS

It does not provide web, standalone card-entry, or other payment-provider
integrations. It also does not create payment sessions, draw the
application-owned direct wallet button, poll payment status, or verify the final
payment. Those responsibilities remain with the integrating application and
its backend. The full Flow view renders its own available payment-method UI.

See [ROADMAP.md](ROADMAP.md) for the current capabilities and planned Flutter
interfaces.

The package exposes a small Dart API while keeping the native Checkout SDKs and
Flutter platform channels internal. Host applications do not need their own
Swift bridge or Checkout SDK dependency.

## How it works

1. Your backend creates a Checkout.com payment session using its secret key.
2. The backend returns the payment session ID and payment session secret to the
   Flutter application.
3. The Flutter application renders `CheckoutFlowView` or calls
   a direct wallet payment with that session and its Checkout client
   configuration.
4. Checkout Flow presents the chosen payment experience and submits the payment
   to Checkout.com.
5. A `submitted` result means the SDK submitted the payment. Your application
   must verify or poll the final payment status through its backend.

Wallet tokens are handled by Checkout Flow. They are not returned to the
Flutter application and should not be forwarded manually to the backend.

## Requirements

- Flutter 3.44 or newer
- Dart 3.12 or newer
- iOS 15 or newer and Xcode 16 or newer for iOS
- An arm64 device or simulator for iOS
- A Checkout.com account and public key
- A payment session created by your backend
- An Apple Pay merchant identifier for Apple Pay

The current package integrates Checkout's iOS Components SDK 2.6.0 and
Checkout Risk SDK 4.0.1 on iOS.

## Installation

Until the package is published on pub.dev, add the public Git repository to
`pubspec.yaml`:

```yaml
dependencies:
  checkout_flow_flutter:
    git:
      url: https://github.com/Jeel-Org/checkout-flow-flutter.git
      ref: platform/ios-only-v0.3.1
```

Then install dependencies:

```sh
flutter pub get
```

The plugin supports both CocoaPods and Flutter's Swift Package Manager
integration. Keep the dependency manager already used by your Flutter project;
no manual Checkout SDK installation is required.

## iOS configuration

In Xcode, open the host application's target and:

1. Add the **Apple Pay** capability under **Signing & Capabilities**.
2. Select the Apple Pay merchant identifier used by your Checkout.com account.
3. Ensure the selected provisioning profile includes that merchant identifier.
4. Set the application's minimum iOS deployment target to iOS 15 or newer.

The identifier enabled in the application entitlement must be the same value
passed to `payWithApplePay`.

## Backend requirements

Create the Checkout.com payment session on a trusted backend. Never include a
Checkout.com secret key (`sk_...`) in a Flutter application.

The Flutter application needs these values from the backend session response:

- Payment session ID
- Payment session secret

The Checkout.com public key (`pk_...`) and Apple Pay merchant identifier are
client configuration values and may be stored using the application's normal
environment-configuration mechanism.

## Usage

Import and create the client:

```dart
import 'package:checkout_flow_flutter/checkout_flow_flutter.dart';

final checkoutFlow = CheckoutFlowFlutter();
```

### Full Checkout Flow

Render the complete Flow interface inside a constrained area such as an
`Expanded` or `SizedBox` widget:

```dart
CheckoutFlowView(
  configuration: CheckoutFlowConfiguration(
    paymentSession: CheckoutFlowPaymentSession(
      id: paymentSessionId,
      secret: paymentSessionSecret,
    ),
    publicKey: checkoutPublicKey,
    environment: CheckoutFlowEnvironment.sandbox,
    applePayMerchantIdentifier: applePayMerchantIdentifier,
    locale: 'en-GB',
  ),
  onReady: () {
    // Flow is ready for customer input.
  },
  onPaymentResult: (result) {
    // Verify submitted payments through your backend.
  },
)
```

Provide `applePayMerchantIdentifier` to include Apple Pay. The backend payment
session remains the source of truth for the payment methods available to Flow.

### Direct Apple Pay

Check whether Apple Pay can be presented before displaying it as an available
payment method:

```dart
final isAvailable = await checkoutFlow.isApplePayAvailable();
if (!isAvailable) {
  return;
}
```

After your backend creates the Checkout.com payment session, start Apple Pay:

```dart
final result = await checkoutFlow.payWithApplePay(
  paymentSession: CheckoutFlowPaymentSession(
    id: paymentSessionId,
    secret: paymentSessionSecret,
  ),
  publicKey: checkoutPublicKey,
  merchantIdentifier: applePayMerchantIdentifier,
  environment: CheckoutFlowEnvironment.sandbox,
);
```

Use `CheckoutFlowEnvironment.production` with a production public key and a
production payment session.

Handle the SDK result:

```dart
switch (result.status) {
  case CheckoutFlowPaymentStatus.submitted:
    // Verify or poll the final payment status through your backend.
    break;
  case CheckoutFlowPaymentStatus.cancelled:
    // The customer dismissed the Apple Pay sheet.
    break;
  case CheckoutFlowPaymentStatus.failed:
    // Log or display result.errorCode and result.errorMessage as appropriate.
    break;
}
```

`submitted` is not a replacement for server-side verification. Treat the
backend payment status as the source of truth.

## API

### `isApplePayAvailable()`

Returns whether Apple Pay can be presented on the current iOS device.

### `CheckoutFlowView`

Renders the complete Checkout Flow interface on iOS. The host widget must
provide bounded width and height. It reports readiness and payment results
through callbacks.

### `payWithApplePay(...)`

Presents Checkout Flow's Apple Pay component using an existing payment session.
Required arguments:

- `paymentSession`: Checkout.com session ID and secret returned by the backend
- `publicKey`: Checkout.com sandbox or production public key
- `merchantIdentifier`: Apple Pay merchant identifier from the app entitlement
- `environment`: `sandbox` by default, or `production`

Returns a `CheckoutFlowPaymentResult` with a `submitted`, `cancelled`, or
`failed` status and optional error details.

## Troubleshooting

If Apple Pay is unavailable or the sheet does not open, verify that:

- the application is running on iOS 15 or newer on an arm64 device or simulator;
- Apple Pay is enabled for the application target;
- the merchant identifier matches the application entitlement;
- the public key, payment session, and selected environment all belong to the
  same Checkout.com environment; and
- the payment session is present and has not expired.

## Support

Report issues with this Flutter wrapper in the
[GitHub issue tracker](https://github.com/Jeel-Org/checkout-flow-flutter/issues).
For Checkout.com account, payment-processing, or native SDK support, use the
official Checkout.com support channels.

## License

This package is available under the [MIT License](LICENSE). It includes and
depends on third-party Checkout.com components; see
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for their notices.
