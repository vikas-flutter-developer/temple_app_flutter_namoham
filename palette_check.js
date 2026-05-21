const { Jimp } = require("jimp");
const path = require('path');

async function diag() {
    try {
        const img = await Jimp.read(path.join(__dirname, 'splash screen.png'));
        const p = img.getPixelColor(10, 10);
        console.log(`Pixel (10,10): hex=${p.toString(16)} r=${(p>>24)&0xFF} g=${(p>>16)&0xFF} b=${(p>>8)&0xFF} a=${p&0xFF}`);
        
        // What is the most common color?
        let colorCounts = {};
        for(let y=0; y<img.bitmap.height; y+=50) { // Sample
            for(let x=0; x<img.bitmap.width; x+=50) {
                const px = img.getPixelColor(x,y).toString(16);
                colorCounts[px] = (colorCounts[px] || 0) + 1;
            }
        }
        console.log("MOST COMMON COLORS (Sampled):", colorCounts);
    } catch (e) { console.error(e); }
}
diag();
