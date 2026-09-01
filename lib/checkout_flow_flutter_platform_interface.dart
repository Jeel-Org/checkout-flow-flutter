import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'checkout_flow_flutter_method_channel.dart';
import 'src/checkout_flow_models.dart';

abstract class CheckoutFlowFlutterPlatform extends PlatformInterface {
  CheckoutFlowFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static CheckoutFlowFlutterPlatform _instance =
      MethodChannelCheckoutFlowFlutter();

  static CheckoutFlowFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CheckoutFlowFlutterPlatform] when
  /// they register themselves.
  static set instance(CheckoutFlowFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> isApplePayAvailable() {
    throw UnimplementedError('isApplePayAvailable() has not been implemented.');
  }

  Future<CheckoutFlowPaymentResult> payWithApplePay({
    required CheckoutFlowPaymentSession paymentSession,
    required String publicKey,
    required String merchantIdentifier,
    required CheckoutFlowEnvironment environment,
  }) {
    throw UnimplementedError('payWithApplePay() has not been implemented.');
  }

  Future<bool> isGooglePayAvailable({
    required CheckoutFlowPaymentSession paymentSession,
    required String publicKey,
    required CheckoutFlowEnvironment environment,
  }) {
    throw UnimplementedError(
      'isGooglePayAvailable() has not been implemented.',
    );
  }

  Future<CheckoutFlowPaymentResult> payWithGooglePay({
    required CheckoutFlowPaymentSession paymentSession,
    required String publicKey,
    required CheckoutFlowEnvironment environment,
  }) {
    throw UnimplementedError('payWithGooglePay() has not been implemented.');
  }
}
