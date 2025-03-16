import 'package:flutter/material.dart';
import '../../core/utils/constants.dart';

class AppointmentListScreen extends StatelessWidget {
  const AppointmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Replace with actual data
      itemBuilder: (context, index) => Card(
        child: ListTile(
          leading: const CircleAvatar(
            backgroundImage: AssetImage('assets/images/doctor1.png'),
          ),
          title: const Text('Dr. Sarah Johnson'),
          subtitle: const Text('Tomorrow 10:00 AM'),
          trailing: Icon(Icons.chevron_right, color: AppColors.primary),
          onTap: () {}, // Add details navigation
        ),
      ),
    );
  }
}