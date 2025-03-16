// import 'package:flutter/material.dart';
// import 'package:my_app/views/appointments/appointments_screen.dart';
// import 'package:my_app/views/chat/chat_list_screen.dart';
// import 'package:my_app/views/profile/profile_screen.dart';
// //import 'package:my_app/views/doctors/doctors_by_specialty_screen.dart'; // New import
// import '../../core/utils/constants.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _currentIndex = 0;

//   final List<Widget> _screens = [
//     const HomeContent(),
//     const AppointmentsScreen(),
//     const ChatListScreen(),
//     const ProfileScreen(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _screens[_currentIndex],
//       bottomNavigationBar: _buildBottomNavBar(),
//     );
//   }

//   Widget _buildBottomNavBar() {
//     return BottomNavigationBar(
//       currentIndex: _currentIndex,
//       onTap: (index) => setState(() => _currentIndex = index),
//       selectedItemColor: AppColors.primary,
//       unselectedItemColor: Colors.grey,
//       showSelectedLabels: false,
//       showUnselectedLabels: false,
//       type: BottomNavigationBarType.fixed,
//       items: const [
//         BottomNavigationBarItem(
//           icon: Icon(Icons.home_outlined),
//           label: 'Home',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.calendar_today),
//           label: 'Appointments',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.chat_bubble_outline),
//           label: 'Chat',
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.person_outline),
//           label: 'Profile',
//         ),
//       ],
//     );
//   }
// }

// class HomeContent extends StatelessWidget {
//   const HomeContent({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [Colors.purple.shade50, Colors.white],
//         ),
//       ),
//       child: Column(
//         children: [
//           // App Header
//           Container(
//             padding: const EdgeInsets.only(top: 40, bottom: 20),
//             decoration: BoxDecoration(
//               color: AppColors.primary,
//               borderRadius: const BorderRadius.only(
//                 bottomLeft: Radius.circular(20),
//                 bottomRight: Radius.circular(20),
//               ),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text("Welcome Back!", 
//                               style: TextStyle(color: Colors.white, fontSize: 18)),
//                           Text("Sarah Smith",
//                               style: TextStyle(color: Colors.white, 
//                                   fontSize: 24, 
//                                   fontWeight: FontWeight.bold)),
//                         ],
//                       ),
//                       CircleAvatar(
//                         radius: 25,
//                         backgroundColor: Colors.white,
//                         child: Icon(Icons.person, color: AppColors.primary),
//                       )
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   // Search Bar
//                   TextField(
//                     decoration: InputDecoration(
//                       filled: true,
//                       fillColor: Colors.white,
//                       hintText: "Search doctors, services...",
//                       prefixIcon: Icon(Icons.search, color: AppColors.primary),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(15),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 20),
                  
//                   // Doctor Categories Title with clearer header
//                   Container(
//                     padding: const EdgeInsets.only(bottom: 10),
//                     decoration: BoxDecoration(
//                       border: Border(
//                         bottom: BorderSide(
//                           color: Colors.grey.shade300,
//                           width: 1.0,
//                         ),
//                       ),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           children: [
//                             Icon(Icons.medical_services, color: AppColors.primary),
//                             const SizedBox(width: 10),
//                             const Text(
//                               "Medical Specialties", 
//                               style: TextStyle(
//                                 fontSize: 20, 
//                                 fontWeight: FontWeight.bold
//                               )
//                             ),
//                           ],
//                         ),
//                         TextButton(
//                           onPressed: () {
//                             Navigator.push(
//                               context, 
//                               MaterialPageRoute(
// ///builder: (context) => const DoctorsBySpecialtyScreen(
//                                   specialty: "All Specialties"
//                                 )
//                               )
//                             );
//                           },
//                           child: Row(
//                             children: [
//                               Text("View All", style: TextStyle(color: AppColors.primary)),
//                               Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 20),
                  
