import { Request, Response } from 'express';
import { ApplicationStatus } from '@prisma/client';
import prisma from '../config/prisma';

// Volunteer applies to an opportunity
export const applyToOpportunity = async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ error: 'Authentication required' });
      return;
    }

    const opportunityId = req.params.opportunityId as string;

    if (!opportunityId) {
      res.status(400).json({ error: 'Opportunity ID is required' });
      return;
    }

    const opportunity = await prisma.opportunity.findUnique({
      where: { id: opportunityId },
    });

    if (!opportunity) {
      res.status(404).json({ error: 'Opportunity not found' });
      return;
    }

    if (opportunity.status === 'CLOSED') {
      res.status(400).json({ error: 'This opportunity is closed for applications' });
      return;
    }

    // Check if duplicate application exists using the compound unique key
    const existingApplication = await prisma.application.findUnique({
      where: {
        volunteerId_opportunityId: {
          volunteerId: req.user.userId,
          opportunityId,
        },
      },
    });

    if (existingApplication) {
      res.status(409).json({ error: 'You have already applied for this opportunity' });
      return;
    }

    const application = await prisma.application.create({
      data: {
        volunteerId: req.user.userId,
        opportunityId,
        status: ApplicationStatus.PENDING,
      },
      include: {
        opportunity: {
          select: {
            id: true,
            title: true,
            location: true,
            date: true,
            status: true,
          },
        },
        volunteer: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
    });

    res.status(201).json({
      message: 'Application submitted successfully',
      application,
    });
  } catch (error: any) {
    console.error('applyToOpportunity error:', error);
    res.status(500).json({ error: 'Internal server error submitting application' });
  }
};

// Volunteer views all their own applications
export const getMyApplications = async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ error: 'Authentication required' });
      return;
    }

    const applications = await prisma.application.findMany({
      where: { volunteerId: req.user.userId },
      include: {
        opportunity: {
          select: {
            id: true,
            title: true,
            description: true,
            location: true,
            date: true,
            status: true,
            ngo: {
              select: {
                id: true,
                name: true,
                email: true,
                contactInfo: true,
              },
            },
          },
        },
      },
      orderBy: { appliedAt: 'desc' },
    });

    res.status(200).json({ applications });
  } catch (error: any) {
    console.error('getMyApplications error:', error);
    res.status(500).json({ error: 'Internal server error fetching your applications' });
  }
};

// NGO views applications for a specific opportunity they own
export const getApplicationsForOpportunity = async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ error: 'Authentication required' });
      return;
    }

    const opportunityId = req.params.opportunityId as string;

    const opportunity = await prisma.opportunity.findUnique({
      where: { id: opportunityId },
    });

    if (!opportunity) {
      res.status(404).json({ error: 'Opportunity not found' });
      return;
    }

    // Enforce ownership
    if (opportunity.ngoId !== req.user.userId) {
      res.status(403).json({ error: 'Forbidden: You do not own this opportunity' });
      return;
    }

    const applications = await prisma.application.findMany({
      where: { opportunityId },
      include: {
        volunteer: {
          select: {
            id: true,
            name: true,
            email: true,
            bio: true,
            contactInfo: true,
          },
        },
      },
      orderBy: { appliedAt: 'desc' },
    });

    res.status(200).json({ applications });
  } catch (error: any) {
    console.error('getApplicationsForOpportunity error:', error);
    res.status(500).json({ error: 'Internal server error fetching applications' });
  }
};

// NGO views all applications across all their opportunities
export const getNgoApplications = async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ error: 'Authentication required' });
      return;
    }

    const applications = await prisma.application.findMany({
      where: {
        opportunity: {
          ngoId: req.user.userId,
        },
      },
      include: {
        opportunity: {
          select: {
            id: true,
            title: true,
            location: true,
            date: true,
            status: true,
          },
        },
        volunteer: {
          select: {
            id: true,
            name: true,
            email: true,
            bio: true,
            contactInfo: true,
          },
        },
      },
      orderBy: { appliedAt: 'desc' },
    });

    res.status(200).json({ applications });
  } catch (error: any) {
    console.error('getNgoApplications error:', error);
    res.status(500).json({ error: 'Internal server error fetching NGO applications' });
  }
};

// NGO accepts or rejects an application
export const updateApplicationStatus = async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ error: 'Authentication required' });
      return;
    }

    const applicationId = req.params.applicationId as string;
    const { status } = req.body;

    if (!status || (status !== 'ACCEPTED' && status !== 'REJECTED')) {
      res.status(400).json({ error: "Status must be either 'ACCEPTED' or 'REJECTED'" });
      return;
    }

    const application = await prisma.application.findUnique({
      where: { id: applicationId },
      include: {
        opportunity: {
          select: {
            id: true,
            ngoId: true,
            title: true,
          },
        },
      },
    });

    if (!application) {
      res.status(404).json({ error: 'Application not found' });
      return;
    }

    // Enforce ownership: only the NGO that owns the opportunity can manage applications
    if (application.opportunity.ngoId !== req.user.userId) {
      res.status(403).json({
        error: 'Forbidden: You can only manage applications for opportunities that you own',
      });
      return;
    }

    const updatedApplication = await prisma.application.update({
      where: { id: applicationId },
      data: {
        status: status as ApplicationStatus,
      },
      include: {
        opportunity: {
          select: {
            id: true,
            title: true,
            location: true,
            date: true,
            status: true,
          },
        },
        volunteer: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
    });

    res.status(200).json({
      message: `Application ${status.toLowerCase()} successfully`,
      application: updatedApplication,
    });
  } catch (error: any) {
    console.error('updateApplicationStatus error:', error);
    res.status(500).json({ error: 'Internal server error updating application status' });
  }
};
