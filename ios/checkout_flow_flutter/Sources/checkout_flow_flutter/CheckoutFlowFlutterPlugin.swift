import CheckoutComponentsSDK
import Flutter
import PassKit

public final class CheckoutFlowFlutterPlugin: NSObject, FlutterPlugin {
  private var activeComponent: Any?
  private var pendingResult: FlutterResult?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "checkout_flow_flutter",
      binaryMessenger: registrar.messenger()
    )
    let instance = CheckoutFlowFlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.register(
      CheckoutFlowViewFactory(
        messenger: registrar.messenger()
      ),
      withId: "checkout_flow_flutter/flow"
    )
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isApplePayAvailable":
      result(PKPaymentAuthorizationController.canMakePayments())
    case "payWithApplePay":
      Task { @MainActor [weak self] in
        self?.startApplePay(arguments: call.arguments, result: result)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @MainActor
  private func startApplePay(arguments: Any?, result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(
        code: "payment_in_progress",
        message: "A payment is already in progress.",
        details: nil
      ))
      return
    }

    guard
      let params = arguments as? [String: Any],
      let paymentSessionId = nonEmptyString(params["paymentSessionId"]),
      let paymentSessionSecret = nonEmptyString(params["paymentSessionSecret"]),
      let publicKey = nonEmptyString(params["publicKey"]),
      let merchantIdentifier = nonEmptyString(params["merchantIdentifier"]),
      let environmentName = nonEmptyString(params["environment"])
    else {
      result(FlutterError(
        code: "invalid_arguments",
        message: "Missing Checkout Flow Apple Pay configuration.",
        details: nil
      ))
      return
    }

    let environment: CheckoutComponents.Environment
    switch environmentName {
    case "sandbox":
      environment = .sandbox
    case "production":
      environment = .production
    default:
      result(FlutterError(
        code: "invalid_environment",
        message: "Environment must be sandbox or production.",
        details: environmentName
      ))
      return
    }

    pendingResult = result
    let paymentSession = PaymentSession(
      id: paymentSessionId,
      paymentSessionSecret: paymentSessionSecret
    )

    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let configuration = try await CheckoutComponents.Configuration(
          paymentSession: paymentSession,
          publicKey: publicKey,
          environment: environment,
          callbacks: .init(
            onSuccess: { [weak self] component, paymentID in
              Task { @MainActor [weak self] in
                self?.complete(
                  status: "submitted",
                  paymentId: paymentID,
                  componentName: component.name
                )
              }
            },
            onError: { [weak self] error in
              Task { @MainActor [weak self] in
                let cancelled: Bool
                if case .paymentCancelled = error.errorCode {
                  cancelled = true
                } else {
                  cancelled = false
                }
                self?.complete(
                  status: cancelled ? "cancelled" : "failed",
                  errorCode: String(describing: error.errorCode),
                  errorMessage: String(describing: error)
                )
              }
            }
          )
        )
        let checkout = CheckoutComponents(configuration: configuration)
        let component = try checkout.create(.applePay(
          merchantIdentifier: merchantIdentifier,
          showPayButton: false
        ))

        guard component.isAvailable else {
          complete(
            status: "failed",
            errorCode: "apple_pay_unavailable",
            errorMessage: "Apple Pay is unavailable on this device."
          )
          return
        }

        activeComponent = component
        component.submit()
      } catch {
        complete(
          status: "failed",
          errorCode: "checkout_flow_error",
          errorMessage: error.localizedDescription
        )
      }
    }
  }

  private func nonEmptyString(_ value: Any?) -> String? {
    guard let value = value as? String,
          !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else { return nil }
    return value
  }

  @MainActor
  private func complete(
    status: String,
    paymentId: String? = nil,
    componentName: String? = nil,
    errorCode: String? = nil,
    errorMessage: String? = nil
  ) {
    var response: [String: Any] = ["status": status]
    if let paymentId { response["paymentId"] = paymentId }
    if let componentName { response["componentName"] = componentName }
    if let errorCode { response["errorCode"] = errorCode }
    if let errorMessage { response["errorMessage"] = errorMessage }

    let result = pendingResult
    pendingResult = nil
    activeComponent = nil
    result?(response)
  }
}
