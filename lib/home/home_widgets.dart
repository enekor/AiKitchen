import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/widgets/common_widgets.dart';
import 'package:flutter/material.dart';

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
  TextEditingController _ingredientController = TextEditingController();

  void _addNewIngredient() {
    setState(() {
      widget.ingredientes.add(_ingredientController.text);
      widget.onNewIngredient(_ingredientController.text);
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
    if(!widget.ingredientes.contains(ingredient)) {
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
            Expanded(child: 
            TextFormField(
              controller: _ingredientController,
              decoration: InputDecoration(
                hintText: 'Añadir ingrediente',
                border: OutlineInputBorder(),
              ),
            )),
            IconButton(
              onPressed: _addNewIngredient,
              icon: Icon(Icons.add),
            )
          ],
        ),
        SizedBox(height: 16),
        Text('Ingredientes:'),
        ...widget.ingredientes.map((ingredient) => Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Row(
            children: [
              Text('• $ingredient'),
              IconButton(
                onPressed: () => _removeIngredient(ingredient),
                icon: Icon(Icons.remove),
              )
            ],
          ),
        )).toList(),
      ],
    );
  }
}

class RecipesListHasData extends StatelessWidget {
  final List<Recipe> recipes;

  const RecipesListHasData({
    super.key,
    required this.recipes,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) return const SizedBox.shrink();
    
    return AnimatedCard(
      text: 'Recetas sugeridas',
      icon: Icon(Icons.soup_kitchen_rounded),
      children: recipes.map((receta) => AnimatedCard(
        text: receta.nombre,
        icon: Icon(Icons.restaurant),
        children: [
          Text('Tipo: ${receta.tipo}'),
          const SizedBox(height: 8),
          Text('Tiempo: ${receta.tiempoPreparacion}'),
          const SizedBox(height: 8),
          Text('Ingredientes:'),
          ...receta.ingredientes.map((ing) => Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text('• $ing'),
          )),
          const SizedBox(height: 8),
          Text('Descripción: ${receta.descripcion}'),
        ],
      )).toList(),
    );
  }
}