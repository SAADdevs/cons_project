// // views/auth/onboarding_screen.dart
// import 'package:flutter/material.dart';
// import 'package:my_app/routes/app_routes.dart';

// class OnboardingScreen extends StatefulWidget {
//   const OnboardingScreen({super.key});

//   @override
//   _OnboardingScreenState createState() => _OnboardingScreenState();
// }

// class _OnboardingScreenState extends State<OnboardingScreen> {
//   final PageController _pageController = PageController();
//   int _currentPage = 0;

//   final List<Widget> _pages = [
//     const PolicyPage(
//       title: "Privacy & Security",
//       content: "Your health data is encrypted and protected with bank-level security.\n\n"
//           "We never share your medical information without your explicit consent.",
//       icon: Icons.security,
//     ),
//     const PolicyPage(
//       title: "Terms of Service",
//       content: "By using HealthConsult, you agree to our Terms of Service and professional conduct guidelines.\n\n"
//           "All consultations are conducted by certified medical professionals.",
//       icon: Icons.assignment,
//     ),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           PageView(
//             controller: _pageController,
//             onPageChanged: (index) {
//               setState(() => _currentPage = index);
//             },
//             children: _pages,
//           ),
//           Positioned(
//             bottom: 40,
//             left: 0,
//             right: 0,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 AnimatedContainer(
//                   duration: const Duration(milliseconds: 300),
//                   width: _currentPage == 0 ? 160 : 180,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blueAccent,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                     ),
//                     // In OnboardingScreen's "Get Started" button
//                     onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
//                     child: Text(
//                       _currentPage == 0 ? "Continue" : "Get Started",
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class PolicyPage extends StatelessWidget {
//   final String title;
//   final String content;
//   final IconData icon;

//   const PolicyPage({
//     super.key,
//     required this.title,
//     required this.content,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 32),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.blueAccent.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             padding: const EdgeInsets.all(24),
//             child: Icon(
//               icon,
//               size: 64,
//               color: Colors.blueAccent,
//             ),
//           ),
//           const SizedBox(height: 40),
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           Text(
//             content,
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey[700],
//               height: 1.6,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }