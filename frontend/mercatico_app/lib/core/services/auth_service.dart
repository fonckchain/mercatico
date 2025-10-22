import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Servicio de autenticación que maneja login, registro y tokens
class AuthService {
  final ApiService _apiService = ApiService();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';

  /// Login de usuario
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);

      // Guardar tokens
      if (response.containsKey('access') && response.containsKey('refresh')) {
        await _saveTokens(response['access'], response['refresh']);
        _apiService.setAccessToken(response['access']);

        // Obtener datos del usuario
        final userData = await _apiService.getCurrentUser();
        await _saveUserData(userData);

        return {
          'success': true,
          'user': userData,
        };
      } else {
        return {
          'success': false,
          'error': 'Respuesta inválida del servidor',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Registro de usuario
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String role, // 'BUYER' o 'SELLER'
    String? businessName,
    String? businessDescription,
    String? sinpeNumber,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final userData = {
        'email': email,
        'password': password,
        'password_confirm': password, // API requires confirmation
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'user_type': role, // Backend expects 'user_type' not 'role'
        if (businessName != null) 'business_name': businessName,
        if (sinpeNumber != null) 'sinpe_number': sinpeNumber,
        if (latitude != null && longitude != null) ...{
          'latitude': latitude.toStringAsFixed(6),
          'longitude': longitude.toStringAsFixed(6),
        },
      };

      final response = await _apiService.register(userData);

      // Después del registro exitoso, hacer login automático
      return await login(email, password);
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
    _apiService.clearAccessToken();
  }

  /// Verificar si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Obtener token de acceso guardado
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Obtener datos del usuario guardados
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      // Simple parsing - en producción usar json.decode
      return {}; // TODO: Implementar parsing correcto
    }
    return null;
  }

  /// Guardar tokens en SharedPreferences
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  /// Guardar datos del usuario
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    // Simple storage - en producción usar json.encode
    await prefs.setString(_userDataKey, userData.toString());
  }

  /// Inicializar servicio (cargar token si existe)
  Future<void> initialize() async {
    final token = await getAccessToken();
    if (token != null) {
      _apiService.setAccessToken(token);
    }
  }
}
