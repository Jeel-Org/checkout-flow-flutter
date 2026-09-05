import 'checkout_flow_flutter_platform_interface.dart';
import 'src/checkout_flow_models.dart';

export 'src/checkout_flow_models.dart';
export 'src/checkout_flow_view.dart';

/// High-level access to direct Checkout.com Apple Pay payments on iOS.
final class CheckoutFlowFlutter {
  CheckoutFlowFlutter({CheckoutFlowFlutterPlatform? platform})
    : _platform = platform ?? CheckoutFlowFlutterPlatform.instance;

  final CheckoutFlowFlutterPlatform _platform;

  /// Whether Apple Pay can be presented on this device.
  Future<bool> isApplePayAvailable() => _platform.isApplePayAvailable();

  /// Presents Apple Pay immediately using an existing Checkout payment session.
  Future<CheckoutFlowPaymentResult> payWithApplePay({
    required CheckoutFlowPaymentSession paymentSession,
    required String publicKey,
    required String merchantIdentifier,
    CheckoutFlowEnvironment environment = CheckoutFlowEnvironment.sandbox,
  }) {
    _requireNotBlank(paymentSession.id, 'paymentSession.id');
    _requireNotBlank(paymentSession.secret, 'paymentSession.secret');
    _requireNotBlank(publicKey, 'publicKey');
    _requireNotBlank(merchantIdentifier, 'merchantIdentifier');

    return _platform.payWithApplePay(
      paymentSession: paymentSession,
      publicKey: publicKey,
      merchantIdentifier: merchantIdentifier,
      environment: environment,
    );
  }

  static void _requireNotBlank(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'Must not be empty.');
    }
  }
}
