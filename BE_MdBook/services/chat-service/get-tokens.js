#!/usr/bin/env node

const axios = require('axios');

// Configuration
const KEYCLOAK_URL = process.env.KEYCLOAK_URL || 'http://localhost:8181';
const KEYCLOAK_REALM = process.env.KEYCLOAK_REALM || 'clinic-realm';
const KEYCLOAK_CLIENT = process.env.KEYCLOAK_CLIENT || 'clinic-client';
const KEYCLOAK_SECRET = process.env.KEYCLOAK_SECRET || 'clinic-client-secret';

// Test users
const TEST_USERS = [
  { username: 'alice_test', password: 'alice_test' },
  { username: 'bob_test', password: 'bob_test' },
  { username: 'testuser1', password: 'testuser1' },
];

async function getToken(username, password) {
  try {
    const response = await axios.post(
      `${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/token`,
      new URLSearchParams({
        grant_type: 'password',
        client_id: KEYCLOAK_CLIENT,
        client_secret: KEYCLOAK_SECRET,
        username,
        password,
        scope: 'openid profile email',
      }).toString(),
      {
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      }
    );

    return {
      username,
      success: true,
      access_token: response.data.access_token,
      token_type: response.data.token_type || 'Bearer',
      expires_in: response.data.expires_in,
    };
  } catch (error) {
    return {
      username,
      success: false,
      error: error.response?.data?.error_description || error.message,
    };
  }
}

async function getUserInfo(token) {
  try {
    const response = await axios.get(`${KEYCLOAK_URL}/realms/${KEYCLOAK_REALM}/protocol/openid-connect/userinfo`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    return response.data;
  } catch (error) {
    return null;
  }
}

async function main() {
  console.log('🔐 Keycloak Token Retrieval');
  console.log('==========================\n');
  console.log(`Keycloak URL: ${KEYCLOAK_URL}`);
  console.log(`Realm: ${KEYCLOAK_REALM}`);
  console.log(`Client: ${KEYCLOAK_CLIENT}\n`);

  console.log('Fetching tokens for test users...\n');

  const results = [];

  for (const user of TEST_USERS) {
    console.log(`Getting token for ${user.username}...`);
    const tokenResult = await getToken(user.username, user.password);

    if (tokenResult.success) {
      const userInfo = await getUserInfo(tokenResult.access_token);
      console.log(`✅ Success\n`);
      console.log(`   Token (expires in ${tokenResult.expires_in}s):`);
      console.log(`   ${tokenResult.access_token.substring(0, 50)}...\n`);
      if (userInfo) {
        console.log(`   User Info:`);
        console.log(`   - ID: ${userInfo.sub}`);
        console.log(`   - Name: ${userInfo.name}`);
        console.log(`   - Email: ${userInfo.email}\n`);
      }
      results.push({
        ...tokenResult,
        userInfo,
      });
    } else {
      console.log(`❌ Failed: ${tokenResult.error}\n`);
    }
  }

  // Export for environment
  console.log('\n📝 Environment Variables:\n');
  console.log(`Export these to use tokens in tests:\n`);
  
  results.forEach((result, idx) => {
    if (result.success) {
      const envName = result.username.toUpperCase().replace(/[^A-Z0-9]/g, '_') + '_TOKEN';
      console.log(`export ${envName}="${result.access_token}"`);
    }
  });

  console.log('\n💡 Usage:\n');
  console.log('To run E2E tests with these tokens:');
  results.forEach((result, idx) => {
    if (result.success && idx < 2) {
      const envName = result.username.toUpperCase().replace(/[^A-Z0-9]/g, '_') + '_TOKEN';
      console.log(`export ${envName}="${result.access_token}"`);
    }
  });
  console.log('npm run test:e2e');
}

if (require.main === module) {
  main().catch((error) => {
    console.error('Error:', error.message);
    process.exit(1);
  });
}
