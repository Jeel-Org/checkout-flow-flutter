import 'checkout_flow_models.dart';

CheckoutFlowPaymentResult checkoutFlowResultFromMap(
  Map<Object?, Object?>? response,
) {
  final status = switch (response?['status']) {
    'submitted' => CheckoutFlowPaymentStatus.submitted,
    'cancelled' => CheckoutFlowPaymentStatus.cancelled,
    _ => CheckoutFlowPaymentStatus.failed,
  };

  return CheckoutFlowPaymentResult(
    status: status,
    paymentId: response?['paymentId'] as String?,
    componentName: response?['componentName'] as String?,
    errorCode: response?['errorCode'] as String?,
    errorMessage: response?['errorMessage'] as String?,
  );
}
