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
                if (a < 10) continue; 
                
                const r = (px >> 24) & 0xFF;
                const g = (px >> 16) & 0xFF;
                const b = (px >> 8) & 0xFF;
                
                if (r < 250 || g < 250 || b < 250) {
                    logoPixels++;
                    if (x < minX) minX = x;
                    if (x > maxX) maxX = x;
                    if (y < minY) minY = y;
                    if (y > maxY) maxY = y;
                }
            }
        }
        
        const w = maxX - minX + 1;
        const h = maxY - minY + 1;
        
        const cropped = img.clone().crop({ x: minX, y: minY, w: w, h: h });
        
        // FIXED MATH FOR WIDE IMAGES ON CIRCULAR MASKS:
        // To prevent ANY pixel being cut off by circular masks:
        // Maximum corner distance must fit within Safe Radius = Dimension / 3.
        // Distance to corner = sqrt(W^2 + H^2) / 2
        // Dimension / 3 >= sqrt(W^2 + H^2) / 2
        // Dimension >= 1.5 * sqrt(W^2 + H^2)
        
        const diagonal = Math.sqrt(w*w + h*h);
        
        // Use 1.65x buffer to provide a tiny, handsome padding buffer inside the circle boundaries.
        const targetDim = Math.ceil(diagonal * 1.65); 
        
        console.log(`Content: ${w}x${h}, Diagonal: ${Math.ceil(diagonal)}`);
        console.log(`SAFE CANVAS DIMENSION: ${targetDim}x${targetDim}`);
        
        const finalCanvas = new Jimp({ width: targetDim, height: targetDim, color: 0xFFFFFFFF });
        finalCanvas.composite(cropped, Math.floor((targetDim - w)/2), Math.floor((targetDim - h)/2));
        
        await finalCanvas.write(targetPath);
        console.log("SUCCESSFULLY APPLIED SAFE MASK PADDING!");
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

main();
