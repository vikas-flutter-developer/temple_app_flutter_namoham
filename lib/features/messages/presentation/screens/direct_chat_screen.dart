import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_service.dart';
import '../../data/models/conversation_model.dart';
import '../providers/messages_provider.dart';
import '../../../../widgets/custom_widgets/custom_network_image.dart';

class DirectChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverType; // temple/creator/user
  final String receiverName;
  final String receiverImage;

  const DirectChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverType,
    required this.receiverName,
    required this.receiverImage,
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _conversationId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MessagesProvider>();
      
      // 1. Try to initiate/find conversation immediately
      // This will either find existing OR create a new one (pending)
      final conversation = await provider.initiateChat(
        otherUserId: widget.receiverId,
        otherUserType: widget.receiverType,
        otherUserName: widget.receiverName,
      );

      if (conversation != null && mounted) {
        setState(() => _conversationId = conversation.id);
        await provider.loadMessages(conversation.id);
        // await provider.markAsRead(conversation.id); // Optional: mark as read if desired
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  String _timeLabel(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('hh:mm a').format(dt.toLocal());
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    final provider = context.read<MessagesProvider>();

    final newId = await provider.sendMessage(
      receiverId: widget.receiverId,
      receiverType: widget.receiverType,
      content: text,
      conversationId: _conversationId,
    );

    if (!mounted) return;

    if (newId == null || newId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to send message')),
      );
      return;
    }

    if (_conversationId != newId) {
      setState(() => _conversationId = newId);
      await provider.loadMessages(newId);
      await provider.markAsRead(newId);
    }

    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,

              child: widget.receiverImage.trim().isNotEmpty
                  ? ClipOval(
                      child: CustomNetworkImage(
                        imageUrl: widget.receiverImage,
                        fit: BoxFit.cover,
                        width: 36,
                        height: 36,
                        errorWidget: Text(
                          widget.receiverName.isNotEmpty ? widget.receiverName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      widget.receiverName.isNotEmpty ? widget.receiverName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName.isNotEmpty ? widget.receiverName : widget.receiverId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    widget.receiverType,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<MessagesProvider>(
              builder: (context, provider, child) {
                if (_conversationId == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Check conversation status
                final conversation = provider.conversations.firstWhere(
                  (c) => c.id == _conversationId,
                  orElse: () => ConversationModel(
                    id: '', 
                    otherUserId: '', 
                    otherUserType: '', 
                    otherUserName: '', 
                    otherUserImage: '', 
                    lastMessage: '', 
                    lastMessageAt: null, 
                    unreadCount: 0,
                    status: 'accepted', // Default to accepted to avoid blocking if not found
                  ),
                );

                if (conversation.status == 'pending' && conversation.requestSenderId == provider.userId) {
                   return Center(
                     child: Padding(
                       padding: const EdgeInsets.all(24.0),
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           const Icon(Icons.access_time, size: 48, color: Colors.orange),
                           const SizedBox(height: 16),
                           Text(
                             'Message Request Sent',
                             style: theme.textTheme.titleLarge,
                           ),
                           const SizedBox(height: 8),
                           Text(
                             'You can chat with ${widget.receiverName} once they accept your request.',
                             textAlign: TextAlign.center,
                             style: theme.textTheme.bodyMedium,
                           ),
                         ],
                       ),
                     ),
                   );
                }

                if (conversation.status == 'rejected') {
                   return const Center(child: Text('Message request was declined.'));
                }

                final messages = provider.messagesFor(_conversationId!);

                if (provider.isLoadingMessages && messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final isMe = provider.userId != null && m.senderId == provider.userId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        constraints: const BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          color: isMe
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              m.content,
                              style: TextStyle(
                                color: isMe
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _timeLabel(m.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isMe
                                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.75)
                                    : theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<MessagesProvider>(
                    builder: (context, provider, child) {
                      return IconButton(
                        icon: provider.isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        onPressed: provider.isSending ? null : _send,
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper wrapper to open DirectChatScreen with its own provider
class DirectChatEntry extends StatelessWidget {
  final String receiverId;
  final String receiverType;
  final String receiverName;
  final String receiverImage;

  const DirectChatEntry({
    super.key,
    required this.receiverId,
    required this.receiverType,
    required this.receiverName,
    required this.receiverImage,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MessagesProvider(ApiService.create()),
      child: DirectChatScreen(
        receiverId: receiverId,
        receiverType: receiverType,
        receiverName: receiverName,
        receiverImage: receiverImage,
      ),
    );
  }
}
