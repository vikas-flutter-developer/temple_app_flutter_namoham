import Notification from '../models/notificationModel.js';
import Follow from '../models/followModel.js';

/**
 * Send notification to a specific user
 */
export const sendNotification = async (app, notificationData) => {
    try {
        const notification = new Notification(notificationData);
        await notification.save();

        const io = app.get('io');
        const connectedUsers = app.get('connectedUsers');

        if (io && connectedUsers) {
            const recipientSocketId = connectedUsers.get(notificationData.recipient.toString());
            if (recipientSocketId) {
                io.to(recipientSocketId).emit('newNotification', notification);
                console.log(`🔔 Real-time notification sent to user ${notificationData.recipient}`);
            }
        }

        return notification;
    } catch (error) {
        console.error('Error sending notification:', error);
    }
};

/**
 * Notify all followers about a new post or reel
 */
export const notifyFollowers = async (app, creatorId, creatorType, contentId, contentType) => {
    try {
        // Find all followers
        const follows = await Follow.find({
            followingId: creatorId,
            followingType: creatorType.toLowerCase()
        });

        if (follows.length === 0) return;

        const creatorName = follows[0].followingName || creatorType;
        let typeLabel = 'post';
        let notifType = 'new_post';

        if (contentType === 'reel') {
            typeLabel = 'reel';
            notifType = 'new_reel';
        } else if (contentType === 'event') {
            typeLabel = 'event';
            notifType = 'new_event';
        }

        const message = `${creatorName} shared a new ${typeLabel}.`;

        const notifications = follows.map(follow => ({
            recipient: follow.followerId,
            recipientModel: follow.followerType === 'user' ? 'User' : (follow.followerType === 'temple' ? 'Temple' : 'Creator'),
            sender: creatorId,
            senderModel: creatorType === 'user' ? 'User' : (creatorType === 'temple' ? 'Temple' : 'Creator'),
            type: notifType,
            [contentType]: contentId,
            message: message
        }));

        // Bulk insert notifications
        const savedNotifications = await Notification.insertMany(notifications);

        // Real-time updates via socket
        const io = app.get('io');
        const connectedUsers = app.get('connectedUsers');

        if (io && connectedUsers) {
            savedNotifications.forEach(notif => {
                const recipientSocketId = connectedUsers.get(notif.recipient.toString());
                if (recipientSocketId) {
                    io.to(recipientSocketId).emit('newNotification', notif);
                }
            });
        }

        console.log(`🔔 Notifications sent to ${follows.length} followers for new ${contentType}`);
    } catch (error) {
        console.error('Error notifying followers:', error);
    }
};
