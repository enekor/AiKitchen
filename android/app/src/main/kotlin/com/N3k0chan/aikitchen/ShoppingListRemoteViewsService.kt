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

class ShoppingListRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return ShoppingListRemoteViewsFactory(this.applicationContext, intent)
    }
}

class ShoppingListRemoteViewsFactory(
    private val context: Context,
    intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private val appWidgetId: Int = intent.getIntExtra(
        AppWidgetManager.EXTRA_APPWIDGET_ID,
        AppWidgetManager.INVALID_APPWIDGET_ID
    )
    
    private var shoppingItems: List<ShoppingItem> = emptyList()

    data class ShoppingItem(
        val name: String,
        val isPurchased: Boolean
    )

    override fun onCreate() {
        android.util.Log.d("ShoppingWidget", "=== RemoteViewsFactory.onCreate called ===")
        android.util.Log.d("ShoppingWidget", "AppWidget ID: $appWidgetId")
        // Forzar carga inicial de datos
        onDataSetChanged()
    }

    override fun onDataSetChanged() {
        android.util.Log.d("ShoppingWidget", "=== onDataSetChanged called ===")
        
        // Cargar datos desde el plugin
        val widgetData = HomeWidgetPlugin.getData(context)
        android.util.Log.d("ShoppingWidget", "Widget data loaded")
        
        val shoppingListJson = widgetData.getString("shopping_list_items", "[]")
        android.util.Log.d("ShoppingWidget", "Raw JSON data: '$shoppingListJson'")
        android.util.Log.d("ShoppingWidget", "JSON data length: ${shoppingListJson?.length ?: 0}")
        
        // Verificar otros datos
        val pendingCount = widgetData.getInt("pending_count", -1)
        val completedCount = widgetData.getInt("completed_count", -1)
        android.util.Log.d("ShoppingWidget", "Pending: $pendingCount, Completed: $completedCount")
        
        shoppingItems = try {
            if (shoppingListJson.isNullOrBlank() || shoppingListJson == "[]") {
                android.util.Log.w("ShoppingWidget", "No shopping list data found or empty array")
                emptyList()
            } else {
                val jsonArray = JSONArray(shoppingListJson)
                android.util.Log.d("ShoppingWidget", "JSON array created, length: ${jsonArray.length()}")
                
                val items = (0 until jsonArray.length()).map { index ->
                    val item = jsonArray.getJSONObject(index)
                    android.util.Log.d("ShoppingWidget", "Processing item $index: $item")
                    
                    val shoppingItem = ShoppingItem(
                        name = item.getString("name"),
                        isPurchased = item.getBoolean("isPurchased")
                    )
                    android.util.Log.d("ShoppingWidget", "Created ShoppingItem: ${shoppingItem.name} - ${shoppingItem.isPurchased}")
                    shoppingItem
                }
                
                android.util.Log.d("ShoppingWidget", "All items processed successfully")
                items
            }
        } catch (e: JSONException) {
            android.util.Log.e("ShoppingWidget", "JSON parsing error: ${e.message}", e)
            android.util.Log.e("ShoppingWidget", "Problematic JSON: '$shoppingListJson'")
            emptyList()
        } catch (e: Exception) {
            android.util.Log.e("ShoppingWidget", "Unexpected error: ${e.message}", e)
            emptyList()
        }
        
        android.util.Log.d("ShoppingWidget", "Final items count: ${shoppingItems.size}")
        for (i in shoppingItems.indices) {
            android.util.Log.d("ShoppingWidget", "Item $i: ${shoppingItems[i].name} - ${shoppingItems[i].isPurchased}")
        }
        android.util.Log.d("ShoppingWidget", "=== onDataSetChanged completed ===")
    }

    override fun onDestroy() {
        shoppingItems = emptyList()
    }

    override fun getCount(): Int {
        val realCount = shoppingItems.size
        val count = if (realCount == 0) {
            android.util.Log.w("ShoppingWidget", "No real items found, using fallback count: 1")
            1 // Mostrar al menos un item que diga "Lista vacía"
        } else {
            android.util.Log.d("ShoppingWidget", "Using real items count: $realCount")
            realCount
        }
        android.util.Log.d("ShoppingWidget", "getCount() returning: $count")
        return count
    }

    override fun getViewAt(position: Int): RemoteViews? {
        android.util.Log.d("ShoppingWidget", "=== getViewAt called for position $position ===")
        android.util.Log.d("ShoppingWidget", "Total items available: ${shoppingItems.size}")
        
        return try {
            val views = RemoteViews(context.packageName, R.layout.shopping_item_widget)
            
            if (shoppingItems.isEmpty()) {
                // Mostrar mensaje de lista vacía
                android.util.Log.d("ShoppingWidget", "Showing empty list message")
                views.setTextViewText(R.id.item_text, "Lista vacía - Agrega items en la app")
                views.setBoolean(R.id.item_checkbox, "setChecked", false)
                views.setTextColor(R.id.item_text, 0xFF888888.toInt()) // Gris
            } else {
                // Verificar bounds
                if (position >= shoppingItems.size) {
                    android.util.Log.w("ShoppingWidget", "Position $position >= items size ${shoppingItems.size}")
                    return null
                }
                
                val item = shoppingItems[position]
                android.util.Log.d("ShoppingWidget", "Creating view for item: '${item.name}' - isPurchased: ${item.isPurchased}")
                
                // Configurar el item real
                views.setTextViewText(R.id.item_text, item.name)
                views.setBoolean(R.id.item_checkbox, "setChecked", item.isPurchased)
                
                // Configurar el estilo según el estado
                if (item.isPurchased) {
                    views.setTextColor(R.id.item_text, 0xFF888888.toInt()) // Gris
                    views.setInt(R.id.item_text, "setPaintFlags", 
                        android.graphics.Paint.STRIKE_THRU_TEXT_FLAG)
                } else {
                    views.setTextColor(R.id.item_text, 0xFF000000.toInt()) // Negro
                    views.setInt(R.id.item_text, "setPaintFlags", 0)
                }
                
                // Configurar click intent
                val fillInIntent = Intent()
                fillInIntent.putExtra("item_name", item.name)
                views.setOnClickFillInIntent(R.id.item_checkbox, fillInIntent)
            }
            
            android.util.Log.d("ShoppingWidget", "View created successfully")
            views
            
        } catch (e: Exception) {
            android.util.Log.e("ShoppingWidget", "ERROR in getViewAt: ${e.message}", e)
            // Retornar vista de error
            val errorViews = RemoteViews(context.packageName, R.layout.shopping_item_widget)
            errorViews.setTextViewText(R.id.item_text, "Error: ${e.message}")
            errorViews.setBoolean(R.id.item_checkbox, "setChecked", false)
            errorViews
        }
    }

    override fun getLoadingView(): RemoteViews? {
        val loadingView = RemoteViews(context.packageName, R.layout.shopping_item_widget)
        loadingView.setTextViewText(R.id.item_text, "Cargando...")
        return loadingView
    }

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true
}
