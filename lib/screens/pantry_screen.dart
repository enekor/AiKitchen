import 'package:aikitchen/services/pantry_service.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/content_shell.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:aikitchen/widgets/ui/ui.dart';
import 'package:flutter/material.dart';

/// Lo que el usuario tiene en casa. Se usa para no añadir a la compra lo que
/// ya hay, para marcarlo en las recetas y para buscar recetas con ello.
class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final TextEditingController _controller = TextEditingController();
  final PantryService _pantry = PantryService.instance;

  /// Básicos que casi todas las cocinas tienen, para llenar la despensa con
  /// pocos toques la primera vez.
  static const _staples = [
    'Aceite de oliva',
    'Sal',
    'Pimienta',
    'Azúcar',
    'Harina',
    'Huevos',
    'Leche',
    'Ajo',
    'Cebolla',
    'Arroz',
    'Pasta',
    'Vinagre',
    'Tomate frito',
    'Pimentón',
    'Caldo',
  ];

  @override
  void initState() {
    super.initState();
    _pantry.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add(String name) async {
    if (name.trim().isEmpty) return;
    final added = await _pantry.add(name);
    _controller.clear();
    if (!added) Toaster.showWarning('"${name.trim()}" ya está en la despensa');
  }

  Future<void> _remove(String name) async {
    await _pantry.remove(name);
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vaciar la despensa'),
        content: const Text('Se quitarán todos los productos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _pantry.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _pantry,
      builder: (context, _) {
        final items = _pantry.items;
        final suggestions = _staples.where((s) => !_pantry.contains(s)).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi despensa'),
            actions: [
              IconButton(
                onPressed: items.isEmpty ? null : _confirmClear,
                tooltip: 'Vaciar la despensa',
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
            ],
          ),
          body: ContentShell.wide(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Añadir producto...',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        onSubmitted: _add,
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    IconButton.filledTonal(
                      onPressed: () => _add(_controller.text),
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'Añadir',
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xl),
                if (items.isEmpty)
                  const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Tu despensa está vacía',
                    description:
                        'Apunta lo que tienes en casa. Las recetas lo marcarán, '
                        'no se añadirá a la lista de la compra y podrás buscar '
                        'recetas con ello.',
                  )
                else ...[
                  SectionHeader(title: 'En casa (${items.length})'),
                  const SizedBox(height: Spacing.md),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      for (final item in items)
                        RemovableChip(label: item, onRemove: () => _remove(item)),
                    ],
                  ),
                ],
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: Spacing.xl),
                  const SectionHeader(title: 'Básicos'),
                  const SizedBox(height: Spacing.md),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      for (final staple in suggestions)
                        ActionChip(
                          avatar: const Icon(Icons.add_rounded, size: 18),
                          label: Text(staple),
                          onPressed: () => _add(staple),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
