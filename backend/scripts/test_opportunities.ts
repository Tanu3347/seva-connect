import app from '../src/app';
import { Server } from 'http';

const PORT = 3002;
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
  console.log('🚀 Starting Seva Connect Opportunity & Application Integration Tests...\n');

  server = app.listen(PORT);
  await new Promise((resolve) => setTimeout(resolve, 500));

  const ts = Date.now();
  const ngoEmail = `testngo_opp_${ts}@example.org`;
  const volunteerEmail = `testvol_opp_${ts}@example.com`;
  const volunteer2Email = `testvol2_opp_${ts}@example.com`;
  const ngo2Email = `testngo2_opp_${ts}@example.org`;

  try {
    // ========== SETUP: Register users ==========
    console.log('--- Setup: Register NGO, Volunteer, Volunteer2, NGO2 ---');

    const ngoReg = await request('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ email: ngoEmail, password: 'password123', name: 'Green Earth Foundation', role: 'NGO' }),
    });
    assert(ngoReg.status === 201, 'NGO registered');
    const ngoToken = ngoReg.data.token;

    const volReg = await request('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ email: volunteerEmail, password: 'password123', name: 'Priya Sharma', role: 'VOLUNTEER', bio: 'Eager volunteer' }),
    });
    assert(volReg.status === 201, 'Volunteer registered');
    const volunteerToken = volReg.data.token;

    const vol2Reg = await request('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ email: volunteer2Email, password: 'password123', name: 'Arjun Singh', role: 'VOLUNTEER' }),
    });
    assert(vol2Reg.status === 201, 'Volunteer2 registered');
    const volunteer2Token = vol2Reg.data.token;

    const ngo2Reg = await request('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ email: ngo2Email, password: 'password123', name: 'Helping Hands', role: 'NGO' }),
    });
    assert(ngo2Reg.status === 201, 'NGO2 registered');
    const ngo2Token = ngo2Reg.data.token;

    // ========== TEST 1: NGO creates opportunity ==========
    console.log('\n--- Test 1: NGO Creates Opportunity ---');
    const createOpp = await request('/opportunities', {
      method: 'POST',
      headers: { Authorization: `Bearer ${ngoToken}` },
      body: JSON.stringify({
        title: 'Beach Cleanup Drive',
        description: 'Help us clean the local beach and protect marine life.',
        location: 'Mumbai, Marine Drive',
        date: '2026-12-15T09:00:00Z',
      }),
    });
    assert(createOpp.status === 201, 'Opportunity created with HTTP 201');
    assert(createOpp.data.opportunity.title === 'Beach Cleanup Drive', 'Title matches');
    assert(createOpp.data.opportunity.status === 'OPEN', 'Default status is OPEN');
    assert(createOpp.data.opportunity.ngo.name === 'Green Earth Foundation', 'NGO name included');
    const opportunityId = createOpp.data.opportunity.id;

    // Volunteer cannot create opportunity
    const volCreateOpp = await request('/opportunities', {
      method: 'POST',
      headers: { Authorization: `Bearer ${volunteerToken}` },
      body: JSON.stringify({
        title: 'Illegal opportunity', description: 'Nope', location: 'Nowhere', date: '2026-12-01',
      }),
    });
    assert(volCreateOpp.status === 403, 'Volunteer cannot create opportunity (403)');

    // ========== TEST 2: Validation errors on opportunity creation ==========
    console.log('\n--- Test 2: Opportunity Creation Validation ---');
    const missingTitle = await request('/opportunities', {
      method: 'POST',
      headers: { Authorization: `Bearer ${ngoToken}` },
      body: JSON.stringify({ description: 'Desc', location: 'Loc', date: '2026-12-01' }),
    });
    assert(missingTitle.status === 400, 'Missing title rejected');

    const missingDate = await request('/opportunities', {
      method: 'POST',
      headers: { Authorization: `Bearer ${ngoToken}` },
      body: JSON.stringify({ title: 'Title', description: 'Desc', location: 'Loc' }),
    });
    assert(missingDate.status === 400, 'Missing date rejected');

    // ========== TEST 3: Browse opportunities ==========
    console.log('\n--- Test 3: Browse & Search Opportunities ---');
    const browseAll = await request('/opportunities');
    assert(browseAll.status === 200, 'Browse opportunities returned 200');
    assert(Array.isArray(browseAll.data.opportunities), 'Opportunities is an array');
    const found = browseAll.data.opportunities.find((o: any) => o.id === opportunityId);
    assert(!!found, 'Created opportunity is visible in browse list');

    // Search by keyword
    const searchResult = await request('/opportunities?search=Beach');
    assert(searchResult.status === 200, 'Search returned 200');
    const searchFound = searchResult.data.opportunities.find((o: any) => o.id === opportunityId);
    assert(!!searchFound, 'Opportunity found via search');

    // ========== TEST 4: View single opportunity ==========
    console.log('\n--- Test 4: View Single Opportunity ---');
    const viewOpp = await request(`/opportunities/${opportunityId}`);
    assert(viewOpp.status === 200, 'Single opportunity view returned 200');
    assert(viewOpp.data.opportunity.id === opportunityId, 'Correct opportunity returned');
    assert(viewOpp.data.opportunity.ngo.name === 'Green Earth Foundation', 'NGO info included');

    const viewNotFound = await request('/opportunities/00000000-0000-0000-0000-000000000000');
    assert(viewNotFound.status === 404, 'Non-existent opportunity returns 404');

    // ========== TEST 5: NGO updates opportunity ==========
    console.log('\n--- Test 5: NGO Updates Opportunity ---');
    const updateOpp = await request(`/opportunities/${opportunityId}`, {
      method: 'PUT',
      headers: { Authorization: `Bearer ${ngoToken}` },
      body: JSON.stringify({ title: 'Beach Cleanup Drive 2026', location: 'Mumbai, Juhu Beach' }),
    });
    assert(updateOpp.status === 200, 'Opportunity updated');
    assert(updateOpp.data.opportunity.title === 'Beach Cleanup Drive 2026', 'Title updated');
    assert(updateOpp.data.opportunity.location === 'Mumbai, Juhu Beach', 'Location updated');

    // Other NGO cannot update (ownership enforcement)
    const ngo2Update = await request(`/opportunities/${opportunityId}`, {
      method: 'PUT',
      headers: { Authorization: `Bearer ${ngo2Token}` },
      body: JSON.stringify({ title: 'Hijacked' }),
    });
    assert(ngo2Update.status === 403, 'Other NGO cannot update opportunity (403)');

    // ========== TEST 6: Volunteer applies ==========
    console.log('\n--- Test 6: Volunteer Applies to Opportunity ---');
    const applyRes = await request(`/opportunities/${opportunityId}/apply`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${volunteerToken}` },
    });
    assert(applyRes.status === 201, 'Application submitted successfully');
    assert(applyRes.data.application.status === 'PENDING', 'Application status is PENDING');
    assert(applyRes.data.application.opportunity.title === 'Beach Cleanup Drive 2026', 'Application includes opportunity title');
    const applicationId = applyRes.data.application.id;

    // NGO cannot apply
    const ngoApply = await request(`/opportunities/${opportunityId}/apply`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${ngoToken}` },
    });
    assert(ngoApply.status === 403, 'NGO cannot apply to opportunities (403)');

    // ========== TEST 7: Duplicate application rejected ==========
    console.log('\n--- Test 7: Duplicate Application Rejected ---');
    const duplicateApply = await request(`/opportunities/${opportunityId}/apply`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${volunteerToken}` },
    });
    assert(duplicateApply.status === 409, 'Duplicate application rejected with 409');

    // ========== TEST 8: Volunteer2 also applies ==========
    console.log('\n--- Test 8: Second Volunteer Applies ---');
    const apply2 = await request(`/opportunities/${opportunityId}/apply`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${volunteer2Token}` },
    });
    assert(apply2.status === 201, 'Volunteer2 application submitted');

    // ========== TEST 9: NGO views applicants ==========
    console.log('\n--- Test 9: NGO Views Applicants ---');
    const ngoViewApps = await request(`/opportunities/${opportunityId}/applications`, {
      headers: { Authorization: `Bearer ${ngoToken}` },
    });
    assert(ngoViewApps.status === 200, 'NGO can view applications for own opportunity');
    assert(ngoViewApps.data.applications.length === 2, 'Two applications found');
    const volunteerApp = ngoViewApps.data.applications.find((a: any) => a.volunteer.name === 'Priya Sharma');
    assert(!!volunteerApp, 'Volunteer Priya Sharma visible in applications');

    // Other NGO cannot view these applications
    const ngo2ViewApps = await request(`/opportunities/${opportunityId}/applications`, {
      headers: { Authorization: `Bearer ${ngo2Token}` },
    });
    assert(ngo2ViewApps.status === 403, 'Other NGO cannot view applications for unowned opportunity (403)');

    // NGO views all applications across all opportunities
    const ngoAllApps = await request('/applications/ngo', {
      headers: { Authorization: `Bearer ${ngoToken}` },
    });
    assert(ngoAllApps.status === 200, 'NGO all-applications endpoint returned 200');
    assert(ngoAllApps.data.applications.length >= 2, 'NGO sees at least 2 applications');

    // ========== TEST 10: NGO accepts an application ==========
    console.log('\n--- Test 10: NGO Accepts Application ---');
    const acceptRes = await request(`/applications/${applicationId}/status`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${ngoToken}` },
      body: JSON.stringify({ status: 'ACCEPTED' }),
    });
    assert(acceptRes.status === 200, 'Application accepted');
    assert(acceptRes.data.application.status === 'ACCEPTED', 'Application status is ACCEPTED');

    // Other NGO cannot manage this application
    const ngo2Accept = await request(`/applications/${applicationId}/status`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${ngo2Token}` },
      body: JSON.stringify({ status: 'REJECTED' }),
    });
    assert(ngo2Accept.status === 403, 'Other NGO cannot manage applications for unowned opportunity (403)');

    // Invalid status value
    const badStatus = await request(`/applications/${applicationId}/status`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${ngoToken}` },
      body: JSON.stringify({ status: 'MAYBE' }),
    });
    assert(badStatus.status === 400, 'Invalid application status rejected with 400');

    // ========== TEST 11: Volunteer sees updated status ==========
    console.log('\n--- Test 11: Volunteer Sees Updated Status ---');
    const volApps = await request('/applications/my', {
      headers: { Authorization: `Bearer ${volunteerToken}` },
    });
    assert(volApps.status === 200, 'Volunteer can view own applications');
    const myApp = volApps.data.applications.find((a: any) => a.id === applicationId);
    assert(!!myApp, 'Volunteer sees their own application');
    assert(myApp.status === 'ACCEPTED', 'Status is now ACCEPTED');
    assert(myApp.opportunity.title === 'Beach Cleanup Drive 2026', 'Opportunity details included');

    // ========== TEST 12: NGO rejects volunteer2's application ==========
    console.log('\n--- Test 12: NGO Rejects Application ---');
    const rejectRes = await request(`/applications/${apply2.data.application.id}/status`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${ngoToken}` },
      body: JSON.stringify({ status: 'REJECTED' }),
    });
    assert(rejectRes.status === 200, 'Application rejected');
    assert(rejectRes.data.application.status === 'REJECTED', 'Application status is REJECTED');

    // Volunteer2 sees REJECTED status
    const vol2Apps = await request('/applications/my', {
      headers: { Authorization: `Bearer ${volunteer2Token}` },
    });
    const vol2App = vol2Apps.data.applications.find((a: any) => a.id === apply2.data.application.id);
    assert(!!vol2App, 'Volunteer2 sees their application');
    assert(vol2App.status === 'REJECTED', 'Volunteer2 sees REJECTED status');

    // ========== TEST 13: Apply to closed opportunity ==========
    console.log('\n--- Test 13: Closed Opportunity Blocks Applications ---');
    const closeOpp = await request(`/opportunities/${opportunityId}`, {
      method: 'PUT',
      headers: { Authorization: `Bearer ${ngoToken}` },
      body: JSON.stringify({ status: 'CLOSED' }),
    });
    assert(closeOpp.status === 200, 'Opportunity closed');
    assert(closeOpp.data.opportunity.status === 'CLOSED', 'Status is now CLOSED');

    // Volunteer2 tries to apply to a second time after closure (but they already applied)
    // Create a fresh volunteer to test closed-opportunity blocking
    const vol3Reg = await request('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ email: `vol3_${ts}@example.com`, password: 'password123', name: 'Volunteer3', role: 'VOLUNTEER' }),
    });
    const vol3Token = vol3Reg.data.token;

    const closedApply = await request(`/opportunities/${opportunityId}/apply`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${vol3Token}` },
    });
    assert(closedApply.status === 400, 'Cannot apply to closed opportunity (400)');

    // ========== TEST 14: NGO deletes opportunity ==========
    console.log('\n--- Test 14: NGO Deletes Opportunity ---');

    // Create a new opportunity for deletion test
    const deleteOpp = await request('/opportunities', {
      method: 'POST',
      headers: { Authorization: `Bearer ${ngoToken}` },
      body: JSON.stringify({
        title: 'Temporary Event', description: 'Will be deleted', location: 'Test', date: '2026-12-20',
      }),
    });
    assert(deleteOpp.status === 201, 'Temporary opportunity created');
    const deleteOppId = deleteOpp.data.opportunity.id;

    // Other NGO cannot delete
    const ngo2Delete = await request(`/opportunities/${deleteOppId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${ngo2Token}` },
    });
    assert(ngo2Delete.status === 403, 'Other NGO cannot delete opportunity (403)');

    // Owner deletes
    const deleteRes = await request(`/opportunities/${deleteOppId}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${ngoToken}` },
    });
    assert(deleteRes.status === 200, 'Opportunity deleted');

    // Verify deleted
    const verifyDeleted = await request(`/opportunities/${deleteOppId}`);
    assert(verifyDeleted.status === 404, 'Deleted opportunity returns 404');

    // ========== TEST 15: NGO views own opportunities ==========
    console.log('\n--- Test 15: NGO Views Own Opportunities ---');
    const myOpps = await request('/opportunities/my', {
      headers: { Authorization: `Bearer ${ngoToken}` },
    });
    assert(myOpps.status === 200, 'NGO my-opportunities returned 200');
    assert(Array.isArray(myOpps.data.opportunities), 'Opportunities is an array');

    console.log('\n🎉 ALL OPPORTUNITY & APPLICATION TESTS PASSED!\n');
  } finally {
    server.close();
  }
}

runTests().catch((err) => {
  console.error('Test suite failed:', err);
  if (server) server.close();
  process.exit(1);
});
