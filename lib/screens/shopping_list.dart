import 'dart:convert';

import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/widget_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/theme/cooking_theme.dart';
import 'package:aikitchen/widgets/content_shell.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:aikitchen/widgets/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Acciones poco frecuentes de la lista. Viven en el menú de la barra superior
/// para que la lista empiece lo más arriba posible.
enum _ListAction { fromWeeklyMenu, monthlyWithAi, share, clearCompleted }

/// Destino "Lista de la compra" del armazón de navegación.
class ShoppingList extends StatefulWidget {
  const ShoppingList({super.key});

  @override
  State<ShoppingList> createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  List<CartItem> _items = [];
  bool _isGenerating = false;
  CartCategory? _filter;
  final TextEditingController _itemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await JsonDocumentsService().getCartItems();
    if (mounted) setState(() => _items = items);
  }

  Future<void> _addItem(String name) async {
    if (name.trim().isEmpty) return;
    await JsonDocumentsService().addCartItem(CartItem(name: name.trim()));
    _itemController.clear();
    await WidgetService.updateShoppingListWidget();
    await _load();
  }

  Future<void> _togglePurchased(CartItem item) async {
    item.isPurchased = !item.isPurchased;
    await JsonDocumentsService().updateCartItem(item);
    await WidgetService.updateShoppingListWidget();
    await _load();
  }

  Future<void> _removeItem(CartItem item) async {
    if (item.id == null) return;

    // La fila sale de la lista en el mismo fotograma en que se desliza:
    // esperar a que responda la base de datos deja un `Dismissible` ya
    // descartado dentro del árbol, y eso salta como aserto.
    setState(() => _items = _items.where((i) => i.id != item.id).toList());

    await JsonDocumentsService().removeCartItem(item.id!);
    await WidgetService.updateShoppingListWidget();
    Toaster.showSuccess('"${item.name}" eliminado');
  }

  Future<void> _clearCompleted() async {
    final completed = _items.where((i) => i.isPurchased).toList();
    for (final item in completed) {
      if (item.id != null) await JsonDocumentsService().removeCartItem(item.id!);
    }
    await WidgetService.updateShoppingListWidget();
    await _load();
  }

  void _shareList() {
    final pending = _items.where((i) => !i.isPurchased).toList();
    if (pending.isEmpty) {
      Toaster.showWarning('No hay artículos pendientes que compartir');
      return;
    }
    final text = pending.map((i) => '- ${i.name}').join('\n');
    SharePlus.instance.share(
      ShareParams(
        text: 'Lista de la compra:\n$text',
        subject: 'Lista de la compra',
      ),
    );
  }

  String _cleanJsonResponse(String response) {
    return response
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'\s*```'), '')
        .trim();
  }

  List<CartItem> _parseCategorizedList(String response) {
    final jsonData = jsonDecode(_cleanJsonResponse(response));
    final lista = jsonData['lista'];
    if (lista is! List) return [];
    return lista
        .map((e) {
          if (e is Map) {
            return CartItem(
              name: (e['nombre'] ?? '').toString(),
              categoria: CartCategory.fromName(e['categoria']?.toString()),
            );
          }
          return CartItem(name: e.toString());
        })
        .where((item) => item.name.isNotEmpty)
        .toList();
  }

  Future<void> _generateMonthlyList() async {
    setState(() => _isGenerating = true);
    try {
      final prompt = Prompt.shoppingListPrompt(
        tipoReceta: AppSingleton().tipoReceta,
        personas: '2',
      );
      final response = await AppSingleton().generateContent(prompt, context);
      final items = _parseCategorizedList(response);
      await JsonDocumentsService().addCategorizedCartItems(items);
      await WidgetService.updateShoppingListWidget();
      await _load();
      Toaster.showSuccess('Lista generada con ${items.length} artículos');
    } catch (e) {
      Toaster.showError('Error al generar la lista: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateFromWeeklyMenu() async {
    final menu = await JsonDocumentsService().loadWeeklyMenu();
    final ingredientes = <String>{};
    for (final recetas in menu.values) {
      for (final receta in recetas) {
        ingredientes.addAll(receta.ingredientes);
      }
    }
    if (ingredientes.isEmpty) {
      Toaster.showWarning('No hay un menú semanal generado todavía');
      return;
    }

    // El menú se ha leído de forma asíncrona antes de esto: comprobamos que la
    // pantalla siga viva antes de usar el contexto.
    if (!mounted) return;

    setState(() => _isGenerating = true);
    try {
      final response = await AppSingleton().generateContent(
        Prompt.categorizeIngredientsPrompt(ingredientes.toList()),
        context,
      );
      final items = _parseCategorizedList(response);
      await JsonDocumentsService().addCategorizedCartItems(items);
      await WidgetService.updateShoppingListWidget();
      await _load();
      Toaster.showSuccess('${items.length} ingredientes añadidos desde el menú');
    } catch (e) {
      Toaster.showError('Error al exportar el menú: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _runAction(_ListAction action) {
    switch (action) {
      case _ListAction.fromWeeklyMenu:
        _generateFromWeeklyMenu();
        break;
      case _ListAction.monthlyWithAi:
        _generateMonthlyList();
        break;
      case _ListAction.share:
        _shareList();
        break;
      case _ListAction.clearCompleted:
        _clearCompleted();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _items.where((i) => !i.isPurchased).toList();
    final completed = _items.where((i) => i.isPurchased).toList();

    final categories = pending.map((i) => i.categoriaEfectiva).toSet();
    // Con una sola categoría los filtros no filtran nada: solo roban altura.
    final showFilters = categories.length > 1;
    final filter = showFilters ? _filter : null;

    final visiblePending = filter == null
        ? pending
        : pending.where((i) => i.categoriaEfectiva == filter).toList();

    final byCategory = <CartCategory, List<CartItem>>{};
    for (final item in visiblePending) {
      byCategory.putIfAbsent(item.categoriaEfectiva, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de la compra'),
        actions: [
          if (_isGenerating)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          PopupMenuButton<_ListAction>(
            onSelected: _runAction,
            tooltip: 'Más acciones',
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ListAction.fromWeeklyMenu,
                enabled: !_isGenerating,
                child: const _MenuRow(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Generar desde el menú semanal',
                ),
              ),
              PopupMenuItem(
                value: _ListAction.monthlyWithAi,
                enabled: !_isGenerating,
                child: const _MenuRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Generar lista mensual con IA',
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: _ListAction.share,
                enabled: pending.isNotEmpty,
                child: const _MenuRow(
                  icon: Icons.share_outlined,
                  label: 'Compartir lista',
                ),
              ),
              PopupMenuItem(
                value: _ListAction.clearCompleted,
                enabled: completed.isNotEmpty,
                child: const _MenuRow(
                  icon: Icons.delete_sweep_outlined,
                  label: 'Vaciar comprados',
                ),
              ),
            ],
          ),
        ],
      ),
      body: ContentShell.wide(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Añadir a mano es la acción más frecuente, así que va arriba y se
            // queda fija mientras la lista se desplaza.
            Padding(
              padding: const EdgeInsets.only(top: Spacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _itemController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        hintText: 'Añadir artículo...',
                        prefixIcon: Icon(Icons.add_shopping_cart_outlined),
                      ),
                      onSubmitted: _addItem,
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  IconButton.filledTonal(
                    onPressed: () => _addItem(_itemController.text),
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Añadir',
                  ),
                ],
              ),
            ),
            if (_items.isNotEmpty) ...[
              const SizedBox(height: Spacing.md),
              _ProgressLine(
                purchased: completed.length,
                total: _items.length,
              ),
            ],
            if (showFilters) ...[
              const SizedBox(height: Spacing.md),
              FilterChipBar<CartCategory?>(
                options: [null, ...CartCategory.values.where(categories.contains)],
                labelOf: (c) => c?.displayName ?? 'Todas',
                selected: _filter,
                onChanged: (c) => setState(() => _filter = c),
              ),
            ],
            const SizedBox(height: Spacing.md),
            Expanded(
              child: _items.isEmpty
                  ? _EmptyList(
                      isGenerating: _isGenerating,
                      onFromWeeklyMenu: _generateFromWeeklyMenu,
                      onMonthly: _generateMonthlyList,
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: Spacing.xl),
                      children: [
                        for (final category in byCategory.keys) ...[
                          SectionHeader(title: category.displayName),
                          const SizedBox(height: Spacing.sm),
                          for (final item in byCategory[category]!) ...[
                            _ShoppingRow(
                              item: item,
                              onToggle: () => _togglePurchased(item),
                              onDelete: () => _removeItem(item),
                            ),
                            const SizedBox(height: Spacing.sm),
                          ],
                          const SizedBox(height: Spacing.md),
                        ],
                        if (completed.isNotEmpty)
                          _CompletedSection(
                            items: completed,
                            onToggle: _togglePurchased,
                            onDelete: _removeItem,
                            onClear: _clearCompleted,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: Spacing.md),
        Text(label),
      ],
    );
  }
}

/// Sustituye a las dos tarjetas de recuento: el mismo dato en una línea.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.purchased, required this.total});

  final int purchased;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$purchased de $total comprados',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        ClipRRect(
          borderRadius: AppRadius.small,
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : purchased / total,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

/// Los generadores con IA solo aparecen como botones grandes aquí, que es
/// donde toca descubrirlos; con la lista llena viven en el menú de la barra.
class _EmptyList extends StatelessWidget {
  const _EmptyList({
    required this.isGenerating,
    required this.onFromWeeklyMenu,
    required this.onMonthly,
  });

  final bool isGenerating;
  final VoidCallback onFromWeeklyMenu;
  final VoidCallback onMonthly;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const EmptyState(
            icon: Icons.shopping_cart_outlined,
            title: 'Lista vacía',
            description: 'Añade artículos arriba o genera una lista con IA.',
          ),
          AiButton(
            label: isGenerating ? 'Generando...' : 'Generar desde el menú semanal',
            expand: true,
            loading: isGenerating,
            onPressed: onFromWeeklyMenu,
          ),
          const SizedBox(height: Spacing.sm),
          OutlinedButton.icon(
            onPressed: isGenerating ? null : onMonthly,
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Generar lista mensual con IA'),
          ),
        ],
      ),
    );
  }
}

