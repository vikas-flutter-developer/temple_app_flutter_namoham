import BlockedEntity from '../models/blockedEntityModel.js';
import Temple from '../models/templeModel.js';
import Creator from '../models/creatorModel.js';

// POST /api/block - Block/Hide a temple or creator
export const blockEntity = async (req, res) => {
    try {
        const { entityId, entityType } = req.body;
        const userId = req.user.id;
        const userType = req.user.userType; // 'user', 'temple', or 'creator'

        if (!entityId || !entityType) {
            return res.status(400).json({
                success: false,
                message: 'EntityID and EntityType are required'
            });
        }

        if (!['temple', 'creator'].includes(entityType.toLowerCase())) {
            return res.status(400).json({
                success: false,
                message: 'Invalid entity type. Must be "temple" or "creator"'
            });
        }

        // Normalize model names
        const normalizedUserType = userType.charAt(0).toUpperCase() + userType.slice(1);
        const normalizedEntityType = entityType.charAt(0).toUpperCase() + entityType.slice(1);

        // Check if already blocked
        const existingBlock = await BlockedEntity.findOne({
            userId,
            blockedEntityId: entityId
        });

        if (existingBlock) {
            return res.status(400).json({
                success: false,
                message: 'Entity is already blocked'
            });
        }

        await BlockedEntity.create({
            userId,
            userModel: normalizedUserType,
            blockedEntityId: entityId,
            blockedEntityModel: normalizedEntityType
        });

        res.json({
            success: true,
            message: `${normalizedEntityType} has been hidden/blocked successfully`
        });
    } catch (error) {
        console.error('❌ Error blocking entity:', error);
        res.status(500).json({
            success: false,
            message: 'Error blocking entity',
            error: error.message
        });
    }
};

// POST /api/unblock - Unblock/Unhide a temple or creator
export const unblockEntity = async (req, res) => {
    try {
        const { entityId } = req.body;
        const userId = req.user.id;

        if (!entityId) {
            return res.status(400).json({
                success: false,
                message: 'EntityID is required'
            });
        }

        const result = await BlockedEntity.findOneAndDelete({
            userId,
            blockedEntityId: entityId
        });

        if (!result) {
            return res.status(404).json({
                success: false,
                message: 'Block record not found'
            });
        }

        res.json({
            success: true,
            message: 'Entity has been unblocked/shown successfully'
        });
    } catch (error) {
        console.error('❌ Error unblocking entity:', error);
        res.status(500).json({
            success: false,
            message: 'Error unblocking entity',
            error: error.message
        });
    }
};

// GET /api/blocks - Get all blocked entities for the current user
export const getBlockedEntities = async (req, res) => {
    try {
        const userId = req.user.id;

        const blocks = await BlockedEntity.find({ userId });

        const results = await Promise.all(blocks.map(async (block) => {
            let details = null;
            if (block.blockedEntityModel === 'Temple') {
                details = await Temple.findById(block.blockedEntityId).select('templeName templePics city state');
            } else {
                details = await Creator.findById(block.blockedEntityId).select('creatorName creatorPics title');
            }

            return {
                id: block.blockedEntityId,
                type: block.blockedEntityModel.toLowerCase(),
                name: details ? (details.templeName || details.creatorName) : 'Unknown',
                pic: details ? (details.templePics?.[0] || details.creatorPics?.[0]) : '',
                blockedAt: block.createdAt
            };
        }));

        res.json({
            success: true,
            blocks: results
        });
    } catch (error) {
        console.error('❌ Error fetching blocked entities:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching blocked entities',
            error: error.message
        });
    }
};
