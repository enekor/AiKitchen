import 'package:aikitchen/AI/by_ingredients/find_by_ingredients.dart';
import 'package:aikitchen/AI/by_name/find_by_name.dart';
import 'package:aikitchen/AI/favourites/favourites.dart';
import 'package:aikitchen/widgets/floating_actions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class UsingAi extends StatefulWidget {
  UsingAi({Key? key}) : super(key: key);

  @override
  _UsingAiState createState() => _UsingAiState();
}

class _UsingAiState extends State<UsingAi> {
  int _page = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ModularFloatingActions(
          actions: [
            NeumorphicActionButton(
              icon: kIsWeb 
                ? _page == 0
                  ? Icons.soup_kitchen_rounded
                  : Icons.soup_kitchen_outlined
                : Symbols.grocery_rounded,
              onPressed:
                  () => setState(() {
                    _page = 0;
                  }),
              isHighlighted: _page == 0,
              tooltip: 'Buscar por ingredientes',
            ),
            NeumorphicActionButton(
              icon: _page == 1 ? Icons.receipt : Icons.receipt_outlined,
              onPressed:
                  () => setState(() {
                    _page = 1;
                  }),
              tooltip: 'Buscar por receta',
              isHighlighted: _page == 1,
            ),
            if (!kIsWeb)
              NeumorphicActionButton(
                icon: _page == 2 ? Icons.favorite : Icons.favorite_border,
                onPressed:
                    () => setState(() {
                      _page = 2;
                    }),
                tooltip: 'Favoritos',
                isHighlighted: _page == 2,
              ),
          ],
        ),
        Expanded(
          child: IndexedStack(
            index: _page,
            children: [FindByIngredients(), FindByName(), Favourites()],
          ),
        ),
      ],
    );
  }
}
