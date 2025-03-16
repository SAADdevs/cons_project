import 'package:flutter/material.dart';
import '../../core/utils/constants.dart';
import '../../widgets/custom_button.dart';

class BookAppointmentScreen extends StatelessWidget {
  const BookAppointmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Appointment'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Add your booking form fields here
            const Spacer(),
            CustomButton(
              text: 'Book Now',
              onPressed: () {},
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}