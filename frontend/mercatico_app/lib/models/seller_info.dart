/// Modelo de información del vendedor (para compradores)
class SellerInfo {
  final String id;
  final String businessName;
  final String description;
  final String? logoUrl;
  final String province;
  final String canton;
  final String district;
  final String address;
  final bool offersPickup;
  final bool offersDelivery;
  final double ratingAvg;
  final int ratingCount;

  SellerInfo({
    required this.id,
    required this.businessName,
    this.description = '',
    this.logoUrl,
    this.province = '',
    this.canton = '',
    this.district = '',
    this.address = '',
    this.offersPickup = true,
    this.offersDelivery = false,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
  });

  /// Crear desde JSON
  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    // Helper para parsear rating_avg que puede venir como string o número
    double parseRating(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return SellerInfo(
      id: json['id'] ?? '',
      businessName: json['business_name'] ?? '',
      description: json['description'] ?? '',
      logoUrl: json['logo'],
      province: json['province'] ?? '',
      canton: json['canton'] ?? '',
      district: json['district'] ?? '',
      address: json['address'] ?? '',
      offersPickup: json['offers_pickup'] ?? true,
      offersDelivery: json['offers_delivery'] ?? false,
      ratingAvg: parseRating(json['rating_avg']),
      ratingCount: json['rating_count'] ?? 0,
    );
  }

  /// Dirección completa formateada
  String get fullAddress {
    List<String> parts = [];
    if (address.isNotEmpty) parts.add(address);
    if (district.isNotEmpty) parts.add(district);
    if (canton.isNotEmpty) parts.add(canton);
    if (province.isNotEmpty) parts.add(province);
    return parts.join(', ');
  }

  /// Verificar si tiene dirección completa
  bool get hasAddress {
    return address.isNotEmpty ||
           district.isNotEmpty ||
           canton.isNotEmpty ||
           province.isNotEmpty;
  }
}
