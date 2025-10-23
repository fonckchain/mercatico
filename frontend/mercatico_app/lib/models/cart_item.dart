import 'product.dart';

/// Modelo para un item en el carrito de compras
class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  /// Precio total del item (precio unitario × cantidad)
  double get totalPrice => product.price * quantity;

  /// Precio total formateado
  String get formattedTotalPrice => '₡${totalPrice.toStringAsFixed(2)}';

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'product_id': product.id,
      'quantity': quantity,
    };
  }

  /// Crear desde JSON (requiere el producto completo)
  factory CartItem.fromJson(Map<String, dynamic> json, Product product) {
    return CartItem(
      product: product,
      quantity: json['quantity'] ?? 1,
    );
  }
}
