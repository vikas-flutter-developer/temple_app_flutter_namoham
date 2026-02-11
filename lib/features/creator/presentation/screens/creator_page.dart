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
import 'package:flutter_user_app/features/creator/presentation/tabs/creator_about_tab.dart';
import 'package:flutter_user_app/features/creator/presentation/tabs/creator_gallery_tab.dart';
import 'package:flutter_user_app/features/creator/presentation/tabs/creator_calender_tab.dart';
import 'package:flutter_user_app/features/creator/presentation/tabs/creator_review_tab.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_user_app/features/posts/presentation/provider/posts_provider.dart';
import 'package:flutter_user_app/features/posts/domain/usecase/get_posts_usecase.dart';
import 'package:flutter_user_app/features/posts/data/repository/post_repository_impl.dart';
import 'package:flutter_user_app/features/follow/presentation/providers/follow_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../widgets/custom_widgets/custom_network_image.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
        backgroundColor: Colors.white,
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
          length: 4,
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
                      backgroundColor: Colors.white,
                      leading: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Main Image
                            Hero(
                              tag: creator.id,
                                child: CustomNetworkImage(
                                  imageUrl: creator.displayImage,
                                  fit: BoxFit.cover,
                                  errorWidget: Container(
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.person, size: 64, color: Colors.grey),
                                  ),
                                ),
                            ),

                            // Share Button (Floating on bottom right of image)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: GestureDetector(
                                onTap: () {
                                  Share.share('Check out ${creator.creatorName} on Temple App!${creator.website.isNotEmpty ? '\n\n${creator.website}' : ''}'); 
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.share, color: Colors.black87),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and Website Row (matching Temple UI)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    creator.creatorName,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                if (creator.website.isNotEmpty)
                                  TextButton(
                                    onPressed: () async {
                                      final url = Uri.parse(creator.website);
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url, mode: LaunchMode.externalApplication);
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Could not launch website')),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text(
                                      'Website',
                                      style: TextStyle(
                                        color: Color(0xFF29D0FF),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Stats
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
                            
                            // Actions
                            CreatorProfileActions(profile: creator),
                          ],
                        ),
                      ),
                    ),
                    
                    // Tab Bar (Sticky) - 4 tabs matching Temple
                    SliverPersistentHeader(
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          labelColor: const Color(0xFF29D0FF),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: const Color(0xFF29D0FF),
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                          tabs: [
                            Tab(text: AppLocalizations.of(context)!.about),
                            Tab(text: AppLocalizations.of(context)!.review),
                            Tab(text: AppLocalizations.of(context)!.gallery),
                            Tab(text: AppLocalizations.of(context)!.calendar),
                          ],
                        ),
                      ),
                      pinned: true,
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CreatorAboutTab(profile: creator),
                      ),
                      CreatorReviewTab(creator: creator),
                      CreatorGalleryTab(creatorId: creator.id),
                      CreatorCalendarTab(creatorId: creator.id),
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: shrinkOffset > 0 // Only show shadow when stuck/scrolled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          _tabBar,
          if (shrinkOffset == 0) const Divider(height: 1), // Only show divider when expanded
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
