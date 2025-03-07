import 'package:aikitchen/home/by_ingredients/find_by_ingredients_widgets.dart';
import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/widgets/lottie_animation_widget.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../singleton/app_singleton.dart';
import '../../models/recipe_screen_arguments.dart';

class FindByIngredients extends StatefulWidget {
  const FindByIngredients({super.key});

  @override
  State<FindByIngredients> createState() => _FindByIngredientsState();
}

class _FindByIngredientsState extends State<FindByIngredients> {
  List<String> ingredientes = [];
  List<Recipe>? recetas;
  bool _searching = false;
  bool _isFav = false;

  Future<void> _loadJson() async {
    final String response = await rootBundle.loadString('assets/ejemplo.json');
    setState(() {
      recetas = Recipe.fromJsonList(response);
    });
  }

  Future<void> _generateResponse() async {
    setState(() {
      recetas = [];
      _searching = true;
    });

    if (_isFav) {
      if (kIsWeb) {
        await _loadJson();
      } else {
        await AppSingleton().getFavRecipes();
        recetas = AppSingleton().recetasFavoritas;
      }

      for (String ingrediente in ingredientes) {
        recetas =
            recetas!
                .where(
                  (element) => element.recipeContainsIngredient(ingrediente),
                )
                .toList();
      }

      setState(() {
        _searching = false;
      });
      return;
    }

    try {
      final response = await AppSingleton().generateContent(
        Prompt.recipePrompt(
          ingredientes,
          AppSingleton().numRecetas,
          AppSingleton().personality,
        ),
      );
      if (response.contains('preparacion')) {
        setState(() {
          recetas = Recipe.fromJsonList(
            response.replaceAll("```json", "").replaceAll("```", ""),
          );
        });
      } else {
        Toaster.showToast('''Hubo un problema: $response,
          buscando en recetas favoritas''');
      }
    } on NoApiKeyException {
      setState(() {
        Toaster.showToast(
          'Por favor, configura tu API Key de Gemini para poder usar la aplicación',
        );
      });
    } catch (e) {
      Toaster.showToast('Error al procesar la respuesta: $e');
    } finally {
      if (recetas == null || recetas!.isEmpty) {
        setState(() {
          _isFav = true;
          _generateResponse();
        });
      }
    }

    setState(() {
      _searching = false;
    });
  }

  void onFav() {
    _isFav = !_isFav;
    Toaster.showToast(
      _isFav ? 'Buscando en recetas favoritas' : 'Buscando recetas con la IA',
    );
  }

  void onNewIngredient(String ingrediente) {
    setState(() {
      if (!ingredientes.contains(ingrediente)) {
        ingredientes.add(ingrediente);
      }
    });
  }

  void onRemoveIngredient(String ingrediente) {
    setState(() {
      ingredientes.remove(ingrediente);
    });
  }

  void onClickRecipe(Recipe recipe) {
    Navigator.pushNamed(
      context,
      '/recipe',
      arguments: RecipeScreenArguments(recipe: recipe),
    );
  }

  void onFavRecipe(Recipe recipe) {
    if (AppSingleton().recetasFavoritas.contains(recipe)) {
      AppSingleton().recetasFavoritas.remove(recipe);
    } else {
      AppSingleton().recetasFavoritas.add(recipe);
    }

    AppSingleton().setFavRecipes();
  }

  @override
  Widget build(BuildContext context) {
    Widget content =
        _searching
            ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LottieAnimationWidget(),
                  SizedBox(height: 16),
                  Text('Generando recetas...'),
                ],
              ),
            )
            : Column(
              children: [
                IngredientsPart(
                  onNewIngredient: onNewIngredient,
                  onRemoveIngredient: onRemoveIngredient,
                  ingredientes: ingredientes,
                  onSearch: _generateResponse,
                  onFav: onFav,
                  isLoading: _searching,
                  isFavourite: _isFav,
                ),
                const SizedBox(height: 16),
                if (recetas == null)
                  Container()
                else if (recetas != null && recetas!.isNotEmpty)
                  RecipesListHasData(
                    recipes: recetas!,
                    onClickRecipe: onClickRecipe,
                    onFavRecipe: onFavRecipe,
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LottieAnimationWidget(
                          type: LottieAnimationType.notfound,
                        ),
                        Text('No hay recetas disponibles'),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: content,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
