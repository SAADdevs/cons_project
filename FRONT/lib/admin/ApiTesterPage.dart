import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiTesterPage extends StatefulWidget {
  const ApiTesterPage({Key? key}) : super(key: key);

  @override
  State<ApiTesterPage> createState() => _ApiTesterPageState();
}

class _ApiTesterPageState extends State<ApiTesterPage> {
  final TextEditingController _baseUrlController = TextEditingController(text: 'http://192.168.1.11:5000');
  final TextEditingController _endpointController = TextEditingController(text: '/api/doctors/with-names');
  final TextEditingController _methodController = TextEditingController(text: 'GET');
  final TextEditingController _bodyController = TextEditingController();
  
  bool _isLoading = false;
  String _responseText = '';
  int _statusCode = 0;
  
  // List of predefined endpoints
  final List<Map<String, dynamic>> _predefinedEndpoints = [
    {
      'name': 'Get All Doctors',
      'endpoint': '/api/doctors',
      'method': 'GET'
    },
    {
      'name': 'Get Doctors with Names',
      'endpoint': '/api/doctors/with-names',
      'method': 'GET'
    },
    {
      'name': 'Get Verified Doctors',
      'endpoint': '/api/doctors/verified',
      'method': 'GET'
    },
    {
      'name': 'Get Available Doctors',
      'endpoint': '/api/doctors/available/list',
      'method': 'GET'
    },
    {
      'name': 'Get Doctor by ID',
      'endpoint': '/api/doctors/1',
      'method': 'GET'
    },
    {
      'name': 'Approve Doctor',
      'endpoint': '/api/doctors/approve/1',
      'method': 'PUT'
    },
    {
      'name': 'Unverify Doctor',
      'endpoint': '/api/doctors/unverify/1',
      'method': 'PUT'
    },
    {
      'name': 'Update Availability',
      'endpoint': '/api/doctors/update-availability',
      'method': 'PUT',
      'body': '{"doctor_id": 1, "is_available": true}'
    },
    {
      'name': 'Get Doctors by Specialty',
      'endpoint': '/api/doctors/specialty/heart',
      'method': 'GET'
    }
  ];
  
  @override
  void dispose() {
    _baseUrlController.dispose();
    _endpointController.dispose();
    _methodController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
  
  Future<void> _testApi() async {
    setState(() {
      _isLoading = true;
      _responseText = '';
      _statusCode = 0;
    });
    
    final baseUrl = _baseUrlController.text.trim();
    final endpoint = _endpointController.text.trim();
    final method = _methodController.text.trim().toUpperCase();
    final body = _bodyController.text.trim();
    
    final url = Uri.parse('$baseUrl$endpoint');
    
    try {
      http.Response response;
      
      switch (method) {
        case 'GET':
          response = await http.get(url);
          break;
        case 'POST':
          response = await http.post(
            url, 
            headers: {'Content-Type': 'application/json'},
            body: body.isNotEmpty ? body : null
          );
          break;
        case 'PUT':
          response = await http.put(
            url, 
            headers: {'Content-Type': 'application/json'},
            body: body.isNotEmpty ? body : null
          );
          break;
        case 'DELETE':
          response = await http.delete(url);
          break;
        default:
          throw Exception('Unsupported method: $method');
      }
      
      // Format JSON response for readability
      String prettyResponse = response.body;
      try {
        final jsonObj = json.decode(response.body);
        prettyResponse = const JsonEncoder.withIndent('  ').convert(jsonObj);
      } catch (e) {
        // Not valid JSON, keep as is
      }
      
      setState(() {
        _statusCode = response.statusCode;
        _responseText = prettyResponse;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _responseText = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Tester'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // API Request Section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'API Request',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Base URL input
                  TextField(
                    controller: _baseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      border: OutlineInputBorder(),
                      hintText: 'http://192.168.1.11:5000',
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Predefined endpoints dropdown
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Predefined Endpoints',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      _predefinedEndpoints.length,
                      (index) => DropdownMenuItem(
                        value: index,
                        child: Text(_predefinedEndpoints[index]['name']),
                      ),
                    ),
                    onChanged: (index) {
                      if (index != null) {
                        final endpoint = _predefinedEndpoints[index];
                        _endpointController.text = endpoint['endpoint'];
                        _methodController.text = endpoint['method'];
                        _bodyController.text = endpoint['body'] ?? '';
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Endpoint input
                  TextField(
                    controller: _endpointController,
                    decoration: const InputDecoration(
                      labelText: 'Endpoint',
                      border: OutlineInputBorder(),
                      hintText: '/api/doctors',
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Method dropdown
                  DropdownButtonFormField<String>(
                    value: _methodController.text,
                    decoration: const InputDecoration(
                      labelText: 'Method',
                      border: OutlineInputBorder(),
                    ),
                    items: ['GET', 'POST', 'PUT', 'DELETE']
                        .map((method) => DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _methodController.text = value;
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Request body input (for POST/PUT)
                  if (_methodController.text == 'POST' || _methodController.text == 'PUT')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Request Body (JSON):'),
                            TextButton(
                              onPressed: () {
                                _bodyController.text = '{"doctor_id": 1, "is_available": true}';
                              },
                              child: const Text('Insert Sample'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _bodyController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '{"key": "value"}',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  
                  // Send request button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _testApi,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.0),
                            )
                          : const Text('Send Request'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // API Response Section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'API Response',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_statusCode > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _statusCode >= 200 && _statusCode < 300
                                    ? Colors.green[100]
                                    : Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Status: $_statusCode',
                                style: TextStyle(
                                  color: _statusCode >= 200 && _statusCode < 300
                                      ? Colors.green[800]
                                      : Colors.red[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_responseText.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _responseText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Response copied to clipboard')),
                            );
                          },
                          tooltip: 'Copy response',
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _responseText.isEmpty ? 'No response yet' : _responseText,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: _responseText.startsWith('Error:') ? Colors.red : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}