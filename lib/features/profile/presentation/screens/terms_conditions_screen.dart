import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
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
              '1. Agreement to Terms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'These Terms and Conditions constitute a legally binding agreement made between you, whether personally or on behalf of an entity ("you") and Temple App ("we," "us" or "our"), concerning your access to and use of our mobile application (the "App"). by accessing the App, you have read, understood, and agreed to be bound by all of these Terms and Conditions.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            
            const Text(
              '2. User Registration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You may be required to register with the App. You agree to keep your password confidential and will be responsible for all use of your account and password. We reserve the right to remove, reclaim, or change a username you select if we determine, in our sole discretion, that such username is inappropriate, obscene, or otherwise objectionable.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),

            const Text(
              '3. Prohibited Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You may not access or use the App for any purpose other than that for which we make the App available. The App may not be used in connection with any commercial endeavors except those that are specifically endorsed or approved by us. As a user of the App, you agree not to:',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Systematically retrieve data or other content from the App to create or compile, directly or indirectly, a collection, compilation, database, or directory without written permission from us.\n• Make any unauthorized use of the App, including collecting usernames and/or email addresses of users by electronic or other means for the purpose of sending unsolicited email.\n• Use the App to advertise or offer to sell goods and services.\n• Engage in unauthorized framing of or linking to the App.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),

            const Text(
              '4. User Generated Contributions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The App may invite you to chat, contribute to, or participate in blogs, message boards, online forums, and other functionality, and may provide you with the opportunity to create, submit, post, display, transmit, perform, publish, distribute, or broadcast content and materials to us or on the App, including but not limited to text, writings, video, audio, photographs, graphics, comments, suggestions, or personal information or other material (collectively, "Contributions").',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
             const SizedBox(height: 8),
            const Text(
              'Contributions may be viewable by other users of the App and through third-party websites. As such, any Contributions you transmit may be treated as non-confidential and non-proprietary.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),

            const Text(
              '5. Limitation of Liability',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'In no event will we or our directors, employees, or agents be liable to you or any third party for any direct, indirect, consequential, exemplary, incidental, special, or punitive damages, including lost profit, lost revenue, loss of data, or other damages arising from your use of the App, even if we have been advised of the possibility of such damages.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),

             const Text(
              '6. Contact Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'In order to resolve a complaint regarding the App or to receive further information regarding use of the App, please contact us at:\n\nEmail: support@templeapp.com',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
