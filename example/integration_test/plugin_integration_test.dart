import 'package:checkout_flow_flutter/checkout_flow_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _publicKey = String.fromEnvironment('CHECKOUT_PUBLIC_KEY');
const _paymentSessionId = String.fromEnvironment('PAYMENT_SESSION_ID');
const _paymentSessionSecret = String.fromEnvironment('PAYMENT_SESSION_SECRET');

const _hasPaymentSession =
    _publicKey != '' && _paymentSessionId != '' && _paymentSessionSecret != '';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'reports Apple Pay availability on iOS',
    (tester) async {
      final plugin = CheckoutFlowFlutter();
      final available = await plugin.isApplePayAvailable();
      expect(available, isA<bool>());
    },
    skip: defaultTargetPlatform != TargetPlatform.iOS,
  );

  testWidgets(
    'reports Google Pay availability on Android',
    (tester) async {
      final plugin = CheckoutFlowFlutter();
      final available = await plugin.isGooglePayAvailable(
        paymentSession: const CheckoutFlowPaymentSession(
          id: _paymentSessionId,
          secret: _paymentSessionSecret,
        ),
        publicKey: _publicKey,
      );
      expect(available, isA<bool>());
    },
    skip:
        defaultTargetPlatform != TargetPlatform.android || !_hasPaymentSession,
  );
}
