import 'package:aikitchen/AI/by_ingredients/find_by_ingredients.dart';
import 'package:aikitchen/AI/by_name/find_by_name.dart';
import 'package:aikitchen/AI/from_url/recipe_from_url.dart';
import 'package:aikitchen/AI/favourites/favourites.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/screens/create_recipe.dart';
import 'package:aikitchen/screens/recipe_screen.dart';
import 'package:aikitchen/screens/settings.dart';
import 'package:aikitchen/screens/shopping_list.dart';
import 'package:aikitchen/screens/weekly_menu.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/web/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeatureSelector extends StatefulWidget {
  static const String routeName = '/inicio';

  const FeatureSelector({super.key});

  @override
  State<FeatureSelector> createState() => _FeatureSelectorState();
}

class _FeatureSelectorState extends State<FeatureSelector> {
  List<Recipe>? _todayMenu;
  String? _currentDayName;

  @override
  void initState() {
    super.initState();
    _loadTodayMenu();
  }

  Future<void> _loadTodayMenu() async {
    final menu = await JsonDocumentsService().loadWeeklyMenu();
    if (menu.isNotEmpty) {
      final now = DateTime.now();
      final dayFormat = DateFormat('EEEE');
      final englishDay = dayFormat.format(now);

      final Map<String, String> dayTranslations = {
        'Monday': 'Lunes',
        'Tuesday': 'Martes',
        'Wednesday': 'Miércoles',
        'Thursday': 'Jueves',
        'Friday': 'Viernes',
        'Saturday': 'Sábado',
        'Sunday': 'Domingo',
      };

      final dayName = dayTranslations[englishDay];
      if (dayName != null && menu.containsKey(dayName)) {
        setState(() {
          _todayMenu = menu[dayName];
          _currentDayName = dayName;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Se decide por ancho de ventana, no por orientación: un móvil tumbado y
    // un monitor son casos distintos aunque ambos sean apaisados.
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = Breakpoints.isCompact(width)
        ? Spacing.lg
        : Spacing.xxl;
    // El contenido se centra y se topa para que las tarjetas no se estiren
    // hasta tener el tamaño de una postal en pantallas grandes.
    final sideMargin = width > ContentWidth.wide
        ? (width - ContentWidth.wide) / 2
        : 0.0;
    final contentPadding = horizontalPadding + sideMargin;
    final shortViewport = MediaQuery.sizeOf(context).height < 700;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              // En apaisado sobra poca altura, así que la cabecera se encoge
              // en vez de comerse una quinta parte de la vista.
              expandedHeight: shortViewport ? 88 : 120,
              collapsedHeight: shortViewport ? 64 : 80,
              pinned: true,
              backgroundColor: theme.colorScheme.surface,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: EdgeInsets.symmetric(
                  horizontal: contentPadding,
                  vertical: Spacing.lg,
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI Kitchen',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.settings_rounded),
                      onPressed: () => _navigateTo(
                        context,
                        Settings(),
                        title: 'Ajustes',
                        subtitle: 'Personaliza tu experiencia',
                        route: '/ajustes',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_todayMenu != null && _todayMenu!.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: contentPadding,
                    vertical: Spacing.sm,
                  ),
                  child: _TodayMenuCard(
                    dayName: _currentDayName!,
                    recipes: _todayMenu!,
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: contentPadding,
                vertical: Spacing.xl,
              ),
              sliver: SliverGrid(
                // El número de columnas sale del ancho disponible, así que la
                // tarjeta mantiene un tamaño razonable en cualquier pantalla
                // en lugar de estirarse hasta deformarse.
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  crossAxisSpacing: Spacing.lg,
                  mainAxisSpacing: Spacing.lg,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildListDelegate([
                  _CombinedAICard(
                    onNameTap: () => _navigateTo(
                      context,
                      const FindByName(),
                      title: 'Buscar',
                      subtitle: 'Inspiración para hoy',
                      route: '/buscar',
                    ),
                    onIngredientsTap: () => _navigateTo(
                      context,
                      const FindByIngredients(),
                      title: 'Tu Nevera',
                      subtitle: 'Cocina con lo que tienes',
                      route: '/nevera',
                    ),
                  ),
                  _FeatureCard(
                    title: 'Internet',
                    icon: Icons.cloud_rounded,
                    color: theme.colorScheme.tertiary,
                    onTap: () => _navigateTo(
                      context,
                      const LidSearchScreen(),
                      title: 'Internet',
                      subtitle: 'Recetas externas',
                      route: '/internet',
                    ),
                  ),
                  _FeatureCard(
                    title: 'Mi Menú',
                    icon: Icons.calendar_today_rounded,
                    color: Colors.deepPurpleAccent,
                    onTap: () => _navigateTo(
                      context,
                      const WeeklyMenu(),
                      title: 'Mi Menú',
                      subtitle: 'Planificación inteligente',
                      route: '/menu',
                    ),
                  ),
                  _FeatureCard(
                    title: 'Favoritos',
                    icon: Icons.favorite_rounded,
                    color: Colors.redAccent,
                    onTap: () => _navigateTo(
                      context,
                      const Favourites(),
                      title: 'Favoritos',
                      subtitle: 'Tus recetas guardadas',
                      route: '/favoritos',
                    ),
                  ),
                  _FeatureCard(
                    title: 'La Compra',
                    icon: Icons.shopping_bag_rounded,
                    color: Colors.orange,
                    onTap: () => _navigateTo(
                      context,
                      const ShoppingList(),
                      title: 'La Compra',
                      subtitle: 'Lo que necesitas',
                      route: '/compra',
                    ),
                  ),
                  _FeatureCard(
                    title: 'Crear',
                    icon: Icons.add_rounded,
                    color: Colors.green,
                    onTap: () => _navigateTo(
                      context,
                      const CreateRecipe(),
                      title: 'Crear Receta',
                      subtitle: 'Tu propia magia',
                      route: '/crear',
                    ),
                  ),
                  _FeatureCard(
                    title: 'Desde URL',
                    icon: Icons.link_rounded,
                    color: Colors.teal,
                    onTap: () => _navigateTo(
                      context,
                      const RecipeFromUrl(),
                      title: 'Desde URL',
                      subtitle: 'Receta desde cualquier página',
                      route: '/desde-url',
                    ),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  void _navigateTo(
    BuildContext context,
    Widget page, {
    String? title,
    String? subtitle,
    required String route,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Dar nombre a la ruta hace que la barra de direcciones del navegador
        // refleje la pantalla actual, y con ello que el botón atrás funcione.
        settings: RouteSettings(name: route),
        builder: (context) =>
            _PageWrapper(child: page, title: title, subtitle: subtitle),
      ),
    ).then((_) => _loadTodayMenu());
  }
}

class _CombinedAICard extends StatelessWidget {
  final VoidCallback onNameTap;
  final VoidCallback onIngredientsTap;

  const _CombinedAICard({
    required this.onNameTap,
    required this.onIngredientsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      borderRadius: AppRadius.medium,
      child: Column(
        children: [
          Expanded(
            child: InkWell(
              onTap: onNameTap,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: Spacing.sm),
                  Text('Nombre', style: theme.textTheme.titleSmall),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          Expanded(
            child: InkWell(
              onTap: onIngredientsTap,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.kitchen_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: Spacing.sm),
                  Text('Ingredientes', style: theme.textTheme.titleSmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayMenuCard extends StatelessWidget {
  final String dayName;
  final List<Recipe> recipes;

  const _TodayMenuCard({required this.dayName, required this.recipes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Las recetas se ponen en fila solo si de verdad hay ancho para ello.
    final side = MediaQuery.sizeOf(context).width >= Breakpoints.medium;

    // Tarjeta destacada: se invierte la superficie en lugar de fijar un azul
    // oscuro y texto blanco, que en modo oscuro quedaba fuera de tono.
    final background = theme.colorScheme.inverseSurface;
    final foreground = theme.colorScheme.onInverseSurface;

    Widget buildRecipeItem(Recipe recipe) {
      return Material(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: AppRadius.medium,
        child: InkWell(
          borderRadius: AppRadius.medium,
          onTap: () => Navigator.pushNamed(
            context,
            RecipeScreen.routeName,
            arguments: RecipeScreenArguments(recipe: recipe),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    recipe.nombre,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: foreground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: foreground.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.medium,
      ),
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: foreground.withValues(alpha: 0.7),
                size: 18,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'PARA HOY',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          if (side && recipes.isNotEmpty)
            Row(
              children: recipes.asMap().entries.map((entry) {
                final isLast = entry.key == recipes.length - 1;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : Spacing.md),
                    child: buildRecipeItem(entry.value),
                  ),
                );
              }).toList(),
            )
          else
            ...recipes.map((recipe) {
              return Padding(
                padding: const EdgeInsets.only(bottom: Spacing.md),
                child: buildRecipeItem(recipe),
              );
            }),
        ],
      ),
    );
  }
}

class _PageWrapper extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;

  const _PageWrapper({required this.child, this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Se usa una AppBar real en lugar de una cabecera dibujada a mano con un
    // hueco fijo de 45 px que simulaba la barra de estado del móvil. En un
    // navegador ese hueco era espacio muerto.
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Volver',
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: title == null
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title!,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
      ),
      body: child,
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Color.alphaBlend(
        color.withValues(alpha: 0.10),
        theme.colorScheme.surface,
      ),
      borderRadius: AppRadius.medium,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.medium,
            // Un borde perceptible: con alfa 0,05 el contorno no se veía y la
            // tarjeta no parecía pulsable.
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: Spacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
