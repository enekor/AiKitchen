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

class FavoritesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.favorites_widget)
        
        // Obtener datos del widget
        val widgetData = HomeWidgetPlugin.getData(context)
        val favoritesCount = widgetData.getInt("favorites_count", 0)
        
        // Actualizar contador
        views.setTextViewText(R.id.favorites_count, favoritesCount.toString())
        
        // Mostrar estado vacío si no hay favoritos
        if (favoritesCount == 0) {
            views.setViewVisibility(R.id.favorites_list, android.view.View.GONE)
            views.setViewVisibility(R.id.empty_state, android.view.View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.favorites_list, android.view.View.VISIBLE)
            views.setViewVisibility(R.id.empty_state, android.view.View.GONE)
            
            // Configurar lista de recetas
            val intent = Intent(context, FavoritesRemoteViewsService::class.java)
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            views.setRemoteAdapter(R.id.favorites_list, intent)
        }
        
        // Intent para abrir la app
        val openAppIntent = Intent(context, MainActivity::class.java)
        openAppIntent.putExtra("route", "/favorites")
        val openAppPendingIntent = PendingIntent.getActivity(
            context, 0, openAppIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.btn_open_app, openAppPendingIntent)
        
        // Intent para refrescar
        val refreshIntent = Intent(context, FavoritesWidgetProvider::class.java)
        refreshIntent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        refreshIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
        val refreshPendingIntent = PendingIntent.getBroadcast(
            context, appWidgetId, refreshIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.btn_refresh, refreshPendingIntent)
        
        // Intent template para items individuales
        val itemClickIntent = Intent(context, FavoritesWidgetProvider::class.java)
        itemClickIntent.action = "OPEN_RECIPE"
        val itemClickPendingIntent = PendingIntent.getBroadcast(
            context, 0, itemClickIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setPendingIntentTemplate(R.id.favorites_list, itemClickPendingIntent)
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        super.onReceive(context, intent)
        
        when (intent?.action) {
            "OPEN_RECIPE" -> {
                val recipeName = intent.getStringExtra("recipe_name")
                if (recipeName != null) {
                    // Abrir la app con la receta específica
                    val openRecipeIntent = Intent(context, MainActivity::class.java)
                    openRecipeIntent.putExtra("route", "/recipe")
                    openRecipeIntent.putExtra("recipe_name", recipeName)
                    openRecipeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    context?.startActivity(openRecipeIntent)
                }
            }
        }
    }
}
