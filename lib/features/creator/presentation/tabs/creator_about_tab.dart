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
          _buildSection(theme, 'Description', profile.description),
          const SizedBox(height: 16),
          if (profile.bio.isNotEmpty) ...[
            _buildSection(theme, 'Bio', profile.bio),
            const SizedBox(height: 16),
          ],
          if (_getLocationString(profile).isNotEmpty) ...[
            _buildSection(theme, 'Location', _getLocationString(profile)),
            const SizedBox(height: 16),
          ],
          if (profile.dob.isNotEmpty) ...[
            _buildSection(theme, 'Date of Birth', profile.dob.split('T')[0]),
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

  String _getLocationString(CreatorModel profile) {
    String loc = '';
    if (profile.address.isNotEmpty) loc += profile.address;
    if (profile.city.isNotEmpty) loc += (loc.isNotEmpty ? ', ' : '') + profile.city;
    if (profile.state.isNotEmpty) loc += (loc.isNotEmpty ? ', ' : '') + profile.state;
    if (profile.country.isNotEmpty) loc += (loc.isNotEmpty ? ', ' : '') + profile.country;
    if (profile.zipCode.isNotEmpty) loc += (loc.isNotEmpty ? ' - ' : '') + profile.zipCode;
    return loc;
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
