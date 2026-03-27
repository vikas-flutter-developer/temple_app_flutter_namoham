const { Jimp } = require("jimp");
const fs = require('fs');
const path = require('path');

async function padImage() {
    try {
        const inputPath = path.join(__dirname, 'assets', 'splash', 'namo_ham_splash.png');
        const outputPath = path.join(__dirname, 'assets', 'splash', 'namo_ham_splash_padded.png');

        console.log(`Reading image from ${inputPath}`);
        
        // Read the image
        const image = await Jimp.read(inputPath);
        
        const width = image.bitmap.width;
        const height = image.bitmap.height;
        
        console.log(`Original dimensions: ${width}x${height}`);
        
        // Android 12 splash screen is a circle mask. 
        // We need the image to fit comfortably within the center.
        // A safe square padding ratio is roughly 2.5x the width for landscape logos.
        const size = Math.max(width, height) * 2; 
        
        console.log(`Creating padded canvas of ${size}x${size}`);
        
        // Create a new blank white image
        const newImage = new Jimp({ width: size, height: size, color: 0xFFFFFFFF });
        
        // Composite the original image onto the center of the new image
        const x = (size - width) / 2;
        const y = (size - height) / 2;
        
        newImage.composite(image, x, y);
        
        // Save
        await newImage.write(outputPath);
        console.log(`Successfully saved padded image to ${outputPath}`);
    } catch (err) {
        console.error("Error processing image:", err);
        process.exit(1);
    }
}

padImage();
