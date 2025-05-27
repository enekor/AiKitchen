import 'package:aikitchen/AI/by_name/find_by_name_widgets.dart';
import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/screens/create_recipe.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/share_recipe_service.dart';
import 'package:aikitchen/services/shared_preferences_service.dart';
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
  List<String> _historial = [];
  bool _searching = false;
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    SharedPreferencesService.getStringListValue(
      SharedPreferencesKeys.historialBusquedaNombres,
    ).then((value) {
      _historial = value;
    });
  }

  int _totalTries = 0;
  void _searchByName(String name) async {
    setState(() {
      _historial.add(name);
    });

    SharedPreferencesService.setStringListValue(
      SharedPreferencesKeys.historialBusquedaNombres,
      _historial,
    );

    setState(() {
      _recetas = [];
      _searching = true;
    });

    try {
      final prompt = Prompt.recipePromptByName(
        name,
        AppSingleton().numRecetas,
        AppSingleton().personality,
        AppSingleton().idioma,
        AppSingleton().tipoReceta,
      );
      final response = await AppSingleton().generateContent(prompt, context);
      if (response.contains('preparacion')) {
        _recetas = Recipe.fromJsonList(
          response.replaceAll("```json", "").replaceAll("```", ""),
        );
        setState(() {
          _searching = false;
        });
      } else if (response.toLowerCase().contains('no puedo') ||
          response.toLowerCase().contains('no se') ||
          response.toLowerCase().contains('no se puede') ||
          response.toLowerCase().contains('no se ha podido') ||
          response.toLowerCase().contains('no debo')) {
        Toaster.showToast('Gemini: $response', long: true);
      } else {
        Toaster.showToast(
          '''Hubo un problema, vuelve a intentarlo mas tarde''',
        );
      }
    } on NoApiKeyException {
      setState(() {
        Toaster.showToast(
          'Por favor, configura tu API Key de Gemini para poder buscar usando la IA',
        );
      });
    } catch (e) {
      _totalTries++;
      if (_totalTries < 3) {
        _searchByName(name);
      } else {
        Toaster.showToast('No se ha podido completar la solicitud...');
      }
    }
  }

  void shareRecipe(List<Recipe> receta) async {
    await ShareRecipeService().shareRecipe(receta);
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

    JsonDocumentsService().setFavRecipes(AppSingleton().recetasFavoritas);
  }

  void onEditRecipe(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateRecipe(recipe: recipe)),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      children: [
        nameInputPart(
          history: _historial,
          onSearch: _searchByName,
          isLoading: _searching,
        ),
        const SizedBox(height: 16),
        if (_searching)
          const Column(
            children: [
              LottieAnimationWidget(type: LottieAnimationType.loading),
              SizedBox(height: 16),
              Text('Generando recetas...'),
            ],
          )
        else if (_recetas != null && _recetas!.isNotEmpty)
          Expanded(
            child: RecipesListHasData(
              recipes: _recetas!,
              onClickRecipe: onClickRecipe,
              onFavRecipe: onFavRecipe,
              onEdit: onEditRecipe,
              onShareRecipe: shareRecipe,
            ),
          )
        else if (_recetas != null && _recetas!.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LottieAnimationWidget(type: LottieAnimationType.notfound),
                  Text("No hay recetas para mostrar"),
                ],
              ),
            ),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child:
            _recetas == null || _recetas!.isEmpty && !_searching
                ? Center(
                  child: nameInputPart(
                    history: _historial,
                    onSearch: _searchByName,
                    isLoading: _searching,
                    isFavorite: _isFav,
                  ),
                )
                : content,
      ),
    );
  }
}
