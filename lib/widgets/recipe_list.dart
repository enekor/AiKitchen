import 'package:aikitchen/models/recipe.dart';
import 'package:flutter/material.dart';

class RecipeList extends StatefulWidget {
  RecipeList({Key? key, required this.recipes, required this.onClickRecipe, this.onFavRecipe, this.onSelectIngredient}) : super(key: key);

  final List<Recipe> recipes;
  final Function(Recipe)? onFavRecipe;
  final Function(Recipe) onClickRecipe;
  final Function(String)? onSelectIngredient;

  @override
  _RecipeListState createState() => _RecipeListState();
}

class _RecipeListState extends State<RecipeList> {
  @override
  Widget build(BuildContext context) {
    return 
  }
}
