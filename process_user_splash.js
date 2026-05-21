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
        let pixelsFound = 0;
        
        // Stricter analysis: require significant alpha to be considered "real content" 
        // to ignore compression ghosts near the edges.
        for (let y = 0; y < H; y++) {
            for (let x = 0; x < W; x++) {
                const px = img.getPixelColor(x, y);
                // Alpha is lowest byte in Jimp's returned 32-bit BE int sometimes, 
                // but wait, Jimp 1.x uses a different system occasionally. 
                // Let's just check if NOT FULLY ZERO first, but extract color properly.
                
                // Safer way in Jimp 1.x:
                const r = (px >> 24) & 0xFF;
                const g = (px >> 16) & 0xFF;
                const b = (px >> 8) & 0xFF;
                const a = px & 0xFF;
                
                // Look specifically for solid content or non-empty
                if (a > 100) { // Very confident non-transparency
                    pixelsFound++;
                    if (x < minX) minX = x;
                    if (x > maxX) maxX = x;
                    if (y < minY) minY = y;
                    if (y > maxY) maxY = y;
                }
            }
        }
        
        console.log(`Robust Content Search: minX=${minX} minY=${minY} maxX=${maxX} maxY=${maxY}`);
        
        if (pixelsFound === 0) {
            throw new Error("NO SOLID CONTENT FOUND!");
        }
        
        const logoW = maxX - minX + 1;
        const logoH = maxY - minY + 1;
        console.log(`Solid logo detected at: ${logoW}x${logoH}`);
        
        // Extract it
        const cropped = img.clone().crop({ x: minX, y: minY, w: logoW, h: logoH });
        
        // Maximize on square canvas like before
        const finalDim = Math.ceil(Math.max(logoW, logoH) * 1.1);
        console.log(`Final Canvas Dimension: ${finalDim}`);
        
        const canvas = new Jimp({ width: finalDim, height: finalDim, color: 0xFFFFFFFF });
        
        canvas.composite(cropped, Math.floor((finalDim - logoW)/2), Math.floor((finalDim - logoH)/2));
        
        await canvas.write(targetPath);
        console.log("SUCCESSFULLY PROCESSED USER IMAGE TO MAXIMAL FORMAT!");
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

main();
