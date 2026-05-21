import mongoose from 'mongoose';

const remoteUri = "mongodb+srv://abhitreader_db_user:EMtQH7RfreWh9Y7K@cluster0.kkb9tlf.mongodb.net/templeapp?retryWrites=true&w=majority";

console.log('🔌 Attempting to connect to Remote MongoDB...');

async function run() {
    try {
        const conn = await mongoose.connect(remoteUri, { serverSelectionTimeoutMS: 5000 });
        console.log(`✅ SUCCESS! MongoDB Connected: ${conn.connection.host}`);
        await mongoose.disconnect();
        process.exit(0);
    } catch (error) {
        console.error(`❌ FAILED to connect to remote MongoDB!`);
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }
}

run();
