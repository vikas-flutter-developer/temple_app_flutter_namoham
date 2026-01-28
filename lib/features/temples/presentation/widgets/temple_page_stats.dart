// widgets/profile_stats.dart
import 'package:flutter/material.dart';
import 'package:flutter_user_app/features/temples/data/models/temple_model.dart';

class ProfileStats extends StatelessWidget {
  final TempleModel profile;
  final VoidCallback? onFollowersTap;
  final int? followersOverride;

  const ProfileStats({
    super.key,
    required this.profile,
    this.onFollowersTap,
    this.followersOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat('${profile.posts}', 'Posts', context),
          _buildStat(
            '${followersOverride ?? profile.followers}',
            'Followers',
            context,
            onTap: onFollowersTap,
          ),
          _buildStat('${profile.following}', 'Following', context),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, BuildContext context,
      {VoidCallback? onTap}) {
    final theme = Theme.of(context);

    final child = Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );

    if (onTap == null) return child;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: child,
      ),
    );
  }
}
