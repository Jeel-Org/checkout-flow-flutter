# Checkout Flow Flutter example

The example demonstrates:

- the complete Checkout Flow interface on iOS; and
- direct Apple Pay and availability detection on iOS.

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
