const { Jimp } = require("jimp");
const path = require('path');

async function main() {
    try {
        const targetPath = path.join(__dirname, 'assets', 'splash', 'namo_ham_splash.png');
        const image = await Jimp.read(targetPath);
        
        console.log("Auto-cropping initial image...");
        image.autocrop();
        const W = image.bitmap.width;
        const H = image.bitmap.height;
        
        const rowHasContent = new Array(H).fill(false);
        
        for (let y = 0; y < H; y++) {
            for (let x = 0; x < W; x++) {
                const hex = image.getPixelColor(x, y);
                // Deconstruct components manually to be safe
                const r = (hex >> 24) & 0xFF;
                const g = (hex >> 16) & 0xFF;
                const b = (hex >> 8) & 0xFF;
                
                // Consider non-white if any channel deviates significantly from white (255)
                if (r < 253 || g < 253 || b < 253) {
                    rowHasContent[y] = true;
                    break;
                }
            }
        }
        
        const blocks = [];
        let start = -1;
        for (let y = 0; y < H; y++) {
            if (rowHasContent[y] && start === -1) {
                start = y;
            } else if (!rowHasContent[y] && start !== -1) {
                blocks.push({ start, end: y - 1 });
                start = -1;
            }
        }
        if (start !== -1) {
            blocks.push({ start, end: H - 1 });
        }
        
        console.log("Detected blocks:", blocks);
        
        let logoImg, textImg, combinedImage;
        
        if (blocks.length >= 2) {
            const logoBlock = blocks[0];
            const textBlock = blocks[blocks.length - 1];
            
            logoImg = image.clone().crop({ x: 0, y: logoBlock.start, w: W, h: logoBlock.end - logoBlock.start + 1 }).autocrop();
            textImg = image.clone().crop({ x: 0, y: textBlock.start, w: W, h: textBlock.end - textBlock.start + 1 }).autocrop();
            
            console.log(`Extracted: Logo ${logoImg.bitmap.width}x${logoImg.bitmap.height}, Text ${textImg.bitmap.width}x${textImg.bitmap.height}`);
            
            // Reduce gap drastically to shrink height! Set gap to fixed minimal pixels for visual tightness
            const gap = 20; 
            
            const cW = Math.max(logoImg.bitmap.width, textImg.bitmap.width);
            const cH = logoImg.bitmap.height + gap + textImg.bitmap.height;
            
            combinedImage = new Jimp({ width: cW, height: cH, color: 0xFFFFFFFF });
            combinedImage.composite(logoImg, Math.floor((cW - logoImg.bitmap.width)/2), 0);
            combinedImage.composite(textImg, Math.floor((cW - textImg.bitmap.width)/2), logoImg.bitmap.height + gap);
        } else {
            console.log("Could not identify separation. Using whole autocropped image.");
            combinedImage = image;
        }
        
        const fW = combinedImage.bitmap.width;
        const fH = combinedImage.bitmap.height;
        
        // Max dimension approach: 
        // Android 12 circle fits exactly width*2/3.
        // So to maximize visibility without absolute clipping of critical midpoints:
        // canvas = 1.25 * H. This means the logo fills 1 / 1.25 = 80% of canvas height.
        // This will easily satisfy almost all launchers while making it look MASSIVE!
        const dim = Math.ceil(Math.max(fW, fH) * 1.2);
        
        console.log(`Creating output canvas ${dim}x${dim} with content ${fW}x${fH}`);
        const canvas = new Jimp({ width: dim, height: dim, color: 0xFFFFFFFF });
        canvas.composite(combinedImage, Math.floor((dim - fW)/2), Math.floor((dim - fH)/2));
        
        await canvas.write(targetPath);
        console.log("COMPLETION SUCCESSFUL!");
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

main();
