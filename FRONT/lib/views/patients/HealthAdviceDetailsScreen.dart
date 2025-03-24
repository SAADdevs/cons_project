import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/utils/constants.dart';
import '../../core/models/healthAdvice.dart';

class HealthAdviceDetailsScreen extends StatelessWidget {
  final HealthAdvice advice;

  const HealthAdviceDetailsScreen({
    Key? key, 
    required this.advice
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                advice.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              background: _buildHeaderBackground(),
            ),
          ),

          // Content
          SliverList(
            delegate: SliverChildListDelegate([
              // Doctor Info
              _buildDoctorSection(),

              // Advice Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      advice.content,
                      style: TextStyle(
                        color: Colors.grey[800],
                        height: 1.6,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildKeyTakeaways(),
                  ],
                ),
              ),

              // Additional Details
              _buildAdditionalDetails(),

              // Disclaimer
              _buildDisclaimer(),

              // Padding at bottom
              const SizedBox(height: 20),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient Background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // Category Chip
        Positioned(
          top: 100,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              advice.category,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue[100],
            child: const Icon(
              Icons.person,
              color: Colors.blue,
              size: 35,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advice.doctorName ?? 'Unknown Doctor',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  advice.doctorSpecialty ?? 'Medical Professional',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalDetails() {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy');
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDetailChip(
            icon: Icons.calendar_today,
            label: dateFormat.format(advice.createdAt),
          ),
          _buildDetailChip(
            icon: Icons.category,
            label: advice.category,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyTakeaways() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Key Takeaways',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Extract key points from the content - this is simplified for now
          // In a real app, you might want to have these stored in the database
          _buildTakeawayItem('Follow medical professional advice'),
          _buildTakeawayItem('Maintain a healthy lifestyle'),
          _buildTakeawayItem('Consult with a doctor regularly'),
        ],
      ),
    );
  }

  Widget _buildTakeawayItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This health advice is for informational purposes only. Always consult with a healthcare professional for personalized medical advice.',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}