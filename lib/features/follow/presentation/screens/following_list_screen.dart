import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_service.dart';
import '../providers/follow_provider.dart';

class FollowingListScreen extends StatelessWidget {
  const FollowingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService.create();

    return ChangeNotifierProvider(
      create: (_) => FollowProvider(apiService),
      child: const _FollowingListView(),
    );
  }
}

class _FollowingListView extends StatefulWidget {
  const _FollowingListView();

  @override
  State<_FollowingListView> createState() => _FollowingListViewState();
}

class _FollowingListViewState extends State<_FollowingListView> with WidgetsBindingObserver {
  Timer? _refreshTimer;
  static const _refreshInterval = Duration(seconds: 30);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshFollowing();
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      _refreshTimer?.cancel();
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => _refreshFollowing());
  }

  void _refreshFollowing() {
    if (mounted) {
      Provider.of<FollowProvider>(context, listen: false).loadMyFollowing();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.following),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Consumer<FollowProvider>(
        builder: (context, provider, child) {
          final type = provider.userType?.toLowerCase();
          if (provider.userType != null && type != 'user' && type != 'creator' && type != 'temple') {
            return Center(child: Text(AppLocalizations.of(context)!.onlyUsersHaveFollowingList));
          }

          if (provider.isLoading && provider.myFollowing.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.myFollowing.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${provider.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => provider.loadMyFollowing(),
                      child: Text(AppLocalizations.of(context)!.retry),
                    )
                  ],
                ),
              ),
            );
          }

          if (provider.myFollowing.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.loadMyFollowing(),
              child: ListView(
                children: [
                  SizedBox(height: 160),
                  Center(child: Text(AppLocalizations.of(context)!.noFollowingYet)),
                ],
              ),
            );
          }

          // Filter list
          final filteredList = provider.myFollowing.where((item) {
            final query = _searchQuery.toLowerCase();
            return item.followingName.toLowerCase().contains(query) ||
                   item.followingLocation.toLowerCase().contains(query) ||
                   item.followingType.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search following...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              
              // List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.loadMyFollowing(),
                  child: filteredList.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 100),
                            Center(child: Text(_searchQuery.isEmpty 
                                ? AppLocalizations.of(context)!.noFollowingYet
                                : 'No results found',
                            )),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: filteredList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = filteredList[index];

                            return Card(
                              color: theme.colorScheme.surfaceContainer,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                  backgroundImage: item.followingImage.trim().isNotEmpty
                                      ? NetworkImage(item.followingImage)
                                      : null,
                                  child: item.followingImage.trim().isEmpty
                                      ? Text(
                                          item.followingName.isNotEmpty
                                              ? item.followingName[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(item.followingName),
                                subtitle: Text(
                                  [
                                    if (item.followingType.isNotEmpty) item.followingType,
                                    if (item.followingLocation.isNotEmpty) item.followingLocation,
                                  ].join(' • '),
                                ),
                                trailing: provider.isToggling
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : OutlinedButton(
                                        onPressed: () async {
                                          final ok = await provider.unfollow(
                                            followingId: item.followingId,
                                            followingType: item.followingType,
                                          );

                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  ok
                                                      ? AppLocalizations.of(context)!.unfollowed(item.followingName)
                                                      : (provider.error ?? 'Failed to unfollow'),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: Text(AppLocalizations.of(context)!.unfollow),
                                      ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
