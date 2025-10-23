import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../core/services/api_service.dart';
import '../../core/services/cart_service.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  final CartService _cartService = CartService();
  Product? _product;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedQuantity = 1;
  int _currentImageIndex = 0; // Para el carrusel de imágenes

  @override
  void initState() {
    super.initState();
    _loadProductDetail();
  }

  Future<void> _loadProductDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getProduct(widget.productId);
      setState(() {
        _product = Product.fromJson(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar el producto: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_product?.name ?? 'Detalle del Producto'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProductDetail,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _product == null
                  ? const Center(child: Text('Producto no encontrado'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Gallery
                          _buildImageGallery(),

                          // Product Info
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Name
                                Text(
                                  _product!.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Price
                                Text(
                                  '₡${_product!.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Stock availability
                                Row(
                                  children: [
                                    Icon(
                                      _product!.hasStock
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: _product!.hasStock
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _product!.hasStock
                                          ? (_product!.showStock
                                              ? 'Disponible (${_product!.stock} unidades)'
                                              : 'Disponible')
                                          : 'Agotado',
                                      style: TextStyle(
                                        color: _product!.hasStock
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Category - temporarily hidden until we add category name lookup
                                // Container(
                                //   padding: const EdgeInsets.symmetric(
                                //     horizontal: 12,
                                //     vertical: 6,
                                //   ),
                                //   decoration: BoxDecoration(
                                //     color: Colors.green.shade50,
                                //     borderRadius: BorderRadius.circular(20),
                                //     border: Border.all(
                                //         color: Colors.green.shade200),
                                //   ),
                                //   child: Text(
                                //     _product!.category,
                                //     style: TextStyle(
                                //       color: Colors.green.shade700,
                                //       fontWeight: FontWeight.w500,
                                //     ),
                                //   ),
                                // ),
                                const SizedBox(height: 24),

                                // Description
                                const Text(
                                  'Descripción',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _product!.description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Seller Info
                                const Text(
                                  'Vendedor',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Colors.green,
                                      child: Icon(Icons.store,
                                          color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _product!.sellerName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),

                                // Quantity Selector
                                if (_product!.hasStock) ...[
                                  Row(
                                    children: [
                                      const Text(
                                        'Cantidad:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey[300]!),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: _selectedQuantity > 1
                                                  ? () {
                                                      setState(() {
                                                        _selectedQuantity--;
                                                      });
                                                    }
                                                  : null,
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 16),
                                              child: Text(
                                                '$_selectedQuantity',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: _selectedQuantity < _product!.stock
                                                  ? () {
                                                      setState(() {
                                                        _selectedQuantity++;
                                                      });
                                                    }
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      if (_product!.showStock)
                                        Text(
                                          '${_product!.stock} disponibles',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // Add to Cart Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: _product!.hasStock
                                        ? () async {
                                            await _cartService.addItem(
                                              _product!,
                                              quantity: _selectedQuantity,
                                            );
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '$_selectedQuantity ${_selectedQuantity == 1 ? 'producto agregado' : 'productos agregados'} al carrito',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                  action: SnackBarAction(
                                                    label: 'Ver carrito',
                                                    textColor: Colors.white,
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              const CartScreen(),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              );
                                              // Reset quantity to 1
                                              setState(() {
                                                _selectedQuantity = 1;
                                              });
                                            }
                                          }
                                        : null,
                                    icon: const Icon(Icons.shopping_cart),
                                    label: const Text(
                                      'Agregar al Carrito',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildImageGallery() {
    // Usar lista de imágenes si está disponible, sino usar imageUrl
    final images = _product!.images.isNotEmpty
        ? _product!.images
        : (_product!.imageUrl != null ? [_product!.imageUrl!] : <String>[]);

    final hasImages = images.isNotEmpty;

    return Container(
      width: double.infinity,
      height: 300,
      color: Colors.grey.shade200,
      child: hasImages
          ? Stack(
              children: [
                // Carrusel de imágenes
                PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, size: 64, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Imagen no disponible'),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    );
                  },
                ),
                // Indicador de página (solo si hay más de una imagen)
                if (images.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Contador de imágenes
                if (images.length > 1)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Sin imagen'),
                ],
              ),
            ),
    );
  }
}
