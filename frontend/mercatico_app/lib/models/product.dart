import 'seller_info.dart';

/// Modelo de producto
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final bool showStock;
  final bool acceptsCash;
  final bool acceptsSinpe;
  final bool offersPickup;
  final bool offersDelivery;
  final String? imageUrl; // URL de la imagen principal (para compatibilidad)
  final List<String> images; // Lista completa de URLs de imágenes
  final String category;
  final String sellerId;
  final String sellerName;
  final bool isActive;
  final DateTime createdAt;
  final SellerInfo? sellerInfo; // Información completa del vendedor (solo en detalle)
  final double? latitude;
  final double? longitude;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.showStock = false,
    this.acceptsCash = true,
    this.acceptsSinpe = true,
    this.offersPickup = true,
    this.offersDelivery = false,
    this.imageUrl,
    this.images = const [],
    required this.category,
    required this.sellerId,
    required this.sellerName,
    required this.isActive,
    required this.createdAt,
    this.sellerInfo,
    this.latitude,
    this.longitude,
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

    // Parsear lista de imágenes
    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = List<String>.from(json['images']);
    }

    // Para compatibilidad, usar main_image o la primera de la lista
    String? mainImageUrl;
    if (json['main_image'] != null) {
      mainImageUrl = json['main_image'];
    } else if (imagesList.isNotEmpty) {
      mainImageUrl = imagesList.first;
    }

    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: parsePrice(json['price']),
      stock: json['stock'] ?? 0,
      showStock: json['show_stock'] ?? false,
      acceptsCash: json['accepts_cash'] ?? true,
      acceptsSinpe: json['accepts_sinpe'] ?? true,
      offersPickup: json['offers_pickup'] ?? true,
      offersDelivery: json['offers_delivery'] ?? false,
      imageUrl: mainImageUrl,
      images: imagesList,
      category: json['category'] ?? '',
      sellerId: json['seller'] ?? '',
      sellerName: json['seller_name'] ?? 'Vendedor',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      sellerInfo: json['seller_info'] != null
          ? SellerInfo.fromJson(json['seller_info'])
          : null,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
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
      'accepts_sinpe': acceptsSinpe,
      'offers_pickup': offersPickup,
      'offers_delivery': offersDelivery,
      'image_url': imageUrl,
      'images': images,
      'main_image': imageUrl,
      'category': category,
      'seller': sellerId,
      'seller_name': sellerName,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
    };
  }

  /// Precio formateado con símbolo de colones
  String get formattedPrice => '₡${price.toStringAsFixed(2)}';

  /// Verificar si hay stock disponible
  bool get hasStock => stock > 0;
}
