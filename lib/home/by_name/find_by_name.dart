import 'package:aikitchen/home/by_name/find_by_name_widgets.dart';
import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/lottie_animation_widget.dart';
import 'package:aikitchen/widgets/recipe_preview.dart';
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

  void _searchByName(String name) {
    setState(() {
      _recetas = null;
      _searching = true;
    });

    if (_isFav) {
      AppSingleton().getFavRecipes();
      _recetas =
          AppSingleton().recetasFavoritas
              .where((recipe) => recipe.nombre.contains(name))
              .toList();
    } else {
      String prompt = Prompt.recipePromptByName(
        name,
        AppSingleton().numRecetas,
        AppSingleton().personality,
      );

      AppSingleton().generateContent(prompt).then((response) {
        setState(() {
          _recetas = Recipe.fromJsonList(response);
        });
      });
    }

    setState(() {
      _searching = false;
    });
  }

  void _fav() {
    setState(() {
      _isFav = !_isFav;
    });

      Toaster.showToast(_isFav ? 'Mostrando recetas favoritas' : 'Generando recetas con la IA');
    
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
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          nameInputPart(onSearch: _searchByName, onFav: _fav),
          const SizedBox(height: 16),
          SingleChildScrollView(
            child: Column(
              children: [
                if (_searching)
                  LottieAnimationWidget(type: LottieAnimationType.loading)
                else if (_recetas == null)
                  const Text('Algo ha salido mal')
                else if (_recetas!.isEmpty)
                  LottieAnimationWidget(type: LottieAnimationType.notfound)
                else
                  for (Recipe receta in _recetas!)
                    RecipePreview(
                      onFavRecipe: onFavRecipe,
                      recipe: receta,
                      onNavigateRecipe: onClickRecipe,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
