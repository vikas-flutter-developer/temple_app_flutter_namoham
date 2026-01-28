import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_service.dart';
import '../providers/messages_provider.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService.create();

    return ChangeNotifierProvider(
      create: (_) => MessagesProvider(apiService)..loadConversations(),
      child: const _ConversationsView(),
    );
  }
}

class _ConversationsView extends StatelessWidget {
  const _ConversationsView();

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    if (now.difference(local).inDays == 0) {
      return DateFormat('hh:mm a').format(local);
    }
    return DateFormat('dd MMM').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          Consumer<MessagesProvider>(
            builder: (context, provider, child) {
              final count = provider.unreadCount;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: count > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$count unread',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              );
            },
          )
        ],
      ),
      body: Consumer<MessagesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingConversations && provider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${provider.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => provider.loadConversations(),
                      child: const Text('Retry'),
                    )
                  ],
                ),
              ),
            );
          }

          if (provider.conversations.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.loadConversations(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'No conversations yet.\n\nOpen any Temple/Creator profile and tap “Message” to start a chat.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadConversations(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: provider.conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final c = provider.conversations[index];

                return Card(
                  color: theme.colorScheme.surfaceContainer,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      backgroundImage: c.otherUserImage.trim().isNotEmpty
                          ? NetworkImage(c.otherUserImage)
                          : null,
                      child: c.otherUserImage.trim().isEmpty
                          ? Text(
                              c.otherUserName.isNotEmpty
                                  ? c.otherUserName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      c.otherUserName.isNotEmpty ? c.otherUserName : c.otherUserId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      c.lastMessage.isNotEmpty ? c.lastMessage : 'Tap to open chat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTime(c.lastMessageAt),
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        if (c.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${c.unreadCount}',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onTap: () async {
                      // Pass provider to next route (scoped provider)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: provider,
                            child: ChatScreen(conversation: c),
                          ),
                        ),
                      );
                    },
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
