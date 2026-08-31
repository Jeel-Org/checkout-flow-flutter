import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:checkout_flow_flutter/checkout_flow_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reports Apple Pay availability', (tester) async {
    final plugin = CheckoutFlowFlutter();
    final available = await plugin.isApplePayAvailable();
    expect(available, isA<bool>());
  });
}
