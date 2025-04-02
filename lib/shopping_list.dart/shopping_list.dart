import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/widgets/floating_actions.dart';
import 'package:aikitchen/widgets/neumorphic_card.dart';
import 'package:aikitchen/widgets/neumorphic_switch.dart';
import 'package:aikitchen/widgets/text_input.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class ShoppingList extends StatefulWidget {
  const ShoppingList({super.key});

  @override
  _ShoppingListState createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  List<CartItem> _shoppingList = [];
  bool _showAvailable = true;
  bool _adding = false;
  final _newIngredient = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }

  Future<void> _loadShoppingList() async {
    _shoppingList = await JsonDocumentsService().getCartItems();
    setState(() {});
  }

  void _addNewIngredient(String name) {
    setState(() {
      _shoppingList.add(CartItem(name: name, isIn: _showAvailable));
      _newIngredient.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupedShoppingList = groupBy(
      _shoppingList,
      (item) => item.isIn ? "Tengo" : "Falta",
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () => _loadShoppingList(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ModularFloatingActions(
                actions: [
                  NeumorphicActionButton(
                    icon: Icons.shopping_cart,
                    isHighlighted: _showAvailable == true,
                    onPressed: () {
                      setState(() {
                        _showAvailable = true;
                      });
                    },
                  ),
                  NeumorphicActionButton(
                    icon: Icons.remove_shopping_cart_rounded,
                    onPressed: () {
                      setState(() {
                        _showAvailable = false;
                      });
                    },
                    isHighlighted: _showAvailable == false,
                  ),
                  NeumorphicActionButton(
                    icon: Icons.add_rounded,
                    onPressed:
                        () => setState(() {
                          _adding = !_adding;
                        }),
                  ),
                ],
              ),
              if (_adding)
                BasicTextInput(
                  onSearch: _addNewIngredient,
                  hint: "Patatas",
                  checkIcon: Icons.add_rounded,
                  padding: EdgeInsets.all(2),
                  isInnerShadow: true,
                ),
              const SizedBox(height: 16),
              _buildShoppingListSection(
                title:
                    _showAvailable
                        ? "En mi despensa (${groupedShoppingList["Tengo"]?.length ?? 0})"
                        : "Faltan (${groupedShoppingList["Falta"]?.length ?? 0})",
                shoppingList:
                    _showAvailable
                        ? groupedShoppingList["Tengo"] ?? []
                        : groupedShoppingList["Falta"] ?? [],
                color:
                    _showAvailable
                        ? theme.colorScheme.primary.withOpacity(0.2)
                        : theme.colorScheme.secondary.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShoppingListSection({
    required String title,
    required List<CartItem> shoppingList,
    required Color? color,
  }) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: NeumorphicCard(
              withInnerShadow: true,
              child:
                  shoppingList.isEmpty
                      ? Center(
                        child: Text(
                          "No hay ingredientes",
                          style: theme.textTheme.bodyLarge,
                        ),
                      )
                      : ListView.builder(
                        itemCount: shoppingList.length,
                        itemBuilder: (context, index) {
                          final item = shoppingList[index];
                          return _buildIngredientCard(item, index);
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientCard(CartItem item, int originalIndex) {
    final theme = Theme.of(context);
    final realIndex = _shoppingList.indexWhere((i) => i.name == item.name);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              offset: const Offset(-3, -3),
              blurRadius: 5,
            ),
            BoxShadow(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              offset: const Offset(3, 3),
              blurRadius: 5,
            ),
          ],
        ),
        child: ListTile(
          title: Text(
            item.name,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: IconButton(
            icon: item.isIn ? Icon(Icons.close) : Icon(Icons.check),
            onPressed:
                () => setState(() {
                  item.isIn = !item.isIn;
                }),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  void _showAddIngredientDialog(BuildContext context) {
    final theme = Theme.of(context);
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Añadir Ingrediente",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    labelText: "Nombre del ingrediente",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancelar",
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (textController.text.isNotEmpty) {
                          _addNewIngredient(textController.text);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Añadir"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
