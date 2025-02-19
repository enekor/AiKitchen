import 'package:aikitchen/models/recipe.dart';

class RecipeScreenArguments {
  final Recipe recipe;
  final Function(Recipe) onSteps;

  RecipeScreenArguments({
    required this.recipe,
    required this.onSteps,
  });
} 