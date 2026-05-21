import mongoose from 'mongoose';

// Conversation Schema - Chat thread between two users
const conversationSchema = new mongoose.Schema({
    // Participants in the conversation
    participants: [{
        odaId: {
            type: String,
            required: true
        },
        userId: {
            type: String,
            required: true
        },
        userType: {
            type: String,
            enum: ['user', 'temple', 'creator', 'admin'],
            required: true
        },
        userName: {
            type: String,
            required: true
        },
        userImage: {
            type: String,
            default: ''
        }
    }],
    // Last message preview
    lastMessage: {
        content: {
            type: String,
            default: ''
        },
        senderId: {
            type: String,
            default: ''
        },
        timestamp: {
            type: Date,
            default: Date.now
        },
        isRead: {
            type: Boolean,
            default: false
        }
    },
    // Unread count per participant
    unreadCount: {
        type: Map,
        of: Number,
        default: {}
    },
    // Chat Request Status
    status: {
        type: String,
        enum: ['pending', 'accepted', 'rejected'],
        default: 'pending'
    },
    // Who initiated the conversation/request
    requestSenderId: {
        type: String,
        default: ''
    },
    // Type of chat
    chatType: {
        type: String,
        enum: ['direct', 'support'],
        default: 'direct'
    },
    // Is conversation active
    isActive: {
        type: Boolean,
        default: true
    }
}, {
    timestamps: true
});

// Index for faster lookups
conversationSchema.index({ 'participants.userId': 1 });
conversationSchema.index({ status: 1 });
conversationSchema.index({ chatType: 1 });
conversationSchema.index({ updatedAt: -1 });

// Static method to find or create conversation between two users
conversationSchema.statics.findOrCreateConversation = async function (user1, user2, chatType = 'direct') {
    // Find existing conversation
    let conversation = await this.findOne({
        chatType,
        $and: [
            { 'participants.userId': user1.userId },
            { 'participants.userId': user2.userId }
        ]
    });

    if (!conversation) {
        // Create new conversation
        // For support chat, we might want it pre-accepted or handle differently
        // For direct chat, it starts as 'pending'
        conversation = await this.create({
            participants: [
                {
                    odaId: user1.userId,
                    userId: user1.userId,
                    userType: user1.userType,
                    userName: user1.userName,
                    userImage: user1.userImage || ''
                },
                {
                    odaId: user2.userId,
                    userId: user2.userId,
                    userType: user2.userType,
                    userName: user2.userName,
                    userImage: user2.userImage || ''
                }
            ],
            chatType,
            status: chatType === 'support' ? 'accepted' : 'pending',
            requestSenderId: user1.userId,
            unreadCount: {
                [user1.userId]: 0,
                [user2.userId]: 0
            }
        });
    }

    return conversation;
};

const Conversation = mongoose.model('Conversation', conversationSchema);

export default Conversation;
