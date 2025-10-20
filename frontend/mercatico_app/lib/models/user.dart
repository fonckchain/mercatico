/// Modelo de usuario
class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String userType; // 'BUYER' o 'SELLER'
  final String? businessName;
  final String? businessDescription;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.userType,
    this.businessName,
    this.businessDescription,
    required this.isActive,
  });

  /// Crear usuario desde JSON del API
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
      userType: json['user_type'] ?? 'BUYER',
      businessName: json['business_name'],
      businessDescription: json['business_description'],
      isActive: json['is_active'] ?? true,
    );
  }

  /// Nombre completo del usuario
  String get fullName => '$firstName $lastName';

  /// Verificar si es vendedor
  bool get isSeller => userType == 'SELLER';

  /// Verificar si es comprador
  bool get isBuyer => userType == 'BUYER';
}
