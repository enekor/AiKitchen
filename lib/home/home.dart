import 'package:aikitchen/home/by_ingredients/find_by_ingredients.dart';
import 'package:aikitchen/home/by_name/find_by_name.dart';
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
        children: [
          FindByIngredients(),
          FindByName(),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (selPage)=>setState(() => _page = selPage),
        selectedIndex: _page,
        elevation: 3,
        destinations: [
        NavigationDestination(
          icon: Icon(Icons.search),
          label: 'Buscar por ingredientes',
        ),
        NavigationDestination(
          icon: Icon(Icons.search),
          label: 'Buscar por nombre',
        ),
      ]),
    );
  }
}