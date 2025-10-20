import 'package:flutter/material.dart';
import 'products/products_screen.dart';
import 'seller/my_products_screen.dart';
import '../core/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _redirectBasedOnUserType();
  }

  Future<void> _redirectBasedOnUserType() async {
    try {
      // Obtener datos del usuario
      final userData = await _apiService.getCurrentUser();
      final userType = userData['user_type'];

      if (!mounted) return;

      // Redirigir según el tipo de usuario
      if (userType == 'SELLER') {
        // Vendedores van a "Mis Productos"
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MyProductsScreen(),
          ),
        );
      } else {
        // Compradores van al catálogo de productos
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ProductsScreen(),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Si hay error, por defecto mostrar productos
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const ProductsScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
