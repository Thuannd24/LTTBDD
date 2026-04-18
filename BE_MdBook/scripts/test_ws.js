const io = require("socket.io-client");
const axios = require("axios");

async function run() {
  try {
    // 1. Get Token
    const params = new URLSearchParams();
    params.append('grant_type', 'password');
    params.append('client_id', 'admin-cli');
    params.append('client_secret', 'JjTiPYv07eVL44pGklrL4sXNZUxIlXYP');
    params.append('username', 'alice_test');
    params.append('password', 'password123');

    const res = await axios.post("http://localhost:8080/api/v1/auth/token", params);
    const token = res.data.access_token;
    console.log("Logged in successfully. Token length:", token.length);

    // 2. Connect Socket
    const socket = io("http://localhost:8080", {
      path: "/api/v1/chat/socket.io",
      auth: { token: `Bearer ${token}` }
    });

    socket.on("connect", () => {
      console.log("Socket connected! ID:", socket.id);
      
      const payload = {
        conversationId: "69ce38cdb43351936b8940c2",
        content: "Testing raw emit",
        contentType: "TEXT"
      };
      
      console.log("Emitting message:send", payload);
      socket.emit("message:send", payload);
    });

    socket.on("connect_error", (err) => {
      console.error("Connect error:", err.message);
    });

    socket.on("chat:error", (err) => {
      console.error("chat:error event received:", err);
    });

    socket.on("message:new", (msg) => {
      console.log("message:new event received:", msg);
      process.exit(0);
    });

    setTimeout(() => {
      console.log("Timeout! No message:new received.");
      process.exit(1);
    }, 5000);

  } catch (err) {
    console.error("Script error:", err?.response?.data || err.message);
  }
}

run();
