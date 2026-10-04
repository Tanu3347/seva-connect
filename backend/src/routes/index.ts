import { Router, Request, Response } from 'express';
import { healthCheck } from '../controllers/health.controller';
import authRoutes from './auth.routes';
import opportunityRoutes from './opportunity.routes';
import applicationRoutes from './application.routes';
import profileRoutes from './profile.routes';
import { authenticate, authorize } from '../middlewares/auth.middleware';

const router = Router();

// Health check endpoint
router.get('/health', healthCheck);

// Authentication endpoints
router.use('/auth', authRoutes);

// Opportunity endpoints
router.use('/opportunities', opportunityRoutes);

// Application endpoints
router.use('/applications', applicationRoutes);
router.use('/profile', profileRoutes);

// Role-protected endpoints for testing & authorization verification
router.get('/protected/volunteer-only', authenticate, authorize(['VOLUNTEER']), (req: Request, res: Response) => {
  res.status(200).json({
    message: 'Access granted to Volunteer',
    user: req.user,
  });
});

router.get('/protected/ngo-only', authenticate, authorize(['NGO']), (req: Request, res: Response) => {
  res.status(200).json({
    message: 'Access granted to NGO',
    user: req.user,
  });
});

export default router;
