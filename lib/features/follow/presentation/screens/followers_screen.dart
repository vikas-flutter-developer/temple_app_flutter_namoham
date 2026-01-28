import 'package:flutter/material.dart';
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

class _FollowersView extends StatelessWidget {
  final String title;
  final String entityId;

  const _FollowersView({required this.title, required this.entityId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Consumer<FollowProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingFollowers && provider.followers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.followers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${provider.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => provider.loadFollowers(entityId),
                      child: const Text('Retry'),
                    )
                  ],
                ),
              ),
            );
          }

          if (provider.followers.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.loadFollowers(entityId),
              child: ListView(
                children: const [
                  SizedBox(height: 160),
                  Center(child: Text('No followers yet.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadFollowers(entityId),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: provider.followers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
              final f = provider.followers[index];
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
          );
        },
      ),
    );
  }
}
