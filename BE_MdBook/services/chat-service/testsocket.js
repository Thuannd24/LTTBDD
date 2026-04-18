// test-client.js
const { io } = require("socket.io-client");

// Setup from environment or fallback
const TOKEN = process.env.TOKEN || "Bearer YOUR_JWT_TOKEN_HERE";
const SERVER_URL = process.env.SERVER_URL || "ws://localhost:8080";
const PATH = "/api/v1/chat/socket.io";
const TO_USER_ID = process.env.TO_USER_ID || "RECIPIENT_KEYCLOAK_UUID";

console.log("Connecting to:", SERVER_URL, PATH);

const socket = io(SERVER_URL, {
  path: PATH,
  auth: {
    token: TOKEN
  }
});

socket.on("connect", () => {
  console.log("✅ Connected with socket id:", socket.id);

  // Gửi thử một tin nhắn
  socket.emit("send_message", {
    toUserId: TO_USER_ID,
    content: "Ping E2E from automated test!",
    images: [],
    files: []
  });

  // Yêu cầu lịch sử chat
  socket.emit("load_history", {
    friendId: TO_USER_ID
  });
});


// Nhận tin nhắn gửi đi thành công
socket.on("message_sent", (msg) => {
  console.log("📤 message_sent:", msg);
});

// Nhận tin nhắn đến
socket.on("receive_message", (msg) => {
  console.log("📥 receive_message:", msg);
});

// Nhận lịch sử tin nhắn
socket.on("chat_history", (messages) => {
  console.log("📚 chat_history:", messages);
});

// Báo lỗi kết nối
socket.on("connect_error", (err) => {
  console.error("❌ connect_error:", err.message);
});
socket.on("disconnect",()=>{
  
})