import 'package:flutter/material.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/events/presentation/providers/events_provider.dart';
import 'package:flutter_user_app/features/follow/presentation/screens/followers_screen.dart';
import 'package:flutter_user_app/features/temples/data/models/temple_model.dart';
import 'package:flutter_user_app/features/temples/presentation/widgets/temple_page_actions.dart';
import 'package:flutter_user_app/features/temples/presentation/widgets/temple_page_stats.dart';
import 'package:flutter_user_app/features/temples/presentation/widgets/temple_page_tabs.dart';
import 'package:flutter_user_app/features/posts/presentation/provider/posts_provider.dart';
import 'package:flutter_user_app/features/posts/domain/usecase/get_posts_usecase.dart';
import 'package:flutter_user_app/features/posts/data/repository/post_repository_impl.dart';
import 'package:flutter_user_app/features/follow/presentation/providers/follow_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_user_app/features/events/presentation/screens/create_event_screen.dart';

class TemplePage extends StatefulWidget {
  final TempleModel templeModel;
  const TemplePage({super.key, required this.templeModel});

  @override
  State<TemplePage> createState() => _TemplePageState();
}

class _TemplePageState extends State<TemplePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TempleModel? _updatedTemple;

  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkOwnership();
    _fetchTempleDetails();
  }

  Future<void> _checkOwnership() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('user_id');
    if (mounted && currentUserId != null) {
      setState(() {
        _isOwner = currentUserId == widget.templeModel.id;
      });
    }
  }

  void _fetchTempleDetails() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final updated = await api.getTempleById(widget.templeModel.id);
      if (mounted) {
        setState(() {
          _updatedTemple = updated;
        });
      }
    } catch (e) {
      debugPrint('Error fetching temple details: $e');
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
    final temple = _updatedTemple ?? widget.templeModel;
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
                          organizerId: temple.id,
                          organizerType: 'temple',
                        ),
                      ),
                    );
                    if (result == true && mounted) {
                       // Refresh page state and Fetch events
                       setState(() {});
                       Provider.of<EventsProvider>(fabContext, listen: false).fetchEventsByOrganizer(temple.id);
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
          length: 4,
          child: Builder(
            builder: (innerContext) {
              return RefreshIndicator(
                onRefresh: () async {
                  // 1. Refresh Temple Details
                  // We can't await _fetchTempleDetails easily as it's void, but we can call it.
                  // Ideally refactor _fetchTempleDetails to return Future, but for now just calling it is okay 
                  // or we can copy logic here.
                  try {
                    final api = Provider.of<ApiService>(innerContext, listen: false);
                    final updated = await api.getTempleById(widget.templeModel.id);
                    if (mounted) {
                      setState(() {
                         _updatedTemple = updated;
                      });
                    }
                  } catch (e) {
                     debugPrint('Error refreshing temple: $e');
                  }

                  // 2. Refresh Providers
                  // Events
                  await Provider.of<EventsProvider>(innerContext, listen: false).fetchEvents(); 
                  
                  // Posts & Follows
                  final followProvider = Provider.of<FollowProvider>(innerContext, listen: false);
                  final postProvider = Provider.of<PostsProvider>(innerContext, listen: false);
                  
                  await Future.wait([
                     followProvider.loadFollowers(widget.templeModel.id),
                     followProvider.loadFollowing(widget.templeModel.id),
                     postProvider.loadUserPostCount(widget.templeModel.id),
                  ]);
                },
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverAppBar(
                      expandedHeight: 280,
                      pinned: true,
                      stretch: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          temple.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Hero(
                              tag: temple.imageUrl,
                              child: Image.network(
                                temple.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.temple_hindu,
                                      size: 64,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  );
                                },
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
                                  backgroundImage: NetworkImage(temple.profilePic),
                                  onBackgroundImageError: (_, __) {}, // Handled by child
                                  child: temple.profilePic.isEmpty || temple.profilePic.contains('placeholder')
                                      ? Icon(Icons.temple_hindu, size: 40, color: theme.colorScheme.onSurfaceVariant)
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
                      ProfileStats(
                        profile: temple,
                        onFollowersTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowersScreen(
                                entityId: temple.id,
                                title: '${temple.name} ${AppLocalizations.of(context)!.followers}',
                              ),
                            ),
                          );
                        },
                      ),
                      ProfileActions(profile: temple),
                      ProfileTabs(
                        tabController: _tabController,
                        profile: temple,
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
