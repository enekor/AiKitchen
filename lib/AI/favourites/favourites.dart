import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/share_recipe_service.dart';
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
    AppSingleton().recetasFavoritas =
        await JsonDocumentsService().getFavRecipes();
    _recetasFavoritas = AppSingleton().recetasFavoritas;
    setState(() {});
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
                JsonDocumentsService().setFavRecipes(
                  AppSingleton().recetasFavoritas,
                );
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

  void shareRecipe(List<Recipe> receta) async {
    await ShareRecipeService().shareRecipe(receta);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child:
            _recetasFavoritas.isNotEmpty
                ? RecipesList(
                  recipes: _recetasFavoritas,
                  onClickRecipe: openRecipe,
                  onFavRecipe: removeFavRecipe,
                  isFav: true,
                  onShareRecipe: shareRecipe,
                  favIcon: Icon(
                    Icons.recycling_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                )
                : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '¯\\_(ツ)_/¯',
                        style: TextStyle(
                          fontSize: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('No se han encontrado recetas favoritas'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('Recargar'),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
