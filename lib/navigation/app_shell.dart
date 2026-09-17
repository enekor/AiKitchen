import 'package:aikitchen/navigation/app_shell_controller.dart';
import 'package:aikitchen/screens/favourites_screen.dart';
import 'package:aikitchen/screens/home_screen.dart';
import 'package:aikitchen/screens/search/search_hub.dart';
import 'package:aikitchen/screens/shopping_list.dart';
import 'package:aikitchen/screens/weekly_menu.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:flutter/material.dart';

/// Armazón con los cinco destinos persistentes de la aplicación.
///
/// Cada destino conserva su estado al cambiar de pestaña, gracias al
/// [IndexedStack]. La navegación cambia de forma según el ancho de ventana:
/// barra inferior en móvil, raíl lateral a partir de 600 px.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _Destination {
  const _Destination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.builder,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final WidgetBuilder builder;
}

class _AppShellState extends State<AppShell> {
  int _index = AppShellController.instance.tab;

  @override
  void initState() {
    super.initState();
    AppShellController.instance.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    AppShellController.instance.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() => _index = AppShellController.instance.tab);
  }

  static final List<_Destination> _destinations = [
    _Destination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Inicio',
      builder: (_) => const HomeScreen(),
    ),
    _Destination(
      icon: Icons.search_outlined,
      selectedIcon: Icons.search_rounded,
      label: 'Buscar',
      builder: (_) => const SearchHub(),
    ),
    _Destination(
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart_rounded,
      label: 'Lista compra',
      builder: (_) => const ShoppingList(),
    ),
    _Destination(
      icon: Icons.bookmark_border_rounded,
      selectedIcon: Icons.bookmark_rounded,
      label: 'Favoritos',
      builder: (_) => const FavouritesScreen(),
    ),
    _Destination(
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today_rounded,
      label: 'Menú',
      builder: (_) => const WeeklyMenu(),
    ),
  ];

  void _onSelect(int index) => AppShellController.instance.goTo(index);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final stack = IndexedStack(
      index: _index,
      children: [
        for (final destination in _destinations) destination.builder(context),
      ],
    );

    if (Breakpoints.isCompact(width)) {
      return Scaffold(
        body: stack,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onSelect,
          destinations: [
            for (final destination in _destinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label,
              ),
          ],
        ),
      );
    }

    final extended = width >= Breakpoints.railExtended;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: _onSelect,
            extended: extended,
            minExtendedWidth: 220,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: [
              for (final destination in _destinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: Text(destination.label),
                ),
            ],
          ),
          VerticalDivider(
            width: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Expanded(child: stack),
        ],
      ),
    );
  }
}
