import 'package:flutter/material.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_appbar.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_text_widget.dart';

class DonationScreen extends StatelessWidget {
  const DonationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and description
            CustomTextWidget(
              title: 'Donation Received',
              subtitle:
                  'Please choose what types of support do you need and let us know.',
            ),

            const SizedBox(height: 24.0),
            // Total Amount section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Withdraw History',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Amount display
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0),
              child: Text(
                '₹ 12500',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32.0),
            // Today's donations section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Today',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            // Donation list
            Expanded(
              child: ListView(
                children: [
                  _buildDonationItem(
                    'Kedarnath',
                    '10:30 AM',
                    125.00,
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/5/56/Kedarnath_Temple_in_Rainy_season.jpg/1200px-Kedarnath_Temple_in_Rainy_season.jpg', // Dummy image URL
                  ),
                  _buildDonationItem(
                    'Badrinath',
                    '11:45 AM',
                    215.00,
                    'https://www.peakadventuretour.com/assets/imgs/badrinath-temple-bnr.webp', // Dummy image URL
                  ),
                  _buildDonationItem(
                    'Jagannath',
                    '12:15 PM',
                    128.00,
                    'https://c.ndtvimg.com/2022-01/4t40lvq_jagannath-puri-_625x300_21_January_22.jpg', // Dummy image URL
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationItem(
      String name, String time, double amount, String imagePath) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Temple image
          Container(
            width: 60.0,
            height: 60.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              image: DecorationImage(
                image: NetworkImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16.0),
          // Temple name and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '+ ₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
