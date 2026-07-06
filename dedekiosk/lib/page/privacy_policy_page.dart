import 'package:flutter/material.dart';
import 'package:dedekiosk/global.dart' as global;

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(global.language("privacy_policy")),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/dedelogo.png',
                    height: 80,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.store,
                      size: 80,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'DEDE Kiosk',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last Updated: December 1, 2025',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Introduction
            _buildSection(
              'Introduction',
              'DEDE Kiosk ("we", "our", or "us") is committed to protecting your privacy. '
                  'This Privacy Policy explains how we collect, use, and safeguard your information '
                  'when you use our point-of-sale kiosk application.',
            ),

            // Information We Collect
            _buildSection(
              'Information We Collect',
              'We may collect the following types of information:\n\n'
                  '• Device Information: Device identifiers, operating system version, and hardware model '
                  'for app functionality and troubleshooting.\n\n'
                  '• Transaction Data: Order details, payment information (processed securely), and receipts '
                  'for business operations.\n\n'
                  '• Location Data: General location information for regional settings and compliance purposes.\n\n'
                  '• Network Information: Connection status to ensure reliable service.',
            ),

            // READ_PHONE_STATE Permission
            _buildSection(
              'Phone State Permission (READ_PHONE_STATE)',
              'Our application may request the READ_PHONE_STATE permission for the following purposes:\n\n'
                  '• Device Identification: To generate a unique device identifier for licensing and '
                  'device registration purposes.\n\n'
                  '• Network Status: To detect network connectivity changes and ensure reliable '
                  'communication with our servers.\n\n'
                  '• Call State Detection: To pause audio or other activities when the device '
                  'receives incoming calls (if applicable).\n\n'
                  'We do NOT collect, store, or transmit your phone number, call logs, or any '
                  'personal communication data.',
            ),

            // How We Use Information
            _buildSection(
              'How We Use Your Information',
              '• To provide and maintain our point-of-sale services\n'
                  '• To process transactions and generate receipts\n'
                  '• To improve our application and user experience\n'
                  '• To communicate important updates and notifications\n'
                  '• To ensure security and prevent fraud\n'
                  '• To comply with legal obligations',
            ),

            // Data Security
            _buildSection(
              'Data Security',
              'We implement industry-standard security measures to protect your information:\n\n'
                  '• SSL/TLS encryption for data transmission\n'
                  '• Secure cloud storage with access controls\n'
                  '• Regular security audits and updates\n'
                  '• Local data encryption where applicable',
            ),

            // Data Retention
            _buildSection(
              'Data Retention',
              'We retain your data only as long as necessary for business operations and legal '
                  'compliance. Transaction records may be kept for accounting and tax purposes as '
                  'required by law.',
            ),

            // Third-Party Services
            _buildSection(
              'Third-Party Services',
              'Our application may use third-party services for:\n\n'
                  '• Payment processing (e.g., GB PrimePay)\n'
                  '• Cloud services (e.g., Firebase)\n'
                  '• Analytics and crash reporting\n\n'
                  'These services have their own privacy policies governing the use of your information.',
            ),

            // Your Rights
            _buildSection(
              'Your Rights',
              'You have the right to:\n\n'
                  '• Access your personal data\n'
                  '• Request correction of inaccurate data\n'
                  '• Request deletion of your data (subject to legal requirements)\n'
                  '• Withdraw consent for optional data collection\n'
                  '• File a complaint with relevant authorities',
            ),

            // Children's Privacy
            _buildSection(
              "Children's Privacy",
              'Our application is designed for business use and is not intended for children '
                  'under 13 years of age. We do not knowingly collect personal information from children.',
            ),

            // Changes to Policy
            _buildSection(
              'Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any '
                  'changes by posting the new Privacy Policy in the application. You are advised to '
                  'review this Privacy Policy periodically for any changes.',
            ),

            // Contact Information
            _buildSection(
              'Contact Us',
              'If you have any questions about this Privacy Policy or our data practices, '
                  'please contact us:\n\n'
                  '• Email: support@dedesoftware.com\n'
                  '• Website: www.dedesoftware.com\n'
                  '• Address: Thailand',
            ),

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text(
                '© 2025 DEDE Software. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
