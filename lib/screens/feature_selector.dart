import 'package:aikitchen/AI/by_ingredients/find_by_ingredients.dart';
import 'package:aikitchen/AI/by_name/find_by_name.dart';
import 'package:aikitchen/AI/favourites/favourites.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/screens/create_recipe.dart';
import 'package:aikitchen/screens/recipe_screen.dart';
import 'package:aikitchen/screens/settings.dart';
import 'package:aikitchen/screens/shopping_list.dart';
import 'package:aikitchen/screens/weekly_menu.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:flutter/foundation.dart';
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
      // Obtener el día de la semana actual traducido
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
          SliverAppBar.large(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AI Kitchen',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                 IconButton( icon:Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Settings()),
                  ),
                )
              ],
            ),
          ),
          if (_todayMenu != null && _todayMenu!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _TodayMenuCard(
                  dayName: _currentDayName!,
                  recipes: _todayMenu!,
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildListDelegate([
                _FeatureCard(
                  title: 'Receta por Nombre',
                  icon: Icons.restaurant_menu,
                  description: 'Busca una receta específica',
                  color: theme.colorScheme.primary,
                  onTap: () => _navigateTo(context, const FindByName()),
                ),
                _FeatureCard(
                  title: 'Receta por Ingredientes',
                  icon: Icons.kitchen,
                  description: 'Usa lo que tienes en casa',
                  color: theme.colorScheme.secondary,
                  onTap: () => _navigateTo(context, const FindByIngredients()),
                ),
                _FeatureCard(
                  title: 'Menú Semanal',
                  icon: Icons.calendar_month,
                  description: 'Organiza tu semana',
                  color: theme.colorScheme.tertiary,
                  onTap: () => _navigateTo(context, const WeeklyMenu()),
                ),
                _FeatureCard(
                  title: 'Favoritos',
                  icon: Icons.favorite,
                  description: 'Tus recetas guardadas',
                  color: Colors.redAccent,
                  onTap: () => _navigateTo(context, const Favourites()),
                ),
                _FeatureCard(
                  title: 'Lista de la Compra',
                  icon: Icons.shopping_cart,
                  description: 'Lo que necesitas comprar',
                  color: Colors.orange,
                  onTap: () => _navigateTo(context, const ShoppingList()),
                ),
                _FeatureCard(
                  title: 'Crear Receta',
                  icon: Icons.add_circle,
                  description: 'Añade tu propia receta',
                  color: Colors.green,
                  onTap: () => _navigateTo(context, const CreateRecipe()),
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _PageWrapper(child: page)),
    ).then((_) => _loadTodayMenu()); // Recargar al volver por si cambió el menú
  }
}

class _TodayMenuCard extends StatelessWidget {
  final String dayName;
  final List<Recipe> recipes;

  const _TodayMenuCard({required this.dayName, required this.recipes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Menú de hoy ($dayName)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recipes.asMap().entries.map((entry) {
              final index = entry.key;
              final recipe = entry.value;
              final mealType = index == 0 ? 'Comida' : 'Cena';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeScreen(recipe: recipe),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mealType,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary.withOpacity(0.8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              recipe.nombre,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PageWrapper extends StatelessWidget {
  final Widget child;
  const _PageWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: child,
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
