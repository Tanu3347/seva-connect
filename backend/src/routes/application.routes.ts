import { Router } from 'express';
import {
  getMyApplications,
  getNgoApplications,
  updateApplicationStatus,
} from '../controllers/application.controller';
import { authenticate, authorize } from '../middlewares/auth.middleware';

const router = Router();

// Volunteer views their own applications
router.get('/my', authenticate, authorize(['VOLUNTEER']), getMyApplications);

// NGO views all applications across all their opportunities
router.get('/ngo', authenticate, authorize(['NGO']), getNgoApplications);

// NGO accept/reject an application
router.patch('/:applicationId/status', authenticate, authorize(['NGO']), updateApplicationStatus);

export default router;
