import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:flutter/material.dart';

/// Estado de marcado de una lista de ingredientes, compartido entre la lista
/// y cualquier cabecera externa que quiera mostrar un contador o un botón de
/// "desmarcar todos" (como hace la cabecera de la pantalla de receta).
///
/// El marcado es efímero a propósito: vive solo en este controlador y se
/// pierde al salir. Persistirlo exigiría una tabla por receta y no aporta lo
/// suficiente para el coste.
class IngredientsController extends ChangeNotifier {
  IngredientsController(this.total);

  final int total;
  final Set<int> _marked = {};

  int get markedCount => _marked.length;

  bool isMarked(int index) => _marked.contains(index);

  void toggle(int index) {
    if (!_marked.remove(index)) _marked.add(index);
    notifyListeners();
  }

  void clearAll() {
    if (_marked.isEmpty) return;
    _marked.clear();
    notifyListeners();
  }
}

/// Lista de ingredientes con casilla para marcar mientras se cocina.
class IngredientsList extends StatefulWidget {
  const IngredientsList({super.key, required this.ingredients, this.controller});

  final List<String> ingredients;

  /// Si no se da uno, la lista crea el suyo propio. Se expone para que la
  /// cabecera de la pantalla de receta pueda mostrar el contador y el botón
  /// de desmarcar todos sin duplicar el estado.
  final IngredientsController? controller;

  @override
  State<IngredientsList> createState() => _IngredientsListState();
}

class _IngredientsListState extends State<IngredientsList> {
  late final IngredientsController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? IngredientsController(widget.ingredients.length);
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < widget.ingredients.length; i++) ...[
          if (i > 0) const SizedBox(height: Spacing.sm),
          _IngredientRow(
            text: widget.ingredients[i],
            marked: _controller.isMarked(i),
            onTap: () => _controller.toggle(i),
          ),
        ],
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.text,
    required this.marked,
    required this.onTap,
  });

  final String text;
  final bool marked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: AppRadius.medium,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.medium,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Checkbox(value: marked, onChanged: (_) => onTap()),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    decoration: marked ? TextDecoration.lineThrough : null,
                    color: marked
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
