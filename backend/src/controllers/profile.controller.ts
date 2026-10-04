import { Request, Response } from 'express';
import prisma from '../config/prisma';

const profileFields = {
  id: true,
  email: true,
  role: true,
  name: true,
  bio: true,
  location: true,
  interests: true,
  skills: true,
  createdAt: true,
  updatedAt: true,
} as const;

const parseOptionalText = (
  value: unknown,
  field: string,
  maxLength: number,
): string | null | undefined => {
  if (value === undefined) return undefined;
  if (value === null) return null;
  if (typeof value !== 'string') {
    throw new TypeError(`${field} must be a string`);
  }
  const trimmed = value.trim();
  if (trimmed.length > maxLength) {
    throw new RangeError(`${field} must be ${maxLength} characters or fewer`);
  }
  return trimmed || null;
};

const parseStringList = (value: unknown, field: string): string[] | undefined => {
  if (value === undefined) return undefined;
  if (!Array.isArray(value) || value.length > 20) {
    throw new TypeError(`${field} must be a list of up to 20 items`);
  }
  const items: string[] = [];
  for (const item of value) {
    if (typeof item !== 'string' || item.trim().length === 0 || item.trim().length > 60) {
      throw new TypeError(`${field} items must be non-empty strings of at most 60 characters`);
    }
    const trimmed = item.trim();
    if (!items.includes(trimmed)) items.push(trimmed);
  }
  return items;
};

export const getVolunteerProfile = async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ error: 'Authentication required' });
      return;
    }

    const profile = await prisma.user.findUnique({
      where: { id: req.user.userId },
      select: profileFields,
    });
    if (!profile) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    res.status(200).json({ profile });
  } catch (error: unknown) {
    console.error('getVolunteerProfile error:', error);
    res.status(500).json({ error: 'Internal server error fetching volunteer profile' });
  }
};

export const updateVolunteerProfile = async (
  req: Request,
  res: Response,
): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ error: 'Authentication required' });
      return;
    }

    if (!req.body || typeof req.body !== 'object' || Array.isArray(req.body)) {
      res.status(400).json({ error: 'A profile update object is required' });
      return;
    }

    const { name, bio, location, interests, skills } = req.body;
    if (name !== undefined &&
        (typeof name !== 'string' || name.trim().length === 0 || name.trim().length > 100)) {
      res.status(400).json({ error: 'Name must be a non-empty string of at most 100 characters' });
      return;
    }

    let parsedBio: string | null | undefined;
    let parsedLocation: string | null | undefined;
    let parsedInterests: string[] | undefined;
    let parsedSkills: string[] | undefined;
    try {
      parsedBio = parseOptionalText(bio, 'Bio', 1000);
      parsedLocation = parseOptionalText(location, 'Location', 200);
      parsedInterests = parseStringList(interests, 'Interests');
      parsedSkills = parseStringList(skills, 'Skills');
    } catch (error: unknown) {
      if (error instanceof TypeError || error instanceof RangeError) {
        res.status(400).json({ error: error.message });
        return;
      }
      throw error;
    }

    const data = {
      ...(name !== undefined ? { name: name.trim() } : {}),
      ...(parsedBio !== undefined ? { bio: parsedBio } : {}),
      ...(parsedLocation !== undefined ? { location: parsedLocation } : {}),
      ...(parsedInterests !== undefined ? { interests: parsedInterests } : {}),
      ...(parsedSkills !== undefined ? { skills: parsedSkills } : {}),
    };

    const profile = await prisma.user.update({
      where: { id: req.user.userId },
      data,
      select: profileFields,
    });
    res.status(200).json({
      message: 'Volunteer profile updated successfully',
      profile,
    });
  } catch (error: unknown) {
    console.error('updateVolunteerProfile error:', error);
    res.status(500).json({ error: 'Internal server error updating volunteer profile' });
  }
};
