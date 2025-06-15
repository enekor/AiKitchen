import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/widgets/text_input.dart';
import 'package:aikitchen/widgets/recipe_list.dart';
import 'package:flutter/material.dart';

class nameInputPart extends StatefulWidget {
  nameInputPart({
    super.key,
    required this.onSearch,
    this.onFav,
    required this.isLoading,
    this.isFavorite,
    required this.history,
  });
  Function(String) onSearch;
  Function? onFav;
  bool isLoading;
  bool? isFavorite;
  List<String> history;
  @override
  State<nameInputPart> createState() => _nameInputPartState();
}

class _nameInputPartState extends State<nameInputPart> {
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextInput(
          onSearch: widget.onSearch,
          isLoading: widget.isLoading,
          onFav: widget.onFav,
          isFavorite: widget.isFavorite,
          prefixIcon: Icon(Icons.soup_kitchen_outlined),
          hint: 'Ejemplo: Tarta de manzana',
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                setState(() {
                  _showHistory = !_showHistory;
                });
              },
            ),
          ],
        ),
        if (_showHistory)
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Card(
              elevation: 1,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount:
                    widget.history.toSet().where((v) => v.isNotEmpty).length,
                itemBuilder: (context, index) {
                  final item = widget.history
                      .toSet()
                      .where((v) => v.isNotEmpty)
                      .elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.history, size: 16),
                    title: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onTap: () => widget.onSearch(item),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class RecipesListHasData extends StatelessWidget {
  final List<Recipe> recipes;
  final Function(Recipe) onClickRecipe;
  final Function(Recipe) onFavRecipe;
  final Function(Recipe) onEdit;
  final Function(List<Recipe>) onShareRecipe;

  const RecipesListHasData({
    super.key,
    required this.recipes,
    required this.onClickRecipe,
    required this.onFavRecipe,
    required this.onEdit,
    required this.onShareRecipe,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) return const SizedBox.shrink();

    return RecipesList(
      recipes: recipes,
      onClickRecipe: onClickRecipe,
      onFavRecipe: onFavRecipe,
      onEdit: onEdit,
      onShareRecipe: onShareRecipe,
    );
  }
}
