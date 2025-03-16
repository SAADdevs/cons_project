// import 'package:flutter/material.dart';
// import '../../core/utils/constants.dart';
// import '../../routes/app_routes.dart';

// class ChatListScreen extends StatelessWidget {
//   const ChatListScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Messages'),
//         backgroundColor: AppColors.primary,
//       ),
//       body: ListView.builder(
//         itemCount: 5, // Replace with actual data
//         itemBuilder: (context, index) => ListTile(
//           leading: const CircleAvatar(
//             backgroundImage: AssetImage('assets/images/doctor1.png'),
//           ),
//           title: const Text('Dr. Michael Chen'),
//           subtitle: const Text('Last message preview...'),
//           trailing: Text('2h', style: TextStyle(color: AppColors.secondaryText)),
//           onTap: () => // In your chat list item onTap handler
//           Navigator.pushNamed(context,AppRoutes.chat,arguments: {'name': 'Dr. Sarah Johnson','specialty': 'Cardiologist'},),
//         ),
//       ),
//     );
//   }
// }