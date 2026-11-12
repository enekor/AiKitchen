import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/navigation/app_routes.dart';
import 'package:aikitchen/navigation/app_shell_controller.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/kitchen_timers.dart';
import 'package:aikitchen/services/pantry_service.dart';
import 'package:aikitchen/services/recetario_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/utils/step_durations.dart';
import 'package:aikitchen/widgets/diet_preferences.dart';
import 'package:aikitchen/widgets/ui/ui.dart';
import 'package:flutter/material.dart';

/// Pantalla de inicio nueva.
///
/// Prioriza lo que se hace a diario: buscar una receta, ver qué toca hoy y
/// empezar a cocinarlo. Se usa sobre todo en tabletas en horizontal, así que
/// a partir de [Breakpoints.expanded] se reparte en dos columnas en vez de
/// estirar una sola de lado a lado.
class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({super.key, this.loader});

  /// Para pruebas: sustituye la lectura del almacenamiento.
  @visibleForTesting
  final Future<HomeSnapshot> Function()? loader;

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen> {
  static const _dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  static const _meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  List<Recipe>? _todayMenu;
  List<Recipe> _favourites = const [];
  int _pendingShopping = 0;

  @override
  void initState() {
    super.initState();
    _load();
    PantryService.instance.load();
    // Inicio no se reconstruye al volver a la pestaña: se recarga al volver.
    AppShellController.instance.addListener(_onShellChanged);
    // El consejo de la despensa depende de si está vacía.
    PantryService.instance.addListener(_onPantryChanged);
  }

  @override
  void dispose() {
    AppShellController.instance.removeListener(_onShellChanged);
    PantryService.instance.removeListener(_onPantryChanged);
    super.dispose();
  }

  void _onPantryChanged() {
    if (mounted) setState(() {});
  }

  void _onShellChanged() {
    if (AppShellController.instance.tab == AppShellTab.home) _load();
  }

  Future<void> _load() async {
    HomeSnapshot data;
    try {
      data = await (widget.loader ?? _readStorage)();
    } catch (e) {
      // Sin datos, Inicio se muestra vacío; mejor que una pantalla rota.
      debugPrint('No se pudieron cargar los datos de Inicio: $e');
      return;
    }
    if (!mounted) return;
    setState(() {
      final today = data.menu[_dias[DateTime.now().weekday - 1]];
      _todayMenu = (today == null || today.isEmpty) ? null : today;
      _favourites = ([...data.favourites]
            // Sin fecha en el modelo, el id más alto es la última guardada.
            ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0)))
          .take(8)
          .toList();
      _pendingShopping = data.cart.where((i) => !i.isPurchased).length;
    });
  }

  static Future<HomeSnapshot> _readStorage() async {
    final storage = JsonDocumentsService();
    final results = await Future.wait([
      storage.loadWeeklyMenu(),
      storage.getFavRecipes(),
      storage.getCartItems(),
    ]);
    return HomeSnapshot(
      menu: results[0] as Map<String, List<Recipe>>,
      favourites: results[1] as List<Recipe>,
      cart: results[2] as List<CartItem>,
    );
  }

  void _openRecipe(Recipe recipe) {
    Navigator.pushNamed(
      context,
      AppRoutes.recipe,
      arguments: RecipeScreenArguments(recipe: recipe),
    );
  }

  void _cook(Recipe recipe) {
    Navigator.pushNamed(
      context,
      AppRoutes.cookingMode,
      arguments: RecipeScreenArguments(recipe: recipe),
    );
  }

  void _goSearch(SearchMode mode) =>
      AppShellController.instance.goTo(AppShellTab.search, searchMode: mode);

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 13) return 'Buenos días';
    if (hour < 21) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String get _dateLabel {
    final now = DateTime.now();
    return '${_dias[now.weekday - 1]}, ${now.day} de ${_meses[now.month - 1]}';
  }

  /// Un único consejo, solo si hay algo útil que descubrir. Desaparece en
  /// cuanto el usuario usa la función.
  _TipData? get _tip {
    if (_favourites.isNotEmpty && !_favourites.any((r) => r.tieneFoto)) {
      return const _TipData(
        Icons.add_a_photo_outlined,
        'Añade la foto de tu plato desde Favoritos con el icono de la cámara. '
        'Viaja con la receta cuando la compartes.',
      );
    }
    if (PantryService.instance.isEmpty) {
      return const _TipData(
        Icons.inventory_2_outlined,
        'Apunta en la Despensa lo que tienes en casa: las recetas lo marcarán '
        'y no se añadirá a la lista de la compra.',
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final wide = width >= Breakpoints.expanded;
              final compact = Breakpoints.isCompact(width);
              final hPadding = compact ? Spacing.lg : Spacing.xxl;

              return ListView(
                padding: EdgeInsets.fromLTRB(hPadding, Spacing.md, hPadding, Spacing.xxl),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: wide ? _wideLayout() : _singleColumn(compact: compact),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- Layouts

  /// Tableta en horizontal: lo de hoy a la izquierda, explorar a la derecha.
  Widget _wideLayout() {
    final tip = _tip;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const SizedBox(height: Spacing.lg),
              _SearchBar(onTap: () => _goSearch(SearchMode.byName)),
              const SizedBox(height: Spacing.md),
              _statusChips(scrollable: false),
              const SizedBox(height: Spacing.xl),
              _today(),
              if (tip != null) ...[
                const SizedBox(height: Spacing.lg),
                _Tip(data: tip),
              ],
            ],
          ),
        ),
        const SizedBox(width: Spacing.xxl),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Alinea los títulos de la derecha con el saludo de la izquierda.
              const SizedBox(height: Spacing.sm),
              const _SectionTitle('¿Qué te apetece?'),
              const SizedBox(height: Spacing.md),
              _actions(columns: 2, tall: true),
              const SizedBox(height: Spacing.xl),
              _favouritesSection(grid: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _singleColumn({required bool compact}) {
    final tip = _tip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(),
        const SizedBox(height: Spacing.lg),
        _SearchBar(onTap: () => _goSearch(SearchMode.byName)),
        const SizedBox(height: Spacing.md),
        _statusChips(scrollable: compact),
        const SizedBox(height: Spacing.xl),
        _today(),
        const SizedBox(height: Spacing.xl),
        const _SectionTitle('¿Qué te apetece?'),
        const SizedBox(height: Spacing.md),
        _actions(columns: compact ? 2 : 4, tall: false),
        const SizedBox(height: Spacing.xl),
        _favouritesSection(grid: false),
        if (tip != null) ...[
          const SizedBox(height: Spacing.xl),
          _Tip(data: tip),
        ],
      ],
    );
  }

  // ------------------------------------------------------------ Secciones

  Widget _header() {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _dateLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                '$_greeting,\n¿qué cocinamos hoy?',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          tooltip: 'Ajustes',
          // Tono neutro: es una acción secundaria y no debe competir con el
          // buscador ni con el menú de hoy.
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            foregroundColor: theme.colorScheme.onSurfaceVariant,
          ),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }

  Widget _statusChips({required bool scrollable}) {
    final theme = Theme.of(context);
    final tones = _Tones.of(theme);

    return ListenableBuilder(
      listenable: Listenable.merge([
        AppSingleton().preferenciasCambiadas,
        PantryService.instance,
        KitchenTimers.instance,
      ]),
      builder: (context, _) {
        final prefs = AppSingleton().preferenciasCocina;
        final timers = KitchenTimers.instance;
        final pantryCount = PantryService.instance.items.length;

        final chips = <Widget>[
          _StatusChip(
            icon: prefs.length > 1 ? Icons.no_food_outlined : Icons.eco_outlined,
            label: prefs.map((t) => t.label).join(' · '),
            background: tones.greenBg,
            foreground: tones.greenFg,
            tooltip: 'Cambiar dieta y alergias',
            onTap: () => DietPreferencesSheet.show(context),
          ),
          if (_pendingShopping > 0)
            _StatusChip(
              icon: Icons.shopping_cart_outlined,
              label: '$_pendingShopping por comprar',
              background: tones.warmBg,
              foreground: tones.warmFg,
              onTap: () => AppShellController.instance.goTo(AppShellTab.shoppingList),
            ),
          for (final timer in timers.timers)
            _StatusChip(
              icon: timer.isFinished
                  ? Icons.alarm_on_rounded
                  : (timer.isPaused ? Icons.pause_rounded : Icons.timer_outlined),
              label: '${timer.label} · '
                  '${timer.isFinished ? '¡Listo!' : formatCountdown(timers.remaining(timer))}',
              background: theme.colorScheme.errorContainer,
              foreground: theme.colorScheme.onErrorContainer,
              tooltip: timer.isFinished ? 'Quitar' : (timer.isPaused ? 'Reanudar' : 'Pausar'),
              onTap: () => timer.isFinished ? timers.cancel(timer) : timers.togglePause(timer),
            ),
          _StatusChip(
            icon: Icons.inventory_2_outlined,
            label: pantryCount == 0 ? 'Despensa vacía' : '$pantryCount en despensa',
            background: theme.colorScheme.surfaceContainerLow,
            foreground: theme.colorScheme.onSurface,
            outlined: true,
            onTap: () => Navigator.pushNamed(context, AppRoutes.pantry),
          ),
        ];

        if (!scrollable) {
          return Wrap(spacing: Spacing.sm, runSpacing: Spacing.sm, children: chips);
        }
        // En móvil, una fila deslizable en vez de varias líneas de chips.
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: chips.length,
            separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
            itemBuilder: (_, i) => chips[i],
          ),
        );
      },
    );
  }

  Widget _today() {
    final menu = _todayMenu;
    if (menu == null) {
      return _EmptyTodayCard(
        onCreate: () => AppShellController.instance.goTo(AppShellTab.weeklyMenu),
      );
    }
    // Hasta las cinco de la tarde se propone la comida; después, la cena.
    final cookIndex = DateTime.now().hour < 17 || menu.length == 1 ? 0 : menu.length - 1;
    return _TodayCard(
      recipes: menu,
      cookIndex: cookIndex,
      onOpen: _openRecipe,
      onCook: () => _cook(menu[cookIndex]),
      onWeek: () => AppShellController.instance.goTo(AppShellTab.weeklyMenu),
    );
  }

  Widget _actions({required int columns, required bool tall}) {
    final tones = _Tones.of(Theme.of(context));
    final scheme = Theme.of(context).colorScheme;
    final tiles = [
      _ActionTile(
        icon: Icons.search_rounded,
        title: 'Por nombre',
        subtitle: '"Paella", "algo con pollo"',
        background: scheme.surfaceContainerHigh,
        foreground: scheme.onSurface,
        iconColor: scheme.primary,
        onTap: () => _goSearch(SearchMode.byName),
      ),
      _ActionTile(
        icon: Icons.kitchen_rounded,
        title: 'Con lo que tengo',
        subtitle: 'Usa tu despensa',
        background: tones.greenBg,
        foreground: tones.greenFg,
        iconColor: tones.greenFg,
        onTap: () => _goSearch(SearchMode.byIngredients),
      ),
      _ActionTile(
        icon: Icons.calendar_month_rounded,
        title: 'Menú semanal',
        subtitle: '7 días planificados',
        background: tones.warmBg,
        foreground: tones.warmFg,
        iconColor: tones.warmAccent,
        onTap: () => AppShellController.instance.goTo(AppShellTab.weeklyMenu),
      ),
      _ActionTile(
        icon: Icons.edit_note_rounded,
        title: 'Crear receta',
        subtitle: 'La de toda la vida',
        background: scheme.surfaceContainerLow,
        foreground: scheme.onSurface,
        iconColor: scheme.secondary,
        outlined: true,
        onTap: () => Navigator.pushNamed(context, AppRoutes.createRecipe),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: Spacing.md,
            mainAxisSpacing: Spacing.md,
            // Altura fija y no proporción: el texto ocupa lo mismo sea cual
            // sea el ancho, y una proporción dejaba tarjetas enormes en
            // tableta.
            mainAxisExtent: tall ? 128 : 112,
          ),
          children: tiles,
        ),
        const SizedBox(height: Spacing.md),
        // A lo ancho y no como una quinta casilla: así la cuadrícula queda
        // completa tanto a dos como a cuatro columnas.
        _ActionTile(
          icon: Icons.menu_book_rounded,
          title: 'Nuestro recetario',
          subtitle: 'Recetas de ${RecetarioService.canal}',
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
          iconColor: scheme.onSecondaryContainer,
          horizontal: true,
          onTap: () => _goSearch(SearchMode.recetario),
        ),
      ],
    );
  }

  Widget _favouritesSection({required bool grid}) {
    if (_favourites.isEmpty) {
      // En tableta la columna derecha quedaría casi vacía: se explica qué
      // aparecerá ahí. En móvil no hace falta, la pantalla ya va llena.
      return grid ? const _EmptyFavourites() : const SizedBox.shrink();
    }
    final header = _SectionTitle(
      'Tus favoritas',
      action: 'Ver todas',
      onAction: () => AppShellController.instance.goTo(AppShellTab.favourites),
    );

    if (!grid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: Spacing.md),
          SizedBox(
            height: 214,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _favourites.length,
              separatorBuilder: (_, _) => const SizedBox(width: Spacing.md),
              itemBuilder: (_, i) => SizedBox(
                width: 168,
                child: _FavouriteTile(
                  recipe: _favourites[i],
                  onTap: () => _openRecipe(_favourites[i]),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // En tableta, cuadrícula: con ancho de sobra un carrusel esconde
    // contenido sin motivo.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: Spacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / 190).floor().clamp(2, 4);
            final visible = _favourites.take(columns * 2).toList();
            final tileWidth =
                (constraints.maxWidth - Spacing.md * (columns - 1)) / columns;
            return Wrap(
              spacing: Spacing.md,
              runSpacing: Spacing.lg,
              children: [
                for (final recipe in visible)
                  SizedBox(
                    width: tileWidth,
                    child: _FavouriteTile(
                      recipe: recipe,
                      onTap: () => _openRecipe(recipe),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Datos que muestra Inicio.
class HomeSnapshot {
  const HomeSnapshot({
    this.menu = const {},
    this.favourites = const [],
    this.cart = const [],
  });

  final Map<String, List<Recipe>> menu;
  final List<Recipe> favourites;
  final List<CartItem> cart;
}

// ------------------------------------------------------------- Componentes

/// Tonos verde y cálido que el tema no define, ajustados a claro y oscuro.
class _Tones {
  const _Tones({
    required this.greenBg,
    required this.greenFg,
    required this.warmBg,
    required this.warmFg,
    required this.warmAccent,
  });

  final Color greenBg;
  final Color greenFg;
  final Color warmBg;
  final Color warmFg;
  final Color warmAccent;

  static _Tones of(ThemeData theme) => theme.brightness == Brightness.dark
      ? const _Tones(
          greenBg: Color(0xFF14301F),
          greenFg: Color(0xFFA6E8BE),
          warmBg: Color(0xFF3A2416),
          warmFg: Color(0xFFFFD2B3),
          warmAccent: Color(0xFFFF9A57),
        )
      : const _Tones(
          greenBg: Color(0xFFE3F6EA),
          greenFg: Color(0xFF0E5A2E),
          warmBg: Color(0xFFFFF1E6),
          warmFg: Color(0xFF8A3B00),
          warmAccent: Color(0xFFE8722A),
        );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      elevation: 1,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.sm, Spacing.sm, Spacing.sm),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  'Busca una receta…',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: const Text('Con IA'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.tooltip,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final String? tooltip;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chip = Material(
      color: background,
      shape: StadiumBorder(
        side: outlined
            ? BorderSide(color: theme.colorScheme.outlineVariant)
            : BorderSide.none,
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: Spacing.xs + 2),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

/// Menú de hoy, con un botón directo al modo cocina.
class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.recipes,
    required this.cookIndex,
    required this.onOpen,
    required this.onCook,
    required this.onWeek,
  });

  final List<Recipe> recipes;
  final int cookIndex;
  final ValueChanged<Recipe> onOpen;
  final VoidCallback onCook;
  final VoidCallback onWeek;

  static const _labels = ['Comida', 'Cena'];
  static const _icons = [Icons.wb_sunny_outlined, Icons.dark_mode_outlined];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const onCard = Colors.white;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg + 8),
        // Mismo degradado en claro y en oscuro: el texto blanco contrasta en
        // ambos y la tarjeta destaca igual.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B5FB8), Color(0xFF4648D4), Color(0xFF7A4BD8)],
        ),
      ),
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'HOY EN TU MENÚ',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: onCard.withValues(alpha: 0.9),
                    letterSpacing: 1,
                  ),
                ),
              ),
              TextButton(
                onPressed: onWeek,
                style: TextButton.styleFrom(foregroundColor: onCard),
                child: const Text('Semana ›'),
              ),
            ],
          ),
          for (var i = 0; i < recipes.length; i++) ...[
            const SizedBox(height: Spacing.sm),
            Material(
              color: onCard.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () => onOpen(recipes[i]),
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: onCard.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          i < _icons.length ? _icons[i] : Icons.restaurant_rounded,
                          color: onCard,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (i < _labels.length ? _labels[i] : 'Plato ${i + 1}').toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: onCard.withValues(alpha: 0.8),
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              recipes[i].nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: onCard,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${recipes[i].tiempoEstimado} · ${recipes[i].calorias} kcal',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: onCard.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: onCard),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: Spacing.md),
          FilledButton.icon(
            onPressed: onCook,
            style: FilledButton.styleFrom(
              backgroundColor: onCard,
              foregroundColor: const Color(0xFF0B3F80),
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.soup_kitchen_rounded),
            label: Text(
              'Empezar a cocinar la '
              '${(cookIndex < _labels.length ? _labels[cookIndex] : 'receta').toLowerCase()}',
            ),
          ),
        ],
      ),
    );
  }
}

