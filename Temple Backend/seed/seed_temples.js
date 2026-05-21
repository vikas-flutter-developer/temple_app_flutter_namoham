import mongoose from 'mongoose';

// MongoDB connection string
const MONGO_URI = 'mongodb://localhost:27017/templeApp';

// Temple Schema
const templeSchema = new mongoose.Schema({
    templePics: [String],
    templeName: String,
    email: String,
    address: String,
    zipCode: String,
    state: String,
    establishmentDate: Date,
    userId: { type: String, unique: true },
    website: String,
    password: String,
    pocPhoneNumber: String,
    bankDetails: {
        accountHolderName: String,
        bankAccountNumber: String,
        ifscCode: String,
        bankName: String
    },
    description: String,
    city: String,
    country: { type: String, default: 'India' },
    rating: { type: Number, default: 4.5 },
    totalReviews: { type: Number, default: 0 },
    posts: { type: Number, default: 0 },
    followers: { type: Number, default: 0 },
    following: { type: Number, default: 0 },
    recommendationPercentage: { type: Number, default: 90 },
    totalDonations: { type: Number, default: 0 },
    isVerified: { type: Boolean, default: false },
    timings: {
        openTime: String,
        closeTime: String,
        specialDays: [String]
    },
    coordinates: {
        latitude: Number,
        longitude: Number
    },
    createdAt: { type: Date, default: Date.now },
    updatedAt: { type: Date, default: Date.now }
});

const Temple = mongoose.model('Temple', templeSchema);

