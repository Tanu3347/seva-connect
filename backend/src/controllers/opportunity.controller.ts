import { Request, Response } from 'express';
import { OpportunityStatus } from '@prisma/client';
import prisma from '../config/prisma';

// Create a new opportunity (NGO only)
export const createOpportunity = async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ error: 'Authentication required' });
      return;
    }

    const { title, description, location, date, status } = req.body;

    if (!title || typeof title !== 'string' || title.trim().length === 0) {
      res.status(400).json({ error: 'Title is required' });
      return;
    }

    if (!description || typeof description !== 'string' || description.trim().length === 0) {
      res.status(400).json({ error: 'Description is required' });
      return;
    }

    if (!location || typeof location !== 'string' || location.trim().length === 0) {
      res.status(400).json({ error: 'Location is required' });
      return;
    }

    if (!date) {
      res.status(400).json({ error: 'Date is required' });
      return;
    }

    const parsedDate = new Date(date);
    if (isNaN(parsedDate.getTime())) {
      res.status(400).json({ error: 'Invalid date format' });
      return;
    }

    let opportunityStatus: OpportunityStatus = OpportunityStatus.OPEN;
    if (status) {
      if (status !== 'OPEN' && status !== 'CLOSED') {
        res.status(400).json({ error: "Status must be either 'OPEN' or 'CLOSED'" });
        return;
      }
      opportunityStatus = status as OpportunityStatus;
    }

    const opportunity = await prisma.opportunity.create({
      data: {
        title: title.trim(),
        description: description.trim(),
        location: location.trim(),
        date: parsedDate,
        status: opportunityStatus,
        ngoId: req.user.userId,
      },
      include: {
        ngo: {
          select: {
            id: true,
            name: true,
            email: true,
            contactInfo: true,
          },
        },
      },
    });

    res.status(201).json({
      message: 'Opportunity created successfully',
      opportunity,
    });
  } catch (error: any) {
    console.error('createOpportunity error:', error);
    res.status(500).json({ error: 'Internal server error creating opportunity' });
  }
};

// Get all open opportunities (with optional search and status query)
export const getOpportunities = async (req: Request, res: Response): Promise<void> => {
  try {
    const { search, status } = req.query;

    const whereClause: any = {};

    if (status && (status === 'OPEN' || status === 'CLOSED')) {
      whereClause.status = status as OpportunityStatus;
    } else if (!status) {
      // Default to OPEN opportunities when not specified
      whereClause.status = OpportunityStatus.OPEN;
    }

    if (search && typeof search === 'string' && search.trim().length > 0) {
      const searchTerm = search.trim();
      whereClause.OR = [
        { title: { contains: searchTerm, mode: 'insensitive' } },
        { description: { contains: searchTerm, mode: 'insensitive' } },
        { location: { contains: searchTerm, mode: 'insensitive' } },
      ];
    }

    const opportunities = await prisma.opportunity.findMany({
      where: whereClause,
      include: {
        ngo: {
          select: {
            id: true,
            name: true,
            email: true,
            contactInfo: true,
          },
        },
        _count: {
          select: { applications: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.status(200).json({ opportunities });
  } catch (error: any) {
    console.error('getOpportunities error:', error);
    res.status(500).json({ error: 'Internal server error fetching opportunities' });
  }
};

// Get NGO's own opportunities
export const getMyOpportunities = async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ error: 'Authentication required' });
      return;
    }

    const opportunities = await prisma.opportunity.findMany({
      where: { ngoId: req.user.userId },
      include: {
        _count: {
          select: { applications: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.status(200).json({ opportunities });
  } catch (error: any) {
    console.error('getMyOpportunities error:', error);
    res.status(500).json({ error: 'Internal server error fetching your opportunities' });
  }
};

// Get single opportunity by ID
export const getOpportunityById = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;

    const opportunity = await prisma.opportunity.findUnique({
      where: { id },
      include: {
        ngo: {
          select: {
            id: true,
            name: true,
            email: true,
            contactInfo: true,
            bio: true,
          },
        },
        _count: {
          select: { applications: true },
        },
      },
    });

    if (!opportunity) {
      res.status(404).json({ error: 'Opportunity not found' });
      return;
    }

    res.status(200).json({ opportunity });
  } catch (error: any) {
    console.error('getOpportunityById error:', error);
    res.status(500).json({ error: 'Internal server error fetching opportunity' });
  }
};

// Update opportunity (NGO owner only)
export const updateOpportunity = async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ error: 'Authentication required' });
      return;
    }

    const id = req.params.id as string;
    const { title, description, location, date, status } = req.body;

    const existing = await prisma.opportunity.findUnique({
      where: { id },
    });

    if (!existing) {
      res.status(404).json({ error: 'Opportunity not found' });
      return;
    }

    // Enforce ownership
    if (existing.ngoId !== req.user.userId) {
      res.status(403).json({ error: 'Forbidden: You do not own this opportunity' });
      return;
    }

    const updateData: any = {};

    if (title !== undefined) {
      if (typeof title !== 'string' || title.trim().length === 0) {
        res.status(400).json({ error: 'Title cannot be empty' });
        return;
      }
      updateData.title = title.trim();
    }

    if (description !== undefined) {
      if (typeof description !== 'string' || description.trim().length === 0) {
        res.status(400).json({ error: 'Description cannot be empty' });
        return;
      }
      updateData.description = description.trim();
    }

    if (location !== undefined) {
      if (typeof location !== 'string' || location.trim().length === 0) {
        res.status(400).json({ error: 'Location cannot be empty' });
        return;
      }
      updateData.location = location.trim();
    }

    if (date !== undefined) {
      const parsedDate = new Date(date);
      if (isNaN(parsedDate.getTime())) {
        res.status(400).json({ error: 'Invalid date format' });
        return;
      }
      updateData.date = parsedDate;
    }

    if (status !== undefined) {
      if (status !== 'OPEN' && status !== 'CLOSED') {
        res.status(400).json({ error: "Status must be either 'OPEN' or 'CLOSED'" });
        return;
      }
      updateData.status = status as OpportunityStatus;
    }

    const updated = await prisma.opportunity.update({
      where: { id },
      data: updateData,
      include: {
        ngo: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
    });

    res.status(200).json({
      message: 'Opportunity updated successfully',
      opportunity: updated,
    });
  } catch (error: any) {
    console.error('updateOpportunity error:', error);
    res.status(500).json({ error: 'Internal server error updating opportunity' });
  }
};

// Delete opportunity (NGO owner only)
export const deleteOpportunity = async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ error: 'Authentication required' });
      return;
    }

    const id = req.params.id as string;

    const existing = await prisma.opportunity.findUnique({
      where: { id },
    });

    if (!existing) {
      res.status(404).json({ error: 'Opportunity not found' });
      return;
    }

    // Enforce ownership
    if (existing.ngoId !== req.user.userId) {
      res.status(403).json({ error: 'Forbidden: You do not own this opportunity' });
      return;
    }

    await prisma.opportunity.delete({
      where: { id },
    });

    res.status(200).json({ message: 'Opportunity deleted successfully' });
  } catch (error: any) {
    console.error('deleteOpportunity error:', error);
    res.status(500).json({ error: 'Internal server error deleting opportunity' });
  }
};
