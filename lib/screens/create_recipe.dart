import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/json_documents.dart';
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
    if (widget.recipe != null) {
      _nameController.text = widget.recipe!.nombre;
      _descriptionController.text = widget.recipe!.descripcion;
      _estimatedTimeController.text = widget.recipe!.tiempoEstimado.replaceAll(RegExp(r'[^0-9]'), '');
      _caloriesController.text = widget.recipe!.calorias.toString();
      _rationsController.text = widget.recipe!.raciones.toString();
      _ingredients.clear();
      _steps.clear();
      _ingredients.addAll(widget.recipe!.ingredientes);
      _steps.addAll(widget.recipe!.preparacion);
    }
  }

  void _saveRecipe() {
    if (_nameController.text.isEmpty) {
      Toaster.showWarning('El nombre es obligatorio');
      return;
    }

    Recipe recipe = Recipe(
      nombre: _nameController.text,
      descripcion: _descriptionController.text,
      raciones: int.tryParse(_rationsController.text) ?? 1,
      calorias: double.tryParse(_caloriesController.text) ?? 0,
      ingredientes: _ingredients.where((i) => i.isNotEmpty).toList(),
      preparacion: _steps.where((s) => s.isNotEmpty).toList(),
      tiempoEstimado: "${_estimatedTimeController.text} min",
    );

    JsonDocumentsService().addFavRecipe(recipe);
    Toaster.showSuccess('${_nameController.text} guardada');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.recipe == null ? 'Crear' : 'Editar',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Añade tu propia magia culinaria a la biblioteca',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            
            _sectionTitle(theme, 'Información básica', Icons.info_outline_rounded),
            const SizedBox(height: 16),
            _buildTextField(theme, _nameController, 'Nombre de la receta', Icons.restaurant_rounded),
            const SizedBox(height: 16),
            _buildTextField(theme, _descriptionController, 'Breve descripción', Icons.description_rounded, maxLines: 3),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField(theme, _rationsController, 'Raciones', Icons.people_rounded, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(theme, _estimatedTimeController, 'Minutos', Icons.timer_rounded, keyboardType: TextInputType.number)),
              ],
            ),
            
            const SizedBox(height: 32),
            _sectionTitle(theme, 'Ingredientes', Icons.shopping_basket_rounded),
            const SizedBox(height: 16),
            ..._ingredients.asMap().entries.map((entry) => _buildDynamicField(theme, entry.key, _ingredients, 'Ingrediente', Icons.check_circle_outline_rounded)),
            
            const SizedBox(height: 32),
            _sectionTitle(theme, 'Pasos', Icons.format_list_numbered_rounded),
            const SizedBox(height: 16),
            ..._steps.asMap().entries.map((entry) => _buildDynamicField(theme, entry.key, _steps, 'Paso ${entry.key + 1}', Icons.arrow_forward_rounded, maxLines: 2)),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: FloatingActionButton.extended(
                onPressed: _saveRecipe,
                elevation: 0,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                label: const Text('GUARDAR RECETA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                icon: const Icon(Icons.save_rounded),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.secondary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(ThemeData theme, TextEditingController controller, String hint, IconData icon, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDynamicField(ThemeData theme, int index, List<String> list, String hint, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => list[index] = v,
                controller: TextEditingController(text: list[index])..selection = TextSelection.collapsed(offset: list[index].length),
                maxLines: maxLines,
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: Icon(icon, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () {
              setState(() {
                if (index == list.length - 1) {
                  list.add('');
                } else {
                  list.removeAt(index);
                }
              });
            },
            icon: Icon(index == list.length - 1 ? Icons.add_rounded : Icons.remove_rounded),
            style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          ),
        ],
      ),
    );
  }
}
