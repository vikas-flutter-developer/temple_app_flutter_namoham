import 'package:flutter/material.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/events/presentation/providers/events_provider.dart';
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
  CreatorModel? _updatedCreator;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchCreatorDetails();
  }

  void _fetchCreatorDetails() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final updated = await api.getCreatorById(widget.creator.id);
      if (mounted) {
        setState(() {
          _updatedCreator = updated;
        });
      }
    } catch (e) {
      debugPrint('Error fetching creator details: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final creator = _updatedCreator ?? widget.creator;
    final apiService = Provider.of<ApiService>(context, listen: false);

    return ChangeNotifierProvider(
      create: (_) => EventsProvider(apiService),
      child: Scaffold(
        body: DefaultTabController(
          length: 3,
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
              CreatorProfileStats(
                profile: creator,
                onFollowersTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FollowersScreen(
                        entityId: creator.id,
                        title: '${creator.creatorName} ${AppLocalizations.of(context)!.followers}',
                      ),
                    ),
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
