import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Updated: February 2026',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Introduction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Welcome to Temple App. We value your privacy and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, disclosure, and safeguard your information when you use our mobile application.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            
            const Text(
              '2. Information We Collect',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We may collect information about you in a variety of ways. The information we may collect via the Application includes:',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Personal Data: Personally identifiable information, such as your name, shipping address, email address, and telephone number, and demographic information, such as your age, gender, hometown, and interests, that you voluntarily give to us when you register with the Application.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Usage Data: Information our servers automatically collect when you access the Application, such as your IP address, your browser type, your operating system, your access times, and the pages you have viewed directly before and after accessing the Application.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
              const SizedBox(height: 8),
            const Text(
              '• Media Permissions: We may request access into your device gallery or camera to upload content such as profile pictures, reels, or posts as per your request.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),

            const Text(
              '3. Use of Your Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Having accurate information about you permits us to provide you with a smooth, efficient, and customized experience. Specifically, we may use information collected about you via the Application to:',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Create and manage your account.\n• Process payments and refunds.\n• Send you email regarding your account or order.\n• Enable user-to-user communications.\n• Monitor and analyze usage and trends to improve your experience.\n• Notify you of updates to the Application.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),

            const Text(
              '4. Disclosure of Your Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We may share information we have collected about you in certain situations. Your information may be disclosed as follows:',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              '• By Law or to Protect Rights: If we believe the release of information about you is necessary to respond to legal process, to investigate or remedy potential violations of our policies, or to protect the rights, property, and safety of others.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
             const SizedBox(height: 8),
            const Text(
              '• Third-Party Service Providers: We may share your information with third parties that perform services for us or on our behalf, including payment processing, data analysis, email delivery, hosting services, customer service, and marketing assistance.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),

            const Text(
              '5. Security of Your Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We use administrative, technical, and physical security measures to help protect your personal information. While we have taken reasonable steps to secure the personal information you provide to us, please be aware that despite our efforts, no security measures are perfect or impenetrable, and no method of data transmission can be guaranteed against any interception or other type of misuse.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),

             const Text(
              '6. Policy for Children',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We do not knowingly solicit information from or market to children under the age of 13. If we learn that we have collected information from a child under age 13 without verification of parental consent, we will delete that information as quickly as possible.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            
            const Text(
              '7. Contact Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'If you have questions or comments about this Privacy Policy, please contact us at:\n\nEmail: privacy@templeapp.com',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
