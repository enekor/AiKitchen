import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/widgets/lottie_animation_widget.dart';
import 'package:aikitchen/widgets/recipe_preview.dart';
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
  TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary.withAlpha(80),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Row(
          children: [
            Expanded(
              child: Card(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.soup_kitchen_outlined),
                    border: InputBorder.none,
                    labelText: 'Nombre de la receta',
                    hintText: 'Ejemplo: Tarta de manzana',
                  ),
                ),
              ),
            ),
            IconButton(
              icon:
                  widget.isLoading
                      ? CircularProgressIndicator()
                      : Icon(Icons.search),
              onPressed: () {
                widget.onSearch(_nameController.text);
              },
            ),
            IconButton(
              icon: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
              ),
              onPressed: () {
                widget.onFav();
              },
            ),
          ],
        ),
      ),
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
          recipes.isNotEmpty
              ? recipes
                  .map(
                    (receta) => RecipePreview(
                      recipe: receta,
                      onFavRecipe: onFavRecipe,
                      onNavigateRecipe: onClickRecipe,
                    ),
                  )
                  .toList()
              : [
                LottieAnimationWidget(type: LottieAnimationType.notfound),
                Text('No hay recetas disponibles'),
              ],
    );
  }
}
