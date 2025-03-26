import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/recipe_list.dart';
import 'package:flutter/material.dart';

class Favourites extends StatefulWidget {
  const Favourites({super.key});

  @override
  State<Favourites> createState() => _FavouritesState();
}

class _FavouritesState extends State<Favourites> {
  List<Recipe> _recetasFavoritas = [];

  Future<void> _load() async {
    AppSingleton().recetasFavoritas.clear();
    await AppSingleton().getFavRecipes();
    _recetasFavoritas = AppSingleton().recetasFavoritas;
  }

  void removeFavRecipe(Recipe receta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmación'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar esta receta de favoritos?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                AppSingleton().recetasFavoritas.removeWhere(
                  (recipe) =>
                      recipe.nombre == receta.nombre &&
                      recipe.descripcion == receta.descripcion &&
                      recipe.tiempoEstimado == receta.tiempoEstimado,
                );
                AppSingleton().setFavRecipes();
                setState(() {
                  _recetasFavoritas = AppSingleton().recetasFavoritas;
                });

                Navigator.of(context).pop();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  void openRecipe(Recipe receta) {
    Navigator.pushNamed(
      context,
      '/recipe',
      arguments: RecipeScreenArguments(recipe: receta),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _load(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading data'));
        } else {
          return SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child:
                _recetasFavoritas.isNotEmpty
                    ? RecipesList(
                      recipes: _recetasFavoritas,
                      onClickRecipe: openRecipe,
                      onFavRecipe: removeFavRecipe,
                      isFav: true,
                    )
                    : Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('¯⁠\⁠\_⁠ಠ⁠_⁠ಠ⁠_⁠/⁠¯'),
                          Text('No se han encontrado recetas favoritas'),
                        ],
                      ),
                    ),
          );
        }
      },
    );
  }
}
