import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/cart_service.dart';
import '../../core/services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  final String deliveryMethod; // 'pickup' or 'delivery'
  final String? deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? sellerBusinessName;

  const CheckoutScreen({
    super.key,
    required this.deliveryMethod,
    this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.sellerBusinessName,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService();
  final ApiService _apiService = ApiService();

  String? _paymentMethod; // 'sinpe' or 'cash'
  bool _isLoading = true;
  bool _isProcessingOrder = false;

  // Seller payment preferences
  bool _sellerAcceptsCash = false;
  bool _sellerAcceptsSinpe = false;
  String? _sellerSinpeNumber;

  @override
  void initState() {
    super.initState();
    _loadSellerPaymentInfo();
  }

  Future<void> _loadSellerPaymentInfo() async {
    try {
      // Get product and seller info from first cart item
      if (_cartService.items.isNotEmpty) {
        final firstProduct = _cartService.items.first.product;
        final productData = await _apiService.getProduct(firstProduct.id);
        final sellerInfo = productData['seller_info'];

        setState(() {
          // accepts_cash viene del producto (configuración por producto)
          _sellerAcceptsCash = productData['accepts_cash'] ?? false;

          // sinpe_number viene del perfil del vendedor (es global)
          _sellerSinpeNumber = sellerInfo?['sinpe_number'];
          _sellerAcceptsSinpe = _sellerSinpeNumber != null && _sellerSinpeNumber!.isNotEmpty;

          // Set default payment method
          if (_sellerAcceptsSinpe) {
            _paymentMethod = 'sinpe';
          } else if (_sellerAcceptsCash) {
            _paymentMethod = 'cash';
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading seller payment info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processOrder() async {
    if (_paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un método de pago'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessingOrder = true;
    });

    try {
      // TODO: Implement actual order creation API call
      // This is a placeholder for the order creation logic
      await Future.delayed(const Duration(seconds: 2));

      // Clear cart after successful order
      await _cartService.clear();

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('¡Pedido Realizado!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tu pedido ha sido creado exitosamente.'),
                const SizedBox(height: 16),
                if (_paymentMethod == 'sinpe') ...[
                  const Text(
                    'Por favor realiza el pago SINPE Móvil al número:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _sellerSinpeNumber!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _sellerSinpeNumber!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Número copiado')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Monto: ${_cartService.formattedTotalPrice}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ] else if (_paymentMethod == 'cash') ...[
                  const Text(
                    'Pagarás en efectivo al momento de ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.deliveryMethod == 'pickup' ? 'recoger el pedido.' : 'recibir el pedido.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to products screen
                  Navigator.of(context).pop(); // Go back to cart screen
                },
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar pedido: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Pedido'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary
                  _buildSectionTitle('Resumen del Pedido'),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ..._cartService.items.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.quantity}x ${item.product.name}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    Text(
                                      '₡${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _cartService.formattedTotalPrice,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Delivery Info
                  _buildSectionTitle('Información de Entrega'),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                widget.deliveryMethod == 'pickup' ? Icons.store : Icons.local_shipping,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.deliveryMethod == 'pickup' ? 'Recoger en tienda' : 'Entrega a domicilio',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (widget.deliveryMethod == 'pickup') ...[
                            if (widget.sellerBusinessName != null)
                              Text(
                                widget.sellerBusinessName!,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            if (widget.pickupAddress != null && widget.pickupAddress!.isNotEmpty)
                              Text(widget.pickupAddress!),
                            if (widget.pickupLatitude != null && widget.pickupLongitude != null)
                              Text(
                                'GPS: ${widget.pickupLatitude!.toStringAsFixed(6)}, ${widget.pickupLongitude!.toStringAsFixed(6)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                          ] else ...[
                            if (widget.deliveryAddress != null && widget.deliveryAddress!.isNotEmpty)
                              Text(widget.deliveryAddress!),
                            if (widget.deliveryLatitude != null && widget.deliveryLongitude != null)
                              Text(
                                'GPS: ${widget.deliveryLatitude!.toStringAsFixed(6)}, ${widget.deliveryLongitude!.toStringAsFixed(6)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Method
                  _buildSectionTitle('Método de Pago'),
                  const SizedBox(height: 12),
                  if (!_sellerAcceptsCash && !_sellerAcceptsSinpe)
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red.shade700),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Este vendedor no tiene métodos de pago configurados. Contacta al vendedor.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    if (_sellerAcceptsSinpe)
                      Card(
                        color: _paymentMethod == 'sinpe' ? Colors.green.shade50 : null,
                        child: RadioListTile<String>(
                          value: 'sinpe',
                          groupValue: _paymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _paymentMethod = value;
                            });
                          },
                          title: const Text('SINPE Móvil'),
                          subtitle: Text('Pago inmediato a: $_sellerSinpeNumber'),
                          secondary: const Icon(Icons.phone_android, color: Colors.green),
                        ),
                      ),
                    if (_sellerAcceptsCash)
                      Card(
                        color: _paymentMethod == 'cash' ? Colors.green.shade50 : null,
                        child: RadioListTile<String>(
                          value: 'cash',
                          groupValue: _paymentMethod,
                          onChanged: (value) {
                            setState(() {
                              _paymentMethod = value;
                            });
                          },
                          title: const Text('Efectivo'),
                          subtitle: Text(
                            widget.deliveryMethod == 'pickup'
                                ? 'Pagar al recoger el pedido'
                                : 'Pagar contra entrega',
                          ),
                          secondary: const Icon(Icons.attach_money, color: Colors.green),
                        ),
                      ),
                  ],
                  const SizedBox(height: 32),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_isProcessingOrder || (!_sellerAcceptsCash && !_sellerAcceptsSinpe))
                          ? null
                          : _processOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _isProcessingOrder
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirmar Pedido',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
