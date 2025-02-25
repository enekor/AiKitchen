import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/widgets/animated_card.dart';
import 'package:aikitchen/widgets/recipe_preview.dart';
import 'package:flutter/material.dart';
import 'package:aikitchen/widgets/toaster.dart';

class IngredientsPart extends StatefulWidget {
  final List<String> ingredientes;
  final Function(String) onNewIngredient;
  final Function(String) onRemoveIngredient;

  const IngredientsPart({
    super.key,
    required this.onNewIngredient,
    required this.onRemoveIngredient,
    required this.ingredientes,
  });

  @override
  State<IngredientsPart> createState() => _IngredientsPartState();
}

class _IngredientsPartState extends State<IngredientsPart> {
  final TextEditingController _ingredientController = TextEditingController();

  void _addNewIngredient() {
    setState(() {
      widget.ingredientes.add(_ingredientController.text);
      widget.onNewIngredient(_ingredientController.text);
      Toaster.showToast('Ingrediente añadido: ${_ingredientController.text}');
      _ingredientController.clear();
    });
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      if (widget.ingredientes.contains(ingredient)) {
        widget.ingredientes.remove(ingredient);
        widget.onRemoveIngredient(ingredient);
      }
    });
  }

  void _saveIngredient(String ingredient) {
    if (!widget.ingredientes.contains(ingredient)) {
      widget.ingredientes.add(ingredient);
      widget.onNewIngredient(ingredient);
    }
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      text: 'Listado de ingredientes',
      icon: Icon(Icons.kitchen),
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ingredientController,
                decoration: InputDecoration(
                  hintText: 'Añadir ingrediente',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(onPressed: _addNewIngredient, icon: Icon(Icons.add)),
          ],
        ),
        SizedBox(height: 16),
        Text('Ingredientes:'),
        ...widget.ingredientes.map(
          (ingredient) => Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              children: [
                Text('• $ingredient'),
                IconButton(
                  onPressed: () => _removeIngredient(ingredient),
                  icon: Icon(Icons.remove),
                ),
              ],
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

  const RecipesListHasData({
    super.key,
    required this.recipes,
    required this.onClickRecipe,
    required this.onFavRecipe,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) return const SizedBox.shrink();

    return Column(
      children:
          recipes
              .map(
                (receta) => RecipePreview(recipe: receta, onFavRecipe: onFavRecipe, onNavigateRecipe: onClickRecipe)
              )
              .toList(),
    );
  }
}
