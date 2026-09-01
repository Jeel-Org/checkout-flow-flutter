package com.checkoutflow.checkout_flow_flutter

import android.content.Context
import androidx.activity.result.ActivityResultRegistryOwner
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ViewModelStoreOwner
import com.checkout.components.core.CheckoutComponentsFactory
import com.checkout.components.interfaces.Environment
import com.checkout.components.interfaces.api.CheckoutComponents
import com.checkout.components.interfaces.component.CheckoutComponentConfiguration
import com.checkout.components.interfaces.component.ComponentCallback
import com.checkout.components.interfaces.component.FlowCoordinator
import com.checkout.components.interfaces.localisation.Locale
import com.checkout.components.interfaces.model.PaymentMethodName
import com.checkout.components.interfaces.model.PaymentSessionResponse
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

internal data class NativeCheckoutConfiguration(
    val paymentSessionId: String,
    val paymentSessionSecret: String,
    val publicKey: String,
    val environment: Environment,
    val locale: Locale,
)

internal fun parseConfiguration(arguments: Any?): NativeCheckoutConfiguration {
    val params = arguments as? Map<*, *>
        ?: throw IllegalArgumentException("Missing Checkout Flow configuration.")

    return NativeCheckoutConfiguration(
        paymentSessionId = params.requiredString("paymentSessionId"),
        paymentSessionSecret = params.requiredString("paymentSessionSecret"),
        publicKey = params.requiredString("publicKey"),
        environment = when (params.requiredString("environment")) {
            "sandbox" -> Environment.SANDBOX
            "production" -> Environment.PRODUCTION
            else -> throw IllegalArgumentException(
                "Environment must be sandbox or production.",
            )
        },
        locale = checkoutLocale(params["locale"] as? String),
    )
}

internal fun googlePayEnabled(arguments: Any?): Boolean =
    (arguments as? Map<*, *>)?.get("googlePayEnabled") as? Boolean ?: false

internal suspend fun createCheckoutComponents(
    context: Context,
    configuration: NativeCheckoutConfiguration,
    callbacks: ComponentCallback,
    enableGooglePay: Boolean,
    googlePayCoordinator: FlowCoordinator? = null,
): CheckoutComponents {
    val flowCoordinators: Map<PaymentMethodName, FlowCoordinator> =
        if (enableGooglePay) {
            mapOf(
                PaymentMethodName.GooglePay to checkNotNull(googlePayCoordinator) {
                    "A Google Pay coordinator is required when Google Pay is enabled."
                },
            )
        } else {
            emptyMap()
        }

    val componentConfiguration = CheckoutComponentConfiguration(
        context = context,
        publicKey = configuration.publicKey,
        environment = configuration.environment,
        paymentSession = PaymentSessionResponse(
            configuration.paymentSessionId,
            configuration.paymentSessionSecret,
        ),
        flowCoordinators = flowCoordinators,
        locale = configuration.locale,
        componentCallback = callbacks,
    )

    val createdComponents = withContext(Dispatchers.IO) {
        CheckoutComponentsFactory(componentConfiguration).create()
    }
    return createdComponents
}

internal fun requireGooglePayHost(context: Context) {
    if (
        context !is ViewModelStoreOwner ||
        context !is ActivityResultRegistryOwner ||
        context !is LifecycleOwner
    ) {
        throw IllegalStateException(
            "Google Pay requires the host activity to extend FlutterFragmentActivity.",
        )
    }
}

private fun Map<*, *>.requiredString(key: String): String {
    val value = this[key] as? String
    if (value.isNullOrBlank()) {
        throw IllegalArgumentException("Missing $key.")
    }
    return value
}

private fun checkoutLocale(value: String?): Locale {
    val normalized = value?.replace('_', '-')?.lowercase().orEmpty()
    return when {
        normalized.startsWith("ar") -> Locale.Ar
        normalized.startsWith("da") -> Locale.Da
        normalized.startsWith("de") -> Locale.De
        normalized.startsWith("el") -> Locale.El
        normalized.startsWith("es") -> Locale.Es
        normalized.startsWith("fil") -> Locale.Fil
        normalized.startsWith("fi") -> Locale.Fi
        normalized.startsWith("fr") -> Locale.Fr
        normalized.startsWith("hi") -> Locale.Hi
        normalized.startsWith("id") -> Locale.Id
        normalized.startsWith("it") -> Locale.It
        normalized.startsWith("ja") -> Locale.Ja
        normalized.startsWith("ms") -> Locale.Ms
        normalized.startsWith("nb") -> Locale.Nb
        normalized.startsWith("nl") -> Locale.Nl
        normalized.startsWith("pt") -> Locale.Pt
        normalized.startsWith("sv") -> Locale.Sv
        normalized.startsWith("th") -> Locale.Th
        normalized.startsWith("vi") -> Locale.Vi
        normalized.startsWith("zh-hk") -> Locale.ZhHk
        normalized.startsWith("zh-tw") -> Locale.ZhTw
        normalized.startsWith("zh") -> Locale.Zh
        else -> Locale.En
    }
}
