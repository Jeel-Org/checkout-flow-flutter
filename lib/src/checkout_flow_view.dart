import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'checkout_flow_models.dart';
import 'checkout_flow_result_mapper.dart';

/// Renders Checkout.com's complete Flow component on iOS and Android.
class CheckoutFlowView extends StatefulWidget {
  const CheckoutFlowView({
    super.key,
    required this.configuration,
    required this.onPaymentResult,
    this.onReady,
  });

  final CheckoutFlowConfiguration configuration;
  final ValueChanged<CheckoutFlowPaymentResult> onPaymentResult;
  final VoidCallback? onReady;

  @override
  State<CheckoutFlowView> createState() => _CheckoutFlowViewState();
}

class _CheckoutFlowViewState extends State<CheckoutFlowView> {
  MethodChannel? _channel;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      throw UnsupportedError('CheckoutFlowView does not support web.');
    }

    _validateConfiguration(widget.configuration);
    final platformViewKey = ValueKey<int>(
      _configurationHash(widget.configuration),
    );

    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => UiKitView(
        key: platformViewKey,
        viewType: 'checkout_flow_flutter/flow',
        creationParams: _creationParams(widget.configuration),
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      ),
      TargetPlatform.android => AndroidView(
        key: platformViewKey,
        viewType: 'checkout_flow_flutter/flow',
        creationParams: _creationParams(widget.configuration),
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      ),
      _ => throw UnsupportedError(
        'CheckoutFlowView supports iOS and Android only.',
      ),
    };
  }

  void _onPlatformViewCreated(int viewId) {
    _channel?.setMethodCallHandler(null);
    final channel = MethodChannel('checkout_flow_flutter/flow/$viewId');
    channel.setMethodCallHandler(_handleMethodCall);
    _channel = channel;
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (!mounted) return;

    switch (call.method) {
      case 'onReady':
        widget.onReady?.call();
      case 'onPaymentResult':
        final arguments = call.arguments;
        final response = arguments is Map
            ? Map<Object?, Object?>.from(arguments)
            : <Object?, Object?>{};
        widget.onPaymentResult(checkoutFlowResultFromMap(response));
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }
}

int _configurationHash(CheckoutFlowConfiguration configuration) => Object.hash(
  configuration.paymentSession.id,
  configuration.paymentSession.secret,
  configuration.publicKey,
  configuration.environment,
  configuration.applePayMerchantIdentifier,
  configuration.googlePayEnabled,
  configuration.locale,
);

Map<String, Object?> _creationParams(CheckoutFlowConfiguration configuration) {
  return <String, Object?>{
    'paymentSessionId': configuration.paymentSession.id,
    'paymentSessionSecret': configuration.paymentSession.secret,
    'publicKey': configuration.publicKey,
    'environment': configuration.environment.name,
    'merchantIdentifier': ?configuration.applePayMerchantIdentifier,
    'googlePayEnabled': configuration.googlePayEnabled,
    'locale': ?configuration.locale,
  };
}

void _validateConfiguration(CheckoutFlowConfiguration configuration) {
  _requireNotBlank(configuration.paymentSession.id, 'paymentSession.id');
  _requireNotBlank(
    configuration.paymentSession.secret,
    'paymentSession.secret',
  );
  _requireNotBlank(configuration.publicKey, 'publicKey');

  final merchantIdentifier = configuration.applePayMerchantIdentifier;
  if (merchantIdentifier != null) {
    _requireNotBlank(merchantIdentifier, 'applePayMerchantIdentifier');
  }
}

void _requireNotBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'Must not be empty.');
  }
}
