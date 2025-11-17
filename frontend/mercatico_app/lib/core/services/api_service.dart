import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

/// Servicio centralizado para llamadas a la API (Singleton)
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  String? _accessToken;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: ApiConstants.headers,
      ),
    );

    // Interceptor para agregar token automáticamente
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('🌐 API Request: ${options.method} ${options.uri}');
          print('📦 Request Data: ${options.data}');

          // Si no hay token en memoria, intentar cargarlo de SharedPreferences
          if (_accessToken == null) {
            final prefs = await SharedPreferences.getInstance();
            _accessToken = prefs.getString('access_token');
            if (_accessToken != null) {
              print('🔑 Token cargado desde SharedPreferences');
            }
          }

          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ API Response: ${response.statusCode} ${response.requestOptions.uri}');
          print('📥 Response Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('❌ API Error: ${error.response?.statusCode} ${error.requestOptions.uri}');
          print('📄 Error Response: ${error.response?.data}');
          print('🔍 Error Message: ${error.message}');

          // Manejar errores 401 (no autorizado)
          if (error.response?.statusCode == 401) {
            // TODO: Intentar refrescar el token
            print('Error 401: Token expirado o inválido');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Establecer token de acceso
  void setAccessToken(String token) {
    _accessToken = token;
  }

  /// Limpiar token de acceso
  void clearAccessToken() {
    _accessToken = null;
  }

  // ==================== AUTH ====================

  /// Login de usuario
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );
    return response.data;
  }

  /// Registro de usuario
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await _dio.post(
      ApiConstants.register,
      data: userData,
    );
    return response.data;
  }

  /// Obtener perfil del usuario actual
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get(ApiConstants.userMe);
    return response.data;
  }

  /// Actualizar perfil del usuario actual
  Future<Map<String, dynamic>> updateCurrentUser(Map<String, dynamic> userData) async {
    final response = await _dio.patch(ApiConstants.userMe, data: userData);
    return response.data;
  }

  // ==================== PRODUCTS ====================

  /// Obtener lista de productos
  Future<Map<String, dynamic>> getProducts({
    int? page,
    String? search,
    String? category,
    String? seller,
  }) async {
    final queryParams = <String, dynamic>{};
    if (page != null) queryParams['page'] = page;
    if (search != null) queryParams['search'] = search;
    if (category != null) queryParams['category'] = category;
    if (seller != null) queryParams['seller'] = seller;

    final response = await _dio.get(
      ApiConstants.products,
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Obtener detalle de un producto
  Future<Map<String, dynamic>> getProduct(String id) async {
    final response = await _dio.get(ApiConstants.productDetail(id));
    return response.data;
  }

  /// Crear producto (vendedores)
  Future<Map<String, dynamic>> createProduct(
      Map<String, dynamic> productData) async {
    final response = await _dio.post(
      ApiConstants.products,
      data: productData,
    );
    return response.data;
  }

  /// Actualizar producto (vendedores)
  Future<Map<String, dynamic>> updateProduct(
      String id, Map<String, dynamic> productData) async {
    final response = await _dio.put(
      ApiConstants.productDetail(id),
      data: productData,
    );
    return response.data;
  }

  /// Eliminar producto (vendedores)
  Future<void> deleteProduct(String id) async {
    await _dio.delete(ApiConstants.productDetail(id));
  }

  /// Obtener mis productos (vendedores)
  Future<Map<String, dynamic>> getMyProducts({bool includeInactive = false}) async {
    final queryParams = <String, dynamic>{};
    if (includeInactive) {
      queryParams['include_inactive'] = 'true';
    }

    final response = await _dio.get(
      '${ApiConstants.products}my_products/',
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Subir imágenes a un producto
  Future<Map<String, dynamic>> uploadProductImages(
    String productId,
    List<XFile> imageFiles,
  ) async {
    final formData = FormData();

    // Agregar cada imagen al FormData usando bytes (compatible con web)
    for (final xFile in imageFiles) {
      final bytes = await xFile.readAsBytes();
      // Obtener nombre del archivo (compatible con web y móvil)
      final fileName = xFile.name.split('/').last.split('\\').last;
      
      formData.files.add(
        MapEntry(
          'images',
          MultipartFile.fromBytes(
            bytes,
            filename: fileName,
          ),
        ),
      );
    }

    final response = await _dio.post(
      '${ApiConstants.productDetail(productId)}/upload_images/',
      data: formData,
    );
    return response.data;
  }

  /// Eliminar una imagen de un producto
  Future<Map<String, dynamic>> deleteProductImage(
    String productId,
    String imageUrl,
  ) async {
    final response = await _dio.delete(
      '${ApiConstants.productDetail(productId)}/delete_image/',
      data: {'image_url': imageUrl},
    );
    return response.data;
  }

  /// Obtener lista de categorías
  Future<Map<String, dynamic>> getCategories() async {
    final response = await _dio.get(ApiConstants.categories);
    return response.data;
  }

  // ==================== SELLER PROFILE ====================

  /// Obtener perfil del vendedor actual
  Future<Map<String, dynamic>> getSellerProfile() async {
    final response = await _dio.get(ApiConstants.userMe);
    return response.data['seller_profile'] ?? {};
  }

  /// Actualizar perfil del vendedor
  Future<Map<String, dynamic>> updateSellerProfile(
    Map<String, dynamic> profileData,
  ) async {
    final response = await _dio.patch(
      ApiConstants.userMe,
      data: {
        'seller_profile': profileData,
      },
    );
    return response.data;
  }

  // ==================== ORDERS ====================

  /// Obtener lista de órdenes
  Future<Map<String, dynamic>> getOrders({String? status}) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;

    final response = await _dio.get(
      ApiConstants.orders,
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Crear nueva orden
  Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> orderData, {XFile? paymentProofFile}) async {
    // If there's a payment proof image, use FormData
    if (paymentProofFile != null) {
      // Create a copy of orderData to modify
      final Map<String, dynamic> formDataMap = {};

      // Add all fields except items
      orderData.forEach((key, value) {
        if (key != 'items') {
          formDataMap[key] = value;
        }
      });

      // Add items as JSON string
      formDataMap['items'] = jsonEncode(orderData['items']);

      // Add payment proof file using bytes (compatible with web)
      final bytes = await paymentProofFile.readAsBytes();
      final fileName = paymentProofFile.name.split('/').last.split('\\').last;
      formDataMap['payment_proof'] = MultipartFile.fromBytes(
        bytes,
        filename: fileName.isNotEmpty 
            ? fileName 
            : 'payment_proof_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final formData = FormData.fromMap(formDataMap);

      final response = await _dio.post(
        ApiConstants.orders,
        data: formData,
      );
      return response.data;
    } else {
      // Regular JSON request without file
      final response = await _dio.post(
        ApiConstants.orders,
        data: orderData,
      );
      return response.data;
    }
  }

  /// Obtener historial de compras del usuario
  Future<List<dynamic>> getMyPurchases() async {
    final response = await _dio.get('${ApiConstants.orders}my_purchases/');
    if (response.data is Map && response.data.containsKey('results')) {
      return response.data['results'] as List<dynamic>;
    }
    return response.data as List<dynamic>;
  }

  /// Obtener detalles de una orden específica
  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    final response = await _dio.get('${ApiConstants.orders}$orderId/');
    return response.data;
  }

  /// Obtener historial de ventas del vendedor
  Future<List<dynamic>> getMySales() async {
    final response = await _dio.get('${ApiConstants.orders}my_sales/');
    if (response.data is Map && response.data.containsKey('results')) {
      return response.data['results'] as List<dynamic>;
    }
    return response.data as List<dynamic>;
  }

  /// Actualizar estado de una orden
  Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    String status, {
    String? notes,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.orders}$orderId/update_status/',
      data: {
        'status': status,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data;
  }

  /// Confirmar pago de una orden
  Future<Map<String, dynamic>> confirmOrderPayment(String orderId) async {
    final response = await _dio.post(
      '${ApiConstants.orders}$orderId/confirm_payment/',
    );
    return response.data;
  }

  /// Calcular costo de envío basado en distancia
  Future<Map<String, dynamic>> calculateDeliveryCost({
    required String sellerLatitude,
    required String sellerLongitude,
    required String buyerLatitude,
    required String buyerLongitude,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.orders}calculate_delivery_cost/',
      data: {
        'seller_latitude': sellerLatitude,
        'seller_longitude': sellerLongitude,
        'buyer_latitude': buyerLatitude,
        'buyer_longitude': buyerLongitude,
      },
    );
    return response.data;
  }

  // ==================== PAYMENTS ====================

  /// Subir comprobante de pago
  Future<Map<String, dynamic>> uploadPaymentReceipt(
    String orderId,
    XFile imageFile,
  ) async {
    // Read bytes from XFile (compatible with web)
    final bytes = await imageFile.readAsBytes();
    final fileName = imageFile.name.split('/').last.split('\\').last;
    
    final formData = FormData.fromMap({
      'order_id': orderId,
      'receipt_image': MultipartFile.fromBytes(
        bytes,
        filename: fileName.isNotEmpty 
            ? fileName 
            : 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    });

    final response = await _dio.post(
      ApiConstants.paymentUpload,
      data: formData,
    );
    return response.data;
  }

  /// Revisar comprobante manualmente
  Future<Map<String, dynamic>> reviewPaymentReceipt(
    String receiptId,
    bool approved, {
    String? notes,
  }) async {
    final response = await _dio.post(
      ApiConstants.paymentManualReview(receiptId),
      data: {
        'approved': approved,
        if (notes != null) 'notes': notes,
      },
    );
    return response.data;
  }

  /// Obtener comprobantes pendientes (vendedores)
  Future<Map<String, dynamic>> getPendingReceipts() async {
    final response = await _dio.get(ApiConstants.paymentPending);
    return response.data;
  }

  // ==================== REVIEWS ====================

  /// Obtener reseñas
  Future<Map<String, dynamic>> getReviews({String? seller}) async {
    final queryParams = <String, dynamic>{};
    if (seller != null) queryParams['seller'] = seller;

    final response = await _dio.get(
      ApiConstants.reviews,
      queryParameters: queryParams,
    );
    return response.data;
  }

  /// Crear reseña
  Future<Map<String, dynamic>> createReview(
      Map<String, dynamic> reviewData) async {
    final response = await _dio.post(
      ApiConstants.reviews,
      data: reviewData,
    );
    return response.data;
  }

  /// Obtener reseñas de un vendedor
  Future<Map<String, dynamic>> getSellerReviews(String sellerId) async {
    final response = await _dio.get(ApiConstants.sellerReviews(sellerId));
    return response.data;
  }

  // ==================== HEALTH ====================

  /// Verificar estado de la API
  Future<Map<String, dynamic>> healthCheck() async {
    // Health endpoint is not under /api, so we use an absolute URL
    final healthDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    final response = await healthDio.get(ApiConstants.healthUrl);
    return response.data;
  }
}
