# Checkout Flow Flutter example

The example demonstrates:

- the complete Checkout Flow interface;
- direct Apple Pay and availability detection on iOS; and
- direct Google Pay and availability detection on Android.

Create a sandbox payment session on your backend, then run the example:

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

## Android and Google Pay

Before running the Google Pay examples:

1. Ask Checkout.com to enable the Google Pay processing channel for the account.
2. Create the Payment Session on your backend with Google Pay enabled.
3. Use a Google Play Services device or emulator with an eligible wallet.

The Android example already uses `FlutterFragmentActivity`, as required by
Checkout's Google Pay Activity Result coordinator. Google Pay is enabled in the
complete Flow configuration and is also demonstrated through the direct
`isGooglePayAvailable` and `payWithGooglePay` APIs.

Run the Android integration test with a short-lived sandbox Payment Session:

```sh
flutter test integration_test/plugin_integration_test.dart \
  -d <android-device-id> \
  --dart-define=CHECKOUT_PUBLIC_KEY=pk_sbox_... \
  --dart-define=PAYMENT_SESSION_ID=ps_... \
  --dart-define=PAYMENT_SESSION_SECRET=...
```

## iOS and Apple Pay

Apple Pay requires configuration owned by the integrating application. Open
`ios/Runner.xcworkspace` in Xcode, then:

1. Select the Runner target and your own development team and bundle identifier.
2. Add the Apple Pay capability under Signing & Capabilities.
3. Select a merchant identifier provisioned for that bundle identifier.
4. Pass the same merchant identifier through
   `APPLE_PAY_MERCHANT_IDENTIFIER` when running the example.

Run the iOS integration test on a configured device:

```sh
flutter test integration_test/plugin_integration_test.dart \
  -d <ios-device-id> \
  --dart-define=APPLE_PAY_MERCHANT_IDENTIFIER=merchant.example
```

No Checkout-specific native bridge or SDK dependency needs to be added to the
example application; the plugin owns those dependencies.
