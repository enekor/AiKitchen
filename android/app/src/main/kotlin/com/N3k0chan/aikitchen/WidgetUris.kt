package com.N3k0chan.aikitchen

import android.app.PendingIntent
import android.content.Context
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/// Enlaces que el widget de la lista y el botón de ajustes rápidos usan para
/// pedirle a la app que abra una pestaña concreta. El anfitrión del URI debe
/// coincidir con el que espera `WidgetService` en Dart.
object WidgetUris {
    private val SHOPPING_LIST: Uri = Uri.parse("aikitchen://shopping_list")

    /// Abre la app en la lista de la compra. El plugin `home_widget` se encarga
    /// de entregarle el URI a Dart, tanto si la app estaba cerrada como viva.
    fun openShoppingList(context: Context): PendingIntent =
        HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            SHOPPING_LIST,
        )
}
