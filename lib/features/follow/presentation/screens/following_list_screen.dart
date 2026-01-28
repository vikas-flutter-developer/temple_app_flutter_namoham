import 'package:flutter/material.dart';
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

class _FollowingListView extends StatelessWidget {
  const _FollowingListView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Following'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Consumer<FollowProvider>(
        builder: (context, provider, child) {
          if (provider.userType != null && provider.userType != 'User') {
            return const Center(child: Text('Only users have a following list.'));
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
                      child: const Text('Retry'),
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
                children: const [
                  SizedBox(height: 160),
                  Center(child: Text('You are not following anyone yet.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadMyFollowing(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: provider.myFollowing.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = provider.myFollowing[index];

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
                              final ok = await provider.unfollow(item.followingId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok
                                          ? 'Unfollowed ${item.followingName}'
                                          : (provider.error ?? 'Failed to unfollow'),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text('Unfollow'),
                          ),
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
