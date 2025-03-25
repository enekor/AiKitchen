import 'package:flutter/material.dart';

class ShoppingList extends StatefulWidget {
  ShoppingList({Key? key}) : super(key: key);

  @override
  _ShoppingListState createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Expanded(child: Center(child: Text('Tu lista de la compra'))),
    );
  }
}
