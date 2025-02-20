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
  bool _isLoading = false;

  Future<void> _generateRecipe() async {
    if (widget.recipe.pasos == null || widget.recipe.pasos!.isEmpty) {
      setState(() {
        _isLoading = true;
      });
      final response = await AppSingleton().generateRecipe(widget.recipe);
      setState(() {
        widget.recipe.addSteps(
          response.replaceAll('```json', '').replaceAll('```', ''),
        );
        widget.onSteps(widget.recipe);
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _generateRecipe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recipe.nombre)),
      body: Column(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : widget.recipe.pasos != null
                ? StepsList(steps: widget.recipe.pasos!)
                : Center(child: Column(
                  children: [
                    Text('Hubo un problema, intentelo mas tarde'),
                    ElevatedButton(onPressed: _generateRecipe, child: Row(
                      children: [
                        Icon(Icons.refresh_rounded),
                        Text('Reintentar'),
                      ],
                    ))
                  ],
                )),
        ],
      ),
    );
  }
}
