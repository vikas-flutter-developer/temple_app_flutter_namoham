import 'package:flutter/material.dart';
import 'package:flutter_user_app/features/creator/data/model/creators_model.dart';

class CreatorReviewTab extends StatefulWidget {
  final CreatorModel creator;

  const CreatorReviewTab({
    Key? key,
    required this.creator,
  }) : super(key: key);

  @override
  State<CreatorReviewTab> createState() => _CreatorReviewTabState();
}

class _CreatorReviewTabState extends State<CreatorReviewTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Reviews Coming Soon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reviews for ${widget.creator.creatorName} will be available soon.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
