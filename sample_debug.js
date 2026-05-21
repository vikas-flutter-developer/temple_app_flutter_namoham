const { Jimp } = require("jimp");
const path = require('path');

async function diag() {
    try {
        const img = await Jimp.read(path.join(__dirname, 'splash screen.png'));
        
        for(let y=0; y<5; y++){
            for(let x=0; x<5; x++){
                const val = img.getPixelColor(x,y);
                console.log(`Pixel (${x},${y}): Hex=${val.toString(16)}`);
            }
        }
    } catch (e) { console.error(e); }
}
diag();
