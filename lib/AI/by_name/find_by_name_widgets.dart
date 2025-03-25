import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/widgets/text_input.dart';
import 'package:aikitchen/widgets/recipe_list.dart';
import 'package:flutter/material.dart';

class nameInputPart extends StatefulWidget {
  nameInputPart({
    super.key,
    required this.onSearch,
    required this.onFav,
    required this.isLoading,
    required this.isFavorite,
  });
  Function(String) onSearch;
  Function onFav;
  bool isLoading;
  bool isFavorite;
  @override
  State<nameInputPart> createState() => _nameInputPartState();
}

class _nameInputPartState extends State<nameInputPart> {
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextInput(
      onSearch: widget.onSearch,
      isLoading: widget.isLoading,
      onFav: widget.onFav,
      isFavorite: widget.isFavorite,
      prefixIcon: Icon(Icons.soup_kitchen_outlined),
      hint: 'Ejemplo: Tarta de manzana',
    );
  }
}

class RecipesListHasData extends StatelessWidget {
  final List<Recipe> recipes;
  final Function(Recipe) onClickRecipe;
  final Function(Recipe) onFavRecipe;

  const RecipesListHasData({
    super.key,
    required this.recipes,
    required this.onClickRecipe,
    required this.onFavRecipe,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) return const SizedBox.shrink();

    return RecipesList(
      recipes: recipes,
      onClickRecipe: onClickRecipe,
      onFavRecipe: onFavRecipe,
    );
  }
}
