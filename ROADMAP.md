# Package direction

`checkout_flow_flutter` aims to provide a simple, unofficial Flutter interface
for Checkout.com Flow for Mobile.

Applications should be able to use the complete Checkout Flow experience or
open a native wallet directly when they already have their own payment-method
screen.

## Current and future support

| Capability | Status | Flutter API direction |
| --- | --- | --- |
| Full Checkout Flow | Available on iOS and Android | `CheckoutFlowView` widget |
| Direct Apple Pay | Available on iOS | `payWithApplePay()` |
| Direct Google Pay | Available on Android | `payWithGooglePay()` |
| Standalone card form | Future | `CheckoutCardView` widget |
| Stored cards | Future | Dedicated component |
| Other payment methods | Future | Optional components and configuration |
| Payment-session creation | Merchant backend | Passed into the package |
| Final payment confirmation | Merchant backend or webhook | Returned to the application |

## Package experience

The package should:

- expose a small, consistent Dart API across supported platforms;
- keep native Checkout SDK setup, platform views, and platform channels inside
  the plugin;
- allow each application to provide its own Checkout public key, environment,
  payment session, and wallet configuration; and
- include examples and tests for every supported payment experience.

## Delivery direction

Direct Apple Pay, complete Checkout Flow, Android Flow, and direct Google Pay
form the package's initial cross-platform foundation. Future releases can grow
into standalone and optional components based on real integration needs.

The roadmap describes direction rather than a promise that every native
Checkout component will be exposed. Features will be added when they can have a
clear Flutter API and reliable behavior on their supported platforms.
