import 'package:flutter/material.dart';

class AdminAdvicePage extends StatelessWidget {
  const AdminAdvicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Advice'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 5, // Replace with actual number of advice submissions
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text('Advice ${index + 1}'),
              subtitle: const Text('This is a sample advice submission.'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                      // Handle accept advice
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      // Handle reject advice
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}