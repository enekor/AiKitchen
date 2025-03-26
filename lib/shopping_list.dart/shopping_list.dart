import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // Para groupBy

class ShoppingList extends StatefulWidget {
  @override
  _ShoppingListState createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  List<CartItem> _ShoppingList = [];
  bool _showAvailable = true;

  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }

  Future<void> _loadShoppingList() async {
    _ShoppingList = await JsonDocumentsService.getCartItems();
    setState(() {});
  }

  void _toggleShoppingListtatus(int index) {
    setState(() {
      _ShoppingList[index].isIn = !_ShoppingList[index].isIn;
    });
  }

  void _addNewIngredient(String name) {
    setState(() {
      _ShoppingList.add(CartItem(name: name, isIn: false));
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupedShoppingList = groupBy(
      _ShoppingList,
      (item) => item.isIn ? "Tengo" : "Falta",
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mis Ingredientes',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Color(0xFFE0E5EC),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Mostramos solo una sección a la vez basada en _showAvailable
            _buildShoppingListSection(
              title:
                  _showAvailable
                      ? "En mi despensa (${groupedShoppingList["Tengo"]?.length ?? 0})"
                      : "Faltan (${groupedShoppingList["Falta"]?.length ?? 0})",
              shoppingList:
                  _showAvailable
                      ? groupedShoppingList["Tengo"] ?? []
                      : groupedShoppingList["Falta"] ?? [],
              color: _showAvailable ? Colors.green[200] : Colors.orange[200],
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "add_ingredient",
            onPressed: () => _showAddIngredientDialog(context),
            child: Icon(Icons.add),
            backgroundColor: Color(0xFFE0E5EC),
            foregroundColor: Colors.blue,
            elevation: 8,
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "toggle_view",
            onPressed: () {
              setState(() {
                _showAvailable = !_showAvailable;
              });
            },
            child: Icon(
              _showAvailable ? Icons.remove_shopping_cart : Icons.shopping_cart,
            ),
            backgroundColor: Color(0xFFE0E5EC),
            foregroundColor: _showAvailable ? Colors.orange : Colors.green,
            elevation: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingListSection({
    required String title,
    required List<CartItem> shoppingList,
    required Color? color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Color(0xFFE0E5EC),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(-5, -5),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.grey.shade400,
                    offset: Offset(5, 5),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child:
                  shoppingList.isEmpty
                      ? Center(child: Text("No hay ingredientes"))
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
    // Encontramos el índice real en la lista completa
    final realIndex = _ShoppingList.indexWhere((i) => i.name == item.name);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Color(0xFFE0E5EC),
          boxShadow: [
            BoxShadow(
              color: Colors.white,
              offset: Offset(-3, -3),
              blurRadius: 5,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.grey.shade400,
              offset: Offset(3, 3),
              blurRadius: 5,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ListTile(
          title: Text(item.name, style: TextStyle(fontWeight: FontWeight.w500)),
          trailing: Switch(
            value: item.isIn,
            onChanged: (value) => _toggleShoppingListtatus(realIndex),
            activeColor: Colors.green,
            inactiveThumbColor: Colors.orange,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  void _showAddIngredientDialog(BuildContext context) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Color(0xFFE0E5EC),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    labelText: "Nombre del ingrediente",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancelar"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (textController.text.isNotEmpty) {
                          _addNewIngredient(textController.text);
                          Navigator.pop(context);
                        }
                      },
                      child: Text("Añadir"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE0E5EC),
                        foregroundColor: Colors.blue,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
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
