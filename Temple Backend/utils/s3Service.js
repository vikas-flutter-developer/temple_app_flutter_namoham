import { S3Client, PutObjectCommand, DeleteObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import config from "../config/env.js";

const s3Client = new S3Client({
    region: "auto",
    endpoint: config.r2Endpoint,
    credentials: {
        accessKeyId: config.r2AccessKeyId,
        secretAccessKey: config.r2SecretAccessKey,
    },
    forcePathStyle: true,
    requestChecksumCalculation: "WHEN_REQUIRED",
});

/**
 * Generate a presigned URL for uploading a file directly to Cloudflare R2
 * @param {string} folder - The folder name (post, reel, profile_pic)
 * @param {string} fileName - The name of the file
 * @param {string} contentType - Mime type of the file
 * @returns {Promise<{uploadUrl: string, fileUrl: string, key: string}>}
 */
export const generateUploadUrl = async (folder, fileName, contentType) => {
    // Ensure the path is 'folder/filename'
    const key = `${folder}/${Date.now()}-${fileName}`;
    const command = new PutObjectCommand({
        Bucket: config.r2BucketName,
        Key: key,
        ContentType: contentType,
    });

    // URL expires in 3600 seconds (1 hour)
    const uploadUrl = await getSignedUrl(s3Client, command, { expiresIn: 3600 });

    // The public URL to access the file after upload
    const fileUrl = `${config.r2PublicUrl}/${key}`;

    return { uploadUrl, fileUrl, key };
};

/**
 * Delete an object from R2
 * @param {string} key - The key (filename) of the object in the bucket
 */
export const deleteFile = async (key) => {
    const command = new DeleteObjectCommand({
        Bucket: config.r2BucketName,
        Key: key,
    });
    return await s3Client.send(command);
};
