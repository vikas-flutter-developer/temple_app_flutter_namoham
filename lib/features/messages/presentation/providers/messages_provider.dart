import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/api/api_service.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';

class MessagesProvider with ChangeNotifier {
  final ApiService _apiService;

  MessagesProvider(this._apiService) {
    _loadUserInfo();
  }

  String? _userId;
  String? _userType;
  String? _userName;
  String? _userImage;

  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  String? _error;

  int _unreadCount = 0;

  List<ConversationModel> _conversations = [];
  final Map<String, List<MessageModel>> _messagesByConversation = {};

  String? get userId => _userId;
  String? get userType => _userType;
  String? get userName => _userName;
  String? get userImage => _userImage;

  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSending => _isSending;
  String? get error => _error;

  int get unreadCount => _unreadCount;
  List<ConversationModel> get conversations => _conversations;

  List<MessageModel> messagesFor(String conversationId) {
    return _messagesByConversation[conversationId] ?? const <MessageModel>[];
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    _userType = prefs.getString('user_type');

    // Optional (if you store these later)
    _userName = prefs.getString('user_name');
    _userImage = prefs.getString('user_image');

    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<void> refreshUnreadCount() async {
    if (_userId == null) return;
    try {
      _unreadCount = await _apiService.getUnreadCount(_userId!);
      notifyListeners();
    } catch (e) {
      // keep silent for badge
    }
  }

  Future<void> loadConversations() async {
    if (_userId == null) {
      await _loadUserInfo();
      if (_userId == null) {
        _setError('Please login first');
        return;
      }
    }

    _isLoadingConversations = true;
    _setError(null);

    try {
      final data = await _apiService.getConversations(_userId!, chatType: 'direct');
      _conversations = data
          .map((j) => ConversationModel.fromJson(j, myUserId: _userId))
          .where((c) => c.id.isNotEmpty)
          .toList();

      await refreshUnreadCount();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String conversationId) async {
    _isLoadingMessages = true;
    _setError(null);

    try {
      final data = await _apiService.getConversationMessages(conversationId);
      final msgs = data.map((j) => MessageModel.fromJson(j)).toList();
      msgs.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
      _messagesByConversation[conversationId] = msgs;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Mark as read (payload differs by backend; we include userId + conversationId)
  Future<void> markAsRead(String conversationId) async {
    if (_userId == null) return;

    try {
      await _apiService.markMessagesAsRead({
        'conversationId': conversationId,
        'userId': _userId,
      });
      await refreshUnreadCount();
    } catch (_) {
      // ignore
    }
  }

  /// Sends a text message. If [conversationId] is null/empty, backend should create a conversation
  /// and return a new conversationId in the response.
  Future<String?> sendMessage({
    required String receiverId,
    required String receiverType,
    required String content,
    String? conversationId,
  }) async {
    final text = content.trim();
    if (text.isEmpty) return null;

    if (_userId == null || _userType == null) {
      await _loadUserInfo();
      if (_userId == null || _userType == null) {
        _setError('Please login first');
        return null;
      }
    }

    _isSending = true;
    _setError(null);
    notifyListeners();

    try {
      final senderName = (_userName ?? '').trim().isNotEmpty
          ? (_userName ?? '').trim()
          : (_userType ?? 'User');

      final payload = <String, dynamic>{
        if (conversationId != null && conversationId.trim().isNotEmpty)
          'conversationId': conversationId.trim(),
        'senderId': _userId,
        // Messages API commonly uses lowercase types (user/temple/creator)
        'senderType': _userType!.toLowerCase(),
        // Always include senderName/senderImage to avoid backend null errors
        'senderName': senderName,
        'senderImage': (_userImage ?? '').toString(),
        'receiverId': receiverId,
        'receiverType': receiverType.toLowerCase(),
        'content': text,
        'messageType': 'text',
        'mediaUrl': '',
      };

      final res = await _apiService.sendMessage(payload);

      // Try to extract conversationId from response
      String? newConversationId;
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        newConversationId = (data['conversationId'] ?? data['conversationID'] ?? '').toString();
      }
      if ((newConversationId == null || newConversationId.isEmpty) && res['conversationId'] != null) {
        newConversationId = res['conversationId'].toString();
      }

      final effectiveConversationId =
          (newConversationId != null && newConversationId.isNotEmpty)
              ? newConversationId
              : conversationId;

      if (effectiveConversationId != null && effectiveConversationId.isNotEmpty) {
        await loadMessages(effectiveConversationId);
      }
      await loadConversations();

      return effectiveConversationId;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<bool> sendText({
    required ConversationModel conversation,
    required String text,
  }) async {
    final id = await sendMessage(
      receiverId: conversation.otherUserId,
      receiverType: conversation.otherUserType,
      content: text,
      conversationId: conversation.id,
    );
    return id != null && id.isNotEmpty;
  }
  // ============== CHAT REQUESTS & FLOW ==============

  List<ConversationModel> _pendingRequests = [];
  List<ConversationModel> get pendingRequests => _pendingRequests;

  Future<void> loadPendingRequests() async {
    if (_userId == null) return;
    
    try {
      final data = await _apiService.getPendingRequests(_userId!);
      _pendingRequests = data
          .map((j) => ConversationModel.fromJson(j, myUserId: _userId))
          .toList();
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  Future<bool> acceptRequest(String conversationId) async {
    if (_userId == null) return false;
    
    try {
      await _apiService.acceptMessageRequest(conversationId, _userId!);
      // Refresh both lists
      await loadPendingRequests();
      await loadConversations();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> rejectRequest(String conversationId) async {
    if (_userId == null) return false;

    try {
      await _apiService.rejectMessageRequest(conversationId, _userId!);
      // Refresh pending list
      await loadPendingRequests();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<ConversationModel?> initiateChat({
    required String otherUserId,
    required String otherUserType,
    required String otherUserName,
  }) async {
    if (_userId == null) {
      await _loadUserInfo();
      if (_userId == null) return null;
    }

    try {
      final payload = {
        'user1': {
          'userId': _userId,
          'userType': _userType?.toLowerCase() ?? 'user',
          'userName': _userName ?? 'User',
        },
        'user2': {
          'userId': otherUserId,
          'userType': otherUserType.toLowerCase(),
          'userName': otherUserName,
        },
        'chatType': 'direct',
      };

      debugPrint('MESSAGES_PROVIDER: Initiating chat with payload: $payload');
      final res = await _apiService.initiateConversation(payload);
      debugPrint('MESSAGES_PROVIDER: Backend response: $res');
      
      // Parse the returned conversation immediately
      final conversation = ConversationModel.fromJson(res, myUserId: _userId);
      
      // IMPORTANT: If backend didn't return the name, use what we passed
      final fixedConversation = ConversationModel(
        id: conversation.id,
        otherUserId: conversation.otherUserId.isNotEmpty ? conversation.otherUserId : otherUserId,
        otherUserType: conversation.otherUserType.isNotEmpty ? conversation.otherUserType : otherUserType,
        otherUserName: conversation.otherUserName.isNotEmpty ? conversation.otherUserName : otherUserName,
        otherUserImage: conversation.otherUserImage,
        lastMessage: conversation.lastMessage,
        lastMessageAt: conversation.lastMessageAt,
        unreadCount: conversation.unreadCount,
        status: conversation.status,
        requestSenderId: conversation.requestSenderId,
        chatType: conversation.chatType,
      );

      debugPrint('MESSAGES_PROVIDER: Conversation ID: ${fixedConversation.id}');
      debugPrint('MESSAGES_PROVIDER: Other User Name: ${fixedConversation.otherUserName}');
      debugPrint('MESSAGES_PROVIDER: Status: ${fixedConversation.status}');
      
      // Update local list
      final index = _conversations.indexWhere((c) => c.id == fixedConversation.id);
      if (index >= 0) {
        _conversations[index] = fixedConversation;
      } else {
        _conversations.insert(0, fixedConversation);
      }
      
      notifyListeners();
      
      return fixedConversation;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }
}
