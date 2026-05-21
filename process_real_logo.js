const { Jimp } = require("jimp");
const path = require('path');

async function main() {
    try {
        const imgPath = path.join(__dirname, 'splash screen.png');
        const targetPath = path.join(__dirname, 'assets', 'splash', 'namo_ham_splash.png');
        
        const img = await Jimp.read(imgPath);
        const W = img.bitmap.width;
        const H = img.bitmap.height;
        
        let minX = W, minY = H, maxX = 0, maxY = 0;
        let logoPixels = 0;
        
        for (let y = 0; y < H; y++) {
            for (let x = 0; x < W; x++) {
                const px = img.getPixelColor(x, y);
                const a = px & 0xFF;
                if (a < 10) continue; // Skip transparent border
                
                const r = (px >> 24) & 0xFF;
                const g = (px >> 16) & 0xFF;
                const b = (px >> 8) & 0xFF;
                
                // Look for blue elements of logo (logo is clearly not white)
                if (r < 250 || g < 250 || b < 250) {
                    logoPixels++;
                    if (x < minX) minX = x;
                    if (x > maxX) maxX = x;
                    if (y < minY) minY = y;
                    if (y > maxY) maxY = y;
                }
            }
        }
        
        console.log(`FOUND ACTUAL COLORED LOGO BOUNDS: minX=${minX} minY=${minY} maxX=${maxX} maxY=${maxY}`);
        
        if (logoPixels === 0) {
            throw new Error("Could not find non-white pixels in the image body.");
        }
        
        const w = maxX - minX + 1;
        const h = maxY - minY + 1;
        
        console.log(`Exact Content: ${w}x${h}`);
        
        const cropped = img.clone().crop({ x: minX, y: minY, w: w, h: h });
        
        // Format into the maximally-sized square canvas
        const targetDim = Math.ceil(Math.max(w, h) * 1.1);
        console.log(`Generating square canvas: ${targetDim}x${targetDim}`);
        
        const finalCanvas = new Jimp({ width: targetDim, height: targetDim, color: 0xFFFFFFFF });
        finalCanvas.composite(cropped, Math.floor((targetDim - w)/2), Math.floor((targetDim - h)/2));
        
        await finalCanvas.write(targetPath);
        console.log("SUCCESSFULLY UPDATED ASSET!");
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

main();
