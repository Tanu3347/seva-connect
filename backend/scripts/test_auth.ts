import app from '../src/app';
import { Server } from 'http';

const PORT = 3001;
const BASE_URL = `http://localhost:${PORT}/api`;

let server: Server;

async function request(path: string, options: RequestInit = {}) {
  const url = `${BASE_URL}${path}`;
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
  });
  const data = await response.json().catch(() => null);
  return { status: response.status, data };
}

function assert(condition: boolean, message: string) {
  if (!condition) {
    console.error(`❌ ASSERTION FAILED: ${message}`);
    throw new Error(message);
  } else {
    console.log(`✅ ${message}`);
  }
}

async function runTests() {
  console.log('🚀 Starting Seva Connect Auth Integration Tests...\n');

  server = app.listen(PORT);
  await new Promise((resolve) => setTimeout(resolve, 500));

  try {
    // 1. Health check
    console.log('--- Test 1: Health Check ---');
    const health = await request('/health');
    assert(health.status === 200, 'Health check returned HTTP 200');
    assert(health.data.status === 'ok', 'Health check message indicates ok');

    // Test unique emails using timestamp
    const timestamp = Date.now();
    const volunteerEmail = `volunteer_${timestamp}@example.com`;
    const ngoEmail = `ngo_${timestamp}@example.org`;

    // 2. Validation failures on registration
    console.log('\n--- Test 2: Registration Validation Errors ---');
    const invalidEmail = await request('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ email: 'invalid-email', password: '123', name: '', role: 'UNKNOWN' }),
    });
    assert(invalidEmail.status === 400, 'Invalid email format rejected with 400');

    const shortPassword = await request('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ email: volunteerEmail, password: '123', name: 'Aarav', role: 'VOLUNTEER' }),
    });
    assert(shortPassword.status === 400, 'Short password (< 6 chars) rejected with 400');

    const invalidRole = await request('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ email: volunteerEmail, password: 'password123', name: 'Aarav', role: 'ADMIN' }),
    });
    assert(invalidRole.status === 400, 'Invalid role rejected with 400');

    // 3. Volunteer Registration
    console.log('\n--- Test 3: Volunteer Registration ---');
    const volReg = await request('/auth/register', {
      method: 'POST',
      body: JSON.stringify({
        email: volunteerEmail,
        password: 'password123',
        name: 'Aarav Patel',
        role: 'VOLUNTEER',
        bio: 'Passionate about educational volunteering',
        contactInfo: '+91 9876543210',
      }),
    });
    assert(volReg.status === 201, 'Volunteer registration returned HTTP 201');
    assert(typeof volReg.data.token === 'string', 'JWT token returned on registration');
    assert(volReg.data.user.role === 'VOLUNTEER', 'Registered user role is VOLUNTEER');
    assert(!volReg.data.user.passwordHash, 'Password hash is NOT exposed in response');
    const volunteerToken = volReg.data.token;

    // 4. Duplicate Registration
    console.log('\n--- Test 4: Duplicate Email Registration ---');
    const duplicateReg = await request('/auth/register', {
      method: 'POST',
      body: JSON.stringify({
        email: volunteerEmail,
        password: 'anotherPassword',
        name: 'Duplicate Aarav',
        role: 'VOLUNTEER',
      }),
    });
    assert(duplicateReg.status === 409, 'Duplicate registration rejected with 409 Conflict');

    // 5. NGO Registration
    console.log('\n--- Test 5: NGO Registration ---');
    const ngoReg = await request('/auth/register', {
      method: 'POST',
      body: JSON.stringify({
        email: ngoEmail,
        password: 'ngoPassword456',
        name: 'Helping Hands Foundation',
        role: 'NGO',
        bio: 'Community relief and youth education NGO',
        contactInfo: 'contact@helpinghands.org',
      }),
    });
    assert(ngoReg.status === 201, 'NGO registration returned HTTP 201');
    assert(typeof ngoReg.data.token === 'string', 'JWT token returned for NGO');
    assert(ngoReg.data.user.role === 'NGO', 'Registered user role is NGO');
    const ngoToken = ngoReg.data.token;

    // 6. Login with Valid Credentials
    console.log('\n--- Test 6: Valid Login (Volunteer & NGO) ---');
    const volLogin = await request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email: volunteerEmail, password: 'password123' }),
    });
    assert(volLogin.status === 200, 'Volunteer login returned HTTP 200');
    assert(typeof volLogin.data.token === 'string', 'JWT token returned on login');
    assert(volLogin.data.user.role === 'VOLUNTEER', 'User role correctly VOLUNTEER');

    const ngoLogin = await request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email: ngoEmail, password: 'ngoPassword456' }),
    });
    assert(ngoLogin.status === 200, 'NGO login returned HTTP 200');
    assert(ngoLogin.data.user.role === 'NGO', 'NGO role correctly NGO');

    // 7. Login with Invalid Credentials
    console.log('\n--- Test 7: Invalid Credentials Login ---');
    const wrongPassword = await request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email: volunteerEmail, password: 'wrongPassword123' }),
    });
    assert(wrongPassword.status === 401, 'Wrong password rejected with 401');

    const nonExistentEmail = await request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email: 'nonexistent@example.com', password: 'password123' }),
    });
    assert(nonExistentEmail.status === 401, 'Non-existent email rejected with 401');

    // 8. JWT Verification (/auth/me)
    console.log('\n--- Test 8: JWT Verification & Profile (/auth/me) ---');
    const meValid = await request('/auth/me', {
      headers: { Authorization: `Bearer ${volunteerToken}` },
    });
    assert(meValid.status === 200, 'Valid JWT /auth/me returned HTTP 200');
    assert(meValid.data.user.email === volunteerEmail, 'Profile email matches authenticated user');

    const meInvalid = await request('/auth/me', {
      headers: { Authorization: 'Bearer invalid.token.payload' },
    });
    assert(meInvalid.status === 401, 'Invalid JWT token rejected with 401');

    const meMissing = await request('/auth/me');
    assert(meMissing.status === 401, 'Missing Authorization header rejected with 401');

    // 9. Role-Based Authorization Checks
    console.log('\n--- Test 9: Role-Based Authorization Middleware ---');
    // Volunteer accessing Volunteer route -> 200
    const volOnVolRoute = await request('/protected/volunteer-only', {
      headers: { Authorization: `Bearer ${volunteerToken}` },
    });
    assert(volOnVolRoute.status === 200, 'Volunteer successfully accessed volunteer-only route');

    // NGO accessing Volunteer route -> 403 Forbidden
    const ngoOnVolRoute = await request('/protected/volunteer-only', {
      headers: { Authorization: `Bearer ${ngoToken}` },
    });
    assert(ngoOnVolRoute.status === 403, 'NGO access to volunteer-only route forbidden (403)');

    // NGO accessing NGO route -> 200
    const ngoOnNgoRoute = await request('/protected/ngo-only', {
      headers: { Authorization: `Bearer ${ngoToken}` },
    });
    assert(ngoOnNgoRoute.status === 200, 'NGO successfully accessed NGO-only route');

    // Volunteer accessing NGO route -> 403 Forbidden
    const volOnNgoRoute = await request('/protected/ngo-only', {
      headers: { Authorization: `Bearer ${volunteerToken}` },
    });
    assert(volOnNgoRoute.status === 403, 'Volunteer access to NGO-only route forbidden (403)');

    // Unauthenticated accessing protected route -> 401
    const noTokenProtected = await request('/protected/volunteer-only');
    assert(noTokenProtected.status === 401, 'Unauthenticated request to protected route returned 401');

    console.log('\n🎉 ALL AUTHENTICATION AND AUTHORIZATION TESTS PASSED!\n');
  } finally {
    server.close();
  }
}

runTests().catch((err) => {
  console.error('Test suite failed:', err);
  if (server) server.close();
  process.exit(1);
});
