import 'package:flutter/material.dart';
import 'package:haticare/core/theme/app_colors.dart';

class PharmacyPrivacyPolicyScreen extends StatelessWidget {
  const PharmacyPrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your Privacy Matters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: ${_getFormattedDate()}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Privacy Policy Content
            _buildSectionCard(
              title: '1. Information We Collect',
              content:
                  'We collect information that you provide directly to us, including:\n\n'
                  '• Personal identification information (Name, email address, phone number)\n'
                  '• Professional credentials and license information\n'
                  '• Prescription and medication data\n'
                  '• Patient information for prescription processing\n'
                  '• Usage data and analytics',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: '2. How We Use Your Information',
              content:
                  'We use the information we collect to:\n\n'
                  '• Provide, maintain, and improve our services\n'
                  '• Process and manage prescription requests\n'
                  '• Communicate with you about services and updates\n'
                  '• Ensure compliance with healthcare regulations\n'
                  '• Protect against fraudulent or illegal activity\n'
                  '• Analyze usage patterns to improve user experience',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: '3. Information Sharing',
              content:
                  'We may share your information with:\n\n'
                  '• Healthcare providers and authorized medical professionals\n'
                  '• Patients (limited to prescription-related information)\n'
                  '• Service providers who assist in our operations\n'
                  '• Legal authorities when required by law\n\n'
                  'We do not sell your personal information to third parties.',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: '4. Data Security',
              content:
                  'We implement appropriate technical and organizational measures to protect your personal information, including:\n\n'
                  '• Encryption of data in transit and at rest\n'
                  '• Regular security assessments and updates\n'
                  '• Access controls and authentication\n'
                  '• Secure data storage and backup systems\n'
                  '• Employee training on data protection',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: '5. Your Rights',
              content:
                  'You have the right to:\n\n'
                  '• Access your personal information\n'
                  '• Correct inaccurate or incomplete data\n'
                  '• Request deletion of your data\n'
                  '• Object to processing of your information\n'
                  '• Withdraw consent at any time\n'
                  '• Request data portability',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: '6. Data Retention',
              content:
                  'We retain your information for as long as necessary to:\n\n'
                  '• Provide our services to you\n'
                  '• Comply with legal obligations\n'
                  '• Resolve disputes and enforce agreements\n'
                  '• Meet regulatory requirements\n\n'
                  'Prescription records are retained according to applicable healthcare regulations.',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: '7. Cookies and Tracking',
              content:
                  'We use cookies and similar tracking technologies to:\n\n'
                  '• Remember your preferences and settings\n'
                  '• Analyze usage patterns and trends\n'
                  '• Improve application performance\n'
                  '• Provide personalized content\n\n'
                  'You can control cookie settings through your device preferences.',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: '8. Children\'s Privacy',
              content:
                  'Our services are not intended for individuals under the age of 18. '
                  'We do not knowingly collect personal information from children. '
                  'If you believe we have collected information from a child, please contact us immediately.',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: '9. Changes to This Policy',
              content:
                  'We may update this Privacy Policy from time to time. '
                  'We will notify you of any changes by posting the new Privacy Policy on this page '
                  'and updating the "Last updated" date. '
                  'You are advised to review this Privacy Policy periodically for any changes.',
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: '10. Contact Us',
              content:
                  'If you have any questions about this Privacy Policy, please contact us:\n\n'
                  '• Email: privacy@haticare.com\n'
                  '• Phone: +1 (555) 123-4567\n'
                  '• Address: 123 Healthcare Ave, Medical District, City, State 12345\n\n'
                  'Our Data Protection Officer is available to address your privacy concerns.',
            ),
            const SizedBox(height: 24),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.verified_user,
                    color: AppColors.primaryDark,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'HIPAA Compliant',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We are committed to protecting your health information',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
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

  Widget _buildSectionCard({required String title, required String content}) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}
