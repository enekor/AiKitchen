import 'package:aikitchen/AI/by_ingredients/find_by_ingredients.dart';
import 'package:aikitchen/AI/by_name/find_by_name.dart';
import 'package:aikitchen/AI/favourites/favourites.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/screens/create_recipe.dart';
import 'package:aikitchen/screens/recipe_screen.dart';
import 'package:aikitchen/screens/settings.dart';
import 'package:aikitchen/screens/shopping_list.dart';
import 'package:aikitchen/screens/weekly_menu.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/web/search/search_screen.dart';
import 'package:aikitchen/web/web_features.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class FeatureSelector extends StatefulWidget {
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
        'Monday': 'Lunes', 'Tuesday': 'Martes', 'Wednesday': 'Miércoles',
        'Thursday': 'Jueves', 'Friday': 'Viernes', 'Saturday': 'Sábado', 'Sunday': 'Domingo',
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

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            collapsedHeight: 80,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI Kitchen',
                    style: GoogleFonts.robotoFlex(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -1,
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.settings_rounded),
                    onPressed: () => _navigateTo(context, Settings(), title: 'Ajustes', subtitle: 'Personaliza tu experiencia'),
                  ),
                ],
              ),
            ),
          ),
          if (_todayMenu != null && _todayMenu!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: _TodayMenuCard(
                  dayName: _currentDayName!,
                  recipes: _todayMenu!,
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildListDelegate([
                _CombinedAICard(
                  onNameTap: () => _navigateTo(context, const FindByName(), title: 'Buscar', subtitle: 'Inspiración para hoy'),
                  onIngredientsTap: () => _navigateTo(context, const FindByIngredients(), title: 'Tu Nevera', subtitle: 'Cocina con lo que tienes'),
                ),
                _FeatureCard(
                  title: 'Internet',
                  icon: Icons.cloud_rounded,
                  color: theme.colorScheme.tertiary,
                  onTap: () => _navigateTo(context, const LidSearchScreen(), title: 'Internet', subtitle: 'Recetas externas'),
                ),
                _FeatureCard(
                  title: 'Mi Menú',
                  icon: Icons.calendar_today_rounded,
                  color: Colors.deepPurpleAccent,
                  onTap: () => _navigateTo(context, const WeeklyMenu(), title: 'Mi Menú', subtitle: 'Planificación inteligente'),
                ),
                _FeatureCard(
                  title: 'Favoritos',
                  icon: Icons.favorite_rounded,
                  color: Colors.redAccent,
                  onTap: () => _navigateTo(context, const Favourites(), title: 'Favoritos', subtitle: 'Tus recetas guardadas'),
                ),
                _FeatureCard(
                  title: 'La Compra',
                  icon: Icons.shopping_bag_rounded,
                  color: Colors.orange,
                  onTap: () => _navigateTo(context, const ShoppingList(), title: 'La Compra', subtitle: 'Lo que necesitas'),
                ),
                _FeatureCard(
                  title: 'Crear',
                  icon: Icons.add_rounded,
                  color: Colors.green,
                  onTap: () => _navigateTo(context, const CreateRecipe(), title: 'Crear Receta', subtitle: 'Tu propia magia'),
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page, {String? title, String? subtitle}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _PageWrapper(child: page, title: title, subtitle: subtitle)),
    ).then((_) => _loadTodayMenu());
  }
}

class _CombinedAICard extends StatelessWidget {
  final VoidCallback onNameTap;
  final VoidCallback onIngredientsTap;

  const _CombinedAICard({required this.onNameTap, required this.onIngredientsTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Expanded(
            child: InkWell(
              onTap: onNameTap,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Nombre', style: GoogleFonts.robotoFlex(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.primary.withOpacity(0.1)),
          Expanded(
            child: InkWell(
              onTap: onIngredientsTap,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.kitchen_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Ingredientes', style: GoogleFonts.robotoFlex(fontWeight: FontWeight.w700)),
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

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232D3F),
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                'PARA HOY',
                style: GoogleFonts.robotoFlex(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...recipes.asMap().entries.map((entry) {
            final recipe = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RecipeScreen(recipe: recipe)),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe.nombre,
                          style: GoogleFonts.robotoFlex(fontWeight: FontWeight.w600, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white70),
                    ],
                  ),
                ),
              ),
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
    
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 45, 20, 10),
            child: Row(
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.arrow_back_rounded, size: 28),
                  padding: const EdgeInsets.all(12),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                if (title != null) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title!,
                          style: GoogleFonts.robotoFlex(
                            textStyle: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Text(
                            subtitle!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: color.withOpacity(0.05)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.robotoFlex(
                fontWeight: FontWeight.w800,
                color: color.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