/// Sin menú: invitación a crearlo que explica para qué sirve.
class _EmptyTodayCard extends StatelessWidget {
  const _EmptyTodayCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg + 8),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.edit_calendar_rounded, size: 32, color: theme.colorScheme.primary),
          const SizedBox(height: Spacing.md),
          Text(
            'Planifica tu semana en un toque',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'La IA prepara comida y cena para 7 días con tu dieta, y luego te hace '
            'la lista de la compra descontando lo que ya tienes.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          AiButton(label: 'Crear mi menú', onPressed: onCreate),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.background,
    required this.foreground,
    required this.iconColor,
    required this.onTap,
    this.outlined = false,
    this.horizontal = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color background;
  final Color foreground;
  final Color iconColor;
  final VoidCallback onTap;
  final bool outlined;

  /// Icono a la izquierda y texto al lado, para la tarjeta a lo ancho.
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg + 4);
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: foreground.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: outlined
            ? BorderSide(color: theme.colorScheme.outlineVariant)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: horizontal
              ? Row(
                  children: [
                    Icon(icon, size: 28, color: iconColor),
                    const SizedBox(width: Spacing.md),
                    Expanded(child: texts),
                    Icon(Icons.chevron_right_rounded, color: foreground),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, size: 28, color: iconColor),
                    texts,
                  ],
                ),
        ),
      ),
    );
  }
}

