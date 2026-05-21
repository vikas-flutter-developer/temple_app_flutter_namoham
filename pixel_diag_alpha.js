const { Jimp } = require("jimp");
const path = require('path');

async function diag() {
    try {
        const img = await Jimp.read(path.join(__dirname, 'splash screen.png'));
        
        let minX = 99999, minY = 99999, maxX = 0, maxY = 0;
        let found = false;
        
        for(let y=0; y<img.bitmap.height; y++){
            for(let x=0; x<img.bitmap.width; x++){
                const px = img.getPixelColor(x, y);
                // In Jimp (newer versions), default getPixelColor is sometimes RGBA packed or custom format.
                // Let's extract alpha reliably: 
                const alpha = px & 0xFF; 
                
                // If pixel is VISIBLE (alpha > 20)
                if (alpha > 20) {
                    found = true;
                    if (x < minX) minX = x;
                    if (x > maxX) maxX = x;
                    if (y < minY) minY = y;
                    if (y > maxY) maxY = y;
                }
            }
        }
        if (!found) {
            console.log("NO VISIBLE PIXELS DETECTED! Testing if RGB layout is different...");
            // Try alternative mask if alpha wasn't correct bitmask
        } else {
            console.log(`VISIBLE CONTENT BOUNDS: minX=${minX} minY=${minY} maxX=${maxX} maxY=${maxY}`);
            console.log(`Intrinsic Size: ${maxX - minX + 1}x${maxY - minY + 1}`);
        }
    } catch (e) { console.error(e); }
}
diag();
