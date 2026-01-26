import 'package:aikitchen/models/recipe.dart';

class RecipeScreenArguments {
  final Recipe recipe;
  final String? url;

  RecipeScreenArguments({required this.recipe, this.url});
}
