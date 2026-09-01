package com.checkoutflow.checkout_flow_flutter

import android.app.Activity
import com.checkout.components.interfaces.api.CheckoutComponents
import com.checkout.components.interfaces.api.PaymentMethodComponent
import com.checkout.components.interfaces.component.ComponentCallback
import com.checkout.components.interfaces.component.ComponentOption
import com.checkout.components.interfaces.component.GooglePayConfiguration
import com.checkout.components.interfaces.error.CheckoutError
import com.checkout.components.interfaces.error.CheckoutErrorCode
import com.checkout.components.interfaces.model.PaymentMethodName
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class CheckoutFlowFlutterPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var scope: CoroutineScope
    private var activity: Activity? = null
    private var operationJob: Job? = null
    private var pendingAvailabilityResult: Result? = null
    private var pendingPaymentResult: Result? = null
    private var checkoutComponents: CheckoutComponents? = null
    private var activeComponent: PaymentMethodComponent? = null
    private val googlePayCoordinatorManager = GooglePayCoordinatorManager()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
        channel = MethodChannel(binding.binaryMessenger, "checkout_flow_flutter")
        channel.setMethodCallHandler(this)
        binding.platformViewRegistry.registerViewFactory(
            "checkout_flow_flutter/flow",
            CheckoutFlowViewFactory(
                binding.binaryMessenger,
                { activity },
                googlePayCoordinatorManager,
            ),
        )
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isGooglePayAvailable" -> checkGooglePayAvailability(call.arguments, result)
            "payWithGooglePay" -> startGooglePay(call.arguments, result)
            else -> result.notImplemented()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity()
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        failPendingOperations(
            code = "engine_detached",
            message = "The Flutter engine detached during Google Pay.",
        )
        googlePayCoordinatorManager.detach()
        scope.cancel()
        clearOperation()
    }

    private fun checkGooglePayAvailability(arguments: Any?, result: Result) {
        val currentActivity = requireActivity(result) ?: return
        if (!beginOperation(result)) return
        pendingAvailabilityResult = result

        operationJob = scope.launch {
            try {
                val (_, component) = createGooglePayComponent(
                    currentActivity,
                    arguments,
                    ComponentCallback(),
                )
                result.success(component.isAvailable())
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                result.error(
                    "google_pay_error",
                    error.message ?: error.toString(),
                    null,
                )
            } finally {
                clearOperation()
            }
        }
    }

    private fun startGooglePay(arguments: Any?, result: Result) {
        val currentActivity = requireActivity(result) ?: return
        if (!beginOperation(result)) return
        pendingPaymentResult = result

        operationJob = scope.launch {
            try {
                val callbacks = ComponentCallback(
                    onSuccess = { paymentComponent, paymentId ->
                        scope.launch {
                            completePayment(
                                status = "submitted",
                                paymentId = paymentId,
                                componentName = paymentComponent.name.value,
                            )
                        }
                    },
                    onError = { _, error -> scope.launch { completePayment(error) } },
                )
                val (checkout, component) = createGooglePayComponent(
                    currentActivity,
                    arguments,
                    callbacks,
                )
                checkoutComponents = checkout
                activeComponent = component
                googlePayCoordinatorManager.activate(checkout)

                if (!component.isAvailable()) {
                    completePayment(
                        status = "failed",
                        errorCode = "google_pay_unavailable",
                        errorMessage = "Google Pay is unavailable on this device.",
                    )
                    return@launch
                }
                component.submit()
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                completePayment(
                    status = "failed",
                    errorCode = "google_pay_error",
                    errorMessage = error.message ?: error.toString(),
                )
            }
        }
    }

    private suspend fun createGooglePayComponent(
        currentActivity: Activity,
        arguments: Any?,
        callbacks: ComponentCallback,
    ): Pair<CheckoutComponents, PaymentMethodComponent> {
        val configuration = parseConfiguration(arguments)
        val checkout = createCheckoutComponents(
            context = currentActivity,
            configuration = configuration,
            callbacks = callbacks,
            enableGooglePay = true,
            googlePayCoordinator = googlePayCoordinatorManager.coordinator(currentActivity),
        )
        val component = checkout.create(
            PaymentMethodName.GooglePay,
            ComponentOption(
                showPayButton = false,
                googlePayConfiguration = GooglePayConfiguration(),
            ),
        )
        return checkout to component
    }

    private fun beginOperation(result: Result): Boolean {
        if (operationJob?.isActive == true || pendingPaymentResult != null) {
            result.error(
                "payment_in_progress",
                "A Google Pay operation is already in progress.",
                null,
            )
            return false
        }
        return true
    }

    private fun requireActivity(result: Result): Activity? {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error(
                "activity_unavailable",
                "Google Pay requires an attached Android activity.",
                null,
            )
        }
        return currentActivity
    }

    private fun completePayment(error: CheckoutError) {
        completePayment(
            status = if (error.code == CheckoutErrorCode.PAYMENT_CANCELLED) {
                "cancelled"
            } else {
                "failed"
            },
            errorCode = error.code.name,
            errorMessage = error.message,
        )
    }

    private fun completePayment(
        status: String,
        paymentId: String? = null,
        componentName: String? = null,
        errorCode: String? = null,
        errorMessage: String? = null,
    ) {
        val result = pendingPaymentResult ?: return
        result.success(
            buildMap<String, Any> {
                put("status", status)
                paymentId?.let { put("paymentId", it) }
                componentName?.let { put("componentName", it) }
                errorCode?.let { put("errorCode", it) }
                errorMessage?.let { put("errorMessage", it) }
            },
        )
        clearOperation()
    }

    private fun detachActivity() {
        activity = null
        operationJob?.cancel()
        googlePayCoordinatorManager.detach()
        failPendingOperations(
            code = "activity_detached",
            message = "The Android activity detached during Google Pay.",
        )
        clearOperation()
    }

    private fun failPendingOperations(code: String, message: String) {
        pendingAvailabilityResult?.error(code, message, null)
        pendingPaymentResult?.error(code, message, null)
    }

    private fun clearOperation() {
        googlePayCoordinatorManager.clear(checkoutComponents)
        operationJob = null
        pendingAvailabilityResult = null
        pendingPaymentResult = null
        activeComponent = null
        checkoutComponents = null
    }
}
