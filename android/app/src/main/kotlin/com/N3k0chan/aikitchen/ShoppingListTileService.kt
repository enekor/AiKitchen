package com.N3k0chan.aikitchen

import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import es.antonborri.home_widget.HomeWidgetPlugin

/// Botón del panel de ajustes rápidos que abre la lista de la compra y muestra
/// cuántos artículos quedan pendientes.
class ShoppingListTileService : TileService() {

    /// Se dispara cada vez que el usuario despliega el panel, que es refresco
    /// suficiente: no hace falta avisar al tile desde la app.
    override fun onStartListening() {
        super.onStartListening()

        val tile = qsTile ?: return
        val pending = HomeWidgetPlugin.getData(this).getInt("pending_count", 0)

        tile.state = Tile.STATE_ACTIVE
        tile.subtitle = if (pending == 0) {
            getString(R.string.qs_tile_empty)
        } else {
            resources.getQuantityString(R.plurals.qs_tile_pending, pending, pending)
        }
        tile.updateTile()
    }

    override fun onClick() {
        super.onClick()
        startActivityAndCollapse(WidgetUris.openShoppingList(this))
    }
}
