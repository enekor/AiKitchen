import 'package:aikitchen/home/home_widgets.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import '../singleton/app_singleton.dart';
import '../models/recipe_screen_arguments.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String prompt =
      'Eres un asistente de cocina que me ayuda a elegir que comer a partir de un listado de ingredientes que tengo en mi nevera, pero necesito que solo me deslas posibles recetas en formato de json, sin ningun texto ni saludo ni nada, la respuesta es una lista json que se compone de nombre con el nombre "nombre", lista de ingredientes con el nombre "ingredientes", tiempo estimado de preparacion con el nombre "tiempo_preparacion", y tipo de plato (principal, postre, etc) con el nombre "tipo_plato" y una pequeña descripcion del plato con el nombre "descripcion", la lista de ingredientes a la que tengo acceso es esta: ';
  bool _isLoading = false;
  List<String> ingredientes = [];
  List<Recipe> recetas = [];

  void _navigateToSettings() {
    Navigator.pushNamed(context, '/api_key');
  }

  void _onSteps(Recipe recipe) {
    recetas.firstWhere((element) => element.nombre == recipe.nombre).pasos =
        recipe.pasos ?? [];
  }

  Future<void> _generateResponse() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AppSingleton().generateContent(
        prompt + ingredientes.join(', '),
      );
      setState(() {
        if (response.contains('json')) {
          recetas = Recipe.fromJsonList(
            response.replaceAll("```json", "").replaceAll("```", ""),
          );
        } else {
          Toaster.showToast('Hubo un problema: $response');
        }
      });
    } on NoApiKeyException {
      setState(() {
        Toaster.showToast(
          'Por favor, configura tu API Key de Gemini para poder usar la aplicación',
        );
      });
    } catch (e) {
      setState(() {
        Toaster.showToast('Error al procesar la respuesta: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
      arguments: RecipeScreenArguments(recipe: recipe, onSteps: _onSteps),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content =
        _isLoading
            ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Generando recetas...'),
                  SizedBox(height: 16),
                  CircularProgressIndicator(),
                ],
              ),
            )
            : Column(
              children: [
                IngredientsPart(
                  onNewIngredient: onNewIngredient,
                  onRemoveIngredient: onRemoveIngredient,
                  ingredientes: ingredientes,
                ),
                const SizedBox(height: 16),
                RecipesListHasData(
                  recipes: recetas,
                  onClickRecipe: onClickRecipe,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _generateResponse,
                  child: Text('Generar recetas'),
                ),
              ],
            );

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Kitchen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
