// API Test Screen for debugging connectivity issues
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/network_helper.dart';
import '../config/api_config.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String _results = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Connectivity Test'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Configuration Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Base URL: ${ApiConfig.baseUrl}'),
                    Text('API Base URL: ${ApiConfig.apiBaseUrl}'),
                    Text('Development Mode: ${ApiConfig.isDevelopment}'),
                    Text('Logging Enabled: ${ApiConfig.enableLogging}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Buttons
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnectivity,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Test Connectivity'),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Test Login Endpoint'),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testPrescriptionEndpoints,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Test Prescription Endpoints'),
            ),
            
            const SizedBox(height: 16),
            
            // Results
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _results.isEmpty ? 'No tests run yet.' : _results,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnectivity() async {
    setState(() {
      _isLoading = true;
      _results = 'Testing connectivity...\n';
    });

    try {
      // Test network connectivity
      final hasInternet = await NetworkHelper.hasInternetConnection();
      _appendResult('Internet Connection: ${hasInternet ? "✓" : "✗"}');

      if (hasInternet) {
        // Test server reachability
        final serverReachable = await NetworkHelper.isServerReachable();
        _appendResult('Server Reachable: ${serverReachable ? "✓" : "✗"}');

        // Test API health
        final apiHealthy = await NetworkHelper.isApiHealthy();
        _appendResult('API Healthy: ${apiHealthy ? "✓" : "✗"}');

        // Test API service connection
        final connectionResult = await _apiService.testConnection();
        _appendResult('API Service Test: ${connectionResult.isSuccess ? "✓" : "✗"}');
        if (!connectionResult.isSuccess) {
          _appendResult('Error: ${connectionResult.error}');
        }
      }

      // Get comprehensive health check
      final healthCheck = await _apiService.checkSystemHealth();
      _appendResult('\nSystem Health Check:');
      _appendResult('Message: ${healthCheck['message']}');
      _appendResult('Timestamp: ${healthCheck['timestamp']}');

    } catch (e) {
      _appendResult('Test failed with error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
    });

    _appendResult('\nTesting login endpoint...');

    try {
      final result = await _apiService.login('test@example.com', 'testpassword');
      _appendResult('Login Test: ${result.isSuccess ? "✓" : "✗"}');
      if (!result.isSuccess) {
        _appendResult('Login Error: ${result.error}');
      }
    } catch (e) {
      _appendResult('Login test failed: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testPrescriptionEndpoints() async {
    setState(() {
      _isLoading = true;
    });

    _appendResult('\nTesting prescription endpoints...');

    try {
      // Test prescription status endpoint (will fail without valid ID, but tests connectivity)
      final statusResult = await _apiService.getPrescriptionStatus(1);
      _appendResult('Prescription Status Endpoint: ${statusResult.statusCode != 0 ? "✓" : "✗"}');
      if (statusResult.statusCode == 0) {
        _appendResult('Status Error: ${statusResult.error}');
      }

      // Test medicine suggestions endpoint
      final suggestionsResult = await _apiService.getMedicineSuggestions(1);
      _appendResult('Medicine Suggestions Endpoint: ${suggestionsResult.statusCode != 0 ? "✓" : "✗"}');
      if (suggestionsResult.statusCode == 0) {
        _appendResult('Suggestions Error: ${suggestionsResult.error}');
      }

    } catch (e) {
      _appendResult('Prescription endpoints test failed: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _appendResult(String result) {
    setState(() {
      _results += '$result\n';
    });
  }
}
