import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/follow/presentation/providers/follow_provider.dart';
import 'package:flutter_user_app/features/follow/presentation/screens/followers_screen.dart';
import 'package:flutter_user_app/features/creator/data/model/creators_model.dart';
import 'package:flutter_user_app/features/creator/presentation/widgets/creator_page_actions.dart';
import 'package:flutter_user_app/features/creator/presentation/widgets/creator_page_stats.dart';
import 'package:flutter_user_app/features/creator/presentation/widgets/creator_page_tabs.dart';

class CreatorPage extends StatefulWidget {
  final CreatorModel creator;
  const CreatorPage({super.key, required this.creator});

  @override
  State<CreatorPage> createState() => _CreatorPageState();
}

class _CreatorPageState extends State<CreatorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final creator = widget.creator;

    return ChangeNotifierProvider(
      create: (_) => FollowProvider(ApiService.create())..loadFollowers(creator.id),
      child: Scaffold(
        body: DefaultTabController(
          length: 4,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Padding(
                    padding: const EdgeInsets.only(right: 30.0),
                    child: Text(
                      creator.creatorName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: creator.id,
                        child: Image.network(
                          creator.displayImage,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Overlay gradient for better readability
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              theme.colorScheme.surface.withAlpha(130)
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            body: Column(
              children: [
                Consumer<FollowProvider>(
                  builder: (context, followProvider, child) {
                    final int? followersOverride = followProvider.isLoadingFollowers &&
                            followProvider.followersCount == 0
                        ? null
                        : followProvider.followersCount;

                    return CreatorProfileStats(
                      profile: creator,
                      followersOverride: followersOverride,
                      onFollowersTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FollowersScreen(
                              entityId: creator.id,
                              title: '${creator.creatorName} Followers',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                CreatorProfileActions(profile: creator),
                CreatorProfileTabs(
                  tabController: _tabController,
                  profile: creator,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
