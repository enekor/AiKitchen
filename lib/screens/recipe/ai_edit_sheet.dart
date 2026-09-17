import 'dart:convert';

import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:aikitchen/widgets/ui/ui.dart';
import 'package:flutter/material.dart';

enum _Dificultad { principiante, intermedio, avanzado }

enum _Tono { conciso, guiado, profesional }

/// Panel de "Modificar con IA": las siete opciones existentes como prompts,
/// más una petición libre, combinadas en una sola llamada al modelo.
class AiEditSheet extends StatefulWidget {
  const AiEditSheet({super.key, required this.recipe, required this.onRecipeUpdated});

  final Recipe recipe;
  final ValueChanged<Recipe> onRecipeUpdated;

  static Future<void> show(
    BuildContext context, {
    required Recipe recipe,
    required ValueChanged<Recipe> onRecipeUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AiEditSheet(recipe: recipe, onRecipeUpdated: onRecipeUpdated),
    );
  }

  @override
  State<AiEditSheet> createState() => _AiEditSheetState();
}

class _AiEditSheetState extends State<AiEditSheet> {
  bool _processing = false;

  late int _raciones = int.tryParse(widget.recipe.raciones) ?? 2;
  bool _cambiarUnidades = false;
  bool _expres = false;
  bool _saludable = false;
  String? _dieta;
  _Dificultad _dificultad = _Dificultad.intermedio;
  _Tono _tono = _Tono.guiado;
  final _peticionController = TextEditingController();

  static const _dietas = [
    'Sin gluten',
    'Sin lactosa',
    'Keto / baja en carbohidratos',
    'Vegetariana',
    'Apta para diabéticos',
  ];

  @override
  void dispose() {
    _peticionController.dispose();
    super.dispose();
  }

  List<String> _buildInstructions() {
    final original = int.tryParse(widget.recipe.raciones) ?? _raciones;
    final instrucciones = <String>[];

    if (_raciones != original) {
      instrucciones.add(
        'Cambia el número de raciones a $_raciones y ajusta proporcionalmente las cantidades de los ingredientes.',
      );
    }
    if (_cambiarUnidades) {
      instrucciones.add(
        'Convierte las medidas de los ingredientes a tazas, cucharadas u otras unidades prácticas, dejando en su unidad original las que ya sean prácticas (como "1 huevo").',
      );
    }
    if (_expres) {
      instrucciones.add('Haz una versión exprés, más rápida de preparar.');
    }
    if (_saludable) {
      instrucciones.add('Haz una versión más saludable, con menos grasas y calorías.');
    }
    if (_dieta != null) {
      instrucciones.add('Adapta la receta para que sea apta para una dieta "$_dieta".');
    }
    instrucciones.add(
      'El nivel de dificultad debe ser "${_dificultadLabel(_dificultad)}".',
    );
    instrucciones.add('El tono de las instrucciones debe ser: ${_tonoLabel(_tono)}.');
    if (_peticionController.text.trim().isNotEmpty) {
      instrucciones.add(_peticionController.text.trim());
    }
    return instrucciones;
  }

  String _dificultadLabel(_Dificultad d) => switch (d) {
    _Dificultad.principiante => 'Principiante',
    _Dificultad.intermedio => 'Intermedio',
    _Dificultad.avanzado => 'Avanzado',
  };

  String _tonoLabel(_Tono t) => switch (t) {
    _Tono.conciso => 'conciso y directo, con tiempos exactos y sin florituras',
    _Tono.guiado =>
      'paso a paso guiado para principiantes, con explicaciones de textura y avisos de seguridad',
    _Tono.profesional =>
      'explicación de chef profesional, con enfoque culinario avanzado',
  };

