import 'package:flutter/material.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/events/presentation/providers/events_provider.dart';
import 'package:flutter_user_app/features/follow/presentation/screens/followers_screen.dart';
import 'package:flutter_user_app/features/follow/presentation/screens/following_list_screen.dart';
import 'package:flutter_user_app/features/creator/data/model/creators_model.dart';
import 'package:flutter_user_app/features/creator/presentation/widgets/creator_page_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_user_app/features/events/presentation/screens/create_event_screen.dart';
import 'package:flutter_user_app/features/creator/presentation/widgets/creator_page_stats.dart';
import 'package:flutter_user_app/features/creator/presentation/widgets/creator_page_tabs.dart';
import 'package:flutter_user_app/features/posts/presentation/provider/posts_provider.dart';
import 'package:flutter_user_app/features/posts/domain/usecase/get_posts_usecase.dart';
import 'package:flutter_user_app/features/posts/data/repository/post_repository_impl.dart';
import 'package:flutter_user_app/features/follow/presentation/providers/follow_provider.dart';

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

  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkOwnership();
    _fetchCreatorDetails();
  }

  Future<void> _checkOwnership() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('user_id');
    if (mounted && currentUserId != null) {
      setState(() {
        _isOwner = currentUserId == widget.creator.id;
      });
    }
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

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventsProvider(apiService)),
        ChangeNotifierProvider(
          create: (_) => PostsProvider(
            GetPostsUsecase(PostRepositoryImpl(apiService: apiService)),
            PostRepositoryImpl(apiService: apiService),
          ),
        ),
      ],
      child: Scaffold(
        floatingActionButton: _isOwner
            ? Builder(
                builder: (fabContext) => FloatingActionButton.extended(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateEventScreen(
                          organizerId: creator.id,
                          organizerType: 'creator',
                        ),
                      ),
                    );
                    if (result == true && mounted) {
                       // Refresh page state and Fetch events
                       setState(() {});
                       Provider.of<EventsProvider>(fabContext, listen: false).fetchEventsByOrganizer(creator.id);
                    }
                  },
                  label: const Text('Create Event'),
                  icon: const Icon(Icons.add),
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              )
            : null,
        body: DefaultTabController(
          length: 3,
          child: Builder(
            builder: (innerContext) {
              return RefreshIndicator(
                onRefresh: () async {
                  // 1. Refresh Creator Details
                  try {
                    final api = Provider.of<ApiService>(innerContext, listen: false);
                    final updated = await api.getCreatorById(widget.creator.id);
                    if (mounted) {
                      setState(() {
                         _updatedCreator = updated;
                      });
                    }
                  } catch (e) {
                     debugPrint('Error refreshing creator: $e');
                  }

                  // 2. Refresh Providers
                  // Events
                  await Provider.of<EventsProvider>(innerContext, listen: false).fetchEvents();
                  
                  // Posts & Follows
                  final followProvider = Provider.of<FollowProvider>(innerContext, listen: false);
                  final postProvider = Provider.of<PostsProvider>(innerContext, listen: false);
                  
                  await Future.wait([
                     followProvider.loadFollowers(widget.creator.id),
                     followProvider.loadFollowing(widget.creator.id),
                     postProvider.loadUserPostCount(widget.creator.id),
                  ]);
                },
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
 
                            // Profile Avatar Overlay
                            Positioned(
                              bottom: 70, // Adjust based on title height
                              left: 20,
                              child: Container(
                                 decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: theme.colorScheme.surface, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                  backgroundImage: NetworkImage(creator.profilePic.isNotEmpty ? creator.profilePic : creator.displayImage),
                                  onBackgroundImageError: (_, __) {},
                                  child: (creator.profilePic.isEmpty && creator.displayImage.contains('placeholder'))
                                      ? Icon(Icons.person, size: 40, color: theme.colorScheme.onSurfaceVariant)
                                      : null,
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
                        onFollowingTap: _isOwner ? () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowingListScreen(),
                            ),
                          );
                        } : null,
                      ),
                      CreatorProfileActions(profile: creator),
                      CreatorProfileTabs(
                        tabController: _tabController,
                        profile: creator,
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
        ),
      ),
    );
  }
}
