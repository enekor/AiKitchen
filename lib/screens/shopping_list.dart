import 'package:aikitchen/models/cart_item.dart';
import 'package:aikitchen/models/prompt.dart';
import 'package:aikitchen/services/json_documents.dart';
import 'package:aikitchen/singleton/app_singleton.dart';
import 'package:aikitchen/widgets/floating_actions.dart';
import 'package:aikitchen/widgets/neumorphic_card.dart';
import 'package:aikitchen/widgets/text_input.dart';
import 'package:aikitchen/widgets/toaster.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class ShoppingList extends StatefulWidget {
  const ShoppingList({super.key});

  @override
  _ShoppingListState createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  List<CartItem> _shoppingList = [];
  List<String> _generatedShoppingList = [];
  bool _showAvailable = true;
  bool _adding = false;
  bool _showAIShoppingList = false;
  bool _showAIShoppingListLoading = false;
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

  Future<void> _updateShoppingList() async {
    await JsonDocumentsService().setCartItems(_shoppingList);
    setState(() {});
  }

  void _addNewIngredient(String name) {
    setState(() {
      _shoppingList.add(CartItem(name: name, isIn: _showAvailable));
      _newIngredient.clear();
    });
    _updateShoppingList();
  }

  void _generateShoppingList(String userInfo) async {
    setState(() {
      _showAIShoppingListLoading = true;
    });

    String prompt = Prompt.shoppingListPrompt(
      userInfo,
      AppSingleton().tipoReceta,
    );

    String response = await AppSingleton().generateContent(prompt, context);

    if (response.isEmpty || response.contains('error')) {
      setState(() {
        _showAIShoppingListLoading = false;
      });
      Toaster.showError(
        "Error al generar la lista de la compra: ${response.split(":")[1]}",
      );
      return;
    } else {
      _generatedShoppingList = response.split(',');

      setState(() {
        _showAIShoppingListLoading = false;
      });
    }
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
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.secondary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.shopping_cart,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Lista de la compra',
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadShoppingList(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ModularFloatingActions(
                actions: [
                  NeumorphicActionButton(
                    icon: Icons.kitchen,
                    isHighlighted: _showAvailable == true,
                    onPressed: () {
                      setState(() {
                        _showAvailable = true;
                        _showAIShoppingList = false;
                      });
                    },
                  ),
                  NeumorphicActionButton(
                    icon: Icons.shopping_basket_outlined,
                    onPressed: () {
                      setState(() {
                        _showAvailable = false;
                        _showAIShoppingList = false;
                      });
                    },
                    isHighlighted: _showAvailable == false,
                  ),
                  NeumorphicActionButton(
                    icon: Icons.add_shopping_cart,
                    onPressed:
                        () => setState(() {
                          _adding = !_adding;
                        }),
                  ),
                  NeumorphicActionButton(
                    icon: Icons.auto_awesome,
                    onPressed:
                        () => setState(() {
                          _showAIShoppingList = true;
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
              if (_showAIShoppingList)
                _generateAIShoppingList()
              else
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
            icon: item.isIn ? const Icon(Icons.close) : const Icon(Icons.check),
            onPressed: () async {
              setState(() {
                item.isIn = !item.isIn;
              });
              await _updateShoppingList();
            },
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _generateAIShoppingList() {
    String userInfo = '';
    return Expanded(
      child: NeumorphicCard(
        padding: EdgeInsets.symmetric(horizontal: 20),
        withInnerShadow: false,
        child: Center(
          child:
              _showAIShoppingListLoading
                  ? Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          "Generando lista de la compra...",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  )
                  : _generatedShoppingList.isNotEmpty
                  ? Stack(
                    children: [
                      ListView.builder(
                        itemCount: _generatedShoppingList.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 12,
                            ),
                            child: Text(
                              _generatedShoppingList[index],
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.replay_circle_filled_rounded),
                          onPressed: () {
                            setState(() {
                              _generatedShoppingList = [];
                              userInfo = '';
                            });
                            Toaster.showWarning(
                              "Reiniciando lista de la compra...",
                            );
                          },
                        ),
                      ),
                    ],
                  )
                  : Column(
                    children: [
                      Expanded(
                        child: BasicMultilineTextInput(
                          isInnerShadow: true,
                          hint:
                              '''¡Hola! ¿Podrías indicar que puedes necesitar para el mes? Tambien puedes incluir el presupuesto mensual que tienes disponible, cuantas personas sois en casa, si hay algun amigo peludo... Lo que sea, trabajo mejor cuanta mas información me das. 'Ejemplo: "Somos 4 personas en casa, tengo un presupuesto de 1000 euros al mes. Para hacerte la lista de la compra tendre en cuenta el tipo de recetas que generas en la aplicación, puedes cambiar esto en ajustes o decirme expresamente que no quieres usar el tipo de recetas que está especificado''',
                          onChanged: (info) => userInfo = info,
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _generateShoppingList(userInfo),
                        icon: const Icon(Icons.checklist_sharp),
                        label: const Text("Generar lista de la compra"),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
