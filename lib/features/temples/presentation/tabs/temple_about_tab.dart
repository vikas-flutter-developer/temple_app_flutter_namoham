// tabs/about_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_user_app/features/temples/data/models/temple_model.dart';
import 'package:readmore/readmore.dart';

class AboutTab extends StatelessWidget {
  final TempleModel profile;

  const AboutTab({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(theme, 'Description', profile.description),
          const SizedBox(height: 16),
          if (profile.location.isNotEmpty) ...[
            _buildSection(theme, 'Location', profile.location),
            const SizedBox(height: 16),
          ],
          if (profile.openTime.isNotEmpty || profile.closeTime.isNotEmpty) ...[
             _buildSection(theme, 'Timings', '${profile.openTime} - ${profile.closeTime}'),
             const SizedBox(height: 16),
          ],
          if (profile.website.isNotEmpty) ...[
            _buildSection(theme, 'Website', profile.website, isLink: true),
            const SizedBox(height: 16),
          ],
          if (profile.phoneNumber.isNotEmpty) ...[
            _buildSection(theme, 'Contact', profile.phoneNumber),
             const SizedBox(height: 16),
          ],
           if (profile.email.isNotEmpty) ...[
            _buildSection(theme, 'Email', profile.email),
             const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String content, {bool isLink = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.all(16.0),
          child: isLink 
            ? Text(
                content,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              )
            : ReadMoreText(
                content,
                style: TextStyle(
                  fontSize: 16,
                   color: theme.colorScheme.onSurfaceVariant,
                ),
                trimMode: TrimMode.Line,
                trimLines: 4,
                colorClickableText: theme.colorScheme.primary,
                trimCollapsedText: 'Read More',
                trimExpandedText: 'Read Less',
              ),
        ),
      ],
    );
  }
}
