import mongoose from 'mongoose';

// Message Schema - Individual messages
const messageSchema = new mongoose.Schema({
    conversationId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Conversation',
        required: true
    },
    senderId: {
        type: String,
        required: true
    },
    senderType: {
        type: String,
        enum: ['user', 'temple', 'creator', 'admin'],
        required: true
    },
    senderName: {
        type: String,
        required: true
    },
    senderImage: {
        type: String,
        default: ''
    },
    receiverId: {
        type: String,
        required: true
    },
    receiverType: {
        type: String,
        enum: ['user', 'temple', 'creator', 'admin'],
        required: true
    },
    content: {
        type: String,
        required: true
    },
    messageType: {
        type: String,
        enum: ['text', 'image', 'video'],
        default: 'text'
    },
    mediaUrl: {
        type: String,
        default: ''
    },
    isRead: {
        type: Boolean,
        default: false
    },
    readAt: {
        type: Date,
        default: null
    }
}, {
    timestamps: true
});

// Index for faster queries
messageSchema.index({ conversationId: 1, createdAt: -1 });
messageSchema.index({ senderId: 1 });
messageSchema.index({ receiverId: 1 });

const Message = mongoose.model('Message', messageSchema);

export default Message;
