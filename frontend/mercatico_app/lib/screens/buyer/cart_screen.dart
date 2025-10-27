import 'package:flutter/material.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/api_service.dart';
import '../../models/cart_item.dart';
import 'checkout_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carrito (${_cartService.sellerCount} ${_cartService.sellerCount == 1 ? 'vendedor' : 'vendedores'})'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _cartService.isEmpty
          ? _buildEmptyCart()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cartService.sellerCarts.length,
              itemBuilder: (context, index) {
                final sellerCart = _cartService.sellerCarts[index];
                return _SellerCartSection(
                  sellerCart: sellerCart,
                  onUpdate: () => setState(() {}),
                );
              },
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Tu carrito está vacío',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega productos para empezar a comprar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Explorar Productos'),
          ),
        ],
      ),
    );
  }
}

/// Widget que muestra el carrito de un vendedor específico
class _SellerCartSection extends StatefulWidget {
  final SellerCart sellerCart;
  final VoidCallback onUpdate;

  const _SellerCartSection({
    required this.sellerCart,
    required this.onUpdate,
  });

  @override
  State<_SellerCartSection> createState() => _SellerCartSectionState();
}

class _SellerCartSectionState extends State<_SellerCartSection> {
  final CartService _cartService = CartService();
  final ApiService _apiService = ApiService();

  String _deliveryMethod = 'pickup';
  final TextEditingController _addressController = TextEditingController();

  // Buyer delivery location
  double? _deliveryLatitude;
  double? _deliveryLongitude;

  // Seller pickup location
  String? _sellerAddress;
  double? _pickupLatitude;
  double? _pickupLongitude;

  // Payment info
  String? _sinpeNumber;

  bool _isLoadingInfo = true;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadInfo() async {
    try {
      // Load buyer profile
      final userData = await _apiService.getCurrentUser();
      final buyerProfile = userData['buyer_profile'];

      if (buyerProfile != null) {
        _addressController.text = buyerProfile['address'] ?? '';
        if (buyerProfile['latitude'] != null) {
          _deliveryLatitude = double.tryParse(buyerProfile['latitude'].toString());
        }
        if (buyerProfile['longitude'] != null) {
          _deliveryLongitude = double.tryParse(buyerProfile['longitude'].toString());
        }
      }

      // Load seller info from first product
      if (widget.sellerCart.items.isNotEmpty) {
        final firstProduct = widget.sellerCart.items.first.product;
        final productData = await _apiService.getProduct(firstProduct.id);
        final sellerInfo = productData['seller_info'];

        if (sellerInfo != null) {
          _sellerAddress = sellerInfo['address'];
          if (sellerInfo['latitude'] != null) {
            _pickupLatitude = double.tryParse(sellerInfo['latitude'].toString());
          }
          if (sellerInfo['longitude'] != null) {
            _pickupLongitude = double.tryParse(sellerInfo['longitude'].toString());
          }
          _sinpeNumber = sellerInfo['sinpe_number'];
        }
      }

      setState(() {
        _isLoadingInfo = false;
      });
    } catch (e) {
      print('Error loading info: $e');
      setState(() {
        _isLoadingInfo = false;
      });
    }
  }

  void _goToCheckout() {
    // Validate delivery method is available
    final availableMethods = widget.sellerCart.availableDeliveryMethods;
    final selectedMethod = _deliveryMethod.toUpperCase();

    if (!availableMethods.contains(selectedMethod)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El método de entrega "$_deliveryMethod" no está disponible para todos los productos de ${widget.sellerCart.sellerName}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate payment methods available
    if (widget.sellerCart.availablePaymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay métodos de pago compatibles entre los productos de este vendedor',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate delivery address if needed
    if (_deliveryMethod == 'delivery' && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa la dirección de entrega'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          sellerId: widget.sellerCart.sellerId,
          deliveryMethod: _deliveryMethod,
          deliveryAddress: _deliveryMethod == 'delivery' ? _addressController.text : null,
          deliveryLatitude: _deliveryMethod == 'delivery' ? _deliveryLatitude : null,
          deliveryLongitude: _deliveryMethod == 'delivery' ? _deliveryLongitude : null,
          pickupAddress: _deliveryMethod == 'pickup' ? _sellerAddress : null,
          pickupLatitude: _deliveryMethod == 'pickup' ? _pickupLatitude : null,
          pickupLongitude: _deliveryMethod == 'pickup' ? _pickupLongitude : null,
          sellerBusinessName: widget.sellerCart.sellerName,
        ),
      ),
    ).then((_) => widget.onUpdate());
  }

