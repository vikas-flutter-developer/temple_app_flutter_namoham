import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/api/api_service.dart';
import '../../../../messages/data/models/message_model.dart';
import 'dart:async';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  final ApiService _apiService = ApiService.create();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _conversations = [];
  List<MessageModel> _messages = [];
  Map<String, dynamic>? _selectedConversation;
  String? _adminId;
  bool _isLoading = true;
  bool _isSending = false;
  String _searchQuery = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeMessages();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _adminId = prefs.getString('user_id');

      if (_adminId == null) {
        throw Exception('Admin not logged in');
      }

      await _loadConversations();

      // Set up periodic refresh every 5 seconds
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _loadConversations();
        if (_selectedConversation != null) {
          _loadMessages(_selectedConversation!['id']);
        }
      });
    } catch (e) {
      print('Error initializing messages: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await _apiService.getConversations(_adminId!);
      if (mounted) {
        setState(() {
          _conversations = conversations;
        });
      }
    } catch (e) {
      print('Error loading conversations: $e');
    }
  }

  Future<void> _loadMessages(String conversationId) async {
    try {
      final messagesData = await _apiService.getConversationMessages(conversationId);
      final messages = messagesData.map((json) => MessageModel.fromJson(json)).toList();

      if (mounted) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_selectedConversation == null) return;
    
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final messageData = {
        'senderId': _adminId!,
        'senderType': 'admin',
        'senderName': 'Support Admin',
        'receiverId': _selectedConversation!['recipientId'],
        'receiverType': _selectedConversation!['recipientType'],
        'receiverName': _selectedConversation!['recipientName'],
        'content': text,
        'messageType': 'text',
      };

      await _apiService.sendMessage(messageData);
      _messageController.clear();
      await _loadMessages(_selectedConversation!['id']);
    } catch (e) {
      if (mounted) {
        final cleanError = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $cleanError')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations.where((conv) {
      final name = conv['recipientName']?.toString().toLowerCase() ?? '';
      final lastMsg = conv['lastMessage']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase()) ||
          lastMsg.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  Color _getAvatarColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'temple':
        return Colors.orange;
      case 'creator':
        return Colors.purple;
      default:
        return const Color(0xFF29C5F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Left Panel - Conversation List
                Container(
                  width: 350,
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Support Messages',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Search Bar
                            TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() => _searchQuery = value);
                              },
                              decoration: InputDecoration(
                                hintText: 'Search conversations...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Conversations List
                      Expanded(
                        child: _filteredConversations.isEmpty
                            ? Center(
                                child: Text(
                                  _searchQuery.isEmpty
                                      ? 'No support messages yet'
                                      : 'No results found',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredConversations.length,
                                itemBuilder: (context, index) {
                                  final conv = _filteredConversations[index];
                                  final isSelected = _selectedConversation?['id'] == conv['id'];
                                  
                                  return _buildConversationItem(conv, isSelected);
                                },
                              ),
                      ),
                    ],
                  ),
                ),

                // Right Panel - Chat View
                Expanded(
                  child: _selectedConversation == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.message_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Select a conversation to view messages',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // Chat Header
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: _getAvatarColor(
                                      _selectedConversation!['recipientType'],
                                    ),
                                    child: Text(
                                      _getInitials(_selectedConversation!['recipientName']),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedConversation!['recipientName'] ?? 'Unknown',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          _selectedConversation!['recipientType']?.toString().toUpperCase() ?? 'USER',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Messages
                            Expanded(
                              child: _messages.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No messages yet',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[50],
                                      child: ListView.builder(
                                        controller: _scrollController,
                                        padding: const EdgeInsets.all(24),
                                        itemCount: _messages.length,
                                        itemBuilder: (context, index) {
                                          final message = _messages[index];
                                          final isAdmin = message.senderType == 'admin';
                                          
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 16),
                                            child: _buildMessageBubble(
                                              message.content,
                                              isAdmin,
                                              _formatTime(message.createdAt),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                            ),

                            // Input Area
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  top: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _messageController,
                                      decoration: InputDecoration(
                                        hintText: 'Type your reply...',
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(24),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                      ),
                                      onSubmitted: (_) => _sendMessage(),
                                      maxLines: null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  GestureDetector(
                                    onTap: _sendMessage,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _isSending ? Colors.grey : const Color(0xFF00A3FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.send,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> conv, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedConversation = conv;
          _messages = [];
        });
        _loadMessages(conv['id']);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00A3FF).withOpacity(0.1) : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _getAvatarColor(conv['recipientType']),
              child: Text(
                _getInitials(conv['recipientName']),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conv['recipientName'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(conv['updatedAt'] != null 
                            ? DateTime.parse(conv['updatedAt']) 
                            : null),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conv['lastMessage'] ?? 'No messages yet',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isAdmin, String time) {
    return Column(
      crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.6,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isAdmin ? const Color(0xFF00A3FF) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isAdmin ? const Radius.circular(20) : const Radius.circular(4),
              bottomRight: isAdmin ? const Radius.circular(4) : const Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isAdmin ? Colors.white : Colors.black87,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
        if (time.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[400],
            ),
          ),
        ],
      ],
    );
  }
}
