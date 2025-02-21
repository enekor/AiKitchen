import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/steps_list.dart';
import 'package:flutter/material.dart';

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key, required this.recipe, required this.onSteps});
  final Recipe recipe;
  final Function(Recipe) onSteps;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {

  Future<String> _generateRecipe() async {
    if (widget.recipe.pasos == null || widget.recipe.pasos!.isEmpty) {
      String pasos = await AppSingleton().generateRecipe(widget.recipe);
      widget.recipe.addSteps(
        pasos.replaceAll('```json', '').replaceAll('```', ''),
      );
      widget.onSteps(widget.recipe);
      return pasos;
    } else {
      return widget.recipe.pasos.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recipe.nombre)),
      body: FutureBuilder<void>(
        future: _generateRecipe(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Hubo un problema: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: _generateRecipe,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          } else {
            return widget.recipe.pasos != null && widget.recipe.pasos!.isNotEmpty
                ? StepsList(steps: widget.recipe.pasos!)
                : const Center(child: Text('No hay pasos disponibles.'));
          }
        },
      ),
    );
  }
}
