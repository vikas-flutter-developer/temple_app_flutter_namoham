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
import '../../../../widgets/custom_widgets/custom_network_image.dart';
import 'package:flutter_user_app/features/temples/presentation/tabs/temple_about_tab.dart';
import 'package:flutter_user_app/features/temples/presentation/tabs/temple_gallery_tab.dart';
import 'package:flutter_user_app/features/temples/presentation/tabs/temple_calender_tab.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_user_app/core/util/share_helper.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
        // backgroundColor: Colors.white, // Removed for dark mode
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
        body: RefreshIndicator(
          onRefresh: () async {
            try {
              final api = Provider.of<ApiService>(context, listen: false); // context is fine here as it's from build
              final updated = await api.getTempleById(widget.templeModel.id);
              if (mounted) {
                setState(() {
                   _updatedTemple = updated;
                });
              }
            } catch (e) {
               debugPrint('Error refreshing temple: $e');
            }

            await Provider.of<EventsProvider>(context, listen: false).fetchEvents(); 
            
            final followProvider = Provider.of<FollowProvider>(context, listen: false);
            final postProvider = Provider.of<PostsProvider>(context, listen: false);
            
            await Future.wait([
               followProvider.loadFollowers(widget.templeModel.id),
               followProvider.loadFollowing(widget.templeModel.id),
               postProvider.loadUserPostCount(widget.templeModel.id),
            ]);
          },
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 280, // Reduced from 320 for better proportion
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black26, // Semi-transparent dark background
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
                      CustomNetworkImage(
                        imageUrl: temple.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.temple_hindu, size: 64, color: Colors.grey),
                        ),
                      ),


                      // Share Button (Floating on bottom right of image)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: () {
                            ShareHelper.showTempleShareSheet(context, temple.id, temple.name);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
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
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Website Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              temple.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (temple.website.isNotEmpty)
                            TextButton(
                              onPressed: () async {
                                final url = Uri.parse(temple.website);
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
                                  color: Color(0xFF29D0FF), // Cyan/Blue
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      // Rating Row Removed as per request
                      
                      // Stats and Actions shifted up together
                      Transform.translate(
                        offset: const Offset(0, -12.0),
                        child: Column(
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
                            ProfileActions(
                              profile: temple,
                              isOwner: _isOwner,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Tab Bar (Sticky)
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
                      Tab(text: AppLocalizations.of(context)!.gallery),
                      Tab(text: AppLocalizations.of(context)!.calendar),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ],
            body: Transform.translate(
              offset: const Offset(0, -12.0),
              child: TabBarView(
                controller: _tabController,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AboutTab(profile: temple),
                  ),
                  GalleryTab(templeId: temple.id, templeName: temple.name),
                  CalendarTab(templeId: temple.id),
                ],
              ),
            ),
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
  double get minExtent => _tabBar.preferredSize.height + 1; // plus border?
  @override
  double get maxExtent => _tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Transform.translate(
      offset: const Offset(0, -12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
