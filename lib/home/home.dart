import 'package:aikitchen/AI/by_ingredients/find_by_ingredients.dart';
import 'package:aikitchen/AI/by_name/find_by_name.dart';
import 'package:aikitchen/AI/favourites/favourites.dart';
import 'package:aikitchen/screens/create_recipe.dart';
import 'package:aikitchen/screens/settings.dart';
import 'package:aikitchen/screens/shopping_list.dart';
import 'package:aikitchen/widgets/navigation_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const FindByName(),
    const FindByIngredients(),
    // if (!kIsWeb)
    const Favourites(),
  ];

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Settings()),
    );
  }

  void _navigateToShoppingList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShoppingList()),
    );
  }

  void _navigateToCreateRecipe() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateRecipe()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          _getAppBarTitle(),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _navigateToShoppingList,
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Lista de la compra',
          ),
          IconButton(
            onPressed: _navigateToSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ajustes',
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NeumorphicNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        isWeb: kIsWeb,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateRecipe,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Buscar por Nombre';
      case 1:
        return 'Buscar por Ingredientes';
      case 2:
        return 'Favoritos';
      default:
        return 'AI Kitchen';
    }
  }
}
