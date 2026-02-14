import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_user_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_service.dart';
import '../providers/follow_provider.dart';

class FollowingScreen extends StatelessWidget {
  final String entityId;
  final String title;

  const FollowingScreen({
    super.key,
    required this.entityId,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService.create();

    return ChangeNotifierProvider(
      create: (_) => FollowProvider(apiService)..loadFollowing(entityId),
      child: _FollowingView(title: title, entityId: entityId),
    );
  }
}

class _FollowingView extends StatefulWidget {
  final String title;
  final String entityId;

  const _FollowingView({required this.title, required this.entityId});

  @override
  State<_FollowingView> createState() => _FollowingViewState();
}

class _FollowingViewState extends State<_FollowingView> with WidgetsBindingObserver {
  Timer? _refreshTimer;
  static const _refreshInterval = Duration(seconds: 30);

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
      Provider.of<FollowProvider>(context, listen: false).loadFollowing(widget.entityId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Localize manually if needed, or use existing l10n keys
    // Assuming 'No following yet' exists or using a generic fallback
    final noFollowingText = 'No following yet'; 

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Consumer<FollowProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingFollowing && provider.viewedFollowing.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.viewedFollowing.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.loadFollowing(widget.entityId),
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
                              onPressed: () => provider.loadFollowing(widget.entityId),
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

          if (provider.viewedFollowing.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.loadFollowing(widget.entityId),
              child: ListView(
                children: [
                   const SizedBox(height: 160),
                   Center(child: Text(noFollowingText)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadFollowing(widget.entityId),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: provider.viewedFollowing.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
              final f = provider.viewedFollowing[index];
              return Card(
                color: theme.colorScheme.surfaceContainer,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage: f.followingImage.trim().isNotEmpty
                        ? NetworkImage(f.followingImage)
                        : null,
                    child: f.followingImage.trim().isEmpty
                        ? Text(
                            f.followingName.isNotEmpty
                                ? f.followingName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  title: Text(f.followingName.isNotEmpty ? f.followingName : f.followingId),
                  subtitle: Text(f.followingType),
                ),
              );
              },
            ),
          );
        },
      ),
    );
  }
}
