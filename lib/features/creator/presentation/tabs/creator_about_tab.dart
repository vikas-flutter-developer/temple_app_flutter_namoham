// tabs/about_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_user_app/features/creator/data/model/creators_model.dart';
import 'package:readmore/readmore.dart';

class CreatorAboutTab extends StatelessWidget {
  final CreatorModel profile;

  const CreatorAboutTab({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: ReadMoreText(
                profile.description,
                style: const TextStyle(fontSize: 16),
                trimMode: TrimMode.Line,
                trimLines: 8,
                trimCollapsedText: 'Read More',
                trimExpandedText: 'Read Less',
                moreStyle: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                lessStyle: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
