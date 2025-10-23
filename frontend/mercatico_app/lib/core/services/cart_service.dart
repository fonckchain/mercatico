import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';

/// Servicio para manejar el carrito de compras
/// El carrito se guarda localmente usando SharedPreferences
class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  static const String _cartKey = 'shopping_cart';
  final List<CartItem> _items = [];

  /// Lista de items en el carrito
  List<CartItem> get items => List.unmodifiable(_items);

  /// Número total de items en el carrito
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Precio total del carrito
  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Precio total formateado
  String get formattedTotalPrice => '₡${totalPrice.toStringAsFixed(2)}';

  /// Verificar si el carrito está vacío
  bool get isEmpty => _items.isEmpty;

  /// Inicializar el carrito cargando datos guardados
  Future<void> initialize() async {
    await _loadCart();
  }

  /// Agregar producto al carrito
  Future<void> addItem(Product product, {int quantity = 1}) async {
    // Verificar si el producto ya está en el carrito
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      // Si ya existe, incrementar la cantidad
      _items[existingIndex].quantity += quantity;
    } else {
      // Si no existe, agregar nuevo item
      _items.add(CartItem(product: product, quantity: quantity));
    }

    await _saveCart();
  }

  /// Remover producto del carrito
  Future<void> removeItem(String productId) async {
    _items.removeWhere((item) => item.product.id == productId);
    await _saveCart();
  }

  /// Actualizar cantidad de un producto
  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      await _saveCart();
    }
  }

  /// Limpiar el carrito
  Future<void> clear() async {
    _items.clear();
    await _saveCart();
  }

  /// Obtener un item específico del carrito
  CartItem? getItem(String productId) {
    try {
      return _items.firstWhere((item) => item.product.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Verificar si un producto está en el carrito
  bool contains(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  /// Guardar carrito en SharedPreferences
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = _items.map((item) {
        return {
          'product': item.product.toJson(),
          'quantity': item.quantity,
        };
      }).toList();
      await prefs.setString(_cartKey, jsonEncode(cartData));
    } catch (e) {
      print('Error al guardar carrito: $e');
    }
  }

  /// Cargar carrito desde SharedPreferences
  Future<void> _loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString(_cartKey);

      if (cartString != null) {
        final List<dynamic> cartData = jsonDecode(cartString);
        _items.clear();

        for (var item in cartData) {
          final product = Product.fromJson(item['product']);
          final quantity = item['quantity'] as int;
          _items.add(CartItem(product: product, quantity: quantity));
        }
      }
    } catch (e) {
      print('Error al cargar carrito: $e');
      _items.clear();
    }
  }
}
