class CartItem {
  String name;
  bool isPurchased;

  CartItem({required this.name, this.isPurchased = false});

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      name: json['name'],
      isPurchased: json['isPurchased'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'isPurchased': isPurchased};
  }
}
