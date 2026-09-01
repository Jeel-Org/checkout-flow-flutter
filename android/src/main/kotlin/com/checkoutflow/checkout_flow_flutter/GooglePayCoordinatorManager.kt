package com.checkoutflow.checkout_flow_flutter

import android.content.Context
import com.checkout.components.interfaces.api.CheckoutComponents
import com.checkout.components.interfaces.component.FlowCoordinator
import com.checkout.components.wallet.wrapper.GooglePayFlowCoordinator

internal class GooglePayCoordinatorManager {
    private var coordinatorContext: Context? = null
    private var coordinator: GooglePayFlowCoordinator? = null
    private var activeCheckoutComponents: CheckoutComponents? = null

    fun coordinator(context: Context): FlowCoordinator {
        requireGooglePayHost(context)
        if (coordinator == null || coordinatorContext !== context) {
            coordinatorContext = context
            coordinator = GooglePayFlowCoordinator(context) { resultCode, data ->
                activeCheckoutComponents?.handleActivityResult(resultCode, data)
            }
        }
        return checkNotNull(coordinator)
    }

    fun activate(checkoutComponents: CheckoutComponents) {
        activeCheckoutComponents = checkoutComponents
    }

    fun clear(checkoutComponents: CheckoutComponents? = null) {
        if (checkoutComponents == null || activeCheckoutComponents === checkoutComponents) {
            activeCheckoutComponents = null
        }
    }

    fun detach() {
        activeCheckoutComponents = null
        coordinator = null
        coordinatorContext = null
    }
}
