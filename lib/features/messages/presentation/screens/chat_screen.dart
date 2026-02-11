import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/conversation_model.dart';
import '../providers/messages_provider.dart';
import '../../../../widgets/custom_widgets/custom_network_image.dart';

class ChatScreen extends StatefulWidget {
  final ConversationModel conversation;
  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MessagesProvider>();
      await provider.loadMessages(widget.conversation.id);
      await provider.markAsRead(widget.conversation.id);
      _scrollToBottom();
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
    final ok = await provider.sendText(conversation: widget.conversation, text: text);

    if (!mounted) return;

    if (ok) {
      _controller.clear();
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Failed to send message')),
      );
    }
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

              child: widget.conversation.otherUserImage.trim().isNotEmpty
                  ? ClipOval(
                      child: CustomNetworkImage(
                        imageUrl: widget.conversation.otherUserImage,
                        fit: BoxFit.cover,
                        width: 36,
                        height: 36,
                        errorWidget: Text(
                          widget.conversation.otherUserName.isNotEmpty
                              ? widget.conversation.otherUserName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      widget.conversation.otherUserName.isNotEmpty
                          ? widget.conversation.otherUserName[0].toUpperCase()
                          : '?',
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
                    widget.conversation.otherUserName.isNotEmpty
                        ? widget.conversation.otherUserName
                        : widget.conversation.otherUserId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    widget.conversation.otherUserType,
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
                final messages = provider.messagesFor(widget.conversation.id);

                if (provider.isLoadingMessages && messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null && messages.isEmpty) {
                  return Center(child: Text(provider.error!));
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
