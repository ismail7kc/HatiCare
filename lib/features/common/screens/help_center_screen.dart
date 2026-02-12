import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:haticare/core/theme/app_colors.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help Center',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.help_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'How Can We Help You?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Find answers to common questions and get support',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // FAQs Section
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            _buildFAQCard(
              question: 'How do I verify a prescription?',
              answer:
                  'To verify a prescription:\n\n'
                  '1. Go to the Home screen\n'
                  '2. Enter the Rx Code in the verification field\n'
                  '3. Click "Verify" button\n'
                  '4. Review the prescription details\n'
                  '5. Approve or reject the request',
            ),
            const SizedBox(height: 12),

            _buildFAQCard(
              question: 'How do I update my profile?',
              answer:
                  'You can update your profile by:\n\n'
                  '1. Go to Settings tab\n'
                  '2. Tap on "Edit Profile"\n'
                  '3. Update your information\n'
                  '4. Upload required documents if needed\n'
                  '5. Click "Submit" to save changes',
            ),
            const SizedBox(height: 12),

            _buildFAQCard(
              question: 'How do I change my profile picture?',
              answer:
                  'To change your profile picture:\n\n'
                  '1. Go to Settings tab\n'
                  '2. Tap the edit icon on your profile picture\n'
                  '3. Choose to take a photo or select from gallery\n'
                  '4. Your picture will be updated automatically',
            ),
            const SizedBox(height: 12),

            _buildFAQCard(
              question: 'How do I view history?',
              answer:
                  'To view history:\n\n'
                  '1. Go to the History tab\n'
                  '2. Browse through all processed requests\n'
                  '3. Tap on any item to view details\n'
                  '4. Use filters to find specific items',
            ),
            const SizedBox(height: 12),

            _buildFAQCard(
              question: 'What should I do if I forgot my password?',
              answer:
                  'If you forgot your password:\n\n'
                  '1. Go to the Login screen\n'
                  '2. Tap "Forgot Password?"\n'
                  '3. Enter your registered email\n'
                  '4. Check your email for reset instructions\n'
                  '5. Follow the link to create a new password',
            ),
            const SizedBox(height: 12),

            _buildFAQCard(
              question: 'How do I manage notifications?',
              answer:
                  'To manage notifications:\n\n'
                  '1. Go to Settings tab\n'
                  '2. Tap on "Notifications"\n'
                  '3. View all your notifications\n'
                  '4. Mark as read or delete as needed',
            ),
            const SizedBox(height: 12),

            _buildFAQCard(
              question: 'Is my data secure?',
              answer:
                  'Yes, your data is secure. We use:\n\n'
                  '• End-to-end encryption\n'
                  '• HIPAA-compliant storage\n'
                  '• Secure authentication\n'
                  '• Regular security audits\n'
                  '• Protected API communications',
            ),
            const SizedBox(height: 24),

            // Quick Links Section
            const Text(
              'Quick Links',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            _buildQuickLinkCard(
              icon: Icons.article_outlined,
              title: 'User Guide',
              description: 'Complete guide to using the app',
            ),
            const SizedBox(height: 12),

            _buildQuickLinkCard(
              icon: Icons.video_library_outlined,
              title: 'Video Tutorials',
              description: 'Watch step-by-step video guides',
            ),
            const SizedBox(height: 12),

            _buildQuickLinkCard(
              icon: Icons.security_outlined,
              title: 'Privacy & Security',
              description: 'Learn about data protection',
            ),
            const SizedBox(height: 24),

            // Still Need Help Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryDark.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Still Need Help?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our support team is here to help you',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to contact support or show contact options
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        child: const Text(
                          'Contact Support',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard({required String question, required String answer}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.question_answer,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinkCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryDark.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey[400],
            size: 16,
          ),
        ],
      ),
    );
  }
}
