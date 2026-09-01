import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:checkout_flow_flutter/checkout_flow_flutter.dart';
import 'package:checkout_flow_flutter/checkout_flow_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelCheckoutFlowFlutter platform =
      MethodChannelCheckoutFlowFlutter();
  const MethodChannel channel = MethodChannel('checkout_flow_flutter');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('isApplePayAvailable returns native value', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          expect(methodCall.method, 'isApplePayAvailable');
          return true;
        });

    expect(await platform.isApplePayAvailable(), isTrue);
  });

  test('payWithApplePay maps arguments and result', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          expect(methodCall.method, 'payWithApplePay');
          expect(methodCall.arguments, {
            'paymentSessionId': 'ps_test',
            'paymentSessionSecret': 'secret',
            'publicKey': 'pk_sbox_test',
            'merchantIdentifier': 'merchant.example',
            'environment': 'sandbox',
          });
          return {
            'status': 'failed',
            'paymentId': 'pay_test',
            'componentName': 'applePay',
            'errorCode': 'declined',
            'errorMessage': 'Payment declined',
          };
        });

    final result = await platform.payWithApplePay(
      paymentSession: const CheckoutFlowPaymentSession(
        id: 'ps_test',
        secret: 'secret',
      ),
      publicKey: 'pk_sbox_test',
      merchantIdentifier: 'merchant.example',
      environment: CheckoutFlowEnvironment.sandbox,
    );

    expect(result.status, CheckoutFlowPaymentStatus.failed);
    expect(result.paymentId, 'pay_test');
    expect(result.componentName, 'applePay');
    expect(result.errorCode, 'declined');
    expect(result.errorMessage, 'Payment declined');
  });

  test('isGooglePayAvailable maps session arguments', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          expect(methodCall.method, 'isGooglePayAvailable');
          expect(methodCall.arguments, {
            'paymentSessionId': 'ps_test',
            'paymentSessionSecret': 'secret',
            'publicKey': 'pk_sbox_test',
            'environment': 'sandbox',
          });
          return true;
        });

    final available = await platform.isGooglePayAvailable(
      paymentSession: const CheckoutFlowPaymentSession(
        id: 'ps_test',
        secret: 'secret',
      ),
      publicKey: 'pk_sbox_test',
      environment: CheckoutFlowEnvironment.sandbox,
    );

    expect(available, isTrue);
  });

  test('payWithGooglePay maps payment result', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
          expect(methodCall.method, 'payWithGooglePay');
          return {
            'status': 'submitted',
            'paymentId': 'pay_test',
            'componentName': 'googlepay',
          };
        });

    final result = await platform.payWithGooglePay(
      paymentSession: const CheckoutFlowPaymentSession(
        id: 'ps_test',
        secret: 'secret',
      ),
      publicKey: 'pk_sbox_test',
      environment: CheckoutFlowEnvironment.sandbox,
    );

    expect(result.status, CheckoutFlowPaymentStatus.submitted);
    expect(result.paymentId, 'pay_test');
    expect(result.componentName, 'googlepay');
  });
}
