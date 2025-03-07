import 'package:aikitchen/home/by_ingredients/find_by_ingredients.dart';
import 'package:aikitchen/home/by_name/find_by_name.dart';
import 'package:aikitchen/home/favourites/favourites.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _page = 0;
  void _navigateToSettings() {
    Navigator.pushNamed(context, '/api_key');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Kitchen'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: IndexedStack(
        index: _page,
        children: [FindByIngredients(), FindByName(), Favourites()],
      ),

      bottomNavigationBar: NavigationBar(
        maintainBottomViewPadding: true,

        onDestinationSelected: (selPage) => setState(() => _page = selPage),
        selectedIndex: _page,
        elevation: 3,
        destinations: [
          NavigationDestination(
            icon:
                _page == 0 ? Icon(Icons.kitchen) : Icon(Icons.kitchen_outlined),
            label: _page == 0 ? 'Ingredientes' : '',
          ),
          NavigationDestination(
            icon:
                _page == 1
                    ? Icon(Icons.soup_kitchen_rounded)
                    : Icon(Icons.soup_kitchen_outlined),
            label: _page == 1 ? 'Nombre' : '',
          ),
          if (!kIsWeb)
            NavigationDestination(
              icon:
                  _page == 2
                      ? Icon(Icons.favorite)
                      : Icon(Icons.favorite_border),
              label: _page == 2 ? 'Favoritos' : '',
            ),
        ],
      ),
    );
  }
}
