import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_service.dart';
import '../../../messages/data/models/message_model.dart';
import 'dart:async';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ApiService _apiService = ApiService.create();
  final ScrollController _scrollController = ScrollController();
  
  List<MessageModel> _messages = [];
  String? _adminId;
  String? _adminName;
  String? _adminProfilePic;
  String? _currentUserId;
  String? _currentUserType;
  String? _currentUserName;
  String? _conversationId;
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _refreshTimer;
  bool _showEmojiPicker = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      // Get current user info from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('user_id');
      _currentUserType = prefs.getString('user_type') ?? 'user'; // user, temple, or creator
      _currentUserName = prefs.getString('user_name') ?? 'User';

      if (_currentUserId == null) {
        throw Exception('User not logged in');
      }

      // Fetch admin ID
      final adminResponse = await _apiService.getAdminId();
      setState(() {
        _adminId = adminResponse['data']['adminId'];
        _adminName = adminResponse['data']['fullName'];
        _adminProfilePic = adminResponse['data']['profilePic'];
      });

      // Load existing conversations to find admin conversation
      await _loadConversation();

      // Set up periodic refresh
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
    } catch (e) {
      print('Error initializing chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize chat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadConversation() async {
    try {
      final conversations = await _apiService.getConversations(_currentUserId!);
      
      // Find conversation with admin
      for (var conv in conversations) {
        if (conv['recipientType'] == 'admin' || conv['recipientId'] == _adminId) {
          _conversationId = conv['id'];
          await _loadMessages();
          return;
        }
      }
      
      // No existing conversation with admin
      setState(() => _messages = []);
    } catch (e) {
      print('Error loading conversation: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (_conversationId == null) return;

    try {
      final messagesData = await _apiService.getConversationMessages(_conversationId!);
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
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending || _adminId == null) return;

    setState(() => _isSending = true);

    try {
      final messageData = {
        'senderId': _currentUserId!,
        'senderType': _currentUserType!.toLowerCase(), // Ensure lowercase for API validation
        'senderName': _currentUserName!,
        'receiverId': _adminId!,
        'receiverType': 'admin',
        'receiverName': _adminName ?? 'Admin',
        'content': text,
        'messageType': 'text',
      };

      final response = await _apiService.sendMessage(messageData);
      
      // Update conversation ID if this is the first message
      if (_conversationId == null && response['data'] != null) {
        _conversationId = response['data']['conversationId'];
      }

      _messageController.clear();
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        // TODO: Implement image upload to server and send as message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image selected. Upload feature coming soon!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showVoiceRecordingDialog() {
    // TODO: Implement voice recording functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice recording feature coming soon!')),
    );
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'A';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Support Chat",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Please wait our support team will reply you as soon as possible.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 24),
                      
                      // Admin Profile
                      Row(
                        children: [
                          Stack(
                            children: [
                              _adminProfilePic != null && _adminProfilePic!.isNotEmpty
                                  ? CircleAvatar(
                                      radius: 24,
                                      backgroundImage: NetworkImage(_adminProfilePic!),
                                      backgroundColor: const Color(0xFF29C5F6),
                                    )
                                  : Container(
                                      width: 48,
                                      height: 48,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF29C5F6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          _getInitials(_adminName),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _adminName ?? 'Support Admin',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "Active now",
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Chat Area
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Text(
                            'Start a conversation with our support team',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(24),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isMe = message.senderId == _currentUserId;
                            final showTime = index == 0 ||
                                (index > 0 &&
                                    _messages[index - 1].createdAt != message.createdAt);
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildMessageBubble(
                                message.content,
                                isMe,
                                showTime ? _formatTime(message.createdAt) : '',
                              ),
                            );
                          },
                        ),
                ),

                // Input Area
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SafeArea(
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: const Icon(Icons.image_outlined, size: 28, color: Colors.black87),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: _showVoiceRecordingDialog,
                              child: const Icon(Icons.mic_none_outlined, size: 28, color: Colors.black87),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _messageController,
                                        decoration: const InputDecoration(
                                          hintText: "Type a message...",
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.only(bottom: 4),
                                        ),
                                        onSubmitted: (_) => _sendMessage(),
                                        onTap: () {
                                          if (_showEmojiPicker) {
                                            setState(() => _showEmojiPicker = false);
                                          }
                                        },
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _toggleEmojiPicker,
                                      child: Icon(
                                        _showEmojiPicker 
                                          ? Icons.keyboard 
                                          : Icons.sentiment_satisfied_alt,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: _isSending ? null : _sendMessage,
                              icon: Transform.rotate(
                                angle: -0.5,
                                child: Icon(
                                  Icons.send,
                                  size: 28,
                                  color: _isSending ? Colors.grey : const Color(0xFF29C5F6),
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      if (_showEmojiPicker)
                        SizedBox(
                          height: 250,
                          child: EmojiPicker(
                            onEmojiSelected: (category, emoji) {
                              _messageController.text += emoji.emoji;
                            },
                            config: Config(
                              height: 250,
                              checkPlatformCompatibility: true,
                              emojiViewConfig: EmojiViewConfig(
                                columns: 7,
                                emojiSizeMax: 32.0,
                                verticalSpacing: 0,
                                horizontalSpacing: 0,
                                gridPadding: EdgeInsets.zero,
                                recentsLimit: 28,
                                noRecents: const Text(
                                  'No Recents',
                                  style: TextStyle(fontSize: 20, color: Colors.black26),
                                  textAlign: TextAlign.center,
                                ),
                                buttonMode: ButtonMode.MATERIAL,
                              ),
                              categoryViewConfig: CategoryViewConfig(
                                initCategory: Category.RECENT,
                                recentTabBehavior: RecentTabBehavior.RECENT,
                                indicatorColor: const Color(0xFF29C5F6),
                                iconColor: Colors.grey,
                                iconColorSelected: const Color(0xFF29C5F6),
                                backspaceColor: const Color(0xFF29C5F6),
                              ),
                              skinToneConfig: const SkinToneConfig(
                                enabled: true,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String time) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF29C5F6) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
        if (time.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ]
      ],
    );
  }
}
