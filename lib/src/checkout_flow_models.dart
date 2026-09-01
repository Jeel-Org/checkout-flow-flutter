/// Checkout.com environment used to process a payment.
enum CheckoutFlowEnvironment { sandbox, production }

/// Final outcome reported by Checkout Flow.
enum CheckoutFlowPaymentStatus { submitted, cancelled, failed }

/// Checkout.com payment-session credentials returned by a merchant backend.
final class CheckoutFlowPaymentSession {
  const CheckoutFlowPaymentSession({required this.id, required this.secret});

  final String id;
  final String secret;
}

/// Configuration shared by the full Checkout Flow component.
final class CheckoutFlowConfiguration {
  const CheckoutFlowConfiguration({
    required this.paymentSession,
    required this.publicKey,
    this.environment = CheckoutFlowEnvironment.sandbox,
    this.applePayMerchantIdentifier,
    this.googlePayEnabled = false,
    this.locale,
  });

  final CheckoutFlowPaymentSession paymentSession;
  final String publicKey;
  final CheckoutFlowEnvironment environment;

  /// Adds Apple Pay to Flow when provided and available for the session.
  final String? applePayMerchantIdentifier;

  /// Adds Google Pay to Flow on Android when enabled.
  ///
  /// The host activity must extend `FlutterFragmentActivity` because the
  /// native Google Pay coordinator uses Android's Activity Result API.
  final bool googlePayEnabled;

  /// Optional locale such as `en-GB` or `ar-SA`.
  final String? locale;
}

/// Result reported after a Flow or direct wallet payment attempt.
final class CheckoutFlowPaymentResult {
  const CheckoutFlowPaymentResult({
    required this.status,
    this.paymentId,
    this.componentName,
    this.errorCode,
    this.errorMessage,
  });

  final CheckoutFlowPaymentStatus status;
  final String? paymentId;
  final String? componentName;
  final String? errorCode;
  final String? errorMessage;

  bool get isSubmitted => status == CheckoutFlowPaymentStatus.submitted;
  bool get isCancelled => status == CheckoutFlowPaymentStatus.cancelled;
}
