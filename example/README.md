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

The Android example uses `FlutterFragmentActivity`, as required by Checkout's
Google Pay Activity Result coordinator. No Checkout-specific native bridge or
SDK dependency is configured in the example application.
