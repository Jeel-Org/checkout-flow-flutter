import 'package:flutter_test/flutter_test.dart';
import 'package:checkout_flow_flutter/checkout_flow_flutter.dart';
import 'package:checkout_flow_flutter/checkout_flow_flutter_platform_interface.dart';
import 'package:checkout_flow_flutter/checkout_flow_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCheckoutFlowFlutterPlatform
    with MockPlatformInterfaceMixin
    implements CheckoutFlowFlutterPlatform {
  @override
  Future<bool> isApplePayAvailable() async => true;

  @override
  Future<CheckoutFlowPaymentResult> payWithApplePay({
    required CheckoutFlowPaymentSession paymentSession,
    required String publicKey,
    required String merchantIdentifier,
    required CheckoutFlowEnvironment environment,
  }) async => const CheckoutFlowPaymentResult(
    status: CheckoutFlowPaymentStatus.submitted,
  );
}

void main() {
  final CheckoutFlowFlutterPlatform initialPlatform =
      CheckoutFlowFlutterPlatform.instance;

  test('$MethodChannelCheckoutFlowFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCheckoutFlowFlutter>());
  });

  test('reports Apple Pay availability', () async {
    final plugin = CheckoutFlowFlutter(
      platform: MockCheckoutFlowFlutterPlatform(),
    );
    expect(await plugin.isApplePayAvailable(), isTrue);
  });

  test('returns submitted payment result', () async {
    final plugin = CheckoutFlowFlutter(
      platform: MockCheckoutFlowFlutterPlatform(),
    );

    final result = await plugin.payWithApplePay(
      paymentSession: const CheckoutFlowPaymentSession(
        id: 'ps_test',
        secret: 'secret',
      ),
      publicKey: 'pk_sbox_test',
      merchantIdentifier: 'merchant.example',
    );

    expect(result.status, CheckoutFlowPaymentStatus.submitted);
    expect(result.isSubmitted, isTrue);
  });

  test('rejects empty configuration before calling the platform', () {
    final plugin = CheckoutFlowFlutter(
      platform: MockCheckoutFlowFlutterPlatform(),
    );

    expect(
      () => plugin.payWithApplePay(
        paymentSession: const CheckoutFlowPaymentSession(
          id: '',
          secret: 'secret',
        ),
        publicKey: 'pk_sbox_test',
        merchantIdentifier: 'merchant.example',
      ),
      throwsArgumentError,
    );
  });

  test('creates configuration for full Flow', () {
    const configuration = CheckoutFlowConfiguration(
      paymentSession: CheckoutFlowPaymentSession(
        id: 'ps_test',
        secret: 'secret',
      ),
      publicKey: 'pk_sbox_test',
      applePayMerchantIdentifier: 'merchant.example',
      locale: 'en-GB',
    );

    expect(configuration.environment, CheckoutFlowEnvironment.sandbox);
    expect(configuration.paymentSession.id, 'ps_test');
    expect(configuration.applePayMerchantIdentifier, 'merchant.example');
    expect(configuration.locale, 'en-GB');
  });
}
