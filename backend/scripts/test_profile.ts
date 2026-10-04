import app from '../src/app';
import prisma from '../src/config/prisma';
import { Server } from 'http';

const PORT = 3003;
const BASE_URL = `http://localhost:${PORT}/api`;
let server: Server;

async function request(path: string, options: RequestInit = {}) {
  const response = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
  });
  return {
    status: response.status,
    data: await response.json().catch(() => null),
  };
}

function assert(condition: boolean, message: string): void {
  if (!condition) throw new Error(`ASSERTION FAILED: ${message}`);
  console.log(`PASS: ${message}`);
}

async function register(email: string, name: string, role = 'VOLUNTEER') {
  const response = await request('/auth/register', {
    method: 'POST',
    body: JSON.stringify({ email, name, password: 'password123', role }),
  });
  assert(response.status === 201, `${role} test account registered`);
  return response;
}

async function runTests(): Promise<void> {
  const suffix = Date.now();
  const volunteerEmail = `profile_${suffix}@example.com`;
  const otherVolunteerEmail = `profile_other_${suffix}@example.com`;
  const ngoEmail = `profile_ngo_${suffix}@example.org`;
  server = app.listen(PORT);
  await new Promise((resolve) => setTimeout(resolve, 300));

  try {
    const volunteer = await register(volunteerEmail, 'Profile Volunteer');
    const otherVolunteer = await register(otherVolunteerEmail, 'Other Volunteer');
    const ngo = await register(ngoEmail, 'Profile NGO', 'NGO');
    const volunteerAuth = { Authorization: `Bearer ${volunteer.data.token}` };
    const otherVolunteerAuth = {
      Authorization: `Bearer ${otherVolunteer.data.token}`,
    };
    const ngoAuth = { Authorization: `Bearer ${ngo.data.token}` };

    const missingAuth = await request('/profile/me');
    assert(missingAuth.status === 401, 'profile read requires authentication');

    const ngoRead = await request('/profile/me', { headers: ngoAuth });
    assert(ngoRead.status === 403, 'NGO cannot read volunteer profile endpoint');

    const initial = await request('/profile/me', { headers: volunteerAuth });
    assert(initial.status === 200, 'volunteer reads own profile');
    assert(initial.data.profile.name === 'Profile Volunteer', 'profile name returned');
    assert(Array.isArray(initial.data.profile.interests), 'interests default to an array');
    assert(Array.isArray(initial.data.profile.skills), 'skills default to an array');
    assert(!('passwordHash' in initial.data.profile), 'password hash is not returned');

    const invalidName = await request('/profile/me', {
      method: 'PATCH',
      headers: volunteerAuth,
      body: JSON.stringify({ name: '   ' }),
    });
    assert(invalidName.status === 400, 'blank profile name is rejected');

    const invalidInterests = await request('/profile/me', {
      method: 'PATCH',
      headers: volunteerAuth,
      body: JSON.stringify({ interests: ['Education', 42] }),
    });
    assert(invalidInterests.status === 400, 'invalid interest values are rejected');

    const saved = await request('/profile/me', {
      method: 'PATCH',
      headers: volunteerAuth,
      body: JSON.stringify({
        name: 'Updated Volunteer',
        bio: 'I enjoy helping my community.',
        location: 'Northside',
        interests: ['Education', 'Environment', 'Education'],
        skills: ['Teaching', 'First aid'],
        userId: otherVolunteer.data.user.id,
      }),
    });
    assert(saved.status === 200, 'volunteer updates own profile');
    assert(saved.data.profile.id === volunteer.data.user.id, 'update remains scoped to authenticated user');
    assert(saved.data.profile.interests.length === 2, 'duplicate interests are normalized');
    assert(saved.data.profile.skills[0] === 'Teaching', 'skills are returned');

    const persisted = await request('/profile/me', { headers: volunteerAuth });
    assert(persisted.status === 200, 'updated profile can be loaded again');
    assert(persisted.data.profile.location === 'Northside', 'location persists');
    assert(persisted.data.profile.bio === 'I enjoy helping my community.', 'bio persists');

    const otherProfile = await request('/profile/me', {
      headers: otherVolunteerAuth,
    });
    assert(otherProfile.status === 200, 'second volunteer reads own profile');
    assert(otherProfile.data.profile.name === 'Other Volunteer', 'second volunteer profile was not modified');
    assert(otherProfile.data.profile.location === null, 'second volunteer location remains unchanged');

    const ngoUpdate = await request('/profile/me', {
      method: 'PATCH',
      headers: ngoAuth,
      body: JSON.stringify({ name: 'Not a volunteer' }),
    });
    assert(ngoUpdate.status === 403, 'NGO cannot update volunteer profile endpoint');

    console.log('All volunteer profile integration tests passed.');
  } finally {
    server.close();
    await prisma.user.deleteMany({
      where: { email: { in: [volunteerEmail, otherVolunteerEmail, ngoEmail] } },
    });
    await prisma.$disconnect();
  }
}

runTests().catch((error: unknown) => {
  console.error('Volunteer profile integration tests failed:', error);
  if (server) server.close();
  process.exitCode = 1;
});
