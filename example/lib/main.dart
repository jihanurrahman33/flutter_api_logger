import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter_api_logger/flutter_api_logger.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter API Logger Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Configuration state
  bool _enableLog = true;
  bool _showHeaders = true;
  bool _showBody = true;
  bool _logColor = true;

  // Output
  String _status = 'Ready';

  // HTTP Client
  late http.Client _httpClient;
  
  // Dio Client
  late Dio _dio;

  ApiLoggerConfig get _config => ApiLoggerConfig(
    enableLog: _enableLog,
    showHeaders: _showHeaders,
    showRequestBody: _showBody,
    showResponseBody: _showBody, 
    logColor: _logColor,
  );

  @override
  void initState() {
    super.initState();
    _setupClients();
  }

  void _setupClients() {
    // Re-create clients when config changes (mostly for demo purposes)
    // In real app, you might just update config if supported or simple wrapper.
    // Here our ApiLoggerHttpClient takes config in constructor.
    _httpClient = ApiLoggerHttpClient(config: _config);
    
    _dio = Dio();
    _dio.interceptors.add(ApiLoggerDioInterceptor(config: _config));
  }
  
  void _updateConfig() {
    setState(() {
      _setupClients();
      _status = 'Configuration updated';
    });
  }

  Future<void> _makeHttpRequest() async {
    setState(() => _status = 'Sending HTTP request...');
    try {
      final response = await _httpClient.post(
        Uri.parse('https://jsonplaceholder.typicode.com/posts'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer secret_token'},
        body: jsonEncode({'title': 'foo', 'body': 'bar', 'userId': 1}),
      );
      setState(() => _status = 'HTTP Response: ${response.statusCode}');
    } catch (e) {
      setState(() => _status = 'HTTP Error: $e');
    }
  }

  Future<void> _makeDioRequest() async {
    setState(() => _status = 'Sending Dio request...');
    try {
      final response = await _dio.get(
        'https://jsonplaceholder.typicode.com/users/1',
        options: Options(headers: {'Authorization': 'Bearer secret_user_token'}),
      );
      setState(() => _status = 'Dio Response: ${response.statusCode}');
    } catch (e) {
      setState(() => _status = 'Dio Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Logger Demo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
                    SwitchListTile(
                      title: const Text('Enable Logging'),
                      value: _enableLog,
                      onChanged: (v) { _enableLog = v; _updateConfig(); },
                    ),
                    SwitchListTile(
                      title: const Text('Show Headers'),
                      value: _showHeaders,
                      onChanged: (v) { _showHeaders = v; _updateConfig(); },
                    ),
                    SwitchListTile(
                      title: const Text('Show Body'),
                      value: _showBody,
                      onChanged: (v) { _showBody = v; _updateConfig(); },
                    ),
                    SwitchListTile(
                      title: const Text('Log Color'),
                      value: _logColor,
                      onChanged: (v) { _logColor = v; _updateConfig(); },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Status: $_status', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _makeHttpRequest,
              icon: const Icon(Icons.http),
              label: const Text('Make HTTP Request (POST)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _makeDioRequest,
              icon: const Icon(Icons.cloud_download),
              label: const Text('Make Dio Request (GET)'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Check your console to see the logs!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
