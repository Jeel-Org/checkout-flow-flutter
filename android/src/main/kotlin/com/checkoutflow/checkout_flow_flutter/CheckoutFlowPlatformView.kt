package com.checkoutflow.checkout_flow_flutter

import android.content.Context
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import com.checkout.components.interfaces.api.CheckoutComponents
import com.checkout.components.interfaces.api.PaymentMethodComponent
import com.checkout.components.interfaces.component.ComponentCallback
import com.checkout.components.interfaces.component.ComponentOption
import com.checkout.components.interfaces.component.GooglePayConfiguration
import com.checkout.components.interfaces.error.CheckoutError
import com.checkout.components.interfaces.error.CheckoutErrorCode
import com.checkout.components.interfaces.model.ComponentName
import com.checkout.components.interfaces.model.PaymentMethodName
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

internal class CheckoutFlowViewFactory(
    private val messenger: BinaryMessenger,
    private val activityProvider: () -> Context?,
    private val googlePayCoordinatorManager: GooglePayCoordinatorManager,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        CheckoutFlowPlatformView(
            context = activityProvider() ?: context,
            viewId = viewId,
            arguments = args,
            messenger = messenger,
            googlePayCoordinatorManager = googlePayCoordinatorManager,
        )
}

internal class CheckoutFlowPlatformView(
    context: Context,
    viewId: Int,
    arguments: Any?,
    messenger: BinaryMessenger,
    private val googlePayCoordinatorManager: GooglePayCoordinatorManager,
) : PlatformView {
    private val container = FrameLayout(context)
    private val channel = MethodChannel(messenger, "checkout_flow_flutter/flow/$viewId")
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var checkoutComponents: CheckoutComponents? = null
    private var component: PaymentMethodComponent? = null

    init {
        scope.launch { start(arguments) }
    }

    override fun getView(): View = container

    override fun dispose() {
        scope.cancel()
        container.removeAllViews()
        googlePayCoordinatorManager.clear(checkoutComponents)
        component = null
        checkoutComponents = null
    }

    private suspend fun start(arguments: Any?) {
        try {
            val configuration = parseConfiguration(arguments)
            val enableGooglePay = googlePayEnabled(arguments)
            var createdCheckoutComponents: CheckoutComponents? = null
            val callbacks = ComponentCallback(
                onReady = { paymentComponent ->
                    scope.launch {
                        channel.invokeMethod(
                            "onReady",
                            mapOf("componentName" to paymentComponent.name.value),
                        )
                    }
                },
                onSuccess = { paymentComponent, paymentId ->
                    scope.launch {
                        googlePayCoordinatorManager.clear(createdCheckoutComponents)
                        sendResult(
                            status = "submitted",
                            paymentId = paymentId,
                            componentName = paymentComponent.name.value,
                        )
                    }
                },
                onError = { _, error ->
                    scope.launch {
                        googlePayCoordinatorManager.clear(createdCheckoutComponents)
                        sendError(error)
                    }
                },
                onSubmit = { paymentComponent ->
                    if (paymentComponent.name == PaymentMethodName.GooglePay) {
                        createdCheckoutComponents?.let(googlePayCoordinatorManager::activate)
                    }
                },
            )
            val checkout = createCheckoutComponents(
                context = container.context,
                configuration = configuration,
                callbacks = callbacks,
                enableGooglePay = enableGooglePay,
                googlePayCoordinator = if (enableGooglePay) {
                    googlePayCoordinatorManager.coordinator(container.context)
                } else {
                    null
                },
            )
            createdCheckoutComponents = checkout
            val options = ComponentOption(
                googlePayConfiguration = if (enableGooglePay) {
                    GooglePayConfiguration()
                } else {
                    null
                },
            )
            val flowComponent = checkout.create(ComponentName.Flow, options)

            if (!flowComponent.isAvailable()) {
                sendFailure(
                    code = "flow_unavailable",
                    message = "Checkout Flow is unavailable for this payment session.",
                )
                return
            }

            checkoutComponents = checkout
            component = flowComponent
            val nativeView = flowComponent.provideView(container)
            nativeView.layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
            container.addView(nativeView)
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            sendFailure(
                code = "checkout_flow_error",
                message = error.message ?: error.toString(),
            )
        }
    }

    private fun sendError(error: CheckoutError) {
        sendResult(
            status = if (error.code == CheckoutErrorCode.PAYMENT_CANCELLED) {
                "cancelled"
            } else {
                "failed"
            },
            errorCode = error.code.name,
            errorMessage = error.message,
        )
    }

    private fun sendFailure(code: String, message: String) {
        sendResult(status = "failed", errorCode = code, errorMessage = message)
    }

    private fun sendResult(
        status: String,
        paymentId: String? = null,
        componentName: String? = null,
        errorCode: String? = null,
        errorMessage: String? = null,
    ) {
        channel.invokeMethod(
            "onPaymentResult",
            buildMap<String, Any> {
                put("status", status)
                paymentId?.let { put("paymentId", it) }
                componentName?.let { put("componentName", it) }
                errorCode?.let { put("errorCode", it) }
                errorMessage?.let { put("errorMessage", it) }
            },
        )
    }
}
