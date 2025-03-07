import 'package:flutter/material.dart';

class nameInputPart extends StatefulWidget {
  nameInputPart({super.key, required this.onSearch, required this.onFav});
  Function(String) onSearch;
  Function onFav;
  @override
  State<nameInputPart> createState() => _nameInputPartState();
}

class _nameInputPartState extends State<nameInputPart> {
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    bool isFav = false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
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
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
                onPressed: () {
                  setState(() {
                    isFav = !isFav;
                  });
                  widget.onFav();
                },
            )
              
          ],
        
        ),
      ),
    );
  }
}