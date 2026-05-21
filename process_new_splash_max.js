const { Jimp } = require("jimp");
const path = require('path');

async function main() {
    try {
        const targetPath = path.join(__dirname, 'assets', 'splash', 'namo_ham_splash.png');
        const image = await Jimp.read(targetPath);
        
        console.log("Auto-cropping...");
        image.autocrop();
        const W = image.bitmap.width;
        const H = image.bitmap.height;
        
        console.log(`Detected intrinsic logo dimensions: ${W}x${H}`);
        
        // Scale setting to maximize UI presence.
        // Using a dimension of 1.1 * H leaves almost zero vertical border, 
        // effectively filling the entire display allocation on contemporary Android.
        const canvasDimension = Math.ceil(Math.max(W, H) * 1.1);
        
        console.log(`Compositing onto minimal constraint canvas: ${canvasDimension}x${canvasDimension}`);
        const finalCanvas = new Jimp({ width: canvasDimension, height: canvasDimension, color: 0xFFFFFFFF });
        
        finalCanvas.composite(image, Math.floor((canvasDimension - W)/2), Math.floor((canvasDimension - H)/2));
        
        await finalCanvas.write(targetPath);
        console.log("LOGO OPTIMIZED SUCCESSFULLY FOR MAXIMUM SCALE.");
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

main();
