import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/screens/create_recipe.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/share_recipe_service.dart';
import 'package:aikitchen/services/shared_preferences_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/lottie_animation_widget.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:aikitchen/widgets/cooking_card.dart';
import 'package:flutter/material.dart';

class FindByName extends StatefulWidget {
  const FindByName({super.key});

  @override
  State<FindByName> createState() => _FindByNameState();
}

class _FindByNameState extends State<FindByName> with TickerProviderStateMixin {
  List<Recipe>? _recetas;
  List<String> _historial = [];
  bool _searching = false;
  bool _showHistory = false;
  final TextEditingController _nameController = TextEditingController();
  late AnimationController _animationController;
  late AnimationController _historyAnimationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _historySlideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _historyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _historySlideAnimation = Tween<double>(begin: -20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _historyAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
    _loadHistory();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _historyAnimationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _loadHistory() async {
    final history = await SharedPreferencesService.getStringListValue(
      SharedPreferencesKeys.historialBusquedaNombres,
    );
    setState(() {
      _historial = history;
    });
  }

  void _toggleHistory() {
    setState(() {
      _showHistory = !_showHistory;
    });
    if (_showHistory) {
      _historyAnimationController.forward();
    } else {
      _historyAnimationController.reverse();
    }
  }

  int _totalTries = 0;
  String _cleanJsonResponse(String response) {
    // Remove markdown code blocks if present
    response = response.replaceAll(RegExp(r'```json\s*'), '');
    response = response.replaceAll(RegExp(r'\s*```'), '');
    response = response.trim();
    return response;
  }

  Future<void> _searchByName(String name) async {
    if (name.trim().isEmpty) {
      Toaster.showWarning('Escribe el nombre de una receta');
      return;
    }

    // Añadir al historial
    if (!_historial.contains(name.trim())) {
      setState(() {
        _historial.insert(0, name.trim());
        if (_historial.length > 10) {
          _historial = _historial.take(10).toList();
        }
      });
      SharedPreferencesService.setStringListValue(
        SharedPreferencesKeys.historialBusquedaNombres,
        _historial,
      );
    }

    setState(() {
      _recetas = [];
      _searching = true;
      _showHistory = false;
    });
    _historyAnimationController.reverse();
    try {
      final response = await AppSingleton().generateContent(
        Prompt.recipePromptByName(
          name,
          AppSingleton().numRecetas,
          AppSingleton().personality,
          AppSingleton().idioma,
          AppSingleton().tipoReceta,
        ),
        context,
      );

      final cleanedResponse = _cleanJsonResponse(response);

      if (cleanedResponse.isNotEmpty && !cleanedResponse.contains('error')) {
        setState(() {
          _recetas = Recipe.fromJsonList(cleanedResponse);
          _searching = false;
        });
        Toaster.showSuccess('¡${_recetas!.length} recetas encontradas!');
      } else {
        _handleError(response);
      }
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _handleError(String error) {
    setState(() => _searching = false);

    if (_totalTries < 2) {
      _totalTries++;
      Toaster.showWarning('Reintentando... (${_totalTries}/3)');
      Future.delayed(
        const Duration(seconds: 2),
        () => _searchByName(_nameController.text),
      );
    } else {
      _totalTries = 0;
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Error al buscar recetas'),
              content: Text('Ha ocurrido un error: ${error.split(":").last}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
      );
    }
  }

  void shareRecipe(List<Recipe> receta) async {
    await ShareRecipeService().shareRecipe(receta);
  }

  void onClickRecipe(Recipe receta) {
    Navigator.pushNamed(
      context,
      '/recipe',
      arguments: RecipeScreenArguments(recipe: receta),
    );
  }

  void onFavRecipe(Recipe recipe) {
    if (AppSingleton().recetasFavoritas.contains(recipe)) {
      AppSingleton().recetasFavoritas.remove(recipe);
      Toaster.showWarning('Eliminado de favoritos');
    } else {
      AppSingleton().recetasFavoritas.add(recipe);
      Toaster.showSuccess('¡Añadido a favoritos!');
    }
    JsonDocumentsService().setFavRecipes(AppSingleton().recetasFavoritas);
  }

  void onEditRecipe(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateRecipe(recipe: recipe)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // Sección de búsqueda moderna
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(opacity: _fadeAnimation.value, child: child),
                );
              },
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.secondary.withOpacity(0.05),
                          theme.colorScheme.tertiary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.secondary.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CookingCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Ej: Paella valenciana, Lasaña, Tiramisu...',
                                    hintStyle: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.restaurant_menu,
                                      color: theme.colorScheme.secondary,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  onSubmitted: _searchByName,
                                  onChanged: (value) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Botón de historial
                              if (_historial.isNotEmpty)
                                Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed: _toggleHistory,
                                    icon: AnimatedRotation(
                                      turns: _showHistory ? 0.5 : 0,
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: const Icon(Icons.history),
                                    ),
                                    color: theme.colorScheme.secondary,
                                    tooltip: 'Historial',
                                  ),
                                ),
                            ],
                          ),

                          // Historial desplegable
                          AnimatedBuilder(
                            animation: _historyAnimationController,
                            builder: (context, child) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height:
                                    _showHistory && _historial.isNotEmpty
                                        ? 200
                                        : 0,
                                child:
                                    _showHistory && _historial.isNotEmpty
                                        ? Transform.translate(
                                          offset: Offset(
                                            0,
                                            _historySlideAnimation.value,
                                          ),
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              top: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withOpacity(0.5),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: theme.colorScheme.outline
                                                    .withOpacity(0.2),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.history,
                                                        size: 16,
                                                        color:
                                                            theme
                                                                .colorScheme
                                                                .secondary,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Búsquedas recientes',
                                                        style: theme
                                                            .textTheme
                                                            .titleSmall
                                                            ?.copyWith(
                                                              color:
                                                                  theme
                                                                      .colorScheme
                                                                      .secondary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Expanded(
                                                  child: ListView.builder(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    itemCount:
                                                        _historial.length > 5
                                                            ? 5
                                                            : _historial.length,
                                                    itemBuilder: (
                                                      context,
                                                      index,
                                                    ) {
                                                      final item =
                                                          _historial[index];
                                                      return Container(
                                                        margin:
                                                            const EdgeInsets.symmetric(
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: ListTile(
                                                          dense: true,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          leading: Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  6,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: theme
                                                                  .colorScheme
                                                                  .secondary
                                                                  .withOpacity(
                                                                    0.1,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                            child: Icon(
                                                              Icons.access_time,
                                                              size: 14,
                                                              color:
                                                                  theme
                                                                      .colorScheme
                                                                      .secondary,
                                                            ),
                                                          ),
                                                          title: Text(
                                                            item,
                                                            style: theme
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                          ),
                                                          trailing: Icon(
                                                            Icons.north_west,
                                                            size: 16,
                                                            color: theme
                                                                .colorScheme
                                                                .onSurface
                                                                .withOpacity(
                                                                  0.5,
                                                                ),
                                                          ),
                                                          onTap: () {
                                                            _nameController
                                                                .text = item;
                                                            _searchByName(item);
                                                          },
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        : null,
                              );
                            },
                          ),

                          // Chips de sugerencias
                          if (!_showHistory &&
                              _nameController.text.isEmpty) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Sugerencias populares:',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,

                              child: Row(
                                spacing: 8,
                                children:
                                    [
                                          'Paella Valenciana',
                                          'Lasaña Boloñesa',
                                          'Tacos Mexicanos',
                                          'Sushi Rolls',
                                          'Pizza Margherita',
                                        ]
                                        .map(
                                          (suggestion) => _buildSuggestionChip(
                                            suggestion,
                                            theme,
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient:
                            _nameController.text.trim().isNotEmpty
                                ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.green,
                                    Colors.yellow,
                                    Colors.orange,
                                    Colors.red,
                                  ],
                                )
                                : null,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow:
                            _nameController.text.trim().isNotEmpty
                                ? [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                                : null,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(17),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(17),
                            onTap:
                                _searching ||
                                        _nameController.text.trim().isEmpty
                                    ? null
                                    : () => _searchByName(_nameController.text),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              child:
                                  _searching
                                      ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    theme.colorScheme.secondary,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Buscando recetas...',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  color:
                                                      theme
                                                          .colorScheme
                                                          .secondary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      )
                                      : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.search,
                                            color:
                                                _nameController.text
                                                        .trim()
                                                        .isNotEmpty
                                                    ? theme
                                                        .colorScheme
                                                        .secondary
                                                    : theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.5),
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _nameController.text.trim().isEmpty
                                                ? 'Escribe un nombre primero'
                                                : '¡Buscar recetas!',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  color:
                                                      _nameController.text
                                                              .trim()
                                                              .isNotEmpty
                                                          ? theme
                                                              .colorScheme
                                                              .secondary
                                                          : theme
                                                              .colorScheme
                                                              .onSurface
                                                              .withOpacity(0.5),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Espacio entre sección de búsqueda y resultados
        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Resultados como sliver
        _buildResultsSliver(),
      ],
    );
  }

  Widget _buildSuggestionChip(String suggestion, ThemeData theme) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (suggestion.hashCode % 300)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.secondary.withOpacity(0.1),
                    theme.colorScheme.tertiary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.3),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    _nameController.text = suggestion;
                    _searchByName(suggestion);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          suggestion,
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsSliver() {
    final theme = Theme.of(context);

    if (_searching) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: LottieAnimationWidget(type: LottieAnimationType.loading),
              ),
              const SizedBox(height: 24),
              Text(
                'Buscando recetas perfectas...',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Buscando: "${_nameController.text}"',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_recetas != null && _recetas!.isNotEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index < _recetas!.length) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildRecipeCard(_recetas![index], theme),
              );
            }
            return null;
          }, childCount: _recetas!.length),
        ),
      );
    }

    if (_recetas != null && _recetas!.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: LottieAnimationWidget(
                  type: LottieAnimationType.notfound,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '¡Ups! No encontré esa receta',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Intenta con un nombre diferente\no verifica la ortografía',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextButton.icon(
                  onPressed: () {
                    final sugerencias = [
                      'Paella',
                      'Lasaña',
                      'Pizza',
                      'Sushi',
                      'Tacos',
                    ];
                    final random = (sugerencias..shuffle()).first;
                    _nameController.text = random;
                    _searchByName(random);
                  },
                  icon: Icon(
                    Icons.lightbulb_outline,
                    color: theme.colorScheme.secondary,
                  ),
                  label: Text(
                    'Probar una sugerencia',
                    style: TextStyle(color: theme.colorScheme.secondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.secondary.withOpacity(0.1),
                    theme.colorScheme.tertiary.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.secondary.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.search,
                size: 80,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '¡Busca tu receta favorita!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Text(
                'Escribe el nombre de cualquier receta y te ayudaré a encontrarla con instrucciones detalladas',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onClickRecipe(recipe),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.restaurant_menu,
                        color: theme.colorScheme.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recipe.nombre,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onFavRecipe(recipe),
                      icon: Icon(
                        AppSingleton().recetasFavoritas.contains(recipe)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color:
                            AppSingleton().recetasFavoritas.contains(recipe)
                                ? Colors.red
                                : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  recipe.descripcion,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      recipe.tiempoEstimado,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.people,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.raciones} personas',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