/// Favorita con su foto o, si no tiene, un fondo de color con un icono.
class _FavouriteTile extends StatelessWidget {
  const _FavouriteTile({required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg + 2);
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surfaceContainerHigh,
            theme.colorScheme.surfaceContainerHighest,
          ],
        ),
      ),
      child: Center(
        child: Icon(Icons.restaurant_rounded, size: 40, color: theme.colorScheme.primary),
      ),
    );

    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: radius,
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RecipePhoto(recipe: recipe, aspectRatio: 4 / 3, fallback: fallback),
                  if (recipe.etiquetas.isNotEmpty)
                    Positioned(
                      left: Spacing.sm,
                      bottom: Spacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          recipe.etiquetas.first,
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            recipe.nombre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            '${recipe.tiempoEstimado} · ${recipe.raciones} raciones',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFavourites extends StatelessWidget {
  const _EmptyFavourites();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Tus favoritas'),
        const SizedBox(height: Spacing.md),
        Container(
          padding: const EdgeInsets.all(Spacing.xl),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg + 4),
          ),
          child: Row(
            children: [
              Icon(Icons.bookmark_add_outlined, size: 32, color: theme.colorScheme.primary),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Text(
                  'Guarda las recetas que te gusten con el marcador y '
                  'aparecerán aquí, con la foto de tu plato si se la añades.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TipData {
  const _TipData(this.icon, this.text);

  final IconData icon;
  final String text;
}

class _Tip extends StatelessWidget {
  const _Tip({required this.data});

  final _TipData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: theme.colorScheme.tertiary),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Consejo\n',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  TextSpan(text: data.text),
                ],
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Icon(data.icon, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
