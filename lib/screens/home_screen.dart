import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/navigation/app_routes.dart';
import 'package:aikitchen/navigation/app_shell_controller.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/content_shell.dart';
import 'package:aikitchen/widgets/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Pantalla de inicio: menú del día, accesos rápidos y últimas guardadas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Recipe>? _todayMenu;
  String? _currentDayName;
  List<Recipe> _recentFavourites = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([_loadTodayMenu(), _loadRecentFavourites()]);
  }

  Future<void> _loadTodayMenu() async {
    final menu = await JsonDocumentsService().loadWeeklyMenu();
    if (menu.isEmpty) return;

    const dayTranslations = {
      'Monday': 'Lunes',
      'Tuesday': 'Martes',
      'Wednesday': 'Miércoles',
      'Thursday': 'Jueves',
      'Friday': 'Viernes',
      'Saturday': 'Sábado',
      'Sunday': 'Domingo',
    };
    final englishDay = DateFormat('EEEE').format(DateTime.now());
    final dayName = dayTranslations[englishDay];

    if (dayName != null && menu.containsKey(dayName) && mounted) {
      setState(() {
        _todayMenu = menu[dayName];
        _currentDayName = dayName;
      });
    }
  }

  Future<void> _loadRecentFavourites() async {
    final favourites = await JsonDocumentsService().getFavRecipes();
    // Sin fecha en el modelo, el id más alto es la última guardada.
    final sorted = [...favourites]
      ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    if (mounted) {
      setState(() => _recentFavourites = sorted.take(3).toList());
    }
  }

  void _openRecipe(Recipe recipe) {
    Navigator.pushNamed(
      context,
      AppRoutes.recipe,
      arguments: RecipeScreenArguments(recipe: recipe),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Kitchen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ajustes',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
          const SizedBox(width: Spacing.sm),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
          children: [
            ContentShell.wide(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: 'Para hoy',
                    actionText: _todayMenu != null ? 'Semana completa' : null,
                    onAction: () =>
                        AppShellController.instance.goTo(AppShellTab.weeklyMenu),
                  ),
                  const SizedBox(height: Spacing.md),
                  if (_todayMenu != null && _todayMenu!.isNotEmpty)
                    _TodayMenuCard(
                      dayName: _currentDayName!,
                      recipes: _todayMenu!,
                      onOpenRecipe: _openRecipe,
                    )
                  else
                    AppCard(
                      child: Row(
                        children: [
                          Icon(
                            Icons.restaurant_menu_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Text(
                              'Aún no tienes un menú semanal. Genera uno para ver aquí la comida y la cena de hoy.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: () => AppShellController.instance
                                .goTo(AppShellTab.weeklyMenu),
                            child: const Text('Generar'),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: Spacing.xl),
                  SectionHeader(title: 'Accesos rápidos'),
                  const SizedBox(height: Spacing.md),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: Breakpoints.isCompact(
                          MediaQuery.sizeOf(context).width,
                        )
                        ? 2
                        : 4,
                    crossAxisSpacing: Spacing.md,
                    mainAxisSpacing: Spacing.md,
                    childAspectRatio: 1.1,
                    children: [
                      _QuickAccessCard(
                        icon: Icons.search_rounded,
                        label: 'Por nombre',
                        onTap: () => AppShellController.instance.goTo(
                          AppShellTab.search,
                          searchMode: SearchMode.byName,
                        ),
                      ),
                      _QuickAccessCard(
                        icon: Icons.kitchen_rounded,
                        label: 'Por ingredientes',
                        onTap: () => AppShellController.instance.goTo(
                          AppShellTab.search,
                          searchMode: SearchMode.byIngredients,
                        ),
                      ),
                      _QuickAccessCard(
                        icon: Icons.cloud_outlined,
                        label: 'De internet',
                        onTap: () => AppShellController.instance.goTo(
                          AppShellTab.search,
                          searchMode: SearchMode.web,
                        ),
                      ),
                      _QuickAccessCard(
                        icon: Icons.calendar_today_rounded,
                        label: 'Plan semanal',
                        onTap: () => AppShellController.instance
                            .goTo(AppShellTab.weeklyMenu),
                      ),
                      _QuickAccessCard(
                        icon: Icons.shopping_cart_rounded,
                        label: 'Lista de la compra',
                        onTap: () => AppShellController.instance
                            .goTo(AppShellTab.shoppingList),
                      ),
                      _QuickAccessCard(
                        icon: Icons.link_rounded,
                        label: 'Importar URL',
                        onTap: () => AppShellController.instance.goTo(
                          AppShellTab.search,
                          searchMode: SearchMode.fromUrl,
                        ),
                      ),
                      _QuickAccessCard(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Crear receta',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.createRecipe),
                      ),
                      _QuickAccessCard(
                        icon: Icons.bookmark_outline_rounded,
                        label: 'Favoritos',
                        onTap: () => AppShellController.instance
                            .goTo(AppShellTab.favourites),
                      ),
                    ],
                  ),
                  if (_recentFavourites.isNotEmpty) ...[
                    const SizedBox(height: Spacing.xl),
                    SectionHeader(
                      title: 'Guardadas recientemente',
                      actionText: 'Ver todas',
                      onAction: () => AppShellController.instance
                          .goTo(AppShellTab.favourites),
                    ),
                    const SizedBox(height: Spacing.md),
                    for (final recipe in _recentFavourites) ...[
                      RecipeCard(
                        recipe: recipe,
                        onTap: () => _openRecipe(recipe),
                        isFavorite: true,
                      ),
                      const SizedBox(height: Spacing.md),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: theme.colorScheme.primary),
          const SizedBox(height: Spacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class _TodayMenuCard extends StatelessWidget {
  const _TodayMenuCard({
    required this.dayName,
    required this.recipes,
    required this.onOpenRecipe,
  });

  final String dayName;
  final List<Recipe> recipes;
  final ValueChanged<Recipe> onOpenRecipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = ['Almuerzo', 'Cena'];

    return AppCard(
      color: theme.colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayName,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: Spacing.md),
          for (var i = 0; i < recipes.length; i++) ...[
            if (i > 0) const SizedBox(height: Spacing.sm),
            Material(
              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.08),
              borderRadius: AppRadius.medium,
              child: InkWell(
                borderRadius: AppRadius.medium,
                onTap: () => onOpenRecipe(recipes[i]),
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i < labels.length ? labels[i] : 'Plato ${i + 1}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              recipes[i].nombre,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
