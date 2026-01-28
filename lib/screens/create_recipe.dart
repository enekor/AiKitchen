import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      id: widget.recipe?.id,
      nombre: _nameController.text,
      descripcion: _descriptionController.text,
      raciones: int.tryParse(_rationsController.text) ?? 1,
      calorias: double.tryParse(_caloriesController.text) ?? 0,
      ingredientes: _ingredients.where((i) => i.isNotEmpty).toList(),
      preparacion: _steps.where((s) => s.isNotEmpty).toList(),
      tiempoEstimado: "${_estimatedTimeController.text} min",
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Expressive que respeta la barra de estado
          /*SliverAppBar.large(
            backgroundColor: theme.colorScheme.surface,
            expandedHeight: 200,
            collapsedHeight: kToolbarHeight + MediaQuery.of(context).padding.top,
            pinned: true,
            stretch: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton.filledTonal(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              centerTitle: false,
              title: Text(
                widget.recipe == null ? 'Crear Receta' : 'Editar Receta',
                style: GoogleFonts.robotoFlex(
                  textStyle: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    letterSpacing: -1.2,
                  ),
                ),
              ),
            ),
          ),*/

          // Formulario
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _sectionHeader(theme, 'Información básica', Icons.info_outline_rounded),
                const SizedBox(height: 20),
                _buildTextField(theme, _nameController, '¿Cómo se llama tu plato?', Icons.restaurant_rounded),
                const SizedBox(height: 16),
                _buildTextField(theme, _descriptionController, 'Cuéntanos algo sobre ella...', Icons.description_rounded, maxLines: 3),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(theme, _rationsController, 'Raciones', Icons.people_rounded, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField(theme, _estimatedTimeController, 'Minutos', Icons.timer_rounded, keyboardType: TextInputType.number)),
                  ],
                ),
                
                const SizedBox(height: 48),
                _sectionHeader(theme, 'Ingredientes', Icons.shopping_basket_rounded),
                const SizedBox(height: 20),
                ..._ingredients.asMap().entries.map((entry) => _buildDynamicField(theme, entry.key, _ingredients, 'Ingrediente...', Icons.check_rounded)),
                
                const SizedBox(height: 48),
                _sectionHeader(theme, 'Preparación', Icons.format_list_numbered_rounded),
                const SizedBox(height: 20),
                ..._steps.asMap().entries.map((entry) => _buildDynamicField(theme, entry.key, _steps, 'Paso ${entry.key + 1}', Icons.arrow_forward_rounded, maxLines: 2)),
              ]),
            ),
          ),
        ],
      ),
      // Botón flotante sobredimensionado
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FloatingActionButton.extended(
          onPressed: _saveRecipe,
          elevation: 0,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          label: const Text('GUARDAR CAMBIOS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          icon: const Icon(Icons.save_rounded),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _sectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.secondary),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
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
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
          prefixIcon: Icon(icon, size: 20, color: theme.colorScheme.primary.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
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
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => list[index] = v,
                controller: TextEditingController(text: list[index])..selection = TextSelection.collapsed(offset: list[index].length),
                maxLines: maxLines,
                style: const TextStyle(fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: Icon(icon, size: 18, color: theme.colorScheme.secondary.withOpacity(0.6)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () {
              setState(() {
                if (index == list.length - 1 && list[index].isNotEmpty) {
                  list.add('');
                } else if (list.length > 1) {
                  list.removeAt(index);
                }
              });
            },
            icon: Icon(index == list.length - 1 ? Icons.add_rounded : Icons.remove_rounded),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: index == list.length - 1 ? theme.colorScheme.primaryContainer : null,
            ),
          ),
        ],
      ),
    );
  }
}
