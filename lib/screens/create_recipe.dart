import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/widgets/neumorphic_card.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';

class CreateRecipe extends StatefulWidget {
  final Recipe? recipe;

  const CreateRecipe({super.key, this.recipe});

  @override
  State<CreateRecipe> createState() => _CreateRecipeState();
}

class _CreateRecipeState extends State<CreateRecipe> {
  @override
  void initState() {
    super.initState();
    // Initialize the text fields with data from the recipe if provided
    _initializeTextFields();
    _initializeFocusListeners();
  }

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
    
    JsonDocumentsService().updateFavRecipes(recipe, outdatedRecipe: widget.recipe);

    Toaster.showToast('${_nameController.text} guardada con éxito');
  }

  final List<String> _ingredients = [''];
  final List<String> _steps = [''];

  // Controllers para los campos de texto
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedTimeController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _rationsController = TextEditingController();

  // Focus nodes para la primera tarjeta
  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _rationsFocus = FocusNode();
  final _timeFocus = FocusNode();
  final _caloriesFocus = FocusNode();

  // Initialize text fields with recipe data if provided
  void _initializeTextFields() {
    if (widget.recipe != null) {
      _nameController.text = widget.recipe!.nombre;
      _descriptionController.text = widget.recipe!.descripcion;
      _estimatedTimeController.text =
          widget.recipe!.tiempoEstimado.split(" ")[0];
      _caloriesController.text = widget.recipe!.calorias.toString();
      _rationsController.text = widget.recipe!.raciones.toString();

      // Initialize ingredients and steps with data from the recipe
      _ingredients.clear();
      _steps.clear();
      _ingredients.addAll(widget.recipe!.ingredientes);
      _steps.addAll(widget.recipe!.preparacion);
      // Ensure we have enough focus nodes for the initial ingredients and steps
      while (_ingredientFocusNodes.length < _ingredients.length) {
        _addIngredientFocusNode();
      }
      while (_stepFocusNodes.length < _steps.length) {
        _addStepFocusNode();
      }
    }
  }

  // Estados de focus para cada tarjeta
  bool _basicInfoHasFocus = false;
  bool _ingredientsHasFocus = false;
  bool _stepsHasFocus = false;

  // Lista de focus nodes para ingredientes y pasos
  final List<FocusNode> _ingredientFocusNodes = [];
  final List<FocusNode> _stepFocusNodes = [];

  @override
  void _initializeFocusListeners() {
    // Listeners para los focus nodes de información básica
    void updateBasicInfoFocus() {
      setState(() {
        _basicInfoHasFocus =
            _nameFocus.hasFocus ||
            _descriptionFocus.hasFocus ||
            _rationsFocus.hasFocus ||
            _timeFocus.hasFocus ||
            _caloriesFocus.hasFocus;
      });
    }

    _nameFocus.addListener(updateBasicInfoFocus);
    _descriptionFocus.addListener(updateBasicInfoFocus);
    _rationsFocus.addListener(updateBasicInfoFocus);
    _timeFocus.addListener(updateBasicInfoFocus);
    _caloriesFocus.addListener(updateBasicInfoFocus);

    // Inicializar focus nodes para el primer ingrediente y paso
    _addIngredientFocusNode();
    _addStepFocusNode();
  }

  void _addIngredientFocusNode() {
    final focusNode = FocusNode();
    focusNode.addListener(() {
      setState(() {
        _ingredientsHasFocus = _ingredientFocusNodes.any(
          (node) => node.hasFocus,
        );
      });
    });
    _ingredientFocusNodes.add(focusNode);
  }

  void _addStepFocusNode() {
    final focusNode = FocusNode();
    focusNode.addListener(() {
      setState(() {
        _stepsHasFocus = _stepFocusNodes.any((node) => node.hasFocus);
      });
    });
    _stepFocusNodes.add(focusNode);
  }

  @override
  void dispose() {
    // Dispose de los focus nodes básicos
    _nameFocus.dispose();
    _descriptionFocus.dispose();
    _rationsFocus.dispose();
    _timeFocus.dispose();
    _caloriesFocus.dispose();

    // Dispose de los focus nodes de ingredientes y pasos
    for (var node in _ingredientFocusNodes) {
      node.dispose();
    }
    for (var node in _stepFocusNodes) {
      node.dispose();
    }

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
      appBar: null,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Crear nueva receta',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              // Primera tarjeta - Información básica
              NeumorphicCard(
                withInnerShadow: _basicInfoHasFocus,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        focusNode: _descriptionFocus,
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
                              focusNode: _rationsFocus,
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
                              focusNode: _timeFocus,
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
                              focusNode: _caloriesFocus,
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
                withInnerShadow: _ingredientsHasFocus,
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
                          // Añadir nuevo focus node si es necesario
                          if (index >= _ingredientFocusNodes.length) {
                            _addIngredientFocusNode();
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: _ingredients[index],
                                  focusNode: _ingredientFocusNodes[index],
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
                          );
                        },
                      ),
                      const SizedBox(height: 12),
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
                withInnerShadow: _stepsHasFocus,
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
                          // Añadir nuevo focus node si es necesario
                          if (index >= _stepFocusNodes.length) {
                            _addStepFocusNode();
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: _steps[index],
                                  focusNode: _stepFocusNodes[index],
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
                          );
                        },
                      ),
                      SizedBox(height: 12),
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