  Future<void> _generate() async {
    final instrucciones = _buildInstructions();
    setState(() => _processing = true);

    try {
      final recipeJsonStr = jsonEncode([widget.recipe.toJson()]);
      final response = await AppSingleton().generateContent(
        Prompt.combinedUpdatePrompt(recipeJsonStr, instrucciones),
        context,
      );

      if (response.isNotEmpty && !response.contains('error')) {
        final cleaned = response
            .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
            .replaceAll(RegExp(r'\s*```$', multiLine: true), '')
            .trim();
        final newRecipes = Recipe.fromJsonList(cleaned);
        if (newRecipes.isNotEmpty) {
          widget.onRecipeUpdated(newRecipes.first);
          if (mounted) Navigator.pop(context);
          Toaster.showSuccess('¡Receta actualizada!');
        } else {
          Toaster.showError('La IA no devolvió una receta válida');
        }
      } else {
        Toaster.showError('Algo ha fallado: ${response.split(":").last}');
      }
    } catch (e) {
      Toaster.showError('Error al modificar la receta: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = context.aiAccent;

    if (_processing) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: accent.color),
                  const SizedBox(width: Spacing.sm),
                  Text('Modificar con IA', style: theme.textTheme.headlineSmall),
                ],
              ),
              const SizedBox(height: Spacing.xl),

              _SettingTile(
                title: 'Raciones',
                child: Row(
                  children: [
                    IconButton.outlined(
                      onPressed: _raciones > 1
                          ? () => setState(() => _raciones--)
                          : null,
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '$_raciones',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton.outlined(
                      onPressed: () => setState(() => _raciones++),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),

              _SettingTile(
                title: 'Sistema de unidades',
                subtitle: 'Convertir a tazas, cucharadas, etc.',
                child: Switch(
                  value: _cambiarUnidades,
                  onChanged: (v) => setState(() => _cambiarUnidades = v),
                ),
              ),
              const SizedBox(height: Spacing.md),

              _SettingTile(
                title: 'Versión exprés',
                subtitle: 'Menos de 15 minutos',
                child: Switch(value: _expres, onChanged: (v) => setState(() => _expres = v)),
              ),
              const SizedBox(height: Spacing.md),

              _SettingTile(
                title: 'Versión más saludable',
                subtitle: 'Menos grasas y calorías',
                child: Switch(
                  value: _saludable,
                  onChanged: (v) => setState(() => _saludable = v),
                ),
              ),
              const SizedBox(height: Spacing.lg),

              Text('Adaptar a una dieta', style: theme.textTheme.titleMedium),
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: [
                  for (final dieta in _dietas)
                    ChoiceChip(
                      label: Text(dieta),
                      selected: _dieta == dieta,
                      onSelected: (selected) =>
                          setState(() => _dieta = selected ? dieta : null),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.lg),

              Text('Nivel de dificultad', style: theme.textTheme.titleMedium),
              const SizedBox(height: Spacing.sm),
              SegmentedButton<_Dificultad>(
                segments: const [
                  ButtonSegment(value: _Dificultad.principiante, label: Text('Principiante')),
                  ButtonSegment(value: _Dificultad.intermedio, label: Text('Intermedio')),
                  ButtonSegment(value: _Dificultad.avanzado, label: Text('Avanzado')),
                ],
                selected: {_dificultad},
                onSelectionChanged: (s) => setState(() => _dificultad = s.first),
              ),
              const SizedBox(height: Spacing.lg),

              Text('Tono de las instrucciones', style: theme.textTheme.titleMedium),
              const SizedBox(height: Spacing.sm),
              RadioGroup<_Tono>(
                groupValue: _tono,
                onChanged: (v) => setState(() => _tono = v!),
                child: Column(
                  children: [
                    for (final tono in _Tono.values)
                      RadioListTile<_Tono>(
                        contentPadding: EdgeInsets.zero,
                        value: tono,
                        title: Text(_tonoTitle(tono)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),

              Text('Petición personalizada', style: theme.textTheme.titleMedium),
              const SizedBox(height: Spacing.sm),
              TextField(
                controller: _peticionController,
                maxLength: 300,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Añade preferencias específicas, ingredientes a evitar...',
                ),
              ),
              const SizedBox(height: Spacing.md),
              AiButton(
                label: 'Generar nueva receta',
                expand: true,
                onPressed: _generate,
              ),
            ],
          ),
        );
      },
    );
  }

  String _tonoTitle(_Tono t) => switch (t) {
    _Tono.conciso => 'Conciso y directo',
    _Tono.guiado => 'Paso a paso guiado para principiantes',
    _Tono.profesional => 'Explicación de chef profesional',
  };
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}
