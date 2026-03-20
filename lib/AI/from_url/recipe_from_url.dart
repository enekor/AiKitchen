import 'dart:convert';

import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/share_recipe_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/lottie_animation_widget.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecipeFromUrl extends StatefulWidget {
  const RecipeFromUrl({super.key});

  @override
  State<RecipeFromUrl> createState() => _RecipeFromUrlState();
}

class _RecipeFromUrlState extends State<RecipeFromUrl> {
  final _urlController = TextEditingController();
  Recipe? _recipe;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(
          RegExp(
            r'<script[^>]*>.*?</script>',
            dotAll: true,
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(
            r'<style[^>]*>.*?</style>',
            dotAll: true,
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _cleanJsonResponse(String response) {
    String cleaned = response;
    cleaned = cleaned.replaceAll(RegExp(r'^```json\s*', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*```$', multiLine: true), '');
    return cleaned.trim();
  }

  Future<void> _generateFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      Toaster.showWarning('Introduce una URL');
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      Toaster.showWarning('La URL debe empezar por http:// o https://');
      return;
    }

    setState(() {
      _loading = true;
      _recipe = null;
      _errorMessage = null;
    });

    try {
      // Fetch URL content
      final httpResponse = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 15));

      if (httpResponse.statusCode != 200) {
        _handleError(
          'No se pudo acceder a la URL (código ${httpResponse.statusCode})',
        );
        return;
      }

      // Strip HTML and truncate to avoid token limits
      final rawText = _stripHtml(httpResponse.body);
      final content = rawText.length > 7000
          ? rawText.substring(0, 7000)
          : rawText;

      // Call AI
      final aiResponse = await AppSingleton().generateContent(
        Prompt.recipeFromUrlPrompt(
          content,
          AppSingleton().personality,
          AppSingleton().idioma,
          AppSingleton().tipoReceta,
        ),
        context,
      );

      // Parse {status, response} JSON
      final cleaned = _cleanJsonResponse(aiResponse);
      final Map<String, dynamic> parsed = jsonDecode(cleaned);

      if (parsed['status'] == 'ok') {
        final recipes = Recipe.fromJsonList(jsonEncode(parsed['response']));
        if (recipes.isNotEmpty) {
          setState(() {
            _recipe = recipes.first;
            _loading = false;
          });
          Toaster.showSuccess('¡Receta extraída con éxito!');
        } else {
          _handleError('La IA no pudo extraer la receta.');
        }
      } else {
        setState(() {
          _errorMessage =
              parsed['response'] as String? ??
              'No se pudo extraer una receta de esa URL.';
          _loading = false;
        });
      }
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _handleError(String error) {
    setState(() => _loading = false);
    Toaster.showError('Error: ${error.split(":").last.trim()}');
  }

  void _onFavRecipe(Recipe recipe) {
    bool isFav = AppSingleton().recetasFavoritas.any(
      (r) => r.nombre == recipe.nombre,
    );
    if (isFav) {
      AppSingleton().recetasFavoritas.removeWhere(
        (r) => r.nombre == recipe.nombre,
      );
      Toaster.showWarning('Eliminado de favoritos');
      if (recipe.id != null) JsonDocumentsService().removeFavRecipe(recipe.id!);
    } else {
      AppSingleton().recetasFavoritas.add(recipe);
      Toaster.showSuccess('¡Guardado en favoritos!');
      JsonDocumentsService().addFavRecipe(recipe);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: LottieAnimationWidget(type: LottieAnimationType.loading),
        ),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUrlInput(theme),
            const SizedBox(height: 20),
            _buildGenerateButton(theme),
            if (_errorMessage != null) ...[
              const SizedBox(height: 32),
              _buildErrorCard(theme),
            ],
            if (_recipe != null) ...[
              const SizedBox(height: 40),
              _buildResultHeader(theme),
              const SizedBox(height: 16),
              _recipeCard(theme, _recipe!),
            ],
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlInput(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.link_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'https://...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _generateFromUrl(),
            ),
          ),
          if (_urlController.text.isNotEmpty)
            IconButton(
              onPressed: () => setState(() => _urlController.clear()),
              icon: const Icon(Icons.close_rounded),
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FloatingActionButton.extended(
        onPressed: _generateFromUrl,
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        label: const Text(
          'EXTRAER RECETA',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        icon: const Icon(Icons.auto_awesome_rounded),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: theme.colorScheme.error,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultHeader(ThemeData theme) {
    return Text(
      'RECETA EXTRAÍDA',
      style: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        color: theme.colorScheme.secondary,
      ),
    );
  }

  Widget _recipeCard(ThemeData theme, Recipe receta) {
    bool isFav = AppSingleton().recetasFavoritas.any(
      (r) => r.nombre == receta.nombre,
    );
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: () => Navigator.pushNamed(
          context,
          '/recipe',
          arguments: RecipeScreenArguments(recipe: receta),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receta.nombre,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          receta.descripcion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    icon: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                    ),
                    color: isFav ? Colors.redAccent : null,
                    onPressed: () => _onFavRecipe(receta),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoBadge(theme, Icons.timer_rounded, receta.tiempoEstimado),
                  _infoBadge(
                    theme,
                    Icons.local_fire_department_rounded,
                    receta.calorias,
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.share_rounded, size: 20),
                    onPressed: () => ShareRecipeService().shareRecipe([receta]),
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBadge(ThemeData theme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
