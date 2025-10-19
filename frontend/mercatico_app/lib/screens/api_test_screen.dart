import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/services/api_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final ApiService _apiService = ApiService();
  String _status = 'No probado';
  bool _isLoading = false;
  Map<String, dynamic>? _apiResponse;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Probando...';
    });

    try {
      // Intentar conectar al endpoint raíz
      final response = await _apiService.healthCheck();
      setState(() {
        _status = 'Conexión exitosa';
        _apiResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _apiResponse = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de API'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'URL de la API:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              width: double.infinity,
              child: Text(
                ApiConstants.apiBaseUrl,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Estado de conexión:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _status.contains('exitosa')
                    ? Colors.green[100]
                    : _status.contains('Error')
                        ? Colors.red[100]
                        : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              width: double.infinity,
              child: Text(
                _status,
                style: TextStyle(
                  fontSize: 16,
                  color: _status.contains('exitosa')
                      ? Colors.green[900]
                      : _status.contains('Error')
                          ? Colors.red[900]
                          : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testConnection,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Probar Conexión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (_apiResponse != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Respuesta de la API:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: Text(
                      _apiResponse.toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
