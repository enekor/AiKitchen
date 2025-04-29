import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/widgets/neumorphic_card.dart';
import 'package:flutter/material.dart';

class CreateRecipe extends StatefulWidget {
  const CreateRecipe({super.key});

  @override
  State<CreateRecipe> createState() => _CreateRecipeState();
}

class _CreateRecipeState extends State<CreateRecipe> {
  void saveRecipe() {
    Recipe recipe = Recipe(
      nombre: _nameController.text,
      descripcion: _descriptionController.text,
      raciones: int.parse(_rationsController.text),
      calorias: double.parse(_caloriesController.text),
      ingredientes: _ingredients,
      preparacion: _steps,
      tiempoEstimado: "${_estimatedTimeController.text}min",
    );

    JsonDocumentsService().updateFavRecipes(recipe);
  }

  final List<String> _ingredients = [''];
  final List<String> _steps = [''];

  // Controllers para los campos de texto
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedTimeController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _rationsController = TextEditingController();

  @override
  void dispose() {
    // Limpieza de los controllers
    _nameController.dispose();
    _descriptionController.dispose();
    _estimatedTimeController.dispose();
    _caloriesController.dispose();
    _rationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear receta')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Primera tarjeta - Información básica
              NeumorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _rationsController,
                              decoration: const InputDecoration(
                                labelText: 'Número de platos',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _estimatedTimeController,
                              decoration: const InputDecoration(
                                labelText: 'Tiempo (min)',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _caloriesController,
                              decoration: const InputDecoration(
                                labelText: 'Calorías por ración',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Segunda tarjeta - Ingredientes
              NeumorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Ingredientes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _ingredients.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: 'Ingrediente ${index + 1}',
                                    ),
                                    onChanged: (value) {
                                      _ingredients[index] = value;
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    if (_ingredients.length > 1) {
                                      setState(() {
                                        _ingredients.removeAt(index);
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _ingredients.add('');
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Añadir ingrediente'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Tercera tarjeta - Pasos de preparación
              NeumorphicCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Pasos de preparación',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _steps.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: 'Paso ${index + 1}',
                                    ),
                                    maxLines: 3,
                                    onChanged: (value) {
                                      _steps[index] = value;
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    if (_steps.length > 1) {
                                      setState(() {
                                        _steps.removeAt(index);
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _steps.add('');
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Añadir paso'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: saveRecipe,
                child: const Text('Guardar receta'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
