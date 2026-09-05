# Package direction

This branch provides the iOS-only variant of `checkout_flow_flutter` while an
Android dependency conflict remains unresolved.

Applications should be able to use the complete Checkout Flow experience or
open a native wallet directly when they already have their own payment-method
screen.

## Current and future support

| Capability | Status | Flutter API direction |
| --- | --- | --- |
| Full Checkout Flow | Available on iOS | `CheckoutFlowView` widget |
| Direct Apple Pay | Available on iOS | `payWithApplePay()` |
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

Direct Apple Pay and complete Checkout Flow form this branch's iOS foundation.
Android Flow and Google Pay remain available on the main package line and can
return once the host application's Android dependencies are compatible.

The roadmap describes direction rather than a promise that every native
Checkout component will be exposed. Features will be added when they can have a
clear Flutter API and reliable behavior on their supported platforms.