//                   // Featured Categories - Clearer design
//                   const Text(
//                     "Featured Specialties",
//                     style: TextStyle(
//                       fontSize: 18, 
//                       fontWeight: FontWeight.w600
//                     )
//                   ),
//                   const SizedBox(height: 15),
//                   GridView.count(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     crossAxisCount: 4,
//                     childAspectRatio: 0.8,
//                     crossAxisSpacing: 10,
//                     mainAxisSpacing: 15,
//                     children: [
//                       _buildNavigableCategory("Cardiology", Icons.favorite, Colors.red, context),
//                       _buildNavigableCategory("Dermatology", Icons.face, Colors.orange, context),
//                       _buildNavigableCategory("Pediatrics", Icons.child_care, Colors.blue, context),
//                       _buildNavigableCategory("Neurology", Icons.psychology, Colors.green, context),
//                       _buildNavigableCategory("Orthopedics", Icons.accessibility_new, Colors.purple, context),
//                       _buildNavigableCategory("Dentistry", Icons.airline_seat_flat_angled, Colors.teal, context),
//                       _buildNavigableCategory("Eye Care", Icons.remove_red_eye, Colors.indigo, context),
//                       _buildNavigableCategory("Psychiatry", Icons.sentiment_satisfied_alt, Colors.amber, context),
//                     ],
//                   ),
                  
//                   const SizedBox(height: 25),
                  
                  
//                   // Health Tips & Advice Section (kept this section)
//                   Container(
//                     padding: const EdgeInsets.only(bottom: 10),
//                     decoration: BoxDecoration(
//                       border: Border(
//                         bottom: BorderSide(
//                           color: Colors.grey.shade300,
//                           width: 1.0,
//                         ),
//                       ),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           children: [
//                             Icon(Icons.health_and_safety, color: AppColors.primary),
//                             const SizedBox(width: 10),
//                             const Text(
//                               "Health Tips & Advice",
//                               style: TextStyle(
//                                 fontSize: 20, 
//                                 fontWeight: FontWeight.bold
//                               )
//                             ),
//                           ],
//                         ),
//                         TextButton(
//                           onPressed: () {},
//                           child: Row(
//                             children: [
//                               Text("More", style: TextStyle(color: AppColors.primary)),
//                               Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 15),
//                   _buildHealthTipCard(
//                     "Importance of Regular Check-ups",
//                     "Regular health check-ups can help detect potential health issues before they become a problem...",
//                     "Dr. Sarah Johnson",
//                     "2 days ago",
//                     "assets/images/doctor1.png",
//                   ),
//                   _buildHealthTipCard(
//                     "5 Tips for Healthy Skin",
//                     "Maintaining healthy skin doesn't have to be complicated. Here are 5 simple tips to keep your skin glowing...",
//                     "Dr. Michael Chen",
//                     "1 week ago",
//                     "assets/images/doctor2.png",
//                   ),
//                   const SizedBox(height: 20),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Updated category item with navigation
//   Widget _buildNavigableCategory(String title, IconData icon, Color color, BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => DoctorsBySpecialtyScreen(specialty: title)
//           )
//         );
//       },
//       child: Column(
//         children: [
//           Container(
//             height: 60,
//             width: 60,
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.15),
//               borderRadius: BorderRadius.circular(15),
//               border: Border.all(color: color.withOpacity(0.3), width: 1.5),
//             ),
//             child: Icon(icon, size: 30, color: color),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             title,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               fontSize: 12, 
//               fontWeight: FontWeight.w500
//             ),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }
  
 
//   Widget _buildHealthTipCard(String title, String content, String author, String time, String authorImage) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 15),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//       ),
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(15),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               content,
//               style: TextStyle(color: Colors.grey.shade700),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 15),
//             Row(
//               children: [
//                 CircleAvatar(
//                   radius: 15,
//                   backgroundImage: AssetImage(authorImage),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         author,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w500,
//                           fontSize: 12,
//                         ),
//                       ),
//                       Text(
//                         time,
//                         style: TextStyle(
//                           color: Colors.grey.shade600,
//                           fontSize: 10,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: AppColors.primary.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                   child: Text(
//                     "Read More",
//                     style: TextStyle(
//                       color: AppColors.primary,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }