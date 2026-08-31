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

/// Result of an Apple Pay attempt.
final class CheckoutFlowPaymentResult {
  const CheckoutFlowPaymentResult({
    required this.status,
    this.errorCode,
    this.errorMessage,
  });

  final CheckoutFlowPaymentStatus status;
  final String? errorCode;
  final String? errorMessage;

  bool get isSubmitted => status == CheckoutFlowPaymentStatus.submitted;
  bool get isCancelled => status == CheckoutFlowPaymentStatus.cancelled;
}
