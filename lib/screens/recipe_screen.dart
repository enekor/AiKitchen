import 'dart:convert';
import 'dart:io';
import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/gemini_service.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/services/widget_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/cooking_card.dart';
import 'package:aikitchen/widgets/ingredients_list.dart';
import 'package:aikitchen/widgets/steps_list.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import 'package:aikitchen/screens/settings.dart' show TipoReceta;

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key, required this.recipe});
  final Recipe recipe;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  bool _showSummary = false;
  bool _isFavorite = false;
  late Recipe showingRecipe;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    showingRecipe = widget.recipe;
  }

  void _onEditNumberOfPlates() async {
    int? newNumPlates = await showDialog<int>(
      context: context,
      builder: (context) {
        int selectedRaciones = widget.recipe.raciones;
        return AlertDialog(
          title: const Text('Selecciona el número de raciones'),
          content: SizedBox(
            height: 150,
            width: 80,
            child: StatefulBuilder(
              builder: (context, setState) {
                return ListWheelScrollView.useDelegate(
                  itemExtent: 40,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      selectedRaciones = index + 1;
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      return Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: selectedRaciones == index + 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selectedRaciones == index + 1
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                      );
                    },
                    childCount: 200,
                  ),
                  controller: FixedExtentScrollController(
                    initialItem: widget.recipe.raciones - 1,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Guarda el valor seleccionado en una variable de estado
                  Navigator.pop(context, selectedRaciones);
                });
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );

    newNumPlates ??=
        showingRecipe.raciones; // Si se cancela, mantener el valor original

    if (newNumPlates != showingRecipe.raciones) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      String prompt = Prompt.UpdateRecipePrompt(
        JsonEncoder().convert(showingRecipe.toJson()),
        newNumPlates,
      );

      String updatedRecipeJson = await AppSingleton().generateContent(
        prompt,
        context,
      );
      if (mounted) Navigator.of(context).pop(); // Cierra el loading
      setState(() {
        showingRecipe = Recipe.fromJson(
          jsonDecode(
            updatedRecipeJson.replaceAll('```json', '').replaceAll('```', ''),
          ),
        );
      });
    }
  }

  void _checkIfFavorite() {
    _isFavorite = AppSingleton().recetasFavoritas.any(
      (recipe) =>
          recipe.nombre == widget.recipe.nombre &&
          recipe.descripcion == widget.recipe.descripcion,
    );
  }

  void _toggleFavorite() async {
    if (_isFavorite) {
      AppSingleton().recetasFavoritas.removeWhere(
        (recipe) =>
            recipe.nombre == showingRecipe.nombre &&
            recipe.descripcion == showingRecipe.descripcion,
      );
      Toaster.showWarning('Eliminado de favoritos');
    } else {
      AppSingleton().recetasFavoritas.add(showingRecipe);
      Toaster.showSuccess('¡Añadido a favoritos!');
    }

    await JsonDocumentsService().setFavRecipes(AppSingleton().recetasFavoritas);

    // Actualizar widget de Android
    if (Platform.isAndroid) {
      await WidgetService.updateFavoritesWidget();
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _showEditOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('Cambiar número de raciones'),
                onTap: () async {
                  Navigator.pop(context);
                  _onEditNumberOfPlates();
                },
              ),
              ListTile(
                leading: const Icon(Icons.flash_on),
                title: const Text('Versión exprés (más rápida)'),
                onTap: () async {
                  Navigator.pop(context);
                  await _editRecipeWithPrompt(
                    Prompt.UpdateRecipePromptExpress(
                      JsonEncoder().convert(showingRecipe.toJson()),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.health_and_safety),
                title: const Text('Versión más saludable'),
                onTap: () async {
                  Navigator.pop(context);
                  await _editRecipeWithPrompt(
                    Prompt.UpdateRecipePromptSaludable(
                      JsonEncoder().convert(showingRecipe.toJson()),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.eco),
                title: const Text('Adaptar a dieta...'),
                onTap: () async {
                  Navigator.pop(context);
                  final dietas = TipoReceta.displayNames;
                  int selectedDieta = 0;
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      int selectedIndex = selectedDieta;
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: SizedBox(
                          height: 260,
                          width: 180,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 16),
                              const Text(
                                'Selecciona la dieta',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: StatefulBuilder(
                                  builder: (context, setState) {
                                    return ListWheelScrollView.useDelegate(
                                      itemExtent: 40,
                                      physics: const FixedExtentScrollPhysics(),
                                      onSelectedItemChanged: (index) =>
                                          setState(() => selectedIndex = index),
                                      childDelegate:
                                          ListWheelChildBuilderDelegate(
                                            builder: (context, index) {
                                              if (index < 0 ||
                                                  index >= dietas.length)
                                                return null;
                                              return Center(
                                                child: Text(
                                                  dietas[index],
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight:
                                                        selectedIndex == index
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color:
                                                        selectedIndex == index
                                                        ? Theme.of(
                                                            context,
                                                          ).colorScheme.primary
                                                        : null,
                                                  ),
                                                ),
                                              );
                                            },
                                            childCount: dietas.length,
                                          ),
                                      controller: FixedExtentScrollController(
                                        initialItem: selectedIndex,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(
                                      context,
                                      dietas[selectedIndex],
                                    ),
                                    child: const Text('Aceptar'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                  if (selected != null && selected.isNotEmpty) {
                    await _editRecipeWithPrompt(
                      Prompt.UpdateRecipePromptDieta(
                        JsonEncoder().convert(showingRecipe.toJson()),
                        selected,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.school),
                title: const Text('Cambiar dificultad...'),
                onTap: () async {
                  Navigator.pop(context);
                  final niveles = [
                    'Principiante',
                    'Intermedio',
                    'Avanzado',
                    'Experto',
                  ];
                  int selectedNivel = 0;
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      int selectedIndex = selectedNivel;
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: SizedBox(
                          height: 260,
                          width: 180,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 16),
                              const Text(
                                'Selecciona el nivel de dificultad',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: StatefulBuilder(
                                  builder: (context, setState) {
                                    return ListWheelScrollView.useDelegate(
                                      itemExtent: 40,
                                      physics: const FixedExtentScrollPhysics(),
                                      onSelectedItemChanged: (index) =>
                                          setState(() => selectedIndex = index),
                                      childDelegate:
                                          ListWheelChildBuilderDelegate(
                                            builder: (context, index) {
                                              if (index < 0 ||
                                                  index >= niveles.length)
                                                return null;
                                              return Center(
                                                child: Text(
                                                  niveles[index],
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight:
                                                        selectedIndex == index
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color:
                                                        selectedIndex == index
                                                        ? Theme.of(
                                                            context,
                                                          ).colorScheme.primary
                                                        : null,
                                                  ),
                                                ),
                                              );
                                            },
                                            childCount: niveles.length,
                                          ),
                                      controller: FixedExtentScrollController(
                                        initialItem: selectedIndex,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(
                                      context,
                                      niveles[selectedIndex],
                                    ),
                                    child: const Text('Aceptar'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                  if (selected != null && selected.isNotEmpty) {
                    await _editRecipeWithPrompt(
                      Prompt.UpdateRecipePromptDificultad(
                        JsonEncoder().convert(showingRecipe.toJson()),
                        selected,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.straighten),
                title: const Text('Cambiar unidades de medida...'),
                onTap: () async {
                  Navigator.pop(context);
                  await _editRecipeWithPrompt(
                    Prompt.UpdateRecipePromptUnidades(
                      JsonEncoder().convert(showingRecipe.toJson()),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.mood),
                title: const Text('Cambiar tono de explicación...'),
                onTap: () async {
                  Navigator.pop(context);
                  final tonos = [
                    'Amistoso',
                    'Profesional',
                    'Casual',
                    'Divertido',
                    'Educativo',
                    'Hiriente',
                    'Bromista',
                    'Sarcástico',
                    'Entusiasta',
                    'Neutral',
                  ];
                  int selectedTono = 0;
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (context) {
                      int selectedIndex = selectedTono;
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: SizedBox(
                          height: 260,
                          width: 180,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 16),
                              const Text(
                                'Selecciona el tono',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: StatefulBuilder(
                                  builder: (context, setState) {
                                    return ListWheelScrollView.useDelegate(
                                      itemExtent: 40,
                                      physics: const FixedExtentScrollPhysics(),
                                      onSelectedItemChanged: (index) =>
                                          setState(() => selectedIndex = index),
                                      childDelegate:
                                          ListWheelChildBuilderDelegate(
                                            builder: (context, index) {
                                              if (index < 0 ||
                                                  index >= tonos.length)
                                                return null;
                                              return Center(
                                                child: Text(
                                                  tonos[index],
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight:
                                                        selectedIndex == index
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color:
                                                        selectedIndex == index
                                                        ? Theme.of(
                                                            context,
                                                          ).colorScheme.primary
                                                        : null,
                                                  ),
                                                ),
                                              );
                                            },
                                            childCount: tonos.length,
                                          ),
                                      controller: FixedExtentScrollController(
                                        initialItem: selectedIndex,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(
                                      context,
                                      tonos[selectedIndex],
                                    ),
                                    child: const Text('Aceptar'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                  if (selected != null && selected.isNotEmpty) {
                    await _editRecipeWithPrompt(
                      Prompt.UpdateRecipePromptTono(
                        JsonEncoder().convert(showingRecipe.toJson()),
                        selected,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editRecipeWithPrompt(String prompt) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    String updatedRecipeJson = await AppSingleton().generateContent(
      prompt,
      context,
    );
    if (mounted) Navigator.of(context).pop(); // Cierra el loading
    setState(() {
      showingRecipe = Recipe.fromJson(
        jsonDecode(
          updatedRecipeJson.replaceAll('```json', '').replaceAll('```', ''),
        ),
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      /*appBar: AppBar(
        title: Text(showingRecipe.nombre),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          // Favorite button
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            tooltip: _isFavorite ? 'Quitar de favoritos' : 'Añadir a favoritos',
          ),

          // Recipe info chips in app bar
        ],
      ),*/
      body: Column(
        children: [
          // Recipe info header
          if (_showSummary)
            CookingCard(
              onTap: () => setState(() {
                _showSummary = !_showSummary;
              }),
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showingRecipe.descripcion,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildInfoItem(
                          Icons.local_fire_department,
                          '${showingRecipe.calorias.toInt()} cal',
                          theme.colorScheme.tertiary,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: _buildInfoItem(
                          Icons.timer,
                          showingRecipe.tiempoEstimado,
                          theme.colorScheme.secondary,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: _onEditNumberOfPlates,
                          child: _buildInfoItem(
                            Icons.restaurant,
                            '${showingRecipe.raciones}',
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (!_showSummary)
            CookingCard(
              onTap: () => setState(() {
                _showSummary = !_showSummary;
              }),
              margin: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Mostrar resumen',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Navigation tabs
          CookingCard(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _currentPage = 0);
                      _pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentPage == 0
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: _currentPage == 0
                            ? Border.all(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.3,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.format_list_numbered,
                            color: _currentPage == 0
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Preparación',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: _currentPage == 0
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                              fontWeight: _currentPage == 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _currentPage = 1);
                      _pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentPage == 1
                            ? theme.colorScheme.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: _currentPage == 1
                            ? Border.all(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.3,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_basket,
                            color: _currentPage == 1
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ingredientes',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: _currentPage == 1
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                              fontWeight: _currentPage == 1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                // Página 1: StepsList
                StepsList(steps: showingRecipe.preparacion),
                // Página 2: IngredientsList
                IngredientsList(ingredients: showingRecipe.ingredientes),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showEditOptions,
        child: const Icon(Icons.auto_awesome),
        tooltip: 'Editar receta',
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
