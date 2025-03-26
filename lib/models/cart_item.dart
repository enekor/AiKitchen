class CartItem {
  String name;
  bool isIn;

  CartItem({required this.name, required this.isIn});

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(name: json['name'], isIn: json['isIn']);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'isIn': isIn};
  }
}
