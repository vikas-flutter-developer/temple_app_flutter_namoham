import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_service.dart';
import '../providers/messages_provider.dart';
import 'chat_screen.dart';
import '../../../../widgets/custom_widgets/custom_network_image.dart';

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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chats'),
              Tab(text: 'Requests'),
            ],
          ),
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
                              '$count',
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
        body: TabBarView(
          children: [
            // Tab 1: Chats
            Consumer<MessagesProvider>(
              builder: (context, provider, child) {
                if (provider.isLoadingConversations && provider.conversations.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
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
                      // Optional: Filter based on status if API includes pending in main list
                      // if (c.status == 'pending') return const SizedBox.shrink();

                      return Card(
                        color: theme.colorScheme.surfaceContainer,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            child: c.otherUserImage.trim().isNotEmpty
                                ? ClipOval(
                                    child: CustomNetworkImage(
                                      imageUrl: c.otherUserImage,
                                      fit: BoxFit.cover,
                                      width: 40,
                                      height: 40,
                                      errorWidget: Text(
                                        c.otherUserName.isNotEmpty
                                            ? c.otherUserName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    c.otherUserName.isNotEmpty
                                        ? c.otherUserName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                          onTap: () async {
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

            // Tab 2: Requests
            _RequestsList(),
          ],
        ),
      ),
    );
  }
}

class _RequestsList extends StatefulWidget {
  @override
  State<_RequestsList> createState() => _RequestsListState();
}

class _RequestsListState extends State<_RequestsList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagesProvider>().loadPendingRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagesProvider>(
      builder: (context, provider, child) {
        final requests = provider.pendingRequests;

        if (requests.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => provider.loadPendingRequests(),
            child: ListView(
              children: const [
                 SizedBox(height: 100),
                 Center(child: Text('No pending requests')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadPendingRequests(),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final req = requests[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: req.otherUserImage.isNotEmpty
                        ? ClipOval(
                            child: CustomNetworkImage(
                              imageUrl: req.otherUserImage,
                              fit: BoxFit.cover,
                              width: 40,
                              height: 40,
                              errorWidget: const Icon(Icons.person),
                            ),
                          )
                        : const Icon(Icons.person),
                  ),
                  title: Text(req.otherUserName),
                  subtitle: Text('Wants to chat • ${req.requestSenderId}'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final success = await provider.acceptRequest(req.id);
                      if (success && context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Request Accepted!')),
                         );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
