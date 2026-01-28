import 'package:flutter/material.dart';

class CustomTextWidget extends StatelessWidget {
  final String title;
  final String? subtitle;

  const CustomTextWidget({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 19,
                color: theme.colorScheme.outline,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
