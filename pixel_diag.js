const { Jimp } = require("jimp");
const path = require('path');

async function diag() {
    try {
        const img = await Jimp.read(path.join(__dirname, 'splash screen.png'));
        const hex = img.getPixelColor(0, 0);
        
        const r = (hex >> 24) & 0xFF;
        const g = (hex >> 16) & 0xFF;
        const b = (hex >> 8) & 0xFF;
        const a = (hex & 0xFF);
        
        console.log(`COLOR AT 0,0: R=${r} G=${g} B=${b} A=${a}`);
        
        // Let's try to find the bounding box of non-white visually
        let minX = 99999, minY = 99999, maxX = 0, maxY = 0;
        let found = false;
        for(let y=0; y<img.bitmap.height; y++){
            for(let x=0; x<img.bitmap.width; x++){
                const px = img.getPixelColor(x, y);
                const pr = (px >> 24) & 0xFF;
                const pg = (px >> 16) & 0xFF;
                const pb = (px >> 8) & 0xFF;
                // If significantly different from R=255,G=255,B=255
                if (pr < 250 || pg < 250 || pb < 250) {
                    found = true;
                    if (x < minX) minX = x;
                    if (x > maxX) maxX = x;
                    if (y < minY) minY = y;
                    if (y > maxY) maxY = y;
                }
            }
        }
        console.log(`BOUNDING BOX FOUND: minX=${minX} minY=${minY} maxX=${maxX} maxY=${maxY}`);
        console.log(`Total Content Dimensions: ${maxX - minX + 1}x${maxY - minY + 1}`);
    } catch (e) { console.error(e); }
}
diag();
