/**
 * seed-chat.js
 * 
 * Script tự động:
 *  1. Đăng ký 2 user (alice & bob) vào Identity Service
 *  2. Lấy JWT token của cả 2 user từ Keycloak
 *  3. Tạo cuộc hội thoại giữa alice và bob qua Chat Service
 * 
 * Sau khi chạy xong, bạn chỉ cần login bằng:
 *   - alice / password123
 *   - bob   / password123
 * và cả 2 đã có conversation sẵn trong /chat
 */

const http = require("http");
const https = require("https");
const { URLSearchParams } = require("url");

const GATEWAY   = "http://localhost:8080";
const KEYCLOAK  = "http://localhost:8181";
const REALM     = "clinic-realm";
const CLIENT_ID = "admin-cli";
const CLIENT_SECRET = "JjTiPYv07eVL44pGklrL4sXNZUxIlXYP";

const USERS = [
  { username: "alice_test", password: "password123", email: "alice@medbook.test", firstName: "Alice",  lastName: "Nguyen", dob: "1995-06-15", city: "Hanoi", roles: ["PATIENT"] },
  { username: "bob_test",   password: "password123", email: "bob@medbook.test",   firstName: "Bob",    lastName: "Tran",   dob: "1998-03-22", city: "HCM",   roles: ["DOCTOR"]  },
];

// ─── HTTP Helpers ─────────────────────────────────────────────
function request(url, options, body) {
  return new Promise((resolve, reject) => {
    const mod = url.startsWith("https") ? https : http;
    const req = mod.request(url, options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        try {
          resolve({ status: res.statusCode, body: JSON.parse(data) });
        } catch {
          resolve({ status: res.statusCode, body: data });
        }
      });
    });
    req.on("error", reject);
    if (body) req.write(body);
    req.end();
  });
}

function post(url, body, headers = {}) {
  const isForm = headers["Content-Type"]?.includes("urlencoded");
  const bodyStr = isForm ? body.toString() : JSON.stringify(body);
  const options = {
    method: "POST",
    headers: {
      "Content-Type": isForm ? "application/x-www-form-urlencoded" : "application/json",
      "Content-Length": Buffer.byteLength(bodyStr),
      ...headers,
    },
  };
  return request(url, options, bodyStr);
}

// ─── Steps ────────────────────────────────────────────────────
async function register(user) {
  console.log(`\n📝 Đăng ký user: ${user.username}`);
  const res = await post(`${GATEWAY}/api/v1/identity/users/registration`, user);
  if (res.status === 200 || res.status === 201) {
    console.log(`  ✅ Thành công!`);
  } else if (JSON.stringify(res.body).includes("existed") || JSON.stringify(res.body).includes("alr")) {
    console.log(`  ⚠️  User đã tồn tại, bỏ qua.`);
  } else {
    console.log(`  ❌ Lỗi (${res.status}):`, JSON.stringify(res.body).slice(0, 200));
    throw new Error(`Registration failed for ${user.username}`);
  }
}

async function getToken(username, password) {
  console.log(`\n🔑 Lấy token cho: ${username}`);
  const params = new URLSearchParams({
    grant_type:    "password",
    client_id:     CLIENT_ID,
    client_secret: CLIENT_SECRET,
    username,
    password,
  });
  const res = await post(
    `${KEYCLOAK}/realms/${REALM}/protocol/openid-connect/token`,
    params,
    { "Content-Type": "application/x-www-form-urlencoded" }
  );

  if (res.status === 200) {
    console.log(`  ✅ Token OK`);
    return res.body.access_token;
  }

  // Fallback: Try directly without gateway
  console.log(`  ⚠️  Thử via Keycloak trực tiếp ...`);
  const res2 = await post(
    `${KEYCLOAK}/realms/${REALM}/protocol/openid-connect/token`,
    params,
    { "Content-Type": "application/x-www-form-urlencoded" }
  );
  if (res2.status === 200) {
    console.log(`  ✅ Token OK (direct)`);
    return res2.body.access_token;
  }

  throw new Error(`Token failed for ${username}: ${JSON.stringify(res2.body)}`);
}

async function getUserIdByToken(token) {
  const res = await request(`${GATEWAY}/api/v1/identity/users/my-info`, {
    method: "GET",
    headers: { Authorization: `Bearer ${token}` },
  });
  if (res.status === 200) {
    const userId = res.body?.result?.id || res.body?.id;
    if (userId) return userId;
  }
  throw new Error(`Could not get user info: ${JSON.stringify(res.body)}`);
}

async function createConversation(tokenAlice, bobUserId) {
  console.log(`\n💬 Tạo cuộc hội thoại alice <-> bob (userId: ${bobUserId})`);
  const res = await post(
    `${GATEWAY}/api/v1/chat/conversations`,
    { targetUserId: bobUserId },
    { Authorization: `Bearer ${tokenAlice}` }
  );
  if (res.status === 200 || res.status === 201) {
    console.log(`  ✅ Conversation tạo thành công! ID: ${res.body?._id || res.body?.id || "?"}`);
    return res.body;
  } else {
    console.log(`  ⚠️  (${res.status}):`, JSON.stringify(res.body).slice(0, 200));
  }
}

// ─── Main ─────────────────────────────────────────────────────
async function main() {
  console.log("🚀 MedBook Chat Seed Script");
  console.log("═══════════════════════════════════════\n");

  // Step 1: Register users
  for (const user of USERS) {
    await register(user);
  }

  // Step 2: Get tokens
  const tokenAlice = await getToken(USERS[0].username, USERS[0].password);
  const tokenBob   = await getToken(USERS[1].username, USERS[1].password);

  // Step 3: Get Bob's user ID
  const bobId = await getUserIdByToken(tokenBob);
  console.log(`\n🆔 Bob's User ID: ${bobId}`);

  // Step 4: Create conversation
  await createConversation(tokenAlice, bobId);

  console.log("\n═══════════════════════════════════════");
  console.log("🎉 Seed hoàn tất! Thông tin đăng nhập:");
  console.log("  👤 alice_test / password123");
  console.log("  👤 bob_test   / password123");
  console.log("\nMở 2 tab hoặc 1 tab + 1 cửa sổ ẩn danh và đăng nhập mỗi tab bằng 1 user!");
  console.log("Vào /chat và nhắn tin qua lại nhé! 🔥\n");
}

main().catch((err) => {
  console.error("\n❌ Seed thất bại:", err.message);
  process.exit(1);
});
