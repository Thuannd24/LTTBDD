// dump.js
const http = require("http");

async function main() {
  const tokenRes = await new Promise((res) => {
    const r = http.request('http://localhost:8080/api/v1/auth/token', { method: 'POST', headers: {'Content-Type': 'application/x-www-form-urlencoded'}}, rs => {
      let d = ''; rs.on('data', c => d+=c); rs.on('end', () => res(JSON.parse(d)));
    });
    r.write('grant_type=password&client_id=admin-cli&client_secret=JjTiPYv07eVL44pGklrL4sXNZUxIlXYP&username=alice_test&password=password123');
    r.end();
  });
  
  if (!tokenRes.access_token) return console.log("NO TOKEN", tokenRes);

  const convs = await new Promise((res) => {
    http.get('http://localhost:8080/api/v1/chat/conversations', { headers: { Authorization: "Bearer " + tokenRes.access_token } }, rs => {
      let d = ''; rs.on('data', c => d+=c); rs.on('end', () => res(JSON.parse(d)));
    }).end();
  });
  
  console.log(JSON.stringify(convs, null, 2));
}

main();
