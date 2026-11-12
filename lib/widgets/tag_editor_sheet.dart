import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/ui/ui.dart';
import 'package:flutter/material.dart';

/// Editor de etiquetas de una receta. Devuelve la lista nueva al pulsar
/// "Guardar", o `null` si se cierra sin guardar.
class TagEditorSheet extends StatefulWidget {
  const TagEditorSheet({
    super.key,
    required this.initialTags,
    required this.knownTags,
  });

  final List<String> initialTags;

  /// Etiquetas ya usadas en otras recetas, para reutilizarlas con un toque.
  final List<String> knownTags;

  /// Etiquetas que se proponen aunque aún no se hayan usado.
  static const suggestedTags = [
    'Cenas rápidas',
    'Táper',
    'Para niños',
    'Fiestas',
    'Postres',
    'Batch cooking',
    'Favorita de casa',
  ];

  static Future<List<String>?> show(
    BuildContext context, {
    required List<String> initialTags,
    required List<String> knownTags,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TagEditorSheet(initialTags: initialTags, knownTags: knownTags),
    );
  }

  @override
  State<TagEditorSheet> createState() => _TagEditorSheetState();
}

class _TagEditorSheetState extends State<TagEditorSheet> {
  late final List<String> _tags = [...widget.initialTags];
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _has(String tag) =>
      _tags.any((t) => t.toLowerCase() == tag.trim().toLowerCase());

  void _add(String raw) {
    final tag = raw.trim();
    if (tag.isEmpty || _has(tag)) {
      _controller.clear();
      return;
    }
    setState(() {
      _tags.add(tag[0].toUpperCase() + tag.substring(1));
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = <String>{
      ...widget.knownTags,
      ...TagEditorSheet.suggestedTags,
    }.where((t) => !_has(t)).toList();

    return Padding(
      // Deja sitio al teclado: el campo de texto está al fondo de la hoja.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Spacing.xl, 0, Spacing.xl, Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Etiquetas', style: theme.textTheme.headlineSmall),
              const SizedBox(height: Spacing.lg),
              if (_tags.isEmpty)
                Text(
                  'Sin etiquetas todavía.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: [
                    for (final tag in _tags)
                      RemovableChip(
                        label: tag,
                        onRemove: () => setState(() => _tags.remove(tag)),
                      ),
                  ],
                ),
              const SizedBox(height: Spacing.lg),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Nueva etiqueta...',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                      ),
                      onSubmitted: _add,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  IconButton.filledTonal(
                    onPressed: () => _add(_controller.text),
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Añadir etiqueta',
                  ),
                ],
              ),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: Spacing.lg),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
                  children: [
                    for (final tag in suggestions)
                      ActionChip(
                        avatar: const Icon(Icons.add_rounded, size: 18),
                        label: Text(tag),
                        onPressed: () => _add(tag),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: Spacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    // Lo escrito sin pulsar "+" también cuenta.
                    if (_controller.text.trim().isNotEmpty) _add(_controller.text);
                    Navigator.pop(context, _tags);
                  },
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
