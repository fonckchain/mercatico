import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/cart_item.dart';
import '../../models/product.dart';

/// Carrito de un vendedor específico
class SellerCart {
  final String sellerId;
  final String sellerName;
  final List<CartItem> items;

  SellerCart({
    required this.sellerId,
    required this.sellerName,
    this.items = const [],
  });

  /// Precio total del carrito de este vendedor
  double get totalPrice => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Número de items del vendedor
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Métodos de pago disponibles (intersección de todos los productos)
  Set<String> get availablePaymentMethods {
    if (items.isEmpty) return {};

    Set<String> methods = {};
    bool firstItem = true;

    print('=== DEBUG: availablePaymentMethods for seller $sellerName ===');
    for (var item in items) {
      Set<String> productMethods = {};
      print('Product: ${item.product.name}');
      print('  acceptsCash: ${item.product.acceptsCash} (type: ${item.product.acceptsCash.runtimeType})');
      print('  acceptsSinpe: ${item.product.acceptsSinpe} (type: ${item.product.acceptsSinpe.runtimeType})');

      if (item.product.acceptsCash == true) productMethods.add('CASH');
      if (item.product.acceptsSinpe == true) productMethods.add('SINPE');

      print('  productMethods: $productMethods');

      if (firstItem) {
        methods = productMethods;
        firstItem = false;
      } else {
        methods = methods.intersection(productMethods);
      }
      print('  methods after intersection: $methods');
    }
    print('=== FINAL payment methods: $methods ===');

    return methods;
  }

  /// Métodos de entrega disponibles (intersección de todos los productos)
  Set<String> get availableDeliveryMethods {
    if (items.isEmpty) return {};

    Set<String> methods = {};
    bool firstItem = true;

    print('=== DEBUG: availableDeliveryMethods for seller $sellerName ===');
    for (var item in items) {
      Set<String> productMethods = {};
      print('Product: ${item.product.name}');
      print('  offersPickup: ${item.product.offersPickup} (type: ${item.product.offersPickup.runtimeType})');
      print('  offersDelivery: ${item.product.offersDelivery} (type: ${item.product.offersDelivery.runtimeType})');

      if (item.product.offersPickup == true) productMethods.add('PICKUP');
      if (item.product.offersDelivery == true) productMethods.add('DELIVERY');

      print('  productMethods: $productMethods');

      if (firstItem) {
        methods = productMethods;
        firstItem = false;
      } else {
        methods = methods.intersection(productMethods);
      }
      print('  methods after intersection: $methods');
    }
    print('=== FINAL delivery methods: $methods ===');

    return methods;
  }

  Map<String, dynamic> toJson() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'items': items.map((item) => {
        'product': item.product.toJson(),
        'quantity': item.quantity,
      }).toList(),
    };
  }

  factory SellerCart.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>).map((item) {
      return CartItem(
        product: Product.fromJson(item['product']),
        quantity: item['quantity'] as int,
      );
    }).toList();

    return SellerCart(
      sellerId: json['sellerId'] as String,
      sellerName: json['sellerName'] as String,
      items: items,
    );
  }
}

