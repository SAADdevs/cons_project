import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminAdvicePage extends StatefulWidget {
  const AdminAdvicePage({Key? key}) : super(key: key);

  @override
  State<AdminAdvicePage> createState() => _AdminAdvicePageState();
}

class _AdminAdvicePageState extends State<AdminAdvicePage> {
  bool _isLoading = true;
  List<dynamic> _allAdvice = [];
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadHealthAdvice();
  }
  
  Future<void> _loadHealthAdvice() async {
    setState(() => _isLoading = true);

    try {
      // Fetch all health advice (including unapproved ones)
      final response = await http.get(
        Uri.parse('http://192.168.1.55:5000/api/health-advice'),
        headers: {"Content-Type": "application/json"},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allAdvice = data;
          _isLoading = false;
        });
      } else {
        _showSnackBar('Failed to load health advice: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading health advice: $e');
      _showSnackBar('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Filter advice based on search query
  List<dynamic> get _filteredAdvice {
    if (_searchQuery.isEmpty) return _allAdvice;
    
    return _allAdvice.where((advice) {
      final title = (advice['title'] ?? '').toString().toLowerCase();
      final content = (advice['advice_text'] ?? '').toString().toLowerCase();
      final category = (advice['category'] ?? '').toString().toLowerCase();
      return title.contains(_searchQuery.toLowerCase()) || 
             content.contains(_searchQuery.toLowerCase()) ||
             category.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _approveAdvice(int id) async {
    try {
      final response = await http.put(
        Uri.parse('http://192.168.1.55:5000/api/health-advice/approve/$id'),
        headers: {"Content-Type": "application/json"},
      );
      
      if (response.statusCode == 200) {
        _showSnackBar('Health advice approved successfully');
        _loadHealthAdvice(); // Refresh the list
      } else {
        _showSnackBar('Failed to approve health advice: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _deleteAdvice(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://192.168.1.55:5000/api/health-advice/$id'),
        headers: {"Content-Type": "application/json"},
      );
      
      if (response.statusCode == 200) {
        _showSnackBar('Health advice rejected and deleted');
        _loadHealthAdvice(); // Refresh the list
      } else {
        _showSnackBar('Failed to delete health advice: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Health Advice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHealthAdvice,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search health advice...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          // Status counters
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatusCard(
                      title: 'Total',
                      count: _allAdvice.length,
                      icon: Icons.article,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusCard(
                      title: 'Pending',
                      count: _allAdvice.where((a) => a['is_approved'] != true).length,
                      icon: Icons.pending,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusCard(
                      title: 'Approved',
                      count: _allAdvice.where((a) => a['is_approved'] == true).length,
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          
          // Main content - advice list
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filteredAdvice.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredAdvice.length,
                    itemBuilder: (context, index) {
                      final advice = _filteredAdvice[index];
                      final isApproved = advice['is_approved'] == true;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          advice['title'] ?? 'Untitled Advice',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'By ${advice['doctor_name'] ?? 'Unknown Doctor'} • ${advice['category'] ?? 'General'}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isApproved 
                                          ? Colors.green.withOpacity(0.2) 
                                          : Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isApproved ? 'Approved' : 'Pending',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isApproved ? Colors.green[800] : Colors.orange[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                advice['advice_text'] ?? 'No content',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!isApproved)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.check, color: Colors.white),
                                      label: const Text('Approve'),
                                      onPressed: () => _showApproveConfirmation(advice['id']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Reject'),
                                    onPressed: () => _showDeleteConfirmation(advice['id']),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty 
                ? 'No health advice found' 
                : 'No health advice matches your search',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showApproveConfirmation(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Health Advice'),
        content: const Text('Are you sure you want to approve this health advice? It will be visible to all patients.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _approveAdvice(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Health Advice'),
        content: const Text('Are you sure you want to reject and delete this health advice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteAdvice(id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}