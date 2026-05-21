import Temple from '../models/templeModel.js';
import Creator from '../models/creatorModel.js';
import BlockedEntity from '../models/blockedEntityModel.js';

// GET /api/search - Unified search for temples and creators
export const unifiedSearch = async (req, res) => {
    try {
        const { q, type = 'all', limit = 20 } = req.query;

        if (!q || q.trim() === '') {
            return res.json({
                success: true,
                results: [],
                message: 'Please provide a search query'
            });
        }

        // Get blocked entities if user is logged in
        let blockedIds = [];
        if (req.user) {
            const blocks = await BlockedEntity.find({ userId: req.user.id }).select('blockedEntityId');
            blockedIds = blocks.map(b => b.blockedEntityId);
        }

        const searchRegex = { $regex: q, $options: 'i' };
        let temples = [];
        let creators = [];

        // Search temples if type is 'all' or 'temples'
        if (type === 'all' || type === 'temples') {
            const templeQuery = {
                isDeactivated: false, // Hide deactivated temples
                adminVerificationStatus: 'approved',
                $or: [
                    { templeName: searchRegex },
                    { address: searchRegex },
                    { city: searchRegex },
                    { state: searchRegex },
                    { description: searchRegex }
                ]
            };

            // Filter out blocked temples
            if (blockedIds.length > 0) {
                templeQuery._id = { $nin: blockedIds };
            }

            temples = await Temple.find(templeQuery).limit(parseInt(limit));
        }

        // Search creators if type is 'all' or 'creators'
        if (type === 'all' || type === 'creators') {
            const creatorQuery = {
                isDeactivated: false, // Hide deactivated creators
                adminVerificationStatus: 'approved',
                $or: [
                    { creatorName: searchRegex },
                    { title: searchRegex },
                    { address: searchRegex },
                    { description: searchRegex }
                ]
            };

            // Filter out blocked creators
            if (blockedIds.length > 0) {
                creatorQuery._id = { $nin: blockedIds };
            }

            creators = await Creator.find(creatorQuery).limit(parseInt(limit));
        }

        // Format results into unified structure
        const results = [];

        // Add temples to results
        temples.forEach(temple => {
            results.push({
                id: temple._id,
                name: temple.templeName || 'Unknown Temple',
                profilePic: temple.templePics?.[0] || '',
                type: 'temple',
                location: temple.city ? `${temple.city}, ${temple.state || ''}`.trim() : (temple.address || ''),
                followers: temple.followers || 0,
                isVerified: temple.isVerified || false,
                rating: temple.rating || 0,
                description: temple.description || ''
            });
        });

        // Add creators to results
        creators.forEach(creator => {
            results.push({
                id: creator._id,
                name: creator.creatorName || 'Unknown Creator',
                profilePic: creator.creatorPics?.[0] || creator.profilePic || '',
                type: 'creator',
                location: creator.address || '',
                followers: creator.followers || 0,
                isVerified: creator.isVerified || false,
                title: creator.title || 'Spiritual Leader',
                description: creator.description || ''
            });
        });

        console.log(`🔍 Search for "${q}" found ${temples.length} temples and ${creators.length} creators`);

        res.json({
            success: true,
            query: q,
            results: results,
            count: {
                total: results.length,
                temples: temples.length,
                creators: creators.length
            }
        });
    } catch (error) {
        console.error('❌ Search error:', error);
        res.status(500).json({
            success: false,
            message: 'Error performing search',
            error: error.message
        });
    }
};

// GET /api/search/suggestions - Get search suggestions
export const getSearchSuggestions = async (req, res) => {
    try {
        const { q, limit = 10 } = req.query;

        if (!q || q.length < 2) {
            return res.json({
                success: true,
                suggestions: []
            });
        }

        const searchRegex = { $regex: `^${q}`, $options: 'i' };

        // Get blocked entities if user is logged in
        let blockedIds = [];
        if (req.user) {
            const blocks = await BlockedEntity.find({ userId: req.user.id }).select('blockedEntityId');
            blockedIds = blocks.map(b => b.blockedEntityId);
        }

        // Get temple name suggestions
        const templeQuery = { 
            templeName: searchRegex, 
            isDeactivated: false, 
            adminVerificationStatus: 'approved' 
        };
        if (blockedIds.length > 0) templeQuery._id = { $nin: blockedIds };
        const templeSuggestions = await Temple.find(
            templeQuery,
            { templeName: 1 }
        ).limit(parseInt(limit) / 2);

        // Get creator name suggestions
        const creatorQuery = { 
            creatorName: searchRegex, 
            isDeactivated: false, 
            adminVerificationStatus: 'approved' 
        };
        if (blockedIds.length > 0) creatorQuery._id = { $nin: blockedIds };
        const creatorSuggestions = await Creator.find(
            creatorQuery,
            { creatorName: 1 }
        ).limit(parseInt(limit) / 2);

        const suggestions = [
            ...templeSuggestions.map(t => ({ name: t.templeName, type: 'temple' })),
            ...creatorSuggestions.map(c => ({ name: c.creatorName, type: 'creator' }))
        ];

        res.json({
            success: true,
            suggestions: suggestions
        });
    } catch (error) {
        console.error('❌ Suggestions error:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching suggestions',
            error: error.message
        });
    }
};
