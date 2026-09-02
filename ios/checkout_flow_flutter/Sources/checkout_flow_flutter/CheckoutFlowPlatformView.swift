import CheckoutComponentsSDK
import Flutter
import SwiftUI
import UIKit

final class CheckoutFlowViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    CheckoutFlowPlatformView(
      frame: frame,
      viewId: viewId,
      arguments: args,
      messenger: messenger
    )
  }
}

final class CheckoutFlowPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let channel: FlutterMethodChannel
  private var hostingController: UIHostingController<AnyView>?
  private var activeComponent: Any?

  init(
    frame: CGRect,
    viewId: Int64,
    arguments: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    containerView = UIView(frame: frame)
    containerView.backgroundColor = .clear
    channel = FlutterMethodChannel(
      name: "checkout_flow_flutter/flow/\(viewId)",
      binaryMessenger: messenger
    )
    super.init()

    Task { @MainActor [weak self] in
      await self?.start(arguments: arguments)
    }
  }

  func view() -> UIView {
    containerView
  }

  @MainActor
  private func start(arguments: Any?) async {
    guard
      let params = arguments as? [String: Any],
      let paymentSessionId = nonEmptyString(params["paymentSessionId"]),
      let paymentSessionSecret = nonEmptyString(params["paymentSessionSecret"]),
      let publicKey = nonEmptyString(params["publicKey"]),
      let environmentName = nonEmptyString(params["environment"])
    else {
      sendFailure(
        code: "invalid_arguments",
        message: "Missing Checkout Flow configuration."
      )
      return
    }

    let environment: CheckoutComponents.Environment
    switch environmentName {
    case "sandbox":
      environment = .sandbox
    case "production":
      environment = .production
    default:
      sendFailure(
        code: "invalid_environment",
        message: "Environment must be sandbox or production."
      )
      return
    }

    let paymentSession = PaymentSession(
      id: paymentSessionId,
      paymentSessionSecret: paymentSessionSecret
    )
    let merchantIdentifier = nonEmptyString(params["merchantIdentifier"])
    let locale = nonEmptyString(params["locale"])

    do {
      let configuration = try await CheckoutComponents.Configuration(
        paymentSession: paymentSession,
        publicKey: publicKey,
        environment: environment,
        locale: locale,
        callbacks: .init(
          onReady: { [weak self] component in
            Task { @MainActor [weak self] in
              self?.channel.invokeMethod(
                "onReady",
                arguments: ["componentName": component.name]
              )
            }
          },
          onSuccess: { [weak self] component, paymentID in
            Task { @MainActor [weak self] in
              self?.sendResult(
                status: "submitted",
                paymentId: paymentID,
                componentName: component.name
              )
            }
          },
          onError: { [weak self] error in
            Task { @MainActor [weak self] in
              let status: String
              if case .paymentCancelled = error.errorCode {
                status = "cancelled"
              } else {
                status = "failed"
              }
              self?.sendResult(
                status: status,
                errorCode: String(describing: error.errorCode),
                errorMessage: String(describing: error)
              )
            }
          }
        )
      )

      let checkout = CheckoutComponents(configuration: configuration)
      var paymentMethods: Set<CheckoutComponents.PaymentMethod> = [
        .card()
      ]
      if let merchantIdentifier {
        paymentMethods.insert(
          .applePay(merchantIdentifier: merchantIdentifier)
        )
      }

      let component = try checkout.create(.flow(options: paymentMethods))
      guard component.isAvailable else {
        sendFailure(
          code: "flow_unavailable",
          message: "Checkout Flow is unavailable for this payment session."
        )
        return
      }

      activeComponent = component
      attach(component.render())
    } catch {
      sendFailure(
        code: "checkout_flow_error",
        message: error.localizedDescription
      )
    }
  }

  @MainActor
  private func attach(_ flowView: AnyView) {
    let hostingController = UIHostingController(rootView: flowView)
    hostingController.view.backgroundColor = .clear
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false

    let parentViewController = containerView.enclosingViewController
    if let parentViewController {
      parentViewController.addChild(hostingController)
    }
    containerView.addSubview(hostingController.view)
    NSLayoutConstraint.activate([
      hostingController.view.leadingAnchor.constraint(
        equalTo: containerView.leadingAnchor
      ),
      hostingController.view.trailingAnchor.constraint(
        equalTo: containerView.trailingAnchor
      ),
      hostingController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
      hostingController.view.bottomAnchor.constraint(
        equalTo: containerView.bottomAnchor
      )
    ])
    if parentViewController != nil {
      hostingController.didMove(toParent: parentViewController)
    }
    self.hostingController = hostingController
  }

  @MainActor
  private func sendFailure(code: String, message: String) {
    sendResult(status: "failed", errorCode: code, errorMessage: message)
  }

  @MainActor
  private func sendResult(
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
    channel.invokeMethod("onPaymentResult", arguments: response)
  }

  private func nonEmptyString(_ value: Any?) -> String? {
    guard
      let value = value as? String,
      !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else { return nil }
    return value
  }

  deinit {
    let hostingController = hostingController
    Task { @MainActor in
      hostingController?.willMove(toParent: nil)
      hostingController?.view.removeFromSuperview()
      hostingController?.removeFromParent()
    }
  }
}

private extension UIView {
  var enclosingViewController: UIViewController? {
    var responder: UIResponder? = self
    while let current = responder {
      if let viewController = current as? UIViewController {
        return viewController
      }
      responder = current.next
    }
    return nil
  }
}
