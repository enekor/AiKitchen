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
import 'package:flutter/material.dart';
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

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            collapsedHeight: 80,
            floating: true,
            pinned: true,
            stretch: true,
            backgroundColor: theme.colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AI Kitchen',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: -1,
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.settings_rounded),
                    onPressed: () => _navigateTo(context, Settings()),
                  ),
                ],
              ),
              background: Container(color: theme.colorScheme.surface),
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
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildListDelegate([
                _FeatureCard(
                  title: 'Receta por Nombre',
                  icon: Icons.search_rounded,
                  color: theme.colorScheme.primary,
                  onTap: () => _navigateTo(context, const FindByName()),
                ),
                _FeatureCard(
                  title: 'Por Nevera',
                  icon: Icons.kitchen_rounded,
                  color: theme.colorScheme.secondary,
                  onTap: () => _navigateTo(context, const FindByIngredients()),
                ),
                _FeatureCard(
                  title: 'Mi Menú',
                  icon: Icons.calendar_today_rounded,
                  color: theme.colorScheme.tertiary,
                  onTap: () => _navigateTo(context, const WeeklyMenu()),
                ),
                _FeatureCard(
                  title: 'Favoritos',
                  icon: Icons.favorite_rounded,
                  color: Colors.redAccent,
                  onTap: () => _navigateTo(context, const Favourites()),
                ),
                _FeatureCard(
                  title: 'La Compra',
                  icon: Icons.shopping_bag_rounded,
                  color: Colors.orange,
                  onTap: () => _navigateTo(context, const ShoppingList()),
                ),
                _FeatureCard(
                  title: 'Crear',
                  icon: Icons.add_rounded,
                  color: Colors.green,
                  onTap: () => _navigateTo(context, const CreateRecipe()),
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _PageWrapper(child: page)),
    ).then((_) => _loadTodayMenu());
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
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.colorScheme.onPrimaryContainer, size: 20),
              const SizedBox(width: 8),
              Text(
                'PARA HOY',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recipes.asMap().entries.map((entry) {
            final recipe = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => _PageWrapper(child: RecipeScreen(recipe: recipe))),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe.nombre,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded, size: 18, color: theme.colorScheme.onPrimaryContainer),
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
  const _PageWrapper({required this.child});

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
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: color.withOpacity(0.1), width: 1),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 42),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: color.withOpacity(0.8),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
