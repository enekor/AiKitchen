import 'dart:convert';

import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/models/recipe_screen_arguments.dart';
import 'package:aikitchen/navigation/app_routes.dart';
import 'package:aikitchen/services/cors_proxy.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/share_recipe_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:aikitchen/widgets/ui/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Modo "desde una URL" del centro de búsqueda. Sin `Scaffold` propio.
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
          RegExp(r'<script[^>]*>.*?</script>', dotAll: true, caseSensitive: false),
          ' ',
        )
        .replaceAll(
          RegExp(r'<style[^>]*>.*?</style>', dotAll: true, caseSensitive: false),
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
    return response
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
        .trim();
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
      // En navegador la petición va por el proxy: leer otra web directamente
      // desde el cliente lo impide CORS.
      final httpResponse = await http
          .get(
            CorsProxy.wrap(Uri.parse(url)),
            headers: kIsWeb ? const {} : const {'User-Agent': 'Mozilla/5.0'},
          )
          .timeout(const Duration(seconds: 20));

      if (httpResponse.statusCode != 200) {
        _handleError('No se pudo acceder a la URL (código ${httpResponse.statusCode})');
        return;
      }

      final rawText = _stripHtml(httpResponse.body);
      final content = rawText.length > 7000 ? rawText.substring(0, 7000) : rawText;

      if (!mounted) return;

      final aiResponse = await AppSingleton().generateContent(
        Prompt.recipeFromUrlPrompt(
          content,
          AppSingleton().personality,
          AppSingleton().idioma,
          AppSingleton().tipoReceta,
        ),
        context,
      );

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
              parsed['response'] as String? ?? 'No se pudo extraer una receta de esa URL.';
          _loading = false;
        });
      }
    } on http.ClientException catch (e) {
      debugPrint('Error de red leyendo la URL: $e');
      _handleError(CorsProxy.failureHint);
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _handleError(String error) {
    final message = error.replaceFirst(RegExp(r'^\w*Exception:\s*'), '').trim();
    setState(() {
      _loading = false;
      _errorMessage = message;
    });
    Toaster.showError(message);
  }

  void _onFavRecipe(Recipe recipe) {
    final isFav = AppSingleton().recetasFavoritas.any((r) => r.nombre == recipe.nombre);
    if (isFav) {
      AppSingleton().recetasFavoritas.removeWhere((r) => r.nombre == recipe.nombre);
      Toaster.showWarning('Eliminado de favoritos');
      if (recipe.id != null) JsonDocumentsService().removeFavRecipe(recipe.id!);
    } else {
      AppSingleton().recetasFavoritas.add(recipe);
      Toaster.showSuccess('¡Guardado en favoritos!');
      JsonDocumentsService().addFavRecipe(recipe);
    }
    setState(() {});
  }

  void _openRecipe(Recipe recipe) {
    Navigator.pushNamed(
      context,
      AppRoutes.recipe,
      arguments: RecipeScreenArguments(recipe: recipe),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        TextField(
          controller: _urlController,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'https://...',
            prefixIcon: const Icon(Icons.link_rounded),
            suffixIcon: _urlController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() => _urlController.clear()),
                  ),
          ),
          onSubmitted: (_) => _generateFromUrl(),
        ),
        const SizedBox(height: Spacing.lg),
        AiButton(
          label: 'Extraer receta',
          expand: true,
          onPressed: _generateFromUrl,
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: Spacing.xl),
          AppCard(
            color: theme.colorScheme.errorContainer,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: theme.colorScheme.onErrorContainer),
                const SizedBox(width: Spacing.md),
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
          ),
        ],
        if (_recipe != null) ...[
          const SizedBox(height: Spacing.xl),
          RecipeCard(
            recipe: _recipe!,
            onTap: () => _openRecipe(_recipe!),
            isFavorite: AppSingleton().recetasFavoritas.any(
              (r) => r.nombre == _recipe!.nombre,
            ),
            onToggleFavorite: () => _onFavRecipe(_recipe!),
            trailing: IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Compartir',
              onPressed: () => ShareRecipeService().shareRecipe([_recipe!]),
            ),
          ),
        ],
      ],
    );
  }
}
