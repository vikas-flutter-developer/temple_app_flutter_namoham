import 'dotenv/config';
process.env.TZ = 'Asia/Kolkata'; // Force Indian Standard Time globally
import express from "express";
import path from "path";
import { router } from "./api.js";
import { fileURLToPath } from "url";
import { createServer } from "http";
import { Server } from "socket.io";
// import mongoose from "mongoose"; // Mongoose connection now handled in config/db.js
import cors from "cors";
import morgan from "morgan";
import cookieParser from "cookie-parser";
import connectDB from './config/db.js';
import config from './config/env.js';
import startAccountCleanupCron from './utils/accountCleanupCron.js';
import startEventReminderCron from './utils/eventReminderCron.js';

const app = express();
// const dbURI = process.env.MONGO_URI; // Moved to config/env.js and config/db.js

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Middleware
app.use(
  cors({
    origin: "*", // Adjust in production: e.g., "http://localhost:3000" or your frontend URL
    credentials: true,
  })
);
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan("dev"));
app.use(cookieParser());

// Serve uploaded files
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// Basic route
app.get("/", (req, res) => {
  res.send("Server is Up and Running...");
});

// API routes
app.use("/api", router);

// Validate MongoDB URI - Handled in connectDB now, but we can check config
if (!config.mongoUri) {
  console.error("Error: MONGO_URI is not defined in .env file");
  process.exit(1);
}

// Connect to MongoDB
await connectDB();

// Start the daily cleanup cron job for deactivated accounts
startAccountCleanupCron();

// Create HTTP server (required for Socket.IO)
const httpServer = createServer(app);

// Socket.IO setup
const io = new Server(httpServer, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
    credentials: true,
  },
});

// Store online users: Map<userId, socketId>
const connectedUsers = new Map();

io.on("connection", (socket) => {
  console.log("User connected:", socket.id);

  // User joins with their userId (from frontend auth)
  socket.on("join", (userId) => {
    connectedUsers.set(userId, socket.id);
    console.log(`User ${userId} joined → socket ${socket.id}`);
    console.log(`Total online users: ${connectedUsers.size}`);
  });

  // Handle sending a private message
  socket.on("sendMessage", (data) => {
    const { receiverId, message } = data;
    const receiverSocketId = connectedUsers.get(receiverId);

    if (receiverSocketId) {
      io.to(receiverSocketId).emit("newMessage", message);
      console.log(`Message delivered to ${receiverId}`);
    } else {
      console.log(`User ${receiverId} is offline → message should be saved in DB`);
      // Optionally emit back to sender for "not delivered" status
    }
  });

  // Typing indicator
  socket.on("typing", ({ receiverId, senderId, senderName }) => {
    const receiverSocketId = connectedUsers.get(receiverId);
    if (receiverSocketId) {
      io.to(receiverSocketId).emit("userTyping", { senderId, senderName });
    }
  });

  socket.on("stopTyping", ({ receiverId, senderId }) => {
    const receiverSocketId = connectedUsers.get(receiverId);
    if (receiverSocketId) {
      io.to(receiverSocketId).emit("userStopTyping", { senderId });
    }
  });

  // Handle disconnection
  socket.on("disconnect", () => {
    let disconnectedUserId = null;

    for (const [userId, socketId] of connectedUsers.entries()) {
      if (socketId === socket.id) {
        disconnectedUserId = userId;
        connectedUsers.delete(userId);
        break;
      }
    }

    if (disconnectedUserId) {
      console.log(`User ${disconnectedUserId} disconnected`);
    }

    console.log(`Online users: ${connectedUsers.size}`);
  });
});

// Make io and connectedUsers available in routes (optional)
app.set("io", io);
app.set("connectedUsers", connectedUsers);

// Start ngrok tunnel (optional). Use dynamic import to support ESM.
// ──────────────────────────────────────────────────────────────
// Modern ngrok setup (2024–2025) – works perfectly
// ──────────────────────────────────────────────────────────────
// ─────── NGROK – Latest working version (ngrok v5+, 2025) ───────
// ─────── NGROK – Bulletproof Setup for v5+ (Dec 2025) ───────
// (async function startNgrok() {
//   if (config.nodeEnv === "production") return;

//   try {
//     const ngrok = (await import("ngrok")).default;

//     // Ensure PORT is a number (critical fix!)
//     const port = Number(config.port);
//     if (isNaN(port)) {
//       throw new Error("PORT must be a valid number");
//     }

//     let url;
//     if (config.ngrokAuthtoken) {
//       // With auth: Use config object (safer for v5+)
//       url = await ngrok.connect({
//         addr: port,
//         authtoken: config.ngrokAuthtoken
//       });
//       console.log("config.ngrokAuthtoken" , )
//     } else {
//       // No auth: Direct port (simplest)
//       url = await ngrok.connect(port);
//     }

//     console.log("========================================");
//     console.log("NGROK TUNNEL ACTIVE ✅");
//     console.log(`Local:      http://localhost:${port}`);
//     console.log(`Public:     ${url}`);
//     console.log(`Socket.IO:  Use ${url.replace('https://', 'https://')}`);  // For WS upgrades
//     console.log("========================================");
//   } catch (err) {
//     console.warn("ngrok failed:", err.message);
//     if (err.message.includes("invalid tunnel configuration")) {
//       console.warn("🔧 Fix tips:");
//       console.warn("  1. Run: npm install ngrok@latest");
//       console.warn("  2. Check .env: PORT=8000 (number, no quotes)");
//       console.warn("  3. Get free token: https://ngrok.com/get-started/your-authtoken");
//       console.warn("  4. Test manually: npx ngrok http 8000");
//     } else if (err.message.includes("connection refused")) {
//       console.warn("🔧 Server not reachable? Ensure http://localhost:8000 works first.");
//     }
//   }
// })();


// Start the server (ONLY ONE LISTEN!)
const PORT = config.port;

httpServer.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
  console.log(`Socket.IO ready for real-time connections`);
  console.log(`Total online users: ${connectedUsers.size}`);

  // Start the event reminder cron job (needs app & socket.io to be ready)
  startEventReminderCron(app);
});