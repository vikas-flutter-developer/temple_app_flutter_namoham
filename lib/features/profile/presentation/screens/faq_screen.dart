import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/features/home/presentation/screens/home_page.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  @override
  Widget build(BuildContext context) {
    const Color cyanColor = Color(0xFF23C1FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // Header
                    const Text(
                      'FAQ',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Find important information and update about any recent changes and fees here.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // General Section
                    const Text(
                      'General',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: cyanColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFAQItem('How to connect with temples?', 
                      'You can connect with a temple by visiting their profile page and tapping the "Follow" button. This will keep you updated on their daily darshan, events, and announcements.'),
                    _buildDivider(),
                    _buildFAQItem('Can I receive receipts for my donation?', 
                      'Yes! After every successful donation, a digital receipt is generated instantly. You can download it to your gallery or share it directly from the success screen.'),
                    _buildDivider(),
                    _buildFAQItem('Is my personal information shared?', 
                      'Your privacy is our priority. We only share necessary transaction details (like your name and donation amount) with the temple or creator you donate to. Your contact details remain private.'),
                    _buildDivider(),

                    const SizedBox(height: 32),

                    // Contact Section
                    const Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: cyanColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFAQItem('How to contact with temples?', 
                      'To contact a temple, go to their profile and look for the "Message" or "Contact" button. Some temples may also verify their phone numbers for direct calls.'),
                    _buildDivider(),
                    _buildFAQItem('How to contact with Creators?', 
                      'Visit the Creator\'s profile page. If they have enabled messaging, you will see a chat icon. You can also follow them to see their latest updates and comment on their posts.',
                      initiallyExpanded: true),
                    _buildDivider(),
                    _buildFAQItem('How to call any service now?', 
                      'For app-related support or issues, please go to the "Contact Us" section in the main menu or settings. Our support team is available to assist you 24/7.'),
                    _buildDivider(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            
            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                     navigateToPageAndRemoveUntil(context, const HomePage());
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Rounded pill shape
                    ),
                    backgroundColor: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Go to Homepage',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: Colors.black, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade200);
  }

  Widget _buildFAQItem(String title, String content, {bool initiallyExpanded = false}) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        initiallyExpanded: initiallyExpanded,
        textColor: Colors.black,
        iconColor: Colors.black,
        childrenPadding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        children: [
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
