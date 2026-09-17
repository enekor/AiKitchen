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
    await JsonDocumentsService().removeCartItem(item.id!);
    await WidgetService.updateShoppingListWidget();
    await _load();
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
      ShareParams(text: 'Lista de la compra:\n$text', subject: 'Lista de la compra'),
    );
  }

  String _cleanJsonResponse(String response) {
    return response.replaceAll(RegExp(r'```json\s*'), '').replaceAll(RegExp(r'\s*```'), '').trim();
  }

  List<CartItem> _parseCategorizedList(String response) {
    final jsonData = jsonDecode(_cleanJsonResponse(response));
    final lista = jsonData['lista'];
    if (lista is! List) return [];
    return lista.map((e) {
      if (e is Map) {
        return CartItem(
          name: (e['nombre'] ?? '').toString(),
          categoria: CartCategory.fromName(e['categoria']?.toString()),
        );
      }
      return CartItem(name: e.toString());
    }).where((item) => item.name.isNotEmpty).toList();
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

  @override
  Widget build(BuildContext context) {
    final pending = _items.where((i) => !i.isPurchased).toList();
    final completed = _items.where((i) => i.isPurchased).toList();

    final visiblePending = _filter == null
        ? pending
        : pending.where((i) => i.categoriaEfectiva == _filter).toList();

    final byCategory = <CartCategory, List<CartItem>>{};
    for (final item in visiblePending) {
      byCategory.putIfAbsent(item.categoriaEfectiva, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lista de la compra')),
      body: ContentShell.wide(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              child: Row(
                children: [
                  Expanded(child: _StatCard(count: pending.length, label: 'Pendientes')),
                  const SizedBox(width: Spacing.md),
                  Expanded(child: _StatCard(count: completed.length, label: 'Comprados')),
                ],
              ),
            ),
            AiButton(
              label: _isGenerating ? 'Generando...' : 'Generar desde el menú semanal',
              expand: true,
              loading: _isGenerating,
              onPressed: _generateFromWeeklyMenu,
            ),
            const SizedBox(height: Spacing.sm),
            OutlinedButton.icon(
              onPressed: _isGenerating ? null : _generateMonthlyList,
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Generar lista mensual con IA'),
            ),
            const SizedBox(height: Spacing.lg),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
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
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            FilterChipBar<CartCategory?>(
              options: [null, ...CartCategory.values],
              labelOf: (c) => c?.displayName ?? 'Todas',
              selected: _filter,
              onChanged: (c) => setState(() => _filter = c),
            ),
            const SizedBox(height: Spacing.md),
            Expanded(
              child: _items.isEmpty
                  ? const EmptyState(
                      icon: Icons.shopping_cart_outlined,
                      title: 'Lista vacía',
                      description: 'Añade artículos o genera una lista con IA.',
                    )
                  : ListView(
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
                            onClear: _clearCompleted,
                          ),
                      ],
                    ),
            ),
            if (_items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                child: OutlinedButton.icon(
                  onPressed: _shareList,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Compartir lista'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        children: [
          Text(count.toString(), style: theme.textTheme.headlineMedium),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShoppingRow extends StatelessWidget {
  const _ShoppingRow({required this.item, required this.onToggle, this.onDelete});

  final CartItem item;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
      child: Row(
        children: [
          Checkbox(value: item.isPurchased, onChanged: (_) => onToggle()),
          Expanded(
            child: Text(
              item.name,
              style: theme.textTheme.bodyLarge?.copyWith(
                decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                color: item.isPurchased ? theme.colorScheme.onSurfaceVariant : null,
              ),
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Eliminar',
            ),
        ],
      ),
    );
  }
}

class _CompletedSection extends StatefulWidget {
  const _CompletedSection({required this.items, required this.onToggle, required this.onClear});

  final List<CartItem> items;
  final ValueChanged<CartItem> onToggle;
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
              Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded),
              const SizedBox(width: Spacing.sm),
              Text('Comprados (${widget.items.length})', style: theme.textTheme.titleMedium),
              const Spacer(),
              TextButton(onPressed: widget.onClear, child: const Text('Vaciar')),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: Spacing.sm),
          for (final item in widget.items) ...[
            _ShoppingRow(item: item, onToggle: () => widget.onToggle(item)),
            const SizedBox(height: Spacing.sm),
          ],
        ],
      ],
    );
  }
}
