import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/recipe_from_file_service.dart';
import 'package:aikitchen/widgets/neumorphic_card.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class PreviewSharedFiles extends StatefulWidget {
  const PreviewSharedFiles({Key? key, required this.recipeUri})
    : super(key: key);

  final String recipeUri;

  @override
  State<PreviewSharedFiles> createState() => _PreviewSharedFilesState();
}

class _PreviewSharedFilesState extends State<PreviewSharedFiles> {
  List<Recipe>? _recipe;
  late Future<List<Recipe>?> _recipeFuture;

  @override
  void initState() {
    super.initState();
    _recipeFuture = _loadRecipe();
  }

  Future<List<Recipe>?> _loadRecipe() async {
    try {
      final recipes = await RecipeFromFileService().loadRecipes(
        widget.recipeUri,
      );
      if (mounted) {
        setState(() => _recipe = recipes);
      }
      return recipes;
    } catch (e) {
      debugPrint('Error loading recipe: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    int _showingRecipe = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _recipe![_showingRecipe].nombre ?? 'Vista previa de recetas',
        ),
        centerTitle: true,
      ),
      floatingActionButton:
          _recipe != null
              ? FloatingActionButton.extended(
                onPressed: () {
                  JsonDocumentsService().updateFavRecipes(
                    _recipe![_showingRecipe],
                  );
                  Toaster.showToast(
                    '${_recipe![_showingRecipe].nombre} guardada como favorita',
                  );
                },
                label: const Text('Guardar receta'),
                icon: const Icon(Icons.save),
              )
              : null,
      body: FutureBuilder<List<Recipe>?>(
        future: _recipeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar la receta',
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          final recipe = snapshot.data!;
          return CarouselSlider(
            options: CarouselOptions(
              height: MediaQuery.of(context).size.height,
              initialPage: _showingRecipe,
              viewportFraction: 0.9,
              enlargeCenterPage: true,
              enableInfiniteScroll: false,
              autoPlay: false,
              pageSnapping: true,
              padEnds: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _showingRecipe = index;
                });
              },
            ),
            items: [
              ...recipe?.map((r) => _recipePreview(r, theme)) ??
                  [Center(child: Text('No hay nada aqui'))],
            ],
          );
        },
      ),
    );
  }

  Widget _recipePreview(Recipe recipe, ThemeData theme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información básica
            NeumorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.nombre,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(recipe.descripcion, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoItem(
                          icon: Icons.timer,
                          label: 'Tiempo',
                          value: recipe.tiempoEstimado,
                        ),
                        _buildInfoItem(
                          icon: Icons.local_fire_department,
                          label: 'Calorías',
                          value: '${recipe.calorias} cal',
                        ),
                        _buildInfoItem(
                          icon: Icons.restaurant,
                          label: 'Raciones',
                          value: '${recipe.raciones}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ingredientes
            NeumorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingredientes',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...(recipe.ingredientes.map(
                      (ingredient) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.fiber_manual_record, size: 8),
                            const SizedBox(width: 8),
                            Expanded(child: Text(ingredient)),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pasos
            NeumorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preparación',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...(recipe.preparacion.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(entry.value)),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
