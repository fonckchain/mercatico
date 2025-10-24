import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/api_service.dart';
import '../../models/cart_item.dart';
import '../../widgets/location_picker.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  final ApiService _apiService = ApiService();
  String _deliveryMethod = 'pickup'; // 'pickup' o 'delivery'
  final TextEditingController _addressController = TextEditingController();

  // Buyer delivery location
  double? _deliveryLatitude;
  double? _deliveryLongitude;

  // Seller pickup location (from first item in cart)
  String? _sellerBusinessName;
  String? _sellerAddress;
  double? _pickupLatitude;
  double? _pickupLongitude;

  bool _isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      // Load buyer's profile for delivery location
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

      // Load seller's pickup location from first cart item
      if (_cartService.items.isNotEmpty) {
        final firstProduct = _cartService.items.first.product;
        final sellerId = firstProduct.sellerId;

        if (sellerId != null) {
          final sellerData = await _apiService.getProduct(firstProduct.id);
          final sellerInfo = sellerData['seller_info'];

          if (sellerInfo != null) {
            _sellerBusinessName = sellerInfo['business_name'];
            _sellerAddress = sellerInfo['address'];
            if (sellerInfo['latitude'] != null) {
              _pickupLatitude = double.tryParse(sellerInfo['latitude'].toString());
            }
            if (sellerInfo['longitude'] != null) {
              _pickupLongitude = double.tryParse(sellerInfo['longitude'].toString());
            }
          }
        }
      }

      setState(() {
        _isLoadingLocations = false;
      });
    } catch (e) {
      print('Error loading locations: $e');
      setState(() {
        _isLoadingLocations = false;
      });
    }
  }

  Future<void> _pickDeliveryLocation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPicker(
          initialLocation: _deliveryLatitude != null && _deliveryLongitude != null
              ? LatLng(_deliveryLatitude!, _deliveryLongitude!)
              : null,
          onLocationSelected: (location, address) {
            setState(() {
              _deliveryLatitude = location.latitude;
              _deliveryLongitude = location.longitude;
              if (_addressController.text.isEmpty) {
                _addressController.text = address;
              }
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _cartService.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartService.items.length,
                    itemBuilder: (context, index) {
                      return _CartItemCard(
                        item: _cartService.items[index],
                        onQuantityChanged: (newQuantity) async {
                          await _cartService.updateQuantity(
                            _cartService.items[index].product.id,
                            newQuantity,
                          );
                          setState(() {});
                        },
                        onRemove: () async {
                          await _cartService.removeItem(
                            _cartService.items[index].product.id,
                          );
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
                _buildCartSummary(),
              ],
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

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Method Selection
            const Text(
              'Método de entrega:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
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

            // Pickup Location Info
            if (_deliveryMethod == 'pickup' && !_isLoadingLocations) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.store, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Lugar de recogida:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_sellerBusinessName != null)
                      Text(
                        _sellerBusinessName!,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    if (_sellerAddress != null && _sellerAddress!.isNotEmpty)
                      Text(
                        _sellerAddress!,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    if (_pickupLatitude != null && _pickupLongitude != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'GPS: ${_pickupLatitude!.toStringAsFixed(6)}, ${_pickupLongitude!.toStringAsFixed(6)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // Delivery Address Field (if delivery selected)
            if (_deliveryMethod == 'delivery') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección de entrega',
                  hintText: 'Ingresa tu dirección completa',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  isDense: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickDeliveryLocation,
                icon: const Icon(Icons.map),
                label: Text(
                  _deliveryLatitude != null && _deliveryLongitude != null
                      ? 'Cambiar ubicación (${_deliveryLatitude!.toStringAsFixed(6)}, ${_deliveryLongitude!.toStringAsFixed(6)})'
                      : 'Seleccionar ubicación en el mapa',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total (${_cartService.itemCount} items):',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _cartService.formattedTotalPrice,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_deliveryMethod == 'delivery' &&
                      _addressController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Por favor ingresa la dirección de entrega'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  // TODO: Navigate to checkout with delivery method
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _deliveryMethod == 'pickup'
                            ? 'Proceder con recogida en tienda'
                            : 'Proceder con entrega a: ${_addressController.text}',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Proceder al pago',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image_not_supported);
                        },
                      ),
                    )
                  : const Icon(Icons.shopping_bag, size: 40),
            ),
            const SizedBox(width: 12),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.product.formattedPrice,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Quantity controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: () {
                                if (item.quantity > 1) {
                                  onQuantityChanged(item.quantity - 1);
                                }
                              },
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () {
                                if (item.quantity < item.product.stock) {
                                  onQuantityChanged(item.quantity + 1);
                                }
                              },
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Total price
                      Text(
                        item.formattedTotalPrice,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Eliminar producto'),
                    content: Text(
                      '¿Deseas eliminar "${item.product.name}" del carrito?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          onRemove();
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
