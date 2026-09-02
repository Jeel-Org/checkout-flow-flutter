# Checkout Flow Flutter

An unofficial Flutter plugin for presenting the complete Checkout.com Flow
experience or opening Apple Pay and Google Pay directly from an existing
payment session.

> [!IMPORTANT]
> This package is maintained by Jeel and is not an official Checkout.com
> package. It is not affiliated with, endorsed by, or supported by Checkout.com.
> For the official native SDK and documentation, see
> [Flow for Mobile iOS SDK](https://github.com/checkout/checkout-ios-components),
> [Flow for Mobile Android SDK](https://github.com/checkout/checkout-android-components),
> and the [Checkout.com documentation](https://www.checkout.com/docs/).

## Scope

This package currently provides:

- `CheckoutFlowView` for full Flow on iOS and Android, including Checkout's
  managed card-entry experience when cards are available in the payment session
- `payWithApplePay()` for an application-owned Apple Pay button on iOS
- `payWithGooglePay()` for an application-owned Google Pay button on Android

It does not provide web, standalone card-entry, or other payment-provider
integrations. It also does not create payment sessions, draw the
application-owned direct wallet button, poll payment status, or verify the final
payment. Those responsibilities remain with the integrating application and
its backend. The full Flow view renders its own available payment-method UI.

The package exposes a small Dart API while keeping the native Checkout SDKs and
Flutter platform channels internal. Host applications do not need their own
Swift/Kotlin bridge or Checkout SDK dependency.

## Backend and payment flow

Create payment sessions on a trusted backend. Never include a Checkout.com
secret key (`sk_...`) in a Flutter application.

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

The Flutter application needs the payment session ID and payment session secret
from the backend response. The Checkout.com public key (`pk_...`), Apple Pay
merchant identifier, and wallet enablement are client configuration values.

## Requirements

- Flutter 3.44 or newer
- Dart 3.12 or newer
- iOS 15 or newer and Xcode 16 or newer for iOS
- An arm64 device or simulator for iOS
- Android API 24 or newer for Android
- A Checkout.com account and public key
- A payment session created by your backend
- An Apple Pay merchant identifier for Apple Pay
- A Google Pay-enabled Checkout.com processing channel for Google Pay

### Native dependencies

| Platform | Dependency | Version | Purpose |
| --- | --- | --- | --- |
| Android | Checkout Android Components | `2.6.0` | Full Flow, managed card entry, and Google Pay |
| iOS | Checkout iOS Components | `2.6.0` | Full Flow, managed card entry, and Apple Pay |
| iOS | Checkout Risk SDK | `4.0.1` | Checkout device-risk signals |

Host applications should not add these dependencies themselves. The plugin
declares them and keeps the native integration internal.

## Installation

Until the package is published on pub.dev, add the public Git repository to
`pubspec.yaml`:

```yaml
dependencies:
  checkout_flow_flutter:
    git:
      url: https://github.com/Jeel-Org/checkout-flow-flutter.git
      ref: v0.3.1
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

## Android configuration

Google Pay's Activity Result integration requires the host activity to extend
`FlutterFragmentActivity`. Many Flutter applications already use it for other
plugins. If yours does not, change only the activity base class:

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

No Checkout SDK dependency, method channel, manifest entry, or Google Pay
coordinator is required in the host application. Full Flow without Google Pay
can run with the standard `FlutterActivity`.

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
    googlePayEnabled: true,
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

On iOS, provide `applePayMerchantIdentifier` to include Apple Pay. On Android,
set `googlePayEnabled` to `true` when the backend payment session includes
Google Pay. The backend payment session remains the source of truth for the
payment methods available to Flow.

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

### Direct Google Pay

Direct Google Pay uses an existing payment session and opens the native wallet
from your own Flutter payment button:

```dart
final isAvailable = await checkoutFlow.isGooglePayAvailable(
  paymentSession: CheckoutFlowPaymentSession(
    id: paymentSessionId,
    secret: paymentSessionSecret,
  ),
  publicKey: checkoutPublicKey,
  environment: CheckoutFlowEnvironment.sandbox,
);

if (isAvailable) {
  final result = await checkoutFlow.payWithGooglePay(
    paymentSession: CheckoutFlowPaymentSession(
      id: paymentSessionId,
      secret: paymentSessionSecret,
    ),
    publicKey: checkoutPublicKey,
    environment: CheckoutFlowEnvironment.sandbox,
  );
  // Verify submitted payments through your backend.
}
```

## Support

Report issues with this Flutter wrapper in the
[GitHub issue tracker](https://github.com/Jeel-Org/checkout-flow-flutter/issues).
For Checkout.com account, payment-processing, or native SDK support, use the
official Checkout.com support channels.

## License

This package is available under the [MIT License](LICENSE). It includes and
depends on third-party Checkout.com components; see
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for their notices.
