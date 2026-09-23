package com.N3k0chan.aikitchen

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin

class ShoppingListWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_TOGGLE_ITEM = "com.N3k0chan.aikitchen.TOGGLE_SHOPPING_ITEM"
        const val EXTRA_ITEM_ID = "item_id"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ) {
        val views = RemoteViews(context.packageName, R.layout.shopping_list_widget)
        val data = HomeWidgetPlugin.getData(context)
        val pendingCount = data.getInt("pending_count", 0)
        val completedCount = data.getInt("completed_count", 0)

        views.setTextViewText(R.id.pending_count, pendingCount.toString())

        val isEmpty = pendingCount + completedCount == 0
        views.setViewVisibility(R.id.shopping_list, if (isEmpty) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.empty_state, if (isEmpty) View.VISIBLE else View.GONE)

        if (!isEmpty) {
            val adapterIntent = Intent(context, ShoppingListRemoteViewsService::class.java)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            // Sin un dato que distinga el intent, varias copias del widget
            // comparten la misma factoría y todas muestran los datos de la
            // primera.
            adapterIntent.data = Uri.parse(adapterIntent.toUri(Intent.URI_INTENT_SCHEME))
            views.setRemoteAdapter(R.id.shopping_list, adapterIntent)
            views.setPendingIntentTemplate(R.id.shopping_list, toggleTemplate(context))
        }

        val openApp = WidgetUris.openShoppingList(context)
        views.setOnClickPendingIntent(R.id.widget_header, openApp)
        views.setOnClickPendingIntent(R.id.empty_state, openApp)
        views.setOnClickPendingIntent(R.id.btn_refresh, refreshIntent(context, appWidgetId))

        appWidgetManager.updateAppWidget(appWidgetId, views)
        // `updateAppWidget` repinta el marco pero no vuelve a pedir las filas:
        // sin este aviso la lista se queda con los datos anteriores.
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.shopping_list)
    }

    /// Plantilla común a todas las filas. Es mutable a propósito: cada fila
    /// completa el `id` de su artículo mediante su intent de relleno.
    private fun toggleTemplate(context: Context): PendingIntent {
        val intent = Intent(context, ShoppingListWidgetProvider::class.java)
            .setAction(ACTION_TOGGLE_ITEM)
        return PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
        )
    }

    private fun refreshIntent(context: Context, appWidgetId: Int): PendingIntent {
        val intent = Intent(context, ShoppingListWidgetProvider::class.java)
            .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
            .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
        return PendingIntent.getBroadcast(
            context,
            appWidgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        super.onReceive(context, intent)

        if (context == null || intent?.action != ACTION_TOGGLE_ITEM) return
        val itemId = intent.getIntExtra(EXTRA_ITEM_ID, -1)
        if (itemId < 0) return

        // Los artículos viven en la base de datos de la app, así que el cambio
        // lo aplica Dart en un aislado de fondo; aquí solo se traslada la
        // intención.
        HomeWidgetBackgroundIntent.getBroadcast(
            context,
            Uri.parse("aikitchen://toggle?action=toggle_shopping_item&item_id=$itemId"),
        ).send()

        // Ejecuta el refresco de la interfaz (igual que al pulsar el botón de actualizar)
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = ComponentName(context, ShoppingListWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
}
