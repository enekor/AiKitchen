import 'package:aikitchen/home/home_widgets.dart';
import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../singleton/app_singleton.dart';
import '../models/recipe_screen_arguments.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<String> ingredientes = [];
  List<Recipe> recetas = [];
  bool _firstSearched = false;

  void _navigateToSettings() {
    Navigator.pushNamed(context, '/api_key');
  }

  Future<void> _loadJson() async {
    final String response = await rootBundle.loadString('assets/ejemplo.json');
    setState(() {
      recetas = Recipe.fromJsonList(response);
    });
  }

  Future<void> _generateResponse() async {
    setState(() {
      _firstSearched = true;
    });

    try {
      final response = await AppSingleton().generateContent(
        Prompt.recipePrompt(ingredientes, AppSingleton().numRecetas, AppSingleton().personality),
      );
      if (response.contains('preparacion')) {
        setState(() {
          recetas = Recipe.fromJsonList(
            response.replaceAll("```json", "").replaceAll("```", ""),
          );
        });
      } else {
        Toaster.showToast('''Hubo un problema: $response,
          estableciendo datos por defecto''');
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
      recetas.isEmpty ? _loadJson() : null;
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
      arguments: RecipeScreenArguments(recipe: recipe),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content =
        _firstSearched && recetas.isEmpty
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
