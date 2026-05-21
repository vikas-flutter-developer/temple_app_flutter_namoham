const { Jimp } = require("jimp");
const path = require('path');

async function diag() {
    try {
        const img = await Jimp.read(path.join(__dirname, 'splash screen.png'));
        const p1 = img.getPixelColor(0, 0);
        const p2 = img.getPixelColor(1499, 3247);
        console.log(`Pixel (0,0): hex=${p1.toString(16)}   r=${(p1>>24)&0xFF} g=${(p1>>16)&0xFF} b=${(p1>>8)&0xFF} a=${p1&0xFF}`);
        console.log(`Pixel (MAX,MAX): hex=${p2.toString(16)} r=${(p2>>24)&0xFF} g=${(p2>>16)&0xFF} b=${(p2>>8)&0xFF} a=${p2&0xFF}`);
        
        // Let me count how many pixels HAVE a > 100
        let count = 0;
        for (let y=0; y<img.bitmap.height; y++) {
            for (let x=0; x<img.bitmap.width; x++) {
                if ((img.getPixelColor(x, y) & 0xFF) > 100) count++;
            }
        }
        console.log(`Total strong alpha pixels: ${count} out of ${img.bitmap.width * img.bitmap.height}`);
    } catch (e) { console.error(e); }
}
diag();
