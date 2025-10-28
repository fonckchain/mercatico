import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_service.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _purchases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final purchases = await _apiService.getMyPurchases();
      setState(() {
        _purchases = purchases;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading purchases: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar historial: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _contactSeller(String phone, String sellerName) async {
    // Clean phone number (remove spaces, dashes, etc.)
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // If phone doesn't start with +, assume Costa Rica (+506)
    if (!cleanPhone.startsWith('+')) {
      cleanPhone = '+506$cleanPhone';
    }

    // Show options dialog
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Contactar a $sellerName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.phone, color: Color(0xFF25D366)),
                title: const Text('WhatsApp'),
                subtitle: Text(phone),
                onTap: () async {
                  Navigator.pop(context);
                  final whatsappUrl = Uri.parse(
                    'https://wa.me/$cleanPhone?text=${Uri.encodeComponent('Hola, tengo una consulta sobre mi pedido en MercaTico')}',
                  );

                  try {
                    final canLaunch = await canLaunchUrl(whatsappUrl);
                    if (canLaunch) {
                      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                    } else {
                      // Try alternative WhatsApp URL scheme
                      final altUrl = Uri.parse('whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent('Hola, tengo una consulta sobre mi pedido en MercaTico')}');
                      if (await canLaunchUrl(altUrl)) {
                        await launchUrl(altUrl, mode: LaunchMode.externalApplication);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('WhatsApp no está instalado'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al abrir WhatsApp: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.call, color: Colors.blue),
                title: const Text('Llamar'),
                subtitle: Text(phone),
                onTap: () async {
                  Navigator.pop(context);
                  final telUrl = Uri.parse('tel:$cleanPhone');
                  try {
                    await launchUrl(telUrl, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al realizar llamada: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Order header
                    Text(
                      'Pedido ${order['order_number']}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusChip(order['status_display']),
                    const Divider(height: 32),

                    // Seller info
                    _buildInfoSection(
                      'Vendedor',
                      Icons.store,
                      [
                        _buildInfoRow('Negocio', order['seller']['business_name'] ?? 'N/A'),
                        _buildInfoRow('Teléfono', order['seller']['phone'] ?? 'N/A'),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _contactSeller(
                                order['seller']['phone'] ?? '',
                                order['seller']['business_name'] ?? 'El Vendedor',
                              );
                            },
                            icon: const Icon(Icons.phone),
                            label: const Text('Contactar por WhatsApp'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Delivery info
                    _buildInfoSection(
                      'Entrega',
                      Icons.local_shipping,
                      [
                        _buildInfoRow('Método', order['delivery_method_display']),
                        if (order['delivery_address'] != null && order['delivery_address'].toString().isNotEmpty)
                          _buildInfoRow('Dirección', order['delivery_address']),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Payment info
                    _buildInfoSection(
                      'Pago',
                      Icons.payment,
                      [
                        _buildInfoRow('Método', order['payment_method_display']),
                        _buildInfoRow(
                          'Estado',
                          order['payment_verified'] ? 'Verificado' : 'Pendiente de verificación',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Items
                    _buildInfoSection(
                      'Productos',
                      Icons.shopping_bag,
                      [
                        ...List.generate(
                          (order['items'] as List).length,
                          (index) {
                            final item = order['items'][index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['product_name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          'Cantidad: ${item['quantity']}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₡${double.parse(item['subtotal'].toString()).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:'),
                              Text('₡${double.parse(order['subtotal'].toString()).toStringAsFixed(2)}'),
                            ],
                          ),
                          if (order['delivery_fee'] != null && double.parse(order['delivery_fee'].toString()) > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Envío:'),
                                Text('₡${double.parse(order['delivery_fee'].toString()).toStringAsFixed(2)}'),
                              ],
                            ),
                          ],
                          const Divider(height: 24),
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
                                '₡${double.parse(order['total'].toString()).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Dates
                    _buildInfoSection(
                      'Fechas',
                      Icons.calendar_today,
                      [
                        _buildInfoRow(
                          'Creado',
                          _formatDate(order['created_at']),
                        ),
                        if (order['confirmed_at'] != null)
                          _buildInfoRow(
                            'Confirmado',
                            _formatDate(order['confirmed_at']),
                          ),
                        if (order['shipped_at'] != null)
                          _buildInfoRow(
                            'Listo para entrega',
                            _formatDate(order['shipped_at']),
                          ),
                        if (order['delivered_at'] != null)
                          _buildInfoRow(
                            'Entregado',
                            _formatDate(order['delivered_at']),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;

    // Determine colors based on status
    switch (status.toLowerCase()) {
      case 'confirmada':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      case 'entregado':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade900;
        break;
      case 'cancelado':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        break;
      case 'pago pendiente de verificación':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        break;
      case 'listo para entrega':
      case 'enviado':
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade900;
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Compras'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _purchases.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes compras aún',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPurchases,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _purchases.length,
                    itemBuilder: (context, index) {
                      final order = _purchases[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () => _showOrderDetails(order),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Order number and status
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Pedido ${order['order_number']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    _buildStatusChip(order['status_display']),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Seller info
                                Row(
                                  children: [
                                    Icon(Icons.store, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        order['seller']['business_name'] ?? 'Vendedor',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Item count
                                Row(
                                  children: [
                                    Icon(Icons.shopping_bag, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(order['items'] as List).length} producto(s)',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Date
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(order['created_at']),
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Total and actions
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '₡${double.parse(order['total'].toString()).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.phone, color: Color(0xFF25D366)),
                                          tooltip: 'Contactar',
                                          onPressed: () => _contactSeller(
                                            order['seller']['phone'] ?? '',
                                            order['seller']['business_name'] ?? 'El Vendedor',
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios, size: 16),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
