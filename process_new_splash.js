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
        
        // Safe distance constraint for corner visibility inside R=96 circle of a 288 width square:
        // Radius Ratio = 192 / 288 = 2 / 3.
        // Distance from center to logo corner <= (SquareSize / 2) * (2 / 3)
        // SquareSize >= 1.5 * 2 * DistanceFromCenterToCorner
        // Let's add a tiny safety buffer factor of 1.1 to be totally safe from overlapping navigation/status.
        const diagonal = Math.sqrt(W*W + H*H);
        const idealSquareSize = Math.ceil(diagonal * 1.5 * 1.1);
        
        console.log(`Logo: ${W}x${H}, Fitting on canvas: ${idealSquareSize}x${idealSquareSize}`);
        
        const canvas = new Jimp({ width: idealSquareSize, height: idealSquareSize, color: 0xFFFFFFFF });
        
        const x = Math.floor((idealSquareSize - W) / 2);
        const y = Math.floor((idealSquareSize - H) / 2);
        
        canvas.composite(image, x, y);
        await canvas.write(targetPath);
        console.log("DONE!");
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

main();
