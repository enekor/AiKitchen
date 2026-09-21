package com.N3k0chan.aikitchen

import android.app.StatusBarManager
import android.content.ComponentName
import android.graphics.drawable.Icon
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.function.Consumer

class MainActivity : FlutterActivity() {

    private companion object {
        const val CHANNEL = "aikitchen/quick_settings"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestAddTile" -> requestAddTile(result)
                    else -> result.notImplemented()
                }
            }
    }

    /// Android no deja colocar un botón en los ajustes rápidos sin permiso
    /// explícito, así que se pide por el diálogo del sistema.
    private fun requestAddTile(result: MethodChannel.Result) {
        getSystemService(StatusBarManager::class.java).requestAddTileService(
            ComponentName(this, ShoppingListTileService::class.java),
            getString(R.string.qs_tile_label),
            Icon.createWithResource(this, R.drawable.ic_shopping_cart),
            mainExecutor,
            Consumer { code ->
                result.success(
                    code == StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ADDED ||
                        code == StatusBarManager.TILE_ADD_REQUEST_RESULT_TILE_ALREADY_ADDED,
                )
            },
        )
    }
}
