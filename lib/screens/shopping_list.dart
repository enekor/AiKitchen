import 'dart:convert';
import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/services/widget_service.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';

class ShoppingList extends StatefulWidget {
  const ShoppingList({super.key});

  @override
  _ShoppingListState createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  List<CartItem> _shoppingList = [];
  bool _isGenerating = false;
  final TextEditingController _itemController = TextEditingController();

  final TextEditingController _personasController = TextEditingController();
  final TextEditingController _presupuestoIniController = TextEditingController();
  final TextEditingController _presupuestoFinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _personasController.dispose();
    _presupuestoIniController.dispose();
    _presupuestoFinController.dispose();
    super.dispose();
  }

  Future<void> _loadShoppingList() async {
    _shoppingList = await JsonDocumentsService().getCartItems();
    setState(() {});
  }

  Future<void> _addItem(String name) async {
    if (name.trim().isEmpty) return;
    await WidgetService.handleWidgetAction('add_shopping_item', {'item_name': name});
    _itemController.clear();
    await _loadShoppingList();
  }

  Future<void> _togglePurchased(int index) async {
    final item = _shoppingList[index];
    await WidgetService.handleWidgetAction('toggle_shopping_item', {'item_name': item.name});
    await _loadShoppingList();
  }

  Future<void> _removeItem(int index) async {
    final item = _shoppingList[index];
    if (item.id != null) {
      await JsonDocumentsService().removeCartItem(item.id!);
      await WidgetService.updateShoppingListWidget();
      await _loadShoppingList();
    }
  }

  Future<void> _clearCompleted() async {
    await WidgetService.handleWidgetAction('clear_completed', {});
    await _loadShoppingList();
  }

  void _showAIGeneratorModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAIGeneratorModal(),
    );
  }

  String _cleanJsonResponse(String response) {
    response = response.replaceAll(RegExp(r'```json\s*'), '');
    response = response.replaceAll(RegExp(r'\s*```'), '');
    return response.trim();
  }

  Future<void> _generateShoppingListWithAI(Map<String, String> formData) async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final prompt = Prompt.shoppingListPrompt(
        tipoReceta: AppSingleton().tipoReceta,
        personas: formData['personas'] ?? '2',
        presupuesto: formData['presupuesto'] ?? '',
      );

      final response = await AppSingleton().generateContent(prompt, context);
      final cleanedResponse = _cleanJsonResponse(response);
      final jsonData = jsonDecode(cleanedResponse);

      if (jsonData['lista'] != null && jsonData['lista'] is List) {
        final List<String> names = (jsonData['lista'] as List).map((e) => e.toString()).toList();
        await JsonDocumentsService().addCartItemsFromNames(names);
        await WidgetService.updateShoppingListWidget();
        await _loadShoppingList();
        Toaster.showSuccess('Lista generada con ${names.length} artículos');
      }
    } catch (e) {
      Toaster.showError('Error al generar la lista: $e');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendingItems = _shoppingList.where((item) => !item.isPurchased).toList();
    final completedItems = _shoppingList.where((item) => item.isPurchased).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildStatCard(theme, '${pendingItems.length}', 'Pendientes', theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 16),
                _buildStatCard(theme, '${completedItems.length}', 'Listos', theme.colorScheme.secondaryContainer, theme.colorScheme.onSecondaryContainer),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Add Item Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.add_shopping_cart_rounded, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _itemController,
                      decoration: const InputDecoration(
                        hintText: 'Añadir artículo...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: _addItem,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => _addItem(_itemController.text),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Items List
          Expanded(
            child: _shoppingList.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _shoppingList.length,
                    itemBuilder: (context, index) {
                      final item = _shoppingList[index];
                      return _buildShoppingItem(theme, item, index);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAIGeneratorModal,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        icon: _isGenerating 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.auto_awesome_rounded),
        label: Text(_isGenerating ? 'GENERANDO...' : 'GENERAR CON IA', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String count, String label, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            Text(count, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: textColor)),
            Text(label, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: textColor.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildShoppingItem(ThemeData theme, CartItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: item.isPurchased 
            ? theme.colorScheme.surfaceVariant.withOpacity(0.2)
            : theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: item.isPurchased ? Colors.transparent : theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Checkbox(
          value: item.isPurchased,
          onChanged: (_) => _togglePurchased(index),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        title: Text(
          item.name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: item.isPurchased ? FontWeight.normal : FontWeight.bold,
            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
            color: item.isPurchased ? theme.colorScheme.onSurface.withOpacity(0.4) : theme.colorScheme.onSurface,
          ),
        ),
        trailing: IconButton(
          onPressed: () => _removeItem(index),
          icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.shopping_bag_rounded, size: 64, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text('¡Lista vacía!', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Añade artículos o usa la IA para generar una.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildAIGeneratorModal() {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: theme.colorScheme.outline.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text('Generar con IA', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _personasController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Número de personas',
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.people_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _presupuestoIniController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'P. Mín (€)',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _presupuestoFinController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'P. Máx (€)',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final formData = {
                    'personas': _personasController.text,
                    'presupuesto': '${_presupuestoIniController.text} - ${_presupuestoFinController.text}',
                  };
                  _generateShoppingListWithAI(formData);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('GENERAR LISTA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
