import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/content_shell.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';

class CreateRecipe extends StatefulWidget {
  final Recipe? recipe;

  const CreateRecipe({super.key, this.recipe});

  @override
  State<CreateRecipe> createState() => _CreateRecipeState();
}

class _CreateRecipeState extends State<CreateRecipe> {
  final List<String> _ingredients = [''];
  final List<String> _steps = [''];

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedTimeController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _rationsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _estimatedTimeController.addListener(_onFieldChanged);
    _rationsController.addListener(_onFieldChanged);

    if (widget.recipe != null) {
      _nameController.text = widget.recipe!.nombre;
      _descriptionController.text = widget.recipe!.descripcion;
      _estimatedTimeController.text = widget.recipe!.tiempoEstimado.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      _caloriesController.text = widget.recipe!.calorias.toString();
      _rationsController.text = widget.recipe!.raciones.toString();
      _ingredients.clear();
      _steps.clear();
      _ingredients.addAll(widget.recipe!.ingredientes);
      _steps.addAll(widget.recipe!.preparacion);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _estimatedTimeController.dispose();
    _caloriesController.dispose();
    _rationsController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {});
  }

  bool get _isFormValid {
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasDescription = _descriptionController.text.trim().isNotEmpty;
    final hasRations = _rationsController.text.trim().isNotEmpty;
    final hasTime = _estimatedTimeController.text.trim().isNotEmpty;

    final hasIngredients = _ingredients.any((i) => i.trim().isNotEmpty);
    final hasSteps = _steps.any((s) => s.trim().isNotEmpty);

    return hasName && hasDescription && hasRations && hasTime && hasIngredients && hasSteps;
  }

  void _saveRecipe() {
    if (_nameController.text.isEmpty) {
      Toaster.showWarning('El nombre es obligatorio');
      return;
    }

    final recipe = Recipe(
      id: widget.recipe?.id,
      nombre: _nameController.text,
      descripcion: _descriptionController.text,
      raciones: _rationsController.text,
      calorias: _caloriesController.text,
      ingredientes: _ingredients.where((i) => i.isNotEmpty).toList(),
      preparacion: _steps.where((s) => s.isNotEmpty).toList(),
      tiempoEstimado: '${_estimatedTimeController.text} min',
      // Al editar se conserva el origen original de la receta.
      origen: widget.recipe?.origen ?? RecipeOrigin.manual,
    );

    if (widget.recipe != null) {
      JsonDocumentsService().updateFavRecipe(recipe);
    } else {
      JsonDocumentsService().addFavRecipe(recipe);
    }

    Toaster.showSuccess('${_nameController.text} guardada');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.recipe != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar receta' : 'Crear receta'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Spacing.md),
            child: FilledButton.icon(
              onPressed: _isFormValid ? _saveRecipe : null,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Guardar'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
        child: ContentShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(context, 'Información básica', Icons.info_outline_rounded),
              const SizedBox(height: Spacing.lg),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la receta',
                  hintText: '¿Cómo se llama tu plato?',
                ),
              ),
              const SizedBox(height: Spacing.md),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Cuéntanos algo sobre ella...',
                ),
              ),
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _rationsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Raciones'),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: TextField(
                      controller: _estimatedTimeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Minutos'),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: TextField(
                      controller: _caloriesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Calorías'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Spacing.xxl),
              _sectionHeader(context, 'Ingredientes', Icons.shopping_basket_outlined),
              const SizedBox(height: Spacing.lg),
              for (final entry in _ingredients.asMap().entries)
                _DynamicField(
                  key: ValueKey('ingrediente_${entry.key}'),
                  index: entry.key,
                  list: _ingredients,
                  hint: 'Ingrediente...',
                  onChanged: () => setState(() {}),
                ),

              const SizedBox(height: Spacing.xxl),
              _sectionHeader(context, 'Preparación', Icons.format_list_numbered_rounded),
              const SizedBox(height: Spacing.lg),
              for (final entry in _steps.asMap().entries)
                _DynamicField(
                  key: ValueKey('paso_${entry.key}'),
                  index: entry.key,
                  list: _steps,
                  hint: 'Paso ${entry.key + 1}',
                  maxLines: 2,
                  onChanged: () => setState(() {}),
                ),
              const SizedBox(height: Spacing.xxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isFormValid ? _saveRecipe : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                  ),
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Guardar Receta'),
                ),
              ),
              const SizedBox(height: Spacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: Spacing.sm),
        Text(title, style: theme.textTheme.titleMedium),
      ],
    );
  }
}

class _DynamicField extends StatelessWidget {
  const _DynamicField({
    super.key,
    required this.index,
    required this.list,
    required this.hint,
    required this.onChanged,
    this.maxLines = 1,
  });

  final int index;
  final List<String> list;
  final String hint;
  final int maxLines;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) {
                list[index] = v;
                onChanged();
              },
              controller: TextEditingController(text: list[index])
                ..selection = TextSelection.collapsed(offset: list[index].length),
              maxLines: maxLines,
              decoration: InputDecoration(hintText: hint),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          IconButton.filledTonal(
            onPressed: () {
              if (index == list.length - 1 && list[index].isNotEmpty) {
                list.add('');
              } else if (list.length > 1) {
                list.removeAt(index);
              }
              onChanged();
            },
            icon: Icon(
              index == list.length - 1 ? Icons.add_rounded : Icons.remove_rounded,
            ),
          ),
        ],
      ),
    );
  }
}