/// Servicio para manejar el carrito de compras
/// El carrito se guarda localmente usando SharedPreferences
/// Ahora soporta múltiples carritos separados por vendedor
class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  static const String _cartKey = 'shopping_cart';
  final Map<String, SellerCart> _carts = {};

  /// Lista de carritos por vendedor
  List<SellerCart> get sellerCarts => _carts.values.toList();

  /// Lista de todos los items (compatibilidad con código existente)
  List<CartItem> get items {
    List<CartItem> allItems = [];
    for (var cart in _carts.values) {
      allItems.addAll(cart.items);
    }
    return allItems;
  }

  /// Número total de items en todos los carritos
  int get itemCount {
    return _carts.values.fold(0, (sum, cart) => sum + cart.itemCount);
  }

  /// Precio total de todos los carritos
  double get totalPrice {
    return _carts.values.fold(0.0, (sum, cart) => sum + cart.totalPrice);
  }

  /// Precio total formateado
  String get formattedTotalPrice => '₡${totalPrice.toStringAsFixed(2)}';

  /// Verificar si el carrito está vacío
  bool get isEmpty => _carts.isEmpty;

  /// Número de vendedores en el carrito
  int get sellerCount => _carts.length;

  /// Inicializar el carrito cargando datos guardados
  Future<void> initialize() async {
    await _loadCart();
  }

  /// Agregar producto al carrito con validación de compatibilidad
  /// Retorna un mensaje de error si hay incompatibilidad, null si todo está bien
  Future<String?> addItem(Product product, {int quantity = 1}) async {
    final sellerId = product.sellerId ?? '';
    final sellerName = product.sellerName ?? 'Vendedor Desconocido';

    // Si no existe el carrito del vendedor, crearlo
    if (!_carts.containsKey(sellerId)) {
      _carts[sellerId] = SellerCart(
        sellerId: sellerId,
        sellerName: sellerName,
        items: [],
      );
    }

    // Crear una lista temporal con el nuevo producto
    final tempItems = List<CartItem>.from(_carts[sellerId]!.items);
    final existingIndex = tempItems.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      tempItems[existingIndex].quantity += quantity;
    } else {
      tempItems.add(CartItem(product: product, quantity: quantity));
    }

    // Crear un carrito temporal para validar
    final tempCart = SellerCart(
      sellerId: sellerId,
      sellerName: sellerName,
      items: tempItems,
    );

    // Validar métodos de pago
    if (tempCart.availablePaymentMethods.isEmpty) {
      return 'No hay métodos de pago compatibles entre los productos. '
             'Este producto no comparte métodos de pago con los demás productos de ${sellerName} en tu carrito.';
    }

    // Validar métodos de entrega
    if (tempCart.availableDeliveryMethods.isEmpty) {
      return 'No hay métodos de entrega compatibles entre los productos. '
             'Este producto no comparte métodos de entrega con los demás productos de ${sellerName} en tu carrito.';
    }

    // Si todo está bien, agregar el producto
    if (existingIndex >= 0) {
      _carts[sellerId]!.items[existingIndex].quantity += quantity;
    } else {
      _carts[sellerId]!.items.add(CartItem(product: product, quantity: quantity));
    }

    await _saveCart();
    return null; // Sin errores
  }

  /// Remover producto del carrito
  Future<void> removeItem(String productId) async {
    for (var sellerId in _carts.keys.toList()) {
      _carts[sellerId]!.items.removeWhere((item) => item.product.id == productId);

      // Si el carrito del vendedor queda vacío, removerlo
      if (_carts[sellerId]!.items.isEmpty) {
        _carts.remove(sellerId);
      }
    }
    await _saveCart();
  }

  /// Actualizar cantidad de un producto
  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(productId);
      return;
    }

    for (var cart in _carts.values) {
      final index = cart.items.indexWhere((item) => item.product.id == productId);
      if (index >= 0) {
        cart.items[index].quantity = quantity;
        await _saveCart();
        return;
      }
    }
  }

  /// Limpiar todos los carritos
  Future<void> clear() async {
    _carts.clear();
    await _saveCart();
  }

  /// Limpiar el carrito de un vendedor específico
  Future<void> clearSeller(String sellerId) async {
    _carts.remove(sellerId);
    await _saveCart();
  }

  /// Obtener el carrito de un vendedor específico
  SellerCart? getSellerCart(String sellerId) {
    return _carts[sellerId];
  }

  /// Obtener un item específico del carrito
  CartItem? getItem(String productId) {
    for (var cart in _carts.values) {
      try {
        return cart.items.firstWhere((item) => item.product.id == productId);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  /// Verificar si un producto está en el carrito
  bool contains(String productId) {
    for (var cart in _carts.values) {
      if (cart.items.any((item) => item.product.id == productId)) {
        return true;
      }
    }
    return false;
  }

  /// Guardar carrito en SharedPreferences
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = _carts.values.map((cart) => cart.toJson()).toList();
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
        _carts.clear();

        bool hasInvalidData = false;

        for (var sellerData in cartData) {
          try {
            final cart = SellerCart.fromJson(sellerData);

            // Validate that products have the required fields
            // If they don't, it means they were saved with old version
            for (var item in cart.items) {
              final productJson = (sellerData['items'] as List)
                  .firstWhere((i) => i['product']['id'] == item.product.id)['product'];

              // Check if critical fields are missing (indicates old format)
              if (!productJson.containsKey('accepts_sinpe') ||
                  !productJson.containsKey('offers_delivery')) {
                hasInvalidData = true;
                print('Warning: Cart has products saved in old format. Clearing cart.');
                break;
              }
            }

            if (hasInvalidData) {
              break;
            }

            _carts[cart.sellerId] = cart;
          } catch (e) {
            print('Error loading seller cart: $e');
            hasInvalidData = true;
            break;
          }
        }

        // Clear cart if we found invalid data
        if (hasInvalidData) {
          _carts.clear();
          await _saveCart(); // Save empty cart
          print('Cart cleared due to old format. Please re-add products.');
        }
      }
    } catch (e) {
      print('Error al cargar carrito: $e');
      _carts.clear();
    }
  }
}
