import Creator from '../models/creatorModel.js';
import path from 'path';

export const getDashboard = async (req, res) => {
    try {
        const creators = await Creator.find({});
        const creatorData = creators.map(creator => ({
            username: creator.creatorName,
            pics: creator.creatorPics.map(pic => path.join('/uploads/creators', pic))
        }));
        res.render('dashboard', { creatorData });
    } catch (error) {
        console.error('Dashboard error:', error);
        res.status(500).json({ message: 'Error loading dashboard' });
    }
};

export default { getDashboard };