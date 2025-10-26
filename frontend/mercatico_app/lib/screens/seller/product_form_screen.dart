import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/api_service.dart';
import '../../models/product.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/image_picker_widget.dart';

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
  bool _offersPickup = true;
  bool _offersDelivery = false;
  bool _acceptsCash = true; // Valor predeterminado, se cargará del perfil del vendedor
  bool _acceptsSinpe = true; // Valor predeterminado, se cargará del perfil del vendedor
  bool _isLoading = false;
  bool _loadingCategories = true;
  String? _errorMessage;

  // Map category IDs to names, loaded dynamically from backend
  Map<String, String> _categories = {};

  // GPS location
  double? _latitude;
  double? _longitude;
  bool _loadingSellerLocation = true;

  // Images
  List<File> _selectedImageFiles = [];
  List<String> _existingImageUrls = [];
  bool _uploadingImages = false;

  List<String> get _categoryIds => _categories.keys.toList();
  List<String> get _categoryNames => _categories.values.toList();

  @override
  void initState() {
    super.initState();

    // Initialize controllers (will be populated when loading product details)
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _stockController = TextEditingController();

    // Load categories from backend (will set category after loading)
    _loadCategories();

    // If editing, load full product details
    if (widget.product != null) {
      _loadProductDetails();
    } else {
      // If creating new product, load seller's default location
      _loadSellerLocation();
    }
  }

  Future<void> _loadProductDetails() async {
    try {
      // Load full product details from API to get description and all fields
      final productData = await _apiService.getProduct(widget.product!.id);
      print('🔍 PRODUCT DATA RECEIVED: $productData');
      print('🔍 IMAGES FIELD TYPE: ${productData['images'].runtimeType}');
      print('🔍 IMAGES FIELD VALUE: ${productData['images']}');

      setState(() {
        _nameController.text = productData['name'] ?? '';
        _descriptionController.text = productData['description'] ?? '';
        _priceController.text = productData['price']?.toString() ?? '';
        _stockController.text = productData['stock']?.toString() ?? '';
        _isActive = productData['is_available'] ?? true;
        _showStock = productData['show_stock'] ?? false;
        _offersPickup = productData['offers_pickup'] ?? true;
        _offersDelivery = productData['offers_delivery'] ?? false;
        _acceptsCash = productData['accepts_cash'] ?? true;
        _acceptsSinpe = productData['accepts_sinpe'] ?? true;

        // Parse GPS coordinates
        if (productData['latitude'] != null) {
          _latitude = double.tryParse(productData['latitude'].toString());
        }
        if (productData['longitude'] != null) {
          _longitude = double.tryParse(productData['longitude'].toString());
        }

        // Load existing images
        if (productData['images'] != null && productData['images'] is List) {
          _existingImageUrls = List<String>.from(productData['images']);
          print('DEBUG: Loaded ${_existingImageUrls.length} existing images');
          print('DEBUG: Images: $_existingImageUrls');
        } else {
          print('DEBUG: No images found in product data');
          print('DEBUG: productData[images] = ${productData['images']}');
        }

        _loadingSellerLocation = false;

        // Category will be set after categories are loaded in _loadCategories
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar detalles del producto: $e';
        _loadingSellerLocation = false;
      });
    }
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
        // Cargar valores predeterminados de métodos de pago del perfil del vendedor
        _acceptsCash = profile['accepts_cash'] ?? true;
        _acceptsSinpe = profile['accepts_sinpe'] ?? true;
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
      final productData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'stock': int.parse(_stockController.text),
        'show_stock': _showStock,
        'category': _selectedCategoryId,  // Send category UUID
        'is_available': _isActive,  // Backend expects 'is_available' not 'is_active'
        'accepts_cash': _acceptsCash,  // Valor del switch
        'accepts_sinpe': _acceptsSinpe,  // Valor del switch
        'offers_pickup': _offersPickup,
        'offers_delivery': _offersDelivery,
        'images': _existingImageUrls,  // Mantener imágenes existentes
      };

      // Only include GPS coordinates if they are not null
      // Round to 6 decimal places to match backend validation
      if (_latitude != null && _longitude != null) {
        productData['latitude'] = _latitude!.toStringAsFixed(6);
        productData['longitude'] = _longitude!.toStringAsFixed(6);
      }

      String productId;

      if (widget.product == null) {
        // Crear nuevo producto
        final response = await _apiService.createProduct(productData);
        productId = response['id'];
      } else {
        // Actualizar producto existente
        await _apiService.updateProduct(widget.product!.id, productData);
        productId = widget.product!.id;
      }

      // Subir nuevas imágenes si hay
      if (_selectedImageFiles.isNotEmpty) {
        setState(() {
          _uploadingImages = true;
        });

        try {
          final imagePaths = _selectedImageFiles.map((file) => file.path).toList();
          await _apiService.uploadProductImages(productId, imagePaths);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Advertencia: Error al subir imágenes: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product == null
              ? 'Producto creado exitosamente'
              : 'Producto actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al guardar producto: $e';
        _isLoading = false;
        _uploadingImages = false;
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

              // Selector de imágenes
              ImagePickerWidget(
                key: ValueKey(_existingImageUrls.length),
                initialImages: _existingImageUrls,
                onImagesChanged: (selectedFiles, existingUrls) {
                  setState(() {
                    _selectedImageFiles = selectedFiles;
                    _existingImageUrls = existingUrls;
                  });
                },
                maxImages: 5,
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

              const SizedBox(height: 16),
              const Text(
                'Opciones de entrega',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Ofrece recogida
              SwitchListTile(
                title: const Text('Ofrece recogida'),
                subtitle: const Text(
                  'El comprador puede recoger el producto en tu ubicación',
                ),
                value: _offersPickup,
                onChanged: (value) {
                  setState(() {
                    _offersPickup = value;
                  });
                },
                activeColor: Colors.green,
              ),

              // Ofrece entrega
              SwitchListTile(
                title: const Text('Ofrece entrega a domicilio'),
                subtitle: const Text(
                  'Puedes enviar el producto a la ubicación del comprador',
                ),
                value: _offersDelivery,
                onChanged: (value) {
                  setState(() {
                    _offersDelivery = value;
                  });
                },
                activeColor: Colors.green,
              ),

              const SizedBox(height: 16),
              const Text(
                'Opciones de pago',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Acepta efectivo
              SwitchListTile(
                title: const Text('Acepta pago en efectivo'),
                subtitle: const Text(
                  'El comprador puede pagar en efectivo al recibir el producto',
                ),
                value: _acceptsCash,
                onChanged: (value) {
                  setState(() {
                    _acceptsCash = value;
                  });
                },
                activeColor: Colors.green,
              ),

              // Acepta SINPE Móvil
              SwitchListTile(
                title: const Text('Acepta SINPE Móvil'),
                subtitle: const Text(
                  'El comprador puede pagar con SINPE Móvil',
                ),
                value: _acceptsSinpe,
                onChanged: (value) {
                  setState(() {
                    _acceptsSinpe = value;
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
                onPressed: (_isLoading || _uploadingImages) ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: (_isLoading || _uploadingImages)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _uploadingImages ? 'Subiendo imágenes...' : 'Guardando...',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
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
