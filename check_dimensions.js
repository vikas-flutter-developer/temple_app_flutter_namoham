const { Jimp } = require("jimp");
const path = require('path');

async function check() {
    try {
        const target = path.join(__dirname, 'splash screen.png');
        const image = await Jimp.read(target);
        console.log(`DIMENSIONS: ${image.bitmap.width}x${image.bitmap.height}`);
        
        // Let's also run autocrop just to see what the intrinsic size is
        const clone = image.clone().autocrop();
        console.log(`INTRINSIC: ${clone.bitmap.width}x${clone.bitmap.height}`);
    } catch (e) {
        console.error(e);
    }
}
check();
