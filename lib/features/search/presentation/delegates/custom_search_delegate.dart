import 'package:flutter/material.dart';
import 'package:flutter_user_app/core/api/api_service.dart';
import 'package:flutter_user_app/features/creator/data/model/creators_model.dart';
import 'package:flutter_user_app/features/temples/data/models/temple_model.dart';
// Error fixed: Import FollowItem from following_page.dart
import 'package:flutter_user_app/features/profile/presentation/screens/following_page.dart';
import 'package:flutter_user_app/widgets/custom_widgets/follow_card.dart';
import 'package:flutter_user_app/core/helper/navigation_helper.dart';
import 'package:flutter_user_app/features/temples/presentation/screens/temple_page.dart';
import 'package:flutter_user_app/features/creator/presentation/screens/creator_page.dart';
import 'package:provider/provider.dart';
import 'package:flutter_user_app/features/follow/presentation/providers/follow_provider.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';

class CustomSearchDelegate extends SearchDelegate<String> {
  final ApiService apiService;

  CustomSearchDelegate({required this.apiService});

  @override
  String get searchFieldLabel => 'Search...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return Container();
    }

    return FutureBuilder<List<FollowItem>>(
      future: _search(context, query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.noResultsFound),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
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
                  _handleToggleFollow(context, item);
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Container();
    }
    
    // Optional: Implement live search or suggestions here. 
    // For simplicity, we just allow the user to submit the search.
    return ListTile(
      leading: const Icon(Icons.search),
      title: Text(query),
      onTap: () {
        showResults(context);
      },
    );
  }

  Future<List<FollowItem>> _search(BuildContext context, String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    try {
      // 1. Search Temples
      List<TempleModel> temples = [];
      try {
        temples = await apiService.searchTemples(q);
      } catch (e) {
        debugPrint('Search Temples failed: $e');
      }

      // 2. Search Creators
      List<CreatorModel> creators = [];
      try {
        creators = await apiService.searchCreators(q);
      } catch (e) {
        debugPrint('Search Creators failed: $e');
      }

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

      return [...templeItems, ...creatorItems];
    } catch (e) {
      debugPrint("Error in search delegate: $e");
      return [];
    }
  }

  Future<void> _handleToggleFollow(BuildContext context, FollowItem item) async {
    final followProvider = Provider.of<FollowProvider>(context, listen: false);
    final type = item.isPerson ? 'Creator' : 'Temple';
    final isCurrentlyFollowing = item.isFollowing;

    bool success;
    if (isCurrentlyFollowing) {
      success = await followProvider.unfollow(
        followingId: item.id, 
        followingType: type.toLowerCase()
      );
      if (success && context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppLocalizations.of(context)!.unfollowed(item.name))),
         );
      }
    } else {
      success = await followProvider.follow(followingId: item.id, followingType: type);
      if (success && context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppLocalizations.of(context)!.followed(item.name))),
         );
      }
    }
    
    // Note: In a FutureBuilder, we can't easily force a rebuild without setState or a Stream.
    // However, since FollowProvider notifies listeners, if we were listening to it, it would update.
    // `buildResults` is not listening to provider directly (it uses FutureBuilder).
    // The `FollowCard` might update if it listens to something, but it usually takes props.
    // 
    // To trigger a UI update for the button state, we might need to trigger a rebuild of the results.
    // One way is to set query = query which triggers buildResults? No.
    // 
    // Ideally, FollowCard should perhaps listen to the provider if we want instant local updates,
    // or we just accept that the list won't refresh until the next search.
    // 
    // Providing `showResults(context)` again behaves like a refresh.
    if (success) {
      // Triggering a refresh of the search results
      showResults(context);
    }
  }
}
