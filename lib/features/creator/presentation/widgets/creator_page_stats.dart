import 'package:flutter/material.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';
import 'package:flutter_user_app/features/creator/data/model/creators_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_user_app/features/follow/presentation/providers/follow_provider.dart';
import 'package:flutter_user_app/features/posts/presentation/provider/posts_provider.dart';

class CreatorProfileStats extends StatefulWidget {
  final CreatorModel profile;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;
  final int? followersOverride;

  const CreatorProfileStats({
    super.key,
    required this.profile,
    this.onFollowersTap,
    this.onFollowingTap,
    this.followersOverride,
  });

  @override
  State<CreatorProfileStats> createState() => _CreatorProfileStatsState();
}

class _CreatorProfileStatsState extends State<CreatorProfileStats> {

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
      padding: const EdgeInsets.only(bottom: 4),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Consumer<PostsProvider>(
                builder: (context, postsProvider, child) {
                  final count = postsProvider.userPostCount;
                  return _buildStat(
                    '${postsProvider.isLoadingPostCount ? "..." : count}', 
                    l10n.posts, 
                    context
                  );
                },
              ),
            ),
            
            VerticalDivider(color: Colors.grey.shade300, width: 1, indent: 8, endIndent: 8),
            
            Expanded(
              child: Consumer<FollowProvider>(
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
            ),
            
            VerticalDivider(color: Colors.grey.shade300, width: 1, indent: 8, endIndent: 8),
            
             Expanded(
               child: Consumer<FollowProvider>(
                builder: (context, followProvider, child) {
                   final count = followProvider.viewedFollowingCount;
                   return _buildStat(
                    '${followProvider.isLoadingFollowing ? "..." : count}', 
                    l10n.following, 
                    context,
                    onTap: widget.onFollowingTap
                  );
                },
              ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, BuildContext context,
      {VoidCallback? onTap}) {
    // final theme = Theme.of(context); // Not needed if hardcoding specific styles to match Temple

    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            // color: Colors.black87, // Removed hardcoded color
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            // color: Colors.grey.shade600, // Removed hardcoded color
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: child,
      ),
    );
  }
}
