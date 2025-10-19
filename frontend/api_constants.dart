/// Constantes de API para MercaTico
class ApiConstants {
  // Base URLs
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const String baseUrlAndroidEmulator = 'http://10.0.2.2:8000/api';

  // Determinar URL base según la plataforma
  static String get apiBaseUrl {
    // TODO: Detectar plataforma y devolver URL apropiada
    return baseUrl;
  }

  // Auth endpoints
  static const String login = '/token/';
  static const String refresh = '/token/refresh/';
  static const String verify = '/token/verify/';
  static const String register = '/auth/register/';

  // User endpoints
  static const String users = '/auth/users/';
  static const String userMe = '/auth/users/me/';
  static const String sellers = '/auth/sellers/';

  // Product endpoints
  static const String products = '/products/';
  static String productDetail(String id) => '/products/$id/';
  static const String categories = '/products/categories/';

  // Order endpoints
  static const String orders = '/orders/';
  static String orderDetail(String id) => '/orders/$id/';
  static String orderUpdateStatus(String id) => '/orders/$id/update_status/';
  static const String myPurchases = '/orders/my_purchases/';
  static const String mySales = '/orders/my_sales/';

  // Payment endpoints
  static const String paymentReceipts = '/payments/receipts/';
  static const String paymentUpload = '/payments/receipts/upload/';
  static String paymentDetail(String id) => '/payments/receipts/$id/';
  static String paymentManualReview(String id) =>
      '/payments/receipts/$id/manual_review/';
  static const String paymentPending = '/payments/receipts/pending/';

  // Review endpoints
  static const String reviews = '/reviews/';
  static String reviewDetail(String id) => '/reviews/$id/';
  static const String myReviews = '/reviews/my_reviews/';
  static String sellerReviews(String sellerId) =>
      '/reviews/seller_reviews/?seller_id=$sellerId';
  static String reportReview(String id) => '/reviews/$id/report/';

  // Health check
  static const String health = '/health/';

  // Headers
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Map<String, String> authHeaders(String token) => {
        ...headers,
        'Authorization': 'Bearer $token',
      };
}
