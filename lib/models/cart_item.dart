/// Pasillo de la tienda para agrupar la lista de la compra. Lo asigna la IA al
/// generar la lista; los artículos añadidos a mano y los guardados antes de
/// este campo quedan sin categoría y se agrupan bajo "Otros".
enum CartCategory {
  frutasVerduras,
  carnesPescados,
  lacteosHuevos,
  despensa,
  congelados,
  bebidas,
  otros;

  static CartCategory? fromName(String? name) {
    if (name == null) return null;
    return CartCategory.values.where((c) => c.name == name).firstOrNull;
  }

  String get displayName {
    switch (this) {
      case CartCategory.frutasVerduras:
        return 'Frutas y verduras';
      case CartCategory.carnesPescados:
        return 'Carnes y pescados';
      case CartCategory.lacteosHuevos:
        return 'Lácteos y huevos';
      case CartCategory.despensa:
        return 'Despensa';
      case CartCategory.congelados:
        return 'Congelados';
      case CartCategory.bebidas:
        return 'Bebidas';
      case CartCategory.otros:
        return 'Otros';
    }
  }
}

class CartItem {
  int? id;
  String name;
  bool isPurchased;
  CartCategory? categoria;

  CartItem({
    this.id,
    required this.name,
    this.isPurchased = false,
    this.categoria,
  });

  /// Categoría a efectos de agrupar, con los artículos sin clasificar cayendo
  /// en "Otros".
  CartCategory get categoriaEfectiva => categoria ?? CartCategory.otros;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      isPurchased: json['isPurchased'] ?? false,
      categoria: CartCategory.fromName(json['categoria'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'isPurchased': isPurchased,
      if (categoria != null) 'categoria': categoria!.name,
    };
  }

  // Compatibilidad con SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isPurchased': isPurchased ? 1 : 0,
      'categoria': categoria?.name,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      name: map['name'],
      isPurchased: map['isPurchased'] == 1,
      // Columna añadida en la versión 3 de la base de datos: puede faltar en
      // filas migradas de una versión anterior.
      categoria: CartCategory.fromName(map['categoria'] as String?),
    );
  }
}
