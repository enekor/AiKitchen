import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/widgets/cooking_card.dart';

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

    JsonDocumentsService().updateFavRecipe(
      recipe,
    );

    Toaster.showSuccess('${_nameController.text} guardada con éxito');
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

      _ingredients.clear();
      _steps.clear();
      _ingredients.addAll(widget.recipe!.ingredientes);
      _steps.addAll(widget.recipe!.preparacion);

      while (_ingredientFocusNodes.length < _ingredients.length) {
        _addIngredientFocusNode();
      }
      while (_stepFocusNodes.length < _steps.length) {
        _addStepFocusNode();
      }
    }
  }

  // Estados de focus para cada tarjeta
  bool _ingredientsHasFocus = false;
  bool _stepsHasFocus = false;

  // Lista de focus nodes para ingredientes y pasos
  final List<FocusNode> _ingredientFocusNodes = [];
  final List<FocusNode> _stepFocusNodes = [];

  void _initializeFocusListeners() {
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
    _nameFocus.dispose();
    _descriptionFocus.dispose();
    _rationsFocus.dispose();
    _timeFocus.dispose();
    _caloriesFocus.dispose();

    for (var node in _ingredientFocusNodes) {
      node.dispose();
    }
    for (var node in _stepFocusNodes) {
      node.dispose();
    }

    _nameController.dispose();
    _descriptionController.dispose();
    _estimatedTimeController.dispose();
    _caloriesController.dispose();
    _rationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      /*appBar: AppBar(
        title: Text(widget.recipe == null ? 'Crear receta' : 'Editar receta'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),*/
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with cooking icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.restaurant_menu,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.recipe == null
                          ? 'Crear nueva receta'
                          : 'Editar receta',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Primera tarjeta - Información básica
              CookingCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Información básica',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      enabled: widget.recipe == null,
                      controller: _nameController,
                      focusNode: _nameFocus,
                      decoration: InputDecoration(
                        labelText: 'Nombre de la receta',
                        prefixIcon: const Icon(Icons.restaurant),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      focusNode: _descriptionFocus,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                            decoration: InputDecoration(
                              labelText: 'Raciones',
                              prefixIcon: const Icon(Icons.people),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _estimatedTimeController,
                            focusNode: _timeFocus,
                            decoration: InputDecoration(
                              labelText: 'Tiempo (min)',
                              prefixIcon: const Icon(Icons.timer),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _caloriesController,
                            focusNode: _caloriesFocus,
                            decoration: InputDecoration(
                              labelText: 'Calorías',
                              prefixIcon: const Icon(
                                Icons.local_fire_department,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Segunda tarjeta - Ingredientes
              CookingCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_basket,
                          color: theme.colorScheme.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ingredientes',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _ingredients.length,
                      itemBuilder: (context, index) {
                        if (index >= _ingredientFocusNodes.length) {
                          _addIngredientFocusNode();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: _ingredients[index],
                                  focusNode: _ingredientFocusNodes[index],
                                  decoration: InputDecoration(
                                    labelText: 'Ingrediente ${index + 1}',
                                    prefixIcon: const Icon(
                                      Icons.add_shopping_cart,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    _ingredients[index] = value;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
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
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _ingredients.add('');
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir ingrediente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tercera tarjeta - Pasos de preparación
              CookingCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_list_numbered,
                          color: theme.colorScheme.tertiary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pasos de preparación',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _steps.length,
                      itemBuilder: (context, index) {
                        if (index >= _stepFocusNodes.length) {
                          _addStepFocusNode();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: _steps[index],
                                  focusNode: _stepFocusNodes[index],
                                  decoration: InputDecoration(
                                    labelText: 'Paso ${index + 1}',
                                    prefixIcon: const Icon(Icons.soup_kitchen),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  maxLines: 3,
                                  onChanged: (value) {
                                    _steps[index] = value;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
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
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _steps.add('');
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir paso'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.tertiary,
                        foregroundColor: theme.colorScheme.onTertiary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save button
              ElevatedButton.icon(
                onPressed: saveRecipe,
                icon: const Icon(Icons.save),
                label: Text(
                  widget.recipe == null
                      ? 'Guardar receta'
                      : 'Actualizar receta',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
