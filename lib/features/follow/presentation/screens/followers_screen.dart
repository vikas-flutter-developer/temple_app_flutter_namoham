import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_service.dart';
import '../providers/follow_provider.dart';

class FollowersScreen extends StatelessWidget {
  final String entityId;
  final String title;

  const FollowersScreen({
    super.key,
    required this.entityId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService.create();

    return ChangeNotifierProvider(
      create: (_) => FollowProvider(apiService)..loadFollowers(entityId),
      child: _FollowersView(title: title, entityId: entityId),
    );
  }
}

class _FollowersView extends StatefulWidget {
  final String title;
  final String entityId;

  const _FollowersView({required this.title, required this.entityId});

  @override
  State<_FollowersView> createState() => _FollowersViewState();
}

class _FollowersViewState extends State<_FollowersView> with WidgetsBindingObserver {
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
      _refreshFollowers();
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      _refreshTimer?.cancel();
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => _refreshFollowers());
  }

  void _refreshFollowers() {
    if (mounted) {
      Provider.of<FollowProvider>(context, listen: false).loadFollowers(widget.entityId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Consumer<FollowProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingFollowers && provider.followers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.followers.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.loadFollowers(widget.entityId),
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: ${provider.error}'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => provider.loadFollowers(widget.entityId),
                              child: Text(AppLocalizations.of(context)!.retry),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (provider.followers.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.loadFollowers(widget.entityId),
              child: ListView(
                children: [
                  SizedBox(height: 160),
                  Center(child: Text(AppLocalizations.of(context)!.noFollowersYet)),
                ],
              ),
            );
          }

          // Filter list
          final filteredList = provider.followers.where((f) {
            final query = _searchQuery.toLowerCase();
            return (f.followerName.isNotEmpty ? f.followerName : f.followerId).toLowerCase().contains(query) ||
                   f.followerType.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search followers...',
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

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.loadFollowers(widget.entityId),
                  child: filteredList.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: 100),
                            Center(child: Text(_searchQuery.isEmpty
                                ? AppLocalizations.of(context)!.noFollowersYet
                                : 'No results found',
                            )),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: filteredList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                          final f = filteredList[index];
                          return Card(
                            color: theme.colorScheme.surfaceContainer,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                backgroundImage: f.followerImage.trim().isNotEmpty
                                    ? NetworkImage(f.followerImage)
                                    : null,
                                child: f.followerImage.trim().isEmpty
                                    ? Text(
                                        f.followerName.isNotEmpty
                                            ? f.followerName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(f.followerName.isNotEmpty ? f.followerName : f.followerId),
                              subtitle: Text(f.followerType),
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
