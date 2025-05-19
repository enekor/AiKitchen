import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/widgets/neumorphic_card.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';

class IngredientModal extends StatefulWidget {
  const IngredientModal({
    super.key,
    required this.recipe,
    required this.onClickRecipe,
  });
  final Function onClickRecipe;
  final Recipe recipe;

  @override
  State<IngredientModal> createState() => _IngredientModalState();
}

class _IngredientModalState extends State<IngredientModal> {
  bool _isSelectingIngredients = false;
  List<String> _selectedIngredients = [];
  void saveIngredients() async {
    await JsonDocumentsService().updateCartItems(_selectedIngredients);
    Toaster.showToast('Ingredientes guardados en la lista de la compra');
  }

  @override
  Widget build(BuildContext context) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height *
              0.8, // 80% de la altura de la pantalla
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.recipe.nombre,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  infoCard(Icons.access_time, widget.recipe.tiempoEstimado),
                  infoCard(
                    Icons.local_fire_department_rounded,
                    '${widget.recipe.calorias} cal',
                  ),
                  infoCard(Icons.person, '${widget.recipe.raciones} platos'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Ingredientes:',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              !_isSelectingIngredients
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...widget.recipe.ingredientes.map(
                        (ing) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('• $ing', textAlign: TextAlign.start),
                        ),
                      ),
                    ],
                  )
                  : Column(
                    children: [
                      ...widget.recipe.ingredientes.map((ing) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _selectedIngredients.contains(ing),
                                onChanged: (value) {
                                  setState(() {
                                    if (!_selectedIngredients.contains(ing)) {
                                      _selectedIngredients.add(ing);
                                    } else {
                                      _selectedIngredients.remove(ing);
                                    }
                                  });
                                },
                              ),
                              SizedBox(width: 20),
                              GestureDetector(
                                onTap:
                                    () => setState(() {
                                      if (!_selectedIngredients.contains(ing)) {
                                        _selectedIngredients.add(ing);
                                      } else {
                                        _selectedIngredients.remove(ing);
                                      }
                                    }),
                                child: Text(ing),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
              const SizedBox(height: 24),
              _isSelectingIngredients
                  ? Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isSelectingIngredients =
                                  !_isSelectingIngredients;
                            });
                          },
                          child: const Text(
                            "CANCELAR",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(50),
                          ),
                          onPressed: () {
                            setState(() {
                              _isSelectingIngredients =
                                  !_isSelectingIngredients;
                              saveIngredients();
                            });
                          },
                          child: const Text('GUARDAR'),
                        ),
                      ),
                    ],
                  )
                  : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isSelectingIngredients =
                                  !_isSelectingIngredients;
                            });
                          },
                          child: const Text(
                            "GUARDAR INGREDIENTES",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(50),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onClickRecipe();
                          },
                          child: const Text('VER RECETA'),
                        ),
                      ),
                    ],
                  ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

Widget infoCard(IconData icon, String text) {
  return SizedBox(
    width: 100,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ),
  );
}
