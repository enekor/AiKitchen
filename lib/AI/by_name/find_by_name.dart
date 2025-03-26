import 'package:aikitchen/AI/by_name/find_by_name_widgets.dart';
import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/lottie_animation_widget.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';

class FindByName extends StatefulWidget {
  const FindByName({super.key});

  @override
  State<FindByName> createState() => _FindByNameState();
}

class _FindByNameState extends State<FindByName> {
  List<Recipe>? _recetas;
  bool _searching = false;
  bool _isFav = false;

  void _searchByName(String name, {bool isfav = false}) async {
    setState(() {
      _recetas = [];
      _searching = true;
    });

    if (_isFav || isfav) {
      AppSingleton().recetasFavoritas =
          await JsonDocumentsService.getFavRecipes();
      _recetas = AppSingleton().recetasFavoritas;
      _recetas =
          AppSingleton().recetasFavoritas
              .where(
                (recipe) =>
                    recipe.nombre.toLowerCase().contains(name.toLowerCase()),
              )
              .toList();

      setState(() {
        _searching = false;
      });
      return;
    }

    try {
      final response = await AppSingleton().generateContent(
        Prompt.recipePromptByName(
          name,
          AppSingleton().numRecetas,
          AppSingleton().personality,
        ),
        context,
      );
      if (response.contains('preparacion')) {
        setState(() {
          _recetas = Recipe.fromJsonList(
            response.replaceAll("```json", "").replaceAll("```", ""),
          );
        });
      } else if (response.toLowerCase().contains('no puedo') ||
          response.toLowerCase().contains('no se') ||
          response.toLowerCase().contains('no se puede') ||
          response.toLowerCase().contains('no se ha podido') ||
          response.toLowerCase().contains('no debo')) {
        Toaster.showToast('Gemini: $response', long: true);
      } else {
        Toaster.showToast(
          '''No se ha podido completar la solicitud... Buscando en recetas favoritas''',
        );
      }
    } on NoApiKeyException {
      setState(() {
        Toaster.showToast(
          'Por favor, configura tu API Key de Gemini para poder buscar usando la IA',
        );
      });
    } catch (e) {
      Toaster.showToast('Error al procesar la respuesta: $e');
    } finally {
      if (_recetas == null || _recetas!.isEmpty) {
        setState(() {
          _searchByName(name, isfav: true);
        });
      }

      setState(() {
        _searching = false;
      });
    }
  }

  void _fav() {
    setState(() {
      _isFav = !_isFav;
    });

    Toaster.showToast(
      _isFav ? 'Mostrando recetas favoritas' : 'Generando recetas con la IA',
    );
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

    JsonDocumentsService.setFavRecipes(AppSingleton().recetasFavoritas);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child:
          _searching
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LottieAnimationWidget(type: LottieAnimationType.loading),
                    SizedBox(height: 16),
                    Text('Generando recetas...'),
                  ],
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Column(
                    children: [
                      nameInputPart(
                        onSearch: _searchByName,
                        onFav: _fav,
                        isLoading: _searching,
                        isFavorite: _isFav,
                      ),
                      const SizedBox(height: 16),
                      if (_recetas == null)
                        Container()
                      else if (_recetas != null && _recetas!.isNotEmpty)
                        Expanded(
                          child: RecipesListHasData(
                            recipes: _recetas!,
                            onClickRecipe: onClickRecipe,
                            onFavRecipe: onFavRecipe,
                          ),
                        )
                      else
                        const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
    );
  }
}
