import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shared_preferences/shared_preferences.dart';
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

class _ConversationsView extends StatefulWidget {
  const _ConversationsView();

  @override
  State<_ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends State<_ConversationsView> with WidgetsBindingObserver {
  Timer? _refreshTimer;
  static const _refreshInterval = Duration(seconds: 30);
  String _userType = 'user'; // Default to user
  bool _isLoadingType = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserType();
    _startAutoRefresh();
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userType = (prefs.getString('user_type') ?? 'user').toLowerCase();
        _isLoadingType = false;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    // WidgetsBinding.instance.removeObserver(this); // Fix: removeObserver was called but addObserver was used. Proper clean up.
    // Actually, looking at original code, it had addObserver.
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshConversations();
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      _refreshTimer?.cancel();
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => _refreshConversations());
  }

  void _refreshConversations() {
    if (mounted) {
      Provider.of<MessagesProvider>(context, listen: false).loadConversations();
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    if (now.difference(local).inDays == 0) {
      return DateFormat('h:mm a').format(local);
    } else if (now.difference(local).inDays == 1) {
      return 'Yesterday';
    }
    return DateFormat('MMM d').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoadingType) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isStandardUser = _userType == 'user';

    Widget buildChatList() {
      return Consumer<MessagesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingConversations && provider.conversations.isEmpty) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
          }

          if (provider.conversations.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.loadConversations(),
              color: theme.colorScheme.primary,
              child: ListView(
                padding: const EdgeInsets.all(32),
                children: [
                  const SizedBox(height: 100),
                  Icon(Icons.chat_bubble_outline_rounded, size: 64, color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect with Temples and Creators\nto start a conversation.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadConversations(),
            color: theme.colorScheme.primary,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.conversations.length,
              separatorBuilder: (_, __) => Divider(
                height: 1, 
                indent: 72, 
                color: theme.colorScheme.outlineVariant.withOpacity(0.2)
              ),
              itemBuilder: (context, index) {
                final c = provider.conversations[index];
                final isUnread = c.unreadCount > 0;

                return InkWell(
                  onTap: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: provider,
                          child: ChatScreen(conversation: c),
                        ),
                      ),
                    ).then((_) => _refreshConversations());
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: ClipOval(
                            child: c.otherUserImage.isNotEmpty
                                ? CustomNetworkImage(
                                    imageUrl: c.otherUserImage,
                                    fit: BoxFit.cover,
                                    errorWidget: Container(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      child: Center(
                                        child: Text(
                                          c.otherUserName.isNotEmpty ? c.otherUserName[0].toUpperCase() : '?',
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: Center(
                                      child: Text(
                                        c.otherUserName.isNotEmpty ? c.otherUserName[0].toUpperCase() : '?',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.otherUserName.isNotEmpty ? c.otherUserName : c.otherUserId,
                                      style: GoogleFonts.outfit(
                                        fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                                        fontSize: 16,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    _formatTime(c.lastMessageAt),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                                      color: isUnread ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.lastMessage.isNotEmpty ? c.lastMessage : 'Tap to chat',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                                        color: isUnread ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isUnread)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 20,
                                          minHeight: 20,
                                        ),
                                        child: Text(
                                          '${c.unreadCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    }

    final scaffold = Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Messages',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: theme.colorScheme.onSurface,
          ),
        ),
        bottom: isStandardUser 
        ? null 
        : PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                indicatorColor: theme.colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Chats'),
                  Tab(text: 'Requests'),
                ],
              ),
            ),
          ),
      ),
      body: isStandardUser 
        ? buildChatList()
        : TabBarView(
            children: [
              buildChatList(),
              const _RequestsList(),
            ],
          ),
    );

    if (!isStandardUser) {
      return DefaultTabController(
        length: 2,
        child: scaffold,
      );
    }

    return scaffold;
  }
}

class _RequestsList extends StatelessWidget {
  const _RequestsList();

  @override
  Widget build(BuildContext context) {
    // Ensuring loadPendingRequests is called
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessagesProvider>().loadPendingRequests();
    });

    final theme = Theme.of(context);

    return Consumer<MessagesProvider>(
      builder: (context, provider, child) {
        final requests = provider.pendingRequests;

        if (requests.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => provider.loadPendingRequests(),
            color: theme.colorScheme.primary,
            child: ListView(
              padding: const EdgeInsets.all(32),
              children: [
                 const SizedBox(height: 80),
                 Icon(Icons.inbox_outlined, size: 64, color: theme.colorScheme.outlineVariant),
                 const SizedBox(height: 16),
                 Center(
                   child: Text(
                     'No pending requests',
                     style: GoogleFonts.outfit(
                       fontSize: 16,
                       color: theme.colorScheme.onSurfaceVariant
                     ),
                   )
                 ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadPendingRequests(),
          color: theme.colorScheme.primary,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final req = requests[index];
              return Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        child: req.otherUserImage.isNotEmpty
                            ? ClipOval(
                                child: CustomNetworkImage(
                                  imageUrl: req.otherUserImage,
                                  fit: BoxFit.cover,
                                  width: 48,
                                  height: 48,
                                  errorWidget: const Icon(Icons.person),
                                ),
                              )
                            : Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              req.otherUserName,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Wants to chat',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final success = await provider.acceptRequest(req.id);
                          if (success && context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Request Accepted!')),
                             );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        ),
                        child: Text('Accept', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      ),
                    ],
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
