import 'dart:convert';
import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/services/json_documents.dart';
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

  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }

  Future<void> _loadShoppingList() async {
    _shoppingList = await JsonDocumentsService().getCartItems();
    setState(() {});
  }

  Future<void> _updateShoppingList() async {
    await JsonDocumentsService().setCartItems(_shoppingList);
  }

  void _addItem(String name) {
    if (name.trim().isEmpty) return;

    setState(() {
      _shoppingList.add(CartItem(name: name.trim()));
    });
    _updateShoppingList();
    _itemController.clear();
  }

  void _togglePurchased(int index) {
    setState(() {
      _shoppingList[index].isPurchased = !_shoppingList[index].isPurchased;
    });
    _updateShoppingList();
  }

  void _removeItem(int index) {
    setState(() {
      _shoppingList.removeAt(index);
    });
    _updateShoppingList();
  }

  void _clearCompleted() {
    setState(() {
      _shoppingList.removeWhere((item) => item.isPurchased);
    });
    _updateShoppingList();
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
    // Remove markdown code blocks if present
    response = response.replaceAll(RegExp(r'```json\s*'), '');
    response = response.replaceAll(RegExp(r'\s*```'), '');
    response = response.trim();
    return response;
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
        final items =
            (jsonData['lista'] as List)
                .map((item) => CartItem(name: item.toString()))
                .toList();

        setState(() {
          _shoppingList.addAll(items);
        });

        await _updateShoppingList();
        Navigator.pop(context);
        Toaster.showSuccess('Lista generada con ${items.length} artículos');
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
    final pendingItems =
        _shoppingList.where((item) => !item.isPurchased).toList();
    final completedItems =
        _shoppingList.where((item) => item.isPurchased).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.shopping_cart,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Lista de la compra',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          if (completedItems.isNotEmpty)
            IconButton(
              onPressed: _clearCompleted,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Limpiar completados',
            ),
        ],
      ),
      body: Column(
        children: [
          // Campo para añadir elementos
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: InputDecoration(
                      hintText: 'Añadir artículo...',
                      prefixIcon: Icon(
                        Icons.add_shopping_cart,
                        color: theme.colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    onSubmitted: _addItem,
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  onPressed: () => _addItem(_itemController.text),
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                  heroTag: 'add-shopping-item',
                ),
              ],
            ),
          ),

          // Estadísticas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${pendingItems.length}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Pendientes',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${completedItems.length}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Completados',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Lista de artículos
          Expanded(
            child:
                _shoppingList.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 80,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Lista vacía',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Añade artículos o genera una lista con IA',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _shoppingList.length,
                      itemBuilder: (context, index) {
                        final item = _shoppingList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color:
                                item.isPurchased
                                    ? theme.colorScheme.secondary.withOpacity(
                                      0.1,
                                    )
                                    : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  item.isPurchased
                                      ? theme.colorScheme.secondary.withOpacity(
                                        0.3,
                                      )
                                      : theme.colorScheme.outline.withOpacity(
                                        0.3,
                                      ),
                            ),
                          ),
                          child: ListTile(
                            leading: Checkbox(
                              value: item.isPurchased,
                              onChanged: (_) => _togglePurchased(index),
                            ),
                            title: Text(
                              item.name,
                              style: TextStyle(
                                decoration:
                                    item.isPurchased
                                        ? TextDecoration.lineThrough
                                        : null,
                                color:
                                    item.isPurchased
                                        ? theme.colorScheme.outline
                                        : theme.colorScheme.onSurface,
                              ),
                            ),
                            trailing: IconButton(
                              onPressed: () => _removeItem(index),
                              icon: Icon(
                                Icons.delete_outline,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAIGeneratorModal,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Generar con IA'),
        heroTag: 'generate-shopping-list',
      ),
    );
  }

  Widget _buildAIGeneratorModal() {
    final theme = Theme.of(context);
    final personasController = TextEditingController();
    final presupuestoIniController = TextEditingController();
    final presupuestoFinController = TextEditingController();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Generar lista con IA',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(),

          // Form
          Expanded(
            child:
                _isGenerating
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Generando lista de la compra...',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cuéntanos sobre tu hogar',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Número de personas
                          TextField(
                            controller: personasController,
                            decoration: InputDecoration(
                              labelText: 'Número de personas',
                              hintText: 'Ej: 4',
                              prefixIcon: const Icon(Icons.people),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),

                          // Presupuesto
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: presupuestoIniController,
                                  decoration: InputDecoration(
                                    labelText: 'Presupuesto min.',
                                    hintText: '200',
                                    prefixIcon: const Icon(Icons.euro),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Text(
                                  '-',
                                  style: theme.textTheme.headlineSmall,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: presupuestoFinController,
                                  decoration: InputDecoration(
                                    labelText: 'Presupuesto max.',
                                    hintText: '300',
                                    prefixIcon: const Icon(Icons.euro),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Info sobre tipo de recetas
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Se tendrá en cuenta el tipo de cocina configurado: ${AppSingleton().tipoReceta}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
          ),

          // Generate button
          if (!_isGenerating)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final formData = {
                      'personas': personasController.text,
                      'presupuesto':
                          '${presupuestoIniController.text} - ${presupuestoFinController.text}',
                    };
                    _generateShoppingListWithAI(formData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text(
                    'Generar lista de la compra',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
