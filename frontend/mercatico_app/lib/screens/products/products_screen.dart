import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/cart_service.dart';
import '../../models/product.dart';
import '../buyer/product_detail_screen.dart';
import '../buyer/cart_screen.dart';
import '../buyer/buyer_profile_screen.dart';
import '../buyer/purchase_history_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Product> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  bool _isLoadingCategories = true;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoggedIn = false;
  String? _userType;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _initializeCart();
    _loadCategories();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isAuthenticated();
    if (isLoggedIn) {
      try {
        final userData = await _apiService.getCurrentUser();
        setState(() {
          _isLoggedIn = true;
          _userType = userData['user_type'];
        });

        // Redirect sellers to their products page
        if (_userType == 'SELLER') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          });
        }
      } catch (e) {
        print('Error getting user data: $e');
        setState(() {
          _isLoggedIn = false;
        });
      }
    } else {
      setState(() {
        _isLoggedIn = false;
      });
    }
  }

  Future<void> _initializeCart() async {
    await _cartService.initialize();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _apiService.getCategories();
      if (response['results'] != null) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(response['results']);
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getProducts(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        category: _selectedCategory,
      );

      if (response['results'] != null) {
        setState(() {
          _products = (response['results'] as List)
              .map((json) => Product.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No se pudieron cargar los productos';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar productos: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      _loadProducts();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _searchController.clear();
    });
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MercaTico'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoggedIn && _userType == 'BUYER') ...[
            IconButton(
              icon: Badge(
                label: Text('${_cartService.itemCount}'),
                isLabelVisible: _cartService.itemCount > 0,
                child: const Icon(Icons.shopping_cart),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CartScreen(),
                  ),
                );
                setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.receipt_long),
              tooltip: 'Mis Compras',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PurchaseHistoryScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Mi Perfil',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BuyerProfileScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                await _authService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ] else if (_isLoggedIn && _userType == 'SELLER') ...[
            TextButton.icon(
              icon: const Icon(Icons.store, color: Colors.white),
              label: const Text('Ir a Mis Productos', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/home');
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                await _authService.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              },
            ),
          ] else ...[
            TextButton.icon(
              icon: const Icon(Icons.login, color: Colors.white),
              label: const Text('Iniciar Sesión', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pushNamed('/login');
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text('Registrarse', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pushNamed('/register');
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por producto o vendedor...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          _loadProducts();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Filtro de categorías
          if (!_isLoadingCategories && _categories.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Chip para "Todas"
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('Todas'),
                            selected: _selectedCategory == null,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = null;
                              });
                              _loadProducts();
                            },
                            selectedColor: Colors.green.shade100,
                          ),
                        ),
                        // Chips de categorías
                        ..._categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category['name']),
                              selected: _selectedCategory == category['id'],
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = selected ? category['id'] : null;
                                });
                                _loadProducts();
                              },
                              selectedColor: Colors.green.shade100,
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  if (_selectedCategory != null || _searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_all),
                      tooltip: 'Limpiar filtros',
                      onPressed: _clearFilters,
                    ),
                ],
              ),
            ),

          const Divider(height: 1),

          // Lista de productos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProducts,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty || _selectedCategory != null
                                      ? 'No se encontraron productos con estos filtros'
                                      : 'No hay productos disponibles',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty || _selectedCategory != null) ...[
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _clearFilters,
                                    icon: const Icon(Icons.clear),
                                    label: const Text('Limpiar filtros'),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadProducts,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Calcular número de columnas basado en el ancho
                                int crossAxisCount;
                                double cardWidth;

                                if (constraints.maxWidth > 1200) {
                                  // Desktop grande: 6 columnas
                                  crossAxisCount = 6;
                                  cardWidth = 200;
                                } else if (constraints.maxWidth > 900) {
                                  // Desktop: 5 columnas
                                  crossAxisCount = 5;
                                  cardWidth = 200;
                                } else if (constraints.maxWidth > 700) {
                                  // Tablet landscape: 4 columnas
                                  crossAxisCount = 4;
                                  cardWidth = 200;
                                } else if (constraints.maxWidth > 500) {
                                  // Tablet portrait: 3 columnas
                                  crossAxisCount = 3;
                                  cardWidth = 180;
                                } else {
                                  // Móvil: 2 columnas
                                  crossAxisCount = 2;
                                  cardWidth = 160;
                                }

                                return GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: _products.length,
                                  itemBuilder: (context, index) {
                                    return _ProductCard(
                                      product: _products[index],
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ProductDetailScreen(
                                              productId: _products[index].id,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey[200],
                child: product.images.isNotEmpty
                    ? Image.network(
                        product.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          );
                        },
                      )
                    : const Icon(
                        Icons.shopping_bag,
                        size: 48,
                        color: Colors.grey,
                      ),
              ),
            ),

            // Información del producto
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₡${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.sellerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
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
}
