import { OpportunityStatus, Role } from '@prisma/client';
import prisma from '../src/config/prisma';
import { hashPassword } from '../src/utils/password';

const demoNgo = {
  email: 'demo-ngo@seva-connect.example',
  password: 'SevaDemo2026!',
  name: 'Seva Connect Demo NGO',
  bio: 'A demo nonprofit coordinating community volunteering opportunities in Pune.',
  contactInfo: 'demo-ngo@seva-connect.example',
  location: 'Pune, Maharashtra',
};

const opportunitySeeds = [
  {
    id: 'd3a00000-0000-4000-8000-000000000001',
    title: 'Community Tree Planting at Vetal Tekdi',
    description:
      'Cause: Environment and urban greening. Help plant native saplings and mulch young trees with the neighborhood green team. Volunteers should wear closed-toe shoes, bring a refillable water bottle, and be comfortable working outdoors. No planting experience is needed; tools and a safety briefing are provided.',
    location: 'Vetal Tekdi, Pune, Maharashtra',
    daysFromNow: 7,
  },
  {
    id: 'd3a00000-0000-4000-8000-000000000002',
    title: 'Saturday Community Kitchen at Hadapsar',
    description:
      'Cause: Food security. Assist with sorting donated produce, preparing meal boxes, and serving a community lunch. Volunteers should wear comfortable clothing and a hair covering; please share any food-handling restrictions with the coordinator beforehand. No prior kitchen experience is required.',
    location: 'Hadapsar, Pune, Maharashtra',
    daysFromNow: 14,
  },
  {
    id: 'd3a00000-0000-4000-8000-000000000003',
    title: 'Accessible Learning Buddy in Kothrud',
    description:
      'Cause: Inclusive education. Support school-age learners with reading practice, simple study activities, and setting up accessible learning materials. Volunteers need patience, clear communication, and a commitment to a two-hour session. Teaching experience is welcome but not required; materials are supplied.',
    location: 'Kothrud, Pune, Maharashtra',
    daysFromNow: 21,
  },
  {
    id: 'd3a00000-0000-4000-8000-000000000004',
    title: 'Pashan Lake Cleanup and Water Watch',
    description:
      'Cause: Clean water and conservation. Join a guided lakeside litter collection and record visible waste hotspots for the local conservation group. Gloves and collection bags are provided. Wear sturdy shoes, bring water, and be prepared to walk on uneven paths; no technical background is needed.',
    location: 'Pashan Lake, Pune, Maharashtra',
    daysFromNow: 28,
  },
  {
    id: 'd3a00000-0000-4000-8000-000000000005',
    title: 'Senior Digital Support Clinic in Aundh',
    description:
      'Cause: Digital inclusion and elder support. Help older residents with basic smartphone settings, video calls, and safe use of common apps. Volunteers should be comfortable explaining steps patiently and must not request or record personal passwords. Bring a charged phone; devices and printed guides are also available.',
    location: 'Aundh, Pune, Maharashtra',
    daysFromNow: 35,
  },
  {
    id: 'd3a00000-0000-4000-8000-000000000006',
    title: 'Community Health Camp Support in Kondhwa',
    description:
      'Cause: Community health access. Welcome visitors, help manage the queue, and guide attendees between registration and consultation desks. This is a non-clinical role; volunteers must follow staff instructions and protect visitor privacy. Clear communication and a half-day commitment are required; no medical training is needed.',
    location: 'Kondhwa, Pune, Maharashtra',
    daysFromNow: 42,
  },
  {
    id: 'd3a00000-0000-4000-8000-000000000007',
    title: 'Animal Shelter Care Shift in Baner',
    description:
      'Cause: Animal welfare. Support shelter staff with cleaning, preparing food, and supervised enrichment for rescued dogs. Volunteers should wear clothes that can get dirty and follow all animal-handling guidance. Prior shelter experience is helpful but not required; the team provides an orientation and cleaning supplies.',
    location: 'Baner, Pune, Maharashtra',
    daysFromNow: 49,
  },
] as const;

const getEventDate = (daysFromNow: number): Date => {
  const date = new Date();
  date.setDate(date.getDate() + daysFromNow);
  date.setHours(9, 0, 0, 0);
  return date;
};

const run = async (): Promise<void> => {
  const passwordHash = await hashPassword(demoNgo.password);

  await prisma.$transaction(async (transaction) => {
    let ngo = await transaction.user.findUnique({
      where: { email: demoNgo.email },
    });

    if (ngo && ngo.role !== Role.NGO) {
      throw new Error(`The reserved demo account ${demoNgo.email} is not an NGO.`);
    }

    if (!ngo) {
      ngo = await transaction.user.create({
        data: {
          email: demoNgo.email,
          passwordHash,
          role: Role.NGO,
          name: demoNgo.name,
          bio: demoNgo.bio,
          contactInfo: demoNgo.contactInfo,
          location: demoNgo.location,
        },
      });
      console.log(`Created demo NGO account: ${demoNgo.email}`);
    } else {
      console.log(`Using existing demo NGO account: ${demoNgo.email}`);
    }

    let createdCount = 0;
    for (const seed of opportunitySeeds) {
      const existing = await transaction.opportunity.findUnique({
        where: { id: seed.id },
      });

      if (existing) {
        if (existing.ngoId !== ngo.id || existing.title !== seed.title) {
          throw new Error(
            `Seed ID ${seed.id} is already used by a different opportunity; no data was changed.`,
          );
        }
        continue;
      }

      await transaction.opportunity.create({
        data: {
          id: seed.id,
          title: seed.title,
          description: seed.description,
          location: seed.location,
          date: getEventDate(seed.daysFromNow),
          status: OpportunityStatus.OPEN,
          ngoId: ngo.id,
        },
      });
      createdCount += 1;
    }

    console.log(
      `Demo seed complete: created ${createdCount}, already present ${opportunitySeeds.length - createdCount} of ${opportunitySeeds.length} opportunities.`,
    );
  });
};

run()
  .catch((error: unknown) => {
    console.error('Demo seed failed:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
