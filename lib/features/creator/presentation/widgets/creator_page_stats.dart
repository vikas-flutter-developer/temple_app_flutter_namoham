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
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
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
           Consumer<FollowProvider>(
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
