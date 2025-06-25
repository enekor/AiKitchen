package com.N3k0chan.aikitchen

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONException
import java.text.SimpleDateFormat
import java.util.*

class ShoppingListWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        android.util.Log.d("ShoppingWidget", "=== ShoppingListWidgetProvider.onUpdate called ===")
        android.util.Log.d("ShoppingWidget", "Widget IDs: ${appWidgetIds.contentToString()}")
        
        for (appWidgetId in appWidgetIds) {
            android.util.Log.d("ShoppingWidget", "Updating widget with ID: $appWidgetId")
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
        
        android.util.Log.d("ShoppingWidget", "=== onUpdate completed ===")
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        android.util.Log.d("ShoppingWidget", "=== updateAppWidget called for ID: $appWidgetId ===")
        
        val views = RemoteViews(context.packageName, R.layout.shopping_list_widget)
        
        // Obtener datos del widget
        val widgetData = HomeWidgetPlugin.getData(context)
        android.util.Log.d("ShoppingWidget", "Widget data available")
        
        val pendingCount = widgetData.getInt("pending_count", 0)
        val completedCount = widgetData.getInt("completed_count", 0)
        val lastUpdated = widgetData.getString("last_updated", "")
        
        android.util.Log.d("ShoppingWidget", "Pending: $pendingCount, Completed: $completedCount")
        android.util.Log.d("ShoppingWidget", "Last updated: $lastUpdated")
        
        // Actualizar contadores
        views.setTextViewText(R.id.pending_count, pendingCount.toString())
        views.setTextViewText(R.id.completed_count, completedCount.toString())
        
        // Configurar lista de items
        android.util.Log.d("ShoppingWidget", "Setting up ListView with RemoteViewsService")
        val intent = Intent(context, ShoppingListRemoteViewsService::class.java)
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        // Agregar un extra único para forzar la actualización
        intent.data = android.net.Uri.parse("content://widget/shopping/$appWidgetId")
        views.setRemoteAdapter(R.id.shopping_list, intent)
        
        // Intent para abrir la app
        val openAppIntent = Intent(context, MainActivity::class.java)
        openAppIntent.putExtra("route", "/shopping_list")
        val openAppPendingIntent = PendingIntent.getActivity(
            context, 0, openAppIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.btn_open_app, openAppPendingIntent)
        
        // Intent template para items individuales
        val itemClickIntent = Intent(context, ShoppingListWidgetProvider::class.java)
        itemClickIntent.action = "TOGGLE_ITEM"
        val itemClickPendingIntent = PendingIntent.getBroadcast(
            context, 0, itemClickIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setPendingIntentTemplate(R.id.shopping_list, itemClickPendingIntent)
        
        android.util.Log.d("ShoppingWidget", "Calling appWidgetManager.updateAppWidget")
        appWidgetManager.updateAppWidget(appWidgetId, views)
        
        // Forzar actualización de la lista
        android.util.Log.d("ShoppingWidget", "Calling notifyAppWidgetViewDataChanged")
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.shopping_list)
        
        android.util.Log.d("ShoppingWidget", "=== updateAppWidget completed ===")
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        super.onReceive(context, intent)
        
        when (intent?.action) {
            "CLEAR_COMPLETED" -> {
                // Enviar acción a Flutter
                val backgroundIntent = Intent("es.antonborri.home_widget.action.BACKGROUND")
                backgroundIntent.putExtra("action", "clear_completed")
                context?.sendBroadcast(backgroundIntent)
            }
            "TOGGLE_ITEM" -> {
                val itemName = intent.getStringExtra("item_name")
                if (itemName != null) {
                    // Enviar acción a Flutter
                    val backgroundIntent = Intent("es.antonborri.home_widget.action.BACKGROUND")
                    backgroundIntent.putExtra("action", "toggle_shopping_item")
                    backgroundIntent.putExtra("item_name", itemName)
                    context?.sendBroadcast(backgroundIntent)
                }
            }
        }
    }
}
