import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/api_service.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/seller_app_bar.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers
  late TextEditingController _businessNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _sinpeNumberController;

  // GPS Coordinates
  double? _latitude;
  double? _longitude;

  // Opciones
  bool _acceptsCash = false;
  bool _acceptsSinpe = true;
  bool _offersPickup = true;
  bool _offersDelivery = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProfile();
  }

  void _initializeControllers() {
    _businessNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _sinpeNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _sinpeNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _apiService.getCurrentUser();
      if (user['seller_profile'] != null) {
        final profile = user['seller_profile'];

        setState(() {
          _businessNameController.text = profile['business_name'] ?? '';
          _descriptionController.text = profile['description'] ?? '';
          _sinpeNumberController.text = profile['sinpe_number'] ?? '';
          _latitude = profile['latitude'] != null
              ? double.tryParse(profile['latitude'].toString())
              : null;
          _longitude = profile['longitude'] != null
              ? double.tryParse(profile['longitude'].toString())
              : null;
          _acceptsCash = profile['accepts_cash'] ?? false;
          _acceptsSinpe = profile['accepts_sinpe'] ?? true;
          _offersPickup = profile['offers_pickup'] ?? true;
          _offersDelivery = profile['offers_delivery'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar perfil: $e';
        _isLoading = false;
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar que al menos una opción de entrega esté seleccionada
    if (!_offersPickup && !_offersDelivery) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes ofrecer al menos una opción: recogida o entrega'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final profileData = <String, dynamic>{
        'business_name': _businessNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'sinpe_number': _sinpeNumberController.text.trim(),
        'accepts_cash': _acceptsCash,
        'accepts_sinpe': _acceptsSinpe,
        'offers_pickup': _offersPickup,
        'offers_delivery': _offersDelivery,
      };

      // Only include GPS coordinates if they are not null
      // Round to 6 decimal places to match backend validation
      if (_latitude != null && _longitude != null) {
        profileData['latitude'] = _latitude!.toStringAsFixed(6);
        profileData['longitude'] = _longitude!.toStringAsFixed(6);
      }

      await _apiService.updateSellerProfile(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() {
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al guardar perfil: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SellerAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del Negocio
                    _buildSectionTitle('Información del Negocio'),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Negocio',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El nombre del negocio es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        hintText: 'Describe tu negocio...',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Información de Pago
                    _buildSectionTitle('Información de Pago'),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _sinpeNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Número SINPE Móvil',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_android),
                        hintText: '88888888',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El número SINPE es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Acepto efectivo'),
                      subtitle: const Text(
                        'Acepto pagos en efectivo al momento de la entrega (valor por defecto para nuevos productos)',
                      ),
                      value: _acceptsCash,
                      onChanged: (value) {
                        setState(() {
                          _acceptsCash = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                    const SizedBox(height: 8),

                    SwitchListTile(
                      title: const Text('Acepto SINPE Móvil'),
                      subtitle: const Text(
                        'Acepto pagos con SINPE Móvil (valor por defecto para nuevos productos)',
                      ),
                      value: _acceptsSinpe,
                      onChanged: (value) {
                        setState(() {
                          _acceptsSinpe = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                    const SizedBox(height: 24),

                    // Ubicación del Negocio
                    _buildSectionTitle('Ubicación del Negocio'),
                    const Text(
                      'Esta ubicación se usará como punto de recogida predeterminado',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // Location selector button
                    OutlinedButton.icon(
                      onPressed: _openLocationPicker,
                      icon: const Icon(Icons.map),
                      label: Text(
                        _latitude != null && _longitude != null
                            ? 'Cambiar Ubicación en el Mapa'
                            : 'Seleccionar Ubicación en el Mapa',
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
                    const SizedBox(height: 16),

                    // Display current location if set
                    if (_latitude != null && _longitude != null) ...[
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
                                    'Ubicación seleccionada:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lat: ${_latitude!.toStringAsFixed(6)}\nLng: ${_longitude!.toStringAsFixed(6)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Opciones de Entrega
                    _buildSectionTitle('Opciones de Entrega'),
                    const Text(
                      'Selecciona cómo entregas tus productos',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),

                    SwitchListTile(
                      title: const Text('Ofrecer Recogida'),
                      subtitle: const Text(
                        'Los clientes pueden recoger en mi ubicación',
                      ),
                      value: _offersPickup,
                      onChanged: (value) {
                        setState(() {
                          _offersPickup = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),

                    SwitchListTile(
                      title: const Text('Ofrecer Entrega'),
                      subtitle: const Text(
                        'Entrego productos a domicilio',
                      ),
                      value: _offersDelivery,
                      onChanged: (value) {
                        setState(() {
                          _offersDelivery = value;
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

                    // Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Guardar Cambios',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
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
