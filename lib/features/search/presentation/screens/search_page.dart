import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/features/creator/data/model/creators_model.dart';
import 'package:flutter_user_app/features/creator/presentation/screens/creator_page.dart';
import 'package:flutter_user_app/features/temples/data/models/temple_model.dart';
import 'package:flutter_user_app/features/temples/presentation/screens/temple_page.dart';
import 'package:flutter_user_app/features/profile/presentation/screens/following_page.dart';
import 'package:flutter_user_app/widgets/card_widgets/custom_creator_card.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_page_bar.dart';
import 'package:flutter_user_app/widgets/card_widgets/custom_temple_card.dart';
import 'package:flutter_user_app/widgets/custom_widgets/follow_card.dart';
import 'package:provider/provider.dart';
import 'package:flutter_user_app/features/follow/presentation/providers/follow_provider.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Search State
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  // Used local variable "Timer" requires import 'dart:async'
  Timer? _debounceTimer;
  bool _isSearchLoading = false;
  List<FollowItem> _searchResults = [];

  // API Service
  late ApiService _apiService;

  // Data State for "Popular" sections
  List<TempleModel> _popularTemples = [];
  List<CreatorModel> _popularCreators = [];

  bool _isInitialLoading = true;
  bool _isCreatorsLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _apiService = Provider.of<ApiService>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    // 1. Fetch Popular Temples (All Temples) on Init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPopularTemples();
      _loadPopularCreators();
    });

    // 2. Refresh Following
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Provider.of<FollowProvider>(context, listen: false).loadMyFollowing();
      } catch (e) {
        debugPrint("FollowProvider not found: $e");
      }
    });
    
    // 3. Listener for search text clearing
    _searchController.addListener(() {
      if (_searchController.text.isEmpty && _searchQuery.isNotEmpty) {
        setState(() {
          _searchQuery = '';
          _searchResults = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Fetch initial data for "Most Popular Temple" section
  Future<void> _loadPopularTemples() async {
    try {
      final temples = await _apiService.getTemples();
      if (mounted) {
        setState(() {
          _popularTemples = temples;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading popular temples: $e");
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  // Fetch initial data for "Most Popular Creator" section
  Future<void> _loadPopularCreators() async {
    if (mounted) {
      setState(() {
        _isCreatorsLoading = true;
      });
    }

    try {
      final creatorsResponse = await _apiService.getCreators(page: 1, limit: 50);
      if (mounted) {
        setState(() {
          _popularCreators = creatorsResponse.creators;
          _isCreatorsLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading popular creators: $e");
      if (mounted) {
        setState(() {
          _popularCreators = [];
          _isCreatorsLoading = false;
        });
      }
    }
  }

  // Validate and handle search input changes
  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        setState(() {
          _searchQuery = query;
          _isSearchLoading = true;
        });
        _performSearch(query);
      } else {
        setState(() {
          _searchQuery = '';
          _searchResults = [];
          _isSearchLoading = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    try {
      // 1. Search Temples
      List<TempleModel> temples = [];
      try {
        temples = await _apiService.searchTemples(q);
      } catch (e) {
        debugPrint('Search Temples failed: $e');
      }

      // 2. Search Creators
      List<CreatorModel> creators = [];
      try {
        creators = await _apiService.searchCreators(q);
      } catch (e) {
        debugPrint('Search Creators failed: $e');
      }

      if (!mounted) return;

      final followProvider = Provider.of<FollowProvider>(context, listen: false);

      // Map Temples
      final templeItems = temples.map((t) {
        final isFollowing = followProvider.isFollowing(t.id);
        return FollowItem(
          id: t.id,
          name: t.name,
          location: t.location,
          distance: '',
          rating: t.rating,
          reviews: t.totalReviews,
          image: t.imageUrl,
          isPerson: false,
          isFollowing: isFollowing,
          followersCount: t.followers,
          data: t,
        );
      }).toList();

      // Map Creators
      final creatorItems = creators.map((c) {
        final isFollowing = followProvider.isFollowing(c.id);
        return FollowItem(
          id: c.id,
          name: c.creatorName,
          location: c.address.isNotEmpty ? c.address : 'India',
          image: c.displayImage,
          isPerson: true,
          username: c.title,
          isFollowing: isFollowing,
          followersCount: c.followers,
          data: c,
        );
      }).toList();

      setState(() {
        _searchResults = [...templeItems, ...creatorItems];
        _isSearchLoading = false;
      });
    } catch (e) {
      debugPrint("Error in search: $e");
      if (mounted) {
        setState(() {
          _isSearchLoading = false;
        });
      }
    }
  }

  Future<void> _handleToggleFollow(FollowItem item) async {
    final followProvider = Provider.of<FollowProvider>(context, listen: false);
    final type = item.isPerson ? 'Creator' : 'Temple';
    final isCurrentlyFollowing = item.isFollowing;

    bool success;
    if (isCurrentlyFollowing) {
      success = await followProvider.unfollow(
        followingId: item.id, 
        followingType: type.toLowerCase()
      );
      if (success && mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppLocalizations.of(context)!.unfollowed(item.name))),
         );
      }
    } else {
      success = await followProvider.follow(followingId: item.id, followingType: type);
      if (success && mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppLocalizations.of(context)!.followed(item.name))),
         );
      }
    }
    
    // Refresh search results to update UI state if needed
    // Ideally we update the local list item directly for immediate feedback
    if (success && mounted) {
       setState(() {
         final index = _searchResults.indexWhere((element) => element.id == item.id);
         if (index != -1) {
           _searchResults[index] = item.copyWith(isFollowing: !isCurrentlyFollowing);
         }
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    final bool isSearchActive = _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomPageBar(title: l10n.search),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: SearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              elevation: WidgetStateProperty.all(1),
              backgroundColor: WidgetStateProperty.all(Colors.white),
              hintText: 'Search...',
              padding: const WidgetStatePropertyAll<EdgeInsets>(
                  EdgeInsets.symmetric(horizontal: 16)),
              leading: Icon(
                Icons.search,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              trailing: _searchController.text.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    ]
                  : null,
            ),
          ),

          Expanded(
            child: isSearchActive 
              ? _buildSearchResults()
              : _buildPopularContent(theme, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noResultsFound),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (item.data != null) {
              if (!item.isPerson && item.data is TempleModel) {
                navigateToPage(context, TemplePage(templeModel: item.data));
              } else if (item.isPerson && item.data is CreatorModel) {
                navigateToPage(context, CreatorPage(creator: item.data));
              }
            }
          },
          child: FollowCard(
            item: item,
            onToggleFollow: () {
              _handleToggleFollow(item);
            },
          ),
        );
      },
    );
  }

  Widget _buildPopularContent(ThemeData theme, AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _loadPopularTemples(),
          _loadPopularCreators(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Most Popular Temple Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.mostPopularTemple,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: _isInitialLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _popularTemples.isEmpty
                    ? Center(child: Text(l10n.noTemplesFound))
                    : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _popularTemples.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final temple = _popularTemples[index];
                    return Hero(
                      tag: temple.id,
                      child: TempleCard(
                        templeModel: temple,
                        onTap: () {
                          navigateToPage(context, TemplePage(templeModel: temple));
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Most Popular Creator Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.mostPopularCreator,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: _isCreatorsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _popularCreators.isEmpty
                        ? const Center(child: Text('No creators found'))
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _popularCreators.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final creator = _popularCreators[index];
                              return CreatorCard(
                                creator: creator,
                                onTap: () {
                                  navigateToPage(context, CreatorPage(creator: creator));
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}