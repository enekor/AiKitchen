class CartItem {
  int? id;
  String name;
  bool isPurchased;

  CartItem({this.id, required this.name, this.isPurchased = false});

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      isPurchased: json['isPurchased'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'isPurchased': isPurchased,
    };
  }

  // Compatibilidad con SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isPurchased': isPurchased ? 1 : 0,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      name: map['name'],
      isPurchased: map['isPurchased'] == 1,
    );
  }
}
