import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../screens/seller/my_products_screen.dart';
import '../screens/seller/sales_history_screen.dart';
import '../screens/seller/seller_profile_screen.dart';

/// AppBar consistente para todas las pantallas de vendedor
class SellerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AuthService _authService = AuthService();

  SellerAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // Remove back button
      title: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/');
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.store, size: 28),
            SizedBox(width: 8),
            Text('MercaTico', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.inventory, color: Colors.white),
          label: const Text('Mis Productos', style: TextStyle(color: Colors.white)),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/my-products');
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.receipt_long, color: Colors.white),
          label: const Text('Mis Ventas', style: TextStyle(color: Colors.white)),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const SalesHistoryScreen(),
              ),
            );
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.person, color: Colors.white),
          label: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const SellerProfileScreen(),
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
      ],
    );
  }
}
