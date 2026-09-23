package com.N3k0chan.aikitchen

import android.content.Context
import android.content.Intent
import android.text.SpannableString
import android.text.style.StrikethroughSpan
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONException

class ShoppingListRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        ShoppingListRemoteViewsFactory(this.applicationContext)
}

private class ShoppingListRemoteViewsFactory(
    private val context: Context,
) : RemoteViewsService.RemoteViewsFactory {

    private data class Item(val id: Int, val name: String, val isPurchased: Boolean)

    private var items: List<Item> = emptyList()

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
        val raw = HomeWidgetPlugin.getData(context)
            .getString("shopping_list_items", "[]") ?: "[]"

        items = try {
            val array = JSONArray(raw)
            (0 until array.length()).mapNotNull { index ->
                val entry = array.getJSONObject(index)
                val id = entry.optInt("id", -1)
                val name = entry.optString("name")
                if (id < 0 || name.isEmpty()) {
                    null
                } else {
                    Item(id, name, entry.optBoolean("isPurchased"))
                }
            }
        } catch (e: JSONException) {
            android.util.Log.e("ShoppingListWidget", "JSON inválido: ${e.message}")
            emptyList()
        }
    }

    override fun onDestroy() {
        items = emptyList()
    }

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews? {
        val item = items.getOrNull(position) ?: return null
        val views = RemoteViews(context.packageName, R.layout.shopping_item_widget)

        views.setImageViewResource(
            R.id.item_checkbox,
            if (item.isPurchased) R.drawable.ic_check_box else R.drawable.ic_check_box_outline,
        )
        views.setTextViewText(R.id.item_name, label(item))
        views.setFloat(R.id.item_name, "setAlpha", if (item.isPurchased) 0.55f else 1.0f)

        val fillInIntent = Intent().putExtra(ShoppingListWidgetProvider.EXTRA_ITEM_ID, item.id)
        views.setOnClickFillInIntent(R.id.shopping_item_root, fillInIntent)
        views.setOnClickFillInIntent(R.id.item_checkbox, fillInIntent)

        return views
    }

    /// `RemoteViews` no permite tocar los flags de pintado del texto, así que el
    /// tachado se manda como texto con estilo.
    private fun label(item: Item): CharSequence {
        if (!item.isPurchased) return item.name
        return SpannableString(item.name).apply {
            setSpan(StrikethroughSpan(), 0, length, 0)
        }
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long =
        items.getOrNull(position)?.id?.toLong() ?: position.toLong()

    override fun hasStableIds(): Boolean = true
}
