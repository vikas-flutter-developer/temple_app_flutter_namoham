import { generateUploadUrl } from "../utils/s3Service.js";

/**
 * Controller to generate a presigned URL for the mobile app
 * POST /api/storage/presigned-url
 */
export const getPresignedUrl = async (req, res) => {
    try {
        const { fileName, contentType, folder } = req.body;

        const allowedFolders = ['posts', 'reels', 'profilePicture'];

        if (!fileName || !contentType || !folder) {
            return res.status(400).json({
                success: false,
                message: "fileName, contentType and folder are required"
            });
        }

        if (!allowedFolders.includes(folder)) {
            return res.status(400).json({
                success: false,
                message: `Invalid folder. Allowed: ${allowedFolders.join(', ')}`
            });
        }

        const data = await generateUploadUrl(folder, fileName, contentType);

        res.json({
            success: true,
            ...data
        });
    } catch (error) {
        console.error("Error generating presigned URL:", error);
        res.status(500).json({
            success: false,
            message: "Failed to generate presigned URL",
            error: error.message
        });
    }
};
