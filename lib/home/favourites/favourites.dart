import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children:
                      _recetasFavoritas
                          .map(
                            (receta) => Card(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondary.withAlpha(80),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Spacer(),
                                      Text(
                                        receta.nombre,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                      ),
                                      SizedBox(height: 10),
                                      Text(receta.descripcion),
                                      Spacer(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              removeFavRecipe(receta);
                                              setState(() {});
                                            },
                                          ),
                                          IconButton(
                                            onPressed: () => openRecipe(receta),
                                            icon: Icon(
                                              Icons.open_in_new_rounded,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
