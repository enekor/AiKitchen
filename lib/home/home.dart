import 'package:aikitchen/AI/by_ingredients/find_by_ingredients.dart';
import 'package:aikitchen/AI/by_name/find_by_name.dart';
import 'package:aikitchen/AI/favourites/favourites.dart';
import 'package:aikitchen/AI/using_ai.dart';
import 'package:aikitchen/DB/using_db.dart';
import 'package:aikitchen/shopping_list.dart/shopping_list.dart';
import 'package:aikitchen/widgets/navigation_bar.dart';
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
        children: [UsingAi(), UsingDB(), ShoppingList()],
      ),

      bottomNavigationBar: NeumorphicNavigationBar(
        currentIndex: _page,
        onTap: (index) => setState(() => _page = index),
        isWeb: kIsWeb,
      ),
    );
  }
}
