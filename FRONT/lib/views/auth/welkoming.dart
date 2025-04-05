// lib/views/auth/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen1.dart';
import 'register_screen1.dart';
import '../../core/utils/constants.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'Welcome to HealthConsult',
      'subtitle': 'Your health, our priority',
      'description': 'Connect with verified medical professionals for personalized consultations anytime, anywhere.',
      'image': 'assets/images/onboarding1.jpg',
      'color': Colors.blue,
    },
    {
      'title': 'Find the Right Doctor',
      'subtitle': 'Specialized care at your fingertips',
      'description': 'Browse through our network of specialists and choose the right doctor for your medical needs.',
      'image': 'assets/images/onboarding2.jpg',
      'color': Colors.green,
    },
    {
      'title': 'Secure Consultations',
      'subtitle': 'Private and confidential',
      'description': 'All your medical data and consultations are encrypted and completely confidential.',
      'image': 'assets/images/onboarding3.jpg',
      'color': Colors.purple,
    },
    {
      'title': 'Get Started',
      'subtitle': 'Your journey to better health begins now',
      'description': 'Create an account or sign in to access all features and connect with doctors.',
      'image': 'assets/images/onboarding4.jpg',
      'color': Colors.teal,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen PageView for onboarding
          PageView.builder(
            controller: _pageController,
            itemCount: _onboardingData.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return _buildOnboardingPage(index);
            },
          ),
          
          // Progress indicators at the bottom
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          
          // Navigation buttons at the bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildNavigationButtons(),
          ),
        ],
      ),
    );
  }

  // Completion of the welcome_screen.dart file

Widget _buildOnboardingPage(int index) {
  final data = _onboardingData[index];
  
  return Container(
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage(data['image']),
        fit: BoxFit.cover,
      ),
    ),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            data['color'].withOpacity(0.6),
            data['color'].withOpacity(0.9),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Logo at the top
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              
              // Main content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data['title'],
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data['subtitle'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      data['description'],
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildNavigationButtons() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Skip button
      if (_currentPage < _onboardingData.length - 1)
        TextButton(
          onPressed: () {
            // Navigate directly to the last page (Get Started)
            _pageController.animateToPage(
              _onboardingData.length - 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: const Text(
            'Skip',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),

      // Next/Continue button
      ElevatedButton(
        onPressed: () {
          if (_currentPage < _onboardingData.length - 1) {
            // Move to next page
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            // On last page, navigate to login screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          _currentPage < _onboardingData.length - 1 ? 'Next' : 'Continue',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}}