  Future<void> _openLocationInMap() async {
    if (_pickupLatitude == null || _pickupLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación no disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Create Google Maps URL
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$_pickupLatitude,$_pickupLongitude'
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el mapa'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir el mapa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.green.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.store, color: Colors.green.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.sellerCart.sellerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.sellerCart.itemCount} ${widget.sellerCart.itemCount == 1 ? 'producto' : 'productos'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₡${widget.sellerCart.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // Products List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.sellerCart.items.length,
            itemBuilder: (context, index) {
              return _CartItemCard(
                item: widget.sellerCart.items[index],
                onQuantityChanged: (newQuantity) async {
                  await _cartService.updateQuantity(
                    widget.sellerCart.items[index].product.id,
                    newQuantity,
                  );
                  widget.onUpdate();
                },
                onRemove: () async {
                  await _cartService.removeItem(
                    widget.sellerCart.items[index].product.id,
                  );
                  widget.onUpdate();
                },
              );
            },
          ),

          // Available Methods Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Métodos disponibles para este vendedor:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Payment Methods
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.sellerCart.availablePaymentMethods.contains('SINPE'))
                      Chip(
                        avatar: const Icon(Icons.phone_android, size: 16),
                        label: const Text('SINPE Móvil'),
                        backgroundColor: Colors.green.shade100,
                      ),
                    if (widget.sellerCart.availablePaymentMethods.contains('CASH'))
                      Chip(
                        avatar: const Text('₡', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        label: const Text('Efectivo'),
                        backgroundColor: Colors.green.shade100,
                      ),
                    if (widget.sellerCart.availablePaymentMethods.isEmpty)
                      Chip(
                        avatar: const Icon(Icons.warning, size: 16),
                        label: const Text('Sin métodos de pago compatibles'),
                        backgroundColor: Colors.red.shade100,
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Delivery Methods
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.sellerCart.availableDeliveryMethods.contains('PICKUP'))
                      Chip(
                        avatar: const Icon(Icons.store, size: 16),
                        label: const Text('Recoger en tienda'),
                        backgroundColor: Colors.blue.shade100,
                      ),
                    if (widget.sellerCart.availableDeliveryMethods.contains('DELIVERY'))
                      Chip(
                        avatar: const Icon(Icons.local_shipping, size: 16),
                        label: const Text('Entrega a domicilio'),
                        backgroundColor: Colors.blue.shade100,
                      ),
                    if (widget.sellerCart.availableDeliveryMethods.isEmpty)
                      Chip(
                        avatar: const Icon(Icons.warning, size: 16),
                        label: const Text('Sin métodos de entrega compatibles'),
                        backgroundColor: Colors.red.shade100,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Delivery Selection & Checkout
          if (!_isLoadingInfo) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Método de entrega:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Delivery method selector
                  Row(
                    children: [
                      if (widget.sellerCart.availableDeliveryMethods.contains('PICKUP'))
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Recoger'),
                            value: 'pickup',
                            groupValue: _deliveryMethod,
                            onChanged: (value) {
                              setState(() {
                                _deliveryMethod = value!;
                              });
                            },
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      if (widget.sellerCart.availableDeliveryMethods.contains('DELIVERY'))
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Entrega'),
                            value: 'delivery',
                            groupValue: _deliveryMethod,
                            onChanged: (value) {
                              setState(() {
                                _deliveryMethod = value!;
                              });
                            },
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Pickup location info
                  if (_deliveryMethod == 'pickup') ...[
                    Card(
                      color: Colors.blue.shade50,
                      child: InkWell(
                        onTap: _pickupLatitude != null && _pickupLongitude != null
                            ? _openLocationInMap
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.store, color: Colors.blue.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Ubicación de recogida:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                  if (_pickupLatitude != null && _pickupLongitude != null)
                                    Icon(
                                      Icons.map,
                                      color: Colors.blue.shade700,
                                      size: 20,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_sellerAddress != null && _sellerAddress!.isNotEmpty) ...[
                                Text(_sellerAddress!),
                                const SizedBox(height: 4),
                              ],
                              if (_pickupLatitude != null && _pickupLongitude != null) ...[
                                Text(
                                  'GPS: ${_pickupLatitude!.toStringAsFixed(6)}, ${_pickupLongitude!.toStringAsFixed(6)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Toca para ver en el mapa',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              if ((_sellerAddress == null || _sellerAddress!.isEmpty) &&
                                  _pickupLatitude == null)
                                Text(
                                  'El vendedor no ha configurado una ubicación de recogida',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Address field for delivery
                  if (_deliveryMethod == 'delivery') ...[
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.local_shipping, color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Dirección de entrega:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Confirma o edita tu dirección',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              maxLines: 2,
                            ),
                            if (_deliveryLatitude != null && _deliveryLongitude != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'GPS: ${_deliveryLatitude!.toStringAsFixed(6)}, ${_deliveryLongitude!.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Checkout Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _goToCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Proceder al pago - ₡${widget.sellerCart.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Card para mostrar un item individual del carrito
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.product.imageUrl != null
                  ? Image.network(
                      item.product.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 40),
                        );
                      },
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.shopping_bag, size: 40),
                    ),
            ),
            const SizedBox(width: 12),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.product.formattedPrice,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quantity Controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (item.quantity > 1) {
                            onQuantityChanged(item.quantity - 1);
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 24,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (item.quantity < item.product.stock) {
                            onQuantityChanged(item.quantity + 1);
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 24,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Price and Remove
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 8),
                Text(
                  '₡${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
