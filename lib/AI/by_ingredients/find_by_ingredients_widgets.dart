import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/widgets/animated_card.dart';
import 'package:aikitchen/widgets/floating_actions.dart';
import 'package:aikitchen/widgets/neumorphic_card.dart';
import 'package:aikitchen/widgets/neumorphic_selections.dart';
import 'package:aikitchen/widgets/recipe_list.dart';
import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:aikitchen/widgets/toaster.dart';

class IngredientsPart extends StatefulWidget {
  final List<String> ingredientes;
  final Function(String) onNewIngredient;
  final Function(String) onRemoveIngredient;
  final Function? onFav;
  final Function() onSearch;
  final bool isLoading;
  final bool? isFavourite;

  const IngredientsPart({
    super.key,
    required this.onNewIngredient,
    required this.onRemoveIngredient,
    required this.ingredientes,
    required this.onSearch,
    this.onFav,
    required this.isLoading,
    this.isFavourite,
  });

  @override
  State<IngredientsPart> createState() => _IngredientsPartState();
}

TextEditingController _ingredientController = TextEditingController();

class _IngredientsPartState extends State<IngredientsPart> {
  bool _isCardExpanded = false; // Keep track of card expansion
  bool _showUseLocalIngredients = false;
  bool _showIngredients = false;
  void _addNewIngredient() {
    widget.onNewIngredient(_ingredientController.text);
    Toaster.showToast('Ingrediente añadido: ${_ingredientController.text}');
    setState(() {
      _ingredientController.text = '';
    });
  }

  // void _showIngredients() {
  //   List<String> ingredients = widget.ingredientes;
  //   if (ingredients.isEmpty) {
  //     Toaster.showToast('No hay ingredientes añadidos');
  //     return;
  //   }

  //   showModalBottomSheet(
  //     context: context,
  //     builder:
  //         (context) => ListView.builder(
  //           itemBuilder:
  //               (context, index) => ListTile(
  //                 title: Text('• ${ingredients[index]}'),
  //                 trailing: IconButton(
  //                   icon: const Icon(Icons.delete),
  //                   onPressed: () {
  //                     setState(() {
  //                       ingredients.removeAt(index);
  //                     });
  //                     _removeIngredient(widget.ingredientes[index]);
  //                   },
  //                 ),
  //               ),
  //           itemCount: ingredients.length,
  //         ),
  //   );
  // }

  void _removeIngredient(String ingredient) {
    widget.onRemoveIngredient(ingredient);
    if (widget.ingredientes.isEmpty) {
      Toaster.showToast('No hay ingredientes añadidos');
      _showIngredients = false;
    } else {
      Toaster.showToast('Ingrediente eliminado: $ingredient');
    }
    setState(() {});
  }

  void _removeAllIngredients() {
    widget.ingredientes.clear();
    setState(() {});
  }

  void _addCartIngredients() async {
    var ingredients = await JsonDocumentsService().getCartItems();
    List<String> ingredientsList =
        ingredients.where((ing) => ing.isIn).map((e) => e.name).toList();
    for (String ingredient in ingredientsList) {
      widget.onNewIngredient(ingredient);
    }

    setState(() {});
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      isExpanded: _isCardExpanded, // Use the local state
      alwaysVisible: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: const Icon(Icons.kitchen_rounded),
          ),
          Expanded(
            child: NeumorphicCard(
              withInnerShadow: true,
              margin: const EdgeInsets.only(left: 5, top: 5, bottom: 5),
              padding: const EdgeInsets.only(
                left: 8,
                top: 8,
                bottom: 8,
                right: 16.0,
              ), // Keep the original margin
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    // to avoid overflow
                    child: Text(
                      widget.ingredientes.join(', '),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ], // Keep the original Row children
              ), // Keep the original Padding content
            ),
          ),
          IconButton(
            onPressed: widget.onSearch,
            icon:
                widget.isLoading
                    ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: const CircularProgressIndicator(),
                    )
                    : const Icon(Icons.search),
          ),
          if (widget.onFav != null && widget.isFavourite != null)
            IconButton(
              onPressed: () {
                widget.onFav!();
              },
              icon: Icon(
                widget.isFavourite! ? Icons.favorite : Icons.favorite_outline,
              ),
            ),
        ],
      ),
      onTap: () {
        // handle onTap event
        setState(() {
          _isCardExpanded = !_isCardExpanded;
        });
      },
      children: [
        Row(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Column(
                  children: [
                    NeumorphicCard(
                      withInnerShadow: true,
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: TextField(
                                controller: _ingredientController,
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  labelText: null,
                                  hintText: 'Añadir ingrediente',
                                ),
                                onSubmitted: (_) => _addNewIngredient,
                              ),
                            ),
                          ),
                          NeumorphicIconButton(
                            context,
                            NeumorphicActionButton(
                              icon: Icons.add,
                              onPressed: () {
                                _addNewIngredient();
                              },
                            ),
                          ),
                          NeumorphicIconButton(
                            context,
                            NeumorphicActionButton(
                              tooltip: "Usar ingredientes locales",
                              icon:
                                  _showUseLocalIngredients
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                              onPressed: () {
                                setState(() {
                                  _showUseLocalIngredients =
                                      !_showUseLocalIngredients;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showUseLocalIngredients)
                      NeumorphicSelections(
                        items: ["Usar propios", "Usar despensa"],
                        onSelected: (index) {
                          if (index == 1) {
                            _removeAllIngredients();
                            _addCartIngredients();
                            Toaster.showToast(
                              'Usando ingredientes de la despensa',
                            );
                          } else {
                            _removeAllIngredients();
                            Toaster.showToast('Cambiando a modo manual');
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: TextButton(
                child: Text('Ver ${widget.ingredientes.length} ingredientes'),
                onPressed:
                    () => setState(() {
                      _showIngredients = !_showIngredients;
                    }),
              ),
            ),
            IconButton(
              onPressed: _removeAllIngredients,
              icon: const Icon(Icons.delete_forever_rounded),
            ),
          ],
        ),
        if (_showIngredients)
          SizedBox(
            height:
                widget.ingredientes.length <= 4
                    ? widget.ingredientes.length * 50.0
                    : 200.0,
            child: SingleChildScrollView(
              child: Column(
                children:
                    widget.ingredientes
                        .map(
                          (ingredient) => ListTile(
                            title: Text('• $ingredient'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _removeIngredient(ingredient);
                              },
                            ),
                          ),
                        )
                        .toList(),
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
  final Function(Recipe) onEditRecipe;
  final Function(List<Recipe>) onShareRecipe;

  const RecipesListHasData({
    super.key,
    required this.recipes,
    required this.onClickRecipe,
    required this.onFavRecipe,
    required this.onEditRecipe,
    required this.onShareRecipe,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) return const SizedBox.shrink();

    return RecipesList(
      recipes: recipes,
      onClickRecipe: onClickRecipe,
      onFavRecipe: onFavRecipe,
      onEdit: onEditRecipe,
      onShareRecipe: onShareRecipe,
    );
  }
}
