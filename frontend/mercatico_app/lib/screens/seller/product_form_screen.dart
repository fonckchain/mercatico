import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/api_service.dart';
import '../../models/product.dart';
import '../../widgets/location_picker.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product; // Si es null, es crear; si tiene valor, es editar

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  String? _selectedCategoryId;
  bool _isActive = true;
  bool _showStock = false;
  bool _isLoading = false;
  bool _loadingCategories = true;
  String? _errorMessage;

  // Map category IDs to names, loaded dynamically from backend
  Map<String, String> _categories = {};

  // GPS location
  double? _latitude;
  double? _longitude;
  bool _loadingSellerLocation = true;

  List<String> get _categoryIds => _categories.keys.toList();
  List<String> get _categoryNames => _categories.values.toList();

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _priceController = TextEditingController(
      text: widget.product != null ? widget.product!.price.toString() : '',
    );
    _stockController = TextEditingController(
      text: widget.product != null ? widget.product!.stock.toString() : '',
    );

    // Load other product data if editing (but NOT category yet)
    if (widget.product != null) {
      _isActive = widget.product!.isActive;
      _showStock = widget.product!.showStock;
      // Load product location if available
      _latitude = widget.product!.latitude;
      _longitude = widget.product!.longitude;
      _loadingSellerLocation = false;
    } else {
      // If creating new product, load seller's default location
      _loadSellerLocation();
    }

    // Load categories from backend (will set category after loading)
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await _apiService.getCategories();

      if (response['results'] != null && response['results'] is List) {
        setState(() {
          _categories = {
            for (var cat in response['results'])
              cat['id'].toString(): cat['name'].toString()
          };

          // Set category based on context
          if (widget.product != null) {
            // Editing: use product's category if it exists in loaded categories
            final productCategoryId = widget.product!.category;
            if (_categories.containsKey(productCategoryId)) {
              _selectedCategoryId = productCategoryId;
            } else {
              // Category doesn't exist, use first available
              _selectedCategoryId = _categories.keys.first;
            }
          } else {
            // Creating: use first category as default
            if (_categories.isNotEmpty) {
              _selectedCategoryId = _categories.keys.first;
            }
          }

          _loadingCategories = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar categorías: $e';
        _loadingCategories = false;
      });
    }
  }

  Future<void> _loadSellerLocation() async {
    try {
      final profile = await _apiService.getSellerProfile();
      setState(() {
        _latitude = profile['latitude'] != null
            ? double.tryParse(profile['latitude'].toString())
            : null;
        _longitude = profile['longitude'] != null
            ? double.tryParse(profile['longitude'].toString())
            : null;
        _loadingSellerLocation = false;
      });
    } catch (e) {
      setState(() {
        _loadingSellerLocation = false;
      });
    }
  }

  Future<void> _openLocationPicker() async {
    final initialLocation = (_latitude != null && _longitude != null)
        ? LatLng(_latitude!, _longitude!)
        : null;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPicker(
          initialLocation: initialLocation,
          onLocationSelected: (location, address) {
            setState(() {
              _latitude = location.latitude;
              _longitude = location.longitude;
            });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      setState(() {
        _errorMessage = 'Por favor selecciona una categoría';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'stock': int.parse(_stockController.text),
        'show_stock': _showStock,
        'category': _selectedCategoryId,  // Send category UUID
        'is_available': _isActive,  // Backend expects 'is_available' not 'is_active'
        'accepts_cash': true,  // Default value
        'images': [],  // Default empty array
        'latitude': _latitude?.toString(),
        'longitude': _longitude?.toString(),
      };

      if (widget.product == null) {
        // Crear nuevo producto
        await _apiService.createProduct(productData);
        if (mounted) {
          Navigator.of(context).pop(true); // true indica que se creó exitosamente
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Actualizar producto existente
        await _apiService.updateProduct(widget.product!.id, productData);
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al guardar producto: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nombre del producto
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre del producto';
                  }
                  if (value.length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  if (value.length < 10) {
                    return 'La descripción debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Precio
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio (₡)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments),
                  hintText: '0.00',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el precio';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'El precio debe ser mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Stock
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad en stock',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la cantidad en stock';
                  }
                  final stock = int.tryParse(value);
                  if (stock == null || stock < 0) {
                    return 'El stock debe ser 0 o mayor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Categoría
              if (_loadingCategories)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _categories.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,  // UUID
                      child: Text(entry.value),  // Name
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor selecciona una categoría';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),

              // Ubicación del producto
              const Text(
                'Ubicación del Producto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecciona dónde se encuentra el producto',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              // Location selector button
              if (_loadingSellerLocation)
                const Center(child: CircularProgressIndicator())
              else
                OutlinedButton.icon(
                  onPressed: _openLocationPicker,
                  icon: const Icon(Icons.map),
                  label: Text(
                    _latitude != null && _longitude != null
                        ? 'Cambiar Ubicación'
                        : 'Seleccionar Ubicación',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // Display current location if set
              if (_latitude != null && _longitude != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ubicación seleccionada',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Estado activo/inactivo
              SwitchListTile(
                title: const Text('Producto activo'),
                subtitle: Text(
                  _isActive
                      ? 'El producto será visible para los compradores'
                      : 'El producto estará oculto',
                ),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                activeColor: Colors.green,
              ),
              const SizedBox(height: 8),

              // Mostrar stock
              SwitchListTile(
                title: const Text('Mostrar cantidad de stock'),
                subtitle: Text(
                  _showStock
                      ? 'Los compradores verán cuántas unidades hay disponibles'
                      : 'Los compradores solo verán si hay stock o no',
                ),
                value: _showStock,
                onChanged: (value) {
                  setState(() {
                    _showStock = value;
                  });
                },
                activeColor: Colors.green,
              ),

              // Mensaje de error
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Botón guardar
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEditing ? 'Actualizar Producto' : 'Crear Producto',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
