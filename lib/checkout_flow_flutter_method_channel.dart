import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'checkout_flow_flutter_platform_interface.dart';
import 'src/checkout_flow_result_mapper.dart';
import 'src/checkout_flow_models.dart';

/// An implementation of [CheckoutFlowFlutterPlatform] that uses method channels.
class MethodChannelCheckoutFlowFlutter extends CheckoutFlowFlutterPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('checkout_flow_flutter');

  @override
  Future<bool> isApplePayAvailable() async {
    return await methodChannel.invokeMethod<bool>('isApplePayAvailable') ??
        false;
  }

  @override
  Future<CheckoutFlowPaymentResult> payWithApplePay({
    required CheckoutFlowPaymentSession paymentSession,
    required String publicKey,
    required String merchantIdentifier,
    required CheckoutFlowEnvironment environment,
  }) async {
    final response = await methodChannel
        .invokeMapMethod<String, Object?>('payWithApplePay', <String, Object?>{
          'paymentSessionId': paymentSession.id,
          'paymentSessionSecret': paymentSession.secret,
          'publicKey': publicKey,
          'merchantIdentifier': merchantIdentifier,
          'environment': environment.name,
        });

    return checkoutFlowResultFromMap(response);
  }
}
