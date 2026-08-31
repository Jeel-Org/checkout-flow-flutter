import 'package:checkout_flow_flutter/checkout_flow_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _checkoutFlow = CheckoutFlowFlutter();
  String _status = 'Not checked';

  Future<void> _checkAvailability() async {
    final available = await _checkoutFlow.isApplePayAvailable();
    if (!mounted) return;
    setState(() => _status = available ? 'Available' : 'Unavailable');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Checkout Flow Flutter')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Apple Pay: $_status'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _checkAvailability,
                child: const Text('Check availability'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
