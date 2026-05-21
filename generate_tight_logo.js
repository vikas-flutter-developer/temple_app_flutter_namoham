const { Jimp } = require("jimp");
const path = require('path');

async function main() {
    try {
        const imgPath = path.join(__dirname, 'splash screen.png');
        const targetPath = path.join(__dirname, 'assets', 'splash', 'namo_logo_tight.png');
        
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
        
        // ADD A VERY SMALL TIGHT PADDING (5%) FOR UI AESTHETICS
        const pad = Math.floor(Math.min(w,h) * 0.05);
        const finalW = w + pad*2;
        const finalH = h + pad*2;
        
        const cropped = img.clone().crop({ x: minX, y: minY, w: w, h: h });
        
        const finalCanvas = new Jimp({ width: finalW, height: finalH, color: 0xFFFFFFFF });
        finalCanvas.composite(cropped, pad, pad);
        
        await finalCanvas.write(targetPath);
        console.log(`SUCCESSFULLY CREATED TIGHT LOGO: ${finalW}x${finalH}`);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

main();
