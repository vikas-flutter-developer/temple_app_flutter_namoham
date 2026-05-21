const { Jimp } = require("jimp");
const path = require('path');

async function diag() {
    try {
        const img = await Jimp.read(path.join(__dirname, 'splash screen.png'));
        const val = img.getPixelColor(0,0);
        console.log(`HEX VALUE: ${val.toString(16)}`);
    } catch (e) { console.error(e); }
}
diag();
