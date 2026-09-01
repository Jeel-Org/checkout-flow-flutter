import 'package:checkout_flow_flutter/checkout_flow_flutter.dart';
import 'package:flutter/material.dart';

const _publicKey = String.fromEnvironment('CHECKOUT_PUBLIC_KEY');
const _paymentSessionId = String.fromEnvironment('PAYMENT_SESSION_ID');
const _paymentSessionSecret = String.fromEnvironment('PAYMENT_SESSION_SECRET');
const _merchantIdentifier = String.fromEnvironment(
  'APPLE_PAY_MERCHANT_IDENTIFIER',
);

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CheckoutExamplePage(),
    );
  }
}

class CheckoutExamplePage extends StatefulWidget {
  const CheckoutExamplePage({super.key});

  @override
  State<CheckoutExamplePage> createState() => _CheckoutExamplePageState();
}

class _CheckoutExamplePageState extends State<CheckoutExamplePage> {
  final _checkoutFlow = CheckoutFlowFlutter();
  String _status = 'Ready';

  bool get _hasPaymentSession =>
      _publicKey.isNotEmpty &&
      _paymentSessionId.isNotEmpty &&
      _paymentSessionSecret.isNotEmpty;

  CheckoutFlowPaymentSession get _paymentSession =>
      const CheckoutFlowPaymentSession(
        id: _paymentSessionId,
        secret: _paymentSessionSecret,
      );

  Future<void> _checkApplePay() async {
    final available = await _checkoutFlow.isApplePayAvailable();
    if (!mounted) return;
    setState(() => _status = available ? 'Apple Pay available' : 'Unavailable');
  }

  Future<void> _payWithApplePay() async {
    if (!_hasPaymentSession || _merchantIdentifier.isEmpty) return;

    final result = await _checkoutFlow.payWithApplePay(
      paymentSession: _paymentSession,
      publicKey: _publicKey,
      merchantIdentifier: _merchantIdentifier,
    );
    if (!mounted) return;
    setState(() => _status = 'Apple Pay: ${result.status.name}');
  }

  void _showFullFlow() {
    if (!_hasPaymentSession) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FullFlowPage(
          configuration: CheckoutFlowConfiguration(
            paymentSession: _paymentSession,
            publicKey: _publicKey,
            applePayMerchantIdentifier: _merchantIdentifier.isEmpty
                ? null
                : _merchantIdentifier,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Flow Flutter')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _checkApplePay,
              child: const Text('Check Apple Pay availability'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _hasPaymentSession ? _showFullFlow : null,
              child: const Text('Show full Checkout Flow'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _hasPaymentSession && _merchantIdentifier.isNotEmpty
                  ? _payWithApplePay
                  : null,
              child: const Text('Pay directly with Apple Pay'),
            ),
            if (!_hasPaymentSession) ...[
              const SizedBox(height: 24),
              const Text(
                'Run with CHECKOUT_PUBLIC_KEY, PAYMENT_SESSION_ID, and '
                'PAYMENT_SESSION_SECRET dart defines to enable payment demos.',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FullFlowPage extends StatefulWidget {
  const FullFlowPage({super.key, required this.configuration});

  final CheckoutFlowConfiguration configuration;

  @override
  State<FullFlowPage> createState() => _FullFlowPageState();
}

class _FullFlowPageState extends State<FullFlowPage> {
  String _status = 'Loading Flow';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Full Checkout Flow')),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(12), child: Text(_status)),
          Expanded(
            child: CheckoutFlowView(
              configuration: widget.configuration,
              onReady: () => setState(() => _status = 'Flow ready'),
              onPaymentResult: (result) {
                setState(() => _status = 'Flow: ${result.status.name}');
              },
            ),
          ),
        ],
      ),
    );
  }
}
