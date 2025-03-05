import 'package:flutter/material.dart';

class nameInputPart extends StatefulWidget {
  nameInputPart({super.key, required this.onSearch, required this.onFav});
  Function(String) onSearch;
  Function onFav;
  @override
  State<nameInputPart> createState() => _nameInputPartState();
}

class _nameInputPartState extends State<nameInputPart> {
  TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    bool _isFav = false;
    return Card(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la receta',
                hintText: 'Ejemplo: Tarta de manzana',
              ),
            ),
          ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                widget.onSearch(_nameController.text);
              },
            ),
            IconButton(
              icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border),
              onPressed: () {
                setState(() {
                  _isFav = !_isFav;
                });
                widget.onFav();
              },
          )
            
        ],
      
      ),
    );
  }
}