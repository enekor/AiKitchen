import 'package:aikitchen/AI/using_ai.dart';
import 'package:aikitchen/DB/using_db.dart';
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
  int _page = 0;
  void _navigateToSettings() {
    Navigator.pushNamed(context, '/api_key');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
          top: Theme.of(context).navigationBarTheme.height ?? 45,
        ),
        child: IndexedStack(
          index: _page,
          children: [UsingAi(), /*UsingDB(),*/ ShoppingList(), Settings()],
        ),
      ),

      bottomNavigationBar: NeumorphicNavigationBar(
        currentIndex: _page,
        onTap: (index) => setState(() => _page = index),
        isWeb: kIsWeb,
      ),
    );
  }
}
