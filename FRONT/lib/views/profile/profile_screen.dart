import 'package:flutter/material.dart';
import '../../core/utils/constants.dart';
import '../../widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/images/user_avatar.png'),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text("Dr. Sarah Johnson", style: AppTextStyles.heading),
            Text("Cardiologist", style: AppTextStyles.body),
            const SizedBox(height: 30),
            
            _buildProfileSection("Personal Information", [
              _buildInfoRow(Icons.person, "Full Name", "Dr. Sarah Johnson"),
              _buildInfoRow(Icons.email, "Email", "sarah.j@healthcare.com"),
              _buildInfoRow(Icons.phone, "Phone", "+1 234 567 890"),
              _buildInfoRow(Icons.location_on, "Location", "New York, USA"),
            ]),
            
            const SizedBox(height: 24),
            _buildProfileSection("Security", [
              _buildActionRow(Icons.lock, "Change Password", () {}),
              _buildActionRow(Icons.security, "Two-Factor Authentication", () {}),
            ]),
            
            const SizedBox(height: 24),
            Padding(  // Added Padding for CustomButton
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomButton(
                text: "Log Out",
                onPressed: () {},
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, 
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold
                )),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12
              )),
              Text(value, style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}