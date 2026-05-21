import Message from '../models/message.js';
import Conversation from '../models/conversation.js';

// Get all conversations for a user
export const getConversations = async (req, res) => {
    try {
        const { userId } = req.params;
        const { chatType } = req.query; // 'support' or 'direct'

        if (!userId) {
            return res.status(400).json({ message: 'User ID is required' });
        }

        const query = {
            'participants.userId': userId,
            isActive: true,
            status: { $ne: 'rejected' }
        };

        if (chatType) {
            query.chatType = chatType;
        }

        const conversations = await Conversation.find(query)
            .sort({ updatedAt: -1 })
            .lean();

        const formattedConversations = conversations.map(conv => {
            // find the other participant
            const otherParticipant = conv.participants.find(
                p => p.userId !== userId
            );

            return {
                id: conv._id,
                recipientId: otherParticipant?.userId || '',
                recipientName: otherParticipant?.userName || 'Unknown',
                recipientImage: otherParticipant?.userImage || '',
                recipientType: otherParticipant?.userType || 'user',

                lastMessage: conv.lastMessage?.content || '',
                lastMessageTime:
                    conv.lastMessage?.timestamp || conv.updatedAt,

                // ✅ FIXED: Map → plain object when using `.lean()`
                unreadCount: conv.unreadCount?.[userId] || 0,

                // last message is read if:
                // - current user sent it
                // - OR it is marked read
                isRead:
                    conv.lastMessage?.senderId === userId ||
                    conv.lastMessage?.isRead === true,

                status: conv.status || 'pending',
                requestSenderId: conv.requestSenderId,
                chatType: conv.chatType || 'direct'
            };
        });

        res.status(200).json(formattedConversations);
    } catch (error) {
        console.error('❌ Error fetching conversations:', error);
        res.status(500).json({
            message: 'Error fetching conversations',
            error: error.message
        });
    }
};


// Get messages for a conversation
export const getMessages = async (req, res) => {
    try {
        const { conversationId } = req.params;
        const { page = 1, limit = 50 } = req.query;

        const messages = await Message.find({ conversationId })
            .sort({ createdAt: -1 })
            .skip((page - 1) * limit)
            .limit(parseInt(limit))
            .lean();

        // Return in chronological order (oldest first)
        res.json(messages.reverse());
    } catch (error) {
        console.error('❌ Error fetching messages:', error);
        res.status(500).json({ message: 'Error fetching messages', error: error.message });
    }
};

// Send a message
export const sendMessage = async (req, res) => {
    try {
        const {
            senderId,
            senderType,
            senderName,
            senderImage,
            receiverId,
            receiverType,
            receiverName,
            receiverImage,
            content,
            messageType = 'text',
            mediaUrl = '',
            chatType // 'support' or 'direct'
        } = req.body;

        // Find or create conversation
        const conversation = await Conversation.findOrCreateConversation(
            { userId: senderId, userType: senderType, userName: senderName, userImage: senderImage },
            { userId: receiverId, userType: receiverType, userName: receiverName, userImage: receiverImage },
            chatType
        );

        // Security Check: If conversation is pending
        if (conversation.status === 'pending') {
            if (senderId !== conversation.requestSenderId) {
                // Case 1: Receiver (e.g., Creator/Temple) trying to reply without accepting
                return res.status(403).json({
                    success: false,
                    message: 'This message request is pending your approval. You must accept the request before replying.'
                });
            } else if (conversation.lastMessage && conversation.lastMessage.senderId !== '') {
                // Case 2: Sender trying to send more than one message while pending
                return res.status(403).json({
                    success: false,
                    message: 'Your message request is still pending approval. You can send more messages once the creator accepts your request.'
                });
            }
            // If senderId === requestSenderId and lastMessage.senderId is empty, we allow the first message.
        }

        // Security Check: If conversation is rejected
        if (conversation.status === 'rejected') {
            return res.status(403).json({
                success: false,
                message: 'This message request has been rejected.'
            });
        }

        // Create message
        const message = await Message.create({
            conversationId: conversation._id,
            senderId,
            senderType,
            senderName,
            senderImage,
            receiverId,
            receiverType,
            content,
            messageType,
            mediaUrl
        });

        // Update conversation with last message
        await Conversation.findByIdAndUpdate(conversation._id, {
            lastMessage: {
                content: content,
                senderId: senderId,
                timestamp: new Date(),
                isRead: false
            },
            $inc: { [`unreadCount.${receiverId}`]: 1 }
        });

        console.log('✅ Message sent:', message._id);

        res.status(201).json({
            message: 'Message sent successfully',
            data: {
                id: message._id,
                conversationId: conversation._id,
                senderId: message.senderId,
                senderName: message.senderName,
                senderImage: message.senderImage,
                receiverId: message.receiverId,
                content: message.content,
                messageType: message.messageType,
                mediaUrl: message.mediaUrl,
                isRead: message.isRead,
                createdAt: message.createdAt
            }
        });
    } catch (error) {
        console.error('❌ Error sending message:', error);
        res.status(500).json({ message: 'Error sending message', error: error.message });
    }
};

