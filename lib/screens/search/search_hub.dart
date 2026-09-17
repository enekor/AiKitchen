import 'package:aikitchen/AI/by_ingredients/find_by_ingredients.dart';
import 'package:aikitchen/AI/by_name/find_by_name.dart';
import 'package:aikitchen/AI/from_url/recipe_from_url.dart';
import 'package:aikitchen/navigation/app_shell_controller.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/web/search/search_screen.dart';
import 'package:aikitchen/widgets/ui/ui.dart';
import 'package:flutter/material.dart';

/// Centro de búsqueda con cuatro modos: por nombre, por ingredientes, de
/// internet y desde una URL. Cada modo conserva su estado al cambiar de modo,
/// gracias al `IndexedStack`.
///
/// Como todos los destinos del armazón, este widget se construye una sola vez
/// y se mantiene vivo mientras dura la sesión: `initState` no vuelve a
/// ejecutarse al volver a esta pestaña. Por eso el modo pedido desde Inicio se
/// aplica escuchando al controlador de forma continua y no solo al arrancar;
/// leerlo únicamente en `initState` hacía que, tras la primera visita, Buscar
/// se quedara siempre en el último modo que el propio usuario hubiera tocado
/// dentro de la pantalla, ignorando los accesos rápidos de Inicio.
class SearchHub extends StatefulWidget {
  const SearchHub({super.key});

  @override
  State<SearchHub> createState() => _SearchHubState();
}

class _SearchHubState extends State<SearchHub> {
  static const _modes = [
    SearchMode.byName,
    SearchMode.byIngredients,
    SearchMode.web,
    SearchMode.fromUrl,
  ];

  static const _labels = {
    SearchMode.byName: 'Por nombre',
    SearchMode.byIngredients: 'Por ingredientes',
    SearchMode.web: 'De internet',
    SearchMode.fromUrl: 'Desde una URL',
  };

  late SearchMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = AppShellController.instance.consumePendingSearchMode() ??
        SearchMode.byName;
    // Este widget no se reconstruye al volver a la pestaña, así que hace
    // falta escuchar cada vez que Inicio (u otra pantalla) pide un modo
    // concreto, no solo comprobarlo una vez al crearse.
    AppShellController.instance.addListener(_applyPendingMode);
  }

  @override
  void dispose() {
    AppShellController.instance.removeListener(_applyPendingMode);
    super.dispose();
  }

  void _applyPendingMode() {
    final pending = AppShellController.instance.consumePendingSearchMode();
    if (pending != null && pending != _mode) {
      setState(() => _mode = pending);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.md,
            ),
            child: FilterChipBar<SearchMode>(
              options: _modes,
              labelOf: (m) => _labels[m]!,
              selected: _mode,
              onChanged: (m) => setState(() => _mode = m),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: IndexedStack(
              index: _modes.indexOf(_mode),
              children: const [
                FindByName(),
                FindByIngredients(),
                LidSearchScreen(),
                RecipeFromUrl(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
