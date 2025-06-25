package com.N3k0chan.aikitchen

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

class FavoritesRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return FavoritesRemoteViewsFactory(this.applicationContext, intent)
    }
}

class FavoritesRemoteViewsFactory(
    private val context: Context,
    intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private val appWidgetId: Int = intent.getIntExtra(
        AppWidgetManager.EXTRA_APPWIDGET_ID,
        AppWidgetManager.INVALID_APPWIDGET_ID
    )
    
    private var favoriteRecipes: List<FavoriteRecipe> = emptyList()

    data class FavoriteRecipe(
        val nombre: String,
        val descripcion: String,
        val tiempo: String,
        val calorias: Int,
        val raciones: Int
    )

    override fun onCreate() {
        // Inicialización
    }

    override fun onDataSetChanged() {
        // Cargar datos desde el plugin
        val widgetData = HomeWidgetPlugin.getData(context)
        val favoritesJson = widgetData.getString("favorite_recipes", "[]")
        
        android.util.Log.d("FavoritesWidget", "Raw JSON data: $favoritesJson")
        
        favoriteRecipes = try {
            val jsonArray = JSONArray(favoritesJson)
            android.util.Log.d("FavoritesWidget", "JSON array length: ${jsonArray.length()}")
            
            (0 until jsonArray.length()).map { index ->
                val item = jsonArray.getJSONObject(index)
                val recipe = FavoriteRecipe(
                    nombre = item.getString("nombre"),
                    descripcion = item.getString("descripcion"),
                    tiempo = item.getString("tiempo"),
                    calorias = item.getInt("calorias"),
                    raciones = item.getInt("raciones")
                )
                android.util.Log.d("FavoritesWidget", "Parsed recipe: ${recipe.nombre}")
                recipe
            }
        } catch (e: JSONException) {
            android.util.Log.e("FavoritesWidget", "JSON parsing error: ${e.message}")
            emptyList()
        }
        
        android.util.Log.d("FavoritesWidget", "Total recipes loaded: ${favoriteRecipes.size}")
    }

    override fun onDestroy() {
        favoriteRecipes = emptyList()
    }

    override fun getCount(): Int = favoriteRecipes.size

    override fun getViewAt(position: Int): RemoteViews? {
        if (position >= favoriteRecipes.size) return null
        
        val recipe = favoriteRecipes[position]
        val views = RemoteViews(context.packageName, R.layout.recipe_item_widget)
        
        // Configurar los datos de la receta
        views.setTextViewText(R.id.recipe_name, recipe.nombre)
        views.setTextViewText(R.id.recipe_description, recipe.descripcion)
        views.setTextViewText(R.id.recipe_time, "⏱ ${recipe.tiempo}")
        views.setTextViewText(R.id.recipe_calories, "🔥 ${recipe.calorias} cal")
        views.setTextViewText(R.id.recipe_servings, "🍽 ${recipe.raciones} raciones")
        
        // Configurar click intent
        val fillInIntent = Intent()
        fillInIntent.putExtra("recipe_name", recipe.nombre)
        views.setOnClickFillInIntent(R.id.recipe_name, fillInIntent)
        
        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true
}
