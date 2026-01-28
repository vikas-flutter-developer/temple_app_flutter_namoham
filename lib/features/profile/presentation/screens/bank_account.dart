import 'package:flutter/material.dart';

class BankAccount extends StatefulWidget {
  const BankAccount({Key? key}) : super(key: key);

  @override
  _BankAccountState createState() => _BankAccountState();
}

class _BankAccountState extends State<BankAccount> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Account'),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/coming_soon.png',
              height: 200,
              width: 200,
              // If image is not available, use Icon instead
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.account_balance,
                  size: 100,
                  color: Colors.grey,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Bank account integration feature is under development. Stay tuned for updates!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