// Mark messages as read
export const markAsRead = async (req, res) => {
    try {
        const { conversationId, userId } = req.body;

        // Mark all unread messages as read
        await Message.updateMany(
            {
                conversationId,
                receiverId: userId,
                isRead: false
            },
            {
                isRead: true,
                readAt: new Date()
            }
        );

        // Reset unread count for this user
        await Conversation.findByIdAndUpdate(conversationId, {
            [`unreadCount.${userId}`]: 0,
            'lastMessage.isRead': true
        });

        res.json({ message: 'Messages marked as read' });
    } catch (error) {
        console.error('❌ Error marking messages as read:', error);
        res.status(500).json({ message: 'Error marking messages as read', error: error.message });
    }
};

// Get or create conversation between two users
export const getOrCreateConversation = async (req, res) => {
    try {
        const { user1, user2, chatType } = req.body;
        const conversation = await Conversation.findOrCreateConversation(user1, user2, chatType);

        res.json({
            id: conversation._id,
            participants: conversation.participants,
            lastMessage: conversation.lastMessage,
            status: conversation.status,
            requestSenderId: conversation.requestSenderId,
            chatType: conversation.chatType,
            createdAt: conversation.createdAt
        });
    } catch (error) {
        console.error('❌ Error getting/creating conversation:', error);
        res.status(500).json({ message: 'Error with conversation', error: error.message });
    }
};

// Delete a conversation (soft delete)
export const deleteConversation = async (req, res) => {
    try {
        const { conversationId } = req.params;

        await Conversation.findByIdAndUpdate(conversationId, { isActive: false });

        res.json({ message: 'Conversation deleted' });
    } catch (error) {
        console.error('❌ Error deleting conversation:', error);
        res.status(500).json({ message: 'Error deleting conversation', error: error.message });
    }
};

// Accept a message request
export const acceptRequest = async (req, res) => {
    try {
        const { conversationId, userId } = req.body;

        const conversation = await Conversation.findById(conversationId);
        if (!conversation) {
            return res.status(404).json({ message: 'Conversation not found' });
        }

        // Check if user is a participant
        const isParticipant = conversation.participants.some(p => p.userId === userId);
        if (!isParticipant) {
            return res.status(403).json({ message: 'You are not a participant in this conversation' });
        }

        // Security: Only the receiver of the request can accept it
        // The one who IS NOT the requestSenderId
        if (userId === conversation.requestSenderId) {
            return res.status(403).json({ message: 'You cannot accept your own request' });
        }

        conversation.status = 'accepted';
        await conversation.save();

        res.json({ message: 'Message request accepted', status: 'accepted' });
    } catch (error) {
        console.error('❌ Error accepting request:', error);
        res.status(500).json({ message: 'Error accepting request', error: error.message });
    }
};

// Reject a message request
export const rejectRequest = async (req, res) => {
    try {
        const { conversationId, userId } = req.body;

        const conversation = await Conversation.findById(conversationId);
        if (!conversation) {
            return res.status(404).json({ message: 'Conversation not found' });
        }

        // Check if user is a participant
        const isParticipant = conversation.participants.some(p => p.userId === userId);
        if (!isParticipant) {
            return res.status(403).json({ message: 'You are not a participant in this conversation' });
        }

        // Security: Only the receiver of the request can reject it
        if (userId === conversation.requestSenderId) {
            return res.status(403).json({ message: 'You cannot reject your own request' });
        }

        conversation.status = 'rejected';
        await conversation.save();

        res.json({ message: 'Message request rejected', status: 'rejected' });
    } catch (error) {
        console.error('❌ Error rejecting request:', error);
        res.status(500).json({ message: 'Error rejecting request', error: error.message });
    }
};

// Get unread message count for a user
export const getUnreadCount = async (req, res) => {
    try {
        const { userId } = req.params;

        const conversations = await Conversation.find({
            'participants.userId': userId,
            isActive: true
        });

        let totalUnread = 0;
        conversations.forEach(conv => {
            // ✅ Map handling
            totalUnread += conv.unreadCount?.[userId] || 0;
        });

        res.json({ unreadCount: totalUnread });
    } catch (error) {
        console.error('❌ Error getting unread count:', error);
        res.status(500).json({ message: 'Error getting unread count', error: error.message });
    }
};

// Get pending message requests for a user (as receiver)
export const getMessageRequests = async (req, res) => {
    try {
        const { userId } = req.params;

        if (!userId) {
            return res.status(400).json({ message: 'User ID is required' });
        }

        const requests = await Conversation.find({
            'participants.userId': userId,
            status: 'pending',
            requestSenderId: { $ne: userId },
            isActive: true
        })
            .sort({ createdAt: -1 })
            .lean();

        const formattedRequests = requests.map(conv => {
            const sender = conv.participants.find(p => p.userId === conv.requestSenderId);
            return {
                conversationId: conv._id,
                senderId: sender?.userId,
                senderName: sender?.userName,
                senderImage: sender?.userImage,
                senderType: sender?.userType,
                chatType: conv.chatType,
                createdAt: conv.createdAt
            };
        });

        res.status(200).json({
            count: formattedRequests.length,
            requests: formattedRequests
        });
    } catch (error) {
        console.error('❌ Error fetching message requests:', error);
        res.status(500).json({ message: 'Error fetching message requests', error: error.message });
    }
};