// Complete Dummy Data (10 famous temples with ALL fields filled)
const temples = [
  {
    userId: "temple_kedarnath_001",
    templeName: "Kedarnath Mandir",
    templePics: [
      "https://himalayandreamtreks.in/wp-content/uploads/2023/10/Kedarnath-Temple-min.jpg",
      "https://i.imgur.com/2f5eX8k.jpg",
      "https://i.imgur.com/9kLmN3d.jpg"
    ],
    description: "One of the twelve Jyotirlingas, located at 3,583 meters in the Garhwal Himalayas. Opens only 6 months a year.",
    address: "Kedarnath Dham, Rudraprayag District",
    city: "Kedarnath",
    state: "Uttarakhand",
    zipCode: "246445",
    country: "India",
    email: "admin@kedarnath.org",
    password: "$2b$10$X5sZkP9kL8fG9jQw2vRt5u8eX9kLmN0pQrT6vBcDeFgHiJkL12345", // "kedar123"
    website: "https://kedarnath.gov.in",
    pocPhoneNumber: "+919876543210",
    establishmentDate: new Date("0800-01-01"),
    bankDetails: {
      accountHolderName: "Shri Badarinath Kedarnath Temple Committee",
      bankAccountNumber: "1001002003004001",
      ifscCode: "SBIN0014181",
      bankName: "State Bank of India"
    },
    rating: 4.9,
    totalReviews: 18250,
    posts: 912,
    followers: 148000,
    following: 42,
    recommendationPercentage: 98,
    totalDonations: 6800000,
    isVerified: true,
    timings: {
      openTime: "04:00 AM",
      closeTime: "09:00 PM",
      specialDays: ["Maha Shivaratri", "Shravan Month", "Opening Day", "Closing Day"]
    },
    coordinates: { latitude: 30.7346, longitude: 79.0669 },
    createdAt: new Date("2023-06-15T10:00:00Z"),
    updatedAt: new Date()
  },
  {
    userId: "temple_badrinath_002",
    templeName: "Badrinath Temple",
    templePics: ["https://www.chardham-pilgrimage-tour.com/assets/images/badrinath-banner3.webp"],
    description: "Dedicated to Lord Vishnu, part of Char Dham. Located between Nar and Narayan mountain ranges.",
    address: "Badrinath, Chamoli District",
    city: "Badrinath",
    state: "Uttarakhand",
    zipCode: "246422",
    email: "contact@badrinath.org",
    password: "$2b$10$AbCdEfGhIjKlMnOpQrStUvWxYz1234567890abcdefghijk",
    website: "https://badrinath-kedarnath.gov.in",
    pocPhoneNumber: "+919876543211",
    establishmentDate: new Date("0815-05-10"),
    bankDetails: {
      accountHolderName: "Shri Badrinath Temple Committee",
      bankAccountNumber: "9876543210987654",
      ifscCode: "UBIN0567890",
      bankName: "Union Bank of India"
    },
    rating: 4.8,
    totalReviews: 14200,
    posts: 789,
    followers: 112000,
    following: 38,
    recommendationPercentage: 96,
    totalDonations: 5200000,
    isVerified: true,
    timings: {
      openTime: "04:30 AM",
      closeTime: "09:00 PM",
      specialDays: ["Mata Murti Ka Mela", "Badri-Kedar Utsav"]
    },
    coordinates: { latitude: 30.7433, longitude: 79.4938 }
  },
  {
    userId: "temple_tirupati_005",
    templeName: "Sri Venkateswara Swamy Temple (Tirupati Balaji)",
    templePics: ["https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/A_view_of_Tirumala_Temple.jpg/1200px-A_view_of_Tirumala_Temple.jpg"],
    description: "World's richest and most visited religious place. Dedicated to Lord Venkateswara.",
    address: "Tirumala, Tirupati",
    city: "Tirupati",
    state: "Andhra Pradesh",
    zipCode: "517504",
    email: "helpdesk@tirumala.org",
    password: "$2b$10$Tirupati2025SecureHashForDevOnlyChangeInProd",
    website: "https://www.tirumala.org",
    pocPhoneNumber: "+9187722261234",
    establishmentDate: new Date("0300-01-01"),
    bankDetails: {
      accountHolderName: "Tirumala Tirupati Devasthanams",
      bankAccountNumber: "1000000000000001",
      ifscCode: "HDFC0000240",
      bankName: "HDFC Bank"
    },
    rating: 4.9,
    totalReviews: 98000,
    posts: 6200,
    followers: 780000,
    following: 200,
    recommendationPercentage: 99,
    totalDonations: 210000000,
    isVerified: true,
    timings: {
      openTime: "02:30 AM",
      closeTime: "01:30 AM",
      specialDays: ["Brahmotsavam", "Vaikunta Ekadashi", "Annual Festival"]
    },
    coordinates: { latitude: 13.6833, longitude: 79.3472 }
  },
  {
    userId: "temple_goldentemple_008",
    templeName: "Harmandir Sahib (Golden Temple)",
    templePics: ["https://upload.wikimedia.org/wikipedia/commons/thumb/9/94/The_Golden_Temple_of_Amritsar.jpg/1200px-The_Golden_Temple_of_Amritsar.jpg"],
    description: "Holiest Gurdwara of Sikhism. Serves free langar to over 100,000 people daily.",
    address: "Golden Temple Road, Amritsar",
    city: "Amritsar",
    state: "Punjab",
    zipCode: "143006",
    email: "info@goldentemple.org",
    password: "$2b$10$GoldenTemple2025DevHashChangeInProduction",
    website: "https://sgpc.net",
    pocPhoneNumber: "+911832553999",
    establishmentDate: new Date("1588-09-01"),
    bankDetails: {
      accountHolderName: "Shiromani Gurdwara Parbandhak Committee",
      bankAccountNumber: "1112223334445556",
      ifscCode: "SBIN0001234",
      bankName: "State Bank of India"
    },
    rating: 5.0,
    totalReviews: 125000,
    posts: 8500,
    followers: 920000,
    following: 180,
    recommendationPercentage: 100,
    totalDonations: 280000000,
    isVerified: true,
    timings: {
      openTime: "02:00 AM",
      closeTime: "11:00 PM",
      specialDays: ["Guru Nanak Jayanti", "Baisakhi", "Diwali"]
    },
    coordinates: { latitude: 31.6200, longitude: 74.8765 }
  },
  {
    userId: "temple_vaishnodevi_006",
    templeName: "Vaishno Devi Mandir",
    templePics: ["https://www.maavaishnodevi.org/images/banner1.jpg"],
    description: "Holy cave shrine of Mata Vaishno Devi in Trikuta Mountains, visited by millions every year.",
    address: "Katra, Reasi District",
    city: "Katra",
    state: "Jammu and Kashmir",
    zipCode: "182301",
    email: "info@maavaishnodevi.org",
    password: "$2b$10$VaishnoDevi2025DevOnlyHash123456789",
    website: "https://www.maavaishnodevi.org",
    pocPhoneNumber: "+911992234567",
    establishmentDate: new Date("0700-01-01"),
    bankDetails: {
      accountHolderName: "Shri Mata Vaishno Devi Shrine Board",
      bankAccountNumber: "1234567890123456",
      ifscCode: "JAKA0KATRAX",
      bankName: "J&K Bank"
    },
    rating: 4.8,
    totalReviews: 68000,
    posts: 3400,
    followers: 410000,
    following: 95,
    recommendationPercentage: 97,
    totalDonations: 85000000,
    isVerified: true,
    timings: {
      openTime: "05:00 AM",
      closeTime: "12:00 AM",
      specialDays: ["Navratri", "New Year", "Chaitra Navratri"]
    },
    coordinates: { latitude: 32.9936, longitude: 74.9300 }
  },
  {
    userId: "temple_jagannath_007",
    templeName: "Jagannath Temple Puri",
    templePics: ["https://c.ndtvimg.com/2022-01/4t40lvq_jagannath-puri_625x300_21_January_22.jpg"],
    description: "One of the original Char Dhams, famous for Rath Yatra festival.",
    address: "Grand Road, Puri",
    city: "Puri",
    state: "Odisha",
    zipCode: "752001",
    email: "admin@jagannath.nic.in",
    password: "$2b$10$JagannathPuri2025DevSecureHash",
    website: "https://jagannath.nic.in",
    pocPhoneNumber: "+916752222002",
    establishmentDate: new Date("1174-01-01"),
    bankDetails: {
      accountHolderName: "Shree Jagannath Temple Administration",
      bankAccountNumber: "2003004005006007",
      ifscCode: "SBIN0000045",
      bankName: "State Bank of India"
    },
    rating: 4.7,
    totalReviews: 45000,
    posts: 2900,
    followers: 320000,
    following: 88,
    recommendationPercentage: 95,
    totalDonations: 48000000,
    isVerified: true,
    timings: {
      openTime: "05:00 AM",
      closeTime: "11:00 PM",
      specialDays: ["Rath Yatra", "Snana Yatra", "Chandan Yatra"]
    },
    coordinates: { latitude: 19.8048, longitude: 85.8181 }
  },
  {
    userId: "temple_kashivishwanath_009",
    templeName: "Kashi Vishwanath Temple",
    templePics: ["https://shrikashivishwanath.org/images/banner.jpg"],
    description: "One of the 12 Jyotirlingas, located on the banks of River Ganga in Varanasi.",
    address: "Vishwanath Gali, Varanasi",
    city: "Varanasi",
    state: "Uttar Pradesh",
    zipCode: "221001",
    email: "info@kashivishwanath.org",
    password: "$2b$10$KashiVishwanath2025DevHash123",
    website: "https://shrikashivishwanath.org",
    pocPhoneNumber: "+915422393999",
    establishmentDate: new Date("1780-01-01"),
    bankDetails: {
      accountHolderName: "Kashi Vishwanath Temple Trust",
      bankAccountNumber: "1780178017801780",
      ifscCode: "SBIN0000215",
      bankName: "State Bank of India"
    },
    rating: 4.9,
    totalReviews: 62000,
    posts: 4800,
    followers: 490000,
    following: 110,
    recommendationPercentage: 98,
    totalDonations: 98000000,
    isVerified: true,
    timings: {
      openTime: "03:00 AM",
      closeTime: "11:00 PM",
      specialDays: ["Maha Shivaratri", "Dev Deepawali", "Shravan Month"]
    },
    coordinates: { latitude: 25.3109, longitude: 83.0107 }
  },
  {
    userId: "temple_meenakshi_010",
    templeName: "Meenakshi Amman Temple",
    templePics: ["https://upload.wikimedia.org/wikipedia/commons/0/04/Madurai_meenakshi_temple.jpg"],
    description: "Historic temple with stunning Dravidian architecture and 14 colorful gopurams.",
    address: "Madurai, Tamil Nadu",
    city: "Madurai",
    state: "Tamil Nadu",
    zipCode: "625001",
    email: "admin@maduraimeenakshi.org",
    password: "$2b$10$Meenakshi2025DevOnlyHashSecure",
    website: "https://www.maduraimeenakshi.org",
    pocPhoneNumber: "+914522345678",
    establishmentDate: new Date("0600-01-01"),
    bankDetails: {
      accountHolderName: "Arulmigu Meenakshi Sundareswarar Temple",
      bankAccountNumber: "6007008009001001",
      ifscCode: "IOBA0000021",
      bankName: "Indian Overseas Bank"
    },
    rating: 4.8,
    totalReviews: 39000,
    posts: 2200,
    followers: 280000,
    following: 72,
    recommendationPercentage: 96,
    totalDonations: 38000000,
    isVerified: true,
    timings: {
      openTime: "05:00 AM",
      closeTime: "09:30 PM",
      specialDays: ["Chithirai Festival", "Navaratri", "Float Festival"]
    },
    coordinates: { latitude: 9.9195, longitude: 78.1193 }
  },
  {
    userId: "temple_somnath_004",
    templeName: "Somnath Temple",
    templePics: ["https://somnath.org/assets/images/gallery/somnath-temple.jpg"],
    description: "First among the twelve Jyotirlinga shrines of Shiva. Rebuilt multiple times.",
    address: "Prabhas Patan, Veraval",
    city: "Somnath",
    state: "Gujarat",
    zipCode: "362268",
    email: "info@somnath.org",
    password: "$2b$10$Somnath2025DevHashForSeedingOnly",
    website: "https://somnath.org",
    pocPhoneNumber: "+912876231212",
    establishmentDate: new Date("1951-05-11"),
    bankDetails: {
      accountHolderName: "Shree Somnath Trust",
      bankAccountNumber: "1951195119511951",
      ifscCode: "SBIN0003279",
      bankName: "State Bank of India"
    },
    rating: 4.8,
    totalReviews: 28000,
    posts: 1800,
    followers: 210000,
    following: 65,
    recommendationPercentage: 97,
    totalDonations: 68000000,
    isVerified: true,
    timings: {
      openTime: "06:00 AM",
      closeTime: "09:30 PM",
      specialDays: ["Maha Shivaratri", "Kartik Purnima", "Shravan Month"]
    },
    coordinates: { latitude: 20.8880, longitude: 70.4012 }
  },
  {
    userId: "temple_rameshwaram_011",
    templeName: "Ramanathaswamy Temple",
    templePics: ["https://upload.wikimedia.org/wikipedia/commons/1/1f/Ramanathaswamy_Temple_Pond.jpg"],
    description: "Famous for 22 holy wells and longest temple corridor in India. Part of Char Dham.",
    address: "Rameswaram Island",
    city: "Rameswaram",
    state: "Tamil Nadu",
    zipCode: "623526",
    email: "admin@rameswaramtemple.org",
    password: "$2b$10$Rameshwaram2025DevSecureHash",
    website: "https://rameswaramtemple.tn.gov.in",
    pocPhoneNumber: "+914573223223",
    establishmentDate: new Date("1200-01-01"),
    bankDetails: {
      accountHolderName: "Ramanathaswamy Devasthanam",
      bankAccountNumber: "1200120012001200",
      ifscCode: "SBIN0000742",
      bankName: "State Bank of India"
    },
    rating: 4.8,
    totalReviews: 41000,
    posts: 2100,
    followers: 260000,
    following: 78,
    recommendationPercentage: 96,
    totalDonations: 52000000,
    isVerified: true,
    timings: {
      openTime: "05:00 AM",
      closeTime: "09:00 PM",
      specialDays: ["Maha Shivaratri", "Thai Poosam", "Arudhra Darshan"]
    },
    coordinates: { latitude: 9.2881, longitude: 79.3174 }
  }
];

async function seedTemples() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('Connected to MongoDB');

    const count = await Temple.countDocuments();
    if (count > 0) {
      console.log(`Found ${count} existing temples. Deleting...`);
      await Temple.deleteMany({});
    }

    const result = await Temple.insertMany(temples);
    console.log(`Successfully seeded ${result.length} temples!`);

    console.log('\nInserted Temples:');
    result.forEach((t, i) => {
      console.log(`${i + 1}. ${t.templeName} (${t.city}, ${t.state})`);
    });

    console.log('\nSeeding completed successfully!');

  } catch (error) {
    console.error('Error seeding temples:', error.message);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
    process.exit(0);
  }
}

seedTemples();