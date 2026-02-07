import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/features/creator/data/model/creators_model.dart';
import 'package:flutter_user_app/features/creator/presentation/screens/creator_page.dart';
import 'package:flutter_user_app/features/profile/presentation/screens/following_page.dart';
import 'package:flutter_user_app/features/temples/data/models/temple_model.dart';
import 'package:flutter_user_app/features/temples/presentation/screens/temple_page.dart';
import 'package:flutter_user_app/widgets/card_widgets/custom_creator_card.dart';
import 'package:flutter_user_app/widgets/custom_widgets/custom_page_bar.dart';
import 'package:flutter_user_app/widgets/card_widgets/custom_temple_card.dart';
import 'package:flutter_user_app/widgets/custom_widgets/follow_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_user_app/features/follow/presentation/providers/follow_provider.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';

// ERROR FIXED: Removed the import of 'temples_dummy_data.dart' because it is no longer needed.

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool _isSearchActive = false;
  String _searchQuery = '';
  String selectedCategory = 'All';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<String> categories = [
    'All',
    'Temples',
    'Creators',
  ];

  // Initialize API Service
  late ApiService _apiService;

  // Data State
  List<FollowItem> _searchResults = [];
  List<TempleModel> _popularTemples = [];
  List<CreatorModel> _popularCreators = [];
  
  // Follow State
  // Follow State managed by FollowProvider

  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _isCreatorsLoading = true;
  Timer? _debounceTimer;
  
  // Search counts
  int _totalCount = 0;
  int _templesCount = 0;
  int _creatorsCount = 0;

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

    // 3. User's Following List is handled directly by FollowProvider
    // which should already be initialized if used within the app tree.
    // We can explicitly refresh it here if needed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FollowProvider>(context, listen: false).loadMyFollowing();
    });

    // 4. Setup Search Listeners
    _searchFocusNode.addListener(() {
      // Rebuild to update UI if needed (e.g. focus border)
      setState(() {});
    });

    _searchController.addListener(() {
      setState(() {
        _isSearchActive = _searchController.text.isNotEmpty;
      });
    });
  }

  // Toggle follow status
  Future<void> _handleToggleFollow(FollowItem item) async {
    final followProvider = Provider.of<FollowProvider>(context, listen: false);
    
    // Determine follow type
    final type = item.isPerson ? 'Creator' : 'Temple';
    final isCurrentlyFollowing = item.isFollowing;
    
    bool success;
    
    if (isCurrentlyFollowing) {
       success = await followProvider.unfollow(
           followingId: item.id, 
           followingType: type.toLowerCase()
       );
       if (success) _showToast(AppLocalizations.of(context)!.unfollowed(item.name));
    } else {
       success = await followProvider.follow(followingId: item.id, followingType: type);
       if (success) _showToast(AppLocalizations.of(context)!.followed(item.name));
    }

    // Reload search results from API to get updated follower counts
    if (success && mounted) {
      await _loadSearchResults();
    } else if (!success && mounted) {
      _showToast(followProvider.error ?? 'Action failed');
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Fetch search suggestions and results with debounce
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _totalCount = 0;
        _templesCount = 0;
        _creatorsCount = 0;
        _isSearchActive = false;
      });
      return;
    }

    // Debounce search to avoid too many API calls
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      // Trigger the actual search
      _loadSearchResults();
    });
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
      print("Error loading popular temples: $e");
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
      print("Error loading popular creators: $e");
      if (mounted) {
        setState(() {
          _popularCreators = [];
          _isCreatorsLoading = false;
        });
      }
    }
  }

  // Fetch search results using unified search API
  Future<void> _loadSearchResults() async {
    if (_searchQuery.isEmpty) return;

    final q = _searchQuery.trim();
    if (q.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    print('SEARCH_PAGE: Starting search for "$q"');

    try {
      // 1) Temples: use backend search endpoint
      // GET /temples/search?q=...
      List<TempleModel> temples = [];
      try {
        temples = await _apiService.searchTemples(q);
        print('SEARCH_PAGE: Fetched ${temples.length} temples from API');
      } catch (e) {
        print('SEARCH_PAGE: API Search Temples failed: $e');
        // Continue to local search
      }

      // Local Fallback for Temples (search in _popularTemples)
      final localTempleMatches = _popularTemples.where((t) {
        final nameLower = t.name.toLowerCase();
        final qLower = q.toLowerCase();
        // Use startsWith for short queries to improve relevance (e.g. "d" shouldn't match "Golden")
        if (q.length < 3) {
          return nameLower.startsWith(qLower);
        }
        return nameLower.contains(qLower) || 
               t.location.toLowerCase().contains(qLower);
      }).toList();
      print('SEARCH_PAGE: Found ${localTempleMatches.length} local temple matches');

      // Merge and Deduplicate Temples (prefer API result)
      final Set<String> templeNames = temples.map((t) => t.name).toSet();
      for (var local in localTempleMatches) {
        if (!templeNames.contains(local.name)) {
          temples.add(local);
        }
      }

      final followProvider = Provider.of<FollowProvider>(context, listen: false);

      final templeItems = temples
          .map(
            (t) {
              // Check follow status via Provider
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
                isFollowing: isFollowing, // Set status from provider
                followersCount: t.followers, // Pass follower count
                data: t, // Pass full model
              );
            },
          )
          .toList();

      // 2) Creators: use backend search endpoint
      // GET /creators/search?q=...
      List<CreatorModel> creators = [];
      try {
        creators = await _apiService.searchCreators(q);
        print('SEARCH_PAGE: Fetched ${creators.length} creators from API');
      } catch (e) {
        print('SEARCH_PAGE: API Search Creators failed: $e');
        // Continue to local search
      }

      // Local Fallback for Creators (search in _popularCreators)
      final localCreatorMatches = _popularCreators.where((c) {
        final nameLower = c.creatorName.toLowerCase();
        final qLower = q.toLowerCase();
        // Use startsWith for short queries
        if (q.length < 3) {
          return nameLower.startsWith(qLower);
        }
        return nameLower.contains(qLower) || 
               c.title.toLowerCase().contains(qLower);
      }).toList();
      print('SEARCH_PAGE: Found ${localCreatorMatches.length} local creator matches');

      // Merge and Deduplicate Creators
      final Set<String> creatorNames = creators.map((c) => c.creatorName).toSet();
      for (var local in localCreatorMatches) {
        if (!creatorNames.contains(local.creatorName)) {
          creators.add(local);
        }
      }
      
      final creatorItems = creators
          .map(
            (c) {
              // Check follow status via Provider
              final isFollowing = followProvider.isFollowing(c.id);
              return FollowItem(
                id: c.id,
                name: c.creatorName,
                location: c.address.isNotEmpty ? c.address : 'India',
                image: c.displayImage,
                isPerson: true,
                username: c.title,
                isFollowing: isFollowing, // Set status from provider
                followersCount: c.followers, // Pass follower count
                data: c, // Pass full model
              );
            },
          )
          .toList();

      if (mounted) {
        setState(() {
          // Store combined results; category tabs will filter this list.
          _searchResults = [...templeItems, ...creatorItems];
          _templesCount = templeItems.length;
          _creatorsCount = creatorItems.length;
          _totalCount = _templesCount + _creatorsCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error search critical failure: $e");
      if (mounted) {
        setState(() {
          _searchResults = [];
          _totalCount = 0;
          _templesCount = 0;
          _creatorsCount = 0;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error occurred. Please try again.')),
        );
      }
    }
  }

  List<FollowItem> get _filteredResults {
    if (_searchQuery.isEmpty) return [];

    // Filter by category
    if (selectedCategory == 'Temples') {
      return _searchResults.where((item) => !item.isPerson).toList();
    } else if (selectedCategory == 'Creators') {
      return _searchResults.where((item) => item.isPerson).toList();
    }

    return _searchResults;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomPageBar(title: l10n.search),
      body: Column(
        children: [
          Container(
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Move padding here
            decoration: BoxDecoration(
              // 1. Clean Background Color
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3), 
              
              // 2. smooth rounded corners
              borderRadius: BorderRadius.circular(16),
              
              // 3. Optional: Add a subtle border if you want a "outlined" look
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2), 
                width: 1
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center, // Vertically centers text
              style: TextStyle(
                color: theme.colorScheme.onSurface, 
                fontSize: 16 // Explicit font size helps alignment
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _isSearchActive = value.isNotEmpty;
                });
                // Auto-search as user types (debounced)
                _onSearchChanged(value);
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _debounceTimer?.cancel();
                  _loadSearchResults();
                }
              },
              decoration: InputDecoration(
                isDense: true, // Reduces default height bloat
                filled: false, // We handled color in the Container
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Search...',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 16,
                ),
                // 4. Use a native Icon instead of the SVG background icon
                prefixIcon: Icon(
                  Icons.search,
                  size: 27,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                // 5. Clean logic for the clear button
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _isSearchActive = false;
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),

          Expanded(
            child: _isSearchActive
                ? _buildSearchResultsView(theme)
                : _buildRegularContent(theme),
          ),
        ],
      ),
    );
  }

  Widget buildCategory(String categoryKey) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isSelected = selectedCategory == categoryKey;
    
    String displayLabel;
    switch (categoryKey) {
      case 'Temples':
        displayLabel = l10n.temples;
        break;
      case 'Creators':
        displayLabel = l10n.creators;
        break;
      case 'All':
      default:
        displayLabel = l10n.all;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = categoryKey;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.primaryContainer.withAlpha(100),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        child: Center(
          child: Text(
            displayLabel,
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onPrimaryContainer,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultsView(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        // Search count info
        if (_totalCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  l10n.foundResults(_totalCount),
                  style: TextStyle(
                    color: theme.colorScheme.outline,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                if (_templesCount > 0)
                  _buildCountChip(l10n.templesCount(_templesCount), theme),
                if (_creatorsCount > 0)
                  _buildCountChip(l10n.creatorsCount(_creatorsCount), theme),
              ],
            ),
          ),
        Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children:
                categories.map((category) => buildCategory(category)).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildFilteredResultsWidget(),
        ),
      ],
    );
  }

  // Show all temples in search results
  void _showAllTemples() {
    // Map all popular temples to search results
    final followProvider = Provider.of<FollowProvider>(context, listen: false);
    final List<FollowItem> items = _popularTemples
        .map(
          (temple) {
            final isFollowing = followProvider.isFollowing(temple.id);
            return FollowItem(
              id: temple.id,
              name: temple.name,
              location: temple.location,
              distance: '',
              rating: temple.rating,
              reviews: temple.totalReviews,
              image: temple.imageUrl,
              isPerson: false,
              isFollowing: isFollowing,
              followersCount: temple.followers,
              data: temple,
            );
          },
        )
        .toList();

    setState(() {
      selectedCategory = 'Temples';
      _searchResults = items;
      _totalCount = items.length;
      _templesCount = items.length;
      _creatorsCount = 0;
      _isSearchActive = true;
      _searchQuery = 'All Temples';
      _searchController.text = 'All Temples';
    });
  }

  // Show all creators in search results (Fetch larger list for "See All")
  Future<void> _showAllCreators() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch a larger batch for "See All"
      final response = await _apiService.getCreators(page: 1, limit: 1000);
      final creators = response.creators;

      final followProvider = Provider.of<FollowProvider>(context, listen: false);
      final List<FollowItem> items = creators
          .map(
            (c) {
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
            },
          )
          .toList();

      if (!mounted) return;

      setState(() {
        selectedCategory = 'Creators';
        _searchResults = items;
        _totalCount = items.length;
        _templesCount = 0;
        _creatorsCount = items.length;
        _isSearchActive = true;
        _searchQuery = 'All Creators';
        _searchController.text = 'All Creators';
        _isLoading = false;
      });
    } catch (e) {
      print("Error showing all creators: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildCountChip(String label, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildFilteredResultsWidget() {
    final results = _filteredResults;
    if (results.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadSearchResults,
        child: ListView(
          children: [
            SizedBox(height: 100),
            Center(child: Text(AppLocalizations.of(context)!.noResultsFound)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadSearchResults,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final item = results[index];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              print('SEARCH_PAGE: Tapped on ${item.name}');
              if (item.data != null) {
                print('SEARCH_PAGE: Has data: ${item.data.runtimeType}');
                if (!item.isPerson && item.data is TempleModel) {
                  print('SEARCH_PAGE: Navigating to TemplePage');
                  navigateToPage(context, TemplePage(templeModel: item.data));
                } else if (item.isPerson && item.data is CreatorModel) {
                  print('SEARCH_PAGE: Navigating to CreatorPage');
                  navigateToPage(context, CreatorPage(creator: item.data));
                } else {
                  print('SEARCH_PAGE: Data type mismatch or unknown');
                }
              } else {
                 print('SEARCH_PAGE: Data is null for ${item.name}');
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: Details not found for ${item.name}')),
                 );
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
      ),
    );
  }

  Widget _buildRegularContent(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Most Popular Temple Section (Connected to API)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.mostPopularTemple,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // Show all temples by triggering search
                    _showAllTemples();
                  },
                  child: Text(l10n.seeAll, style: TextStyle(color: theme.colorScheme.primary)),
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
                    createRectTween: (Rect? begin, Rect? end) {
                      return CustomRectTween(begin: begin, end: end);
                    },
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

            // Most Popular Creator Section (Connected to API)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.mostPopularCreator,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // TODO: add a dedicated creators list page if needed
                TextButton(
                  onPressed: () async {
                    await _showAllCreators();
                  },
                  child: Text(l10n.seeAll, style: TextStyle(color: theme.colorScheme.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: _isCreatorsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _popularCreators.isEmpty
                      ? Center(child: Text(l10n.noCreatorsFound))
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _popularCreators.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final creator = _popularCreators[index];
                            return Hero(
                              tag: creator.id,
                              child: CreatorCard(
                                creator: creator,
                                onTap: () {
                                  navigateToPage(
                                    context,
                                    CreatorPage(creator: creator),
                                  );
                                },
                              ),
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

class CustomRectTween extends RectTween {
  CustomRectTween({required super.begin, required super.end});

  @override
  Rect lerp(double t) {
    final Rect start = begin ?? Rect.zero;
    final Rect endRect = end ?? Rect.zero;
    return Rect.fromLTWH(
      start.left + (endRect.left - start.left) * t,
      start.top + (endRect.top - start.top) * t,
      start.width + (endRect.width - start.width) * t,
      start.height + (endRect.height - start.height) * t,
    );
  }
}