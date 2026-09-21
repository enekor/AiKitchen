# Acceso rápido a la lista de la compra

Fecha: 2026-09-21

## Problema

Llegar a la lista de la compra cuesta demasiado. Hoy el único camino es abrir la
app y cambiar de pestaña, y una vez dentro la pantalla apila cinco bloques de
controles antes de mostrar un solo artículo. En el supermercado, con el móvil en
una mano, eso es fricción pura.

El acceso desde la pantalla de Inicio ya funciona bien y **no se modifica**.

## Estado de partida

El widget de pantalla de inicio de la lista de la compra nunca llegó a
existir, aunque el lado Dart se escribió como si existiera:

- `lib/services/widget_service.dart` empuja `shopping_list_items`,
  `pending_count`, `completed_count` y `last_updated`, y llama a
  `updateWidget` sobre `ShoppingListWidgetProvider`.
- `ShoppingListWidgetProvider.kt` y `ShoppingListRemoteViewsService.kt` existen
  pero están vacíos (0 bytes).
- No hay `res/layout/shopping_list_widget.xml` ni
  `res/xml/shopping_list_widget_info.xml`.
- `AndroidManifest.xml` no declara el `<receiver>` ni el `<service>`.

El widget de Favoritos sí está completo y es la plantilla a seguir.

Hay además un fallo latente en `WidgetService._toggleShoppingItem`: usa
`firstWhere` sin `orElse`, que lanza excepción si el artículo no aparece, y
busca **por nombre**, de modo que con dos artículos homónimos tacharía el
equivocado.

`minSdk = 36`, así que todas las APIs implicadas (tiles de ajustes rápidos,
`startActivityAndCollapse(PendingIntent)`, `Tile.setSubtitle`,
`requestAddTileService`) están disponibles sin comprobaciones de versión.

## Parte A — Widget de pantalla de inicio

### Ficheros

| Fichero | Papel |
|---|---|
| `ShoppingListWidgetProvider.kt` | `AppWidgetProvider`: cabecera, contador, adaptador remoto y acciones |
| `ShoppingListRemoteViewsService.kt` | `RemoteViewsFactory` sobre el JSON de `shopping_list_items` |
| `res/layout/shopping_list_widget.xml` | Cabecera + `ListView` + estado vacío + pie de acciones |
| `res/layout/shopping_item_widget.xml` | Fila: icono de casilla + nombre (tachado si está comprado) |
| `res/xml/shopping_list_widget_info.xml` | Metadatos: redimensionable, mínimo 3x2 celdas |
| `res/drawable/ic_check_box*.xml` | Casilla marcada y sin marcar |
| `AndroidManifest.xml` | `<receiver>` del proveedor y `<service>` del adaptador |

### Datos

`updatePeriodMillis="0"`: los datos se empujan desde la app en cada mutación de
la lista, así que no hace falta sondeo periódico.

El payload que manda Dart incorpora el `id` de cada artículo, y los pendientes
van primero para que lo relevante quede visible sin desplazar.

### Interacciones

- **Tocar una fila** tacha o destacha el artículo sin abrir la app, vía
  `HomeWidgetBackgroundIntent` sobre el `_backgroundCallback` ya registrado. La
  acción identifica el artículo **por `id`**, no por nombre.
- **Tocar la cabecera o "Abrir"** abre la app en la pestaña de lista, con
  `HomeWidgetLaunchIntent` y el URI `aikitchen://shopping_list`.
- **"Actualizar"** fuerza un `APPWIDGET_UPDATE`.

### Enlace profundo

`MainActivity` es un `FlutterActivity` desnudo y no lee ningún extra de intent,
por lo que el `putExtra("route", ...)` del widget de Favoritos no hace nada hoy.
En lugar de tocar Kotlin, el salto se resuelve en Dart: `HomeWidget.widgetClicked`
para la app ya viva y `initiallyLaunchedFromHomeWidget()` para el arranque en
frío, y ambos desembocan en
`AppShellController.goTo(AppShellTab.shoppingList)`.

## Parte B — Botón en ajustes rápidos

`ShoppingListTileService`, un `TileService`:

- `onStartListening` lee `pending_count` de los datos del widget y pinta el tile
  como "Lista de la compra" con subtítulo "N pendientes". Se dispara cada vez
  que el usuario despliega el panel, que es refresco suficiente.
- `onClick` abre la app reutilizando el mismo URI `aikitchen://shopping_list` de
  la Parte A.

Android no permite añadir tiles por código sin intervención del usuario, así que
Ajustes gana un botón **"Añadir a ajustes rápidos"** que lanza el diálogo del
sistema (`requestAddTileService`) para colocarlo en un toque.

## Parte C — Simplificar la pantalla de la lista

El orden actual es: dos tarjetas de estadísticas, botón de IA, segundo botón de
IA, campo de añadir, barra de ocho filtros y por fin la lista. Cambia a:

- **El campo de añadir artículo pasa arriba y se queda fijo.** Es la acción más
  frecuente.
- **Las dos tarjetas de estadísticas se sustituyen por una línea de progreso**:
  "3 de 12 comprados" con una barra. El mismo dato en una fracción del espacio.
- **Los dos generadores con IA, "Compartir lista" y "Vaciar comprados" se mueven
  al menú de desbordamiento** de la barra superior. Los generadores siguen
  apareciendo como botones grandes en el estado vacío, que es donde toca
  descubrirlos.
- **Los filtros por categoría solo se muestran si hay más de una categoría** con
  artículos pendientes.
- **Tocar cualquier punto de la fila la tacha** —hoy solo responde la casilla— y
  **borrar pasa a ser deslizar**, lo que retira un icono de papelera de cada
  fila.

## Verificación

- `flutter analyze` sin nuevos avisos.
- La app compila para Android (`flutter build apk --debug`).
- Repaso manual: el widget aparece en el selector, muestra los pendientes, una
  fila se tacha desde el escritorio y la app se abre en la pestaña correcta
  tanto en frío como estando ya abierta.

## Fuera de alcance

- La pantalla de Inicio y su acceso actual a la lista.
- El widget de Favoritos, más allá de compartir recursos de dibujo.
- iOS: no hay proyecto iOS con widgets en el repositorio.
