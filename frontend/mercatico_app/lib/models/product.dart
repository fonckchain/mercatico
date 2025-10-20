/// Modelo de producto
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final bool showStock;
  final bool acceptsCash;
  final String? imageUrl;
  final String category;
  final String sellerId;
  final String sellerName;
  final bool isActive;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.showStock = false,
    this.acceptsCash = true,
    this.imageUrl,
    required this.category,
    required this.sellerId,
    required this.sellerName,
    required this.isActive,
    required this.createdAt,
  });

  /// Crear producto desde JSON del API
  factory Product.fromJson(Map<String, dynamic> json) {
    // Parsear precio - puede venir como String o num
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: parsePrice(json['price']),
      stock: json['stock'] ?? 0,
      showStock: json['show_stock'] ?? false,
      acceptsCash: json['accepts_cash'] ?? true,
      imageUrl: json['image_url'],
      category: json['category'] ?? '',
      sellerId: json['seller'] ?? '',
      sellerName: json['seller_name'] ?? 'Vendedor',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'show_stock': showStock,
      'accepts_cash': acceptsCash,
      'image_url': imageUrl,
      'category': category,
      'seller': sellerId,
      'is_active': isActive,
    };
  }

  /// Precio formateado con símbolo de colones
  String get formattedPrice => '₡${price.toStringAsFixed(2)}';

  /// Verificar si hay stock disponible
  bool get hasStock => stock > 0;
}
