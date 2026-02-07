import 'package:flutter/material.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';
import 'package:flutter_user_app/features/temples/data/models/temple_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_user_app/features/follow/presentation/providers/follow_provider.dart';
import 'package:flutter_user_app/features/posts/presentation/provider/posts_provider.dart';

class ProfileStats extends StatefulWidget {
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
  State<ProfileStats> createState() => _ProfileStatsState();
}

class _ProfileStatsState extends State<ProfileStats> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final followProvider = Provider.of<FollowProvider>(context, listen: false);
      final postProvider = Provider.of<PostsProvider>(context, listen: false);
      
      followProvider.loadFollowers(widget.profile.id);
      followProvider.loadFollowing(widget.profile.id);
      postProvider.loadUserPostCount(widget.profile.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Live Post Count
            Consumer<PostsProvider>(
              builder: (context, postsProvider, child) {
                final count = postsProvider.userPostCount;
                return _buildStat(
                  '${postsProvider.isLoadingPostCount ? "..." : count}', 
                  l10n.posts, 
                  context
                );
              },
            ),
            
            VerticalDivider(color: Colors.grey.shade300, width: 1, indent: 8, endIndent: 8),

            // Live Follower Count
            Consumer<FollowProvider>(
              builder: (context, followProvider, child) {
                 final count = followProvider.followersCount;
                 return _buildStat(
                  '${followProvider.isLoadingFollowers ? "..." : count}', 
                  l10n.followers, 
                  context, 
                  onTap: widget.onFollowersTap
                );
              },
            ),
            
            VerticalDivider(color: Colors.grey.shade300, width: 1, indent: 8, endIndent: 8),

            // Live Following Count
            Consumer<FollowProvider>(
              builder: (context, followProvider, child) {
                 final count = followProvider.viewedFollowingCount;
                 return _buildStat(
                  '${followProvider.isLoadingFollowing ? "..." : count}', 
                  l10n.following, 
                  context
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, BuildContext context,
      {VoidCallback? onTap}) {
    // final theme = Theme.of(context); // Not needed if hardcoding specific styles to match Figma

    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87, // Strong black for numbers
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600, // Grey for label
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );

    if (onTap == null) return child;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: child,
      ),
    );
  }
}
