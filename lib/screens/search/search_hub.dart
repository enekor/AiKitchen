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
    // Se consume una sola vez: si Inicio pidió abrir un modo concreto, se
    // respeta; si no, se mantiene el que ya se estuviera viendo.
    _mode = AppShellController.instance.consumePendingSearchMode() ??
        SearchMode.byName;
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
