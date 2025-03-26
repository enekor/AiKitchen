import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/widgets/floating_actions.dart';
import 'package:aikitchen/widgets/neumorphic_card.dart';
import 'package:aikitchen/widgets/neumorphic_switch.dart';
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
    _shoppingList = await JsonDocumentsService.getCartItems();
    setState(() {});
  }

  void _toggleShoppingListStatus(int index) {
    setState(() {
      _shoppingList[index].isIn = !_shoppingList[index].isIn;
    });
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
      appBar: AppBar(
        title: ModularFloatingActions(
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
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_adding)
              NeumorphicCard(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newIngredient,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          labelText: null,
                          hintText: 'Patatas',
                        ),
                      ),
                    ),
                    NeumorphicIconButton(
                      context,
                      NeumorphicActionButton(
                        onPressed: () => _addNewIngredient(_newIngredient.text),
                        icon: Icons.add_rounded,
                      ),
                    ),
                  ],
                ),
              ),
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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                    offset: const Offset(-4, -4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
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
          trailing: NeumorphicSwitch(
            value: item.isIn,
            onChanged: (value) => _toggleShoppingListStatus(realIndex),
            activeColor: theme.colorScheme.primary,
            inactiveColor: theme.colorScheme.secondary.withOpacity(0.5),
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
