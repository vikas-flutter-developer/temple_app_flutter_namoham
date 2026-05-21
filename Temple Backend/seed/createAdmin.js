import mongoose from 'mongoose';
import 'dotenv/config';
import Admin from '../models/adminModel.js';

const dbURI = process.env.MONGO_URI;

const createAdminAccount = async () => {
    try {
        // Connect to MongoDB
        await mongoose.connect(dbURI);
        console.log('✅ MongoDB connected successfully');

        // Check if admin already exists
        const existingAdmin = await Admin.findOne({
            $or: [
                { username: 'admin' },
                { email: 'admin@templeapp.com'} 
            ]
        });

        if (existingAdmin) {
            console.log('⚠️ Admin account already exists!');
            console.log('Username:', existingAdmin.username);
            console.log('Email:', existingAdmin.email);
            console.log('Role:', existingAdmin.role);
            await mongoose.connection.close();
            return;
        }

        // Create new admin account
        const admin = new Admin({
            username: 'admin',
            email: 'admin@templeapp.com',
            password: 'Admin@123', // This will be hashed automatically
            fullName: 'System Administrator',
            profilePic: 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
            isActive: true
        });

        await admin.save();

        console.log('✅ Admin account created successfully!');
        console.log('=====================================');
        console.log('Login Credentials:');
        console.log('Username: admin');
        console.log('Password: Admin@123');
        console.log('Email: admin@templeapp.com');
        console.log('Role: superadmin');
        console.log('=====================================');
        console.log('⚠️ IMPORTANT: Please change the password after first login!');

        await mongoose.connection.close();
        console.log('MongoDB connection closed');

    } catch (error) {
        console.error('❌ Error creating admin account:', error);
        await mongoose.connection.close();
        process.exit(1);
    }
};

// Run the function
createAdminAccount();