class _ShoppingRow extends StatelessWidget {
  const _ShoppingRow({
    required this.item,
    required this.onToggle,
    required this.onDelete,
  });

  final CartItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final row = AppCard(
      onTap: onToggle,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.md,
      ),
      child: Row(
        children: [
          Icon(
            item.isPurchased
                ? Icons.check_box_rounded
                : Icons.check_box_outline_blank_rounded,
            color: item.isPurchased
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              item.name,
              style: theme.textTheme.bodyLarge?.copyWith(
                decoration: item.isPurchased
                    ? TextDecoration.lineThrough
                    : null,
                color: item.isPurchased
                    ? theme.colorScheme.onSurfaceVariant
                    : null,
              ),
            ),
          ),
        ],
      ),
    );

    // Sin `id` no se puede borrar en el almacén, así que tampoco se ofrece el
    // gesto.
    if (item.id == null) return row;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: AppRadius.medium,
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      child: row,
    );
  }
}

class _CompletedSection extends StatefulWidget {
  const _CompletedSection({
    required this.items,
    required this.onToggle,
    required this.onDelete,
    required this.onClear,
  });

  final List<CartItem> items;
  final ValueChanged<CartItem> onToggle;
  final ValueChanged<CartItem> onDelete;
  final VoidCallback onClear;

  @override
  State<_CompletedSection> createState() => _CompletedSectionState();
}

class _CompletedSectionState extends State<_CompletedSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(
                _expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                'Comprados (${widget.items.length})',
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onClear,
                child: const Text('Vaciar'),
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: Spacing.sm),
          for (final item in widget.items) ...[
            _ShoppingRow(
              item: item,
              onToggle: () => widget.onToggle(item),
              onDelete: () => widget.onDelete(item),
            ),
            const SizedBox(height: Spacing.sm),
          ],
        ],
      ],
    );
  }
}
