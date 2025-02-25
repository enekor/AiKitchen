import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/widgets/animated_card.dart';
import 'package:flutter/material.dart';

class RecipePreview extends StatefulWidget {
  const RecipePreview({
    super.key,
    required this.recipe,
    required this.onFavRecipe,
    required this.onNavigateRecipe,
  });
  final Recipe recipe;
  final Function(Recipe) onFavRecipe;
  final Function(Recipe) onNavigateRecipe;

  @override
  State<RecipePreview> createState() => _RecipePreviewState();
}

class _RecipePreviewState extends State<RecipePreview> {
  bool _isFav = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      text: widget.recipe.nombre,
      icon: Icon(Icons.restaurant),
      children: [
        Row(
          children: [
            Icon(Icons.timer),
            SizedBox(width: 5),
            Text(widget.recipe.tiempoEstimado),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.description),
            SizedBox(width: 5),
            Expanded(child: Text(widget.recipe.descripcion)),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.kitchen),
            SizedBox(width: 5),
            Text('Ingredientes:'),
          ],
        ),
        ...widget.recipe.ingredientes.map(
          (ingredient) => Text('        · $ingredient'),
        ),
        SizedBox(height: 15),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            IconButton(
              icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border),
              onPressed: () {
                setState(() {
                  _isFav = !_isFav;
                });
                widget.onFavRecipe(widget.recipe);
              },
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: () => widget.onNavigateRecipe(widget.recipe),
            ),
          ],
        ),
      ],
    );
  }
}
