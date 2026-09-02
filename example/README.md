# Checkout Flow Flutter example

The example demonstrates full Checkout Flow and direct Apple Pay or Google Pay.
Create a sandbox payment session on your backend, then run:

```sh
flutter run \
  --dart-define=CHECKOUT_PUBLIC_KEY=pk_sbox_... \
  --dart-define=PAYMENT_SESSION_ID=ps_... \
  --dart-define=PAYMENT_SESSION_SECRET=... \
  --dart-define=APPLE_PAY_MERCHANT_IDENTIFIER=merchant.example
```

The public key and merchant identifier are client configuration. The payment
session must be created by a trusted backend; never add a Checkout secret key to
the example application.

For Apple Pay, open `ios/Runner.xcworkspace` in Xcode, then:

1. Select the Runner target and your own development team and bundle identifier.
2. Add the Apple Pay capability under Signing & Capabilities.
3. Select a merchant identifier provisioned for that bundle identifier.

For Google Pay, use a Google Play Services device with an eligible wallet and a
Checkout.com payment session that includes Google Pay. The Android example is
already configured with `FlutterFragmentActivity`.
