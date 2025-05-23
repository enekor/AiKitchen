import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/widgets/ingredients_list.dart';
import 'package:aikitchen/widgets/steps_list.dart';
import 'package:flutter/material.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key, required this.recipe});
  final Recipe recipe;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recipe.nombre)),
      body: PageView(
        children: [
          // Página 1: StepsList
          Center(child: StepsList(steps: widget.recipe.preparacion)),
          // Página 2: IngredientsList
          Center(
            child: IngredientsList(ingredients: widget.recipe.ingredientes),
          ),
        ],
      ),
    );
  }
}
